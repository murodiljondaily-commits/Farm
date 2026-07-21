"""Sonnet-based orchestration — the "brain" that decides what a farmer's
message means and which tool(s) to call. Runs entirely in English; the
farmer's own language never reaches this module and Sonnet never produces
farmer-facing text directly (see language_boundary.py, which wraps this on
both sides). Reuses the existing tool functions and propose/confirm/execute
plumbing from tool_schemas.py/tools.py unchanged — only the decision-maker
is new.

Deliberately NOT wired into agent.py's run_agent() yet — this module is
self-contained and independently testable first; the entry-point rewiring
is a separate, later step (see the Phase 6 plan).
"""
import os
from typing import Any, Dict, List, Optional

import anthropic

from tool_schemas import (
    ALL_TOOLS,
    TOOL_MAP,
    READ_TOOL_NAMES,
    WRITE_TOOL_NAMES,
    missing_required,
    action_summary,
    _affected_animals,
)

MODEL = "claude-sonnet-5"
MAX_TOOL_ITERATIONS = 8  # hard stop against a runaway tool-call loop

_client = anthropic.AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", "").strip())

# Sonnet's own required "hang up the call" tool — replaces regex-scraping a
# confidence percentage out of free text (the old Gemini approach). Every
# turn must end with exactly one call to this, so confidence/emergency/
# confirmation-pending are always structured data, never parsed prose.
_FINISH_TOOL = {
    "name": "finish_response",
    "description": (
        "Call this exactly once to end your turn, after any other tool calls "
        "you needed to make. This is mandatory — every turn must end with it."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "summary": {
                "type": "string",
                "description": (
                    "Plain English summary of what you found/did, or the "
                    "question you're asking — this is translated and shown "
                    "to the farmer as-is, so write only what a busy farmer "
                    "needs: 3-5 sentences, no mention of tools/databases/"
                    "saving, no meta-commentary."
                ),
            },
            "confidence": {
                "type": "integer",
                "description": "0-100 confidence in any diagnosis/decision this turn. 100 if no diagnosis was involved.",
            },
            "is_emergency": {
                "type": "boolean",
                "description": "True if this situation needs immediate/urgent handling.",
            },
            "needs_confirmation": {
                "type": "boolean",
                "description": "True if you're waiting on the farmer to confirm something rather than having completed an action.",
            },
        },
        "required": ["summary", "confidence", "is_emergency", "needs_confirmation"],
    },
}

SYSTEM_PROMPT = """You are Sonya, the AI veterinarian and farm manager for the AgriVet app — 15 years of experience, based in the Fergana Valley. You reason and act entirely in English; a separate translation layer handles the farmer's actual language on both ends, so you never see or produce anything but English.

YOUR JOB:
1. Take every word the farmer says seriously.
2. When you hear about an animal problem — FIRST call get_animal_full_record, THEN you MUST act. Reading history and stopping there with no action is a bug you must never commit.
3. If the farmer describes a CLEAR problem (a specific symptom or body part), immediately begin the clinical workflow: search_rag, then add_health_case, in the same turn. Do not wait for confirmation first.
   If the description is VAGUE (just "sick" or "not well," no specific symptom), ask exactly ONE clarifying question, then proceed once you have an answer.
4. If the farmer says "I'm a vet/doctor," switch to a structured clinical-report style instead of conversational.
5. Never end a reply by telling the farmer to "consult a vet" — YOU are the vet.
6. Always produce a confidence score (0-100) for any diagnosis you make.
7. In emergencies: act immediately, explain afterward.
8. Before an action needs information you don't have (a vaccine name, a new status, a weight figure) — ask for it in plain language BEFORE calling the tool. Once you have everything, call the tool. If no date is given, assume today.

ANIMAL PINNING:
- Once an animal is identified in the conversation, it becomes "pinned."
- Currently pinned animal: {pinned_animal}
- If the farmer doesn't name a different animal explicitly, all tool calls target the pinned animal.
- If the farmer gives a short/vague reply (just a name, or "it"), continue with the pinned animal.
- When the animal changes, clear old symptom/diagnosis context — it must not carry over to the new animal.

BACKGROUND SYSTEM — CRITICAL:
All records (opening a case, status updates, vaccinations, weight) save automatically in the background. NEVER tell the farmer this is happening — you are simply talking to them as a vet. Never say things like "Saving...", "Confirm?", "Recorded", "Logged in the system". When a tool returns success, continue the clinical conversation naturally — say nothing about the save itself.

WHEN TO OPEN A HEALTH CASE (add_health_case):
Triggered when the farmer DESCRIBES a problem (a symptom, pain, a change, something unusual-looking).
NOT triggered by a command like "mark it healthy" or "just log this" — those are instructions, not clinical descriptions.

CLEAR DESCRIPTION (has a symptom or body part) — e.g. "her eye is swollen," "she's stopped eating," "she's struggling to put weight on that leg":
In the same turn, call in sequence: search_rag, then add_health_case. Do not ask for extra confirmation first.

VAGUE DESCRIPTION (only "got sick," "not doing well," "acting off" — no specific symptom) — e.g. "Guli got sick":
Do NOT open a case — without a real symptom/body part, add_health_case can't be filled in properly (a fabricated diagnosis would be dangerous). Instead ask exactly ONE specific question: "What's bothering her — is she losing weight, running a fever, off her feed, or is there pain somewhere specific?" Once you get an answer, follow the CLEAR DESCRIPTION path above.
Reading the record, finding no active/past illness, and just replying "she's healthy, no active or past issues" and STOPPING THERE is strictly forbidden.

WHICH ACTIONS RUN SILENTLY IN THE BACKGROUND (no confirmation needed from you):
add_health_case, update_animal_status (davolanmoqda/kritik), update_case_status, log_vaccination, log_weight, record_event, add_photo_to_case.

ONLY THESE REQUIRE EXPLICIT CONFIRMATION FROM THE FARMER FIRST:
- Marking an animal as died or sold — ask directly: "I'll mark [name] as died. Confirm?"
- Closing a health case (close_case) — follow the mandatory sequence below.

CLOSING A CASE — MANDATORY SEQUENCE (before calling close_case):
Triggered by phrases like: "recovered," "got better," "healed," "died," "sold," "sent elsewhere," "got over it," "finished treating," "cured."
STEP 1 — Ask the outcome, exactly one of: "How did it turn out — did she recover, get worse, die, or get sent elsewhere?"
STEP 2 — ONLY for "recovered" or "got worse," ask: "How many days did it take?" (skip entirely for died/sent-elsewhere)
STEP 3 — Ask: "Did a vet confirm this — yes or no?"
STEP 4 (optional) — "Any additional notes?"
Once you have all mandatory answers, call close_case(case_id=..., outcome=..., recovery_days=..., vet_confirmed=...). NEVER call it with incomplete information.

READING RECORDS / OPENING CASES — MANDATORY ORDER, NEVER SKIP:
- ALWAYS call get_animal_full_record first — never guess. This is the FIRST step, not the LAST.
- If an active case already exists, do NOT open a new one — use add_photo_to_case or append_case_symptoms instead.
- For a genuinely new problem: search_rag (species + symptoms_list) FIRST, THEN add_health_case.
- If search_rag finds a similar past case, mention it naturally ("In a similar case before...").

ABSOLUTELY FORBIDDEN BEHAVIOR: if the farmer's LATEST message describes a NEW problem (e.g. "X got sick," "she's not doing well"), reading get_animal_full_record/get_animal_history and replying ONLY "the animal is healthy, no active or past illness" AND STOPPING THERE is strictly forbidden. A clean history does not cancel out what the farmer is reporting RIGHT NOW. Follow the health-case trigger rules above instead (clear → act; vague → one question).

PREGNANCY AND INFO UPDATES:
- Pregnancy status/month, name, breed, DOB, sex, age changes: use update_animal_info.
- Health status (healthy/davolanmoqda/kritik) changes: use update_animal_status.
- If both change at once, call BOTH tools in the SAME response.

BULK VACCINATION:
- If the farmer mentions vaccinating many animals at once ("vaccinated all of them," "all the sheep except a few"):
  1. Call get_all_animals (species filter if relevant).
  2. Show the matching animals and ask for confirmation.
  3. Once confirmed, ask for the vaccine name and date.
  4. Call log_bulk_vaccination once you have both.
  5. Report clinically: "N animals given [vaccine]. Next due [date]."
- For "everyone else," get the full list first, then exclude the stated exceptions.

HARD CONSTRAINTS:
- NEVER ask the farmer for a farm code, farm ID, user ID, or login credentials.
- Use ear tags from the FARM CONTEXT section as the only valid animal IDs.
- NEVER say phrases like "technical issue," "an error occurred," "system malfunction."
- If a tool returns found=false: say so plainly and ask the farmer to clarify.
- If a tool returns success=false: say there was a problem saving that, let's try again.

You MUST call the `finish_response` tool exactly once at the end of every turn, after any other tool calls.

FARM CONTEXT:
{farm_context}

VET MODE: {vet_mode}"""


def _tool_result_block(tool_use_id: str, content: Any) -> Dict:
    import json
    return {
        "type": "tool_result",
        "tool_use_id": tool_use_id,
        "content": json.dumps(content, ensure_ascii=False, default=str),
    }


async def decide_and_act(
    farm_id: str,
    message: str,
    history: Optional[List[Dict[str, str]]] = None,
    farm_context: str = "",
    pinned_animal: Optional[str] = None,
    vet_mode: bool = False,
    is_emergency_hint: bool = False,
) -> Dict[str, Any]:
    """Runs one turn of the Sonnet tool-calling loop. `message` and `history`
    must already be in English (see language_boundary.translate_to_english).

    Returns a dict with: response (English summary), tools_called,
    data_saved (results of tools that executed immediately),
    proposed_actions (writes awaiting farmer confirmation), confidence,
    is_emergency, needs_confirmation.
    """
    messages: List[Dict[str, Any]] = list(history or [])
    messages.append({"role": "user", "content": message})

    system = SYSTEM_PROMPT.format(
        pinned_animal=pinned_animal or "none yet",
        farm_context=farm_context or "(no context provided)",
        vet_mode="ACTIVE" if vet_mode else "off",
    )

    tools_called: List[str] = []
    data_saved: Dict[str, Any] = {}
    proposed_actions: List[Dict[str, Any]] = []
    is_emergency = is_emergency_hint
    final: Optional[Dict[str, Any]] = None

    for _ in range(MAX_TOOL_ITERATIONS):
        resp = await _client.messages.create(
            model=MODEL,
            max_tokens=2048,
            system=system,
            tools=[*ALL_TOOLS, _FINISH_TOOL],
            messages=messages,
        )

        tool_uses = [b for b in resp.content if b.type == "tool_use"]
        if not tool_uses:
            # Sonnet didn't call finish_response — treat any text as the
            # summary rather than looping forever or returning nothing.
            text = "".join(b.text for b in resp.content if b.type == "text")
            final = {
                "summary": text or "",
                "confidence": 0,
                "is_emergency": is_emergency,
                "needs_confirmation": False,
            }
            break

        messages.append({"role": "assistant", "content": resp.content})
        result_blocks = []

        for block in tool_uses:
            name = block.name
            inputs = block.input or {}

            if name == "finish_response":
                final = {
                    "summary": inputs.get("summary", ""),
                    "confidence": int(inputs.get("confidence", 0)),
                    "is_emergency": bool(inputs.get("is_emergency", False)) or is_emergency,
                    "needs_confirmation": bool(inputs.get("needs_confirmation", False)),
                }
                result_blocks.append(_tool_result_block(block.id, {"ok": True}))
                continue

            if is_emergency_hint and bool(inputs.get("is_emergency", False)):
                is_emergency = True

            call_kwargs = dict(inputs)
            call_kwargs["farm_id"] = farm_id

            if name in READ_TOOL_NAMES:
                try:
                    result = await TOOL_MAP[name](**call_kwargs)
                except Exception as exc:
                    result = {"success": False, "message": str(exc)}
                tools_called.append(name)
                result_blocks.append(_tool_result_block(block.id, result))
                continue

            # WRITE tool: gate on required fields first.
            missing = missing_required(name, inputs)
            if missing:
                result_blocks.append(_tool_result_block(
                    block.id, {"status": "needs_info", "missing_fields": missing}
                ))
                continue

            affected = _affected_animals(name, inputs)
            if is_emergency:
                try:
                    result = await TOOL_MAP[name](**call_kwargs)
                except Exception as exc:
                    result = {"success": False, "message": str(exc)}
                tools_called.append(name)
                data_saved[name] = result
                result_blocks.append(_tool_result_block(block.id, result))
            else:
                proposed_actions.append({
                    "action": name,
                    "params": inputs,
                    "affected_animals": affected,
                    "summary": action_summary(name, inputs, affected),
                })
                result_blocks.append(_tool_result_block(
                    block.id, {"status": "proposed", "message": "Awaiting farmer confirmation."}
                ))

        messages.append({"role": "user", "content": result_blocks})

        if final is not None:
            break

    if final is None:
        # Hit MAX_TOOL_ITERATIONS without a finish_response call.
        final = {
            "summary": "I need a moment to finish looking into this — could you repeat that?",
            "confidence": 0,
            "is_emergency": is_emergency,
            "needs_confirmation": False,
        }

    return {
        "response": final["summary"],
        "tools_called": tools_called,
        "data_saved": data_saved,
        "proposed_actions": proposed_actions,
        "confidence": final["confidence"],
        "is_emergency": final["is_emergency"],
        "needs_confirmation": final["needs_confirmation"],
    }

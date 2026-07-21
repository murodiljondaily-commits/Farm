"""Gemini-based language boundary — the ONLY place Uzbek/Russian/Cyrillic
text is produced or consumed in the Sonnet-orchestrated pipeline (see
claude_orchestrator.py). Sonnet only ever sees/produces English; this module
translates the farmer's incoming message to English on the way in, and
composes the natural farmer-facing reply from Sonnet's English summary on
the way out. Uses Gemini specifically because its Uzbek is more natural than
Claude's for this — a deliberate choice, not a placeholder.
"""
import os
from typing import Dict

from google import genai
from google.genai import types

_client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY", "").strip())
MODEL = "gemini-2.5-flash-lite"


def _thinking_off_kwargs() -> Dict:
    """Same defensive pattern as agent.py/storage.py: 2.5-flash-lite has
    thinking off by default (good), but older google-genai SDKs (this repo
    is pinned to 1.2.0) reject an explicit thinking_budget — omit it rather
    than 500 every call."""
    try:
        return {"thinking_config": types.ThinkingConfig(thinking_budget=0)}
    except Exception:
        return {}


_THINKING_OFF = _thinking_off_kwargs()

_LOCALE_NAMES = {
    "uz": "Uzbek (Latin script)",
    "uz_Cyrl": "Uzbek (Cyrillic script)",
    "ru": "Russian",
}


async def translate_to_english(text: str) -> str:
    """Translate a farmer's message to English for Sonnet. Falls back to the
    original text on any failure — better to let Sonnet see imperfect input
    than to break the whole turn over a translation-step outage."""
    if not text or not text.strip():
        return text
    prompt = (
        "Translate the following farm veterinary chat message to English. "
        "Preserve the literal meaning exactly — this is for an AI vet's "
        "internal reasoning, not for a human reader. If it's already in "
        "English, return it unchanged. Output ONLY the translation, "
        "nothing else, no quotes, no commentary.\n\n"
        f"Message: {text}"
    )
    try:
        resp = await _client.aio.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(max_output_tokens=512, **_THINKING_OFF),
        )
        translated = (resp.text or "").strip()
        return translated or text
    except Exception as exc:
        print(f"[LanguageBoundary] translate_to_english failed, using raw text: {exc}")
        return text


async def compose_reply(summary: str, locale: str = "uz") -> str:
    """Compose the natural farmer-facing reply in the target locale from
    Sonnet's English summary — COMPOSES a natural reply (as if Sonya is
    actually speaking), not a literal word-for-word translation."""
    if not summary or not summary.strip():
        return summary
    locale_name = _LOCALE_NAMES.get(locale, _LOCALE_NAMES["uz"])
    script_note = ""
    if locale == "uz_Cyrl":
        script_note = " Write in CYRILLIC script (e.g. 'Ассалому алайкум', 'йўқ', 'соғлом'), NOT Latin script."

    prompt = f"""You are Sonya, an AI veterinarian speaking directly to a farmer in the Fergana Valley. Below is what you found/decided this turn, in English. Rewrite it as a natural, warm, conversational reply in {locale_name} — as if you are speaking directly to the farmer, not translating a report.{script_note}

Rules:
- Plain, everyday farmer language — no Latin medical jargon or scientific terms; translate any technical terms into plain words a farmer would understand.
- 3-5 sentences, natural spoken tone.
- NO markdown formatting at all: no **, no *, no bullet points, no # headers, no tables — this is a plain-text mobile chat and those characters would show up literally on screen.
- Never mention databases, tools, saving, or "the system" — you're just talking as the vet.
- Output ONLY the reply text, nothing else.

What you found/decided (English):
{summary}"""

    try:
        resp = await _client.aio.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(max_output_tokens=1024, **_THINKING_OFF),
        )
        composed = (resp.text or "").strip()
        return composed or summary
    except Exception as exc:
        print(f"[LanguageBoundary] compose_reply failed, using raw summary: {exc}")
        return summary

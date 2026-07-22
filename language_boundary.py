"""Gemini-based language boundary — the ONLY place Uzbek/Russian/Cyrillic
text is produced or consumed in the Sonnet-orchestrated pipeline (see
claude_orchestrator.py). Sonnet only ever sees/produces English; this module
translates the farmer's incoming message to English on the way in, and
composes the natural farmer-facing reply from Sonnet's English summary on
the way out. Uses Gemini specifically because its Uzbek is more natural than
Claude's for this — a deliberate choice, not a placeholder.
"""
import asyncio
import os
from typing import Dict

from google import genai
from google.genai import types

_client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY", "").strip())
MODEL = "gemini-2.5-flash-lite"
# Same fallback chain as agent.py's MODEL/FALLBACK_MODELS (duplicated, not
# imported, to avoid a circular import with agent.py). The pinned model 404s
# ("no longer available to new users") on some API keys/projects — confirmed
# live on this deployment via /debug-firebase — so every call here must be
# able to step down rather than silently pass through untranslated text.
FALLBACK_MODELS = ("gemini-flash-lite-latest", "gemini-2.5-flash")


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


async def _generate_text(prompt: str, max_output_tokens: int) -> str:
    """Call Gemini for a single text-in/text-out prompt, stepping down
    MODEL -> FALLBACK_MODELS on 404/not-found or 503/overloaded instead of
    raising — mirrors agent.py's _generate fallback behavior. Raises only if
    every model fails, so callers can decide their own fallback (usually:
    return the untranslated/unsummarized text)."""
    last_exc = None
    # thinking_budget=0 is a flash-lite-specific optimization (see
    # _thinking_off_kwargs) — confirmed by direct testing that forcing it on
    # gemini-flash-lite-latest 400s ("invalid argument"), so only the exact
    # pinned MODEL gets it; every fallback uses its own default.
    primary_config = types.GenerateContentConfig(max_output_tokens=max_output_tokens, **_THINKING_OFF)
    fallback_config = types.GenerateContentConfig(max_output_tokens=max_output_tokens)
    for model in (MODEL, *FALLBACK_MODELS):
        config = primary_config if model == MODEL else fallback_config
        for attempt in range(2):
            try:
                resp = await _client.aio.models.generate_content(
                    model=model, contents=prompt, config=config,
                )
                text = (resp.text or "").strip()
                if text:
                    if model != MODEL:
                        print(f"[LanguageBoundary] reply served by FALLBACK model {model}")
                    return text
                break  # empty response — no point retrying same model twice here
            except Exception as exc:
                msg = str(exc).lower()
                last_exc = exc
                if "503" in msg or "unavailable" in msg or "overloaded" in msg:
                    print(f"[LanguageBoundary] {model} 503/unavailable (attempt {attempt + 1}/2)")
                    await asyncio.sleep(1.0 * (attempt + 1))
                    continue
                print(f"[LanguageBoundary] {model} failed ({msg[:100]}) — trying next model")
                break
    raise last_exc if last_exc else RuntimeError("Gemini: all models returned empty")


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
        return await _generate_text(prompt, max_output_tokens=512)
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
        return await _generate_text(prompt, max_output_tokens=1024)
    except Exception as exc:
        print(f"[LanguageBoundary] compose_reply failed, using raw summary: {exc}")
        return summary

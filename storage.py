import os
import json
from datetime import datetime, timezone
from typing import Optional, Dict

from google import genai
from google.genai import types
from firebase_admin import storage as fb_storage

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY", "").strip())
MODEL = "gemini-2.5-flash"


def _thinking_off_kwargs() -> Dict:
    """Disable 2.5-flash 'thinking' so the vision reply isn't starved of output
    tokens. Defensive: older google-genai without `thinking_budget` must not
    crash the request — omit it instead. See agent.py for the full rationale."""
    try:
        return {"thinking_config": types.ThinkingConfig(thinking_budget=0)}
    except Exception:
        return {}


_THINKING_OFF = _thinking_off_kwargs()


async def upload_photo(
    farm_id: str,
    ear_tag: str,
    case_id: Optional[str],
    image_bytes: bytes,
    category: str = "health",
    species: str = "unknown",
    condition: str = "unknown",
) -> str:
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    bucket = fb_storage.bucket()

    if case_id:
        path = f"farms/{farm_id}/animals/{ear_tag}/cases/{case_id}/{ts}.jpg"
    else:
        path = f"farms/{farm_id}/animals/{ear_tag}/{category}/{ts}.jpg"

    blob = bucket.blob(path)
    blob.upload_from_string(image_bytes, content_type="image/jpeg")
    blob.make_public()

    # Anonymized copy for RAG training
    if category == "health":
        cond_slug = condition[:30].replace(" ", "_")
        anon_path = f"rag_training/{species}/{cond_slug}/{ts}.jpg"
        anon_blob = bucket.blob(anon_path)
        anon_blob.upload_from_string(image_bytes, content_type="image/jpeg")

    print(f"[Storage] Uploaded: {path}")
    return blob.public_url


# Gemini vision accepts jpeg/png/webp/heic/heif — normalise anything else to jpeg
_ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}

async def analyze_photo(
    image_bytes: bytes,
    animal_context: str,
    body_part_hint: str = "",
    content_type: str = "image/jpeg",
) -> Dict:
    media_type = content_type if content_type in _ALLOWED_IMAGE_TYPES else "image/jpeg"

    prompt = f"""Siz tajribali veterinarsiz. Bu hayvon rasmini tahlil qiling.

Hayvon ma'lumotlari: {animal_context}
Ko'rib chiqilayotgan qism: {body_part_hint or "Umumiy ko'rik"}

Faqat JSON formatda javob bering (boshqa hech narsa yozmang):
{{
  "visual_findings": "ko'rilgan narsalar batafsil tavsifi",
  "severity": "low/medium/high/emergency",
  "probable_diagnosis": "ehtimoliy tashxis",
  "immediate_actions": ["harakat 1", "harakat 2", "harakat 3"],
  "confidence": 85,
  "which_leg_or_part": "aniq qaysi qism ko'rinmoqda"
}}"""

    response = await client.aio.models.generate_content(
        model=MODEL,
        contents=[
            types.Content(
                role="user",
                parts=[
                    types.Part.from_bytes(data=image_bytes, mime_type=media_type),
                    types.Part(text=prompt),
                ],
            )
        ],
        config=types.GenerateContentConfig(
            max_output_tokens=1024,
            response_mime_type="application/json",
            **_THINKING_OFF,
        ),
    )

    text = response.text or ""
    clean = text.replace("```json", "").replace("```", "").strip()
    try:
        return json.loads(clean)
    except json.JSONDecodeError:
        print(f"[Storage] JSON parse failed, raw: {text[:200]}")
        return {
            "visual_findings": text,
            "severity": "medium",
            "probable_diagnosis": "Tahlil xatosi — rasmni qayta yuboring",
            "immediate_actions": ["Rasmni aniqroq yuboring", "Hayvonni yaqindan ko'ring"],
            "confidence": 0,
            "which_leg_or_part": body_part_hint or "noma'lum",
        }

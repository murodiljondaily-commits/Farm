import base64
import io
import os
import json
from datetime import datetime, timezone
from typing import Optional, Dict

import anthropic
from firebase_admin import storage as fb_storage
from PIL import Image, ImageOps
import pillow_heif

pillow_heif.register_heif_opener()

_anthropic_client = anthropic.AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", "").strip())
VISION_MODEL = "claude-sonnet-5"
# Switched from GPT-4o-mini: direct A/B on the same test image showed
# GPT-4o-mini confidently fabricating a specific diagnosis (leg, severity,
# 85% confidence) for an image that was actually a synthetic test graphic
# with literal text drawn on it ("test leg wound") — it never noticed the
# image wasn't a real photo. Sonnet correctly read the text, recognized the
# image as a non-clinical test graphic, and gave low confidence instead of
# inventing specifics. For a vet-advice product, that calibration difference
# matters more than raw speed.


def normalize_to_jpeg(image_bytes: bytes) -> bytes:
    """Decode whatever format the phone's camera actually produced and
    re-encode as guaranteed-real JPEG bytes.

    Many Samsung phones (confirmed: the SM A155F used for live testing) save
    camera photos as HEIC/HEIF by default. The Flutter client was labeling
    every upload as image/jpeg regardless of the real format — vision APIs
    (tested against OpenAI's; Claude's accepts the same jpeg/png/gif/webp
    set) only accept a small set of real image formats and correctly reject
    real HEIC bytes even when mislabeled (confirmed via direct testing: 400
    invalid_image_format). Decoding through Pillow (with the HEIF opener
    registered) removes any dependency on the client's declared content-type
    being accurate, and also fixes camera-rotation EXIF handling.

    Falls back to the original bytes on failure so a truly-corrupt upload
    fails the same way it did before this normalization existed, rather than
    a new, different way.
    """
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img = ImageOps.exif_transpose(img)
        if img.mode != "RGB":
            img = img.convert("RGB")
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=90)
        return buf.getvalue()
    except Exception as exc:
        print(f"[Storage] Image normalization failed, using original bytes: {exc}")
        return image_bytes


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


async def analyze_photo(
    image_bytes: bytes,
    animal_context: str,
    body_part_hint: str = "",
) -> Dict:
    # Caller (main.py's /diagnose-photo) always passes bytes through
    # normalize_to_jpeg first, so this is always genuinely image/jpeg.
    media_type = "image/jpeg"

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

    b64_image = base64.b64encode(image_bytes).decode("ascii")

    try:
        response = await _anthropic_client.messages.create(
            model=VISION_MODEL,
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {"type": "base64", "media_type": media_type, "data": b64_image},
                        },
                        {"type": "text", "text": prompt},
                    ],
                }
            ],
        )
    except Exception as exc:
        print(f"[Storage] Claude Sonnet vision call failed: {exc}")
        raise

    text = "".join(b.text for b in response.content if getattr(b, "type", None) == "text")
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

import os
import json
import re
import uuid
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from google import genai
from google.genai import types

import firestore_db
from context_builder import build_farm_context
from tools import (
    get_farm_stats,
    get_all_animals_tool,
    get_animal_tool,
    get_animal_full_record_tool,
    add_health_case,
    update_animal_status,
    update_animal_info,
    log_vaccination,
    log_bulk_vaccination,
    log_weight,
    log_milk,
    get_animal_history_tool,
    search_rag_tool,
    close_case,
    add_photo_to_case,
    append_case_symptoms,
    get_active_cases_tool,
    record_event_tool,
)

# gemini-2.5-flash-lite has "thinking" OFF by default (unlike 2.5-flash, where
# it's on and burns the whole output-token budget → empty replies). We cannot
# disable 2.5-flash thinking here because google-auth==2.36.0 caps google-genai
# at ~1.2.0, whose ThinkingConfig lacks thinking_budget. Flash-Lite sidesteps
# that entirely and is a fast, available model. (gemini-2.0-flash is retired.)
MODEL = "gemini-2.5-flash-lite"

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY", "").strip())


def _thinking_off_kwargs() -> Dict[str, Any]:
    """Kwargs to disable 2.5-flash 'thinking'. Gemini 2.5 thinks by default and
    can spend the whole output-token budget on hidden thoughts, returning an
    EMPTY response.text (the "javob tayyorlab bo'lmadi" fallback). Disabling it
    keeps this a fast tool-calling agent. Built defensively: older google-genai
    versions whose ThinkingConfig lacks `thinking_budget` must NOT 500 every
    request — in that case we simply omit it."""
    try:
        return {"thinking_config": types.ThinkingConfig(thinking_budget=0)}
    except Exception as exc:  # pragma: no cover - depends on installed SDK
        print(f"[Agent] thinking disable unsupported by SDK, leaving default: {exc}")
        return {}


_THINKING_OFF = _thinking_off_kwargs()


def _as_response_dict(result: Any) -> Dict:
    """Gemini function responses must be JSON objects. Sanitise (datetimes etc.)
    via a json round-trip and wrap any non-dict return so it is always a dict."""
    try:
        safe = json.loads(json.dumps(result, ensure_ascii=False, default=str))
    except Exception:
        safe = {"result": str(result)}
    return safe if isinstance(safe, dict) else {"result": safe}

ALL_TOOLS = [
    {
        "name": "get_farm_stats",
        "description": "Fermaning umumiy statistikasini olish: hayvonlar soni, faol kasalliklar, muddati o'tgan emlashlar",
        "input_schema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "get_all_animals",
        "description": "Ferma hayvonlarining to'liq ro'yxatini olish. Tur yoki holat bo'yicha filtrlash mumkin",
        "input_schema": {
            "type": "object",
            "properties": {
                "species": {"type": "string", "description": "Hayvon turi (masalan: sigir, qo'y)"},
                "status": {"type": "string", "description": "Holat filtri"},
            },
            "required": [],
        },
    },
    {
        "name": "get_animal",
        "description": "Quloq raqami yoki ism bo'yicha hayvonning asosiy ma'lumotlarini olish",
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string", "description": "Quloq raqami yoki hayvon ismi"},
            },
            "required": ["ear_tag"],
        },
    },
    {
        "name": "get_animal_full_record",
        "description": (
            "Hayvonning BARCHA ma'lumotlarini bir chaqiruvda olish: joriy holat, "
            "ochiq va yopilgan kasallik tarixi, emlashlar, vazn tarixchasi, asosiy ma'lumotlar. "
            "Hayvon haqida har qanday savol yoki yozish amalidan (holat, kasallik, emlash, vazn) OLDIN "
            "albatta shu toolni chaqiring — taxmin qilmang, haqiqiy ma'lumotdan foydalaning."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string", "description": "Quloq raqami yoki ism"},
            },
            "required": ["ear_tag"],
        },
    },
    {
        "name": "add_health_case",
        "description": "Hayvon kasalligi holatini ochish va ma'lumotlar bazasiga saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string"},
                "symptoms": {"type": "array", "items": {"type": "string"}, "description": "Belgilar ro'yxati"},
                "body_part": {"type": "string", "description": "Ta'sirlangan tana qismi"},
                "severity": {"type": "string", "enum": ["low", "medium", "high", "emergency"]},
                "ai_diagnosis": {"type": "string", "description": "AI tashxisi"},
                "confidence": {"type": "integer", "description": "Ishonch darajasi 0-100"},
                "first_aid": {"type": "array", "items": {"type": "string"}, "description": "Darhol choralar"},
                "photo_urls": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["ear_tag", "symptoms", "body_part", "severity", "ai_diagnosis", "confidence", "first_aid"],
        },
    },
    {
        "name": "update_animal_status",
        "description": "Hayvon holatini yangilash",
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string"},
                "new_status": {"type": "string", "enum": ["sog'lom", "davolanmoqda", "kritik", "oldi", "soyildi"]},
            },
            "required": ["ear_tag", "new_status"],
        },
    },
    {
        "name": "update_animal_info",
        "description": (
            "Hayvonning asosiy ma'lumotlarini yangilash: homiladorlik holati/oyi, ism, zot, "
            "tug'ilgan sana, jins, yosh (oyda). "
            "Holat (sog'lom/davolanmoqda/kritik) o'zgartirish uchun update_animal_status ishlating. "
            "Ikkisi bir vaqtda kerak bo'lsa — IKKALA toolni BITTA javobda chaqiring."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string"},
                "pregnancy_status": {
                    "type": "string",
                    "enum": ["pregnant", "not_pregnant", "unknown"],
                    "description": "Homiladorlik holati",
                },
                "pregnancy_month": {
                    "type": "number",
                    "description": "Homiladorlik oyi (masalan: 3.5)",
                },
                "name": {"type": "string", "description": "Hayvon ismi"},
                "breed": {"type": "string", "description": "Zot"},
                "dob": {"type": "string", "description": "Tug'ilgan sana YYYY-MM-DD"},
                "sex": {"type": "string", "enum": ["male", "female"]},
                "age_months": {"type": "integer", "description": "Yosh oyda"},
            },
            "required": ["ear_tag"],
        },
    },
    {
        "name": "log_vaccination",
        "description": "Emlash ma'lumotlarini saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string"},
                "vaccine_name": {"type": "string"},
                "date": {"type": "string", "description": "YYYY-MM-DD"},
                "next_due": {"type": "string", "description": "Keyingi emlash sanasi YYYY-MM-DD"},
            },
            "required": ["ear_tag", "vaccine_name", "date"],
        },
    },
    {
        "name": "log_bulk_vaccination",
        "description": (
            "Bir vaqtda BIR NECHTA hayvonni emlaymiz — bitta operatsiyada. "
            "Foydalanuvchi ro'yxatini tasdiqlagan va vaksina ma'lumotlari olgandan KEYIN chaqiring. "
            "ear_tags — quloq raqamlari ro'yxati."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tags": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Quloq raqamlari ro'yxati",
                },
                "vaccine_name": {"type": "string"},
                "date": {"type": "string", "description": "YYYY-MM-DD"},
                "next_due": {"type": "string", "description": "Keyingi emlash sanasi YYYY-MM-DD"},
            },
            "required": ["ear_tags", "vaccine_name", "date"],
        },
    },
    {
        "name": "log_weight",
        "description": "Hayvon vaznini saqlash va o'zgarishni kuzatish",
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string"},
                "weight_kg": {"type": "number"},
            },
            "required": ["ear_tag", "weight_kg"],
        },
    },
    {
        "name": "log_milk",
        "description": "Sut miqdorini qayd etish",
        "input_schema": {
            "type": "object",
            "properties": {
                "liters": {"type": "number"},
                "session": {"type": "string", "enum": ["ertalab", "kechqurun"]},
            },
            "required": ["liters", "session"],
        },
    },
    {
        "name": "get_animal_history",
        "description": "Hayvonning to'liq tarixini olish: kasalliklar, emlashlar, vazn o'zgarishlari",
        "input_schema": {
            "type": "object",
            "properties": {
                "ear_tag": {"type": "string"},
            },
            "required": ["ear_tag"],
        },
    },
    {
        "name": "search_rag",
        "description": "O'xshash kasallik holatlarini bazadan qidirish va davolash tavsiyalarini olish",
        "input_schema": {
            "type": "object",
            "properties": {
                "species": {"type": "string"},
                "symptoms_list": {"type": "array", "items": {"type": "string"}},
                "body_part": {"type": "string"},
            },
            "required": ["species", "symptoms_list"],
        },
    },
    {
        "name": "close_case",
        "description": "Kasallik holatini yopish. FAQAT barcha maydonlar to'ldirilgandan keyin chaqiring: outcome, recovery_days (tuzaldi/yomonlashdi uchun), vet_confirmed.",
        "input_schema": {
            "type": "object",
            "properties": {
                "case_id": {"type": "string"},
                "outcome": {"type": "string", "enum": ["tuzaldi", "yomonlashdi", "o'ldi", "boshqa joyga yuborildi"]},
                "recovery_days": {"type": "integer", "description": "Necha kunda tuzaldi — FAQAT tuzaldi yoki yomonlashdi uchun"},
                "vet_confirmed": {"type": "boolean"},
                "vet_notes": {"type": "string"},
            },
            "required": ["case_id", "outcome"],
        },
    },
    {
        "name": "add_photo_to_case",
        "description": "Kasallik holatiga rasm qo'shish va vizual topilmalarni saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "case_id": {"type": "string"},
                "photo_url": {"type": "string"},
                "visual_findings": {"type": "string"},
            },
            "required": ["case_id", "photo_url", "visual_findings"],
        },
    },
    {
        "name": "get_active_cases",
        "description": "Fermadagi barcha faol (yopilmagan) kasallik holatlarini olish",
        "input_schema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "append_case_symptoms",
        "description": "Mavjud ochiq kasallik holatiga yangi belgilar qo'shish. add_health_case already_open=true qaytarganida foydalaning.",
        "input_schema": {
            "type": "object",
            "properties": {
                "case_id": {"type": "string"},
                "new_symptoms": {"type": "array", "items": {"type": "string"}},
                "updated_severity": {"type": "string", "description": "Yangi og'irlik darajasi (ixtiyoriy): low/medium/high/emergency"},
                "notes": {"type": "string", "description": "Qo'shimcha klinik izoh (ixtiyoriy)"},
            },
            "required": ["case_id", "new_symptoms"],
        },
    },
    {
        "name": "record_event",
        "description": "Istalgan voqeani qayd etish (tug'ilish, o'lim, ko'chirish va boshqalar)",
        "input_schema": {
            "type": "object",
            "properties": {
                "event_type": {"type": "string"},
                "data": {"type": "object"},
                "ear_tag": {"type": "string"},
            },
            "required": ["event_type", "data"],
        },
    },
]

def _to_gemini_declaration(tool: Dict) -> Dict:
    """Convert an Anthropic-style tool (name/description/input_schema) into a
    Gemini FunctionDeclaration dict. Tools with no parameters omit `parameters`
    entirely — Gemini rejects an OBJECT schema with empty properties."""
    schema = tool.get("input_schema", {})
    props = schema.get("properties", {})
    decl: Dict[str, Any] = {
        "name": tool["name"],
        "description": tool["description"],
    }
    if props:
        params: Dict[str, Any] = {"type": "object", "properties": props}
        if schema.get("required"):
            params["required"] = schema["required"]
        decl["parameters"] = params
    return decl


# Gemini expects tools grouped under a single Tool with function_declarations.
GEMINI_TOOLS = [
    types.Tool(function_declarations=[_to_gemini_declaration(t) for t in ALL_TOOLS])
]


# Tools that require farm_id injected server-side
_TOOLS_WITH_FARM_ID = {
    "get_farm_stats", "get_all_animals", "get_animal", "get_animal_full_record",
    "add_health_case", "update_animal_status", "update_animal_info",
    "log_vaccination", "log_bulk_vaccination", "log_weight",
    "log_milk", "get_animal_history", "close_case", "add_photo_to_case",
    "append_case_symptoms", "get_active_cases", "record_event", "search_rag",
}

# Tools that look up / pin an animal on successful return
_ANIMAL_LOOKUP_TOOLS = {"get_animal", "get_animal_full_record"}

# Only truly destructive actions go through the confirmation queue.
# Routine clinical writes (health cases, vaccinations, weights, events) execute silently.
_WRITE_TOOLS_REQUIRE_CONFIRM = {"close_case"}

# Status values that are irreversible — always require confirmation
_DESTRUCTIVE_STATUSES = {"oldi", "soyildi"}

TOOL_MAP = {
    "get_farm_stats": get_farm_stats,
    "get_all_animals": get_all_animals_tool,
    "get_animal": get_animal_tool,
    "get_animal_full_record": get_animal_full_record_tool,
    "add_health_case": add_health_case,
    "update_animal_status": update_animal_status,
    "update_animal_info": update_animal_info,
    "log_vaccination": log_vaccination,
    "log_bulk_vaccination": log_bulk_vaccination,
    "log_weight": log_weight,
    "log_milk": log_milk,
    "get_animal_history": get_animal_history_tool,
    "search_rag": search_rag_tool,
    "close_case": close_case,
    "add_photo_to_case": add_photo_to_case,
    "append_case_symptoms": append_case_symptoms,
    "get_active_cases": get_active_cases_tool,
    "record_event": record_event_tool,
}

# ── Phase 1: propose → confirm → execute ──────────────────────────────────────
# READ tools run immediately and return data. Everything else MUTATES state and
# must NOT auto-run — it is returned to the app as a proposed_action, and only
# executed when the user taps Confirm (→ POST /confirm-action).
READ_TOOLS = {
    "get_farm_stats", "get_all_animals", "get_animal", "get_animal_full_record",
    "get_animal_history", "get_active_cases", "search_rag",
}
WRITE_TOOLS = set(TOOL_MAP) - READ_TOOLS


def _affected_animals(name: str, inputs: Dict) -> List[str]:
    """Ear tags a proposed write would touch (for the confirm card)."""
    if name == "log_bulk_vaccination":
        return [str(t) for t in (inputs.get("ear_tags") or [])]
    tag = inputs.get("ear_tag")
    return [str(tag)] if tag else []


def _action_summary(name: str, inputs: Dict, affected: List[str]) -> str:
    """Short, plain-Uzbek one-liner describing the pending action for the card."""
    n = len(affected)
    date = inputs.get("date", "bugun")
    if name == "log_bulk_vaccination":
        return f"{n} ta hayvonni {inputs.get('vaccine_name', '?')} bilan emlash ({date})."
    if name == "log_vaccination":
        return f"{inputs.get('ear_tag', '?')} — {inputs.get('vaccine_name', '?')} emlash ({date})."
    if name == "add_health_case":
        what = inputs.get("ai_diagnosis") or ", ".join(inputs.get("symptoms", []) or []) or "yangi holat"
        return f"{inputs.get('ear_tag', '?')} uchun kasallik holati: {what}."
    if name == "update_animal_status":
        return f"{inputs.get('ear_tag', '?')} holatini '{inputs.get('new_status', '?')}' ga o'zgartirish."
    if name == "update_animal_info":
        return f"{inputs.get('ear_tag', '?')} ma'lumotlarini yangilash."
    if name == "log_weight":
        return f"{inputs.get('ear_tag', '?')} vazni: {inputs.get('weight_kg', '?')} kg."
    if name == "log_milk":
        return f"Sut: {inputs.get('liters', '?')} litr ({inputs.get('session', '?')})."
    if name == "close_case":
        return f"Kasallik holatini yopish (natija: {inputs.get('outcome', '?')})."
    if name == "record_event":
        return f"Voqea qayd etish: {inputs.get('event_type', '?')}."
    if name == "add_photo_to_case":
        return f"{inputs.get('ear_tag', '?')} holatiga rasm qo'shish."
    if name == "append_case_symptoms":
        return "Kasallik holatiga yangi belgilar qo'shish."
    return f"{name} amalini bajarish."


# Phase 3: fields Sonya MUST have before proposing a write. If missing, she asks
# the farmer in plain text first (no card until complete). Only fields a farmer
# would actually forget — targeting + the key value — are listed; date defaults
# to today.
_REQUIRED_FIELDS = {
    "log_vaccination": ["ear_tag", "vaccine_name"],
    "log_bulk_vaccination": ["ear_tags", "vaccine_name"],
    "log_weight": ["ear_tag", "weight_kg"],
    "log_milk": ["liters"],
    "update_animal_status": ["ear_tag", "new_status"],
    "close_case": ["case_id", "outcome"],
}


def _missing_required(name: str, inputs: Dict) -> List[str]:
    missing = []
    for f in _REQUIRED_FIELDS.get(name, []):
        v = inputs.get(f)
        if v is None or (isinstance(v, str) and not v.strip()) or (isinstance(v, (list, dict)) and not v):
            missing.append(f)
    return missing


# Phase 4: pull Sonya's confidence % out of her prose so the app can render it as
# a styled badge instead of inline text. Only strips confidence-labelled numbers
# (never a clinical figure like "10% suvsizlanish").
_CONF_FIND = [
    re.compile(r'ishonch(?:\s*daraja\w*)?\s*[:\-]?\s*(\d{1,3})\s*%', re.IGNORECASE),
    re.compile(r'(\d{1,3})\s*%\s*ishonch', re.IGNORECASE),
    re.compile(r'уверенност\w*\s*[:\-]?\s*(\d{1,3})\s*%', re.IGNORECASE),
    re.compile(r'confidence\s*[:\-]?\s*(\d{1,3})\s*%', re.IGNORECASE),
]
_CONF_STRIP = [
    re.compile(r'[\(\[]?\s*ishonch(?:\s*daraja\w*)?\s*[:\-]?\s*\d{1,3}\s*%\s*[\.\)\]]?', re.IGNORECASE),
    re.compile(r'[\(\[]?\s*\d{1,3}\s*%\s*ishonch\w*\s*[\.\)\]]?', re.IGNORECASE),
    re.compile(r'[\(\[]?\s*уверенност\w*\s*[:\-]?\s*\d{1,3}\s*%\s*[\.\)\]]?', re.IGNORECASE),
    re.compile(r'[\(\[]?\s*confidence\s*[:\-]?\s*\d{1,3}\s*%\s*[\.\)\]]?', re.IGNORECASE),
]


def _extract_confidence(text: str):
    conf = None
    for pat in _CONF_FIND:
        m = pat.search(text)
        if m:
            conf = max(0, min(100, int(m.group(1))))
            break
    if conf is None:
        return text, 0
    clean = text
    for pat in _CONF_STRIP:
        clean = pat.sub('', clean)
    clean = re.sub(r'\s{2,}', ' ', clean).strip()
    clean = clean.strip('—-•·:；;, ').strip()
    return clean, conf


# ── Confirmation keywords ─────────────────────────────────────────────────────

_CONFIRM_KW = [
    "ha", "ha,", "ha.", "ha!", "xo'p", "xop", "mayli", "bajar",
    "saqlang", "tasdiqlash", "tasdiqlayman", "tasdiq", "ok", "okay",
    "да", "подтверждаю", "подтверждаем", "ладно", "хорошо", "сохрани", "yes",
]


def _is_confirmation(text: str) -> bool:
    lower = text.lower().strip()
    return any(lower == kw or lower.startswith(kw + " ") or lower.startswith(kw + ",")
               for kw in _CONFIRM_KW)


# ── System prompt ─────────────────────────────────────────────────────────────

SYSTEM_BASE = """Siz AgriVet ilovasining "Sonya" — Farg'ona vodiysidan 15 yillik tajribali veterinar va ferma menejeri.

Sizning vazifangiz:
1. Fermer aytgan har bir so'zni JIDDIY qabul qiling
2. Hayvon muammosi haqida eshitsangiz — avval get_animal_full_record chaqiring, keyin harakat qiling
3. Fermer hayvon muammosini TASVIRLASA — darhol klinik harakatlar boshla, buyruq yoki tasdiq kutma
4. Fermer "Men vetman/doktorman" desa — VET REJIMIGA o'ting
5. Javob tili: foydalanuvchi tilini aniqlang (uz/ru) va shu tilda javob bering
6. HECH QACHON "veterinarga murojaat qiling" deb TUGAMANG — SIZ veterinarsiz
7. Ishonch darajangizni DOIM ko'rsating (X%)
8. Favqulodda holatlarda: DARHOL harakatlaning, keyin tushuntiring
9. Amalni (emlash, vazn, holat, kasallik) bajarishdan OLDIN kerakli ma'lumot yetishmasa — masalan vaksina nomi, yangi holat, vazn raqami — AVVAL foydalanuvchidan oddiy tilda SO'RANG. Barcha kerakli ma'lumot to'planganidan KEYINGINA tool chaqiring. Sana aytilmasa "bugun" deb oling.

HAYVON PINNING (MUHIM):
- Suhbat davomida bir hayvon aniqlangandan so'ng, u "pinned" (mahkamlangan) hayvon bo'ladi
- Pinned hayvon: {pinned_animal}
- Agar foydalanuvchi boshqa hayvon nomini aniq keltirmasa, barcha tool calllar pinned hayvon uchun
- Agar foydalanuvchi xira/qisqa javob bersa (faqat ism yoki "u" desa), pinned hayvondan davom eting
- Hayvon o'zgarganda: belgilar/tashxis ma'lumotini TOZALANG — eski hayvon belgilari yangi hayvonga o'tmaydi

KLINIK YONDASHUV — FONDA ISHLAYDIGAN TIZIM (JUDA MUHIM):
Barcha yozuvlar (kasallik ochish, holat yangilash, emlash, vazn) fonda avtomatik saqlanadi.
Siz HECH QACHON foydalanuvchiga buni aytmaysiz. Siz shunchaki vet sifatida gaplashasiz.

TAQIQLANGAN iboralar — bularni HECH QACHON ISHLATMA:
- "Saqlayapman", "Saqlandi", "Qayd etildi", "Tizimga kiritildi"
- "Tasdiqlaysizmi?", "Tasdiqlayman", "Ha deb tasdiqlang"
- "Ma'lumotlar bazasiga yozdim", "Tizimda belgiladim", "Amal bajarildi"

Tool {{"success": true}} yoki {{"case_id": ...}} qaytarsa — klinik suhbatni davom ettir, saqlash haqida HECH NARSA demang.

KASALLIK TRIGGER — add_health_case qachon chaqiriladi:
Fermer hayvon muammosini TASVIRLASA trigger bo'ladi (belgilar, og'riq, o'zgarish, notanish ko'rinish).
TRIGGER EMAS: "sog'lom deb belgilang", "yozib qo'y" — buyruq, klinik tasvir emas.
TRIGGER BO'LADI: "Ko'zi shishib qolibdi", "Yemoqdan to'xtabdi", "Oyog'ini bosmoqda qiynalmoqda"

QAYSI AMALLAR FONDA BAJARILADI:
- add_health_case, update_animal_status (davolanmoqda/kritik), log_vaccination, log_weight, record_event, add_photo_to_case

FAQAT BULAR TASDIQ TALAB QILADI:
- Hayvonni "o'ldi" yoki "soyildi" deb belgilash — aniq so'rang: "Hamroni o'ldi deb belgilayman. Tasdiqlaysizmi?"
- Kasallik holatini yopish (close_case) — quyidagi MAJBURIY tartibni bajar

KASALLIK YOPISH — MAJBURIY TARTIB (close_case dan OLDIN):
Quyidagi iboralar eshitilganda darhol bu tartibni boshlang:
"tuzalib ketdi", "yaxshi bo'ldi", "sog'aydi", "o'ldi", "soyildi",
"boshqa joyga yubordik", "o'tib ketdi", "davolab bo'ldik", "tuzaldi"

1-QADAM: Natijani so'rang — faqat bulardan birini:
"Natija qanday? Tuzaldimi, yomonlashdimi, o'ldimi yoki boshqa joyga yuborildimi?"

2-QADAM: Faqat "tuzaldi" yoki "yomonlashdi" uchun so'rang:
"Necha kunda tuzaldi?" — o'ldi yoki boshqa yuborildi uchun BU SAVOLNI SO'RAMA

3-QADAM: "Doktor tasdiqladi: ha yoki yo'q?"

4-QADAM (ixtiyoriy): "Qo'shimcha izoh bor bo'lsa ayting."

Barcha majburiy javoblar olingandan KEYIN close_case() chaqiring:
close_case(case_id=..., outcome=..., recovery_days=..., vet_confirmed=...)

MUHIM: close_case() ni to'liq ma'lumot bo'lmay CHAQIRMANG.

MA'LUMOT O'QISH VA KASALLIK OCHISH TARTIBI:
- Avval get_animal_full_record — taxmin qilmang
- active_cases mavjud bo'lsa — YANGI case OCHMANG, add_photo_to_case bilan ma'lumot qo'shing
- Yangi kasallik bo'lsa — AVVAL search_rag (species + symptoms_list), KEYIN add_health_case
- search_rag natija topsa — "O'xshash holatda..." deb tabiiy tilda xabarlang

HOMILADORLIK VA MA'LUMOT YANGILASH:
- Hayvon homiladorlik holati/oyi, ismi, zoti, jinsi, yoshi o'zgarganda: update_animal_info ishlating
- Holat (sog'lom/davolanmoqda/kritik) o'zgarganda: update_animal_status ishlating
- Bir vaqtda ham holat ham homiladorlik (yoki boshqa maydon) o'zgarsa: IKKALA toolni BITTA javobda chaqiring — ikkalasi ham fonda bajariladi

OMMAVIY EMLASH (MUHIM):
- Foydalanuvchi ko'p hayvonni emlash haqida aytsa (masalan: "hammasini emladim", "qo'ylardan boshqasini", "sigirlarni"):
  1. get_all_animals chaqirib hayvonlar ro'yxatini oling (kerak bo'lsa species filtri bilan)
  2. Mos hayvonlar ro'yxatini ko'rsating: "Bu hayvonlarga qo'llayman: [ism (quloq)], ... — to'g'rimi?"
  3. Foydalanuvchi tasdiqlasa — vaksina nomi va sanasini so'rang
  4. Ma'lumotlar olgach — log_bulk_vaccination chaqiring (fonda bajariladi)
  5. Klinik tarzda xabarlang: "N ta hayvonga [vaksina] qo'yildi. Keyingi emlash [sana]."
- "Boshqa hammasini" iborasi uchun: barcha hayvonlarni oling, keyin istisno turlarini chiqarib tashlang

MUHIM CHEKLOVLAR:
- Foydalanuvchidan HECH QACHON farm kodi, farm ID, foydalanuvchi ID yoki login ma'lumotlarini so'ramang
- Hayvon ID sifatida faqat FARM KONTEKSTI bo'limidagi quloq raqamlaridan foydalaning
- HECH QACHON "tizimda texnik muammo", "xatolik yuz berdi", "texnik nosozlik" kabi iboralar ISHLATMANG
- Tool natijasida {{"found": false}} bo'lsa: aniq ayting va foydalanuvchidan aniqlang
- Tool natijasida {{"success": false}} bo'lsa: "Saqlashda muammo bo'ldi, qayta urinib ko'ring" deng

TIL QOIDALARI — JUDA MUHIM:
Lotin tibbiy terminlar, ilmiy nomlar va klinik jargon MUTLAQO TAQIQLANGAN.
Farg'ona vodiysi fermeri tushunadigan oddiy o'zbek tilida yoz.

TAQIQLANGAN → ODDIY O'ZBEK:
Necrobacillosis, Fusobacterium → tuyoq chirishi
Ekzuberant granulatsiya → yaradagi ortiqcha go'sht
Chronic laminitis → uzoq vaqt e'tiborsiz qolgan tuyoq
Anaerob infeksiya → yopiq yaraning ichki infeksiyasi
Sepsis → qon zaharlanishi
Necrotic tissue → chirib ketgan go'sht
Mastitis → yelim yallig'lanishi
Pneumonia → o'pka kasalligi
Ketosis → qondagi shakar pasayishi
Bloat / Tympany → qorin shishi, gaz

HECH QACHON: lotin so'zlar, ilmiy nomlar, dori brand nomlari
DOIM: oddiy so'zlar, aniq amallar, fermer tushunadi

JAVOB FORMATI (MUHIM):
- Javoblar qisqa va aniq bo'lsin — 3-5 jumladan oshmasin
- HECH QACHON markdown belgilari ishlatmang: ** (bold), * (italic), - (bullet), # (sarlavha), | (jadval)
- Ko'p bo'sh qator qoldirmang
- Faqat oddiy matn va kerak bo'lsa raqamlangan ro'yxat (1. 2. 3.) ishlating
- Mobil chatda o'qish oson bo'lishi kerak — markdown belgilari ekranda harf sifatida ko'rinadi

FARM KONTEKSTI:
{farm_context}

VET REJIMI: {vet_mode}
FOYDALANUVCHI ROLI: {user_role}"""

VET_MODE_SUFFIX = """

VET REJIMI FAOL
Siz hozir ferma veterinariga to'liq hisobot berasiz. Qisqa professional format:

KRITIK HOLATLAR: [ro'yxat — sanalar, belgilar]
FAOL KASALLIKLAR: [ro'yxat — to'liq tarix bilan]
DIQQAT TALAB ETADI: [muddati o'tgan emlashlar, vazn pasayishi]
STATISTIKA (oxirgi 30 kun): [ochilgan/yopilgan holatlar]
DORI-DARMON TAVSIYALARI: [hozirgi faol holatlarga asoslanib]"""

EMERGENCY_KW = [
    "qon oqmoqda", "yiqilib qoldi", "nafas olmayapti",
    "tutqanoq", "tez yordam", "o'lmoqda", "halok",
    "кровотечение", "не дышит", "судороги", "умирает", "срочно",
]
VET_ON_KW = [
    "men vetman", "men doktorman", "men duxturman",
    "я ветеринар", "я врач",
]
VET_OFF_KW = [
    "rahmat doktor", "doktor ketdi", "men fermerman",
    "chiqish", "vet chiqish", "я фермер",
]


async def _execute_tool(name: str, inputs: Dict, farm_id: str) -> Any:
    fn = TOOL_MAP.get(name)
    if not fn:
        return {"success": False, "message": f"Noma'lum tool: {name}"}
    try:
        if name in _TOOLS_WITH_FARM_ID:
            inputs = {**inputs, "farm_id": farm_id}
        print(f"[Tool] → {name}({json.dumps(inputs, ensure_ascii=False)[:150]})")
        result = await fn(**inputs)
        print(f"[Tool] ← {name}: {str(result)[:150]}")
        return result
    except Exception as exc:
        print(f"[Tool] ERROR {name}: {exc}")
        msg = str(exc)
        if "not found" in msg.lower() or "no document" in msg.lower():
            return {"found": False, "message": "Topilmadi"}
        if "permission" in msg.lower() or "unauthorized" in msg.lower():
            return {"success": False, "message": "Ruxsat yo'q"}
        return {"success": False, "message": "Amal bajarilmadi"}


async def run_agent(
    farm_id: str,
    user_message: str,
    conversation_id: Optional[str],
    user_role: str,
    vet_mode: bool,
) -> Dict:
    if not conversation_id:
        conversation_id = uuid.uuid4().hex[:12]

    print(f"[Agent] run_agent farm_id={repr(farm_id)} msg={repr(user_message[:60])}")

    # ── Load conversation state (pinned animal + pending writes) ─────────────
    conv_state = await firestore_db.get_conversation_state(farm_id, conversation_id)
    pinned_animal: Optional[str] = conv_state.get("pinned_animal")
    pending_writes: List[Dict] = conv_state.get("pending_writes", [])

    print(f"[Agent] pinned_animal={pinned_animal!r}  pending_writes_count={len(pending_writes)}")

    # ── Build context and history ─────────────────────────────────────────────
    context = await build_farm_context(farm_id)
    raw_history = await firestore_db.get_conversation_history(farm_id, conversation_id, limit=10)
    # Gemini uses role "model" (not "assistant") and Content/Part objects.
    contents: List[Any] = []
    for m in raw_history:
        role = m.get("role")
        text = m.get("content") or ""
        if role == "user":
            contents.append(types.Content(role="user", parts=[types.Part(text=text)]))
        elif role == "assistant":
            contents.append(types.Content(role="model", parts=[types.Part(text=text)]))

    pinned_label = pinned_animal if pinned_animal else "Hali aniqlanmagan"
    system_prompt = SYSTEM_BASE.format(
        farm_context=context,
        pinned_animal=pinned_label,
        vet_mode="FAOL" if vet_mode else "O'CHIQ",
        user_role=user_role,
    )
    if vet_mode:
        system_prompt += VET_MODE_SUFFIX

    # ── Emergency detection ───────────────────────────────────────────────────
    msg_lower = user_message.lower()
    is_emergency = any(kw in msg_lower for kw in EMERGENCY_KW)
    if is_emergency:
        user_message = f"FAVQULODDA: {user_message}"

    # ── Handle pending writes confirmation / cancellation ────────────────────
    data_saved: Dict[str, Any] = {}

    if pending_writes:
        if _is_confirmation(user_message) or is_emergency:
            # Execute ALL pending writes now that user confirmed
            results_summary = []
            for pw in pending_writes:
                tool_name = pw["name"]
                tool_inputs = pw["inputs"]
                print(f"[Agent] Executing confirmed pending write [{len(results_summary)+1}/{len(pending_writes)}]: {tool_name}({json.dumps(tool_inputs, ensure_ascii=False)[:80]})")
                result = await _execute_tool(tool_name, tool_inputs, farm_id)
                data_saved[tool_name] = result
                results_summary.append(
                    f"'{tool_name}': {json.dumps(result, ensure_ascii=False, default=str)}"
                )
                print(f"[Agent] Confirmed write result: {str(result)[:120]}")

            # Clear ALL pending writes
            await firestore_db.update_conversation_state(
                farm_id, conversation_id, {"pending_writes": []}
            )
            print(f"[Agent] Cleared pending_writes after executing {len(pending_writes)} writes")

            # Inject all results into user message so AI formats a good response
            user_message = (
                f"{user_message}\n\n"
                f"[TIZIM: Foydalanuvchi {len(pending_writes)} ta amalni tasdiqladi. "
                f"Natijalar: {'; '.join(results_summary)}. "
                f"Foydalanuvchiga nima o'zgarganini qisqa xabarlang.]"
            )
        else:
            # User sent something that's not a confirmation — cancel all pending writes
            names = [pw.get("name") for pw in pending_writes]
            print(f"[Agent] Cancelling pending writes (no confirmation): {names}")
            await firestore_db.update_conversation_state(
                farm_id, conversation_id, {"pending_writes": []}
            )
            pending_writes = []

    contents.append(types.Content(role="user", parts=[types.Part(text=user_message)]))

    tools_called_names: List[str] = []

    gen_config = types.GenerateContentConfig(
        system_instruction=system_prompt,
        tools=GEMINI_TOOLS,
        temperature=0.7,
        max_output_tokens=4096,
        # Disable "thinking" (see _thinking_off_kwargs) so the model spends its
        # output budget on the actual reply, not hidden thoughts.
        **_THINKING_OFF,
        # Manual tool loop — we intercept writes for confirmation ourselves.
        automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True),
        tool_config=types.ToolConfig(
            function_calling_config=types.FunctionCallingConfig(mode="AUTO")
        ),
    )

    # ── Agent loop ────────────────────────────────────────────────────────────
    proposed_actions: List[Dict[str, Any]] = []
    response = await client.aio.models.generate_content(
        model=MODEL, contents=contents, config=gen_config
    )
    print(f"[Agent] initial function_calls={len(response.function_calls or [])}")

    _loop_guard = 0
    while response.function_calls and _loop_guard < 8:
        _loop_guard += 1
        function_calls = list(response.function_calls)
        n_proposed_this_turn = 0
        n_executed_this_turn = 0
        print(f"[Agent] function_calls in this turn: {len(function_calls)} "
              f"({[fc.name for fc in function_calls]})")

        # Persist the model's function-call turn so the follow-up call has context.
        if response.candidates and response.candidates[0].content:
            contents.append(response.candidates[0].content)

        fr_parts = []
        for fc in function_calls:
            name = fc.name
            tools_called_names.append(name)
            inputs = dict(fc.args or {})

            # ── Auto-inject pinned animal into ear_tag if AI omitted it ─────
            if (
                pinned_animal
                and "ear_tag" not in inputs
                and name in _TOOLS_WITH_FARM_ID
                and name not in ("get_farm_stats", "get_all_animals", "get_active_cases",
                                 "log_milk", "record_event", "search_rag",
                                 "log_bulk_vaccination")
            ):
                inputs["ear_tag"] = pinned_animal
                print(f"[Agent] Auto-injected pinned_animal={pinned_animal!r} into {name}")

            # ── Pin animal from write tool inputs ─────────────────────────────
            tool_ear_tag = inputs.get("ear_tag")
            if tool_ear_tag and tool_ear_tag != pinned_animal:
                pinned_animal = tool_ear_tag
                try:
                    await firestore_db.update_conversation_state(
                        farm_id, conversation_id, {"pinned_animal": pinned_animal}
                    )
                    print(f"[Agent] Pinned animal (from {name} input) → {pinned_animal!r}")
                except Exception as pin_exc:
                    print(f"[Agent] WARNING: Could not save pin for {pinned_animal!r}: {pin_exc}")

            # ── Phase 1+3: PROPOSE writes (after gathering required info) ─────
            if name in WRITE_TOOLS and not is_emergency:
                # Default the vaccination date to today so we don't nag for it.
                if name in ("log_vaccination", "log_bulk_vaccination") and not inputs.get("date"):
                    inputs["date"] = datetime.now(timezone.utc).date().isoformat()

                # Phase 3: if required info is missing, ASK — don't propose yet.
                missing = _missing_required(name, inputs)
                if missing:
                    print(f"[Agent] NEEDS INFO for {name}: {missing} — asking user")
                    result = {
                        "status": "needs_info",
                        "missing": missing,
                        "message": (
                            f"Amal uchun quyidagi ma'lumot yetishmayapti: {', '.join(missing)}. "
                            "Foydalanuvchidan buni oddiy tabiiy tilda SO'RANG. "
                            "Amalni HALI taklif qilmang, TASDIQLASH kartasini chiqarmang."
                        ),
                    }
                else:
                    # Do NOT run the mutation. Return it as a proposed_action so
                    # the app shows a Confirm card; it runs via /confirm-action.
                    affected = _affected_animals(name, inputs)
                    proposed_actions.append({
                        "action": name,
                        "params": inputs,
                        "affected_animals": affected,
                        "summary": _action_summary(name, inputs, affected),
                    })
                    n_proposed_this_turn += 1
                    print(f"[Agent] PROPOSED {name} (affected={len(affected)}) — awaiting UI confirm")
                    result = {
                        "status": "awaiting_confirmation",
                        "message": (
                            "Amal HALI BAJARILMADI — foydalanuvchiga tasdiqlash KARTASI chiqadi. "
                            "Nima qilmoqchi ekaningizni QISQA, bir jumlada, KELASI zamonda ayting "
                            "(masalan: 'h001 vaznini 250 kg qilib yozaman — tasdiqlang'). "
                            "'belgilandi', 'saqlandi', 'bajarildi' kabi O'TGAN zamon SO'ZLARINI ISHLATMANG. "
                            "'saqlab bo'lmadi' yoki 'xatolik' ham DEMANG."
                        ),
                    }
            elif name in WRITE_TOOLS and is_emergency:
                # Emergency (life-threatening): execute immediately, no confirm delay.
                result = await _execute_tool(name, inputs, farm_id)
                n_executed_this_turn += 1
                data_saved[name] = result
            else:
                # READ tool — execute immediately.
                result = await _execute_tool(name, inputs, farm_id)
                n_executed_this_turn += 1

                # ── Auto-pin animal on successful lookup ─────────────────────
                if name in _ANIMAL_LOOKUP_TOOLS and isinstance(result, dict) and result.get("found") is not False:
                    new_pin = result.get("ear_tag")
                    if new_pin and new_pin != pinned_animal:
                        pinned_animal = new_pin
                        try:
                            await firestore_db.update_conversation_state(
                                farm_id, conversation_id, {"pinned_animal": pinned_animal}
                            )
                            print(f"[Agent] Pinned animal (lookup result) → {pinned_animal!r}")
                        except Exception as pin_exc:
                            print(f"[Agent] WARNING: Could not save pin: {pin_exc}")

            fr_parts.append(
                types.Part.from_function_response(
                    name=name, response=_as_response_dict(result)
                )
            )

        print(f"[Agent] Turn summary: {len(function_calls)} detected, "
              f"{n_proposed_this_turn} proposed, {n_executed_this_turn} executed")

        contents.append(types.Content(role="user", parts=fr_parts))
        response = await client.aio.models.generate_content(
            model=MODEL, contents=contents, config=gen_config
        )
        print(f"[Agent] (loop) function_calls={len(response.function_calls or [])} "
              f"proposed_so_far={len(proposed_actions)}")

    final_text = (response.text or "").strip()
    # Phase 4: lift the confidence % out of the prose into a structured field.
    final_text, confidence = _extract_confidence(final_text)
    if not final_text:
        # A proposed action carries its own card, so never show the error
        # fallback next to it (that read as contradictory).
        final_text = ("Quyidagi amalni tasdiqlang:" if proposed_actions
                      else "Kechirasiz, javob tayyorlab bo'lmadi. Qayta urinib ko'ring.")

    await firestore_db.save_conversation_turn(
        farm_id, conversation_id, user_message, final_text, tools_called_names
    )

    # Detect vet mode toggle
    new_vet_mode = vet_mode
    if any(kw in msg_lower for kw in VET_ON_KW):
        new_vet_mode = True
    if any(kw in msg_lower for kw in VET_OFF_KW):
        new_vet_mode = False

    return {
        "response": final_text,
        "vet_mode": new_vet_mode,
        "tools_called": tools_called_names,
        "conversation_id": conversation_id,
        "data_saved": data_saved,
        "proposed_actions": proposed_actions,
        "confidence": confidence,
        "is_emergency": is_emergency,
        "pinned_animal": pinned_animal,
    }

"""Tool schemas and propose/confirm business logic shared by every
orchestration engine (Gemini today, Sonnet from Phase 6 on). Extracted out of
agent.py so claude_orchestrator.py can import these without a circular
import (agent.py's run_agent calls INTO claude_orchestrator.py, so
claude_orchestrator.py must not import back from agent.py).

These are pure schema/business-logic — zero Gemini or Anthropic SDK
dependencies — so both orchestration engines share exactly one definition of
"what a tool call means," rather than risking two drifting copies.
"""
from typing import Any, Dict, List

from tools import (
    get_farm_stats,
    get_all_animals_tool,
    get_animal_tool,
    get_animal_full_record_tool,
    add_health_case,
    update_animal_status,
    update_case_status,
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

# Native Anthropic tool format (name/description/input_schema). agent.py
# converts this to Gemini's FunctionDeclaration shape for its own use.
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
        "name": "update_case_status",
        "description": "Kasallik holatini 'davolanmoqda' deb belgilash (yopish emas — buning uchun close_case ishlating)",
        "input_schema": {
            "type": "object",
            "properties": {
                "case_id": {"type": "string"},
                "status": {"type": "string", "enum": ["open", "davolanmoqda"]},
            },
            "required": ["case_id", "status"],
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

# name (as it appears in ALL_TOOLS/farmer-facing tool calls) -> actual async
# function. Shared by every orchestration engine — one mapping, so Gemini and
# Sonnet call exactly the same business logic.
TOOL_MAP = {
    "get_farm_stats": get_farm_stats,
    "get_all_animals": get_all_animals_tool,
    "get_animal": get_animal_tool,
    "get_animal_full_record": get_animal_full_record_tool,
    "add_health_case": add_health_case,
    "update_animal_status": update_animal_status,
    "update_case_status": update_case_status,
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


# ── Propose → confirm → execute (Phase 1, unchanged from the Gemini engine) ──
# READ tools run immediately and return data. Everything else MUTATES state and
# must NOT auto-run — it is returned to the app as a proposed_action, and only
# executed when the user taps Confirm (→ POST /confirm-action), UNLESS the
# turn is flagged emergency, in which case it executes immediately.
READ_TOOL_NAMES = {
    "get_farm_stats", "get_all_animals", "get_animal", "get_animal_full_record",
    "get_animal_history", "get_active_cases", "search_rag",
}
WRITE_TOOL_NAMES = {t["name"] for t in ALL_TOOLS} - READ_TOOL_NAMES


def _affected_animals(name: str, inputs: Dict) -> List[str]:
    """Ear tags a proposed write would touch (for the confirm card)."""
    if name == "log_bulk_vaccination":
        return [str(t) for t in (inputs.get("ear_tags") or [])]
    tag = inputs.get("ear_tag")
    return [str(tag)] if tag else []


def action_summary(name: str, inputs: Dict, affected: List[str]) -> str:
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
    if name == "update_case_status":
        return f"Kasallik holatini '{inputs.get('status', '?')}' deb belgilash."
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


# Phase 3: fields Sonya MUST have before proposing a write. If missing, she
# asks the farmer in plain text first (no card until complete). Only fields a
# farmer would actually forget — targeting + the key value — are listed; date
# defaults to today.
REQUIRED_FIELDS = {
    "log_vaccination": ["ear_tag", "vaccine_name"],
    "log_bulk_vaccination": ["ear_tags", "vaccine_name"],
    "log_weight": ["ear_tag", "weight_kg"],
    "log_milk": ["liters"],
    "update_animal_status": ["ear_tag", "new_status"],
    "close_case": ["case_id", "outcome"],
    # Only the facts a FARMER must supply — ai_diagnosis/confidence/first_aid
    # are things Sonya generates herself once she has real symptoms. Without
    # this gate a vague report ("X kasal bo'lib qoldi") could produce a
    # fabricated diagnosis instead of one clarifying question.
    "add_health_case": ["ear_tag", "symptoms", "body_part"],
    "update_case_status": ["case_id", "status"],
}


def missing_required(name: str, inputs: Dict) -> List[str]:
    missing = []
    for f in REQUIRED_FIELDS.get(name, []):
        v = inputs.get(f)
        if v is None or (isinstance(v, str) and not v.strip()) or (isinstance(v, (list, dict)) and not v):
            missing.append(f)
    return missing

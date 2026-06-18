import os
import json
import uuid
from typing import Optional, List, Dict, Any

from anthropic import AsyncAnthropic

import firestore_db
from context_builder import build_farm_context
from tools import (
    get_farm_stats,
    get_all_animals_tool,
    get_animal_tool,
    add_health_case,
    update_animal_status,
    log_vaccination,
    log_weight,
    log_milk,
    get_animal_history_tool,
    search_rag_tool,
    close_case,
    add_photo_to_case,
    get_active_cases_tool,
    record_event_tool,
)

client = AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))

ALL_TOOLS = [
    {
        "name": "get_farm_stats",
        "description": "Fermaning umumiy statistikasini olish: hayvonlar soni, faol kasalliklar, muddati o'tgan emlashlar",
        "input_schema": {
            "type": "object",
            "properties": {"farm_id": {"type": "string"}},
            "required": ["farm_id"],
        },
    },
    {
        "name": "get_all_animals",
        "description": "Ferma hayvonlarining to'liq ro'yxatini olish. Tur yoki holat bo'yicha filtrlash mumkin",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "species": {"type": "string", "description": "Hayvon turi (masalan: sigir, qo'y)"},
                "status": {"type": "string", "description": "Holat filtri"},
            },
            "required": ["farm_id"],
        },
    },
    {
        "name": "get_animal",
        "description": "Quloq raqami yoki ism bo'yicha hayvonning to'liq ma'lumotlarini olish",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "ear_tag": {"type": "string", "description": "Quloq raqami yoki hayvon ismi"},
            },
            "required": ["farm_id", "ear_tag"],
        },
    },
    {
        "name": "add_health_case",
        "description": "Hayvon kasalligi holatini ochish va ma'lumotlar bazasiga saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "ear_tag": {"type": "string"},
                "symptoms": {"type": "array", "items": {"type": "string"}, "description": "Belgilar ro'yxati"},
                "body_part": {"type": "string", "description": "Ta'sirlangan tana qismi"},
                "severity": {"type": "string", "enum": ["low", "medium", "high", "emergency"]},
                "ai_diagnosis": {"type": "string", "description": "AI tashxisi"},
                "confidence": {"type": "integer", "description": "Ishonch darajasi 0-100"},
                "first_aid": {"type": "array", "items": {"type": "string"}, "description": "Darhol choralar"},
                "photo_urls": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["farm_id", "ear_tag", "symptoms", "body_part", "severity", "ai_diagnosis", "confidence", "first_aid"],
        },
    },
    {
        "name": "update_animal_status",
        "description": "Hayvon holatini yangilash",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "ear_tag": {"type": "string"},
                "new_status": {"type": "string", "enum": ["sog'lom", "davolanmoqda", "kritik", "oldi", "soyildi"]},
            },
            "required": ["farm_id", "ear_tag", "new_status"],
        },
    },
    {
        "name": "log_vaccination",
        "description": "Emlash ma'lumotlarini saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "ear_tag": {"type": "string"},
                "vaccine_name": {"type": "string"},
                "date": {"type": "string", "description": "YYYY-MM-DD"},
                "next_due": {"type": "string", "description": "Keyingi emlash sanasi YYYY-MM-DD"},
            },
            "required": ["farm_id", "ear_tag", "vaccine_name", "date"],
        },
    },
    {
        "name": "log_weight",
        "description": "Hayvon vaznini saqlash va o'zgarishni kuzatish",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "ear_tag": {"type": "string"},
                "weight_kg": {"type": "number"},
            },
            "required": ["farm_id", "ear_tag", "weight_kg"],
        },
    },
    {
        "name": "log_milk",
        "description": "Sut miqdorini qayd etish",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "liters": {"type": "number"},
                "session": {"type": "string", "enum": ["ertalab", "kechqurun"]},
            },
            "required": ["farm_id", "liters", "session"],
        },
    },
    {
        "name": "get_animal_history",
        "description": "Hayvonning to'liq tarixini olish: kasalliklar, emlashlar, vazn o'zgarishlari",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "ear_tag": {"type": "string"},
            },
            "required": ["farm_id", "ear_tag"],
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
        "description": "Kasallik holatini yopish va natijani saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "case_id": {"type": "string"},
                "outcome": {"type": "string", "description": "Natija: tuzaldi/yomonlashdi/o'ldi"},
                "vet_confirmed": {"type": "boolean"},
                "vet_notes": {"type": "string"},
            },
            "required": ["farm_id", "case_id", "outcome"],
        },
    },
    {
        "name": "add_photo_to_case",
        "description": "Kasallik holatiga rasm qo'shish va vizual topilmalarni saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "case_id": {"type": "string"},
                "photo_url": {"type": "string"},
                "visual_findings": {"type": "string"},
            },
            "required": ["farm_id", "case_id", "photo_url", "visual_findings"],
        },
    },
    {
        "name": "get_active_cases",
        "description": "Fermadagi barcha faol (yopilmagan) kasallik holatlarini olish",
        "input_schema": {
            "type": "object",
            "properties": {"farm_id": {"type": "string"}},
            "required": ["farm_id"],
        },
    },
    {
        "name": "record_event",
        "description": "Istalgan voqeani qayd etish (tug'ilish, o'lim, ko'chirish va boshqalar)",
        "input_schema": {
            "type": "object",
            "properties": {
                "farm_id": {"type": "string"},
                "event_type": {"type": "string"},
                "data": {"type": "object"},
                "ear_tag": {"type": "string"},
            },
            "required": ["farm_id", "event_type", "data"],
        },
    },
]

TOOL_MAP = {
    "get_farm_stats": get_farm_stats,
    "get_all_animals": get_all_animals_tool,
    "get_animal": get_animal_tool,
    "add_health_case": add_health_case,
    "update_animal_status": update_animal_status,
    "log_vaccination": log_vaccination,
    "log_weight": log_weight,
    "log_milk": log_milk,
    "get_animal_history": get_animal_history_tool,
    "search_rag": search_rag_tool,
    "close_case": close_case,
    "add_photo_to_case": add_photo_to_case,
    "get_active_cases": get_active_cases_tool,
    "record_event": record_event_tool,
}

SYSTEM_BASE = """Siz AgriVet ilovasining "Muxlisa" — Farg'ona vodiysidan 15 yillik tajribali veterinar va ferma menejeri.

Sizning vazifangiz:
1. Fermer aytgan har bir so'zni JIDDIY qabul qiling
2. Hayvon muammosi haqida eshitsangiz — DARHOL harakat qiling:
   - Holatni o'zgartiring (kritik/davolanmoqda)
   - Kasallik holati oching
   - Rasm so'rang (agar yuborilmagan bo'lsa)
   - Aniq ko'rsatmalar bering
3. Ma'lumotlarni SO'RAMASDAN saqlang — har bir gap ma'lumot
4. Fermer "Men vetman/doktorman" desa — VET REJIMIGA o'ting
5. Javob tili: foydalanuvchi tilini aniqlang (uz/ru) va shu tilda javob bering
6. HECH QACHON "veterinarga murojaat qiling" deb TUGAMANG — SIZ veterinarsiz
7. Ishonch darajangizni DOIM ko'rsating (X%)
8. Favqulodda holatlarda: DARHOL harakatlaning, keyin tushuntiring

FARM KONTEKSTI:
{farm_context}

VET REJIMI: {vet_mode}
FOYDALANUVCHI ROLI: {user_role}"""

VET_MODE_SUFFIX = """

VET REJIMI FAOL 🩺
Siz hozir ferma veterinariga to'liq hisobot berasiz. Professional format:

🚨 KRITIK HOLATLAR:
[ro'yxat — sanalar, belgilar, rasmlar]

📋 FAOL KASALLIKLAR:
[ro'yxat — to'liq tarix bilan]

⚠️ DIQQAT TALAB ETADI:
[muddati o'tgan emlashlar, vazn pasayishi va h.k.]

📊 STATISTIKA (oxirgi 30 kun):
[ochilgan/yopilgan holatlar, eng ko'p uchragan muammolar]

💊 DORI-DARMON TAVSIYALARI:
[hozirgi faol holatlarga asoslanib]"""

EMERGENCY_KW = [
    "qon oqmoqda", "yiqilib qoldi", "nafas olmayapti",
    "tutqanoq", "tez yordam", "o'lmoqda", "halok",
    "кровотечение", "не дышит", "судороги", "умирает", "срочно",
]
VET_ON_KW = [
    "men vetman", "men doktorman", "men duxturman",
    "vet keldi", "doktor keldi", "я ветеринар", "я врач",
]
VET_OFF_KW = [
    "rahmat doktor", "doktor ketdi", "men fermerman",
    "chiqish", "vet chiqish", "я фермер",
]


async def _execute_tool(name: str, inputs: Dict) -> Any:
    fn = TOOL_MAP.get(name)
    if not fn:
        return {"error": f"Noma'lum tool: {name}"}
    try:
        print(f"[Tool] → {name}({json.dumps(inputs, ensure_ascii=False)[:150]})")
        result = await fn(**inputs)
        print(f"[Tool] ← {name}: {str(result)[:150]}")
        return result
    except Exception as exc:
        print(f"[Tool] ERROR {name}: {exc}")
        return {"error": str(exc)}


async def run_agent(
    farm_id: str,
    user_message: str,
    conversation_id: Optional[str],
    user_role: str,
    vet_mode: bool,
) -> Dict:
    if not conversation_id:
        conversation_id = uuid.uuid4().hex[:12]

    context = await build_farm_context(farm_id)

    raw_history = await firestore_db.get_conversation_history(farm_id, conversation_id, limit=10)
    messages: List[Dict] = [
        {"role": m["role"], "content": m["content"]}
        for m in raw_history
        if m.get("role") in ("user", "assistant")
    ]

    system_prompt = SYSTEM_BASE.format(
        farm_context=context,
        vet_mode="FAOL 🩺" if vet_mode else "O'CHIQ",
        user_role=user_role,
    )
    if vet_mode:
        system_prompt += VET_MODE_SUFFIX

    msg_lower = user_message.lower()
    is_emergency = any(kw in msg_lower for kw in EMERGENCY_KW)
    if is_emergency:
        user_message = f"⚠️ FAVQULODDA: {user_message}"

    messages.append({"role": "user", "content": user_message})

    tools_called_names: List[str] = []
    data_saved: Dict[str, Any] = {}

    response = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=4096,
        system=system_prompt,
        tools=ALL_TOOLS,
        messages=messages,
    )
    print(f"[Agent] stop_reason={response.stop_reason}")

    while response.stop_reason == "tool_use":
        tool_results = []
        assistant_content = response.content

        for block in response.content:
            if block.type == "tool_use":
                tools_called_names.append(block.name)
                result = await _execute_tool(block.name, block.input)
                if block.name in (
                    "add_health_case", "log_vaccination", "log_weight",
                    "log_milk", "record_event", "close_case",
                ):
                    data_saved[block.name] = result
                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": json.dumps(result, ensure_ascii=False, default=str),
                })

        messages = messages + [
            {"role": "assistant", "content": assistant_content},
            {"role": "user", "content": tool_results},
        ]
        response = await client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=4096,
            system=system_prompt,
            tools=ALL_TOOLS,
            messages=messages,
        )
        print(f"[Agent] (loop) stop_reason={response.stop_reason}")

    final_text = "".join(
        block.text for block in response.content if hasattr(block, "text") and block.text
    )
    if not final_text:
        final_text = "Kechirasiz, javob tayyorlab bo'lmadi. Qayta urinib ko'ring."

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
        "is_emergency": is_emergency,
    }

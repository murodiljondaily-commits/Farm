import os
import json
import uuid
from typing import Optional, List, Dict, Any

import httpx
from anthropic import AsyncAnthropic

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
    get_active_cases_tool,
    record_event_tool,
)

client = AsyncAnthropic(
    api_key=os.environ.get("ANTHROPIC_API_KEY", "").strip(),
    http_client=httpx.AsyncClient(
        http2=False,
        timeout=httpx.Timeout(connect=30.0, read=300.0, write=30.0, pool=30.0),
    ),
)

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
        "description": "Kasallik holatini yopish va natijani saqlash",
        "input_schema": {
            "type": "object",
            "properties": {
                "case_id": {"type": "string"},
                "outcome": {"type": "string", "description": "Natija: tuzaldi/yomonlashdi/o'ldi"},
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

# Tools that require farm_id injected server-side
_TOOLS_WITH_FARM_ID = {
    "get_farm_stats", "get_all_animals", "get_animal", "get_animal_full_record",
    "add_health_case", "update_animal_status", "update_animal_info",
    "log_vaccination", "log_bulk_vaccination", "log_weight",
    "log_milk", "get_animal_history", "close_case", "add_photo_to_case",
    "get_active_cases", "record_event", "search_rag",
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
    "get_active_cases": get_active_cases_tool,
    "record_event": record_event_tool,
}

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

Tool {"success": true} yoki {"case_id": ...} qaytarsa — klinik suhbatni davom ettir, saqlash haqida HECH NARSA demang.

KASALLIK TRIGGER — add_health_case qachon chaqiriladi:
Fermer hayvon muammosini TASVIRLASA trigger bo'ladi (belgilar, og'riq, o'zgarish, notanish ko'rinish).
TRIGGER EMAS: "sog'lom deb belgilang", "yozib qo'y" — buyruq, klinik tasvir emas.
TRIGGER BO'LADI: "Ko'zi shishib qolibdi", "Yemoqdan to'xtabdi", "Oyog'ini bosmoqda qiynalmoqda"

QAYSI AMALLAR FONDA BAJARILADI:
- add_health_case, update_animal_status (davolanmoqda/kritik), log_vaccination, log_weight, record_event, add_photo_to_case

FAQAT BULAR TASDIQ TALAB QILADI:
- Hayvonni "o'ldi" yoki "soyildi" deb belgilash — aniq so'rang: "Hamroni o'ldi deb belgilayman. Tasdiqlaysizmi?"
- Kasallik holatini yopish (close_case) — natija, tuzalish kunlari, doktor tasdiqlovi so'rang

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
    messages: List[Dict] = [
        {"role": m["role"], "content": m["content"]}
        for m in raw_history
        if m.get("role") in ("user", "assistant")
    ]

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

    messages.append({"role": "user", "content": user_message})

    tools_called_names: List[str] = []

    # ── Agent loop ────────────────────────────────────────────────────────────
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
        write_intercepted = False

        # Count tool_use blocks for logging
        tool_use_blocks = [b for b in response.content if b.type == "tool_use"]
        n_queued_this_turn = 0
        n_executed_this_turn = 0
        print(f"[Agent] tool_use blocks in this turn: {len(tool_use_blocks)} "
              f"({[b.name for b in tool_use_blocks]})")

        for block in response.content:
            if block.type != "tool_use":
                continue

            tools_called_names.append(block.name)
            inputs = dict(block.input)

            # ── Auto-inject pinned animal into ear_tag if AI omitted it ─────
            if (
                pinned_animal
                and "ear_tag" not in inputs
                and block.name in _TOOLS_WITH_FARM_ID
                and block.name not in ("get_farm_stats", "get_all_animals", "get_active_cases",
                                       "log_milk", "record_event", "search_rag",
                                       "log_bulk_vaccination")
            ):
                inputs["ear_tag"] = pinned_animal
                print(f"[Agent] Auto-injected pinned_animal={pinned_animal!r} into {block.name}")

            # ── Pin animal from write tool inputs ─────────────────────────────
            tool_ear_tag = inputs.get("ear_tag")
            if tool_ear_tag and tool_ear_tag != pinned_animal:
                pinned_animal = tool_ear_tag
                try:
                    await firestore_db.update_conversation_state(
                        farm_id, conversation_id, {"pinned_animal": pinned_animal}
                    )
                    print(f"[Agent] Pinned animal (from {block.name} input) → {pinned_animal!r}")
                except Exception as pin_exc:
                    print(f"[Agent] WARNING: Could not save pin for {pinned_animal!r}: {pin_exc}")

            # ── Intercept write tools: require confirmation ───────────────────
            is_destructive = (
                block.name in _WRITE_TOOLS_REQUIRE_CONFIRM
                or (block.name == "update_animal_status"
                    and inputs.get("new_status") in _DESTRUCTIVE_STATUSES)
            )
            if is_destructive and not is_emergency:
                # Reload current pending_writes from Firestore to avoid overwrite race
                try:
                    current_state = await firestore_db.get_conversation_state(farm_id, conversation_id)
                    current_writes = current_state.get("pending_writes", [])
                except Exception:
                    current_writes = list(pending_writes)
                current_writes.append({"name": block.name, "inputs": inputs})
                n_queued_this_turn += 1
                print(f"[Agent] QUEUED {block.name} — pending_writes total: {len(current_writes)}")
                try:
                    await firestore_db.update_conversation_state(
                        farm_id, conversation_id,
                        {"pending_writes": current_writes},
                    )
                except Exception as exc:
                    print(f"[Agent] WARNING: Could not save pending_writes: {exc}")
                write_intercepted = True
                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": json.dumps({
                        "pending": True,
                        "message": (
                            "Bu amal foydalanuvchi tasdigini kutmoqda. "
                            "Foydalanuvchiga nima qilmoqchi ekanligingizni aniq, qisqa va oddiy matnda tushuntiring. "
                            "Masalan: 'Hamroni Sogʻlom deb belgilayman. Tasdiqlaysizmi?' "
                            "MUHIM: markdown belgilari ishlatmang."
                        ),
                    }, ensure_ascii=False),
                })
            else:
                # Execute normally
                result = await _execute_tool(block.name, inputs, farm_id)
                n_executed_this_turn += 1

                # ── Auto-pin animal on successful lookup ─────────────────────
                if block.name in _ANIMAL_LOOKUP_TOOLS and result.get("found") is not False:
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

                if block.name in (
                    "add_health_case", "update_animal_status", "update_animal_info",
                    "log_vaccination", "log_bulk_vaccination", "log_weight",
                    "log_milk", "record_event", "close_case",
                ):
                    data_saved[block.name] = result

                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": json.dumps(result, ensure_ascii=False, default=str),
                })

        print(f"[Agent] Turn summary: {len(tool_use_blocks)} detected, "
              f"{n_queued_this_turn} queued, {n_executed_this_turn} executed")

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
        print(f"[Agent] (loop) stop_reason={response.stop_reason}  write_intercepted={write_intercepted}")

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
        "pinned_animal": pinned_animal,
    }

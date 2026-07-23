import os
import asyncio
import json
import re
import uuid
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from google import genai
from google.genai import types

import claude_orchestrator
import firestore_db
from context_builder import build_farm_context
from tool_schemas import (
    ALL_TOOLS,
    TOOL_MAP,
    READ_TOOL_NAMES as READ_TOOLS,
    WRITE_TOOL_NAMES as WRITE_TOOLS,
    REQUIRED_FIELDS as _REQUIRED_FIELDS,
    missing_required as _missing_required,
    action_summary as _action_summary,
    _affected_animals,
)
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

# gemini-2.5-flash-lite has "thinking" OFF by default (unlike 2.5-flash, where
# it's on and burns the whole output-token budget → empty replies). We cannot
# disable 2.5-flash thinking here because google-auth==2.36.0 caps google-genai
# at ~1.2.0, whose ThinkingConfig lacks thinking_budget. Flash-Lite sidesteps
# that entirely and is a fast, available model. (gemini-2.0-flash is retired.)
MODEL = "gemini-2.5-flash-lite"
# Fallbacks for when the primary 503s ("high demand" outages can last minutes
# and killed real farmer chats). Probed 2026-07-06 while 2.5-flash-lite was
# DOWN: gemini-flash-lite-latest was UP (thinking off, separate serving pool);
# gemini-2.5-flash also UP (thinks by default = slower/pricier, last resort).
FALLBACK_MODELS = ("gemini-flash-lite-latest", "gemini-2.5-flash")

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


def _text_history(contents):
    """Convert function_call / function_response parts into plain-text turns.
    Needed when falling back to a THINKING model mid tool-loop: those reject
    flash-lite's functionCall parts ("missing thought_signature", 400 — and our
    SDK 1.2.0 predates thought signatures entirely). Text history is accepted
    by every model and preserves the information."""
    out = []
    for c in contents:
        pieces = []
        for p in (getattr(c, "parts", None) or []):
            if getattr(p, "text", None):
                pieces.append(p.text)
            elif getattr(p, "function_call", None):
                fc = p.function_call
                # Framed as a narrative parenthetical, not a quotable tag —
                # reduces (doesn't eliminate; see _strip_internal_leaks) the
                # chance a model echoes this back verbatim as its own reply.
                pieces.append(f"(ichki eslatma, foydalanuvchiga ko'rsatilmaydi: "
                              f"{fc.name} funksiyasi chaqirildi, args={dict(fc.args or {})})")
            elif getattr(p, "function_response", None):
                fr = p.function_response
                try:
                    payload = json.dumps(fr.response, ensure_ascii=False, default=str)[:800]
                except Exception:
                    payload = str(fr.response)[:800]
                pieces.append(f"(ichki eslatma, foydalanuvchiga ko'rsatilmaydi: "
                              f"{fr.name} natijasi: {payload})")
        if pieces:
            role = "model" if getattr(c, "role", "") == "model" else "user"
            out.append(types.Content(role=role, parts=[types.Part(text="\n".join(pieces))]))
    return out


def _config_for_model(base_config, model: str):
    """gemini-2.5-flash THINKS by default and that's a genuine quality
    advantage as a last-resort fallback (it's the whole reason it's smarter
    than flash-lite) — never force thinking_budget=0 onto it. flash-lite
    models keep thinking forced off (see _thinking_off_kwargs)."""
    if model == "gemini-2.5-flash":
        try:
            return base_config.model_copy(update={"thinking_config": None})
        except Exception:
            return base_config
    return base_config


async def _generate(contents, config):
    """Call Gemini with retries AND a model fallback chain. flash-lite
    intermittently (a) 503s under load — sometimes for minutes — and (b) returns
    an EMPTY response (no text AND no function calls) after a tool turn. Retry
    each model a few times, then step down FALLBACK_MODELS so a Google-side
    outage of one model never surfaces to the farmer as an error."""
    last = None
    last_exc = None
    for model in (MODEL, *FALLBACK_MODELS):
        # Fallback models can't consume flash-lite's functionCall history —
        # hand them an equivalent text-only transcript instead.
        use_contents = contents if model == MODEL else _text_history(contents)
        per_model_config = _config_for_model(config, model)
        for attempt in range(3):
            try:
                resp = await client.aio.models.generate_content(
                    model=model, contents=use_contents, config=per_model_config
                )
            except Exception as exc:
                msg = str(exc).lower()
                if "503" in msg or "unavailable" in msg or "overloaded" in msg:
                    last_exc = exc
                    print(f"[Agent] {model} 503/unavailable (attempt {attempt + 1}/3)")
                    await asyncio.sleep(1.2 * (attempt + 1))
                    continue
                if ("404" in msg or "not_found" in msg or "not found" in msg
                        or "thought_signature" in msg):
                    last_exc = exc
                    print(f"[Agent] {model} rejected request "
                          f"({msg[:80]}) — skipping to next model")
                    break
                raise
            last = resp
            if model != MODEL:
                print(f"[Agent] reply served by FALLBACK model {model}")
            # Good response = tool calls to run, OR text to show. NOTE: resp.text
            # RAISES when the response is a function_call part, so check calls
            # first and guard the .text access.
            if resp.function_calls:
                return resp
            try:
                if (resp.text or "").strip():
                    return resp
            except Exception:
                pass
            # Empty response — brief pause, retry same model.
            await asyncio.sleep(0.6)
        # attempts exhausted on this model → try the next one
    if last is not None:
        return last
    raise last_exc if last_exc else RuntimeError("Gemini: all models failed")


def _as_response_dict(result: Any) -> Dict:
    """Gemini function responses must be JSON objects. Sanitise (datetimes etc.)
    via a json round-trip and wrap any non-dict return so it is always a dict."""
    try:
        safe = json.loads(json.dumps(result, ensure_ascii=False, default=str))
    except Exception:
        safe = {"result": str(result)}
    return safe if isinstance(safe, dict) else {"result": safe}

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
    "add_health_case", "update_animal_status", "update_case_status", "update_animal_info",
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


# Phase 4: pull Sonya's confidence % out of her prose so the app can render it as
# a styled badge instead of inline text. Only strips confidence-labelled numbers
# (never a clinical figure like "10% suvsizlanish").
_NUM = r'\d{1,3}(?:[.,]\d+)?'
# "ishonch\w*" absorbs Uzbek suffixes: Ishonchim, ishonchi, ishonch darajasi…
_CONF_FIND = [
    re.compile(rf'ishonch\w*(?:\s*daraja\w*)?\s*[:\-]?\s*({_NUM})\s*%', re.IGNORECASE),
    re.compile(rf'({_NUM})\s*%\s*ishonch', re.IGNORECASE),
    re.compile(rf'уверенност\w*\s*[:\-]?\s*({_NUM})\s*%', re.IGNORECASE),
    re.compile(rf'confidence\s*[:\-]?\s*({_NUM})\s*%', re.IGNORECASE),
]
_CONF_STRIP = [
    re.compile(rf'[\(\[]?\s*ishonch\w*(?:\s*daraja\w*)?\s*[:\-]?\s*{_NUM}\s*%\s*[\.\)\]]?', re.IGNORECASE),
    re.compile(rf'[\(\[]?\s*{_NUM}\s*%\s*ishonch\w*\s*[\.\)\]]?', re.IGNORECASE),
    re.compile(rf'[\(\[]?\s*уверенност\w*\s*[:\-]?\s*{_NUM}\s*%\s*[\.\)\]]?', re.IGNORECASE),
    re.compile(rf'[\(\[]?\s*confidence\s*[:\-]?\s*{_NUM}\s*%\s*[\.\)\]]?', re.IGNORECASE),
]


def _extract_confidence(text: str):
    conf = None
    for pat in _CONF_FIND:
        m = pat.search(text)
        if m:
            conf = max(0, min(100, int(round(float(m.group(1).replace(',', '.'))))))
            break
    if conf is None:
        return text, 0
    clean = text
    for pat in _CONF_STRIP:
        clean = pat.sub('', clean)
    clean = re.sub(r'\s{2,}', ' ', clean).strip()
    clean = clean.strip('—-•·:；;, ').strip()
    return clean, conf


# A weaker fallback model can echo internal tool-call bookkeeping back
# verbatim as its own reply instead of treating it as history context (seen
# live: a farmer received the raw text "[TIZIM: search_rag tool chaqirildi,
# args=...]"). The leaked args repr often contains its OWN "[" / "]" (e.g. a
# symptoms_list), so a bracket-matched strip can't reliably find the true
# closing bracket and can leave a mangled fragment behind. Detect-and-reject
# the WHOLE reply instead — provably safe regardless of nesting — and let it
# fall through to the existing empty-text fallback message. This also
# protects conversation history, since a leak there would poison future turns.
_TIZIM_MARKER_RE = re.compile(r'\[TIZIM:|ichki eslatma,', re.IGNORECASE)


def _strip_internal_leaks(text: str) -> str:
    if _TIZIM_MARKER_RE.search(text):
        return ''
    return text


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

# Maps the app's UI locale (sent by Flutter as e.g. "uz", "uz_Cyrl", "ru") to an
# explicit instruction — message-text language detection alone can't tell
# Cyrillic Uzbek from Latin Uzbek, and shouldn't override a farmer's deliberate
# UI language choice just because they typed on a Latin keyboard.
_LOCALE_FALLBACK_ERROR = {
    "uz": "Kechirasiz, javob tayyorlab bo'lmadi. Qayta urinib ko'ring.",
    "uz_Cyrl": "Кечирасиз, жавоб тайёрлаб бўлмади. Қайта уриниб кўринг.",
    "ru": "Извините, не удалось подготовить ответ. Попробуйте ещё раз.",
}

_LOCALE_INSTRUCTIONS = {
    "uz": "Javobingizni o'zbek tilida, LOTIN alifbosida yozing.",
    "uz_Cyrl": "Javobingizni o'zbek tilida yozing, lekin albatta KIRILL alifbosida "
               "(masalan: 'Ассалому алайкум', 'йўқ', 'соғлом'), lotin alifbosida EMAS.",
    "ru": "Javobingizni rus tilida yozing.",
}


SYSTEM_BASE = """Siz AgriVet ilovasining "Sonya" — Farg'ona vodiysidan 15 yillik tajribali veterinar va ferma menejeri.

Sizning vazifangiz:
1. Fermer aytgan har bir so'zni JIDDIY qabul qiling
2. Hayvon muammosi haqida eshitsangiz — AVVAL get_animal_full_record chaqiring, SO'NG albatta HARAKAT qiling: faqat tarixni aytib TO'XTASH QAT'IYAN TAQIQLANADI
3. Fermer hayvon muammosini ANIQ TASVIRLASA (belgi/tana qismi bor) — darhol klinik harakatlar boshla (search_rag → add_health_case), buyruq yoki tasdiq kutma. Tasvir XIRA bo'lsa (faqat "kasal", "yomon" — aniq belgi yo'q) — bitta aniqlashtiruvchi savol ber, keyin davom et
4. Fermer "Men vetman/doktorman" desa — VET REJIMIGA o'ting
5. Javob tili: {language_instruction} Bu ilova UI tilidan olingan ko'rsatma — MUHIM va ustuvor. Agar biron sababdan bo'sh bo'lsa, foydalanuvchi xabaridan tilni aniqlang (uz/ru)
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

ANIQ TASVIR (belgi yoki tana qismi bor) — masalan "Ko'zi shishib qolibdi",
"Yemoqdan to'xtabdi", "Oyog'ini bosmoqda qiynalmoqda":
Shu javobda ketma-ket chaqiring: search_rag → add_health_case. Qo'shimcha tasdiq SO'RAMANG.

XIRA/UMUMIY TASVIR (faqat "kasal bo'lib qoldi", "yaxshi emas", "o'zini yomon
tutyapti" — aniq belgi YO'Q) — masalan "Guli kasal bo'lib qolibdi":
Case OCHMANG — aniq belgi/tana qismi bo'lmasa add_health_case ni to'g'ri
to'ldirib bo'lmaydi (o'ylab topilgan tashxis xavfli). Buning o'rniga BITTA
ANIQ savol so'rang: "Nima bezovta qilmoqda — ozib ketyaptimi, harorati
bormi, yemoqdan to'xtadimi, qayerida og'riq bor?" Javob kelgach yuqoridagi
ANIQ tartibga o'ting. Buni FAQAT o'qib "hozircha faol yoki tarixiy
kasalligi yo'q" deb JAVOB BERIB TO'XTASH — QAT'IYAN TAQIQLANADI.

QAYSI AMALLAR FONDA BAJARILADI:
- add_health_case, update_animal_status (davolanmoqda/kritik), update_case_status, log_vaccination, log_weight, record_event, add_photo_to_case

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

MA'LUMOT O'QISH VA KASALLIK OCHISH TARTIBI — MAJBURIY, TO'XTASH TAQIQLANADI:
- Avval get_animal_full_record — taxmin qilmang. Bu BIRINCHI qadam, OXIRGI qadam EMAS
- active_cases mavjud bo'lsa — YANGI case OCHMANG, add_photo_to_case bilan ma'lumot qo'shing
- Yangi kasallik bo'lsa — AVVAL search_rag (species + symptoms_list), KEYIN add_health_case
- search_rag natija topsa — "O'xshash holatda..." deb tabiiy tilda xabarlang

MUTLAQO TAQIQLANGAN XATTI-HARAKAT: fermer OXIRGI xabarida hayvon haqida
YANGI muammo aytgan bo'lsa (masalan "X kasal bo'lib qolibdi", "yaxshi
emas"), get_animal_full_record/get_animal_history natijasini FAQAT o'qib,
"hayvon sog'lom, faol yoki tarixiy kasalligi yo'q" deb JAVOB BERIB TO'XTASH
— QAT'IYAN TAQIQLANADI. Tozalik tarixi bugungi xabarni bekor qilmaydi —
farmer aynan HOZIR muammo ko'rmoqda. Yuqoridagi KASALLIK TRIGGER tartibiga
o'ting (aniq bo'lsa — harakat; xira bo'lsa — bitta savol).

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
    locale: str = "uz",
) -> Dict:
    """Phase 6: Sonnet reads the farmer's message directly in their own
    language/script and replies directly in it too — no separate translation
    layer (see claude_orchestrator.py). An earlier Gemini-based boundary was
    removed after being caught corrupting short/casual messages containing
    animal names (e.g. "guli kasal" -> "gullet blocked"/"throat cough" on two
    different calls for the identical input); Sonnet's native understanding
    tested substantially more accurate on the same real farmer messages, and
    cutting two Gemini hops per turn (one of which re-translated the ENTIRE
    conversation history from scratch every single turn) also removes what
    was very likely the dominant source of the reported 17-25s latency.
    Kept the exact same signature/return shape as the prior implementation
    so main.py's /chat handler needed zero changes.

    The old chat-typed-"yes" pending_writes confirmation path was dropped —
    confirmed dead code before this rewrite (nothing in the repo ever
    populated pending_writes; the only real confirmation path was always
    proposed_actions -> client confirm card -> /confirm-action, which
    claude_orchestrator.py already implements)."""
    if not conversation_id:
        conversation_id = uuid.uuid4().hex[:12]

    print(f"[Agent] run_agent farm_id={repr(farm_id)} msg={repr(user_message[:60])}")

    conv_state = await firestore_db.get_conversation_state(farm_id, conversation_id)
    pinned_animal: Optional[str] = conv_state.get("pinned_animal")
    print(f"[Agent] pinned_animal={pinned_animal!r}")

    context = await build_farm_context(farm_id)
    raw_history = await firestore_db.get_conversation_history(farm_id, conversation_id, limit=10)

    # Stored (and read back) in the farmer's own language — Sonnet now reads
    # it directly, no per-turn translation pass over the whole history.
    history: List[Dict[str, str]] = [
        {"role": m.get("role"), "content": m.get("content") or ""}
        for m in raw_history
        if (m.get("content") or "") and m.get("role") in ("user", "assistant")
    ]

    msg_lower = user_message.lower()
    is_emergency_hint = any(kw in msg_lower for kw in EMERGENCY_KW)

    result = await claude_orchestrator.decide_and_act(
        farm_id=farm_id,
        message=user_message,
        history=history,
        farm_context=context,
        pinned_animal=pinned_animal,
        vet_mode=vet_mode,
        is_emergency_hint=is_emergency_hint,
        locale=locale,
    )

    final_text = result["response"]
    if not final_text.strip():
        final_text = _LOCALE_FALLBACK_ERROR.get(locale, _LOCALE_FALLBACK_ERROR["uz"])

    # ── Pin tracking: last ear_tag touched this turn wins (mirrors old logic) ──
    new_pin = pinned_animal
    for action in result["proposed_actions"]:
        tag = action.get("params", {}).get("ear_tag")
        if tag:
            new_pin = tag
    for tool_result in result["data_saved"].values():
        if isinstance(tool_result, dict):
            tag = tool_result.get("ear_tag")
            if tag:
                new_pin = tag
    if new_pin and new_pin != pinned_animal:
        try:
            await firestore_db.update_conversation_state(
                farm_id, conversation_id, {"pinned_animal": new_pin}
            )
            print(f"[Agent] Pinned animal -> {new_pin!r}")
        except Exception as pin_exc:
            print(f"[Agent] WARNING: Could not save pin for {new_pin!r}: {pin_exc}")
        pinned_animal = new_pin

    # Store the ORIGINAL-language turn, not the English internals — this is
    # what the farmer sees again if they reopen the conversation.
    await firestore_db.save_conversation_turn(
        farm_id, conversation_id, user_message, final_text, result["tools_called"]
    )

    new_vet_mode = vet_mode
    if any(kw in msg_lower for kw in VET_ON_KW):
        new_vet_mode = True
    if any(kw in msg_lower for kw in VET_OFF_KW):
        new_vet_mode = False

    return {
        "response": final_text,
        "vet_mode": new_vet_mode,
        "tools_called": result["tools_called"],
        "conversation_id": conversation_id,
        "data_saved": result["data_saved"],
        "proposed_actions": result["proposed_actions"],
        "confidence": result["confidence"],
        "is_emergency": result["is_emergency"],
        "pinned_animal": pinned_animal,
    }

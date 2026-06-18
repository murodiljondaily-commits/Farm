from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

import firestore_db
from sheets_sync import sync_to_sheets_background


def _now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d")


def _now_time() -> str:
    return datetime.now().strftime("%H:%M")


# ─── 1. get_farm_stats ────────────────────────────────────────────

async def get_farm_stats(farm_id: str) -> Dict:
    animals = await firestore_db.get_all_animals(farm_id)
    active_cases = await firestore_db.get_active_cases(farm_id)

    by_species: Dict[str, int] = {}
    for a in animals:
        sp = a.get("species", "noma'lum")
        by_species[sp] = by_species.get(sp, 0) + 1

    overdue = sum(
        1 for a in animals
        if a.get("last_vaccination")
        and (datetime.now(timezone.utc) - datetime.fromisoformat(
            a["last_vaccination"].replace("Z", "+00:00")
        )).days > 365
    )

    events = await firestore_db.get_recent_events(farm_id, days=1)
    last_activity = events[0]["timestamp"][:10] if events else "noma'lum"

    return {
        "total_animals": len(animals),
        "by_species": by_species,
        "active_cases": len(active_cases),
        "overdue_vaccinations": overdue,
        "last_activity": last_activity,
    }


# ─── 2. get_all_animals ───────────────────────────────────────────

async def get_all_animals_tool(
    farm_id: str,
    species: Optional[str] = None,
    status: Optional[str] = None,
) -> List[Dict]:
    return await firestore_db.get_all_animals(farm_id, species=species, status=status)


# ─── 3. get_animal ────────────────────────────────────────────────

async def get_animal_tool(farm_id: str, ear_tag: str) -> Dict:
    animal = await firestore_db.get_animal(farm_id, ear_tag)
    if not animal:
        return {"error": f"Hayvon topilmadi: {ear_tag}"}

    history = await firestore_db.get_animal_history(farm_id, animal["ear_tag"])
    animal["recent_cases"] = history["cases"][:3]
    animal["recent_weights"] = [w.get("data", {}) for w in history["weights"][:3]]
    animal["last_vaccination_record"] = (
        history["vaccinations"][0].get("data") if history["vaccinations"] else None
    )
    return animal


# ─── 4. add_health_case ───────────────────────────────────────────

async def add_health_case(
    farm_id: str,
    ear_tag: str,
    symptoms: List[str],
    body_part: str,
    severity: str,
    ai_diagnosis: str,
    confidence: int,
    first_aid: List[str],
    photo_urls: Optional[List[str]] = None,
) -> Dict:
    photo_urls = photo_urls or []
    animal = await firestore_db.get_animal(farm_id, ear_tag)
    if not animal:
        return {"error": f"Hayvon topilmadi: {ear_tag}"}

    case_data = {
        "ear_tag": ear_tag,
        "animal_name": animal.get("name", ""),
        "species": animal.get("species", ""),
        "symptoms": symptoms,
        "body_part": body_part,
        "severity": severity,
        "ai_diagnosis": ai_diagnosis,
        "ai_confidence": confidence,
        "first_aid": first_aid,
        "photo_urls": photo_urls,
        "treatment_log": [],
        "confirmed_by_vet": False,
        "vet_notes": None,
        "outcome": None,
        "ai_model": "claude-sonnet-4-6",
        "visual_findings": "",
    }
    case_id = await firestore_db.create_case(farm_id, case_data)

    new_status = "kritik" if severity in ("high", "emergency") else "davolanmoqda"
    await firestore_db.update_animal(farm_id, ear_tag, {"status": new_status})

    await firestore_db.create_event(farm_id, {
        "event_type": "case_opened",
        "ear_tag": ear_tag,
        "data": {"case_id": case_id, "diagnosis": ai_diagnosis, "severity": severity},
        "ai_summary": f"{animal.get('name', '?')} — {ai_diagnosis} ({severity})",
        "recorded_by": "ai",
    })

    # Anonymized RAG pattern
    await firestore_db.save_rag_pattern({
        "species": animal.get("species", ""),
        "breed": animal.get("breed", ""),
        "age_months": animal.get("age_months"),
        "body_part": body_part,
        "symptoms": symptoms,
        "visual_findings": "",
        "diagnosis": ai_diagnosis,
        "treatment": first_aid,
        "outcome": None,
        "confidence_score": confidence,
        "confirmed_by_vet": False,
        "region": "",
        "season": "",
    })

    row = [
        _now_str(), _now_time(), ear_tag, animal.get("name", ""),
        animal.get("species", ""), ", ".join(symptoms), body_part, severity,
        ai_diagnosis, f"{confidence}%", ", ".join(first_aid),
        photo_urls[0] if photo_urls else "", "", "", "",
    ]
    await sync_to_sheets_background(farm_id, "Kasalliklar", row)

    return {"case_id": case_id, "animal_status_updated": new_status, "success": True}


# ─── 5. update_animal_status ─────────────────────────────────────

async def update_animal_status(farm_id: str, ear_tag: str, new_status: str) -> Dict:
    animal = await firestore_db.get_animal(farm_id, ear_tag)
    if not animal:
        return {"error": f"Hayvon topilmadi: {ear_tag}"}

    old_status = animal.get("status", "")
    await firestore_db.update_animal(farm_id, ear_tag, {"status": new_status})
    await firestore_db.create_event(farm_id, {
        "event_type": "status_change",
        "ear_tag": ear_tag,
        "data": {"old_status": old_status, "new_status": new_status},
        "ai_summary": f"{animal.get('name', '?')} holati: {old_status} → {new_status}",
        "recorded_by": "ai",
    })
    await sync_to_sheets_background(farm_id, "Hayvonlar", [
        _now_str(), ear_tag, animal.get("name", ""), new_status,
    ])
    return {"success": True, "ear_tag": ear_tag, "new_status": new_status}


# ─── 6. log_vaccination ──────────────────────────────────────────

async def log_vaccination(
    farm_id: str,
    ear_tag: str,
    vaccine_name: str,
    date: str,
    next_due: Optional[str] = None,
) -> Dict:
    animal = await firestore_db.get_animal(farm_id, ear_tag)
    if not animal:
        return {"error": f"Hayvon topilmadi: {ear_tag}"}

    await firestore_db.update_animal(farm_id, ear_tag, {"last_vaccination": date})
    event_id = await firestore_db.create_event(farm_id, {
        "event_type": "vaccination",
        "ear_tag": ear_tag,
        "data": {"vaccine": vaccine_name, "date": date, "next_due": next_due},
        "ai_summary": f"{animal.get('name', '?')} — {vaccine_name} emlash",
        "recorded_by": "ai",
    })
    await sync_to_sheets_background(farm_id, "Emlashlar", [
        date, ear_tag, animal.get("name", ""), vaccine_name, next_due or "", "AI",
    ])
    return {"success": True, "event_id": event_id, "next_due": next_due}


# ─── 7. log_weight ───────────────────────────────────────────────

async def log_weight(farm_id: str, ear_tag: str, weight_kg: float) -> Dict:
    animal = await firestore_db.get_animal(farm_id, ear_tag)
    if not animal:
        return {"error": f"Hayvon topilmadi: {ear_tag}"}

    old_weight = animal.get("weight_current", 0) or 0
    change = round(weight_kg - old_weight, 1) if old_weight else 0.0
    alert = None
    if old_weight and old_weight > 0:
        pct = (change / old_weight) * 100
        if pct < -10:
            alert = f"⚠️ OGOHLANTIRISH: Vazn {abs(pct):.0f}% kamaydi!"

    await firestore_db.update_animal(farm_id, ear_tag, {"weight_current": weight_kg})
    event_id = await firestore_db.create_event(farm_id, {
        "event_type": "weight",
        "ear_tag": ear_tag,
        "data": {"weight_kg": weight_kg, "previous_kg": old_weight, "change": change},
        "ai_summary": (
            f"{animal.get('name', '?')} vazni: {weight_kg}kg "
            f"(o'zgarish: {change:+.1f}kg)"
        ),
        "recorded_by": "ai",
    })
    await sync_to_sheets_background(farm_id, "Vazn", [
        _now_str(), ear_tag, animal.get("name", ""),
        weight_kg, f"{change:+.1f}" if change else "", alert or "",
    ])
    result: Dict[str, Any] = {"success": True, "weight_kg": weight_kg, "change": change}
    if alert:
        result["alert"] = alert
    return result


# ─── 8. log_milk ─────────────────────────────────────────────────

async def log_milk(farm_id: str, liters: float, session: str) -> Dict:
    event_id = await firestore_db.create_event(farm_id, {
        "event_type": "milk",
        "data": {"liters": liters, "session": session},
        "ai_summary": f"Sut: {liters}L ({session})",
        "recorded_by": "ai",
    })
    await sync_to_sheets_background(farm_id, "Sut", [
        _now_str(), session.capitalize(), liters, "",
    ])
    return {"success": True, "liters": liters, "session": session, "event_id": event_id}


# ─── 9. get_animal_history ────────────────────────────────────────

async def get_animal_history_tool(farm_id: str, ear_tag: str) -> Dict:
    animal = await firestore_db.get_animal(farm_id, ear_tag)
    if not animal:
        return {"error": f"Hayvon topilmadi: {ear_tag}"}
    history = await firestore_db.get_animal_history(farm_id, animal["ear_tag"])
    return {
        "animal": animal,
        "cases": history["cases"],
        "vaccinations": history["vaccinations"],
        "weights": history["weights"],
        "events": history["events"][:20],
    }


# ─── 10. search_rag ──────────────────────────────────────────────

async def search_rag_tool(
    species: str,
    symptoms_list: List[str],
    body_part: Optional[str] = None,
) -> str:
    results = await firestore_db.search_rag(species, symptoms_list, body_part)
    if not results:
        return "Shu turdagi holat bazada topilmadi."
    lines = []
    for r in results:
        score = int(r.get("_match_score", 0) * 100)
        recovery = r.get("recovery_days", "?")
        treatment = ", ".join(r.get("treatment", [])) or "ko'rsatilmagan"
        lines.append(
            f"• {r.get('diagnosis', '?')} ({score}% mos), "
            f"o'rtacha tuzalish {recovery} kun, davolash: {treatment}"
        )
    return f"O'xshash {len(results)} holatlarda:\n" + "\n".join(lines)


# ─── 11. close_case ──────────────────────────────────────────────

async def close_case(
    farm_id: str,
    case_id: str,
    outcome: str,
    vet_confirmed: bool = False,
    vet_notes: Optional[str] = None,
) -> Dict:
    case = await firestore_db.get_case(farm_id, case_id)
    if not case:
        return {"error": f"Holat topilmadi: {case_id}"}

    now_iso = datetime.now(timezone.utc).isoformat()
    await firestore_db.update_case(farm_id, case_id, {
        "closed_at": now_iso,
        "outcome": outcome,
        "confirmed_by_vet": vet_confirmed,
        "vet_notes": vet_notes,
    })

    ear_tag = case.get("ear_tag")
    if ear_tag:
        await firestore_db.update_animal(farm_id, ear_tag, {"status": "sog'lom"})

    await firestore_db.create_event(farm_id, {
        "event_type": "case_closed",
        "ear_tag": ear_tag,
        "data": {"case_id": case_id, "outcome": outcome, "vet_confirmed": vet_confirmed},
        "ai_summary": f"Holat yopildi: {case.get('ai_diagnosis', '?')} — {outcome}",
        "recorded_by": "ai",
    })
    await sync_to_sheets_background(farm_id, "Kasalliklar", [
        _now_str(), case_id, ear_tag or "",
        case.get("ai_diagnosis", ""), outcome,
        "Ha" if vet_confirmed else "Yo'q", vet_notes or "",
    ])
    return {"success": True, "case_id": case_id, "outcome": outcome}


# ─── 12. add_photo_to_case ───────────────────────────────────────

async def add_photo_to_case(
    farm_id: str,
    case_id: str,
    photo_url: str,
    visual_findings: str,
) -> Dict:
    case = await firestore_db.get_case(farm_id, case_id)
    if not case:
        return {"error": f"Holat topilmadi: {case_id}"}

    photo_urls = case.get("photo_urls", []) + [photo_url]
    await firestore_db.update_case(farm_id, case_id, {
        "photo_urls": photo_urls,
        "visual_findings": visual_findings,
    })
    await sync_to_sheets_background(farm_id, "Kasalliklar", [
        _now_str(), case_id, photo_url, visual_findings,
    ])
    return {"success": True, "photo_urls": photo_urls}


# ─── 13. get_active_cases ────────────────────────────────────────

async def get_active_cases_tool(farm_id: str) -> List[Dict]:
    cases = await firestore_db.get_active_cases(farm_id)
    now = datetime.now(timezone.utc)
    for c in cases:
        if c.get("opened_at"):
            try:
                opened = datetime.fromisoformat(c["opened_at"].replace("Z", "+00:00"))
                c["days_open"] = (now - opened).days
            except Exception:
                c["days_open"] = 0
    return cases


# ─── 14. record_event ────────────────────────────────────────────

async def record_event_tool(
    farm_id: str,
    event_type: str,
    data: Dict,
    ear_tag: Optional[str] = None,
) -> Dict:
    event_id = await firestore_db.create_event(farm_id, {
        "event_type": event_type,
        "ear_tag": ear_tag,
        "data": data,
        "ai_summary": str(data)[:100],
        "recorded_by": "ai",
    })
    await sync_to_sheets_background(farm_id, "Voqealar", [
        _now_str(), _now_time(), event_type, ear_tag or "", "", str(data)[:100], "AI",
    ])
    return {"success": True, "event_id": event_id}

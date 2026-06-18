from datetime import datetime, timezone, timedelta
from typing import Optional
import firestore_db

SPECIES_EMOJI = {
    "qoramol": "🐄", "sigir": "🐄", "buqa": "🐂",
    "qo'y": "🐑", "echki": "🐐", "ot": "🐴",
    "cho'chqa": "🐷", "tovuq": "🐓",
}

STATUS_EMOJI = {
    "sog'lom": "✅", "davolanmoqda": "🟡",
    "kritik": "🔴", "oldi": "⚫", "soyildi": "⚫",
}

SEVERITY_EMOJI = {"emergency": "🚨", "high": "🔴", "medium": "🟡", "low": "🟢"}


def _season(month: int) -> str:
    if month in (12, 1, 2):
        return "Qish ❄️"
    if month in (3, 4, 5):
        return "Bahor 🌸"
    if month in (6, 7, 8):
        return "Yoz ☀️"
    return "Kuz 🍂"


def _days_since(iso: str) -> int:
    try:
        dt = datetime.fromisoformat(iso.replace("Z", "+00:00"))
        return (datetime.now(timezone.utc) - dt).days
    except Exception:
        return 0


async def build_farm_context(farm_id: str) -> str:
    now = datetime.now(timezone.utc)
    farm = await firestore_db.get_farm(farm_id)
    animals = await firestore_db.get_all_animals(farm_id)
    active_cases = await firestore_db.get_active_cases(farm_id)
    recent_events = await firestore_db.get_recent_events(farm_id, days=7)

    name = farm.get("name", "?") if farm else "?"
    location = farm.get("location", "?") if farm else "?"
    owner = farm.get("owner_name", "?") if farm else "?"
    region = farm.get("region", "Farg'ona") if farm else "Farg'ona"

    lines = [
        f"FARM: {name} | {location} | Egasi: {owner}",
        f"Mavsum: {_season(now.month)} | Hudud: {region}",
        "",
        f"HAYVONLAR ({len(animals)} ta):",
    ]

    for a in animals:
        sp_key = a.get("species", "").lower()
        emoji = SPECIES_EMOJI.get(sp_key, "🐾")
        st_emoji = STATUS_EMOJI.get(a.get("status", ""), "❓")
        age = f"{a.get('age_months', '?')} oy" if a.get("age_months") else ""
        weight = f" {a.get('weight_current', '')}kg" if a.get("weight_current") else ""
        preg = " (homilador)" if a.get("pregnancy_status") == "homilador" else ""
        lines.append(
            f"  • {emoji} {a.get('name', '?')} ({a.get('ear_tag', '?')}) — "
            f"{a.get('species', '?')}, {a.get('breed', '')}, {age}{weight}, "
            f"{st_emoji}{a.get('status', '?')}{preg}"
        )

    lines += ["", f"FAOL KASALLIKLAR ({len(active_cases)} ta):"]
    for c in active_cases:
        days = _days_since(c.get("opened_at", ""))
        sev = SEVERITY_EMOJI.get(c.get("severity", ""), "❓")
        lines.append(
            f"  • {sev} {c.get('ear_tag', '?')} {c.get('animal_name', '?')} — "
            f"{c.get('ai_diagnosis', '?')}, {days} kun, {c.get('severity', '?')}"
        )

    lines += ["", "OXIRGI 7 KUN:"]
    for e in recent_events[:10]:
        ts = e.get("timestamp", "")[:10]
        summary = e.get("ai_summary") or str(e.get("data", {}))[:60]
        lines.append(f"  • {ts}: {e.get('event_type', '')} — {summary}")

    lines += ["", "MUDDATI O'TGAN EMLASHLAR:"]
    overdue = [
        f"  • {a.get('name', '?')} ({a.get('ear_tag', '?')}) — "
        f"oxirgi emlash: {a['last_vaccination'][:10]}"
        for a in animals
        if a.get("last_vaccination") and _days_since(a["last_vaccination"]) > 365
    ]
    lines += overdue if overdue else ["  • Yo'q"]

    return "\n".join(lines)

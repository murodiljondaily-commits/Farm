"""8PM daily digest: a short, deterministic (non-AI) summary of the day per
farm -- milk total, cases opened/closed today, animals currently under
treatment. Deliberately not LLM-generated: this is just aggregating known
numbers, so a template is faster, free, and can't hallucinate.
"""
from typing import Dict

import firestore_db
import push

_TEMPLATE = {
    "uz": "Bugun: {milk}L sut sog'ildi. {opened} ta yangi holat ochildi, "
          "{closed} ta yopildi. Hozirda {active} ta hayvon davolanmoqda.",
    "uz_Cyrl": "Бугун: {milk}Л сут соғилди. {opened} та янги ҳолат очилди, "
               "{closed} та ёпилди. Ҳозирда {active} та ҳайвон даволанмоқда.",
    "ru": "Сегодня: надоено {milk}Л молока. Открыто новых случаев: {opened}, "
          "закрыто: {closed}. Сейчас на лечении: {active} животных.",
}


async def _aggregate_today(farm_id: str) -> Dict:
    events = await firestore_db.get_recent_events(farm_id, days=1)
    milk_total = round(
        sum(
            float(e.get("data", {}).get("liters") or 0)
            for e in events if e.get("event_type") == "milk"
        ),
        1,
    )
    opened = sum(1 for e in events if e.get("event_type") == "case_opened")
    closed = sum(1 for e in events if e.get("event_type") == "case_closed")
    active_cases = await firestore_db.get_active_cases(farm_id)
    return {
        "milk": milk_total,
        "opened": opened,
        "closed": closed,
        "active": len(active_cases),
    }


async def run_daily_digest_for_all_farms() -> None:
    farms = await firestore_db.get_all_farms()
    print(f"[Digest] running for {len(farms)} farm(s)")
    for farm in farms:
        farm_id = farm.get("farm_id")
        if not farm_id:
            continue
        try:
            stats = await _aggregate_today(farm_id)
            body_per_locale = {
                locale: tmpl.format(**stats) for locale, tmpl in _TEMPLATE.items()
            }
            sent = await push.send_localized_to_farm(
                farm_id,
                title_key="daily_digest_title",
                body_per_locale=body_per_locale,
            )
            print(f"[Digest] {farm_id}: sent={sent} stats={stats}")
        except Exception as exc:
            # One farm's bad data must never block the rest of the run.
            print(f"[Digest] {farm_id}: ERROR {exc}")

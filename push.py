"""Push notifications via FCM (firebase_admin.messaging, already available
through the existing firebase-admin dependency -- no new package needed for
sending). Every notification is composed per-recipient in whatever locale
that device registered with, and uses the custom short alert sound channel
the Flutter client creates (see ANDROID_CHANNEL_ID) -- no spoken/TTS content,
just a short tone, per the confirmed spec.
"""
import asyncio
from typing import Dict, List, Optional

from firebase_admin import messaging

import firestore_db

# Must match the notification channel id created client-side
# (lib/services/push_service.dart) exactly, or Android silently falls back
# to the default channel (default sound, no custom tone). Once a channel
# exists on-device its sound is fixed by the client-side channel definition
# (Android 8+ ignores per-notification sound overrides on existing
# channels) -- ANDROID_SOUND_NAME below is sent for spec-completeness /
# first-run correctness, but the client's channel creation is what really
# determines the tone.
ANDROID_CHANNEL_ID = "agrivet_alerts"
ANDROID_SOUND_NAME = "agrivet_alert"

_LOCALES = ("uz", "uz_Cyrl", "ru")


def _fallback_locale(locale: Optional[str]) -> str:
    return locale if locale in _LOCALES else "uz"


# Fixed (non-templated) notification titles per type/locale. Bodies for
# weather warnings use a {time} placeholder; the daily digest's body is the
# already-composed, already-localized summary text (see digest.py), so it
# has no template here.
MESSAGES: Dict[str, Dict[str, str]] = {
    "daily_digest_title": {
        "uz": "Kunlik hisobot",
        "uz_Cyrl": "Кунлик ҳисобот",
        "ru": "Дневной отчёт",
    },
    "weather_rain_title": {
        "uz": "⚠️ Ob-havo ogohlantirishi",
        "uz_Cyrl": "⚠️ Об-ҳаво огоҳлантириши",
        "ru": "⚠️ Погодное предупреждение",
    },
    "weather_rain_body": {
        "uz": "Bugun soat {time} atrofida kuchli yomg'ir kutilmoqda. Hayvonlarni panohga oling.",
        "uz_Cyrl": "Бугун соат {time} атрофида кучли ёмғир кутилмоқда. Ҳайвонларни паноҳга олинг.",
        "ru": "Сегодня около {time} ожидается сильный дождь. Укройте животных.",
    },
    "weather_wind_title": {
        "uz": "⚠️ Ob-havo ogohlantirishi",
        "uz_Cyrl": "⚠️ Об-ҳаво огоҳлантириши",
        "ru": "⚠️ Погодное предупреждение",
    },
    "weather_wind_body": {
        "uz": "Bugun soat {time} atrofida kuchli shamol kutilmoqda. Hayvonlarni panohga oling.",
        "uz_Cyrl": "Бугун соат {time} атрофида кучли шамол кутилмоқда. Ҳайвонларни паноҳга олинг.",
        "ru": "Сегодня около {time} ожидается сильный ветер. Укройте животных.",
    },
}


def _send_multicast_sync(tokens: List[str], title: str, body: str) -> int:
    if not tokens:
        return 0
    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
        android=messaging.AndroidConfig(
            notification=messaging.AndroidNotification(
                channel_id=ANDROID_CHANNEL_ID,
                sound=ANDROID_SOUND_NAME,
            )
        ),
    )
    resp = messaging.send_each_for_multicast(message)
    return resp.success_count


async def send_localized_to_farm(
    farm_id: str,
    *,
    title_key: Optional[str] = None,
    title_per_locale: Optional[Dict[str, str]] = None,
    body_key: Optional[str] = None,
    body_vars: Optional[Dict[str, str]] = None,
    body_per_locale: Optional[Dict[str, str]] = None,
) -> int:
    """Sends a notification to every device registered to a farm, composed
    in each device's own locale. Title and body are each independently
    either a MESSAGES lookup (title_key / body_key+body_vars) or an
    already-per-locale-composed dict (title_per_locale / body_per_locale) --
    the daily digest needs a templated title with a data-driven body, so
    these can't be coupled into one mode/the other.
    Groups by locale so each distinct locale is one multicast call, not one
    call per device.
    """
    tokens = await firestore_db.get_farm_notification_tokens(farm_id)
    if not tokens:
        return 0

    by_locale: Dict[str, List[str]] = {}
    for t in tokens:
        loc = _fallback_locale(t.get("locale"))
        by_locale.setdefault(loc, []).append(t["token"])

    sent = 0
    for locale, locale_tokens in by_locale.items():
        title = (
            MESSAGES[title_key][locale] if title_key is not None
            else (title_per_locale or {}).get(locale, "")
        )
        body = (
            MESSAGES[body_key][locale].format(**(body_vars or {})) if body_key is not None
            else (body_per_locale or {}).get(locale, "")
        )
        sent += await asyncio.to_thread(_send_multicast_sync, locale_tokens, title, body)
    return sent

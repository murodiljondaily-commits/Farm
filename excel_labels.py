"""Static Uzbek label dictionary for the Excel farm report (excel_export.py).

Kept as its own module — not inline strings in excel_export.py — per the
report spec. Status labels/colors mirror the app's own vocabulary exactly:
statusSoglom/statusDavolanmoqda/etc. in flutter_app/lib/l10n/app_uz.arb, and
the kStatus* color constants in flutter_app/lib/theme.dart — so the report
reads consistently with what the farmer already sees in the app.
"""
from typing import Optional

SHEET_ROSTER = "Hayvonlar ro'yxati"
SHEET_HEALTH = "Sog'liq voqealari"
SHEET_STATS = "Statistika"

ROSTER_HEADERS = [
    "ID", "Quloq raqami", "Ism", "Tur", "Zot", "Holat", "Oxirgi yangilanish",
]

HEALTH_HEADERS = [
    "Sana", "Quloq raqami", "Ism", "Belgilar", "Og'irlik darajasi",
    "Holat", "Natija",
]

STATS_LABELS = {
    "title": "Ferma statistikasi",
    "total_animals": "Jami hayvonlar",
    "active_cases_by_severity": "Faol holatlar (og'irlik darajasi bo'yicha)",
    "resolved_this_period": "Ushbu davrda yopilgan holatlar",
    "severity_low": "Past",
    "severity_medium": "O'rta",
    "severity_high": "Yuqori",
    "severity_emergency": "Favqulodda",
}

# Animal.status -> display label. Matches app_uz.arb's statusSoglom/etc.
ANIMAL_STATUS_LABELS = {
    "soglom": "Sog'lom",
    "davolanmoqda": "Davolanmoqda",
    "kritik": "Kritik",
    "kuzatuvda": "Kuzatuvda",
    "sotildi": "Sotildi",
    "oldi": "O'ldi",
}

# Case.status -> display label (distinct vocabulary from animal status).
CASE_STATUS_LABELS = {
    "open": "Ochiq",
    "davolanmoqda": "Davolanmoqda",
    "closed": "Yopilgan",
}

CASE_OUTCOME_LABELS = {
    "tuzaldi": "Tuzaldi",
    "yomonlashdi": "Yomonlashdi",
    "oldi": "O'ldi",
}

# Fill colors (ARGB hex, openpyxl format) — same hues as theme.dart's kStatus*
# constants, so a farmer who knows the app's colors recognizes them here too.
STATUS_FILL_COLORS = {
    "soglom": "FF2BAF9C",        # kStatusSoglom — aqua mint
    "davolanmoqda": "FFED8936",  # kStatusDavolanmoqda — soft orange
    "kritik": "FFBA1A1A",        # kStatusKritik — soft red
    "kuzatuvda": "FF5F8CA3",     # kStatusKuzatuvda — sage blue
    "sotildi": "FF2E9E8F",       # kStatusSotildi — mint-teal
    "oldi": "FFB3261E",          # kStatusOldi — red
    "open": "FFED8936",          # cases: open ~ treat as "needs attention" orange
    "closed": "FF2BAF9C",        # cases: closed ~ resolved, mint
}


def animal_status_label(status: str) -> str:
    return ANIMAL_STATUS_LABELS.get(status, status)


def case_status_label(status: str) -> str:
    return CASE_STATUS_LABELS.get(status, status)


def case_outcome_label(outcome: str | None) -> str:
    if not outcome:
        return ""
    return CASE_OUTCOME_LABELS.get(outcome, outcome)


def fill_color_for_status(status: str) -> str | None:
    return STATUS_FILL_COLORS.get(status)

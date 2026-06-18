import os
import json
import asyncio
from datetime import datetime
from typing import List, Any

import gspread
from google.oauth2 import service_account

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]

TAB_HEADERS = {
    "Hayvonlar": [
        "Sana", "Quloq raqami", "Ism", "Tur", "Zot", "Jins", "Yoshi",
        "Rang", "Holat", "Vazn", "Oxirgi emlash", "Homiladorlik", "Rasm URL",
    ],
    "Kasalliklar": [
        "Sana", "Vaqt", "Quloq raqami", "Ism", "Tur", "Belgilar",
        "Tana qismi", "Og'irlik darajasi", "AI tashxis", "Ishonch %",
        "Darhol choralar", "Rasm URL", "Natija", "Vet tasdiqladi", "Eslatmalar",
    ],
    "Emlashlar": [
        "Sana", "Quloq raqami", "Ism", "Vaksina", "Keyingi muddati", "Kim tomonidan",
    ],
    "Vazn": [
        "Sana", "Quloq raqami", "Ism", "Vazn (kg)", "O'zgarish", "Eslatma",
    ],
    "Sut": [
        "Sana", "Sessiya (Ertalab/Kechqurun)", "Litr", "Eslatma",
    ],
    "Voqealar": [
        "Sana", "Vaqt", "Tur", "Quloq raqami", "Ism", "Tavsif", "Kim tomonidan",
    ],
}


def _get_gc() -> gspread.Client:
    cred_dict = json.loads(os.environ.get("GOOGLE_SERVICE_ACCOUNT_JSON", "{}"))
    creds = service_account.Credentials.from_service_account_info(cred_dict, scopes=SCOPES)
    return gspread.authorize(creds)


def _get_sheet_id(farm_id: str) -> str | None:
    from firebase_admin import firestore
    db = firestore.client()
    doc = db.collection("farms").document(farm_id).get()
    if not doc.exists:
        return None
    return doc.to_dict().get("google_sheet_id")


def _sync_row_sync(farm_id: str, tab_name: str, row_data: List[Any]) -> None:
    try:
        sheet_id = _get_sheet_id(farm_id)
        if not sheet_id:
            print(f"[Sheets] No sheet linked for farm {farm_id}, skipping")
            return
        gc = _get_gc()
        sheet = gc.open_by_key(sheet_id)
        try:
            ws = sheet.worksheet(tab_name)
        except gspread.WorksheetNotFound:
            ws = sheet.add_worksheet(title=tab_name, rows=1000, cols=20)
            headers = TAB_HEADERS.get(tab_name, [])
            if headers:
                ws.append_row(headers)
        ws.append_row([str(v) if v is not None else "" for v in row_data])
        print(f"[Sheets] ✓ {tab_name}: {row_data}")
    except Exception as e:
        print(f"[Sheets] ERROR {tab_name}: {e}")


async def sync_to_sheets_background(farm_id: str, tab_name: str, row_data: List[Any]) -> None:
    asyncio.ensure_future(asyncio.to_thread(_sync_row_sync, farm_id, tab_name, row_data))


def _create_sheet_sync(farm_id: str, farm_name: str, owner_email: str) -> str:
    gc = _get_gc()
    title = f"AgriVet — {farm_name}"
    sheet = gc.create(title)

    # Remove default Sheet1
    try:
        sheet.del_worksheet(sheet.worksheet("Sheet1"))
    except Exception:
        pass

    # Create all tabs with headers
    for tab_name, headers in TAB_HEADERS.items():
        ws = sheet.add_worksheet(title=tab_name, rows=1000, cols=len(headers) + 2)
        ws.append_row(headers)

    # Share with owner
    sheet.share(owner_email, perm_type="user", role="writer")

    sheet_url = f"https://docs.google.com/spreadsheets/d/{sheet.id}"

    # Persist to Firestore
    from firebase_admin import firestore
    db = firestore.client()
    db.collection("farms").document(farm_id).set(
        {"google_sheet_id": sheet.id, "google_sheet_url": sheet_url},
        merge=True,
    )
    print(f"[Sheets] Created: {sheet_url}")
    return sheet_url


async def create_farm_sheet(farm_id: str, farm_name: str, owner_email: str) -> str:
    return await asyncio.to_thread(_create_sheet_sync, farm_id, farm_name, owner_email)

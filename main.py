import os
from typing import Optional

from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, HTTPException, UploadFile, File, Form, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware

import firestore_db
from models import ChatRequest, ChatResponse, SyncRequest, CreateSheetRequest
from agent import run_agent
from storage import upload_photo, analyze_photo_with_claude
from sheets_sync import sync_to_sheets_background, create_farm_sheet
from context_builder import build_farm_context

app = FastAPI(title="AgriVet AI Backend", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Health ───────────────────────────────────────────────────────

@app.get("/health")
async def health():
    try:
        import firestore_db
        firestore_db._init_firebase()
        return {"status": "ok", "version": "1.0"}
    except Exception as exc:
        return {"status": "error", "detail": str(exc)}


# ─── Chat ─────────────────────────────────────────────────────────

@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    try:
        result = await run_agent(
            farm_id=req.farm_id,
            user_message=req.message,
            conversation_id=req.conversation_id,
            user_role=req.user_role,
            vet_mode=req.vet_mode,
        )
        return ChatResponse(
            response=result["response"],
            conversation_id=result["conversation_id"],
            vet_mode=result["vet_mode"],
            tools_called=result["tools_called"],
            data_saved=result.get("data_saved", {}),
        )
    except Exception as exc:
        print(f"[/chat] ERROR: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


# ─── Photo analysis + upload ──────────────────────────────────────

@app.post("/photo")
async def photo_upload(
    farm_id: str = Form(...),
    user_id: str = Form(...),
    ear_tag: str = Form(...),
    case_id: Optional[str] = Form(None),
    body_part_hint: Optional[str] = Form(""),
    image: UploadFile = File(...),
):
    try:
        image_bytes = await image.read()

        animal = await firestore_db.get_animal(farm_id, ear_tag)
        animal_context = (
            f"{animal.get('name','?')} ({animal.get('species','?')}, {animal.get('age_months','?')} oy)"
            if animal else f"Quloq raqami: {ear_tag}"
        )

        analysis = await analyze_photo_with_claude(
            image_bytes, animal_context, body_part_hint or ""
        )

        species = animal.get("species", "unknown") if animal else "unknown"
        condition = analysis.get("probable_diagnosis", "unknown")[:30]
        photo_url = await upload_photo(
            farm_id, ear_tag, case_id, image_bytes,
            category="health", species=species, condition=condition,
        )

        result_case_id = case_id
        if not result_case_id and analysis.get("severity") in ("medium", "high", "emergency"):
            from tools import add_health_case
            case_result = await add_health_case(
                farm_id=farm_id,
                ear_tag=ear_tag,
                symptoms=[analysis.get("visual_findings", "")],
                body_part=analysis.get("which_leg_or_part", body_part_hint or "noma'lum"),
                severity=analysis.get("severity", "medium"),
                ai_diagnosis=analysis.get("probable_diagnosis", "Noma'lum"),
                confidence=analysis.get("confidence", 50),
                first_aid=analysis.get("immediate_actions", []),
                photo_urls=[photo_url],
            )
            result_case_id = case_result.get("case_id")
        elif result_case_id:
            from tools import add_photo_to_case
            await add_photo_to_case(
                farm_id, result_case_id, photo_url, analysis.get("visual_findings", "")
            )

        return {
            "photo_url": photo_url,
            "visual_findings": analysis.get("visual_findings", ""),
            "severity": analysis.get("severity", "low"),
            "probable_diagnosis": analysis.get("probable_diagnosis", ""),
            "immediate_actions": analysis.get("immediate_actions", []),
            "confidence": analysis.get("confidence", 0),
            "case_id": result_case_id,
        }
    except Exception as exc:
        print(f"[/photo] ERROR: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


# ─── Farm endpoints ───────────────────────────────────────────────

@app.get("/farm/{farm_id}/context")
async def get_context(farm_id: str):
    try:
        ctx = await build_farm_context(farm_id)
        return {"context": ctx}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/farm/{farm_id}/animals")
async def get_animals(
    farm_id: str,
    species: Optional[str] = None,
    status: Optional[str] = None,
):
    try:
        animals = await firestore_db.get_all_animals(farm_id, species=species, status=status)
        return {"animals": animals, "count": len(animals)}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/farm/{farm_id}/animal/{ear_tag}")
async def get_animal(farm_id: str, ear_tag: str):
    try:
        from tools import get_animal_history_tool
        return await get_animal_history_tool(farm_id, ear_tag)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/farm/{farm_id}/cases/active")
async def get_active_cases(farm_id: str):
    try:
        cases = await firestore_db.get_active_cases(farm_id)
        return {"cases": cases, "count": len(cases)}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/farm/{farm_id}/sync-sheets")
async def manual_sync(
    farm_id: str,
    req: SyncRequest,
    background_tasks: BackgroundTasks,
):
    background_tasks.add_task(
        sync_to_sheets_background, farm_id, req.tab_name, req.row_data
    )
    return {"status": "queued", "tab": req.tab_name}


@app.post("/farm/{farm_id}/create-sheet")
async def create_sheet(farm_id: str, req: CreateSheetRequest):
    try:
        farm = await firestore_db.get_farm(farm_id)
        farm_name = farm.get("name", farm_id) if farm else farm_id
        sheet_url = await create_farm_sheet(farm_id, farm_name, req.owner_email)
        return {"sheet_url": sheet_url, "success": True}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))

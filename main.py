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
    return {"status": "ok", "version": "1.0"}


# ─── Diagnostics (temporary) ──────────────────────────────────────

@app.get("/debug-firebase")
async def debug_firebase():
    import json, traceback, os
    import firebase_admin
    from firebase_admin import credentials as fb_creds
    from concurrent.futures import ThreadPoolExecutor

    result = {}

    # ── Step 1: Inspect raw JSON before touching firebase_admin ──────
    raw = os.environ.get("GOOGLE_SERVICE_ACCOUNT_JSON", "")
    result["step1_env_var_length"] = len(raw)
    result["step1_FIREBASE_PROJECT_ID"] = os.environ.get("FIREBASE_PROJECT_ID", "NOT SET")
    ant_key = os.environ.get("ANTHROPIC_API_KEY", "")
    result["step1_ANTHROPIC_API_KEY_set"] = bool(ant_key)
    result["step1_ANTHROPIC_API_KEY_prefix"] = ant_key[:12] if ant_key else "NOT SET"

    if not raw:
        result["step1_error"] = "GOOGLE_SERVICE_ACCOUNT_JSON is empty"
        return result

    try:
        cred_dict = json.loads(raw)
        pk = cred_dict.get("private_key", "")
        result["step1_json_parse"] = "OK"
        result["step1_sa_email"] = cred_dict.get("client_email", "MISSING")
        result["step1_sa_project_id"] = cred_dict.get("project_id", "MISSING")
        result["step1_token_uri"] = cred_dict.get("token_uri", "MISSING")
        result["step1_key_type"] = cred_dict.get("type", "MISSING")
        result["step1_private_key_length"] = len(pk)
        result["step1_private_key_newline_count"] = pk.count("\n")
        result["step1_private_key_first30"] = repr(pk[:30])
        result["step1_private_key_last30"] = repr(pk[-30:])
        result["step1_has_begin_header"] = (
            "-----BEGIN RSA PRIVATE KEY-----" in pk
            or "-----BEGIN PRIVATE KEY-----" in pk
        )
        result["step1_has_end_footer"] = (
            "-----END RSA PRIVATE KEY-----" in pk
            or "-----END PRIVATE KEY-----" in pk
        )
    except json.JSONDecodeError as e:
        result["step1_json_parse"] = f"FAILED: {e}"
        return result

    # ── Step 2: Force initialize (or re-use existing app) ─────────────
    def _do_init():
        # If already initialized, report what's in there
        if firebase_admin._apps:
            app = firebase_admin.get_app()
            return {
                "already_initialized": True,
                "app_project_id": app.project_id,
                "credential_type": type(app.credential).__name__,
                "credential_email": getattr(app.credential, "_service_account_email", "n/a"),
            }
        # Fresh init — build the Certificate object explicitly so we can catch errors
        try:
            cred = fb_creds.Certificate(cred_dict)
            init_info = {
                "certificate_built": True,
                "cert_email": getattr(cred, "_service_account_email", "n/a"),
            }
        except Exception:
            return {"certificate_build": "FAILED", "traceback": traceback.format_exc()}

        firebase_project = os.environ.get("FIREBASE_PROJECT_ID", cred_dict.get("project_id"))
        try:
            firebase_admin.initialize_app(cred, {
                "storageBucket": os.environ.get(
                    "FIREBASE_STORAGE_BUCKET", f"{firebase_project}.appspot.com"
                ),
                "projectId": firebase_project,
            })
            init_info["initialize_app"] = "OK"
            init_info["project_used"] = firebase_project
        except Exception:
            init_info["initialize_app"] = "FAILED"
            init_info["traceback"] = traceback.format_exc()

        return init_info

    executor = ThreadPoolExecutor(max_workers=2)
    f_init = executor.submit(_do_init)
    try:
        result["step2_init"] = f_init.result(timeout=10)
    except Exception:
        result["step2_init"] = {"timeout_or_crash": traceback.format_exc()}

    # ── Step 3: Basic HTTPS connectivity (does Railway reach Google?) ──
    def _test_https():
        import urllib.request
        results = {}
        for label, url in [
            ("google_com", "https://www.google.com"),
            ("oauth2_googleapis", "https://oauth2.googleapis.com/"),
            ("firestore_googleapis", "https://firestore.googleapis.com/"),
        ]:
            try:
                req = urllib.request.Request(url, headers={"User-Agent": "diag/1"})
                with urllib.request.urlopen(req, timeout=8) as r:
                    results[label] = f"HTTP {r.status}"
            except Exception as e:
                results[label] = f"FAILED: {type(e).__name__}: {e}"
        return results

    f_https = executor.submit(_test_https)
    try:
        result["step3_https_connectivity"] = f_https.result(timeout=30)
    except Exception:
        result["step3_https_connectivity"] = traceback.format_exc()

    # ── Step 4: OAuth token via REST (no gRPC) ────────────────────────
    def _get_token():
        from google.oauth2 import service_account
        import google.auth.transport.requests as ga_requests
        creds = service_account.Credentials.from_service_account_info(
            cred_dict,
            scopes=["https://www.googleapis.com/auth/cloud-platform",
                    "https://www.googleapis.com/auth/datastore"],
        )
        request = ga_requests.Request()
        creds.refresh(request)
        return {"token_obtained": True, "expiry": str(creds.expiry)}

    f_token = executor.submit(_get_token)
    try:
        result["step4_oauth_token"] = f_token.result(timeout=15)
    except Exception:
        result["step4_oauth_token"] = {"failed": True, "traceback": traceback.format_exc()}

    # ── Step 5: Firestore via REST (bypasses gRPC entirely) ───────────
    def _firestore_rest():
        import urllib.request, urllib.error
        from google.oauth2 import service_account
        import google.auth.transport.requests as ga_requests

        creds = service_account.Credentials.from_service_account_info(
            cred_dict,
            scopes=["https://www.googleapis.com/auth/cloud-platform",
                    "https://www.googleapis.com/auth/datastore"],
        )
        creds.refresh(ga_requests.Request())
        token = creds.token
        project = os.environ.get("FIREBASE_PROJECT_ID", cred_dict.get("project_id"))
        # List documents in _diag collection via REST
        url = (
            f"https://firestore.googleapis.com/v1/"
            f"projects/{project}/databases/(default)/documents/_diag"
        )
        req = urllib.request.Request(
            url,
            headers={"Authorization": f"Bearer {token}"},
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as r:
                return {"status": r.status, "body_snippet": r.read(200).decode()}
        except urllib.error.HTTPError as e:
            return {"http_error": e.code, "body": e.read(500).decode()}

    f_rest = executor.submit(_firestore_rest)
    try:
        result["step5_firestore_rest"] = f_rest.result(timeout=20)
    except Exception:
        result["step5_firestore_rest"] = {"failed": True, "traceback": traceback.format_exc()}

    # ── Step 6: gRPC Firestore write (original path) ──────────────────
    def _raw_write():
        db = firestore_db.get_db()
        db.collection("_diag").document("ping").set({"ts": "ok"})

    f_write = executor.submit(_raw_write)
    try:
        f_write.result(timeout=15)
        result["step6_grpc_write"] = "SUCCESS"
    except Exception:
        result["step6_grpc_write"] = "FAILED"
        result["step6_full_traceback"] = traceback.format_exc()

    executor.shutdown(wait=False)
    return result


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

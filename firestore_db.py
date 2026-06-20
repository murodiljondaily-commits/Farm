import os
import json
import uuid
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any

import firebase_admin
from firebase_admin import credentials, firestore, storage as fb_storage

_executor = ThreadPoolExecutor(max_workers=10)
FIRESTORE_TIMEOUT = 12  # seconds


def _run(fn, *args):
    """Run a blocking Firestore call in a thread with a hard timeout."""
    future = _executor.submit(fn, *args)
    try:
        return future.result(timeout=FIRESTORE_TIMEOUT)
    except FuturesTimeoutError:
        project = os.environ.get("FIREBASE_PROJECT_ID", "unknown")
        raise RuntimeError(
            f"Firestore timeout ({FIRESTORE_TIMEOUT}s) on project '{project}'. "
            f"Ensure Firestore API is enabled and the service account has "
            f"'Cloud Datastore User' role on that project."
        )


def _init_firebase():
    if firebase_admin._apps:
        return
    cred_json = os.environ.get("GOOGLE_SERVICE_ACCOUNT_JSON", "")
    if not cred_json:
        raise RuntimeError("GOOGLE_SERVICE_ACCOUNT_JSON env var is not set")
    try:
        cred_dict = json.loads(cred_json)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"GOOGLE_SERVICE_ACCOUNT_JSON is not valid JSON: {e}")
    cred = credentials.Certificate(cred_dict)
    firebase_project = os.environ.get("FIREBASE_PROJECT_ID", cred_dict.get("project_id"))
    firebase_admin.initialize_app(cred, {
        "storageBucket": os.environ.get("FIREBASE_STORAGE_BUCKET", f"{firebase_project}.appspot.com"),
        "projectId": firebase_project,
    })
    print(f"[Firebase] project={firebase_project} sa={cred_dict.get('project_id')}")


def get_db():
    _init_firebase()
    return firestore.client()


# ─── Farm ────────────────────────────────────────────────────────

async def get_farm(farm_id: str) -> Optional[Dict]:
    def _q():
        doc = get_db().collection("farms").document(farm_id).get()
        return doc.to_dict() if doc.exists else None
    return _run(_q)


async def save_farm(farm_data: Dict) -> None:
    """Upsert a farm document into Firestore."""
    farm_id = farm_data["farm_id"]
    payload = {k: v for k, v in farm_data.items() if k != "farm_id"}
    payload["updated_at"] = datetime.now(timezone.utc).isoformat()
    def _q():
        get_db().collection("farms").document(farm_id).set(payload, merge=True)
    _run(_q)


async def get_farm_by_code(farm_code: str) -> Optional[Dict]:
    """Look up a farm by its join code (case-insensitive exact match)."""
    upper = farm_code.upper()
    def _q():
        docs = (
            get_db().collection("farms")
            .where("farm_code", "==", upper)
            .limit(1)
            .stream()
        )
        for doc in docs:
            data = doc.to_dict()
            data["farm_id"] = doc.id
            return data
        return None
    return _run(_q)


# ─── Animals ─────────────────────────────────────────────────────

async def get_all_animals(
    farm_id: str,
    species: Optional[str] = None,
    status: Optional[str] = None,
) -> List[Dict]:
    def _q():
        ref = get_db().collection("farms").document(farm_id).collection("animals")
        query = ref
        if species:
            query = query.where("species", "==", species)
        if status:
            query = query.where("status", "==", status)
        animals = []
        for doc in query.stream():
            a = doc.to_dict()
            a["ear_tag"] = doc.id
            animals.append(a)
        return animals
    return _run(_q)


async def get_animal(farm_id: str, ear_tag: str) -> Optional[Dict]:
    def _q():
        doc = get_db().collection("farms").document(farm_id).collection("animals").document(ear_tag).get()
        if doc.exists:
            a = doc.to_dict()
            a["ear_tag"] = doc.id
            return a
        return None
    result = _run(_q)
    if result:
        return result
    # Fuzzy fallback
    all_animals = await get_all_animals(farm_id)
    needle = ear_tag.lower()
    for a in all_animals:
        if (
            a.get("ear_tag", "").lower() == needle
            or a.get("name", "").lower() == needle
            or needle in a.get("name", "").lower()
            or needle in a.get("ear_tag", "").lower()
        ):
            return a
    return None


async def update_animal(farm_id: str, ear_tag: str, data: Dict) -> None:
    data["updated_at"] = datetime.now(timezone.utc).isoformat()
    def _q():
        get_db().collection("farms").document(farm_id).collection("animals").document(ear_tag).set(
            data, merge=True
        )
    _run(_q)


# ─── Cases ───────────────────────────────────────────────────────

async def create_case(farm_id: str, case_data: Dict) -> str:
    case_id = uuid.uuid4().hex[:8]
    case_data["case_id"] = case_id
    case_data["opened_at"] = datetime.now(timezone.utc).isoformat()
    case_data["closed_at"] = None
    def _q():
        get_db().collection("farms").document(farm_id).collection("cases").document(case_id).set(case_data)
    _run(_q)
    return case_id


async def get_case(farm_id: str, case_id: str) -> Optional[Dict]:
    def _q():
        doc = get_db().collection("farms").document(farm_id).collection("cases").document(case_id).get()
        if doc.exists:
            c = doc.to_dict()
            c["case_id"] = doc.id
            return c
        return None
    return _run(_q)


async def update_case(farm_id: str, case_id: str, data: Dict) -> None:
    def _q():
        get_db().collection("farms").document(farm_id).collection("cases").document(case_id).set(
            data, merge=True
        )
    _run(_q)


async def get_active_cases(farm_id: str) -> List[Dict]:
    def _q():
        docs = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("cases")
            .where("closed_at", "==", None)
            .stream()
        )
        cases = []
        for doc in docs:
            c = doc.to_dict()
            c["case_id"] = doc.id
            cases.append(c)
        return cases
    return _run(_q)


# ─── Events ──────────────────────────────────────────────────────

async def create_event(farm_id: str, event_data: Dict) -> str:
    event_id = uuid.uuid4().hex[:8]
    event_data["event_id"] = event_id
    event_data["timestamp"] = datetime.now(timezone.utc).isoformat()
    def _q():
        get_db().collection("farms").document(farm_id).collection("events").document(event_id).set(event_data)
    _run(_q)
    return event_id


async def get_recent_events(farm_id: str, days: int = 7) -> List[Dict]:
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    def _q():
        docs = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("events")
            .where("timestamp", ">=", cutoff)
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(50)
            .stream()
        )
        events = []
        for doc in docs:
            e = doc.to_dict()
            e["event_id"] = doc.id
            events.append(e)
        return events
    return _run(_q)


# ─── Conversations ────────────────────────────────────────────────

async def get_conversation_state(farm_id: str, conv_id: str) -> Dict:
    """Return non-message metadata: pinned_animal, pending_writes (list)."""
    def _q():
        doc = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("conversations")
            .document(conv_id)
            .get()
        )
        if not doc.exists:
            return {}
        data = doc.to_dict()
        # Support legacy single-dict pending_write and new list pending_writes
        raw_writes = data.get("pending_writes")
        if raw_writes is None:
            legacy = data.get("pending_write")
            raw_writes = [legacy] if isinstance(legacy, dict) else []
        elif not isinstance(raw_writes, list):
            raw_writes = []
        return {
            "pinned_animal": data.get("pinned_animal"),
            "pending_writes": raw_writes,
        }
    return _run(_q)


async def update_conversation_state(farm_id: str, conv_id: str, updates: Dict) -> None:
    """Merge metadata fields (pinned_animal, pending_write, …) into conversation doc."""
    def _q():
        (
            get_db().collection("farms")
            .document(farm_id)
            .collection("conversations")
            .document(conv_id)
            .set(updates, merge=True)
        )
    _run(_q)


async def get_conversation_history(farm_id: str, conv_id: str, limit: int = 10) -> List[Dict]:
    def _q():
        doc = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("conversations")
            .document(conv_id)
            .get()
        )
        if not doc.exists:
            return []
        return doc.to_dict().get("messages", [])[-limit:]
    return _run(_q)


async def get_latest_conversation(farm_id: str) -> Optional[Dict]:
    def _q():
        docs = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("conversations")
            .order_by("last_message_at", direction=firestore.Query.DESCENDING)
            .limit(1)
            .stream()
        )
        for doc in docs:
            c = doc.to_dict()
            c["conversation_id"] = doc.id
            return c
        return None
    return _run(_q)


async def delete_conversation(farm_id: str, conv_id: str) -> None:
    def _q():
        (
            get_db().collection("farms")
            .document(farm_id)
            .collection("conversations")
            .document(conv_id)
            .delete()
        )
    _run(_q)


async def save_conversation_turn(
    farm_id: str,
    conv_id: str,
    user_msg: str,
    ai_msg: str,
    tools_called: List[str],
) -> None:
    now = datetime.now(timezone.utc).isoformat()
    new_msgs = [
        {"role": "user", "content": user_msg, "timestamp": now},
        {"role": "assistant", "content": ai_msg, "timestamp": now, "tools_called": tools_called},
    ]
    def _q():
        ref = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("conversations")
            .document(conv_id)
        )
        doc = ref.get()
        if doc.exists:
            msgs = doc.to_dict().get("messages", [])
            msgs.extend(new_msgs)
            ref.set({"messages": msgs, "last_message_at": now}, merge=True)
        else:
            ref.set({"started_at": now, "last_message_at": now, "messages": new_msgs})
    _run(_q)


# ─── Animal history ───────────────────────────────────────────────

async def get_animal_history(farm_id: str, ear_tag: str) -> Dict:
    def _q():
        cases_docs = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("cases")
            .where("ear_tag", "==", ear_tag)
            .stream()
        )
        cases = [dict(d.to_dict(), case_id=d.id) for d in cases_docs]

        events_docs = (
            get_db().collection("farms")
            .document(farm_id)
            .collection("events")
            .where("ear_tag", "==", ear_tag)
            .stream()
        )
        events = [dict(d.to_dict(), event_id=d.id) for d in events_docs]
        return cases, events
    cases, events = _run(_q)

    vaccinations = [e for e in events if e.get("event_type") == "vaccination"]
    weights = [e for e in events if e.get("event_type") == "weight"]
    return {
        "cases": sorted(cases, key=lambda x: x.get("opened_at", ""), reverse=True),
        "vaccinations": sorted(vaccinations, key=lambda x: x.get("timestamp", ""), reverse=True),
        "weights": sorted(weights, key=lambda x: x.get("timestamp", ""), reverse=True),
        "events": sorted(events, key=lambda x: x.get("timestamp", ""), reverse=True),
    }


# ─── RAG knowledge ────────────────────────────────────────────────

async def save_rag_pattern(pattern: Dict) -> None:
    pattern_id = uuid.uuid4().hex[:8]
    now = datetime.now(timezone.utc).isoformat()
    pattern.update({"created_at": now, "updated_at": now, "case_count": 1})
    def _q():
        get_db().collection("rag_knowledge").document(pattern_id).set(pattern)
    _run(_q)


async def search_rag(
    species: str, symptoms_list: List[str], body_part: Optional[str] = None
) -> List[Dict]:
    def _q():
        docs = get_db().collection("rag_knowledge").where("species", "==", species).limit(200).stream()
        return list(docs)
    docs = _run(_q)

    q_symptoms = set(s.lower() for s in symptoms_list)
    results = []
    for doc in docs:
        p = doc.to_dict()
        p["pattern_id"] = doc.id
        p_symptoms = set(s.lower() for s in p.get("symptoms", []))
        overlap = len(p_symptoms & q_symptoms)
        if overlap == 0:
            continue
        score = overlap / max(len(p_symptoms | q_symptoms), 1)
        if body_part and p.get("body_part", "").lower() == body_part.lower():
            score += 0.2
        p["_match_score"] = round(score, 3)
        results.append(p)
    results.sort(key=lambda x: x["_match_score"], reverse=True)
    return results[:5]

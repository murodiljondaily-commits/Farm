import os
import json
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any

import firebase_admin
from firebase_admin import credentials, firestore, storage as fb_storage


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
    firebase_admin.initialize_app(cred, {
        "storageBucket": os.environ.get("FIREBASE_STORAGE_BUCKET", "agrivet-backend.appspot.com")
    })
    print(f"[Firebase] Initialized: project={cred_dict.get('project_id')} bucket={os.environ.get('FIREBASE_STORAGE_BUCKET')}")


def get_db():
    _init_firebase()
    return firestore.client()


# ─── Farm ────────────────────────────────────────────────────────

async def get_farm(farm_id: str) -> Optional[Dict]:
    doc = get_db().collection("farms").document(farm_id).get()
    return doc.to_dict() if doc.exists else None


# ─── Animals ─────────────────────────────────────────────────────

async def get_all_animals(
    farm_id: str,
    species: Optional[str] = None,
    status: Optional[str] = None,
) -> List[Dict]:
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


async def get_animal(farm_id: str, ear_tag: str) -> Optional[Dict]:
    doc = get_db().collection("farms").document(farm_id).collection("animals").document(ear_tag).get()
    if doc.exists:
        a = doc.to_dict()
        a["ear_tag"] = doc.id
        return a
    # Fuzzy match by name or partial tag
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
    get_db().collection("farms").document(farm_id).collection("animals").document(ear_tag).set(
        data, merge=True
    )


# ─── Cases ───────────────────────────────────────────────────────

async def create_case(farm_id: str, case_data: Dict) -> str:
    case_id = uuid.uuid4().hex[:8]
    case_data["case_id"] = case_id
    case_data["opened_at"] = datetime.now(timezone.utc).isoformat()
    case_data["closed_at"] = None
    get_db().collection("farms").document(farm_id).collection("cases").document(case_id).set(case_data)
    return case_id


async def get_case(farm_id: str, case_id: str) -> Optional[Dict]:
    doc = get_db().collection("farms").document(farm_id).collection("cases").document(case_id).get()
    if doc.exists:
        c = doc.to_dict()
        c["case_id"] = doc.id
        return c
    return None


async def update_case(farm_id: str, case_id: str, data: Dict) -> None:
    get_db().collection("farms").document(farm_id).collection("cases").document(case_id).set(
        data, merge=True
    )


async def get_active_cases(farm_id: str) -> List[Dict]:
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


# ─── Events ──────────────────────────────────────────────────────

async def create_event(farm_id: str, event_data: Dict) -> str:
    event_id = uuid.uuid4().hex[:8]
    event_data["event_id"] = event_id
    event_data["timestamp"] = datetime.now(timezone.utc).isoformat()
    get_db().collection("farms").document(farm_id).collection("events").document(event_id).set(event_data)
    return event_id


async def get_recent_events(farm_id: str, days: int = 7) -> List[Dict]:
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
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


# ─── Conversations ────────────────────────────────────────────────

async def get_conversation_history(farm_id: str, conv_id: str, limit: int = 10) -> List[Dict]:
    doc = (
        get_db().collection("farms")
        .document(farm_id)
        .collection("conversations")
        .document(conv_id)
        .get()
    )
    if not doc.exists:
        return []
    messages = doc.to_dict().get("messages", [])
    return messages[-limit:]


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


# ─── Animal history ───────────────────────────────────────────────

async def get_animal_history(farm_id: str, ear_tag: str) -> Dict:
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
    get_db().collection("rag_knowledge").document(pattern_id).set(pattern)


async def search_rag(
    species: str, symptoms_list: List[str], body_part: Optional[str] = None
) -> List[Dict]:
    docs = get_db().collection("rag_knowledge").where("species", "==", species).limit(200).stream()
    results = []
    q_symptoms = set(s.lower() for s in symptoms_list)
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

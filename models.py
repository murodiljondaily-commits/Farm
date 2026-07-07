from pydantic import BaseModel
from typing import Optional, List, Dict, Any


class ChatRequest(BaseModel):
    farm_id: str
    user_id: str = "anonymous"
    user_role: str = "owner"
    message: str
    conversation_id: Optional[str] = None
    vet_mode: bool = False


class ProposedAction(BaseModel):
    action: str
    params: Dict[str, Any] = {}
    affected_animals: List[str] = []
    summary: str = ""


class ChatResponse(BaseModel):
    response: str
    conversation_id: str
    vet_mode: bool
    tools_called: List[str]
    data_saved: Dict[str, Any] = {}
    # Phase 1: write tools are PROPOSED, not executed. The app renders a confirm
    # card and calls /confirm-action to actually run them.
    proposed_actions: List[ProposedAction] = []
    # Phase 4: confidence % lifted out of the text so the app shows a badge.
    confidence: int = 0


class ConfirmActionRequest(BaseModel):
    farm_id: str
    action: str
    params: Dict[str, Any] = {}
    conversation_id: Optional[str] = None


class SyncRequest(BaseModel):
    tab_name: str
    row_data: List[Any]


class CreateSheetRequest(BaseModel):
    owner_email: str


class SyncAnimalsRequest(BaseModel):
    animals: List[Dict[str, Any]]


class CreateFarmRequest(BaseModel):
    farm_id: str
    farm_name: str
    farm_code: str
    location: str
    owner_name: str
    owner_email: Optional[str] = None
    owner_uid: Optional[str] = None
    phone: Optional[str] = None


class TtsRequest(BaseModel):
    text: str


class AssignCaseRequest(BaseModel):
    ear_tag: str


class UpdateCaseStatusRequest(BaseModel):
    status: str

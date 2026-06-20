from pydantic import BaseModel
from typing import Optional, List, Dict, Any


class ChatRequest(BaseModel):
    farm_id: str
    user_id: str = "anonymous"
    user_role: str = "owner"
    message: str
    conversation_id: Optional[str] = None
    vet_mode: bool = False


class ChatResponse(BaseModel):
    response: str
    conversation_id: str
    vet_mode: bool
    tools_called: List[str]
    data_saved: Dict[str, Any] = {}


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
    phone: Optional[str] = None

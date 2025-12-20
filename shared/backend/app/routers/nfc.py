"""
1812 國會風雲 - NFC 卡片驗證 API 端點
支援 UID 驗證 + NDEF 資料驗證
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import json
import hashlib
from pathlib import Path

router = APIRouter(prefix="/api/nfc", tags=["NFC"])

# ═══════════════════════════════════════════════════════════════
# 資料模型
# ═══════════════════════════════════════════════════════════════

class NFCVerifyRequest(BaseModel):
    """NFC UID 驗證請求"""
    uid: str
    signature: str

class NFCDataVerifyRequest(BaseModel):
    """NFC NDEF 資料驗證請求"""
    uid: str
    data: dict

class NFCVerifyResponse(BaseModel):
    """NFC 驗證回應"""
    valid: bool
    error: Optional[str] = None
    role_id: Optional[str] = None
    role_name: Optional[str] = None
    role_title: Optional[str] = None
    faction: Optional[str] = None
    is_special: Optional[bool] = None
    abilities: Optional[list] = None

class CardInfo(BaseModel):
    """卡片資訊"""
    uid: str
    role_id: str
    role_name: str
    card_index: int
    is_active: bool

# ═══════════════════════════════════════════════════════════════
# 角色資料庫
# ═══════════════════════════════════════════════════════════════

VALID_ROLES = {
    "king_george_iii": {
        "name": "喬治三世",
        "title": "大不列顛國王",
        "faction": "crown",
        "is_special": True,
        "abilities": ["royal_decree", "madness_of_king", "dissolve_parliament"]
    },
    "worker_thomas": {
        "name": "湯瑪斯",
        "title": "紡織工人",
        "faction": "workers",
        "is_special": False,
        "abilities": ["skilled_hands", "family_burden", "fair_demand"]
    },
    "factory_wilson": {
        "name": "理查·威爾森",
        "title": "工廠主",
        "faction": "industrialists",
        "is_special": False,
        "abilities": ["capital_power", "machine_investment", "political_lobby"]
    },
    "luddite_george": {
        "name": "喬治",
        "title": "盧德派成員",
        "faction": "luddites",
        "is_special": False,
        "abilities": ["machine_breaker", "underground_network", "martyrdom"]
    },
    "reformer_owen": {
        "name": "羅伯特·烏爾文",
        "title": "社會改革者",
        "faction": "reformers",
        "is_special": False,
        "abilities": ["utopian_vision", "education_reform", "mediation"]
    },
    "mp_fitzgerald": {
        "name": "威廉·菲茨傑拉德",
        "title": "國會議員",
        "faction": "parliament",
        "is_special": False,
        "abilities": ["political_influence", "law_proposal", "vote_manipulation"]
    }
}

# ═══════════════════════════════════════════════════════════════
# 卡片驗證服務
# ═══════════════════════════════════════════════════════════════

class NFCAuthService:
    """NFC 卡片驗證服務"""
    
    def __init__(self):
        # 已註冊的卡片 UID（可選，用於額外驗證）
        self.registered_uids = set()
    
    def verify_ndef_data(self, uid: str, data: dict) -> NFCVerifyResponse:
        """驗證 NDEF 資料中的角色資訊"""
        
        # 取得角色 ID
        role_id = data.get('id')
        
        if not role_id:
            return NFCVerifyResponse(
                valid=False,
                error="MISSING_ROLE_ID"
            )
        
        # 檢查是否為有效角色
        if role_id not in VALID_ROLES:
            return NFCVerifyResponse(
                valid=False,
                error="INVALID_ROLE"
            )
        
        role = VALID_ROLES[role_id]
        
        # 驗證資料完整性（檢查必要欄位）
        required_fields = ['id', 'name', 'faction']
        for field in required_fields:
            if field not in data:
                return NFCVerifyResponse(
                    valid=False,
                    error=f"MISSING_FIELD_{field.upper()}"
                )
        
        # 驗證角色名稱是否匹配
        if data.get('name') != role['name']:
            return NFCVerifyResponse(
                valid=False,
                error="NAME_MISMATCH"
            )
        
        # 驗證陣營是否匹配
        if data.get('faction') != role['faction']:
            return NFCVerifyResponse(
                valid=False,
                error="FACTION_MISMATCH"
            )
        
        # 驗證通過！
        return NFCVerifyResponse(
            valid=True,
            role_id=role_id,
            role_name=role['name'],
            role_title=role['title'],
            faction=role['faction'],
            is_special=role['is_special'],
            abilities=role['abilities']
        )

# 初始化服務
nfc_service = NFCAuthService()

# ═══════════════════════════════════════════════════════════════
# API 端點
# ═══════════════════════════════════════════════════════════════

@router.post("/verify-data", response_model=NFCVerifyResponse)
async def verify_nfc_data(request: NFCDataVerifyRequest):
    """
    驗證 NFC 卡片上的 NDEF 資料
    
    - **uid**: 卡片 UID
    - **data**: 從卡片讀取的 JSON 資料
    
    成功回傳完整角色資訊，失敗回傳錯誤代碼
    """
    return nfc_service.verify_ndef_data(request.uid, request.data)

@router.get("/roles")
async def list_valid_roles():
    """
    列出所有有效角色（供參考）
    """
    return VALID_ROLES

@router.get("/role/{role_id}")
async def get_role_info(role_id: str):
    """
    取得特定角色的詳細資訊
    """
    if role_id not in VALID_ROLES:
        raise HTTPException(status_code=404, detail="角色不存在")
    return VALID_ROLES[role_id]

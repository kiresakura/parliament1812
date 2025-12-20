#!/usr/bin/env python3
"""
1812 Parliament - NFC 本地讀卡服務
提供 HTTP API 讓 Flutter App 讀取 NFC 卡片
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from smartcard.System import readers
from smartcard.util import toHexString
import json
import uvicorn

app = FastAPI(title="1812 Parliament NFC Service", version="1.0.0")

# CORS 設定（允許 Flutter App 連接）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ═══════════════════════════════════════════════════════════════
# 資料模型
# ═══════════════════════════════════════════════════════════════

class NFCReadResponse(BaseModel):
    success: bool
    uid: Optional[str] = None
    data: Optional[dict] = None
    error: Optional[str] = None

class NFCStatusResponse(BaseModel):
    reader_connected: bool
    reader_name: Optional[str] = None
    card_present: bool

# ═══════════════════════════════════════════════════════════════
# NFC 讀取函數
# ═══════════════════════════════════════════════════════════════

def get_reader():
    """取得讀卡器"""
    r = readers()
    return r[0] if r else None

def read_ndef_from_card(connection) -> Optional[str]:
    """從卡片讀取 NDEF Text"""
    all_data = []
    
    for page in range(4, 44):
        cmd = [0xFF, 0xB0, 0x00, page, 0x04]
        response, sw1, sw2 = connection.transmit(cmd)
        if sw1 == 0x90:
            all_data.extend(response)
        else:
            break
    
    if not all_data:
        return None
    
    data = bytes(all_data)
    
    idx = 0
    while idx < len(data):
        tlv_type = data[idx]
        if tlv_type == 0x00:
            idx += 1
            continue
        if tlv_type == 0xFE:
            break
        if tlv_type == 0x03:
            ndef_len = data[idx + 1]
            ndef_msg = data[idx + 2:idx + 2 + ndef_len]
            
            if len(ndef_msg) < 4:
                return None
            
            type_len = ndef_msg[1]
            payload_len = ndef_msg[2]
            rec_type = chr(ndef_msg[3])
            
            if rec_type == 'T':
                payload = ndef_msg[4:4 + payload_len]
                lang_len = payload[0] & 0x3F
                text = payload[1 + lang_len:].decode('utf-8')
                return text
            break
        idx += 2 + data[idx + 1]
    
    return None

# ═══════════════════════════════════════════════════════════════
# API 端點
# ═══════════════════════════════════════════════════════════════

@app.get("/")
async def root():
    return {"service": "1812 Parliament NFC Service", "version": "1.0.0"}

@app.get("/status", response_model=NFCStatusResponse)
async def get_status():
    """檢查讀卡器和卡片狀態"""
    reader = get_reader()
    
    if not reader:
        return NFCStatusResponse(
            reader_connected=False,
            card_present=False
        )
    
    card_present = False
    try:
        conn = reader.createConnection()
        conn.connect()
        card_present = True
        conn.disconnect()
    except:
        pass
    
    return NFCStatusResponse(
        reader_connected=True,
        reader_name=str(reader),
        card_present=card_present
    )

@app.get("/read", response_model=NFCReadResponse)
async def read_card():
    """讀取 NFC 卡片上的角色資料"""
    reader = get_reader()
    
    if not reader:
        return NFCReadResponse(
            success=False,
            error="NO_READER"
        )
    
    try:
        connection = reader.createConnection()
        connection.connect()
        
        # 讀取 UID
        GET_UID = [0xFF, 0xCA, 0x00, 0x00, 0x00]
        uid_response, sw1, sw2 = connection.transmit(GET_UID)
        uid = toHexString(uid_response).replace(' ', '') if sw1 == 0x90 else None
        
        # 讀取 NDEF
        text = read_ndef_from_card(connection)
        
        if not text:
            return NFCReadResponse(
                success=False,
                uid=uid,
                error="NO_NDEF_DATA"
            )
        
        # 解析 JSON
        try:
            data = json.loads(text)
            return NFCReadResponse(
                success=True,
                uid=uid,
                data=data
            )
        except json.JSONDecodeError:
            return NFCReadResponse(
                success=False,
                uid=uid,
                error="INVALID_JSON"
            )
            
    except Exception as e:
        return NFCReadResponse(
            success=False,
            error=f"READ_ERROR: {str(e)}"
        )

@app.post("/write")
async def write_card(role_data: dict):
    """寫入角色資料到 NFC 卡片"""
    reader = get_reader()
    
    if not reader:
        raise HTTPException(status_code=503, detail="NO_READER")
    
    try:
        connection = reader.createConnection()
        connection.connect()
        
        # 編碼並寫入
        text = json.dumps(role_data, ensure_ascii=False)
        text_bytes = text.encode('utf-8')
        
        lang = b'zh'
        lang_len = len(lang)
        payload = bytes([lang_len]) + lang + text_bytes
        payload_len = len(payload)
        
        ndef_record = bytes([0xD1, 0x01, payload_len, 0x54]) + payload
        ndef_tlv = bytes([0x03, len(ndef_record)]) + ndef_record + bytes([0xFE])
        
        # 補齊
        data = ndef_tlv
        while len(data) % 4 != 0:
            data += bytes([0x00])
        
        # 寫入
        page = 4
        for i in range(0, len(data), 4):
            chunk = list(data[i:i+4])
            cmd = [0xFF, 0xD6, 0x00, page, 0x04] + chunk
            response, sw1, sw2 = connection.transmit(cmd)
            if sw1 != 0x90:
                raise HTTPException(status_code=500, detail=f"WRITE_FAILED_PAGE_{page}")
            page += 1
        
        return {"success": True, "message": "寫入成功"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ═══════════════════════════════════════════════════════════════
# 主程式
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 50)
    print("🏰 1812 Parliament - NFC 本地讀卡服務")
    print("   http://localhost:8888")
    print("=" * 50)
    uvicorn.run(app, host="0.0.0.0", port=8888)

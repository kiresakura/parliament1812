#!/usr/bin/env python3
"""
1812 Parliament - NFC 角色卡寫入腳本 (pyscard版)
寫入角色：喬治三世（國王）
"""

from smartcard.System import readers
from smartcard.util import toHexString, toBytes
import json

# 喬治三世角色資料
KING_GEORGE_III = {
    "id": "king_george_iii",
    "name": "喬治三世",
    "title": "大不列顛國王", 
    "alias": "農夫喬治",
    "faction": "crown",
    "role_type": "special"
}

def get_reader():
    """取得ACR122U讀卡器"""
    r = readers()
    if not r:
        print("❌ 找不到讀卡器！請確認 ACR122U 已連接")
        return None
    print(f"✅ 找到讀卡器: {r[0]}")
    return r[0]

def write_ndef_text(connection, text):
    """寫入NDEF Text記錄到NTAG卡"""
    # 編碼文字
    text_bytes = text.encode('utf-8')
    text_len = len(text_bytes)
    
    # NDEF 訊息結構
    # TLV: Type=0x03(NDEF), Length, Value
    # NDEF Record: TNF+Flags, Type Length, Payload Length, Type, Payload
    
    lang = b'zh'
    lang_len = len(lang)
    
    # NDEF Record Header
    # TNF=0x01 (Well Known), SR=1, ME=1, MB=1 → 0xD1
    # Type: 'T' (0x54) for Text
    payload = bytes([lang_len]) + lang + text_bytes
    payload_len = len(payload)
    
    ndef_record = bytes([0xD1, 0x01, payload_len, 0x54]) + payload
    ndef_msg_len = len(ndef_record)
    
    # TLV wrapper
    ndef_tlv = bytes([0x03, ndef_msg_len]) + ndef_record + bytes([0xFE])  # 0xFE = Terminator
    
    print(f"   NDEF 訊息長度: {len(ndef_tlv)} bytes")
    
    # NTAG 從 page 4 開始寫入用戶資料
    # 每個 page 4 bytes
    page = 4
    data = ndef_tlv
    
    # 補齊到4的倍數
    while len(data) % 4 != 0:
        data += bytes([0x00])
    
    # 分頁寫入
    for i in range(0, len(data), 4):
        chunk = list(data[i:i+4])
        # WRITE command: 0xFF 0xD6 0x00 page 0x04 data[4]
        cmd = [0xFF, 0xD6, 0x00, page, 0x04] + chunk
        response, sw1, sw2 = connection.transmit(cmd)
        
        if sw1 != 0x90:
            print(f"   ❌ 寫入 page {page} 失敗: SW={sw1:02X}{sw2:02X}")
            return False
        page += 1
    
    return True

def main():
    print("=" * 50)
    print("🏰 1812 Parliament - NFC 角色卡寫入")
    print("   角色：大不列顛國王 - 喬治三世")
    print("=" * 50)
    
    reader = get_reader()
    if not reader:
        return
    
    print("\n🔍 請將 NFC 卡片放到讀卡器上...")
    
    try:
        connection = reader.createConnection()
        connection.connect()
        print("✅ 卡片已連接!")
        
        # 取得卡片 UID
        GET_UID = [0xFF, 0xCA, 0x00, 0x00, 0x00]
        uid, sw1, sw2 = connection.transmit(GET_UID)
        if sw1 == 0x90:
            print(f"   卡片 UID: {toHexString(uid)}")
        
        # 準備寫入資料
        data = json.dumps(KING_GEORGE_III, ensure_ascii=False)
        print(f"\n📝 寫入資料:")
        print(f"   {data}")
        
        # 寫入
        if write_ndef_text(connection, data):
            print("\n🎉 寫入成功！！喬治三世角色卡已就緒！！")
        else:
            print("\n❌ 寫入失敗")
            
    except Exception as e:
        print(f"\n❌ 錯誤: {e}")
        print("   請確認卡片已放置在讀卡器上")

if __name__ == "__main__":
    main()

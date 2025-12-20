#!/usr/bin/env python3
"""
1812 Parliament - NFC 角色卡讀取驗證腳本
"""

from smartcard.System import readers
from smartcard.util import toHexString
import json

def get_reader():
    r = readers()
    if not r:
        print("❌ 找不到讀卡器！")
        return None
    print(f"✅ 讀卡器: {r[0]}")
    return r[0]

def read_ndef_text(connection):
    """從NTAG卡讀取NDEF Text記錄"""
    all_data = []
    
    # 讀取 page 4-43（160 bytes）
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
    print(f"   讀取了 {len(data)} bytes")
    
    # 找 NDEF TLV (0x03)
    idx = 0
    while idx < len(data):
        tlv_type = data[idx]
        if tlv_type == 0x00:  # NULL TLV
            idx += 1
            continue
        if tlv_type == 0xFE:  # Terminator
            break
        if tlv_type == 0x03:  # NDEF Message
            ndef_len = data[idx + 1]
            ndef_msg = data[idx + 2:idx + 2 + ndef_len]
            
            # 解析 NDEF Record
            if len(ndef_msg) < 4:
                return None
            
            type_len = ndef_msg[1]
            payload_len = ndef_msg[2]
            rec_type = chr(ndef_msg[3])
            
            if rec_type == 'T':
                payload_start = 4
                payload = ndef_msg[payload_start:payload_start + payload_len]
                lang_len = payload[0] & 0x3F
                text = payload[1 + lang_len:].decode('utf-8')
                return text
            break
        idx += 2 + data[idx + 1]
    
    return None

def main():
    print("=" * 50)
    print("🔍 1812 Parliament - NFC 角色卡讀取驗證")
    print("=" * 50)
    
    reader = get_reader()
    if not reader:
        return
    
    print("\n📡 請將 NFC 卡片放到讀卡器上...")
    
    try:
        connection = reader.createConnection()
        connection.connect()
        print("✅ 卡片已連接!")
        
        GET_UID = [0xFF, 0xCA, 0x00, 0x00, 0x00]
        uid, sw1, sw2 = connection.transmit(GET_UID)
        uid_str = toHexString(uid) if sw1 == 0x90 else "unknown"
        print(f"   UID: {uid_str}")
        
        print("\n📖 讀取卡片資料...")
        text = read_ndef_text(connection)
        
        if text:
            print(f"\n✅ 讀取成功!")
            
            try:
                data = json.loads(text)
                print("\n" + "=" * 50)
                print("🎭 角色卡資訊")
                print("=" * 50)
                for key, val in data.items():
                    print(f"   {key}: {val}")
                print("=" * 50)
                print("✅ 驗證通過！！")
            except:
                print(f"   原始: {text}")
        else:
            print("❌ 無法讀取")
            
    except Exception as e:
        print(f"\n❌ 錯誤: {e}")

if __name__ == "__main__":
    main()

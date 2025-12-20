#!/usr/bin/env python3
"""
1812 國會風雲 - ACR122U NFC 卡片綁定工具
使用卡片 UID 作為防複製驗證

需要安裝：
    pip3 install pyscard

macOS 額外需要：
    brew install pcsc-lite
"""

import json
import hashlib
import secrets
from datetime import datetime
from typing import Optional, Dict, List
from dataclasses import dataclass, asdict

# 嘗試導入 smartcard 模組
try:
    from smartcard.System import readers
    from smartcard.util import toHexString, toBytes
    from smartcard.Exceptions import NoCardException, CardConnectionException
    SMARTCARD_AVAILABLE = True
except ImportError:
    SMARTCARD_AVAILABLE = False
    print("⚠️  pyscard 未安裝，請執行: pip3 install pyscard")

from role_data import ALL_ROLES

# ═══════════════════════════════════════════════════════════════
# 資料結構
# ═══════════════════════════════════════════════════════════════

@dataclass
class BoundCard:
    """已綁定的卡片資料"""
    card_uid: str           # 7-byte UID (hex string)
    role_id: str            # 角色 ID
    card_index: int         # 該角色的第幾張卡
    secret_hash: str        # 驗證用 hash
    signature: str          # UID + secret 的簽名
    bound_at: str           # 綁定時間
    is_active: bool = True  # 是否啟用

class NFCCardBinder:
    """NFC 卡片綁定管理器"""
    
    # ACR122U APDU 指令
    GET_UID_CMD = [0xFF, 0xCA, 0x00, 0x00, 0x00]  # 取得 UID
    
    # 簽名用的密鑰（正式環境應該用環境變數或安全儲存）
    SIGNING_KEY = "parliament1812_secret_key_change_in_production"
    
    def __init__(self, db_path: str = "bound_cards.json"):
        self.db_path = db_path
        self.bound_cards: Dict[str, BoundCard] = {}
        self.reader = None
        self.connection = None
        self._load_database()
    
    def _load_database(self):
        """載入已綁定卡片資料庫"""
        try:
            with open(self.db_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for uid, card_data in data.get('cards', {}).items():
                    self.bound_cards[uid] = BoundCard(**card_data)
            print(f"📂 已載入 {len(self.bound_cards)} 張已綁定卡片")
        except FileNotFoundError:
            print("📂 建立新的卡片資料庫")
        except Exception as e:
            print(f"⚠️  載入資料庫失敗: {e}")
    
    def _save_database(self):
        """儲存已綁定卡片資料庫"""
        data = {
            "updated_at": datetime.now().isoformat(),
            "total_cards": len(self.bound_cards),
            "cards": {uid: asdict(card) for uid, card in self.bound_cards.items()}
        }
        with open(self.db_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"💾 已儲存 {len(self.bound_cards)} 張卡片資料")
    
    def connect_reader(self) -> bool:
        """連接 ACR122U 讀卡機"""
        if not SMARTCARD_AVAILABLE:
            print("❌ pyscard 未安裝")
            return False
        
        try:
            available_readers = readers()
            if not available_readers:
                print("❌ 找不到讀卡機，請確認 ACR122U 已連接")
                return False
            
            # 尋找 ACR122U
            for r in available_readers:
                if 'ACR122' in str(r) or 'ACS' in str(r):
                    self.reader = r
                    print(f"✅ 已連接讀卡機: {r}")
                    return True
            
            # 如果沒找到 ACR122U，使用第一個讀卡機
            self.reader = available_readers[0]
            print(f"✅ 已連接讀卡機: {self.reader}")
            return True
            
        except Exception as e:
            print(f"❌ 連接讀卡機失敗: {e}")
            return False
    
    def read_card_uid(self) -> Optional[str]:
        """讀取卡片 UID"""
        if not self.reader:
            print("❌ 讀卡機未連接")
            return None
        
        try:
            connection = self.reader.createConnection()
            connection.connect()
            
            # 發送 GET UID 指令
            response, sw1, sw2 = connection.transmit(self.GET_UID_CMD)
            
            if sw1 == 0x90 and sw2 == 0x00:
                uid = toHexString(response).replace(' ', '')
                print(f"📇 卡片 UID: {uid}")
                return uid
            else:
                print(f"❌ 讀取 UID 失敗: SW={sw1:02X}{sw2:02X}")
                return None
                
        except NoCardException:
            print("⚠️  請將卡片放在讀卡機上")
            return None
        except CardConnectionException as e:
            print(f"❌ 卡片連接錯誤: {e}")
            return None
        except Exception as e:
            print(f"❌ 讀取錯誤: {e}")
            return None
    
    def generate_signature(self, uid: str, role_id: str, secret: str) -> str:
        """生成防偽簽名"""
        # 使用 HMAC-like 簽名
        message = f"{uid}:{role_id}:{secret}:{self.SIGNING_KEY}"
        return hashlib.sha256(message.encode()).hexdigest()[:16].upper()
    
    def verify_signature(self, uid: str, role_id: str, secret: str, signature: str) -> bool:
        """驗證簽名"""
        expected = self.generate_signature(uid, role_id, secret)
        return expected == signature
    
    def bind_card(self, role_id: str, card_index: int = 1) -> Optional[BoundCard]:
        """綁定卡片到角色"""
        # 檢查角色是否存在
        if role_id not in ALL_ROLES:
            print(f"❌ 角色不存在: {role_id}")
            return None
        
        role = ALL_ROLES[role_id]
        
        # 讀取卡片 UID
        print(f"\n🔄 準備綁定【{role.name_zh}】卡片 #{card_index}")
        print("請將 NFC 卡片放在 ACR122U 上...")
        
        uid = self.read_card_uid()
        if not uid:
            return None
        
        # 檢查是否已綁定
        if uid in self.bound_cards:
            existing = self.bound_cards[uid]
            print(f"⚠️  此卡片已綁定為【{ALL_ROLES[existing.role_id].name_zh}】")
            confirm = input("是否覆蓋？(y/N): ").strip().lower()
            if confirm != 'y':
                print("已取消")
                return None
        
        # 生成密鑰和簽名
        secret = secrets.token_hex(4).upper()
        signature = self.generate_signature(uid, role_id, secret)
        
        # 建立綁定記錄
        bound_card = BoundCard(
            card_uid=uid,
            role_id=role_id,
            card_index=card_index,
            secret_hash=secret,
            signature=signature,
            bound_at=datetime.now().isoformat()
        )
        
        self.bound_cards[uid] = bound_card
        self._save_database()
        
        # 生成要寫入卡片的 URL
        nfc_url = f"parliament1812://role?uid={uid}&sig={signature}"
        
        print(f"\n✅ 綁定成功！")
        print(f"   角色: {role.name_zh} ({role.name_en})")
        print(f"   UID: {uid}")
        print(f"   簽名: {signature}")
        print(f"\n📝 請將此 URL 寫入卡片:")
        print(f"   {nfc_url}")
        
        return bound_card
    
    def verify_card(self, uid: str, signature: str) -> Optional[Dict]:
        """驗證卡片（後端 API 用）"""
        if uid not in self.bound_cards:
            return {"valid": False, "error": "卡片未註冊"}
        
        card = self.bound_cards[uid]
        
        if not card.is_active:
            return {"valid": False, "error": "卡片已停用"}
        
        if card.signature != signature:
            return {"valid": False, "error": "簽名不符，可能是偽造卡片"}
        
        role = ALL_ROLES.get(card.role_id)
        if not role:
            return {"valid": False, "error": "角色資料錯誤"}
        
        return {
            "valid": True,
            "role_id": card.role_id,
            "role_name": role.name_zh,
            "card_index": card.card_index,
            "is_special": role.is_special
        }
    
    def list_bound_cards(self):
        """列出所有已綁定卡片"""
        print("\n" + "=" * 60)
        print("📋 已綁定卡片清單")
        print("=" * 60)
        
        if not self.bound_cards:
            print("（尚無綁定卡片）")
            return
        
        for uid, card in self.bound_cards.items():
            role = ALL_ROLES.get(card.role_id)
            role_name = role.name_zh if role else "未知角色"
            status = "✅" if card.is_active else "❌"
            special = "👑" if role and role.is_special else "  "
            print(f"{status} {special} {role_name} #{card.card_index}")
            print(f"      UID: {uid}")
            print(f"      簽名: {card.signature}")
            print()
    
    def export_for_backend(self, filename: str = "card_auth_database.json"):
        """匯出給後端使用的驗證資料庫"""
        export_data = {
            "generated_at": datetime.now().isoformat(),
            "cards": {}
        }
        
        for uid, card in self.bound_cards.items():
            export_data["cards"][uid] = {
                "signature": card.signature,
                "role_id": card.role_id,
                "card_index": card.card_index,
                "is_active": card.is_active
            }
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(export_data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ 已匯出後端驗證資料到 {filename}")


def interactive_menu():
    """互動式選單"""
    binder = NFCCardBinder()
    
    # 嘗試連接讀卡機
    if SMARTCARD_AVAILABLE:
        binder.connect_reader()
    
    while True:
        print("\n" + "=" * 60)
        print("🎭 1812 國會風雲 - NFC 卡片管理")
        print("=" * 60)
        print("1. 綁定新卡片")
        print("2. 讀取卡片 UID")
        print("3. 列出已綁定卡片")
        print("4. 驗證卡片")
        print("5. 匯出後端資料庫")
        print("6. 批量綁定所有角色")
        print("0. 離開")
        print("-" * 60)
        
        choice = input("請選擇功能: ").strip()
        
        if choice == '1':
            print("\n可用角色:")
            for i, (role_id, role) in enumerate(ALL_ROLES.items(), 1):
                special = "👑" if role.is_special else "  "
                print(f"  {special} {role_id}: {role.name_zh}")
            
            role_id = input("\n輸入角色 ID: ").strip()
            card_index = int(input("卡片編號 (1-3): ").strip() or "1")
            binder.bind_card(role_id, card_index)
        
        elif choice == '2':
            print("\n請將卡片放在讀卡機上...")
            uid = binder.read_card_uid()
            if uid:
                print(f"✅ UID: {uid}")
        
        elif choice == '3':
            binder.list_bound_cards()
        
        elif choice == '4':
            uid = input("輸入 UID: ").strip()
            sig = input("輸入簽名: ").strip()
            result = binder.verify_card(uid, sig)
            print(f"\n驗證結果: {json.dumps(result, ensure_ascii=False, indent=2)}")
        
        elif choice == '5':
            binder.export_for_backend()
        
        elif choice == '6':
            print("\n🔄 批量綁定模式")
            print("將依序綁定所有角色...")
            
            cards_config = {
                "george_iii": 1,
                "worker": 3,
                "factory": 2,
                "luddite": 3,
                "reformer": 2,
                "mp": 2,
            }
            
            for role_id, count in cards_config.items():
                role = ALL_ROLES[role_id]
                for i in range(1, count + 1):
                    print(f"\n{'='*40}")
                    print(f"準備綁定: {role.name_zh} #{i}")
                    input("放上卡片後按 Enter...")
                    binder.bind_card(role_id, i)
            
            print("\n✅ 批量綁定完成！")
            binder.export_for_backend()
        
        elif choice == '0':
            print("再見！👋")
            break
        
        else:
            print("無效選項")


if __name__ == "__main__":
    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║     🎭 1812 國會風雲 - ACR122U NFC 卡片綁定工具          ║
    ║                                                           ║
    ║  使用 UID 綁定防止卡片複製                                ║
    ╚═══════════════════════════════════════════════════════════╝
    """)
    
    if not SMARTCARD_AVAILABLE:
        print("⚠️  請先安裝 pyscard:")
        print("    pip3 install pyscard")
        print("\nmacOS 可能還需要:")
        print("    brew install pcsc-lite")
        print()
    
    interactive_menu()

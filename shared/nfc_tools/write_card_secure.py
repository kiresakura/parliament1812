#!/usr/bin/env python3
"""
1812 國會風雲 - 安全 NFC 卡片寫入工具
支援 ACR122U 讀卡機 + NTAG215 卡片
包含 UID 綁定防偽機制

安裝需求:
    pip3 install pyscard

macOS 額外需要:
    brew install pcsc-lite
"""

import json
import hashlib
import hmac
import os
from datetime import datetime
from typing import Optional, Tuple

# 嘗試導入 smartcard 模組
try:
    from smartcard.System import readers
    from smartcard.util import toHexString, toBytes
    from smartcard.Exceptions import NoCardException, CardConnectionException
    SMARTCARD_AVAILABLE = True
except ImportError:
    SMARTCARD_AVAILABLE = False
    print("⚠️  pyscard 未安裝，請執行: pip3 install pyscard")

# ═══════════════════════════════════════════════════════════════
# 配置
# ═══════════════════════════════════════════════════════════════

# 後端 SECRET_KEY（需與 Railway 環境變數一致）
# 正式環境請使用環境變數: os.environ.get('SECRET_KEY')
# 注意：必須與 Railway 生產環境的 SECRET_KEY 完全一致！
# Railway Production SECRET_KEY (從 railway variables 獲取)
SECRET_KEY = os.environ.get('SECRET_KEY', 'yg4mIGHDJOqyJ5svkiSLU7Ws6X+ORhXe/fcjx67nJtg=')

# 角色卡片配置 (每個角色 4 張卡片，對應 4 種秘密任務)
CARD_CONFIG = {
    "worker": {
        "role_id": "worker",
        "name_zh": "湯瑪斯",
        "name_en": "Thomas",
        "title": "紡織工人",
        "count": 4,
        "is_special": False,
        "missions": [
            "私藏的發明圖紙",
            "父親的仇恨",
            "工廠主的密使",
            "覺醒的領袖"
        ]
    },
    "factory_owner": {
        "role_id": "factory_owner",
        "name_zh": "理查·威爾森",
        "name_en": "Richard Wilson",
        "title": "工廠主",
        "count": 4,
        "is_special": False,
        "missions": [
            "隱藏的合約",
            "舊日的復仇",
            "雙面經營",
            "工業改革先驅"
        ]
    },
    "luddite": {
        "role_id": "luddite",
        "name_zh": "內德·勒德",
        "name_en": "Ned Ludd",
        "title": "盧德派成員",
        "count": 4,
        "is_special": False,
        "missions": [
            "失落的愛情",
            "弟弟的復仇",
            "和平的臥底",
            "暴力覺醒者"
        ]
    },
    "reformer": {
        "role_id": "reformer",
        "name_zh": "羅伯特·歐文",
        "name_en": "Robert Owen",
        "title": "社會改革者",
        "count": 4,
        "is_special": False,
        "missions": [
            "烏托邦實驗",
            "失敗者的怨恨",
            "激進改革派",
            "務實妥協者"
        ]
    },
    "mp": {
        "role_id": "mp",
        "name_zh": "威廉·乏茲傑羅",
        "name_en": "William Fitzgerald",
        "title": "國會議員",
        "count": 4,
        "is_special": False,
        "missions": [
            "秘密的賭債",
            "家族的血仇",
            "理想主義者",
            "實用主義者"
        ]
    },
    "george_iii": {
        "role_id": "george_iii",
        "name_zh": "喬治三世",
        "name_en": "George III",
        "title": "大不列顛國王",
        "count": 4,
        "is_special": True,
        "missions": [
            "王權的陰影",
            "瘋狂的復仇",
            "開明君主",
            "王室觀察者"
        ]
    }
}

# ═══════════════════════════════════════════════════════════════
# 安全函數
# ═══════════════════════════════════════════════════════════════

def generate_card_id(role_type: str, index: int) -> str:
    """
    生成卡片 ID（格式需與後端 NFC_CARD_MAPPING 一致）

    格式: WORKER01, FACTORY02, GEORGEIII01 等
    """
    # 角色類型轉換為後端期望的格式
    role_map = {
        "george_iii": "GEORGEIII",
        "worker": "WORKER",
        "factory_owner": "FACTORY",
        "factory": "FACTORY",
        "luddite": "LUDDITE",
        "reformer": "REFORMER",
        "mp": "MP",
    }
    role_prefix = role_map.get(role_type, role_type.upper().replace("_", ""))
    return f"{role_prefix}{index:02d}"

def generate_signature(card_id: str, uid: str = None) -> str:
    """
    生成防偽簽名

    基礎模式: 只用 card_id
    進階模式: card_id + UID 綁定（防複製）
    """
    if uid:
        # UID 綁定模式 - 更安全，卡片無法被複製
        # 注意：必須與後端 verify_nfc_signature 格式一致（全大寫）
        message = f"{card_id.upper()}:{uid.upper()}:{SECRET_KEY}"
    else:
        # 基礎模式 - 與後端相容
        message = card_id.upper()

    return hmac.new(
        SECRET_KEY.encode(),
        message.encode(),
        hashlib.sha256
    ).hexdigest()[:16].upper()

def generate_nfc_url(card_id: str, signature: str, uid: str = None) -> str:
    """生成 NFC URL"""
    if uid:
        # 帶 UID 的進階防偽格式（全大寫以匹配後端驗證）
        return f"parliament1812://role?id={card_id.upper()}&sig={signature.upper()}&uid={uid.upper()}"
    else:
        # 基礎格式（與現有後端相容）
        return f"parliament1812://role?id={card_id}&secret={signature}"

# ═══════════════════════════════════════════════════════════════
# ACR122U 操作類
# ═══════════════════════════════════════════════════════════════

class ACR122UWriter:
    """ACR122U NFC 卡片寫入器"""

    # APDU 指令
    GET_UID_CMD = [0xFF, 0xCA, 0x00, 0x00, 0x00]

    def __init__(self):
        self.reader = None
        self.connection = None

    def connect(self) -> bool:
        """連接讀卡機"""
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
                reader_name = str(r)
                if 'ACR122' in reader_name or 'ACS' in reader_name:
                    self.reader = r
                    print(f"✅ 已連接讀卡機: {reader_name}")
                    return True

            # 使用第一個可用讀卡機
            self.reader = available_readers[0]
            print(f"✅ 已連接讀卡機: {self.reader}")
            return True

        except Exception as e:
            print(f"❌ 連接讀卡機失敗: {e}")
            return False

    def read_uid(self) -> Optional[str]:
        """讀取卡片 UID"""
        if not self.reader:
            print("❌ 讀卡機未連接")
            return None

        try:
            connection = self.reader.createConnection()
            connection.connect()
            self.connection = connection

            response, sw1, sw2 = connection.transmit(self.GET_UID_CMD)

            if sw1 == 0x90 and sw2 == 0x00:
                uid = toHexString(response).replace(' ', '')
                return uid
            else:
                print(f"❌ 讀取 UID 失敗: SW={sw1:02X}{sw2:02X}")
                return None

        except NoCardException:
            print("⚠️  請將卡片放在讀卡機上")
            return None
        except Exception as e:
            print(f"❌ 讀取錯誤: {e}")
            return None

    def write_ndef_uri(self, uri: str) -> bool:
        """寫入 NDEF URI 記錄"""
        if not self.connection:
            print("❌ 請先讀取卡片")
            return False

        try:
            # 編碼 URI
            uri_bytes = uri.encode('utf-8')
            uri_len = len(uri_bytes)

            # NDEF Record 結構
            # TNF=0x01 (Well Known), SR=1, ME=1, MB=1 → 0xD1
            # Type: 'U' (0x55) for URI
            # Prefix: 0x00 (無前綴，自定義 scheme)
            payload = bytes([0x00]) + uri_bytes
            payload_len = len(payload)

            ndef_record = bytes([0xD1, 0x01, payload_len, 0x55]) + payload
            ndef_msg_len = len(ndef_record)

            # TLV 包裝
            ndef_tlv = bytes([0x03, ndef_msg_len]) + ndef_record + bytes([0xFE])

            print(f"   NDEF 訊息長度: {len(ndef_tlv)} bytes")

            # 補齊到 4 的倍數
            data = ndef_tlv
            while len(data) % 4 != 0:
                data += bytes([0x00])

            # 從 page 4 開始寫入（NTAG 用戶資料區）
            page = 4
            for i in range(0, len(data), 4):
                chunk = list(data[i:i+4])
                # WRITE 指令: 0xFF 0xD6 0x00 page 0x04 data[4]
                cmd = [0xFF, 0xD6, 0x00, page, 0x04] + chunk
                response, sw1, sw2 = self.connection.transmit(cmd)

                if sw1 != 0x90:
                    print(f"   ❌ 寫入 page {page} 失敗: SW={sw1:02X}{sw2:02X}")
                    return False
                page += 1

            return True

        except Exception as e:
            print(f"❌ 寫入失敗: {e}")
            return False

    def lock_card(self) -> bool:
        """鎖定卡片（防止篡改，可選）"""
        # TODO: 實作 NTAG 鎖定功能
        # 注意：鎖定後卡片無法再寫入！
        print("⚠️  卡片鎖定功能尚未實作")
        return False

# ═══════════════════════════════════════════════════════════════
# 卡片寫入資料庫
# ═══════════════════════════════════════════════════════════════

class CardDatabase:
    """已寫入卡片資料庫"""

    def __init__(self, db_path: str = "written_cards.json"):
        self.db_path = db_path
        self.cards = {}
        self._load()

    def _load(self):
        try:
            with open(self.db_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.cards = data.get('cards', {})
        except FileNotFoundError:
            self.cards = {}

    def save(self):
        data = {
            "updated_at": datetime.now().isoformat(),
            "total_cards": len(self.cards),
            "cards": self.cards
        }
        with open(self.db_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    def add_card(self, uid: str, card_id: str, role_id: str, signature: str, nfc_url: str):
        self.cards[uid] = {
            "card_id": card_id,
            "role_id": role_id,
            "signature": signature,
            "nfc_url": nfc_url,
            "written_at": datetime.now().isoformat()
        }
        self.save()

    def get_by_uid(self, uid: str) -> Optional[dict]:
        return self.cards.get(uid)

    def export_for_backend(self, filename: str = "card_auth_export.json"):
        """匯出給後端驗證用"""
        export = {
            "generated_at": datetime.now().isoformat(),
            "cards": {}
        }
        for uid, data in self.cards.items():
            export["cards"][data["card_id"]] = {
                "uid": uid,
                "signature": data["signature"],
                "role_id": data["role_id"]
            }

        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(export, f, ensure_ascii=False, indent=2)
        print(f"✅ 已匯出後端驗證資料: {filename}")

# ═══════════════════════════════════════════════════════════════
# 主程式
# ═══════════════════════════════════════════════════════════════

def write_single_card(writer: ACR122UWriter, db: CardDatabase,
                      role_type: str, card_index: int,
                      use_uid_binding: bool = True,
                      force_overwrite: bool = False) -> bool:
    """寫入單張卡片"""

    config = CARD_CONFIG.get(role_type)
    if not config:
        print(f"❌ 未知角色類型: {role_type}")
        return False

    # 取得秘密任務名稱
    missions = config.get('missions', [])
    mission_name = missions[card_index - 1] if card_index <= len(missions) else "未知任務"

    print(f"\n{'='*60}")
    print(f"📝 準備寫入【{config['name_zh']}】卡片 #{card_index}")
    print(f"   角色: {config['title']}")
    print(f"   秘密任務: 🔒 {mission_name}")
    print(f"   特殊角色: {'是 👑' if config['is_special'] else '否'}")
    print(f"{'='*60}")

    # 讀取卡片 UID
    print("\n🔍 請將 NFC 卡片放在 ACR122U 上...")
    uid = writer.read_uid()
    if not uid:
        return False

    print(f"   📇 卡片 UID: {uid}")

    # 檢查是否已寫入
    existing = db.get_by_uid(uid)
    if existing:
        print(f"\n⚠️  此卡片已寫入為【{existing['card_id']}】")
        if force_overwrite:
            print("   強制覆蓋模式，繼續寫入...")
        else:
            confirm = input("是否覆蓋？(y/N): ").strip().lower()
            if confirm != 'y':
                print("已取消")
                return False

    # 生成卡片資料
    card_id = generate_card_id(role_type, card_index)

    if use_uid_binding:
        # 進階模式：UID 綁定防偽
        signature = generate_signature(card_id, uid)
        nfc_url = generate_nfc_url(card_id, signature, uid)
        print(f"\n🔐 防偽模式: UID 綁定（防複製）")
    else:
        # 基礎模式：與現有後端相容
        signature = generate_signature(card_id)
        nfc_url = generate_nfc_url(card_id, signature)
        print(f"\n🔓 基礎模式: 標準簽名")

    print(f"   卡片 ID: {card_id}")
    print(f"   簽名: {signature}")
    print(f"\n📝 NFC URL:")
    print(f"   {nfc_url}")

    # 寫入卡片
    print(f"\n⏳ 正在寫入...")
    if writer.write_ndef_uri(nfc_url):
        # 儲存到資料庫
        db.add_card(uid, card_id, role_type, signature, nfc_url)

        print(f"\n🎉 寫入成功！")
        print(f"   角色: {config['name_zh']} ({config['name_en']})")
        print(f"   職稱: {config['title']}")
        return True
    else:
        print(f"\n❌ 寫入失敗")
        return False

def write_george_iii(use_uid_binding: bool = True):
    """寫入喬治三世卡片（快捷功能）"""
    writer = ACR122UWriter()
    if not writer.connect():
        return

    db = CardDatabase()
    write_single_card(writer, db, "george_iii", 1, use_uid_binding)

def interactive_menu():
    """互動式選單"""
    print("""
    ╔═══════════════════════════════════════════════════════════════╗
    ║     👑 1812 國會風雲 - 安全 NFC 卡片寫入工具                   ║
    ║                                                               ║
    ║     支援 UID 綁定防偽機制                                      ║
    ╚═══════════════════════════════════════════════════════════════╝
    """)

    if not SMARTCARD_AVAILABLE:
        print("❌ 請先安裝 pyscard:")
        print("   pip3 install pyscard")
        print("\nmacOS 可能還需要:")
        print("   brew install pcsc-lite")
        return

    writer = ACR122UWriter()
    if not writer.connect():
        return

    db = CardDatabase()
    use_uid_binding = True

    while True:
        print(f"\n{'='*60}")
        print("🎭 主選單")
        print(f"{'='*60}")
        print("1. 👑 寫入喬治三世（國王）")
        print("2. 📝 寫入指定角色卡片")
        print("3. 📋 批量寫入所有卡片")
        print("4. 🔍 讀取卡片資訊")
        print("5. 📊 查看已寫入卡片")
        print("6. 💾 匯出後端驗證資料")
        print(f"7. 🔐 切換防偽模式 [當前: {'UID綁定' if use_uid_binding else '基礎'}]")
        print("0. 離開")
        print("-" * 60)

        choice = input("請選擇: ").strip()

        if choice == '1':
            write_single_card(writer, db, "george_iii", 1, use_uid_binding)

        elif choice == '2':
            print("\n可用角色:")
            for i, (role_id, config) in enumerate(CARD_CONFIG.items(), 1):
                special = "👑" if config['is_special'] else "  "
                print(f"  {special} {role_id}: {config['name_zh']} ({config['title']})")

            role_type = input("\n輸入角色 ID: ").strip()
            if role_type in CARD_CONFIG:
                max_count = CARD_CONFIG[role_type]['count']
                card_index = int(input(f"卡片編號 (1-{max_count}): ").strip() or "1")
                write_single_card(writer, db, role_type, card_index, use_uid_binding)
            else:
                print("❌ 無效的角色 ID")

        elif choice == '3':
            print("\n🔄 批量寫入模式")
            print("將依序寫入所有角色卡片...")

            for role_type, config in CARD_CONFIG.items():
                for i in range(1, config['count'] + 1):
                    print(f"\n{'='*40}")
                    print(f"準備: {config['name_zh']} #{i}")
                    input("放上卡片後按 Enter...")
                    write_single_card(writer, db, role_type, i, use_uid_binding)

            print("\n✅ 批量寫入完成！")
            db.export_for_backend()

        elif choice == '4':
            print("\n🔍 請將卡片放在讀卡機上...")
            uid = writer.read_uid()
            if uid:
                print(f"   UID: {uid}")
                existing = db.get_by_uid(uid)
                if existing:
                    print(f"   已綁定角色: {existing['card_id']}")
                    print(f"   簽名: {existing['signature']}")
                    print(f"   寫入時間: {existing['written_at']}")
                else:
                    print("   （此卡片尚未寫入）")

        elif choice == '5':
            print(f"\n📊 已寫入卡片: {len(db.cards)} 張")
            for uid, data in db.cards.items():
                config = CARD_CONFIG.get(data['role_id'], {})
                name = config.get('name_zh', data['role_id'])
                print(f"   • {data['card_id']}: {name} (UID: {uid[:8]}...)")

        elif choice == '6':
            db.export_for_backend()

        elif choice == '7':
            use_uid_binding = not use_uid_binding
            mode = "UID 綁定（防複製）" if use_uid_binding else "基礎模式（與後端相容）"
            print(f"\n✅ 已切換到: {mode}")

        elif choice == '0':
            print("\n再見！👋")
            break

        else:
            print("❌ 無效選項")

# ═══════════════════════════════════════════════════════════════
# 入口點
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import sys
    import argparse

    parser = argparse.ArgumentParser(description="Parliament 1812 NFC Card Writer")
    parser.add_argument("--role", "-r", help="Role ID to write (e.g., worker, factory_owner)")
    parser.add_argument("--index", "-i", type=int, default=1, help="Card index (1-4)")
    parser.add_argument("--king", "-k", action="store_true", help="Quick write George III")
    parser.add_argument("--no-uid", action="store_true", help="Disable UID binding")
    parser.add_argument("--force", "-f", action="store_true", help="Force overwrite existing cards")

    args = parser.parse_args()

    if args.king:
        write_george_iii()
    elif args.role:
        if args.role not in CARD_CONFIG:
            print(f"❌ 無效角色 ID: {args.role}")
            print("可用角色:", ", ".join(CARD_CONFIG.keys()))
            sys.exit(1)

        max_count = CARD_CONFIG[args.role]['count']
        if args.index < 1 or args.index > max_count:
            print(f"❌ 卡片編號必須在 1-{max_count} 之間")
            sys.exit(1)

        # Initialize and write
        writer = ACR122UWriter()
        if not writer.connect():
            print("❌ 無法連接 NFC 讀卡機")
            sys.exit(1)

        db = CardDatabase()
        use_uid = not args.no_uid

        config = CARD_CONFIG[args.role]
        print(f"\n🎴 準備寫入: {config['name_zh']} ({config['title']}) #{args.index}")
        if args.index <= len(config.get('missions', [])):
            print(f"   秘密任務: {config['missions'][args.index-1]}")
        print("\n📱 請將 NTAG215 卡片放在讀卡機上...")
        print("   正在等待卡片...\n")

        write_single_card(writer, db, args.role, args.index, use_uid, args.force)
    else:
        interactive_menu()

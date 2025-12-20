#!/usr/bin/env python3
"""
1812 國會風雲 - NFC 卡片 URL 生成器
從後端 API 獲取正確的 NFC URL（包含正確的 HMAC 簽名）
"""

import json
import os
import sys
from datetime import datetime

import requests

# 預設後端 API URL
DEFAULT_API_URL = "https://1812-production.up.railway.app"


def get_admin_key():
    """從環境變數或互動輸入獲取 admin key"""
    admin_key = os.environ.get("ADMIN_KEY")
    if not admin_key:
        print("⚠️  需要 admin key 來取得 NFC 卡片資料")
        print("    請設定環境變數 ADMIN_KEY 或輸入：")
        admin_key = input("    Admin Key: ").strip()
    return admin_key


def fetch_nfc_cards_from_api(api_url: str, admin_key: str) -> list:
    """從後端 API 獲取所有 NFC 卡片 URL"""
    endpoint = f"{api_url}/api/admin/nfc-cards"

    try:
        response = requests.get(
            endpoint,
            params={"admin_key": admin_key},
            timeout=30,
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ API 請求失敗: {e}")
        sys.exit(1)


def export_to_json(results: list, filename: str = "nfc_cards.json"):
    """匯出為 JSON 檔案"""
    output = {
        "generated_at": datetime.now().isoformat(),
        "total_cards": len(results),
        "source": "backend_api",
        "cards": results,
    }

    with open(filename, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"✅ 已匯出 {len(results)} 張卡片資料到 {filename}")


def export_for_nfc_tools(results: list, filename: str = "nfc_urls_for_writing.txt"):
    """匯出為純文字檔案，方便複製貼上到 NFC 寫入 App"""
    with open(filename, "w", encoding="utf-8") as f:
        f.write("=" * 60 + "\n")
        f.write("1812 國會風雲 - NFC 卡片寫入清單\n")
        f.write("=" * 60 + "\n\n")
        f.write("使用方式：\n")
        f.write("1. 下載 NFC Tools App (iOS/Android)\n")
        f.write("2. 選擇「寫入」→「新增紀錄」→「URL/URI」\n")
        f.write("3. 複製下方對應的 URL 貼上\n")
        f.write("4. 將 NFC 卡放在手機背面進行寫入\n")
        f.write("\n" + "=" * 60 + "\n\n")

        current_role = None
        for card in results:
            role_type = card.get("role_type", card.get("card_id", "").split("0")[0])
            if role_type != current_role:
                current_role = role_type
                f.write(f"\n【{card.get('role_name', role_type)}】\n")
                f.write("-" * 50 + "\n")

            f.write(f"\n卡片 {card['card_id']}:\n")
            f.write(f"{card['nfc_url']}\n")

        f.write("\n" + "=" * 60 + "\n")
        f.write(f"總共 {len(results)} 張卡片\n")

    print(f"✅ 已匯出寫入清單到 {filename}")


def print_cards(results: list):
    """印出卡片資訊"""
    print("\n" + "=" * 60)
    print("🎭 1812 國會風雲 - NFC 卡片 URL")
    print("=" * 60)

    current_role = None
    for card in results:
        role_type = card.get("role_type", card.get("card_id", "").split("0")[0])
        if role_type != current_role:
            current_role = role_type
            print(f"\n【{card.get('role_name', role_type)}】")
            print("-" * 50)

        print(f"  {card['card_id']}: {card['nfc_url']}")


def main():
    print()
    print("=" * 60)
    print("🎴 NFC 卡片 URL 生成器")
    print("=" * 60)

    # 獲取 API URL
    api_url = os.environ.get("API_URL", DEFAULT_API_URL)
    print(f"\n📡 後端 API: {api_url}")

    # 獲取 admin key
    admin_key = get_admin_key()
    if not admin_key:
        print("❌ 未提供 admin key，無法繼續")
        sys.exit(1)

    # 從後端獲取卡片資料
    print("\n📥 正在從後端獲取 NFC 卡片資料...")
    cards = fetch_nfc_cards_from_api(api_url, admin_key)

    print(f"✅ 成功獲取 {len(cards)} 張卡片")

    # 印出卡片
    print_cards(cards)

    # 匯出檔案
    print("\n📁 匯出檔案...")
    export_to_json(cards)
    export_for_nfc_tools(cards)

    print("\n" + "=" * 60)
    print("📱 NFC 寫入步驟：")
    print("=" * 60)
    print(
        """
    【iOS 使用者】
    1. 下載「NFC Tools」App（App Store 免費）
    2. 開啟 App → 選擇「寫入」
    3. 點擊「新增紀錄」→「URL/URI」
    4. 貼上對應角色的 URL
    5. 點擊「寫入」，將 NFC 卡放在 iPhone 頂部
    6. 聽到提示音表示寫入成功！

    【Android 使用者】
    1. 下載「NFC Tools」App（Play Store 免費）
    2. 開啟 App → 選擇「寫入」分頁
    3. 點擊「新增紀錄」→「URL/URI」
    4. 貼上對應角色的 URL
    5. 點擊「寫入」，將 NFC 卡放在手機背面
    6. 震動提示表示寫入成功！

    【注意事項】
    - 每張 NFC 卡只能寫入一個 URL
    - 請確認卡片和角色對應正確再寫入
    - 建議在卡片背面標記角色編號
    - NTAG215 卡片容量足夠存放此 URL
    """
    )


if __name__ == "__main__":
    main()

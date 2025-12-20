#!/bin/bash
# Parliament 1812 - iOS 真機部署腳本
# 用法: ./deploy_device.sh [device_id]

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE="$SCRIPT_DIR/Runner.xcworkspace"
SCHEME="Runner"
BUNDLE_ID="com.parliament1812.parliament1812"

# 預設裝置 ID (Bocchi)
DEFAULT_DEVICE_ID="00008101-000231E13C68001E"
DEVICE_ID="${1:-$DEFAULT_DEVICE_ID}"

echo ""
echo "============================================================"
echo -e "${CYAN}🚀 Parliament 1812 - iOS 真機部署${NC}"
echo "============================================================"
echo ""

# 步驟 1: 清理擴展屬性
echo -e "${YELLOW}📁 清理擴展屬性...${NC}"
xattr -cr "$SCRIPT_DIR" 2>/dev/null || true
xattr -cr /opt/homebrew/share/flutter/bin/cache/artifacts/engine/ios 2>/dev/null || true
echo -e "${GREEN}✓${NC} 擴展屬性已清理"

# 步驟 2: 取得依賴
echo ""
echo -e "${YELLOW}📦 取得 Flutter 依賴...${NC}"
cd "$FRONTEND_DIR"
/opt/homebrew/bin/flutter pub get
echo -e "${GREEN}✓${NC} Flutter 依賴已取得"

# 步驟 3: Pod install
echo ""
echo -e "${YELLOW}🔧 安裝 CocoaPods 依賴...${NC}"
cd "$SCRIPT_DIR"
pod install --silent
echo -e "${GREEN}✓${NC} CocoaPods 依賴已安裝"

# 步驟 4: 列出可用裝置
echo ""
echo -e "${YELLOW}📱 可用裝置:${NC}"
xcrun devicectl list devices 2>/dev/null | grep -E "iPhone|iPad" | head -5 || echo "   (無法列出裝置)"

# 步驟 5: 建置
echo ""
echo -e "${YELLOW}🔨 建置 iOS App...${NC}"
xcodebuild -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -sdk iphoneos \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  build \
  -quiet

if [ $? -ne 0 ]; then
  echo -e "${RED}✗${NC} 建置失敗"
  exit 1
fi
echo -e "${GREEN}✓${NC} 建置成功"

# 步驟 6: 找到 App 路徑
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Runner.app" -path "*/Debug-iphoneos/*" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
  echo -e "${RED}✗${NC} 找不到建置的 App"
  exit 1
fi

echo -e "${GREEN}✓${NC} App 路徑: $APP_PATH"

# 步驟 7: 安裝到裝置
echo ""
echo -e "${YELLOW}📲 安裝到裝置...${NC}"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH" 2>/dev/null

if [ $? -ne 0 ]; then
  echo -e "${RED}✗${NC} 安裝失敗"
  exit 1
fi
echo -e "${GREEN}✓${NC} App 已安裝"

# 步驟 8: 啟動 App
echo ""
echo -e "${YELLOW}🎮 啟動 App...${NC}"
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓${NC} App 已啟動"
else
  echo -e "${YELLOW}⚠${NC} 無法自動啟動，請手動開啟 App"
fi

echo ""
echo "============================================================"
echo -e "${GREEN}🎉 部署完成！${NC}"
echo "============================================================"
echo ""
echo "Bundle ID: $BUNDLE_ID"
echo "裝置 ID: $DEVICE_ID"
echo ""

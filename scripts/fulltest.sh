#!/usr/bin/env bash
# 1812 國會風雲 - 完整流程測試
# 建立 4 人房，3 bot + 1 空位給時七
set -uo pipefail

BASE_URL="${1:-https://parliament1812-api.fly.dev}"
API="$BASE_URL/api/v1"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

p()    { echo -e "$*"; }
log()  { p "${GREEN}[✓]${NC} $*"; }
err()  { p "${RED}[✗]${NC} $*"; }
info() { p "${CYAN}[i]${NC} $*"; }

extract_token() { python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null; }

p ""; p "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
p "${BOLD}  1812 國會風雲 · 完整流程測試${NC}"
p "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; p ""

# Health check
info "伺服器: $BASE_URL"
curl -sf --max-time 15 "$BASE_URL/health" >/dev/null 2>&1 || {
    info "喚醒中..."; curl -s --max-time 30 "$BASE_URL/" >/dev/null 2>&1; sleep 5
    curl -sf --max-time 15 "$BASE_URL/health" >/dev/null 2>&1 || { err "伺服器無回應"; exit 1; }
}
log "伺服器正常"

TS=$(date +%s); PW="TestPass1234!@#"

do_reg() {
    curl -s --max-time 15 --ipv4 -X POST "$API/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$1\",\"email\":\"$1@test.com\",\"password\":\"$PW\"}"
}

# 建房者帳號（留在房間裡不離開，避免房間被解散）
p ""; info "=== 註冊帳號 ==="
R=$(do_reg "host_$TS"); HOST_TOKEN=$(echo "$R" | extract_token)
[ -z "$HOST_TOKEN" ] && { err "房主帳號註冊失敗: $R"; exit 1; }
log "🔨 房主Bot (host_$TS)"

# 建房 — 必須緊跟 register，保持同一 TCP 連線
info "=== 建立房間 ==="

create_room_with_retry() {
    local token="$1"
    for attempt in 1 2 3 4 5; do
        RESP=$(curl -s --max-time 10 --ipv4 -X POST "$API/rooms" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d '{"max_players":4}')
        CODE=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); c=d.get('code',''); print(c if isinstance(c,str) and len(c)==6 else '')" 2>/dev/null)
        if [ -n "$CODE" ]; then
            echo "$CODE"
            return 0
        fi
        info "  建房重試 $attempt/5..."
        sleep 1
    done
    echo ""
    return 1
}

ROOM_CODE=$(create_room_with_retry "$HOST_TOKEN")
[ -z "$ROOM_CODE" ] && { err "建房失敗（多次重試）"; exit 1; }
log "房間代碼: ${BOLD}$ROOM_CODE${NC}"

# 再註冊 2 個 bot + 時七帳號
R=$(do_reg "bot2_$TS"); BOT2_TOKEN=$(echo "$R" | extract_token)
[ -z "$BOT2_TOKEN" ] && { err "Bot2 註冊失敗"; exit 1; }
log "💰 理查Bot (bot2_$TS)"

R=$(do_reg "bot3_$TS"); BOT3_TOKEN=$(echo "$R" | extract_token)
[ -z "$BOT3_TOKEN" ] && { err "Bot3 註冊失敗"; exit 1; }
log "📰 愛德華Bot (bot3_$TS)"

SHIQI_USER="shiqi_$TS"
R=$(do_reg "$SHIQI_USER"); SHIQI_TOKEN=$(echo "$R" | extract_token)
[ -z "$SHIQI_TOKEN" ] && { err "時七帳號註冊失敗"; exit 1; }
log "⭐ 時七 ($SHIQI_USER)"

# Bot 加入
p ""; info "=== Bot 加入房間 ==="

join_room_with_retry() {
    local token="$1" name="$2" code="$3"
    for attempt in 1 2 3 4 5; do
        RESP=$(curl -s --max-time 10 --ipv4 -X POST "$API/rooms/$code/join" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d "{\"player_name\":\"$name\"}")
        CHECK=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('player_name','') or d.get('id',''))" 2>/dev/null)
        if [ -n "$CHECK" ]; then
            return 0
        fi
        # 可能 user 不在記憶體，重試
        info "  $name 加入重試 $attempt/5..."
        sleep 1
    done
    err "$name 加入失敗: $RESP"
    return 1
}

join_room_with_retry "$BOT2_TOKEN" "理查Bot" "$ROOM_CODE" || exit 1
log "💰 理查Bot 已加入"

join_room_with_retry "$BOT3_TOKEN" "愛德華Bot" "$ROOM_CODE" || exit 1
log "📰 愛德華Bot 已加入"

# 房間狀態
p ""; info "=== 房間狀態 ==="
ROOM_STATE=$(curl -s --max-time 10 --ipv4 "$API/rooms/$ROOM_CODE" -H "Authorization: Bearer $HOST_TOKEN")
echo "$ROOM_STATE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ps = d.get('players', [])
    mx = d.get('max_players', 4)
    print(f'  代碼: {d.get(\"code\")} | 狀態: {d.get(\"status\")} | {len(ps)}/{mx}')
    for p in ps:
        name = p.get('player_name', p.get('username', '?'))
        h = ' 👑' if p.get('is_host') else ''
        print(f'    🎭 {name}{h}')
    for _ in range(mx - len(ps)):
        print(f'    ⬜ (空位)')
except: pass
"

# 輸出
WS_URL=$(echo "$BASE_URL" | sed 's|https://|wss://|; s|http://|ws://|')

p ""
p "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
p "${BOLD}  ✅ 房間就緒！等你加入${NC}"
p "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
p ""
p "  ${CYAN}房間代碼:${NC}  ${BOLD}$ROOM_CODE${NC}"
p "  ${CYAN}空位:${NC}      1/4"
p ""
p "  ${YELLOW}你的帳號:${NC}"
p "    username: ${BOLD}$SHIQI_USER${NC}"
p "    password: ${BOLD}$PW${NC}"
p ""
p "  ${YELLOW}一鍵加入:${NC}"
p "    curl -s -X POST $API/rooms/$ROOM_CODE/join \\"
p "      -H 'Content-Type: application/json' \\"
p "      -H 'Authorization: Bearer $SHIQI_TOKEN' \\"
p "      -d '{\"player_name\":\"時七\"}' | python3 -m json.tool"
p ""
p "  ${YELLOW}API:${NC}  $API"
p "  ${YELLOW}WS:${NC}   $WS_URL/ws/$ROOM_CODE"
p ""
p "  ⚠️  Token 15 分鐘過期 | 伺服器重啟清空房間"
p ""

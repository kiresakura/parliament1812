# Parliament 1812 Cross-Platform Interoperability Test Report

**Test Date:** 2025-12-27
**Backend:** https://1812-production.up.railway.app
**Platforms:** Android (Medium_Phone_API_36.1) + iOS (iPhone 17 Pro Simulator)

---

## Executive Summary

All four test categories passed successfully:
- ✅ Room Creation & Joining
- ✅ Private Messaging System
- ✅ Voting System
- ✅ WebSocket Real-Time Sync

---

## Test Results

### 1. Room Creation & Joining

| Test | Result | Notes |
|------|--------|-------|
| Create room (Android host) | ✅ PASS | Room code: SVRBLW |
| Join room (iOS player) | ✅ PASS | Successfully joined |
| Player list sync | ✅ PASS | Both players visible |
| NFC card scan | ✅ PASS | Roles assigned: Worker W01, Factory F01 |
| Ready status toggle | ✅ PASS | Both marked ready |
| Start game (host) | ✅ PASS | Game started, phase advanced |

**Test Data:**
- Room Code: `SVRBLW`
- Android Host ID: `7e0766a7-20cc-4c3b-8489-cb04cf7f41af`
- iOS Player ID: `3b943346-8e30-4e98-abe4-00c7b5a12652`

---

### 2. Private Messaging System

| Test | Result | Notes |
|------|--------|-------|
| Send message (Android → iOS) | ✅ PASS | Message delivered |
| Send message (iOS → Android) | ✅ PASS | Message delivered |
| Get conversations list | ✅ PASS | Returns all conversations |
| Get messages with player | ✅ PASS | Full message history |
| Mark message as read | ✅ PASS | Updates read status |
| Unread count | ✅ PASS | Correctly tracks unread |

**API Endpoints Tested:**
```
POST /api/messages
GET  /api/messages?room_code={code}&player_id={id}
GET  /api/messages/{id}
PUT  /api/messages/{id}/read
```

---

### 3. Voting System

| Test | Result | Notes |
|------|--------|-------|
| Cast vote (Android: Option A) | ✅ PASS | Vote recorded |
| Cast vote (iOS: Option C) | ✅ PASS | Vote recorded |
| Get vote progress | ✅ PASS | Returns correct percentage |
| Get vote results | ✅ PASS | A: 50%, C: 50% |
| Prevent duplicate votes | ✅ PASS | Returns existing vote |

**API Endpoints Tested:**
```
POST /api/rooms/{code}/votes?player_id={id}&vote_round=1
GET  /api/rooms/{code}/votes/progress?vote_round=1
GET  /api/rooms/{code}/votes/result?vote_round=1
```

**Vote Results:**
```json
{
  "round": 1,
  "total_votes": 2,
  "percentages": {"A": 50.0, "B": 0.0, "C": 50.0, "D": 0.0},
  "is_complete": true
}
```

---

### 4. WebSocket Real-Time Sync

| Test | Result | Notes |
|------|--------|-------|
| Connect to room (Android) | ✅ PASS | Connection established |
| Connect to room (iOS) | ✅ PASS | Connection established |
| Receive player_join event | ✅ PASS | Both platforms receive |
| Cross-platform event sync | ✅ PASS | Events broadcast to all |

**WebSocket Endpoint:**
```
wss://1812-production.up.railway.app/ws/{room_code}?player_id={player_id}
```

**Event Types Tested:**
- `player_join` - Received when players connect
- `request_sync` - Client can request state sync

---

## Issues Found & Fixes

### Issue 1: Vote API Missing Required Parameter

**Problem:** Voting endpoints require `vote_round` query parameter but error message wasn't clear.

**Error:**
```json
{"detail":[{"type":"missing","loc":["query","vote_round"],"msg":"Field required"}]}
```

**Fix:** Always include `?vote_round=1` or `?vote_round=2` in voting API calls:
```
POST /api/rooms/{code}/votes?player_id={id}&vote_round=1
GET  /api/rooms/{code}/votes/progress?vote_round=1
GET  /api/rooms/{code}/votes/result?vote_round=1
```

---

### Issue 2: Vote Results Endpoint Naming

**Problem:** Endpoint is `/votes/result` (singular), not `/votes/results` (plural).

**Incorrect:** `GET /api/rooms/{code}/votes/results` → 404
**Correct:** `GET /api/rooms/{code}/votes/result` → 200

---

### Issue 3: Android Build Java Configuration

**Problem:** Android build fails with "Unable to locate a Java Runtime" on macOS.

**Error:**
```
The operation couldn't be completed. Unable to locate a Java Runtime.
```

**Fix:** Set JAVA_HOME to Android Studio's bundled JBR:
```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

---

### Issue 4: Android App Launch Command

**Problem:** The Android app has different `namespace` and `applicationId`, causing launch failures.

**Configuration (build.gradle.kts):**
```kotlin
namespace = "com.parliament1812"
applicationId = "com.parliament1812.parliament_1812"
```

**Incorrect Launch:**
```bash
adb shell am start -n com.parliament1812/.MainActivity
# Error: Activity class does not exist
```

**Correct Launch:**
```bash
adb shell am start -n com.parliament1812.parliament_1812/com.parliament1812.MainActivity
```

**Recommendation:** Consider aligning namespace and applicationId:
```kotlin
namespace = "com.parliament1812"
applicationId = "com.parliament1812"  // Simplified
```

---

## Platform-Specific Notes

### iOS
- **Bundle ID:** `com.parliament1812.ios`
- **Simulator:** iPhone 17 Pro (iOS 18.4)
- **App Path:** DerivedData/Parliament1812-*/Build/Products/Debug-iphonesimulator/Parliament1812.app
- **Build Warnings:** AppIcon sizes (1024x1024) - cosmetic only

### Android
- **Application ID:** `com.parliament1812.parliament_1812`
- **Namespace:** `com.parliament1812`
- **Emulator:** Medium_Phone_API_36.1 (API 36.1)
- **APK Path:** platforms/android/app/build/outputs/apk/debug/app-debug.apk

---

## Recommendations

1. **API Documentation:** Update API docs to clarify required parameters
2. **Error Messages:** Improve error messages for missing vote_round
3. **Android Config:** Simplify applicationId to match namespace
4. **iOS Icons:** Add proper 1024x1024 AppIcon for App Store

---

## Test Commands Reference

### Create Room
```bash
curl -X POST "https://1812-production.up.railway.app/api/rooms"
```

### Join Room
```bash
curl -X POST "https://1812-production.up.railway.app/api/rooms/{code}/join" \
  -H "Content-Type: application/json" \
  -d '{"nickname": "Player"}'
```

### Cast Vote
```bash
curl -X POST "https://1812-production.up.railway.app/api/rooms/{code}/votes?player_id={id}&vote_round=1" \
  -H "Content-Type: application/json" \
  -d '{"choice": "A"}'
```

### WebSocket Connection
```python
import websockets
ws = await websockets.connect(f"wss://1812-production.up.railway.app/ws/{room_code}?player_id={player_id}")
```

---

**Report Generated:** 2025-12-27 14:38 CST

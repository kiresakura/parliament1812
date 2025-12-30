# 1812 國會風雲 - iOS 原生開發指南 (Swift/SwiftUI)

## 專案概述

這是一款以 1812 年英國盧德運動為背景的國會辯論角色扮演遊戲 iOS 原生版本。
使用 **Swift + SwiftUI** 開發，原生 **Core NFC** 防作弊系統。

**目標**: Alpha Demo 於 2026/01/07，支援 6 人同時遊玩

---

## 建議專案架構

```
Parliament1812/
├── Parliament1812.xcodeproj
├── Parliament1812/
│   ├── App/
│   │   ├── Parliament1812App.swift      # @main 入口
│   │   └── AppDelegate.swift            # NFC 背景處理 (可選)
│   ├── Models/
│   │   ├── Player.swift
│   │   ├── Room.swift
│   │   ├── Role.swift
│   │   ├── NFCCardData.swift
│   │   └── GameState.swift
│   ├── Views/
│   │   ├── HomeView.swift               # 首頁 (建立/加入房間)
│   │   ├── WaitingRoomView.swift        # 等待室
│   │   ├── NFCScanView.swift            # NFC 掃描畫面
│   │   ├── GameView.swift               # 遊戲主畫面
│   │   ├── VotingView.swift             # 投票畫面
│   │   └── Components/                  # 共用組件
│   ├── ViewModels/
│   │   ├── RoomViewModel.swift          # 房間狀態 @Observable
│   │   ├── PlayerViewModel.swift        # 玩家狀態
│   │   └── GameViewModel.swift          # 遊戲流程
│   ├── Services/
│   │   ├── APIService.swift             # HTTP API 呼叫
│   │   ├── WebSocketService.swift       # WebSocket 連線
│   │   └── NFCService.swift             # Core NFC 封裝
│   ├── Utilities/
│   │   ├── Constants.swift              # API URL, 常數
│   │   └── Extensions.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Localizable.strings
│   │   └── Info.plist
│   └── Parliament1812.entitlements      # NFC 權限
└── Parliament1812Tests/
```

---

## 系統需求

| 項目 | 需求 |
|------|------|
| iOS 版本 | iOS 15.0+ (建議 16.0+ 用 @Observable) |
| Xcode | 15.0+ |
| Swift | 5.9+ |
| NFC 硬體 | iPhone 7 或更新 |

---

## Info.plist 必要配置

```xml
<!-- NFC 權限 -->
<key>NFCReaderUsageDescription</key>
<string>Parliament 1812 需要使用 NFC 功能來掃描角色卡片</string>

<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>D2760000850101</string>
</array>

<!-- URL Scheme (Deep Link) -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>parliament1812</string>
        </array>
    </dict>
</array>
```

---

## Entitlements 配置

在 `Parliament1812.entitlements` 添加:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
    <string>TAG</string>
</array>
```


---

## 後端 API

**生產環境**: `https://1812-production.up.railway.app`
**API 文檔**: `https://1812-production.up.railway.app/docs`

### API 端點

| 端點 | 方法 | 說明 |
|------|------|------|
| `/api/rooms` | POST | 建立房間 |
| `/api/rooms/{code}` | GET | 取得房間資訊 |
| `/api/rooms/{code}/join` | POST | 加入房間 |
| `/api/rooms/{code}/players` | GET | 取得房間玩家 |
| `/api/nfc/scan` | POST | NFC 掃卡驗證 |
| `/api/roles` | GET | 取得所有角色 |
| `/api/roles/{role_type}` | GET | 取得特定角色 |

### WebSocket

```
wss://1812-production.up.railway.app/ws/{room_code}/{player_id}
```

事件: `player_joined`, `player_left`, `role_assigned`, `game_started`, `vote_started`, `vote_ended`

---

## Core NFC 實作

### NFCService.swift 範例

```swift
import CoreNFC

class NFCService: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var scannedCardData: NFCCardData?
    @Published var error: Error?
    
    private var session: NFCNDEFReaderSession?
    
    func startScan() {
        guard NFCNDEFReaderSession.readingAvailable else {
            error = NFCError.notAvailable
            return
        }
        
        session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        session?.alertMessage = "請將 NFC 角色卡片靠近手機頂部"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                if let uri = parseNDEFRecord(record) {
                    DispatchQueue.main.async {
                        self.scannedCardData = self.parseURI(uri)
                    }
                    session.invalidate()
                    return
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    private func parseNDEFRecord(_ record: NFCNDEFPayload) -> String? {
        // 解析 NDEF URI record
        guard record.typeNameFormat == .nfcWellKnown,
              let type = String(data: record.type, encoding: .utf8),
              type == "U" else { return nil }
        
        let payload = record.payload
        guard payload.count > 1 else { return nil }
        
        // 第一個 byte 是 URI prefix code
        let prefixCode = payload[0]
        let uriData = payload.dropFirst()
        
        guard let uriSuffix = String(data: Data(uriData), encoding: .utf8) else { return nil }
        
        // prefix code 0x00 = 無 prefix (自定義 scheme)
        if prefixCode == 0x00 {
            return uriSuffix
        }
        
        return uriSuffix
    }
    
    private func parseURI(_ uri: String) -> NFCCardData? {
        // 解析: parliament1812://role?id=GEORGEIII01&secret=7f3a9c2b1e5d8f04
        guard let url = URL(string: uri),
              url.scheme == "parliament1812",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        
        let cardId = queryItems.first { $0.name == "id" }?.value
        let secret = queryItems.first { $0.name == "secret" }?.value
        
        guard let cardId, let secret else { return nil }
        
        return NFCCardData(cardId: cardId, signature: secret)
    }
}

enum NFCError: LocalizedError {
    case notAvailable
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .notAvailable: return "此設備不支援 NFC"
        case .invalidFormat: return "無效的卡片格式"
        }
    }
}
```

### NFCCardData Model

```swift
struct NFCCardData: Codable {
    let cardId: String      // e.g., "GEORGEIII01"
    let signature: String   // e.g., "7f3a9c2b1e5d8f04"
}
```


---

## NFC 防作弊系統規範

### 正確的 NFC 格式

| 項目 | 規範 | 範例 |
|------|------|------|
| card_id | 大寫，無底線 | `WORKER01`, `GEORGEIII01` |
| secret_hash | HMAC-SHA256，16 字元 | `a1b2c3d4e5f67890` |
| nfc_url | Deep link 格式 | `parliament1812://role?id=WORKER01&secret=a1b2c3d4e5f67890` |

### 所有有效卡片 ID

| 角色 | 卡片 ID | role_type |
|------|---------|-----------|
| 工人 | WORKER01 ~ WORKER04 | `worker` |
| 工廠主 | FACTORY01 ~ FACTORY04 | `factory_owner` |
| 盧德派 | LUDDITE01 ~ LUDDITE04 | `luddite` |
| 改革者 | REFORMER01 ~ REFORMER04 | `reformer` |
| 議員 | MP01 ~ MP04 | `mp` |
| 👑 喬治三世 | GEORGEIII01 ~ GEORGEIII04 | `george_iii` |

### NFC 掃描 API 呼叫

```swift
struct NFCScanRequest: Codable {
    let roomCode: String
    let playerId: String
    let cardId: String
    let signature: String
    
    enum CodingKeys: String, CodingKey {
        case roomCode = "room_code"
        case playerId = "player_id"
        case cardId = "card_id"
        case signature
    }
}

struct NFCScanResponse: Codable {
    let success: Bool
    let roleType: String?
    let roleIndex: Int?
    let role: Role?
    
    enum CodingKeys: String, CodingKey {
        case success
        case roleType = "role_type"
        case roleIndex = "role_index"
        case role
    }
}

// APIService 中
func scanNFC(_ request: NFCScanRequest) async throws -> NFCScanResponse {
    let url = URL(string: "\(baseURL)/api/nfc/scan")!
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = try JSONEncoder().encode(request)
    
    let (data, _) = try await URLSession.shared.data(for: urlRequest)
    return try JSONDecoder().decode(NFCScanResponse.self, from: data)
}
```

---

## API Service 範例

```swift
actor APIService {
    static let shared = APIService()
    
    private let baseURL = "https://1812-production.up.railway.app"
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    // 建立房間
    func createRoom(hostNickname: String) async throws -> CreateRoomResponse {
        let url = URL(string: "\(baseURL)/api/rooms")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["host_nickname": hostNickname])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(CreateRoomResponse.self, from: data)
    }
    
    // 加入房間
    func joinRoom(code: String, nickname: String) async throws -> Player {
        let url = URL(string: "\(baseURL)/api/rooms/\(code)/join")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["nickname": nickname])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(Player.self, from: data)
    }
    
    // 取得房間資訊
    func getRoom(code: String) async throws -> Room {
        let url = URL(string: "\(baseURL)/api/rooms/\(code)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(Room.self, from: data)
    }
}
```


---

## WebSocket Service 範例

```swift
import Foundation

@Observable
class WebSocketService {
    private var webSocket: URLSessionWebSocketTask?
    private var isConnected = false
    
    var onPlayerJoined: ((Player) -> Void)?
    var onPlayerLeft: ((String) -> Void)?
    var onRoleAssigned: ((String, String, Int) -> Void)?
    var onGameStarted: (() -> Void)?
    
    func connect(roomCode: String, playerId: String) {
        let urlString = "wss://1812-production.up.railway.app/ws/\(roomCode)/\(playerId)"
        guard let url = URL(string: urlString) else { return }
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        isConnected = true
        
        receiveMessage()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // 繼續監聽
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.isConnected = false
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        DispatchQueue.main.async { [weak self] in
            switch type {
            case "player_joined":
                // 處理玩家加入
                break
            case "player_left":
                if let playerId = json["player_id"] as? String {
                    self?.onPlayerLeft?(playerId)
                }
            case "role_assigned":
                if let playerId = json["player_id"] as? String,
                   let roleType = json["role_type"] as? String,
                   let roleIndex = json["role_index"] as? Int {
                    self?.onRoleAssigned?(playerId, roleType, roleIndex)
                }
            case "game_started":
                self?.onGameStarted?()
            default:
                break
            }
        }
    }
}
```

---

## Models

### Player.swift

```swift
struct Player: Codable, Identifiable {
    let id: String
    let nickname: String
    let isHost: Bool
    var roleType: String?
    var roleIndex: Int?
    
    var hasRole: Bool {
        roleType != nil && roleIndex != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case isHost = "is_host"
        case roleType = "role_type"
        case roleIndex = "role_index"
    }
}
```

### Room.swift

```swift
struct Room: Codable {
    let code: String
    let hostId: String
    var players: [Player]
    let status: RoomStatus
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case hostId = "host_id"
        case players
        case status
        case createdAt = "created_at"
    }
}

enum RoomStatus: String, Codable {
    case waiting
    case playing
    case finished
}
```

### Role.swift

```swift
struct Role: Codable, Identifiable {
    let id: String
    let nameZh: String
    let nameEn: String
    let faction: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nameZh = "name_zh"
        case nameEn = "name_en"
        case faction
        case description
    }
}
```


---

## View 範例

### HomeView.swift

```swift
import SwiftUI

struct HomeView: View {
    @State private var nickname = ""
    @State private var roomCode = ""
    @State private var showCreateRoom = false
    @State private var showJoinRoom = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("1812 國會風雲")
                    .font(.largeTitle)
                    .bold()
                
                TextField("你的暱稱", text: $nickname)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button("建立房間") {
                    showCreateRoom = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(nickname.isEmpty)
                
                Divider()
                
                TextField("房間代碼", text: $roomCode)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button("加入房間") {
                    showJoinRoom = true
                }
                .buttonStyle(.bordered)
                .disabled(nickname.isEmpty || roomCode.isEmpty)
            }
            .padding()
            .navigationDestination(isPresented: $showCreateRoom) {
                WaitingRoomView(isHost: true, nickname: nickname)
            }
            .navigationDestination(isPresented: $showJoinRoom) {
                WaitingRoomView(isHost: false, nickname: nickname, roomCode: roomCode)
            }
        }
    }
}
```

### NFCScanView.swift

```swift
import SwiftUI

struct NFCScanView: View {
    @StateObject private var nfcService = NFCService()
    @State private var isScanning = false
    
    let roomCode: String
    let playerId: String
    var onRoleAssigned: ((String, Int) -> Void)?
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue)
            
            Text("準備掃描 NFC 角色卡")
                .font(.title2)
            
            Button {
                nfcService.startScan()
                isScanning = true
            } label: {
                Label("開始掃描", systemImage: "sensor.tag.radiowaves.forward.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isScanning)
            
            if let error = nfcService.error {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .onChange(of: nfcService.scannedCardData) { _, cardData in
            guard let cardData else { return }
            Task {
                await submitNFCScan(cardData)
            }
        }
    }
    
    private func submitNFCScan(_ cardData: NFCCardData) async {
        let request = NFCScanRequest(
            roomCode: roomCode,
            playerId: playerId,
            cardId: cardData.cardId,
            signature: cardData.signature
        )
        
        do {
            let response = try await APIService.shared.scanNFC(request)
            if response.success, let roleType = response.roleType, let roleIndex = response.roleIndex {
                onRoleAssigned?(roleType, roleIndex)
            }
        } catch {
            print("NFC scan error: \(error)")
        }
        
        isScanning = false
    }
}
```

---

## 已知問題 (待修復)

### 問題 1: NFC 卡片格式錯誤

**現象**: 目前實體 NFC 卡片寫入的是 JSON 格式，而非正確的 URI 格式

**錯誤格式** (目前卡片內容):
```json
{"id": "king_george_iii", "name": "喬治三世", ...}
```

**正確格式**:
```
parliament1812://role?id=GEORGEIII01&secret=7f3a9c2b1e5d8f04
```

**解決方案**: 使用 `shared/nfc_tools/` 的工具重新寫入卡片

### 問題 2: 模擬器無法測試 NFC

**解決方案**: 
1. 使用實體 iPhone 測試
2. 或實作手動分配角色的備用方案

---

## 角色系統

| 角色 | role_type | 陣營 | 描述 |
|------|-----------|------|------|
| 👑 喬治三世 | `george_iii` | 皇室 | 精神狀態不穩定的國王 |
| 🔨 工人 | `worker` | 勞工 | 紡織工人湯瑪斯 |
| 🏭 工廠主 | `factory_owner` | 資方 | 理查·威爾森 |
| ⚔️ 盧德派 | `luddite` | 激進派 | 機器破壞者喬治 |
| 📜 改革者 | `reformer` | 改革派 | 羅伯特·歐文 |
| 🎩 議員 | `mp` | 國會 | 威廉·菲茨傑拉德 |


---

## 開發指南

### 建立新專案

1. 開啟 Xcode → File → New → Project
2. 選擇 iOS → App
3. Product Name: `Parliament1812`
4. Interface: SwiftUI
5. Language: Swift
6. 勾選 "Include Tests"

### 添加 NFC Capability

1. 選擇專案 → Signing & Capabilities
2. 點擊 "+ Capability"
3. 搜尋並添加 "Near Field Communication Tag Reading"

### 執行專案

```bash
# 列出可用設備
xcrun xctrace list devices

# 在模擬器執行 (NFC 無法使用)
open -a Simulator
xcodebuild -scheme Parliament1812 -destination 'platform=iOS Simulator,name=iPhone 15'

# 在實體設備執行 (推薦)
xcodebuild -scheme Parliament1812 -destination 'platform=iOS,name=Your iPhone'
```

### 打包 Archive

```bash
xcodebuild -scheme Parliament1812 -configuration Release archive -archivePath build/Parliament1812.xcarchive
```

---

## 共用資源

位於: `/Users/zhongliyuanshiqi/Documents/parliament1812/shared/`

| 目錄 | 說明 |
|------|------|
| `backend/` | FastAPI 後端源碼 |
| `nfc_tools/` | NFC 工具和卡片資料庫 |
| `docs/` | 專案文檔 |
| `flutter_original/` | Flutter 版本備份 (可參考邏輯) |

---

## 測試

### 單元測試範例

```swift
import XCTest
@testable import Parliament1812

final class NFCServiceTests: XCTestCase {
    func testParseValidURI() {
        let nfcService = NFCService()
        let uri = "parliament1812://role?id=GEORGEIII01&secret=7f3a9c2b1e5d8f04"
        
        // 使用反射或暴露測試方法
        let cardData = nfcService.testParseURI(uri)
        
        XCTAssertNotNil(cardData)
        XCTAssertEqual(cardData?.cardId, "GEORGEIII01")
        XCTAssertEqual(cardData?.signature, "7f3a9c2b1e5d8f04")
    }
    
    func testParseInvalidURI() {
        let nfcService = NFCService()
        let uri = "invalid://wrong"
        
        let cardData = nfcService.testParseURI(uri)
        XCTAssertNil(cardData)
    }
}
```

---

## 常見問題

| 問題 | 原因 | 解決 |
|------|------|------|
| NFC 掃描無反應 | 模擬器不支援 | 使用實體 iPhone 7+ |
| "No signing certificate" | 無開發者帳號 | 設定 Apple ID Team |
| API 連線失敗 | ATS 設定 | Info.plist 允許 HTTP (開發用) |
| Deep Link 無效 | URL Scheme 未註冊 | 檢查 Info.plist CFBundleURLSchemes |

---

## 參考資源

- [Core NFC 官方文檔](https://developer.apple.com/documentation/corenfc)
- [SwiftUI 教學](https://developer.apple.com/tutorials/swiftui)
- [URLSession WebSocket](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask)

---

*最後更新: 2024-12-20*
*框架: Swift 5.9 + SwiftUI + Core NFC*

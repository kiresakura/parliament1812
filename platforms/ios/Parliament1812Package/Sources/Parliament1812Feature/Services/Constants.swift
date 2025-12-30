import Foundation

enum AppConfig {
    static let appName = "1812 國會風雲"
    static let appVersion = "1.0.0"

    // API 配置 - 生產環境 (Railway)
    static let prodApiBaseUrl = "https://1812-production.up.railway.app"
    static let prodWsBaseUrl = "wss://1812-production.up.railway.app"

    // API 配置 - 開發環境 (本地)
    static let devApiBaseUrl = "http://localhost:8000"
    static let devWsBaseUrl = "ws://localhost:8000"

    // 環境切換
    // true = localhost (模擬器用)
    // false = Railway production (真機用)
    static let isDevelopment = false

    // 取得當前 API URL
    static var currentApiUrl: String {
        isDevelopment ? devApiBaseUrl : prodApiBaseUrl
    }

    static var currentWsUrl: String {
        isDevelopment ? devWsBaseUrl : prodWsBaseUrl
    }

    // WebSocket 配置
    static let wsReconnectDelay: TimeInterval = 3.0
    static let wsHeartbeatInterval: TimeInterval = 30.0

    // 遊戲配置
    static let maxPlayersPerRoom = 20
    static let minPlayersToStart = 5
    static let roomCodeLength = 6

    // NFC 配置
    static let nfcUrlScheme = "parliament1812"
}

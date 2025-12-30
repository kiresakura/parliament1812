import CoreNFC
import Foundation

@MainActor
@Observable
final class NFCService: NSObject, NFCNDEFReaderSessionDelegate {
    var scannedCardData: NFCCardData?
    var error: Error?
    var isScanning = false

    private var session: NFCNDEFReaderSession?

    override init() {
        super.init()
    }

    /// 檢查設備是否支援 NFC
    var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    /// 開始 NFC 掃描
    func startScan() {
        guard NFCNDEFReaderSession.readingAvailable else {
            error = NFCError.notAvailable
            return
        }

        // 清除之前的狀態
        scannedCardData = nil
        error = nil
        isScanning = true

        session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        session?.alertMessage = "請將 NFC 角色卡片靠近手機頂部"
        session?.begin()
    }

    /// 停止 NFC 掃描
    func stopScan() {
        session?.invalidate()
        isScanning = false
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("NFC: didDetectNDEFs - found \(messages.count) message(s)")

        for (msgIndex, message) in messages.enumerated() {
            print("NFC: Message \(msgIndex) has \(message.records.count) record(s)")

            for (recIndex, record) in message.records.enumerated() {
                print("NFC: Record \(recIndex) - typeNameFormat: \(record.typeNameFormat.rawValue), type: \(String(data: record.type, encoding: .utf8) ?? "nil")")

                if let uri = parseNDEFRecord(record) {
                    print("NFC: Parsed URI: \(uri)")

                    if let cardData = parseURI(uri) {
                        print("NFC: Card data parsed - cardId: \(cardData.cardId), sig: \(cardData.signature), uid: \(cardData.uid)")
                        Task { @MainActor in
                            self.scannedCardData = cardData
                            self.isScanning = false
                        }
                        session.alertMessage = "掃描成功！"
                        session.invalidate()
                        return
                    } else {
                        print("NFC: Failed to parse URI as card data")
                    }
                } else {
                    print("NFC: Failed to parse record as URI")
                }
            }
        }

        Task { @MainActor in
            self.error = NFCError.invalidFormat
            self.isScanning = false
        }
        session.alertMessage = "無效的卡片格式"
        session.invalidate()
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            // 檢查是否為「正常結束」的情況（非真正錯誤）
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    // 用戶取消，不算錯誤
                    self.isScanning = false
                    return
                case .readerSessionInvalidationErrorFirstNDEFTagRead:
                    // 成功讀取第一張卡片後 session 自動關閉，這是正常行為
                    self.isScanning = false
                    return
                default:
                    break
                }
            }

            self.error = error
            self.isScanning = false
        }
    }

    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC: Session became active")
    }

    // MARK: - Private Helpers

    nonisolated private func parseNDEFRecord(_ record: NFCNDEFPayload) -> String? {
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

    nonisolated private func parseURI(_ uri: String) -> NFCCardData? {
        // 格式: parliament1812://role?id=george_iii_01&sig=44812E2027E636B2&uid=04F178BA2E0289
        guard let url = URL(string: uri),
              url.scheme == AppConfig.nfcUrlScheme,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }

        let cardId = queryItems.first { $0.name == "id" }?.value
        let signature = queryItems.first { $0.name == "sig" }?.value
        let uid = queryItems.first { $0.name == "uid" }?.value

        guard let cardId, let signature, let uid else { return nil }

        return NFCCardData(cardId: cardId, signature: signature, uid: uid)
    }

    #if DEBUG
    /// 測試用：模擬 NFC 掃描結果
    func simulateScan(cardId: String, signature: String, uid: String) {
        scannedCardData = NFCCardData(cardId: cardId, signature: signature, uid: uid)
        isScanning = false
    }

    /// 測試用：解析 URI
    nonisolated func testParseURI(_ uri: String) -> NFCCardData? {
        parseURI(uri)
    }
    #endif
}

enum NFCError: LocalizedError {
    case notAvailable
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "此設備不支援 NFC"
        case .invalidFormat:
            return "無效的卡片格式"
        }
    }
}

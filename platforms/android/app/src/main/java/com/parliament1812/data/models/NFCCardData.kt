package com.parliament1812.data.models

/**
 * NFC 卡片數據
 * @property cardId 卡片 ID，如 "WORKER01", "GEORGEIII01"
 * @property signature HMAC-SHA256 簽名，16 字元
 */
data class NFCCardData(
    val cardId: String,
    val signature: String
) {
    /**
     * 從 cardId 解析角色類型
     * WORKER01 -> worker
     * GEORGEIII01 -> george_iii
     */
    val roleType: String
        get() = when {
            cardId.startsWith("WORKER") -> "worker"
            cardId.startsWith("FACTORY") -> "factory_owner"
            cardId.startsWith("LUDDITE") -> "luddite"
            cardId.startsWith("REFORMER") -> "reformer"
            cardId.startsWith("MP") -> "mp"
            cardId.startsWith("GEORGEIII") -> "george_iii"
            else -> "unknown"
        }

    /**
     * 從 cardId 解析角色索引
     * WORKER01 -> 1
     */
    val roleIndex: Int
        get() {
            val numStr = cardId.filter { it.isDigit() }
            return numStr.toIntOrNull() ?: 0
        }
}

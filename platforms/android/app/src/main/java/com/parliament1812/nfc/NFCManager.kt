package com.parliament1812.nfc

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Build
import android.util.Log
import com.parliament1812.data.models.NFCCardData
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton

sealed class NFCState {
    object Idle : NFCState()
    object Scanning : NFCState()
    data class Success(val data: NFCCardData) : NFCState()
    data class Error(val message: String) : NFCState()
}

@Singleton
class NFCManager @Inject constructor() {

    private val _state = MutableStateFlow<NFCState>(NFCState.Idle)
    val state: StateFlow<NFCState> = _state

    private var nfcAdapter: NfcAdapter? = null

    companion object {
        private const val TAG = "NFCManager"
        private const val SCHEME = "parliament1812"
    }

    fun isNFCAvailable(activity: Activity): Boolean {
        nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
        return nfcAdapter != null
    }

    fun isNFCEnabled(): Boolean = nfcAdapter?.isEnabled == true

    fun enableForegroundDispatch(activity: Activity) {
        val intent = Intent(activity, activity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            0
        }

        val pendingIntent = PendingIntent.getActivity(activity, 0, intent, flags)

        try {
            nfcAdapter?.enableForegroundDispatch(activity, pendingIntent, null, null)
            // Only set Scanning if we're not already in Success state (to prevent race condition)
            val currentState = _state.value
            if (currentState !is NFCState.Success) {
                _state.value = NFCState.Scanning
            }
            Log.d(TAG, "NFC Foreground Dispatch enabled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enable foreground dispatch", e)
            _state.value = NFCState.Error("無法啟用 NFC 掃描")
        }
    }

    fun disableForegroundDispatch(activity: Activity) {
        try {
            nfcAdapter?.disableForegroundDispatch(activity)
            Log.d(TAG, "NFC Foreground Dispatch disabled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable foreground dispatch", e)
        }
    }

    fun handleIntent(intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Handling NFC intent: $action")

        if (NfcAdapter.ACTION_NDEF_DISCOVERED == action ||
            NfcAdapter.ACTION_TAG_DISCOVERED == action ||
            NfcAdapter.ACTION_TECH_DISCOVERED == action
        ) {
            val tag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
            }

            tag?.let {
                Log.d(TAG, "Tag detected: ${it.id.toHexString()}")
                processTag(it)
            }
        }
    }

    private fun processTag(tag: Tag) {
        try {
            // Get the tag UID (hardware-based, anti-copy protection)
            val tagUid = tag.id.toHexString()
            Log.d(TAG, "Tag UID: $tagUid")

            val ndef = Ndef.get(tag)
            if (ndef == null) {
                _state.value = NFCState.Error("不支援的卡片類型")
                return
            }

            ndef.connect()
            val ndefMessage = ndef.ndefMessage
            ndef.close()

            if (ndefMessage != null) {
                val uri = parseNdefMessage(ndefMessage)
                Log.d(TAG, "Parsed URI: $uri")

                if (uri != null) {
                    val cardData = parseUri(uri, tagUid)
                    if (cardData != null) {
                        Log.d(TAG, "Card data: cardId=${cardData.cardId}, sig=${cardData.signature}, uid=${cardData.uid}")
                        _state.value = NFCState.Success(cardData)
                    } else {
                        _state.value = NFCState.Error("無效的卡片格式")
                    }
                } else {
                    _state.value = NFCState.Error("無法讀取卡片資料")
                }
            } else {
                _state.value = NFCState.Error("卡片沒有資料")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing tag", e)
            _state.value = NFCState.Error("讀取錯誤: ${e.message}")
        }
    }

    private fun parseNdefMessage(message: NdefMessage): String? {
        Log.d(TAG, "Parsing NDEF message with ${message.records.size} records")

        for ((index, record) in message.records.withIndex()) {
            Log.d(TAG, "Record $index: TNF=${record.tnf}, type=${String(record.type)}")

            // Check for URI record (TNF_WELL_KNOWN with RTD_URI)
            if (record.tnf == android.nfc.NdefRecord.TNF_WELL_KNOWN) {
                val typeStr = String(record.type)
                val payload = record.payload

                if (typeStr == "U" && payload.isNotEmpty()) {
                    // URI record: first byte is URI prefix code
                    val prefixCode = payload[0].toInt() and 0xFF
                    val uriBytes = payload.copyOfRange(1, payload.size)
                    val uriSuffix = String(uriBytes, Charsets.UTF_8)

                    // Build full URI based on prefix code
                    val fullUri = when (prefixCode) {
                        0x00 -> uriSuffix  // No prefix, full URI in suffix
                        0x01 -> "http://www.$uriSuffix"
                        0x02 -> "https://www.$uriSuffix"
                        0x03 -> "http://$uriSuffix"
                        0x04 -> "https://$uriSuffix"
                        else -> uriSuffix  // For custom schemes, use as-is
                    }

                    Log.d(TAG, "URI Record: prefixCode=$prefixCode, suffix=$uriSuffix, fullUri=$fullUri")

                    // Check if it's our custom scheme (supports both sig= and secret= formats)
                    if (fullUri.startsWith(SCHEME) ||
                        (fullUri.contains("id=") && (fullUri.contains("secret=") || fullUri.contains("sig=")))) {
                        return fullUri
                    }
                } else if (typeStr == "T" && payload.isNotEmpty()) {
                    // Text record
                    val languageCodeLength = payload[0].toInt() and 0x3F
                    val text = String(payload, languageCodeLength + 1, payload.size - languageCodeLength - 1, Charsets.UTF_8)
                    Log.d(TAG, "Text Record: $text")
                    if (text.startsWith(SCHEME) ||
                        (text.contains("id=") && (text.contains("secret=") || text.contains("sig=")))) {
                        return text
                    }
                }
            }

            // Also try external type for custom scheme
            if (record.tnf == android.nfc.NdefRecord.TNF_EXTERNAL_TYPE) {
                val payload = String(record.payload, Charsets.UTF_8)
                Log.d(TAG, "External record payload: $payload")
                if (payload.startsWith(SCHEME) ||
                    (payload.contains("id=") && (payload.contains("secret=") || payload.contains("sig=")))) {
                    return payload
                }
            }

            // Try absolute URI
            if (record.tnf == android.nfc.NdefRecord.TNF_ABSOLUTE_URI) {
                val uri = String(record.type, Charsets.UTF_8)
                Log.d(TAG, "Absolute URI: $uri")
                if (uri.startsWith(SCHEME) ||
                    (uri.contains("id=") && (uri.contains("secret=") || uri.contains("sig=")))) {
                    return uri
                }
            }
        }
        return null
    }

    private fun parseUri(uri: String, tagUid: String): NFCCardData? {
        // Parse multiple formats:
        // Format 1 (advanced): parliament1812://role?id=WORKER01&sig=abc123&uid=04aabbccdd
        // Format 2 (basic): parliament1812://role?id=WORKER01&secret=abc123
        // Or variations with different delimiters
        return try {
            Log.d(TAG, "Parsing URI: $uri")

            // Extract id parameter
            val idRegex = """[?&]?id=([^&\s]+)""".toRegex(RegexOption.IGNORE_CASE)
            val idMatch = idRegex.find(uri)
            var cardId = idMatch?.groupValues?.get(1)

            // Extract signature - try both "sig=" and "secret=" parameter names
            val sigRegex = """[?&]?sig=([^&\s]+)""".toRegex(RegexOption.IGNORE_CASE)
            val secretRegex = """[?&]?secret=([^&\s]+)""".toRegex(RegexOption.IGNORE_CASE)
            val sigMatch = sigRegex.find(uri)
            val secretMatch = secretRegex.find(uri)
            var signature = sigMatch?.groupValues?.get(1) ?: secretMatch?.groupValues?.get(1)

            // Extract uid from URL (if present), otherwise use tag's hardware UID
            val uidRegex = """[?&]?uid=([^&\s]+)""".toRegex(RegexOption.IGNORE_CASE)
            val uidMatch = uidRegex.find(uri)
            var uid = uidMatch?.groupValues?.get(1) ?: tagUid

            // Also try standard URI parsing as fallback
            if (cardId == null || signature == null) {
                val normalizedUri = if (uri.contains("://")) uri else "$SCHEME://$uri"
                val androidUri = android.net.Uri.parse(normalizedUri)
                cardId = cardId ?: androidUri.getQueryParameter("id")
                signature = signature ?: androidUri.getQueryParameter("sig")
                    ?: androidUri.getQueryParameter("secret")
                uid = uid.ifEmpty { androidUri.getQueryParameter("uid") ?: tagUid }
            }

            if (cardId != null && signature != null) {
                Log.d(TAG, "Parsed card data: id=$cardId, signature=$signature, uid=$uid")
                NFCCardData(cardId = cardId.uppercase(), signature = signature, uid = uid)
            } else {
                Log.w(TAG, "Missing id or signature in URI: $uri (id=$cardId, sig=$signature)")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse URI: $uri", e)
            null
        }
    }

    fun resetState() {
        _state.value = NFCState.Idle
    }

    fun startScanning() {
        _state.value = NFCState.Scanning
    }

    private fun ByteArray.toHexString(): String =
        joinToString("") { "%02x".format(it) }
}

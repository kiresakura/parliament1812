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
            _state.value = NFCState.Scanning
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
                    val cardData = parseUri(uri)
                    if (cardData != null) {
                        Log.d(TAG, "Card data: cardId=${cardData.cardId}, sig=${cardData.signature}")
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
        for (record in message.records) {
            // Check for URI record
            if (record.tnf == android.nfc.NdefRecord.TNF_WELL_KNOWN) {
                val payload = record.payload
                if (payload.isNotEmpty()) {
                    // First byte is URI prefix code
                    val prefixCode = payload[0].toInt()
                    val uriBytes = payload.copyOfRange(1, payload.size)
                    val uriSuffix = String(uriBytes, Charsets.UTF_8)

                    // prefixCode 0 = no prefix (custom scheme)
                    Log.d(TAG, "NDEF Record: prefixCode=$prefixCode, suffix=$uriSuffix")
                    return uriSuffix
                }
            }

            // Also try external type for custom scheme
            if (record.tnf == android.nfc.NdefRecord.TNF_EXTERNAL_TYPE) {
                val payload = String(record.payload, Charsets.UTF_8)
                Log.d(TAG, "External record payload: $payload")
                if (payload.startsWith(SCHEME)) {
                    return payload
                }
            }
        }
        return null
    }

    private fun parseUri(uri: String): NFCCardData? {
        // Parse: parliament1812://role?id=GEORGEIII01&secret=7f3a9c2b1e5d8f04
        return try {
            val androidUri = android.net.Uri.parse(uri)

            // Allow both with and without scheme
            val cardId = androidUri.getQueryParameter("id")
            val secret = androidUri.getQueryParameter("secret")

            if (cardId != null && secret != null) {
                NFCCardData(cardId = cardId.uppercase(), signature = secret)
            } else {
                Log.w(TAG, "Missing id or secret in URI: $uri")
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

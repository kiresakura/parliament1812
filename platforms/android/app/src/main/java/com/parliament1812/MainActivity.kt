package com.parliament1812

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.parliament1812.nfc.NFCManager
import com.parliament1812.ui.navigation.NavGraph
import com.parliament1812.ui.theme.DarkBackground
import com.parliament1812.ui.theme.Parliament1812Theme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var nfcManager: NFCManager

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        enableEdgeToEdge()

        Log.d(TAG, "onCreate - NFC available: ${nfcManager.isNFCAvailable(this)}")

        setContent {
            Parliament1812Theme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = DarkBackground
                ) {
                    NavGraph(nfcManager = nfcManager)
                }
            }
        }

        // Handle NFC intent if app was launched from NFC
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume")
        // NFC foreground dispatch is handled by individual screens
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "onPause")
        // Note: NFC dispatch is managed by individual screens (NFCScanScreen)
        // to avoid conflicts with their lifecycle management
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent: ${intent.action}")
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        Log.d(TAG, "handleIntent: ${intent.action}")
        nfcManager.handleIntent(intent)
    }
}

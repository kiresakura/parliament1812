package com.parliament1812.ui.screens

import android.app.Activity
import android.util.Log
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Nfc
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.painterResource
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.nfc.NFCManager
import com.parliament1812.nfc.NFCState
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.PlayerViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NFCScanScreen(
    roomCode: String,
    playerId: String,
    nfcManager: NFCManager,
    onRoleAssigned: (roleType: String, roleIndex: Int) -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: PlayerViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val activity = context as Activity
    val lifecycleOwner = LocalLifecycleOwner.current

    val nfcState by nfcManager.state.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    var showManualInputDialog by remember { mutableStateOf(false) }
    var manualCode by remember { mutableStateOf("") }

    // Check NFC availability dynamically (not cached)
    val isNfcAvailable by remember {
        derivedStateOf { nfcManager.isNFCAvailable(activity) }
    }
    var isNfcEnabled by remember { mutableStateOf(false) }

    // Update NFC enabled state when screen resumes
    LaunchedEffect(Unit) {
        isNfcEnabled = nfcManager.isNFCEnabled()
    }

    // Lifecycle-aware NFC foreground dispatch
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> {
                    Log.d("NFCScanScreen", "ON_RESUME - Enabling NFC dispatch")
                    // Re-check NFC enabled state
                    isNfcEnabled = nfcManager.isNFCEnabled()
                    if (nfcManager.isNFCAvailable(activity) && nfcManager.isNFCEnabled()) {
                        nfcManager.enableForegroundDispatch(activity)
                    }
                }
                Lifecycle.Event.ON_PAUSE -> {
                    Log.d("NFCScanScreen", "ON_PAUSE - Disabling NFC dispatch")
                    nfcManager.disableForegroundDispatch(activity)
                }
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)

        // Initial enable if already resumed
        if (lifecycleOwner.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) {
            isNfcEnabled = nfcManager.isNFCEnabled()
            if (nfcManager.isNFCAvailable(activity) && nfcManager.isNFCEnabled()) {
                nfcManager.enableForegroundDispatch(activity)
            }
        }

        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            nfcManager.disableForegroundDispatch(activity)
        }
    }

    // Handle NFC scan success
    LaunchedEffect(nfcState) {
        Log.d("NFCScanScreen", "LaunchedEffect triggered with state: $nfcState")
        if (nfcState is NFCState.Success) {
            val cardData = (nfcState as NFCState.Success).data
            Log.d("NFCScanScreen", "NFC Success detected! cardId=${cardData.cardId}, submitting to API...")
            viewModel.submitNFCScan(roomCode, playerId, cardData) { roleType, roleIndex ->
                Log.d("NFCScanScreen", "Role assigned callback: $roleType/$roleIndex")
                onRoleAssigned(roleType, roleIndex)
            }
            nfcManager.resetState()
        }
    }

    // Handle role assignment success
    LaunchedEffect(uiState.roleAssigned) {
        if (uiState.roleAssigned) {
            uiState.currentPlayer?.let { player ->
                if (player.roleType != null && player.roleIndex != null) {
                    onRoleAssigned(player.roleType, player.roleIndex)
                }
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Background Image
        Image(
            painter = painterResource(id = R.drawable.bg_parliament),
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )

        // Dark Overlay
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(DarkOverlay80)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
        ) {
            // Top Header Bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DarkOverlay95)
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onNavigateBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "返回",
                        tint = Gold
                    )
                }

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "身份認證",
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "IDENTITY VERIFICATION",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // NFC Icon with decorative ring
                Box(
                    modifier = Modifier
                        .size(160.dp)
                        .clip(CircleShape)
                        .background(
                            brush = Brush.radialGradient(
                                colors = listOf(
                                    when (nfcState) {
                                        is NFCState.Success -> Success.copy(alpha = 0.2f)
                                        is NFCState.Error -> Error.copy(alpha = 0.2f)
                                        else -> Gold.copy(alpha = 0.15f)
                                    },
                                    Color.Transparent
                                )
                            )
                        )
                        .border(
                            width = 2.dp,
                            color = when (nfcState) {
                                is NFCState.Success -> Success.copy(alpha = 0.5f)
                                is NFCState.Error -> Error.copy(alpha = 0.5f)
                                else -> Gold.copy(alpha = 0.3f)
                            },
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Nfc,
                        contentDescription = null,
                        modifier = Modifier.size(72.dp),
                        tint = when (nfcState) {
                            is NFCState.Success -> Success
                            is NFCState.Error -> Error
                            else -> Gold
                        }
                    )
                }

                Spacer(modifier = Modifier.height(40.dp))

                // Status Text
                Text(
                    text = when {
                        uiState.isLoading -> "驗證中..."
                        nfcState is NFCState.Success -> "掃描成功！"
                        nfcState is NFCState.Error -> "掃描失敗"
                        !isNfcAvailable -> "您的裝置不支援 NFC"
                        !isNfcEnabled -> "請開啟 NFC 功能"
                        nfcState is NFCState.Scanning -> "請將卡片靠近手機背面..."
                        else -> "準備掃描身份令牌"
                    },
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Medium,
                    fontFamily = FontFamily.Serif,
                    color = when (nfcState) {
                        is NFCState.Success -> Success
                        is NFCState.Error -> Error
                        else -> TextPrimary
                    },
                    textAlign = TextAlign.Center
                )

                Text(
                    text = when {
                        uiState.isLoading -> "VERIFYING..."
                        nfcState is NFCState.Success -> "SCAN SUCCESSFUL"
                        nfcState is NFCState.Error -> "SCAN FAILED"
                        !isNfcAvailable -> "NFC NOT SUPPORTED"
                        !isNfcEnabled -> "PLEASE ENABLE NFC"
                        nfcState is NFCState.Scanning -> "HOLD CARD TO PHONE..."
                        else -> "READY TO SCAN"
                    },
                    fontSize = 10.sp,
                    color = TextMuted,
                    letterSpacing = 2.sp
                )

                // Error message
                if (nfcState is NFCState.Error) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = (nfcState as NFCState.Error).message,
                        fontSize = 13.sp,
                        color = Error,
                        textAlign = TextAlign.Center
                    )
                }

                uiState.error?.let { error ->
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = error,
                        fontSize = 13.sp,
                        color = Error,
                        textAlign = TextAlign.Center
                    )
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Loading indicator
                if (uiState.isLoading) {
                    CircularProgressIndicator(
                        color = Gold,
                        modifier = Modifier.size(40.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.height(32.dp))
                }

                // Retry button if error
                if (nfcState is NFCState.Error || uiState.error != null) {
                    Button(
                        onClick = {
                            viewModel.clearError()
                            nfcManager.resetState()
                            if (isNfcAvailable && isNfcEnabled) {
                                nfcManager.enableForegroundDispatch(activity)
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Gold,
                            contentColor = DarkBackground
                        ),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = "重試",
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }

                Spacer(modifier = Modifier.weight(1f))

                // Decorative Quote
                Text(
                    text = "「每位議員都有其獨特的使命」",
                    color = TextMuted,
                    fontSize = 12.sp,
                    fontStyle = FontStyle.Italic,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Manual Input Button
                OutlinedButton(
                    onClick = { showManualInputDialog = true },
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = GoldAccent
                    ),
                    border = ButtonDefaults.outlinedButtonBorder.copy(
                        brush = Brush.horizontalGradient(listOf(GoldAccent, GoldAccent))
                    ),
                    shape = RoundedCornerShape(4.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.Edit,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "手動輸入代碼",
                        fontSize = 14.sp
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))
            }
        }

        // Manual Input Dialog
        if (showManualInputDialog) {
            AlertDialog(
                onDismissRequest = {
                    showManualInputDialog = false
                    manualCode = ""
                },
                title = {
                    Column {
                        Text(
                            text = "手動輸入角色代碼",
                            color = TextPrimary,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "MANUAL CODE ENTRY",
                            color = TextMuted,
                            fontSize = 10.sp,
                            letterSpacing = 1.sp
                        )
                    }
                },
                text = {
                    Column {
                        Text(
                            text = "請輸入卡片背面的角色代碼",
                            color = TextSecondary,
                            fontSize = 13.sp
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        OutlinedTextField(
                            value = manualCode,
                            onValueChange = { manualCode = it.uppercase().take(3) },
                            label = { Text("角色代碼", color = TextMuted) },
                            placeholder = { Text("如 W01、G01", color = TextMuted) },
                            singleLine = true,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = Gold,
                                unfocusedBorderColor = InputBorder,
                                focusedLabelColor = Gold,
                                cursorColor = Gold,
                                focusedTextColor = TextPrimary,
                                unfocusedTextColor = TextPrimary,
                                focusedContainerColor = DarkOverlay80,
                                unfocusedContainerColor = DarkOverlay80
                            ),
                            keyboardOptions = KeyboardOptions(
                                capitalization = KeyboardCapitalization.Characters,
                                imeAction = ImeAction.Done
                            ),
                            keyboardActions = KeyboardActions(
                                onDone = {
                                    if (manualCode.length == 3) {
                                        showManualInputDialog = false
                                        viewModel.submitManualCode(
                                            roomCode,
                                            playerId,
                                            manualCode
                                        ) { roleType, roleIndex ->
                                            onRoleAssigned(roleType, roleIndex)
                                        }
                                        manualCode = ""
                                    }
                                }
                            ),
                            shape = RoundedCornerShape(4.dp),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showManualInputDialog = false
                            viewModel.submitManualCode(
                                roomCode,
                                playerId,
                                manualCode
                            ) { roleType, roleIndex ->
                                onRoleAssigned(roleType, roleIndex)
                            }
                            manualCode = ""
                        },
                        enabled = manualCode.length == 3
                    ) {
                        Text(
                            text = "確認",
                            color = if (manualCode.length == 3) Gold else TextMuted
                        )
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = {
                            showManualInputDialog = false
                            manualCode = ""
                        }
                    ) {
                        Text("取消", color = TextMuted)
                    }
                },
                containerColor = DarkSurface,
                shape = RoundedCornerShape(8.dp)
            )
        }
    }
}

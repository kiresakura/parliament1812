ㄥ# 1812 國會風雲 - Android 原生開發指南 (Kotlin/Jetpack Compose)

## 專案概述

這是一款以 1812 年英國盧德運動為背景的國會辯論角色扮演遊戲 Android 原生版本。
使用 **Kotlin + Jetpack Compose** 開發，原生 **Android NFC API** 防作弊系統。

**目標**: Alpha Demo 於 2026/01/07，支援 6 人同時遊玩

---

## 建議專案架構

```
app/
├── src/main/
│   ├── java/com/parliament1812/
│   │   ├── Parliament1812App.kt          # Application class
│   │   ├── MainActivity.kt               # 主 Activity (NFC 處理)
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── Player.kt
│   │   │   │   ├── Room.kt
│   │   │   │   ├── Role.kt
│   │   │   │   └── NFCCardData.kt
│   │   │   ├── remote/
│   │   │   │   ├── ApiService.kt         # Retrofit interface
│   │   │   │   ├── WebSocketService.kt   # OkHttp WebSocket
│   │   │   │   └── DTOs.kt               # Request/Response
│   │   │   └── repository/
│   │   │       ├── RoomRepository.kt
│   │   │       └── NFCRepository.kt
│   │   ├── di/
│   │   │   └── AppModule.kt              # Hilt DI
│   │   ├── nfc/
│   │   │   └── NFCManager.kt             # NFC 讀取封裝
│   │   ├── ui/
│   │   │   ├── navigation/
│   │   │   │   └── NavGraph.kt
│   │   │   ├── screens/
│   │   │   │   ├── HomeScreen.kt
│   │   │   │   ├── WaitingRoomScreen.kt
│   │   │   │   ├── NFCScanScreen.kt
│   │   │   │   ├── GameScreen.kt
│   │   │   │   └── VotingScreen.kt
│   │   │   ├── components/               # 共用 Composable
│   │   │   └── theme/
│   │   │       ├── Theme.kt
│   │   │       ├── Color.kt
│   │   │       └── Type.kt
│   │   └── viewmodels/
│   │       ├── RoomViewModel.kt
│   │       ├── PlayerViewModel.kt
│   │       └── GameViewModel.kt
│   ├── res/
│   │   ├── values/
│   │   │   └── strings.xml
│   │   └── xml/
│   │       └── nfc_tech_filter.xml       # NFC 技術過濾
│   └── AndroidManifest.xml
├── build.gradle.kts
└── proguard-rules.pro
```

---

## 系統需求

| 項目 | 需求 |
|------|------|
| Android 版本 | API 24+ (Android 7.0) |
| Android Studio | Hedgehog 或更新 |
| Kotlin | 1.9+ |
| Compose | 1.5+ |
| NFC 硬體 | 大多數 Android 設備支援 |

---

## 依賴配置 (build.gradle.kts)

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.dagger.hilt.android")
    id("org.jetbrains.kotlin.plugin.serialization")
    kotlin("kapt")
}

android {
    namespace = "com.parliament1812"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.parliament1812"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0-alpha"
    }
    
    buildFeatures {
        compose = true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }
}

dependencies {
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.navigation:navigation-compose:2.7.6")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    
    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-kotlinx-serialization:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:2.50")
    kapt("com.google.dagger:hilt-compiler:2.50")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```


---

## AndroidManifest.xml 配置

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- 權限 -->
    <uses-permission android:name="android.permission.NFC" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- NFC 硬體需求 (非必須，允許無 NFC 設備安裝) -->
    <uses-feature android:name="android.hardware.nfc" android:required="false" />

    <application
        android:name=".Parliament1812App"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.Parliament1812">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            
            <!-- NFC Intent Filter -->
            <intent-filter>
                <action android:name="android.nfc.action.NDEF_DISCOVERED" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:scheme="parliament1812" />
            </intent-filter>
            
            <!-- Deep Link -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="parliament1812" />
            </intent-filter>
            
        </activity>
    </application>
</manifest>
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

### WebSocket

```
wss://1812-production.up.railway.app/ws/{room_code}/{player_id}
```

事件: `player_joined`, `player_left`, `role_assigned`, `game_started`, `vote_started`, `vote_ended`

---

## NFC 實作

### NFCManager.kt

```kotlin
package com.parliament1812.nfc

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Build
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton

data class NFCCardData(
    val cardId: String,      // e.g., "GEORGEIII01"
    val signature: String    // e.g., "7f3a9c2b1e5d8f04"
)

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
        
        nfcAdapter?.enableForegroundDispatch(activity, pendingIntent, null, null)
        _state.value = NFCState.Scanning
    }
    
    fun disableForegroundDispatch(activity: Activity) {
        nfcAdapter?.disableForegroundDispatch(activity)
        _state.value = NFCState.Idle
    }
    
    fun handleIntent(intent: Intent) {
        if (NfcAdapter.ACTION_NDEF_DISCOVERED == intent.action ||
            NfcAdapter.ACTION_TAG_DISCOVERED == intent.action) {
            
            val tag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
            }
            
            tag?.let { processTag(it) }
        }
    }
    
    private fun processTag(tag: Tag) {
        try {
            val ndef = Ndef.get(tag)
            ndef?.connect()
            
            val ndefMessage = ndef?.ndefMessage
            ndef?.close()
            
            if (ndefMessage != null) {
                val uri = parseNdefMessage(ndefMessage)
                if (uri != null) {
                    val cardData = parseUri(uri)
                    if (cardData != null) {
                        _state.value = NFCState.Success(cardData)
                    } else {
                        _state.value = NFCState.Error("無效的卡片格式")
                    }
                } else {
                    _state.value = NFCState.Error("無法讀取卡片資料")
                }
            }
        } catch (e: Exception) {
            _state.value = NFCState.Error("讀取錯誤: ${e.message}")
        }
    }
    
    private fun parseNdefMessage(message: NdefMessage): String? {
        for (record in message.records) {
            // 檢查 URI record
            if (record.tnf == android.nfc.NdefRecord.TNF_WELL_KNOWN) {
                val payload = record.payload
                if (payload.isNotEmpty()) {
                    // 第一個 byte 是 URI prefix code
                    val prefixCode = payload[0].toInt()
                    val uriBytes = payload.copyOfRange(1, payload.size)
                    val uriSuffix = String(uriBytes, Charsets.UTF_8)
                    
                    // prefixCode 0 = 無 prefix (自定義 scheme)
                    return if (prefixCode == 0) uriSuffix else uriSuffix
                }
            }
        }
        return null
    }
    
    private fun parseUri(uri: String): NFCCardData? {
        // 解析: parliament1812://role?id=GEORGEIII01&secret=7f3a9c2b1e5d8f04
        return try {
            val androidUri = android.net.Uri.parse(uri)
            if (androidUri.scheme != "parliament1812") return null
            
            val cardId = androidUri.getQueryParameter("id") ?: return null
            val secret = androidUri.getQueryParameter("secret") ?: return null
            
            NFCCardData(cardId = cardId, signature = secret)
        } catch (e: Exception) {
            null
        }
    }
    
    fun resetState() {
        _state.value = NFCState.Idle
    }
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

---

## API Service 實作

### ApiService.kt (Retrofit)

```kotlin
package com.parliament1812.data.remote

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import retrofit2.http.*

interface ApiService {
    
    @POST("api/rooms")
    suspend fun createRoom(@Body request: CreateRoomRequest): CreateRoomResponse
    
    @GET("api/rooms/{code}")
    suspend fun getRoom(@Path("code") code: String): Room
    
    @POST("api/rooms/{code}/join")
    suspend fun joinRoom(
        @Path("code") code: String,
        @Body request: JoinRoomRequest
    ): Player
    
    @GET("api/rooms/{code}/players")
    suspend fun getPlayers(@Path("code") code: String): List<Player>
    
    @POST("api/nfc/scan")
    suspend fun scanNFC(@Body request: NFCScanRequest): NFCScanResponse
    
    @GET("api/roles")
    suspend fun getRoles(): List<Role>
    
    @GET("api/roles/{roleType}")
    suspend fun getRole(@Path("roleType") roleType: String): Role
}

// DTOs
@Serializable
data class CreateRoomRequest(
    @SerialName("host_nickname") val hostNickname: String
)

@Serializable
data class CreateRoomResponse(
    val code: String,
    val player: Player
)

@Serializable
data class JoinRoomRequest(
    val nickname: String
)

@Serializable
data class NFCScanRequest(
    @SerialName("room_code") val roomCode: String,
    @SerialName("player_id") val playerId: String,
    @SerialName("card_id") val cardId: String,
    val signature: String
)

@Serializable
data class NFCScanResponse(
    val success: Boolean,
    @SerialName("role_type") val roleType: String? = null,
    @SerialName("role_index") val roleIndex: Int? = null,
    val role: Role? = null,
    val message: String? = null
)
```

### NetworkModule.kt (Hilt DI)

```kotlin
package com.parliament1812.di

import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.parliament1812.data.remote.ApiService
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    private const val BASE_URL = "https://1812-production.up.railway.app/"
    
    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
    }
    
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            })
            .build()
    }
    
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
    }
    
    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService {
        return retrofit.create(ApiService::class.java)
    }
}
```


---

## WebSocket Service

### WebSocketService.kt

```kotlin
package com.parliament1812.data.remote

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.*
import javax.inject.Inject
import javax.inject.Singleton

sealed class WebSocketEvent {
    data class PlayerJoined(val player: Player) : WebSocketEvent()
    data class PlayerLeft(val playerId: String) : WebSocketEvent()
    data class RoleAssigned(val playerId: String, val roleType: String, val roleIndex: Int) : WebSocketEvent()
    object GameStarted : WebSocketEvent()
    object VoteStarted : WebSocketEvent()
    object VoteEnded : WebSocketEvent()
    data class Error(val message: String) : WebSocketEvent()
    object Connected : WebSocketEvent()
    object Disconnected : WebSocketEvent()
}

@Singleton
class WebSocketService @Inject constructor(
    private val okHttpClient: OkHttpClient
) {
    private var webSocket: WebSocket? = null
    private val scope = CoroutineScope(Dispatchers.IO)
    private val json = Json { ignoreUnknownKeys = true }
    
    private val _events = MutableSharedFlow<WebSocketEvent>()
    val events: SharedFlow<WebSocketEvent> = _events
    
    fun connect(roomCode: String, playerId: String) {
        val url = "wss://1812-production.up.railway.app/ws/$roomCode/$playerId"
        val request = Request.Builder().url(url).build()
        
        webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                scope.launch { _events.emit(WebSocketEvent.Connected) }
            }
            
            override fun onMessage(webSocket: WebSocket, text: String) {
                scope.launch { handleMessage(text) }
            }
            
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                scope.launch { _events.emit(WebSocketEvent.Disconnected) }
            }
            
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                scope.launch { _events.emit(WebSocketEvent.Error(t.message ?: "Unknown error")) }
            }
        })
    }
    
    fun disconnect() {
        webSocket?.close(1000, "User disconnected")
        webSocket = null
    }
    
    private suspend fun handleMessage(text: String) {
        try {
            val jsonElement = json.parseToJsonElement(text)
            val type = jsonElement.jsonObject["type"]?.jsonPrimitive?.content
            
            when (type) {
                "player_joined" -> {
                    // Parse player data
                }
                "player_left" -> {
                    val playerId = jsonElement.jsonObject["player_id"]?.jsonPrimitive?.content
                    playerId?.let { _events.emit(WebSocketEvent.PlayerLeft(it)) }
                }
                "role_assigned" -> {
                    val playerId = jsonElement.jsonObject["player_id"]?.jsonPrimitive?.content
                    val roleType = jsonElement.jsonObject["role_type"]?.jsonPrimitive?.content
                    val roleIndex = jsonElement.jsonObject["role_index"]?.jsonPrimitive?.content?.toIntOrNull()
                    
                    if (playerId != null && roleType != null && roleIndex != null) {
                        _events.emit(WebSocketEvent.RoleAssigned(playerId, roleType, roleIndex))
                    }
                }
                "game_started" -> _events.emit(WebSocketEvent.GameStarted)
                "vote_started" -> _events.emit(WebSocketEvent.VoteStarted)
                "vote_ended" -> _events.emit(WebSocketEvent.VoteEnded)
            }
        } catch (e: Exception) {
            _events.emit(WebSocketEvent.Error("Parse error: ${e.message}"))
        }
    }
}
```

---

## Models

### Player.kt

```kotlin
package com.parliament1812.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Player(
    val id: String,
    val nickname: String,
    @SerialName("is_host") val isHost: Boolean = false,
    @SerialName("role_type") val roleType: String? = null,
    @SerialName("role_index") val roleIndex: Int? = null
) {
    val hasRole: Boolean get() = roleType != null && roleIndex != null
}
```

### Room.kt

```kotlin
package com.parliament1812.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Room(
    val code: String,
    @SerialName("host_id") val hostId: String,
    val players: List<Player>,
    val status: RoomStatus,
    @SerialName("created_at") val createdAt: String
)

@Serializable
enum class RoomStatus {
    @SerialName("waiting") WAITING,
    @SerialName("playing") PLAYING,
    @SerialName("finished") FINISHED
}
```

### Role.kt

```kotlin
package com.parliament1812.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Role(
    val id: String,
    @SerialName("name_zh") val nameZh: String,
    @SerialName("name_en") val nameEn: String,
    val faction: String,
    val description: String? = null
)
```


---

## Compose UI 範例

### MainActivity.kt (NFC 處理)

```kotlin
package com.parliament1812

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.parliament1812.nfc.NFCManager
import com.parliament1812.ui.navigation.NavGraph
import com.parliament1812.ui.theme.Parliament1812Theme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    @Inject
    lateinit var nfcManager: NFCManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        setContent {
            Parliament1812Theme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    NavGraph(nfcManager = nfcManager)
                }
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        // 由 Screen 控制何時啟用 NFC
    }
    
    override fun onPause() {
        super.onPause()
        nfcManager.disableForegroundDispatch(this)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        nfcManager.handleIntent(intent)
    }
}
```

### HomeScreen.kt

```kotlin
package com.parliament1812.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun HomeScreen(
    onNavigateToWaitingRoom: (String, Boolean) -> Unit,
    viewModel: RoomViewModel = hiltViewModel()
) {
    var nickname by remember { mutableStateOf("") }
    var roomCode by remember { mutableStateOf("") }
    
    val uiState by viewModel.uiState.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "1812 國會風雲",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(48.dp))
        
        OutlinedTextField(
            value = nickname,
            onValueChange = { nickname = it },
            label = { Text("你的暱稱") },
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(
            onClick = {
                viewModel.createRoom(nickname) { code ->
                    onNavigateToWaitingRoom(code, true)
                }
            },
            enabled = nickname.isNotBlank() && !uiState.isLoading,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("建立房間")
        }
        
        Spacer(modifier = Modifier.height(32.dp))
        
        HorizontalDivider()
        
        Spacer(modifier = Modifier.height(32.dp))
        
        OutlinedTextField(
            value = roomCode,
            onValueChange = { roomCode = it.uppercase() },
            label = { Text("房間代碼") },
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        OutlinedButton(
            onClick = {
                viewModel.joinRoom(roomCode, nickname) {
                    onNavigateToWaitingRoom(roomCode, false)
                }
            },
            enabled = nickname.isNotBlank() && roomCode.isNotBlank() && !uiState.isLoading,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("加入房間")
        }
        
        uiState.error?.let { error ->
            Spacer(modifier = Modifier.height(16.dp))
            Text(text = error, color = MaterialTheme.colorScheme.error)
        }
    }
}
```

### NFCScanScreen.kt

```kotlin
package com.parliament1812.ui.screens

import android.app.Activity
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Nfc
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.parliament1812.nfc.NFCManager
import com.parliament1812.nfc.NFCState

@Composable
fun NFCScanScreen(
    roomCode: String,
    playerId: String,
    nfcManager: NFCManager,
    onRoleAssigned: (String, Int) -> Unit,
    viewModel: PlayerViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val activity = context as Activity
    
    val nfcState by nfcManager.state.collectAsState()
    
    LaunchedEffect(Unit) {
        if (nfcManager.isNFCAvailable(activity) && nfcManager.isNFCEnabled()) {
            nfcManager.enableForegroundDispatch(activity)
        }
    }
    
    DisposableEffect(Unit) {
        onDispose {
            nfcManager.disableForegroundDispatch(activity)
        }
    }
    
    // 監聽 NFC 掃描結果
    LaunchedEffect(nfcState) {
        if (nfcState is NFCState.Success) {
            val cardData = (nfcState as NFCState.Success).data
            viewModel.submitNFCScan(roomCode, playerId, cardData) { roleType, roleIndex ->
                onRoleAssigned(roleType, roleIndex)
            }
            nfcManager.resetState()
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Nfc,
            contentDescription = null,
            modifier = Modifier.size(120.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Text(
            text = when (nfcState) {
                is NFCState.Idle -> "準備掃描 NFC 角色卡"
                is NFCState.Scanning -> "請將卡片靠近手機背面..."
                is NFCState.Success -> "掃描成功！"
                is NFCState.Error -> "掃描失敗"
            },
            style = MaterialTheme.typography.headlineSmall
        )
        
        if (nfcState is NFCState.Error) {
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = (nfcState as NFCState.Error).message,
                color = MaterialTheme.colorScheme.error
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = {
                nfcManager.resetState()
                nfcManager.enableForegroundDispatch(activity)
            }) {
                Text("重試")
            }
        }
    }
}
```


---

## ViewModel 範例

### RoomViewModel.kt

```kotlin
package com.parliament1812.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.parliament1812.data.remote.ApiService
import com.parliament1812.data.remote.CreateRoomRequest
import com.parliament1812.data.remote.JoinRoomRequest
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RoomUiState(
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class RoomViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(RoomUiState())
    val uiState: StateFlow<RoomUiState> = _uiState
    
    fun createRoom(nickname: String, onSuccess: (String) -> Unit) {
        viewModelScope.launch {
            _uiState.value = RoomUiState(isLoading = true)
            try {
                val response = apiService.createRoom(CreateRoomRequest(nickname))
                _uiState.value = RoomUiState()
                onSuccess(response.code)
            } catch (e: Exception) {
                _uiState.value = RoomUiState(error = "建立房間失敗: ${e.message}")
            }
        }
    }
    
    fun joinRoom(code: String, nickname: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            _uiState.value = RoomUiState(isLoading = true)
            try {
                apiService.joinRoom(code, JoinRoomRequest(nickname))
                _uiState.value = RoomUiState()
                onSuccess()
            } catch (e: Exception) {
                _uiState.value = RoomUiState(error = "加入房間失敗: ${e.message}")
            }
        }
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
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

### 問題 2: 加入房間後顯示錯誤訊息

**可能原因**:
1. API 回應格式與預期不符
2. 錯誤狀態未正確清除

**需檢查**: ViewModel 的錯誤處理邏輯

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

1. Android Studio → New Project
2. 選擇 "Empty Compose Activity"
3. Name: `Parliament1812`
4. Package name: `com.parliament1812`
5. Minimum SDK: API 24

### 執行專案

```bash
# 列出連接的設備
adb devices

# 安裝到設備
./gradlew installDebug

# 或使用 Android Studio 的 Run 按鈕
```

### 打包 APK

```bash
# Debug APK
./gradlew assembleDebug
# 輸出: app/build/outputs/apk/debug/app-debug.apk

# Release APK (需要簽名配置)
./gradlew assembleRelease
# 輸出: app/build/outputs/apk/release/app-release.apk
```

### 打包 AAB (Google Play)

```bash
./gradlew bundleRelease
# 輸出: app/build/outputs/bundle/release/app-release.aab
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

### 單元測試

```kotlin
@Test
fun `parseUri should extract cardId and signature`() {
    val nfcManager = NFCManager()
    val uri = "parliament1812://role?id=GEORGEIII01&secret=7f3a9c2b1e5d8f04"
    
    // 使用反射或暴露測試方法
    val result = nfcManager.testParseUri(uri)
    
    assertNotNull(result)
    assertEquals("GEORGEIII01", result?.cardId)
    assertEquals("7f3a9c2b1e5d8f04", result?.signature)
}

@Test
fun `parseUri should return null for invalid scheme`() {
    val nfcManager = NFCManager()
    val uri = "invalid://role?id=TEST01&secret=abc123"
    
    val result = nfcManager.testParseUri(uri)
    
    assertNull(result)
}
```

---

## Android vs iOS 差異

| 功能 | Android | iOS |
|------|---------|-----|
| NFC 掃描 UI | 完全自訂 | 系統彈窗，無法自訂 |
| NFC 背景掃描 | ✅ 完整支援 | 有限支援 |
| Foreground Dispatch | 需手動管理 | 自動處理 |
| 設備支援 | 大多數設備 | iPhone 7+ only |
| 模擬器 NFC | ❌ 不支援 | ❌ 不支援 |
| Deep Link | `parliament1812://` | 相同 |

---

## 常見問題

| 問題 | 原因 | 解決 |
|------|------|------|
| NFC 掃描無反應 | Foreground Dispatch 未啟用 | 檢查 `enableForegroundDispatch` |
| "NFC is disabled" | 使用者關閉 NFC | 引導使用者開啟設定 |
| Hilt 注入失敗 | 缺少 @AndroidEntryPoint | 確保 Activity/Fragment 有註解 |
| API 連線失敗 | 網路權限 | 檢查 `INTERNET` permission |
| Compose Preview 崩潰 | ViewModel 注入問題 | Preview 中使用 mock 資料 |

---

## 調試技巧

### Logcat Filter

```
tag:Parliament1812 level:debug
```

### 調試 NFC

```kotlin
Log.d("NFC", "Tag detected: ${tag.id.toHexString()}")
Log.d("NFC", "URI parsed: $uri")
Log.d("NFC", "CardData: cardId=${cardData.cardId}, sig=${cardData.signature}")
```

### 調試 API

使用 OkHttp Logging Interceptor (已在 NetworkModule 配置)

---

## 參考資源

- [Android NFC 官方文檔](https://developer.android.com/develop/connectivity/nfc)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Hilt 依賴注入](https://developer.android.com/training/dependency-injection/hilt-android)
- [Retrofit](https://square.github.io/retrofit/)

---

*最後更新: 2024-12-20*
*框架: Kotlin 1.9 + Jetpack Compose + Hilt + Retrofit*

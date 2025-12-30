package com.parliament1812.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.unit.IntOffset
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.data.models.RoleDatabase
import com.parliament1812.ui.components.AmbientParticles
import com.parliament1812.ui.components.CharacterPortrait
import com.parliament1812.ui.components.GoldDivider
import com.parliament1812.ui.components.HexagonalPattern
import com.parliament1812.ui.components.VignetteOverlay
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.PlayerViewModel

@Composable
fun RoleCardScreen(
    roleType: String,
    roleIndex: Int,
    onContinue: () -> Unit,
    viewModel: PlayerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val scrollState = rememberScrollState()

    // 從 RoleDatabase 獲取詳細角色資料
    val roleData = RoleDatabase.getRoleByType(roleType)
    val secretMission = RoleDatabase.getSecretMission(roleType, roleIndex - 1) // roleIndex 是 1-based

    val roleColor = roleData?.color ?: GoldMuted
    val roleName = roleData?.nameZh ?: "未知角色"
    val roleNameEn = roleData?.nameEn ?: "UNKNOWN"
    val characterName = roleData?.characterName ?: ""
    val roleDescription = roleData?.description ?: "角色描述載入中..."
    val roleQuote = roleData?.quote ?: ""
    val roleBackground = roleData?.background ?: ""
    val roleAbilities = roleData?.abilities ?: emptyList()

    Box(modifier = Modifier.fillMaxSize()) {
        // Background Image
        Image(
            painter = painterResource(id = R.drawable.bg_parliament),
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )

        // Dark Overlay with role color tint
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(DarkOverlay80)
        )

        // Hexagonal Pattern
        HexagonalPattern(
            modifier = Modifier.fillMaxSize(),
            hexSize = 45f,
            color = roleColor.copy(alpha = 0.03f)
        )

        // Ambient Particles
        AmbientParticles(
            modifier = Modifier.fillMaxSize(),
            particleCount = 15
        )

        // Vignette Effect
        VignetteOverlay(
            modifier = Modifier.fillMaxSize(),
            intensity = 0.6f
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
                .verticalScroll(scrollState)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            // Success Badge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                    tint = Success
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "身份已確認",
                    fontSize = 16.sp,
                    color = Success,
                    fontWeight = FontWeight.Medium
                )
            }

            Text(
                text = "IDENTITY CONFIRMED",
                fontSize = 10.sp,
                color = Success.copy(alpha = 0.7f),
                letterSpacing = 2.sp
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Role Card
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = DarkOverlay95
                ),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, roleColor.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Role Portrait - 簡潔六邊形肖像框
                    CharacterPortrait(
                        roleType = roleType,
                        size = 120.dp
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Role Name
                    Text(
                        text = roleName,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif,
                        color = roleColor
                    )

                    Text(
                        text = roleNameEn,
                        fontSize = 11.sp,
                        color = TextMuted,
                        letterSpacing = 2.sp
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Character Name with Age
                    if (characterName.isNotEmpty()) {
                        Text(
                            text = "$characterName，${roleData?.age ?: 0}歲",
                            fontSize = 14.sp,
                            color = TextSecondary,
                            fontFamily = FontFamily.Serif
                        )
                    }

                    Text(
                        text = "#${String.format("%02d", roleIndex)}",
                        fontSize = 12.sp,
                        color = TextMuted,
                        fontFamily = FontFamily.Serif
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Decorative Divider
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        HorizontalDivider(
                            modifier = Modifier.weight(1f),
                            color = roleColor.copy(alpha = 0.3f)
                        )
                        Text(
                            text = " ◇ ",
                            color = roleColor,
                            fontSize = 12.sp
                        )
                        HorizontalDivider(
                            modifier = Modifier.weight(1f),
                            color = roleColor.copy(alpha = 0.3f)
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Character Quote
                    if (roleQuote.isNotEmpty()) {
                        Text(
                            text = "「$roleQuote」",
                            fontSize = 14.sp,
                            color = roleColor.copy(alpha = 0.9f),
                            textAlign = TextAlign.Center,
                            lineHeight = 22.sp,
                            fontStyle = FontStyle.Italic,
                            fontFamily = FontFamily.Serif
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    // Role Description
                    Text(
                        text = roleDescription,
                        fontSize = 14.sp,
                        color = TextSecondary,
                        textAlign = TextAlign.Center,
                        lineHeight = 22.sp
                    )

                    // Role Abilities Section
                    if (roleAbilities.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(20.dp))

                        // Abilities Header
                        Column {
                            Text(
                                text = "角色能力",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = roleColor
                            )
                            Text(
                                text = "ABILITIES",
                                fontSize = 9.sp,
                                color = TextMuted,
                                letterSpacing = 1.sp
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Abilities List
                        roleAbilities.forEachIndexed { index, ability ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.Top
                            ) {
                                // 使用羅馬數字替代表情符號
                                Text(
                                    text = listOf("Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ").getOrElse(index) { "${index + 1}" },
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = roleColor,
                                    modifier = Modifier.width(28.dp)
                                )
                                Column {
                                    Text(
                                        text = ability.name,
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = TextPrimary
                                    )
                                    Text(
                                        text = ability.description,
                                        fontSize = 12.sp,
                                        color = TextMuted,
                                        lineHeight = 18.sp
                                    )
                                }
                            }
                        }
                    }

                    // Secret Mission (from RoleDatabase if roleIndex matches)
                    secretMission?.let { mission ->
                        Spacer(modifier = Modifier.height(20.dp))

                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = Gold.copy(alpha = 0.08f)
                            ),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .border(1.dp, CardBorderGold, RoundedCornerShape(8.dp))
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text(
                                            text = "秘密任務",
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            color = Gold
                                        )
                                        Text(
                                            text = "SECRET MISSION",
                                            fontSize = 9.sp,
                                            color = TextMuted,
                                            letterSpacing = 1.sp
                                        )
                                    }
                                    Spacer(modifier = Modifier.weight(1f))
                                    // Mission Points Badge
                                    Surface(
                                        color = Gold.copy(alpha = 0.2f),
                                        shape = RoundedCornerShape(12.dp)
                                    ) {
                                        Text(
                                            text = "+${mission.points}分",
                                            fontSize = 11.sp,
                                            color = Gold,
                                            fontWeight = FontWeight.Medium,
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                        )
                                    }
                                }
                                Spacer(modifier = Modifier.height(12.dp))
                                Text(
                                    text = mission.title,
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = TextPrimary
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = mission.description.trim(),
                                    fontSize = 13.sp,
                                    color = TextSecondary,
                                    lineHeight = 20.sp
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                // Success Condition
                                Surface(
                                    color = Success.copy(alpha = 0.1f),
                                    shape = RoundedCornerShape(6.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Row(
                                        modifier = Modifier.padding(10.dp),
                                        verticalAlignment = Alignment.Top
                                    ) {
                                        Text(
                                            text = "✓",
                                            fontSize = 12.sp,
                                            color = Success,
                                            fontWeight = FontWeight.Bold
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Column {
                                            Text(
                                                text = "達成條件",
                                                fontSize = 11.sp,
                                                color = Success,
                                                fontWeight = FontWeight.Medium
                                            )
                                            Text(
                                                text = mission.successCondition ?: "",
                                                fontSize = 12.sp,
                                                color = TextSecondary,
                                                lineHeight = 18.sp
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Fallback: Server-loaded secret mission
                    if (secretMission == null) {
                        uiState.secretMission?.let { mission ->
                            Spacer(modifier = Modifier.height(20.dp))

                            Card(
                                colors = CardDefaults.cardColors(
                                    containerColor = Gold.copy(alpha = 0.08f)
                                ),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .border(1.dp, CardBorderGold, RoundedCornerShape(8.dp))
                            ) {
                                Column(
                                    modifier = Modifier.padding(16.dp)
                                ) {
                                    Column {
                                        Text(
                                            text = "秘密任務",
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            color = Gold
                                        )
                                        Text(
                                            text = "SECRET MISSION",
                                            fontSize = 9.sp,
                                            color = TextMuted,
                                            letterSpacing = 1.sp
                                        )
                                    }
                                    Spacer(modifier = Modifier.height(12.dp))
                                    Text(
                                        text = mission.title,
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = TextPrimary
                                    )
                                    Spacer(modifier = Modifier.height(6.dp))
                                    Text(
                                        text = mission.description,
                                        fontSize = 13.sp,
                                        color = TextSecondary,
                                        lineHeight = 20.sp
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Bottom Quote
            Text(
                text = "「願您在國會殿堂中為信念而戰」",
                color = TextMuted,
                fontSize = 12.sp,
                fontStyle = FontStyle.Italic,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Continue Button
            Button(
                onClick = onContinue,
                colors = ButtonDefaults.buttonColors(
                    containerColor = roleColor,
                    contentColor = TextPrimary
                ),
                shape = RoundedCornerShape(4.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
            ) {
                Text(
                    text = "☆  進入會議",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

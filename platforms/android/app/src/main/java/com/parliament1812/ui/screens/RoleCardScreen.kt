package com.parliament1812.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
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
import com.parliament1812.ui.components.CharacterPortrait
import com.parliament1812.ui.components.GoldDivider
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

    val roleColor = when (roleType) {
        "worker" -> WorkerColor
        "factory_owner" -> FactoryColor
        "luddite" -> LudditeColor
        "reformer" -> ReformerColor
        "mp" -> MPColor
        "george_iii" -> GeorgeIIIColor
        else -> GoldMuted
    }

    val roleName = when (roleType) {
        "worker" -> "紡織工人"
        "factory_owner" -> "工廠主"
        "luddite" -> "盧德派"
        "reformer" -> "改革者"
        "mp" -> "議員"
        "george_iii" -> "喬治三世"
        else -> "未知角色"
    }

    val roleNameEn = when (roleType) {
        "worker" -> "TEXTILE WORKER"
        "factory_owner" -> "FACTORY OWNER"
        "luddite" -> "LUDDITE"
        "reformer" -> "REFORMER"
        "mp" -> "MEMBER OF PARLIAMENT"
        "george_iii" -> "KING GEORGE III"
        else -> "UNKNOWN"
    }

    val roleDescription = when (roleType) {
        "worker" -> "你是一名紡織工人，機器的出現威脅著你的生計。你需要為工人的權益發聲。"
        "factory_owner" -> "你是一名工廠主，機器能為你帶來更多利潤。但你也需要考慮社會穩定。"
        "luddite" -> "你是盧德運動的成員，堅信機器會毀滅工人的生活。你願意採取激進行動。"
        "reformer" -> "你是一名改革者，相信透過立法可以在進步與保護之間找到平衡。"
        "mp" -> "你是一名國會議員，需要在各方利益之間權衡，做出最終決定。"
        "george_iii" -> "你是英國國王喬治三世，雖然精神狀態不穩定，但你的意見仍然舉足輕重。"
        else -> "角色描述載入中..."
    }

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

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))

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

            Spacer(modifier = Modifier.height(32.dp))

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
                    // Role Portrait - 文明6風格肖像
                    CharacterPortrait(
                        roleType = roleType,
                        size = 120.dp,
                        showIcon = true,
                        showGlow = true
                    )

                    Spacer(modifier = Modifier.height(20.dp))

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

                    Text(
                        text = "#${String.format("%02d", roleIndex)}",
                        fontSize = 14.sp,
                        color = TextSecondary,
                        fontFamily = FontFamily.Serif
                    )

                    Spacer(modifier = Modifier.height(20.dp))

                    // Decorative Divider
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Divider(
                            modifier = Modifier.weight(1f),
                            color = roleColor.copy(alpha = 0.3f)
                        )
                        Text(
                            text = " ◇ ",
                            color = roleColor,
                            fontSize = 12.sp
                        )
                        Divider(
                            modifier = Modifier.weight(1f),
                            color = roleColor.copy(alpha = 0.3f)
                        )
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    // Role Description
                    Text(
                        text = roleDescription,
                        fontSize = 15.sp,
                        color = TextSecondary,
                        textAlign = TextAlign.Center,
                        lineHeight = 24.sp,
                        fontStyle = FontStyle.Italic
                    )

                    // Secret Mission (if loaded)
                    uiState.secretMission?.let { mission ->
                        Spacer(modifier = Modifier.height(24.dp))

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
                                    Text(
                                        text = "🔒",
                                        fontSize = 14.sp
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
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

            Spacer(modifier = Modifier.weight(1f))

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

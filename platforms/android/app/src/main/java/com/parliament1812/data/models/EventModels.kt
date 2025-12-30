package com.parliament1812.data.models

import androidx.annotation.DrawableRes
import androidx.compose.ui.graphics.Color
import com.parliament1812.R
import com.parliament1812.ui.theme.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// ============================================
// 1812 國會風雲 - Event System Models
// ============================================

/**
 * 事件類別 - 國內/國際
 */
enum class EventCategory(
    val displayName: String,
    val englishName: String,
    @DrawableRes val iconRes: Int
) {
    DOMESTIC("國內", "Domestic", R.drawable.ic_role_mp),
    INTERNATIONAL("國際", "International", R.drawable.ic_role_george_iii)
}

/**
 * 國內事件類型
 */
enum class DomesticEventType(
    val displayName: String,
    val englishName: String,
    val color: Color
) {
    DISASTER("天災", "Disaster", VictorianRed),
    POLITICAL("政治", "Political", VictorianBlue),
    SOCIAL("社會", "Social", ReformerColor),
    ECONOMIC("經濟", "Economic", FactoryColor),
    MILITARY("軍事", "Military", MPColor),
    RELIGIOUS("宗教", "Religious", GoldMuted),
    SPECIAL("特殊", "Special", GeorgeIIIColor)
}

/**
 * 國際事件類型
 */
enum class InternationalEventType(
    val displayName: String,
    val englishName: String,
    val color: Color
) {
    WAR("戰爭", "War", VictorianRed),
    DIPLOMACY("外交", "Diplomacy", VictorianBlue),
    COLONY("殖民", "Colony", VictorianGreen)
}

/**
 * 統一事件類型（結合國內/國際）
 */
@Serializable
enum class EventType(
    val displayName: String,
    val englishName: String
) {
    // Domestic types
    @SerialName("disaster")
    DISASTER("天災", "Disaster"),

    @SerialName("political")
    POLITICAL("政治", "Political"),

    @SerialName("social")
    SOCIAL("社會", "Social"),

    @SerialName("economic")
    ECONOMIC("經濟", "Economic"),

    @SerialName("military")
    MILITARY("軍事", "Military"),

    @SerialName("religious")
    RELIGIOUS("宗教", "Religious"),

    @SerialName("special")
    SPECIAL("特殊", "Special"),

    // International types
    @SerialName("war")
    WAR("戰爭", "War"),

    @SerialName("diplomacy")
    DIPLOMACY("外交", "Diplomacy"),

    @SerialName("colony")
    COLONY("殖民", "Colony");

    val color: Color
        get() = when (this) {
            DISASTER, WAR -> VictorianRed
            POLITICAL, DIPLOMACY -> VictorianBlue
            SOCIAL -> ReformerColor
            ECONOMIC -> FactoryColor
            MILITARY -> MPColor
            RELIGIOUS -> GoldMuted
            SPECIAL -> GeorgeIIIColor
            COLONY -> VictorianGreen
        }

    val isDomestic: Boolean
        get() = this in listOf(DISASTER, POLITICAL, SOCIAL, ECONOMIC, MILITARY, RELIGIOUS, SPECIAL)

    companion object {
        /**
         * Parse string to EventType, defaulting to POLITICAL if not found
         */
        fun fromString(value: String?): EventType {
            if (value == null) return POLITICAL
            return entries.find {
                it.name.equals(value, ignoreCase = true) ||
                it.englishName.equals(value, ignoreCase = true)
            } ?: POLITICAL
        }
    }
}

/**
 * 事件效果
 */
@Serializable
data class EventEffect(
    @SerialName("target_role")
    val targetRole: String? = null,

    @SerialName("support_change")
    val supportChange: Int = 0,

    @SerialName("reputation_change")
    val reputationChange: Int = 0,

    val condition: String? = null
) {
    /**
     * 獲取效果描述文字
     */
    fun getDescription(): String {
        val parts = mutableListOf<String>()

        if (supportChange != 0) {
            val sign = if (supportChange > 0) "+" else ""
            parts.add("支持度 $sign$supportChange")
        }

        if (reputationChange != 0) {
            val sign = if (reputationChange > 0) "+" else ""
            parts.add("聲望 $sign$reputationChange")
        }

        return parts.joinToString("，")
    }

    /**
     * 判斷是否為正面效果
     */
    fun isPositive(): Boolean {
        return supportChange > 0 || reputationChange > 0
    }

    /**
     * 判斷是否為負面效果
     */
    fun isNegative(): Boolean {
        return supportChange < 0 || reputationChange < 0
    }
}

/**
 * 事件選項（用於互動式事件）
 */
@Serializable
data class EventChoice(
    val id: String,
    val title: String,
    val description: String,
    val effects: List<EventEffect> = emptyList()
)

/**
 * 遊戲事件資料
 */
@Serializable
data class GameEventData(
    val id: String,
    val title: String,

    @SerialName("english_title")
    val englishTitle: String,

    val description: String,
    val category: EventCategory = EventCategory.DOMESTIC,
    val type: EventType = EventType.POLITICAL,
    val severity: Int = 2,
    val effects: List<EventEffect> = emptyList(),
    val choices: List<EventChoice>? = null
) {
    /**
     * 是否有選項可供選擇
     */
    val hasChoices: Boolean
        get() = !choices.isNullOrEmpty()

    /**
     * 獲取嚴重程度描述
     */
    fun getSeverityText(): String {
        return when (severity) {
            1 -> "輕微"
            2 -> "中等"
            3 -> "嚴重"
            4 -> "危機"
            5 -> "災難"
            else -> "未知"
        }
    }

    /**
     * 獲取嚴重程度顏色
     */
    fun getSeverityColor(): Color {
        return when (severity) {
            1 -> Success
            2 -> GoldMuted
            3 -> Warning
            4 -> VictorianRed
            5 -> Error
            else -> TextMuted
        }
    }
}

// ============================================
// 預定義事件資料庫
// ============================================

object EventRepository {

    // MARK: - 國內事件

    val ludditeRiot = GameEventData(
        id = "luddite_riot",
        title = "盧德派暴動",
        englishTitle = "Luddite Riot",
        description = "諾丁漢郡的織工們砸毀了三家工廠的紡織機器，造成重大財產損失。地方治安官請求國會派遣軍隊鎮壓。",
        category = EventCategory.DOMESTIC,
        type = EventType.SOCIAL,
        severity = 4,
        effects = listOf(
            EventEffect(targetRole = "luddite", supportChange = 10, reputationChange = -5),
            EventEffect(targetRole = "factory", supportChange = -10, reputationChange = 5),
            EventEffect(targetRole = "worker", supportChange = 5)
        ),
        choices = listOf(
            EventChoice(
                id = "suppress",
                title = "嚴厲鎮壓",
                description = "派遣軍隊維持秩序，逮捕暴動者",
                effects = listOf(
                    EventEffect(targetRole = "factory", supportChange = 15),
                    EventEffect(targetRole = "worker", supportChange = -20),
                    EventEffect(targetRole = "luddite", supportChange = -25)
                )
            ),
            EventChoice(
                id = "negotiate",
                title = "嘗試談判",
                description = "派遣調解人了解工人訴求",
                effects = listOf(
                    EventEffect(targetRole = "worker", supportChange = 10),
                    EventEffect(targetRole = "reformer", supportChange = 15),
                    EventEffect(targetRole = "factory", supportChange = -10)
                )
            )
        )
    )

    val factoryFire = GameEventData(
        id = "factory_fire",
        title = "工廠大火",
        englishTitle = "Factory Fire",
        description = "曼徹斯特一家大型紡織廠發生火災，12名工人喪生，其中包括3名童工。社會輿論嘩然，要求改善工廠安全。",
        category = EventCategory.DOMESTIC,
        type = EventType.DISASTER,
        severity = 5,
        effects = listOf(
            EventEffect(targetRole = "factory", reputationChange = -15),
            EventEffect(targetRole = "worker", supportChange = 15),
            EventEffect(targetRole = "reformer", supportChange = 10)
        )
    )

    val royalVisit = GameEventData(
        id = "royal_visit",
        title = "皇室視察",
        englishTitle = "Royal Visit",
        description = "攝政王殿下宣布將親自視察北方工業城鎮，了解機器化的進展與工人的生活狀況。",
        category = EventCategory.DOMESTIC,
        type = EventType.POLITICAL,
        severity = 2,
        effects = listOf(
            EventEffect(targetRole = "mp", reputationChange = 5),
            EventEffect(targetRole = "factory", reputationChange = 10)
        ),
        choices = listOf(
            EventChoice(
                id = "showcase_progress",
                title = "展示工業成就",
                description = "安排參觀最先進的工廠",
                effects = listOf(
                    EventEffect(targetRole = "factory", supportChange = 20, reputationChange = 10)
                )
            ),
            EventChoice(
                id = "show_hardship",
                title = "揭示工人困境",
                description = "讓殿下看見工人的真實生活",
                effects = listOf(
                    EventEffect(targetRole = "worker", supportChange = 15),
                    EventEffect(targetRole = "reformer", supportChange = 15),
                    EventEffect(targetRole = "factory", supportChange = -10)
                )
            )
        )
    )

    val grainShortage = GameEventData(
        id = "grain_shortage",
        title = "糧食短缺",
        englishTitle = "Grain Shortage",
        description = "連續的惡劣天氣導致今年糧食歉收，麵包價格飆升。城市貧民區開始出現饑荒跡象。",
        category = EventCategory.DOMESTIC,
        type = EventType.ECONOMIC,
        severity = 4,
        effects = listOf(
            EventEffect(targetRole = "worker", supportChange = -10),
            EventEffect(targetRole = "factory", reputationChange = -5)
        ),
        choices = listOf(
            EventChoice(
                id = "import_grain",
                title = "進口糧食",
                description = "動用國庫購買外國糧食",
                effects = listOf(
                    EventEffect(targetRole = "worker", supportChange = 10),
                    EventEffect(targetRole = "mp", reputationChange = 5)
                )
            ),
            EventChoice(
                id = "price_control",
                title = "價格管制",
                description = "限制糧食價格上限",
                effects = listOf(
                    EventEffect(targetRole = "worker", supportChange = 15),
                    EventEffect(targetRole = "factory", supportChange = -15)
                )
            )
        )
    )

    val churchSermon = GameEventData(
        id = "church_sermon",
        title = "教會佈道",
        englishTitle = "Church Sermon",
        description = "坎特伯雷大主教發表講道，呼籲社會各階層和平共處，譴責暴力行為，但也批評工廠主過度剝削工人。",
        category = EventCategory.DOMESTIC,
        type = EventType.RELIGIOUS,
        severity = 2,
        effects = listOf(
            EventEffect(targetRole = "luddite", supportChange = -5),
            EventEffect(targetRole = "factory", supportChange = -5),
            EventEffect(targetRole = "reformer", supportChange = 10)
        )
    )

    val militiaFormation = GameEventData(
        id = "militia_formation",
        title = "民兵組建",
        englishTitle = "Militia Formation",
        description = "北方多郡開始組建民兵隊伍，以應對日益頻繁的工人騷亂。工廠主們紛紛捐款支持。",
        category = EventCategory.DOMESTIC,
        type = EventType.MILITARY,
        severity = 3,
        effects = listOf(
            EventEffect(targetRole = "factory", supportChange = 10),
            EventEffect(targetRole = "luddite", supportChange = -15),
            EventEffect(targetRole = "worker", supportChange = -10)
        )
    )

    val reformPetition = GameEventData(
        id = "reform_petition",
        title = "改革請願",
        englishTitle = "Reform Petition",
        description = "來自全國各地的改革派人士聯名向國會遞交請願書，要求改善工人待遇並規範工廠作業條件。",
        category = EventCategory.DOMESTIC,
        type = EventType.POLITICAL,
        severity = 2,
        effects = listOf(
            EventEffect(targetRole = "reformer", supportChange = 15, reputationChange = 10),
            EventEffect(targetRole = "worker", supportChange = 10)
        )
    )

    val childLaborScandal = GameEventData(
        id = "child_labor_scandal",
        title = "童工醜聞",
        englishTitle = "Child Labor Scandal",
        description = "《泰晤士報》刊登了一篇調查報導，揭露了某些工廠使用年僅六歲的童工，每天工作十四小時的慘況。",
        category = EventCategory.DOMESTIC,
        type = EventType.SOCIAL,
        severity = 4,
        effects = listOf(
            EventEffect(targetRole = "factory", reputationChange = -20),
            EventEffect(targetRole = "reformer", supportChange = 20),
            EventEffect(targetRole = "worker", supportChange = 10)
        )
    )

    val inventorBreakthrough = GameEventData(
        id = "inventor_breakthrough",
        title = "發明家突破",
        englishTitle = "Inventor Breakthrough",
        description = "一位天才發明家展示了改良版的動力織布機，效率提高三倍。這可能會讓更多工人失業，但也能大幅降低布料價格。",
        category = EventCategory.DOMESTIC,
        type = EventType.ECONOMIC,
        severity = 3,
        effects = listOf(
            EventEffect(targetRole = "factory", supportChange = 15),
            EventEffect(targetRole = "worker", supportChange = -10),
            EventEffect(targetRole = "luddite", supportChange = -15)
        ),
        choices = listOf(
            EventChoice(
                id = "embrace_innovation",
                title = "擁抱創新",
                description = "資助發明家推廣新機器",
                effects = listOf(
                    EventEffect(targetRole = "factory", supportChange = 25),
                    EventEffect(targetRole = "worker", supportChange = -20)
                )
            ),
            EventChoice(
                id = "delay_adoption",
                title = "延緩採用",
                description = "設立過渡期保護現有工人",
                effects = listOf(
                    EventEffect(targetRole = "worker", supportChange = 10),
                    EventEffect(targetRole = "reformer", supportChange = 10),
                    EventEffect(targetRole = "factory", supportChange = -10)
                )
            )
        )
    )

    val kingIllness = GameEventData(
        id = "king_illness",
        title = "國王病況",
        englishTitle = "King's Illness",
        description = "喬治三世的精神狀況再度惡化，攝政王的權力將進一步擴大。宮廷派系開始重新洗牌。",
        category = EventCategory.DOMESTIC,
        type = EventType.SPECIAL,
        severity = 3,
        effects = listOf(
            EventEffect(targetRole = "mp", reputationChange = 5),
            EventEffect(condition = "royal_faction", supportChange = -10)
        )
    )

    // MARK: - 國際事件

    val napoleonicThreat = GameEventData(
        id = "napoleonic_threat",
        title = "拿破崙威脅",
        englishTitle = "Napoleonic Threat",
        description = "拿破崙的大軍在歐洲大陸節節勝利，法國海軍開始在英吉利海峽活動。國防開支可能需要大幅增加。",
        category = EventCategory.INTERNATIONAL,
        type = EventType.WAR,
        severity = 5,
        effects = listOf(
            EventEffect(targetRole = "mp", supportChange = 10),
            EventEffect(targetRole = "factory", supportChange = 5)
        ),
        choices = listOf(
            EventChoice(
                id = "increase_military",
                title = "擴軍備戰",
                description = "增加軍事預算，加強海軍",
                effects = listOf(
                    EventEffect(targetRole = "mp", supportChange = 15),
                    EventEffect(targetRole = "worker", supportChange = -10)
                )
            ),
            EventChoice(
                id = "seek_peace",
                title = "尋求和平",
                description = "派遣使節嘗試談判",
                effects = listOf(
                    EventEffect(targetRole = "reformer", supportChange = 10),
                    EventEffect(targetRole = "mp", supportChange = -15)
                )
            )
        )
    )

    val americanTensions = GameEventData(
        id = "american_tensions",
        title = "美國緊張",
        englishTitle = "American Tensions",
        description = "英美關係持續惡化，美國商船遭到皇家海軍攔截搜查。戰爭陰雲籠罩大西洋。",
        category = EventCategory.INTERNATIONAL,
        type = EventType.DIPLOMACY,
        severity = 4,
        effects = listOf(
            EventEffect(targetRole = "factory", supportChange = -10),
            EventEffect(targetRole = "mp", supportChange = 5)
        )
    )

    val colonialRevolt = GameEventData(
        id = "colonial_revolt",
        title = "殖民地動亂",
        englishTitle = "Colonial Revolt",
        description = "印度殖民地傳來消息，當地王公對東印度公司的統治越來越不滿。需要派遣更多軍隊維持秩序。",
        category = EventCategory.INTERNATIONAL,
        type = EventType.COLONY,
        severity = 3,
        effects = listOf(
            EventEffect(targetRole = "mp", supportChange = -5),
            EventEffect(targetRole = "factory", supportChange = 5)
        )
    )

    val continentalBlockade = GameEventData(
        id = "continental_blockade",
        title = "大陸封鎖",
        englishTitle = "Continental Blockade",
        description = "拿破崙的大陸封鎖政策讓英國商品無法進入歐洲市場，貿易商們叫苦連天。",
        category = EventCategory.INTERNATIONAL,
        type = EventType.ECONOMIC,
        severity = 4,
        effects = listOf(
            EventEffect(targetRole = "factory", supportChange = -15),
            EventEffect(targetRole = "worker", supportChange = -10)
        )
    )

    val spanishAlliance = GameEventData(
        id = "spanish_alliance",
        title = "西班牙結盟",
        englishTitle = "Spanish Alliance",
        description = "西班牙抵抗運動向英國請求軍事援助，這是打破拿破崙霸權的絕佳機會。",
        category = EventCategory.INTERNATIONAL,
        type = EventType.DIPLOMACY,
        severity = 3,
        effects = listOf(
            EventEffect(targetRole = "mp", supportChange = 10, reputationChange = 5)
        ),
        choices = listOf(
            EventChoice(
                id = "send_troops",
                title = "派遣援軍",
                description = "支援威靈頓公爵的伊比利亞戰役",
                effects = listOf(
                    EventEffect(targetRole = "mp", supportChange = 20),
                    EventEffect(targetRole = "worker", supportChange = -5)
                )
            ),
            EventChoice(
                id = "limited_support",
                title = "有限支援",
                description = "只提供武器和資金",
                effects = listOf(
                    EventEffect(targetRole = "mp", supportChange = 5),
                    EventEffect(targetRole = "factory", supportChange = 10)
                )
            )
        )
    )

    // MARK: - 事件列表

    val domesticEvents: List<GameEventData> = listOf(
        ludditeRiot,
        factoryFire,
        royalVisit,
        grainShortage,
        churchSermon,
        militiaFormation,
        reformPetition,
        childLaborScandal,
        inventorBreakthrough,
        kingIllness
    )

    val internationalEvents: List<GameEventData> = listOf(
        napoleonicThreat,
        americanTensions,
        colonialRevolt,
        continentalBlockade,
        spanishAlliance
    )

    val allEvents: List<GameEventData> = domesticEvents + internationalEvents

    /**
     * 根據 ID 查找事件
     */
    fun getEventById(id: String): GameEventData? {
        return allEvents.find { it.id == id }
    }

    /**
     * 隨機獲取一個國內事件
     */
    fun getRandomDomesticEvent(): GameEventData {
        return domesticEvents.random()
    }

    /**
     * 隨機獲取一個國際事件
     */
    fun getRandomInternationalEvent(): GameEventData {
        return internationalEvents.random()
    }

    /**
     * 根據類型獲取事件
     */
    fun getEventsByType(type: EventType): List<GameEventData> {
        return allEvents.filter { it.type == type }
    }

    /**
     * 根據嚴重程度獲取事件
     */
    fun getEventsBySeverity(minSeverity: Int): List<GameEventData> {
        return allEvents.filter { it.severity >= minSeverity }
    }
}

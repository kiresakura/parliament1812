package com.parliament1812.data.models

import androidx.compose.ui.graphics.Color
import com.parliament1812.ui.theme.*

/**
 * 角色資料模型
 * Parliament 1812 - 所有角色的詳細資料定義
 */

// 角色能力資料類
data class RoleAbility(
    val name: String,
    val description: String,
    val icon: String
)

// 角色資料類
data class RoleData(
    val type: String,              // 角色類型 ID
    val nameZh: String,            // 中文名稱
    val nameEn: String,            // 英文名稱
    val characterName: String,     // 角色名字
    val age: Int,                  // 年齡
    val occupation: String,        // 職業
    val background: String,        // 背景故事
    val description: String,       // 簡短描述
    val quote: String,             // 角色名言
    val color: Color,              // 代表色
    val abilities: List<RoleAbility>,      // 角色能力
    val secretMissions: List<SecretMission>, // 秘密任務列表
    val stance: String,            // 立場傾向
    val allies: List<String>,      // 潛在盟友
    val enemies: List<String>      // 潛在敵人
)

/**
 * 所有角色資料
 */
object RoleDatabase {

    // ============================================
    // 紡織工人 - TEXTILE WORKER
    // ============================================
    val worker = RoleData(
        type = "worker",
        nameZh = "紡織工人",
        nameEn = "TEXTILE WORKER",
        characterName = "湯瑪斯·哈德卡索",
        age = 38,
        occupation = "約克郡紡織工人",
        background = """
            湯瑪斯出生於約克郡的一個紡織世家，從十二歲起便在家庭作坊中學習織布技藝。
            二十年來，他以精湛的手藝聞名鄉里，但新式蒸汽織布機的出現，
            讓他和無數同行的生計面臨前所未有的威脅。

            他的妻子瑪莉和三個孩子依靠他的收入生活。
            隨著工廠主大量引進機器，工資不斷下降，工作機會越來越少。
            湯瑪斯必須在國會殿堂為自己和千萬工人的未來發聲。
        """.trimIndent(),
        description = "你是一名紡織工人，機器的出現威脅著你的生計。你需要為工人的權益發聲。",
        quote = "機器或許能織布，但它不能養活我們的家庭。",
        color = WorkerColor,
        abilities = listOf(
            RoleAbility(
                name = "工人團結",
                description = "說服其他工人支持你的立場時，獲得額外說服力",
                icon = "I"
            ),
            RoleAbility(
                name = "基層智慧",
                description = "了解實際勞動情況，可以揭穿不切實際的政策",
                icon = "II"
            ),
            RoleAbility(
                name = "家庭負擔",
                description = "在討論民生議題時，你的發言更具感染力",
                icon = "III"
            )
        ),
        secretMissions = listOf(
            SecretMission(
                id = "worker_01",
                roleType = "worker",
                title = "私藏的發明圖紙",
                description = """
                    你的岳父是一位機械工程師，臨終前交給你一份改良織布機的圖紙。
                    如果這份圖紙被工廠主採用，你可以獲得專利費過上好日子——
                    但這將加速機器取代工人的進程。

                    你必須秘密決定：公開圖紙換取財富，還是銷毀它保護同胞？
                """.trimIndent(),
                successCondition = "在遊戲結束前，選擇公開或銷毀圖紙，並讓至少一名玩家知道你的選擇",
                points = 60
            ),
            SecretMission(
                id = "worker_02",
                roleType = "worker",
                title = "復仇的種子",
                description = """
                    三年前，工廠主理查·威爾森的工廠爆發瘟疫，你的弟弟就是因為惡劣的工作環境而死去。
                    威爾森從未承認責任，甚至沒有給予任何補償。

                    現在他就坐在國會議事廳裡，而你終於有機會讓他付出代價。
                    你必須在辯論中揭露他的罪行，讓他名譽掃地。
                """.trimIndent(),
                successCondition = "在公開辯論中指控工廠主威爾森，並得到至少兩名玩家的支持",
                points = 50
            ),
            SecretMission(
                id = "worker_03",
                roleType = "worker",
                title = "盧德派的臥底",
                description = """
                    你其實是盧德派運動的秘密成員。你們計劃在法案通過後發動一場破壞行動，
                    而你的任務是收集情報，了解哪些工廠會首先採用新機器。

                    但你開始動搖——暴力真的是唯一的出路嗎？
                    你必須決定是繼續臥底任務，還是在關鍵時刻背叛盧德派。
                """.trimIndent(),
                successCondition = "秘密與盧德派成員交換至少三條情報，或在最終投票前公開你的真實身份",
                points = 70
            ),
            SecretMission(
                id = "worker_04",
                roleType = "worker",
                title = "覺醒的改革者",
                description = """
                    一位來自城市的改革者曾在你的家鄉演講，他的話語在你心中種下了改革的種子。
                    你開始相信，或許透過教育和立法，工人可以與機器共存。

                    但這個想法會被你的同胞視為背叛。
                    你必須說服至少一名工人盟友支持折衷改革方案，同時不被視為叛徒。
                """.trimIndent(),
                successCondition = "成功說服一名工人或盧德派支持「折衷改革」選項",
                points = 55
            )
        ),
        stance = "傾向禁止機器 (選項A)",
        allies = listOf("luddite", "reformer"),
        enemies = listOf("factory_owner")
    )

    // ============================================
    // 工廠主 - FACTORY OWNER
    // ============================================
    val factoryOwner = RoleData(
        type = "factory_owner",
        nameZh = "工廠主",
        nameEn = "FACTORY OWNER",
        characterName = "理查·威爾森",
        age = 45,
        occupation = "曼徹斯特紡織廠主",
        background = """
            理查·威爾森是曼徹斯特最大的紡織廠主之一。
            他從一個小作坊起家，透過精明的商業頭腦和對新技術的敏銳嗅覺，
            在二十年間建立起一個紡織帝國。

            他相信機器代表著進步，是英國在歐洲競爭中保持優勢的關鍵。
            然而，工人的暴亂和盧德派的威脅讓他的工廠多次遭受破壞。
            他來到國會，希望爭取保護私有財產的法律。
        """.trimIndent(),
        description = "你是一名工廠主，機器能為你帶來更多利潤。但你也需要考慮社會穩定。",
        quote = "進步的車輪不會因為幾個懷舊者的眼淚而停止轉動。",
        color = FactoryColor,
        abilities = listOf(
            RoleAbility(
                name = "商業影響力",
                description = "可以用經濟利益說服議員支持你的立場",
                icon = "I"
            ),
            RoleAbility(
                name = "產業先驅",
                description = "在討論技術和經濟議題時，你的專業意見更有說服力",
                icon = "II"
            ),
            RoleAbility(
                name = "政商關係",
                description = "與某些議員有私下往來，可以獲得額外情報",
                icon = "III"
            )
        ),
        secretMissions = listOf(
            SecretMission(
                id = "factory_01",
                roleType = "factory_owner",
                title = "良心的拷問",
                description = """
                    你的工廠確實發生過工人傷亡事件，你用錢封住了受害者家屬的口。
                    但午夜夢迴時，那些面孔仍會出現在你的夢中。

                    如果通過「折衷改革」法案，你可以借機改善工廠環境，
                    洗清你的罪惡感——但這會大幅增加你的成本。
                """.trimIndent(),
                successCondition = "支持「折衷改革」選項，並在辯論中提出改善工人待遇的具體方案",
                points = 55
            ),
            SecretMission(
                id = "factory_02",
                roleType = "factory_owner",
                title = "商業競爭對手",
                description = """
                    你的最大競爭對手——伯明翰的湯普森工廠，正在秘密遊說議會禁止機器。
                    你知道他們這麼做是因為他們的機器技術落後，想藉此拖慢你的擴張。

                    你必須揭露他們的虛偽，讓議會看清這不過是一場商業競爭的陰謀。
                """.trimIndent(),
                successCondition = "在辯論中成功指出反機器陣營中存在的利益衝突",
                points = 50
            ),
            SecretMission(
                id = "factory_03",
                roleType = "factory_owner",
                title = "雙面人",
                description = """
                    你其實一直在暗中資助盧德派，希望利用他們破壞競爭對手的工廠。
                    但事情開始失控——盧德派的怒火已經無法被你控制，
                    你自己的工廠也成為了目標。

                    你必須在不暴露身份的情況下，阻止盧德派的行動。
                """.trimIndent(),
                successCondition = "秘密與盧德派成員達成停火協議，並確保你的身份不被其他玩家發現",
                points = 75
            ),
            SecretMission(
                id = "factory_04",
                roleType = "factory_owner",
                title = "工業革命的信徒",
                description = """
                    你真心相信機器是人類進步的象徵，而你願意分享這份進步的果實。
                    你計劃建立一所工人學校，讓工人的孩子學習讀寫和機械知識，
                    成為新時代的技術工人。

                    但這個計劃需要議會的支持和其他工廠主的認同。
                """.trimIndent(),
                successCondition = "在辯論中提出工人教育計劃，並得到至少三名玩家的公開支持",
                points = 60
            )
        ),
        stance = "傾向保護財產 (選項B)",
        allies = listOf("mp"),
        enemies = listOf("worker", "luddite")
    )

    // ============================================
    // 盧德派 - LUDDITE
    // ============================================
    val luddite = RoleData(
        type = "luddite",
        nameZh = "盧德派",
        nameEn = "LUDDITE",
        characterName = "「奈德王」喬治",
        age = 28,
        occupation = "盧德運動領袖",
        background = """
            沒有人知道喬治的真實姓氏，人們只知道他以傳說中的「奈德·盧德」之名領導著一群憤怒的工人。
            他曾是一名出色的剪裁師，但當機器奪走了他的工作，他選擇了戰鬥。

            在過去兩年裡，他帶領追隨者摧毀了數十台織布機，
            成為工廠主們聞風喪膽的名字。
            但他知道，暴力終究不是長久之計。
            這次來到國會，是他最後的賭注。
        """.trimIndent(),
        description = "你是盧德運動的成員，堅信機器會毀滅工人的生活。你願意採取激進行動。",
        quote = "如果法律不保護我們，那就讓錘子來說話！",
        color = LudditeColor,
        abilities = listOf(
            RoleAbility(
                name = "革命威望",
                description = "你的名聲讓其他激進分子願意聽從你的意見",
                icon = "I"
            ),
            RoleAbility(
                name = "地下網絡",
                description = "你可以獲得關於工廠動態的秘密情報",
                icon = "II"
            ),
            RoleAbility(
                name = "威嚇戰術",
                description = "可以用暴力威脅迫使某些人改變立場",
                icon = "III"
            )
        ),
        secretMissions = listOf(
            SecretMission(
                id = "luddite_01",
                roleType = "luddite",
                title = "背負的血債",
                description = """
                    在一次破壞行動中，一名無辜的守夜人被你的追隨者誤殺。
                    你從未告訴過任何人這件事，但死者的眼神一直縈繞在你心頭。

                    你開始懷疑這條道路是否正確。
                    你必須找到一種不流血的方式來保護工人權益。
                """.trimIndent(),
                successCondition = "在遊戲過程中放棄所有暴力威脅行動，並說服至少一名盧德派成員支持和平路線",
                points = 65
            ),
            SecretMission(
                id = "luddite_02",
                roleType = "luddite",
                title = "私人恩怨",
                description = """
                    工廠主威爾森正是害得你父親破產自殺的人。
                    五年前，威爾森用不正當手段收購了你父親的作坊，
                    讓你的家庭一夜之間失去一切。

                    你發誓要讓他付出代價——無論是在議事廳還是在黑暗的巷子裡。
                """.trimIndent(),
                successCondition = "成功讓威爾森在公眾面前名譽掃地，或私下獲得他的道歉",
                points = 50
            ),
            SecretMission(
                id = "luddite_03",
                roleType = "luddite",
                title = "政府的線人",
                description = """
                    你其實是政府派來的臥底。你的任務是打入盧德派內部，
                    收集成員名單和行動計劃，讓政府能夠一網打盡這些「暴徒」。

                    但在這段時間裡，你開始理解工人們的苦難。
                    你必須決定：完成任務，還是背叛政府？
                """.trimIndent(),
                successCondition = "在遊戲結束時，選擇向政府提交名單或公開你的臥底身份",
                points = 80
            ),
            SecretMission(
                id = "luddite_04",
                roleType = "luddite",
                title = "和平的曙光",
                description = """
                    一位改革派議員曾私下接觸你，提議如果你們放棄暴力，
                    他會在議會中為工人權益發聲。

                    你的追隨者不會輕易接受這個提議，但這可能是唯一的出路。
                    你必須說服你的同伴相信改革的可能性。
                """.trimIndent(),
                successCondition = "成功說服至少兩名工人或盧德派成員支持「折衷改革」選項",
                points = 60
            )
        ),
        stance = "傾向禁止機器 (選項A)",
        allies = listOf("worker"),
        enemies = listOf("factory_owner", "mp")
    )

    // ============================================
    // 改革者 - REFORMER
    // ============================================
    val reformer = RoleData(
        type = "reformer",
        nameZh = "改革者",
        nameEn = "REFORMER",
        characterName = "羅伯特·烏爾文",
        age = 35,
        occupation = "改革派思想家",
        background = """
            羅伯特·烏爾文曾是劍橋大學的政治學教授，但他認為象牙塔中的學術爭論無法真正改變世界。
            他離開大學，投身於社會改革運動，成為最具影響力的改革派思想家之一。

            他相信機器本身不是問題，問題在於不公正的社會制度。
            透過立法保護工人、普及教育、建立社會保障，
            機器可以成為解放人類的工具而非枷鎖。

            他來到國會，希望推動「折衷改革」法案。
        """.trimIndent(),
        description = "你是一名改革者，相信透過立法可以在進步與保護之間找到平衡。",
        quote = "我們不能阻止時代的車輪，但我們可以為它鋪設正確的軌道。",
        color = ReformerColor,
        abilities = listOf(
            RoleAbility(
                name = "雄辯之才",
                description = "你的演講能夠影響中立者的立場",
                icon = "I"
            ),
            RoleAbility(
                name = "法律專家",
                description = "可以提出具體的法案修正案",
                icon = "II"
            ),
            RoleAbility(
                name = "橋樑建設者",
                description = "可以促成不同陣營之間的對話和妥協",
                icon = "III"
            )
        ),
        secretMissions = listOf(
            SecretMission(
                id = "reformer_01",
                roleType = "reformer",
                title = "理想與現實",
                description = """
                    你的改革理論很美好，但你其實從未親眼見過工廠的真實情況。
                    一位工人邀請你去參觀他工作的地方，你所見到的景象遠比你想像的要殘酷。

                    這動搖了你對「漸進改革」的信心。
                    你開始考慮是否應該支持更激進的措施。
                """.trimIndent(),
                successCondition = "在辯論中引用你「親眼所見」的工廠現況，並因此修改你的立場",
                points = 50
            ),
            SecretMission(
                id = "reformer_02",
                roleType = "reformer",
                title = "背後的金主",
                description = """
                    你的改革運動一直由一位神秘的貴族資助。
                    最近你發現，這位貴族其實是工廠主威爾森的表親，
                    他資助你只是為了讓改革派分化工人陣營。

                    你必須決定是否切斷這層關係，即使這意味著你的運動將面臨資金困難。
                """.trimIndent(),
                successCondition = "在遊戲中公開你的資金來源，並拒絕繼續接受資助",
                points = 55
            ),
            SecretMission(
                id = "reformer_03",
                roleType = "reformer",
                title = "雙面下注",
                description = """
                    你其實與盧德派有秘密聯繫，你一直在為他們提供法律建議，
                    幫助他們規避政府的追捕。
                    你相信這是為了保護他們，同時也是為了在關鍵時刻能夠說服他們放下武器。

                    但如果這件事曝光，你的政治生涯就完了。
                """.trimIndent(),
                successCondition = "成功說服盧德派在最終投票前放棄暴力威脅，同時保守你協助他們的秘密",
                points = 70
            ),
            SecretMission(
                id = "reformer_04",
                roleType = "reformer",
                title = "未來的建築師",
                description = """
                    你有一個宏大的願景：建立一個工人、工廠主和政府三方合作的委員會，
                    共同制定產業政策。這需要所有利益相關者的支持。

                    你必須在這場辯論中展示這個願景的可行性，
                    並贏得不同陣營的認可。
                """.trimIndent(),
                successCondition = "讓至少各一名工人、工廠主和議員同意參與你提議的三方委員會",
                points = 65
            )
        ),
        stance = "傾向折衷改革 (選項C)",
        allies = listOf("worker", "mp"),
        enemies = listOf()
    )

    // ============================================
    // 議員 - MEMBER OF PARLIAMENT
    // ============================================
    val mp = RoleData(
        type = "mp",
        nameZh = "議員",
        nameEn = "MEMBER OF PARLIAMENT",
        characterName = "威廉·菲茨傑拉德爵士",
        age = 52,
        occupation = "下議院議員",
        background = """
            威廉·菲茨傑拉德是一位資深議員，在西敏寺服務超過二十年。
            他代表的選區包括工業城鎮和農村地區，這讓他的立場總是需要謹慎權衡。

            他親眼見證了工業革命帶來的繁榮與苦難，
            也深知任何決定都會影響成千上萬人的命運。
            作為議事程序的把關者，他手中握有規則的權力。
        """.trimIndent(),
        description = "你是一名國會議員，需要在各方利益之間權衡，做出最終決定。",
        quote = "我們在這裡不是為了滿足某一方，而是為了國家的未來。",
        color = MPColor,
        abilities = listOf(
            RoleAbility(
                name = "議事規則專家",
                description = "可以影響辯論的程序和規則",
                icon = "I"
            ),
            RoleAbility(
                name = "投票影響力",
                description = "你的投票對其他中立議員有示範效應",
                icon = "II"
            ),
            RoleAbility(
                name = "權力掮客",
                description = "可以在私下進行政治交易",
                icon = "III"
            )
        ),
        secretMissions = listOf(
            SecretMission(
                id = "mp_01",
                roleType = "mp",
                title = "選區的壓力",
                description = """
                    你的選區工廠主們聯合寫信要求你支持「保護財產」法案，
                    否則他們會在下次選舉中資助你的對手。

                    但你的良心告訴你，工人的苦難不能被忽視。
                    你必須找到一種方法既保住你的席位，又不違背良心。
                """.trimIndent(),
                successCondition = "找到一種投票方式既能滿足選區要求又能保護工人權益（如推動修正案）",
                points = 55
            ),
            SecretMission(
                id = "mp_02",
                roleType = "mp",
                title = "舊日的債務",
                description = """
                    多年前，你曾在一次政治危機中接受過盧德派的幫助——
                    他們幫你掩蓋了一樁醜聞。現在他們要求你償還這份人情。

                    如果你拒絕，他們可能會把你的秘密公之於眾。
                """.trimIndent(),
                successCondition = "在不完全順從盧德派要求的情況下，保守你的秘密",
                points = 60
            ),
            SecretMission(
                id = "mp_03",
                roleType = "mp",
                title = "王室的意志",
                description = """
                    你收到了來自王室的秘密信函，暗示國王喬治三世對這個議題有特定的看法。
                    雖然國王的精神狀態不穩定，但違背王室意願仍然是政治自殺。

                    你必須設法了解國王的真實態度，並決定是否遵從。
                """.trimIndent(),
                successCondition = "與喬治三世進行私下對話，並根據對話結果調整你的投票策略",
                points = 50
            ),
            SecretMission(
                id = "mp_04",
                roleType = "mp",
                title = "改革的推手",
                description = """
                    你私下相信改革是正確的道路，但作為資深議員，你需要維持中立的形象。
                    你計劃在幕後推動改革派的議程，同時不在公開場合表態。

                    但這種雙面作法能持續多久？
                """.trimIndent(),
                successCondition = "在私下協助改革派取得至少兩張額外的支持票",
                points = 65
            )
        ),
        stance = "中立，傾向折衷方案",
        allies = listOf("reformer", "factory_owner"),
        enemies = listOf()
    )

    // ============================================
    // 喬治三世 - KING GEORGE III
    // ============================================
    val georgeIII = RoleData(
        type = "george_iii",
        nameZh = "喬治三世",
        nameEn = "KING GEORGE III",
        characterName = "喬治·威廉·腓特烈",
        age = 74,
        occupation = "大不列顛及愛爾蘭聯合王國國王",
        background = """
            喬治三世是大英帝國的君主，在位已超過五十年。
            他曾是一位精力充沛的國王，但近年來精神疾病的發作讓他時而清醒時而糊塗。

            在他清醒的時刻，他仍然對國家事務有著深刻的見解。
            他經歷過美洲殖民地的失去，也見證了法國大革命的血腥，
            這讓他對「暴民」和「激進分子」有著深深的警惕。

            但同時，他也是一位關心臣民福祉的君主，
            曾親自視察農村、與農民交談。
        """.trimIndent(),
        description = "你是英國國王喬治三世，雖然精神狀態不穩定，但你的意見仍然舉足輕重。",
        quote = "我可能會失去美洲，但我不會失去英格蘭的心。",
        color = GeorgeIIIColor,
        abilities = listOf(
            RoleAbility(
                name = "王者威嚴",
                description = "你的發言自動獲得所有人的關注",
                icon = "I"
            ),
            RoleAbility(
                name = "皇室否決",
                description = "你可以要求重新考慮任何決議（限用一次）",
                icon = "II"
            ),
            RoleAbility(
                name = "精神波動",
                description = "你的精神狀態會影響辯論的走向",
                icon = "III"
            )
        ),
        secretMissions = listOf(
            SecretMission(
                id = "george_01",
                roleType = "george_iii",
                title = "清醒的時刻",
                description = """
                    在這場辯論中，你經歷著一個罕見的清醒期。
                    你意識到自己的精神疾病讓攝政王（你的兒子）越來越有權力，
                    這可能是你最後一次對國家大事發表意見的機會。

                    你必須做出一個能夠留下印記的決定。
                """.trimIndent(),
                successCondition = "在辯論中發表一個改變至少兩名玩家立場的演說",
                points = 60
            ),
            SecretMission(
                id = "george_02",
                roleType = "george_iii",
                title = "父親的責任",
                description = """
                    你的一個私生子（你從未公開承認的）正在工廠裡勞動。
                    你收到了他的信，描述了工人的悲慘處境。
                    這份血緣關係讓你開始重新思考機器問題。

                    你不能公開這層關係，但你想為他做些什麼。
                """.trimIndent(),
                successCondition = "推動一項保護工人的政策，同時不透露你的私人動機",
                points = 55
            ),
            SecretMission(
                id = "george_03",
                roleType = "george_iii",
                title = "王室的秘密",
                description = """
                    你其實秘密投資了幾家使用新機器的工廠，這是由你的財務顧問安排的。
                    如果這件事曝光，將會嚴重損害王室的形象。

                    你必須確保這個秘密不被發現，同時不能讓你的投票看起來有利益衝突。
                """.trimIndent(),
                successCondition = "保守你的投資秘密，並確保你的投票不被質疑",
                points = 70
            ),
            SecretMission(
                id = "george_04",
                roleType = "george_iii",
                title = "最後的遺產",
                description = """
                    你感覺到自己的清醒時刻越來越少。
                    你想為臣民留下一份禮物——一個能夠讓英國走向繁榮與和諧的決定。

                    你決定支持那個最能促進社會和解的方案，
                    無論它是否符合王室的傳統立場。
                """.trimIndent(),
                successCondition = "投票支持得到最多不同陣營支持的方案",
                points = 50
            )
        ),
        stance = "不可預測（受精神狀態影響）",
        allies = listOf(),
        enemies = listOf()
    )

    // 角色列表
    val allRoles = listOf(worker, factoryOwner, luddite, reformer, mp, georgeIII)

    // 根據類型獲取角色
    fun getRoleByType(type: String): RoleData? {
        return when (type.lowercase()) {
            "worker" -> worker
            "factory_owner", "factory" -> factoryOwner
            "luddite" -> luddite
            "reformer" -> reformer
            "mp" -> mp
            "george_iii", "king" -> georgeIII
            else -> null
        }
    }

    // 根據索引獲取秘密任務
    fun getSecretMission(roleType: String, missionIndex: Int): SecretMission? {
        val role = getRoleByType(roleType) ?: return null
        return role.secretMissions.getOrNull(missionIndex)
    }
}

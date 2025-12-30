# 1812 國會風雲 - Design Documentation
## Parliament Debates - Historical Accuracy & Design System

---

## 🎯 **Historical Context (1812 Britain)**

### **Time Period: Regency Era**
- **Monarch**: King George III (incapacitated by mental illness)
- **Regent**: Prince George (future George IV) ruling as Prince Regent
- **Global Context**: Napoleonic Wars ongoing, War of 1812 with United States
- **Domestic Issues**: Luddite riots, Catholic emancipation debates, economic hardship

---

## 👥 **Historically Accurate Characters (1812)**

### **TORY PARTY (Government - Conservative)**

#### **Spencer Perceval** - 首相 (Prime Minister)
- **Historical Role**: Prime Minister from 1809 until assassination on May 11, 1812
- **Political Stance**: Strongly anti-Catholic emancipation, supporter of established Church
- **Notable**: Only British PM to be assassinated (shot by John Bellingham)

#### **Lord Liverpool (Robert Jenkinson)** - 利物浦伯爵
- **Historical Role**: War & Colonial Secretary, becomes PM after Perceval's death
- **Political Stance**: Conservative, maintainer of wartime government
- **Notable**: Served as PM for 15 years (1812-1827), one of longest-serving PMs

#### **Lord Castlereagh** - 卡斯爾雷子爵
- **Historical Role**: Foreign Secretary and Leader of the House of Commons
- **Political Stance**: Focus on defeating Napoleon, architect of Congress of Vienna
- **Notable**: Robert Stewart, highly influential but deeply unpopular

#### **Lord Eldon** - 艾爾登勳爵
- **Historical Role**: Lord Chancellor (1807-1827)
- **Political Stance**: Ultra-conservative, opposed all reform
- **Notable**: John Scott, obstinate defender of status quo

#### **Nicholas Vansittart** - 范西塔特
- **Historical Role**: Chancellor of the Exchequer (from 1812)
- **Political Stance**: Managing wartime economy
- **Notable**: Competent but uncharismatic financial administrator

---

### **WHIG PARTY (Opposition - Liberal/Reform)**

#### **Earl Grey (Charles Grey)** - 格雷伯爵
- **Historical Role**: Whig opposition leader
- **Political Stance**: Supporter of parliamentary reform and Catholic emancipation
- **Notable**: Later PM (1830-1834), passed Great Reform Act of 1832; Earl Grey tea named after him

#### **Lord Holland** - 霍蘭勳爵
- **Historical Role**: Prominent Whig peer, nephew of Charles James Fox
- **Political Stance**: Religious tolerance, liberal causes
- **Notable**: Holland House was center of Whig political society

#### **Samuel Whitbread** - 塞繆爾·惠特布雷德
- **Historical Role**: Radical Whig MP, wealthy brewer
- **Political Stance**: Critic of war policy, advocate for social reform
- **Notable**: Strong supporter of abolition and workers' rights

#### **Henry Brougham** - 亨利·布魯厄姆
- **Historical Role**: Whig lawyer and reformer, brilliant orator
- **Political Stance**: Legal and educational reform
- **Notable**: Later became Lord Chancellor, founded University College London

#### **Lord Grenville** - 格倫維爾勳爵
- **Historical Role**: Former PM (1806-1807), crossed from Tory to Whig
- **Political Stance**: Moderate reformer, supporter of Catholic relief
- **Notable**: William Grenville, led the "Ministry of All the Talents"

---

## ❌ **Historical Corrections Made**

### **REMOVED: "Duke of Wellington"**
- **Why**: Arthur Wellesley was NOT a Duke in 1812!
- **Actual Status in 1812**: Viscount Wellington (created 1809) or General Wellesley
- **Context**: Fighting in Spain/Portugal (Peninsular War), not in Parliament
- **Became Duke**: Only elevated to Duke of Wellington in 1814 after victories

### **REMOVED: Other Anachronisms**
- Eliminated references to events/titles that didn't exist in 1812
- Ensured all characters were actually active in Parliament in 1812
- Verified political affiliations and roles

---

## 🎨 **Design System**

### **Color Palette**

#### **Primary Colors**
- `#1a1a2e` - Dark Navy Blue (PRIMARY BACKGROUND)
  - Used on ALL screens without exception
  - Evokes candlelit Parliament chambers
  - Creates mysterious, elegant atmosphere

- `#16213e` - Secondary Navy (CARD BACKGROUNDS)
  - Slightly lighter for visual hierarchy
  - Used for raised elements and cards

#### **Accent Colors**
- `#d4af37` - Antique Gold (PRIMARY ACCENT)
  - Buttons, borders, highlights
  - Represents wealth and power of aristocracy
  - Victorian brass and gilt aesthetic

- `#8b4513` - Saddle Brown (SECONDARY ACCENT)
  - Decorative elements
  - Leather and mahogany references

#### **Text Colors**
- `#f5e6d3` - Parchment Cream (PRIMARY TEXT)
  - High contrast against dark backgrounds
  - Evokes aged documents

- `#b8a07e` - Muted Gold (SECONDARY TEXT)
  - Subtitles and less important text

#### **Political Party Colors**
- `#1e3a5f` - Royal Blue (TORY PARTY)
  - Traditional Conservative blue
  - Represents establishment and monarchy

- `#cc7722` - Orange/Buff (WHIG PARTY)
  - Historical Whig party color
  - Orange from William of Orange connection
  - "Buff and Blue" were Whig colors

#### **Voting Colors**
- `#2d5a27` - Parliamentary Green (AYE/SUCCESS)
  - Green benches of House of Commons
  - Support/approval

- `#8b2500` - Deep Crimson (NAY/DANGER)
  - Red for opposition/rejection
  - Danger and warning

---

### **Typography**

#### **Font Families**
- **Primary**: Georgia, serif
  - Classic, readable serif font
  - Period-appropriate formal feeling
  - Excellent for long-form text

- **Secondary**: Times New Roman, serif
  - For dramatic headings
  - Traditional newspaper/document font

#### **Font Styling**
- **Headings**: Bold, letter-spacing 0.1-0.3em
- **Body**: Regular weight, line-height 1.5
- **Accent Text**: Small caps with wide letter-spacing
- **All text**: Subtle shadow for readability on dark backgrounds

---

### **UI Components**

#### **Buttons**
- **Primary (Gold)**:
  - Background: `#d4af37`
  - Text: `#1a1a2e`
  - Border radius: 8px
  - Gradient effect with shine animation

- **Secondary (Outline)**:
  - Border: `#d4af37` 2px
  - Text: `#d4af37`
  - Background: transparent
  - Hover: slight fill

- **Success (Green)**:
  - Background: `#2d5a27`
  - Text: `#f5e6d3`
  - For "Aye" votes

- **Danger (Red)**:
  - Background: `#8b2500`
  - Text: `#f5e6d3`
  - For "Nay" votes

#### **Input Fields**
- Background: `#16213e`
- Border: 1px solid `#d4af37`
- Text: `#f5e6d3`
- Placeholder: `#8b8b8b`
- Focus: 2px gold border glow

#### **Cards**
- Background: `rgba(22, 33, 62, 0.9)`
- Border: 1px solid `rgba(212, 175, 55, 0.3)`
- Border radius: 12px
- Box shadow: `0 4px 20px rgba(0, 0, 0, 0.5)`
- Gold corner flourishes

---

### **Decorative Elements**

#### **Victorian Ornaments**
- Corner flourishes in antique gold
- Divider lines with diamond accents
- Parchment texture overlays
- Crown and shield icons

#### **Visual Effects**
- Vignette on backgrounds
- Subtle grain texture
- Soft glow on gold elements
- Shadow depth on cards

---

## 📱 **Screen Layouts**

### **1. Home Screen (首頁)**
- Crown/crest icon at top
- Large "1812" title with ornate borders
- Parliament chamber background (20% opacity)
- Toggle buttons: Create Room / Join Room
- Nickname input (always visible)
- Room code input (conditional on Join mode)
- Atmospheric tagline about Regency era

### **2. Waiting Room (等候大廳)**
- Back button
- Room code display with copy function
- Player count indicator
- Scrollable player list:
  - Crown icon for host
  - Checkmark for ready players
  - Circle for waiting players
  - Character avatars
- "Start Game" button (host only, requires 5+ players)

### **3. Role Card Reveal (角色揭示)**
- Elegant card with gold borders
- Character portrait in ornate frame
- Party affiliation with correct color:
  - Tory: Royal blue accent
  - Whig: Orange/buff accent
- Character name (Chinese + English)
- Role description
- Secret objective in highlighted box
- List of known allies
- Hide/Show toggle button

### **4. Voting Screen (投票畫面)**
- Bill title and description in parchment card
- Countdown timer with progress bar
- Large voting buttons:
  - "贊成 AYE" (green)
  - "反對 NAY" (red)
- "棄權 ABSTAIN" option
- Vote results (shown after voting ends):
  - Bar chart with percentages
  - Final outcome

---

## 🌍 **Chinese Text Standards**

### **Traditional Chinese (繁體中文)**
- App Name: **國會風雲** (NOT 議會辯論遊戲)
- All UI uses Traditional Chinese
- English subtitles below for accessibility

### **Key Terms**
| English | 中文 |
|---------|------|
| Create Room | 建立房間 |
| Join Room | 加入房間 |
| Nickname | 您的暱稱 |
| Room Code | 房間代碼 |
| Waiting Room | 等候大廳 |
| Start Game | 開始遊戲 |
| Your Role | 您的身份 |
| Objective | 您的目標 |
| Allies | 已知盟友 |
| Vote | 議案表決 |
| Aye | 贊成 |
| Nay | 反對 |
| Abstain | 棄權 |
| Debate | 議會辯論 |
| Members Present | 在場成員 |
| Host | 主持 |

---

## 🎭 **Atmosphere & Mood**

### **Visual Inspiration**
- British House of Commons/Lords historical paintings
- Regency era portraiture (Thomas Lawrence, John Hoppner)
- Victorian gothic decorative elements
- Antique gold and mahogany aesthetics
- Parchment and wax seal textures

### **Emotional Tone**
- **Mysterious**: Dark lighting, secrets, political intrigue
- **Elegant**: Refined typography, ornate borders
- **Historical**: Period-accurate characters and context
- **Intimate**: Candlelit chamber feeling
- **Tense**: Political stakes, competing factions

### **Cultural References**
- "Order, order in the House!" (Speaker's call)
- Parliamentary green benches
- Wax seals on official documents
- Crown and royal symbolism
- Georgian architectural elements

---

## 🔍 **Accessibility Considerations**

- High contrast text on dark backgrounds
- All text has subtle shadow for readability
- Focus states clearly visible (gold outline)
- Large touch targets (minimum 44px)
- English subtitles for all Chinese text
- Clear visual hierarchy
- Readable font sizes (minimum 12px)

---

## 📚 **Historical Sources**

This design was informed by:
- British parliamentary records from 1812
- Regency era historical accounts
- Period portraits and architectural records
- Political history of Tory/Whig parties
- Contemporary documents and newspapers

**Note**: While historically grounded, this is a game. Some creative liberties were taken for gameplay purposes while maintaining historical authenticity in character selection and political context.

---

## 🎮 **Game Design Philosophy**

**"Bring history to life through elegant design and authentic period detail"**

The interface should transport players to a gaslit 1812 Parliament chamber, where political intrigue and eloquent debate decide the fate of the British Empire. Every visual element reinforces the historical setting while maintaining modern usability standards.

---

*Last Updated: 2025*
*Game: 1812 國會風雲 (Parliament Debates)*

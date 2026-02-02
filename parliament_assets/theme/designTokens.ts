// Parliament 1812 — Design Tokens
// 設計規範：羅塞蒂 | 2025-01-31

// ═══════════════════════════════════════════════════════════
// 色彩系統
// ═══════════════════════════════════════════════════════════

export const colors = {
  // 基礎色
  background: {
    primary: '#1A1614',    // 深褐木紋
    secondary: '#241B14',  // 卡片背景
    alt: '#1A1A2E',        // 深藍黑（夜場景）
    overlay: 'rgba(26, 22, 20, 0.95)',
  },

  // 強調色
  accent: {
    gold: '#D4AF37',       // 主強調金
    goldMuted: '#B8941F',  // 暗金（漸層用）
    copper: '#8B6914',     // 銅金
  },

  // 文字色
  text: {
    primary: '#F5E6D3',    // 羊皮紙白
    secondary: '#B8A07E',  // 褐灰
    muted: '#8B7753',      // 暗褐
    inverse: '#1A1614',    // 反色（用於金色按鈕）
  },

  // 功能色
  semantic: {
    success: '#2D5A27',    // 深林綠（AYE）
    successLight: '#3D7A37',
    danger: '#8B2500',     // 深紅（NAY）
    dangerLight: '#A33510',
    warning: '#CC7722',    // 琥珀橙
    info: '#1E3A5F',       // 深藍
  },

  // 派系色
  faction: {
    labour: {
      primary: '#8B2500',   // 勞工派 - 深紅
      secondary: '#6E1E00',
      accent: '#A33510',
    },
    capital: {
      primary: '#D4AF37',   // 資方派 - 金色
      secondary: '#8B6914',
      accent: '#E8C547',
    },
    reform: {
      primary: '#2D5A27',   // 改革派 - 翡翠綠
      secondary: '#1E3D1A',
      accent: '#3D7A37',
    },
    royal: {
      primary: '#4A2882',   // 皇室派 - 皇家紫
      secondary: '#2E1A52',
      accent: '#6A38A2',
    },
    neutral: {
      primary: '#8B7753',   // 中立派 - 灰褐
      secondary: '#5C4A33',
      accent: '#A89068',
    },
  },

  // 稀有度色
  rarity: {
    normal: '#9E9E9E',     // N - 灰色
    rare: '#5C8BAF',       // R - 銅藍
    epic: '#8B6AA8',       // SR - 紫銅
    legendary: '#D4AF37',  // SSR - 金色
  },

  // 卡牌類型色
  cardType: {
    attack: '#E74C3C',     // 攻擊 - 紅
    defense: '#3498DB',    // 防禦 - 藍
    control: '#9B59B6',    // 控制 - 紫
    buff: '#27AE60',       // 增益 - 綠
    intel: '#00BCD4',      // 情報 - 青
    heal: '#2ECC71',       // 治療 - 淺綠
    social: '#E67E22',     // 社交 - 橙
    special: '#F1C40F',    // 特殊 - 金
  },
} as const;

// ═══════════════════════════════════════════════════════════
// 字體系統
// ═══════════════════════════════════════════════════════════

export const typography = {
  fontFamily: {
    primary: '"Georgia", "Times New Roman", serif',
    display: '"Playfair Display", Georgia, serif',
    mono: '"Courier New", monospace',
  },

  fontSize: {
    xs: '0.75rem',    // 12px
    sm: '0.875rem',   // 14px
    base: '1rem',     // 16px
    lg: '1.125rem',   // 18px
    xl: '1.25rem',    // 20px
    '2xl': '1.5rem',  // 24px
    '3xl': '2rem',    // 32px
    '4xl': '2.5rem',  // 40px
    '5xl': '3rem',    // 48px
    '6xl': '4rem',    // 64px
  },

  fontWeight: {
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
  },

  letterSpacing: {
    tight: '-0.025em',
    normal: '0',
    wide: '0.05em',
    wider: '0.1em',
    widest: '0.2em',
  },

  lineHeight: {
    tight: '1.2',
    normal: '1.5',
    relaxed: '1.75',
  },
} as const;

// ═══════════════════════════════════════════════════════════
// 間距系統
// ═══════════════════════════════════════════════════════════

export const spacing = {
  px: '1px',
  0: '0',
  0.5: '0.125rem',  // 2px
  1: '0.25rem',     // 4px
  2: '0.5rem',      // 8px
  3: '0.75rem',     // 12px
  4: '1rem',        // 16px
  5: '1.25rem',     // 20px
  6: '1.5rem',      // 24px
  8: '2rem',        // 32px
  10: '2.5rem',     // 40px
  12: '3rem',       // 48px
  16: '4rem',       // 64px
  20: '5rem',       // 80px
} as const;

// ═══════════════════════════════════════════════════════════
// 圓角系統
// ═══════════════════════════════════════════════════════════

export const borderRadius = {
  none: '0',
  sm: '0.25rem',    // 4px
  base: '0.5rem',   // 8px
  md: '0.75rem',    // 12px
  lg: '1rem',       // 16px
  xl: '1.5rem',     // 24px
  full: '9999px',
} as const;

// ═══════════════════════════════════════════════════════════
// 陰影系統
// ═══════════════════════════════════════════════════════════

export const shadows = {
  sm: '0 1px 2px rgba(0, 0, 0, 0.3)',
  base: '0 2px 4px rgba(0, 0, 0, 0.4)',
  md: '0 4px 8px rgba(0, 0, 0, 0.5)',
  lg: '0 8px 16px rgba(0, 0, 0, 0.6)',
  xl: '0 12px 24px rgba(0, 0, 0, 0.7)',
  
  // 特殊陰影
  gold: '0 0 20px rgba(212, 175, 55, 0.4)',
  goldIntense: '0 0 30px rgba(212, 175, 55, 0.6)',
  danger: '0 0 15px rgba(139, 37, 0, 0.4)',
  success: '0 0 15px rgba(45, 90, 39, 0.4)',
  
  // 內陰影
  inset: 'inset 0 2px 4px rgba(0, 0, 0, 0.3)',
  insetDeep: 'inset 0 4px 8px rgba(0, 0, 0, 0.5)',
} as const;

// ═══════════════════════════════════════════════════════════
// 動畫系統
// ═══════════════════════════════════════════════════════════

export const animation = {
  duration: {
    fast: '150ms',
    base: '300ms',
    slow: '500ms',
    slower: '800ms',
  },

  easing: {
    default: 'cubic-bezier(0.4, 0, 0.2, 1)',
    in: 'cubic-bezier(0.4, 0, 1, 1)',
    out: 'cubic-bezier(0, 0, 0.2, 1)',
    inOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
    bounce: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
  },
} as const;

// ═══════════════════════════════════════════════════════════
// 元件尺寸
// ═══════════════════════════════════════════════════════════

export const componentSizes = {
  // 卡牌尺寸
  card: {
    width: 300,
    height: 420,
    aspectRatio: '5 / 7',
  },
  
  // 角色卡片
  characterCard: {
    width: 280,
    height: 400,
  },
  
  // 頭像尺寸
  avatar: {
    sm: 32,
    md: 48,
    lg: 64,
    xl: 96,
  },
  
  // 按鈕高度
  button: {
    sm: 32,
    md: 44,
    lg: 56,
  },
  
  // 六邊形徽章
  hexBadge: {
    sm: 40,
    md: 64,
    lg: 96,
  },
} as const;

// ═══════════════════════════════════════════════════════════
// 派系配置
// ═══════════════════════════════════════════════════════════

export type FactionId = 'labour' | 'capital' | 'reform' | 'royal' | 'neutral';

export interface FactionConfig {
  id: FactionId;
  nameChinese: string;
  nameEnglish: string;
  icon: string;
  colors: typeof colors.faction.labour;
}

export const factions: Record<FactionId, FactionConfig> = {
  labour: {
    id: 'labour',
    nameChinese: '勞工派',
    nameEnglish: 'Labour',
    icon: '⚒️',
    colors: colors.faction.labour,
  },
  capital: {
    id: 'capital',
    nameChinese: '資方派',
    nameEnglish: 'Capital',
    icon: '💰',
    colors: colors.faction.capital,
  },
  reform: {
    id: 'reform',
    nameChinese: '改革派',
    nameEnglish: 'Reform',
    icon: '📜',
    colors: colors.faction.reform,
  },
  royal: {
    id: 'royal',
    nameChinese: '皇室派',
    nameEnglish: 'Royal',
    icon: '👑',
    colors: colors.faction.royal,
  },
  neutral: {
    id: 'neutral',
    nameChinese: '中立派',
    nameEnglish: 'Neutral',
    icon: '📰',
    colors: colors.faction.neutral,
  },
} as const;

// ═══════════════════════════════════════════════════════════
// 角色配置
// ═══════════════════════════════════════════════════════════

export interface CharacterConfig {
  id: string;
  nameChinese: string;
  nameEnglish: string;
  title: string;
  faction: FactionId;
  icon: string;
  /** 角色立繪圖片路徑 */
  image?: string;
  stats: {
    reputation: number;
    influence: number;
    gold: number;
  };
}

export const characters: Record<string, CharacterConfig> = {
  thomas: {
    id: 'thomas',
    nameChinese: '工人湯瑪斯',
    nameEnglish: 'Thomas the Worker',
    title: '勞工派核心',
    faction: 'labour',
    icon: '🔨',
    image: '/images/characters/thomas_worker.png',
    stats: { reputation: 70, influence: 10, gold: 20 },
  },
  richard: {
    id: 'richard',
    nameChinese: '工廠主理查',
    nameEnglish: 'Richard the Factory Owner',
    title: '資方派核心',
    faction: 'capital',
    icon: '💰',
    image: '/images/characters/richard_factory.png',
    stats: { reputation: 60, influence: 10, gold: 100 },
  },
  edward: {
    id: 'edward',
    nameChinese: '記者愛德華',
    nameEnglish: 'Edward the Journalist',
    title: '輿論操控者',
    faction: 'neutral',
    icon: '📰',
    image: '/images/characters/edward_journalist.png',
    stats: { reputation: 50, influence: 10, gold: 30 },
  },
  george: {
    id: 'george',
    nameChinese: '盧德派喬治',
    nameEnglish: 'George the Luddite',
    title: '機器破壞者',
    faction: 'labour',
    icon: '🔥',
    image: '/images/characters/george_luddite.png',
    stats: { reputation: 80, influence: 10, gold: 10 },
  },
  royal_elder: {
    id: 'royal_elder',
    nameChinese: '皇室長老',
    nameEnglish: 'Royal Elder',
    title: '皇室派核心',
    faction: 'royal',
    icon: '👑',
    image: '/images/characters/royal_elder.png',
    stats: { reputation: 65, influence: 12, gold: 80 },
  },
} as const;

// ═══════════════════════════════════════════════════════════
// Tailwind 相容 CSS 變數
// ═══════════════════════════════════════════════════════════

export const cssVariables = `
:root {
  /* 基礎色 */
  --color-bg-primary: ${colors.background.primary};
  --color-bg-secondary: ${colors.background.secondary};
  --color-bg-alt: ${colors.background.alt};
  
  /* 強調色 */
  --color-accent: ${colors.accent.gold};
  --color-accent-muted: ${colors.accent.goldMuted};
  
  /* 文字色 */
  --color-text-primary: ${colors.text.primary};
  --color-text-secondary: ${colors.text.secondary};
  --color-text-muted: ${colors.text.muted};
  
  /* 功能色 */
  --color-success: ${colors.semantic.success};
  --color-danger: ${colors.semantic.danger};
  --color-warning: ${colors.semantic.warning};
  
  /* 字體 */
  --font-primary: ${typography.fontFamily.primary};
  --font-display: ${typography.fontFamily.display};
}
`;

export default {
  colors,
  typography,
  spacing,
  borderRadius,
  shadows,
  animation,
  componentSizes,
  factions,
  characters,
};

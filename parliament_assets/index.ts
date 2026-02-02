// Parliament 1812 — 設計系統導出
// 設計：羅塞蒂 | 2025-01-31

// ═══════════════════════════════════════════════════════════
// 設計規範
// ═══════════════════════════════════════════════════════════

export * from './theme/designTokens';

// ═══════════════════════════════════════════════════════════
// UI 元件
// ═══════════════════════════════════════════════════════════

// 基礎裝飾元件
export * from './components/VictorianOrnament';
export * from './components/HexagonPattern';

// 角色相關
export { 
  CharacterCard, 
  CharacterSelectGrid, 
  MiniCharacterCard,
} from './components/CharacterCard';

// 遊戲卡牌
export { 
  GameCard, 
  HandDisplay, 
  CardDetailModal,
  type GameCardData,
  type CardType,
  type CardRarity,
} from './components/GameCard';

// 資源面板
export { 
  ResourcePanel, 
  MiniResourceBar, 
  GameStatusBar,
} from './components/ResourcePanel';

// 頁面元件
export { CharacterShowcase } from './components/CharacterShowcase';

// 遊戲畫面（原有）
export { HomeScreen1812 } from './components/HomeScreen1812';
export { RoleCardReveal1812 } from './components/RoleCardReveal1812';
export { VotingScreen1812 } from './components/VotingScreen1812';
export { WaitingRoom1812 } from './components/WaitingRoom1812';

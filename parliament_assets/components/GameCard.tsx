// Parliament 1812 — 遊戲卡牌元件
// 設計：羅塞蒂 | 2025-01-31

import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { 
  Swords, Shield, Lock, TrendingUp, Search, Heart, 
  Handshake, Star, Coins 
} from 'lucide-react';
import { colors, typography, shadows } from '../theme/designTokens';
import { ParchmentTexture } from './VictorianOrnament';

// ═══════════════════════════════════════════════════════════
// 類型定義
// ═══════════════════════════════════════════════════════════

export type CardType = 
  | 'attack' 
  | 'defense' 
  | 'control' 
  | 'buff' 
  | 'intel' 
  | 'heal' 
  | 'social' 
  | 'special';

export type CardRarity = 'normal' | 'rare' | 'epic' | 'legendary';

export interface GameCardData {
  id: string;
  nameChinese: string;
  nameEnglish: string;
  type: CardType;
  rarity: CardRarity;
  cost: {
    influence?: number;
    gold?: number;
  };
  effect: string;
  /** 是否為角色專屬卡 */
  isExclusive?: boolean;
  /** 專屬角色 ID */
  exclusiveCharacter?: string;
}

interface GameCardProps {
  card: GameCardData;
  /** 是否可選擇 */
  selectable?: boolean;
  /** 是否選中 */
  selected?: boolean;
  /** 是否禁用（資源不足） */
  disabled?: boolean;
  /** 是否隱藏（卡背） */
  hidden?: boolean;
  /** 尺寸 */
  size?: 'sm' | 'md' | 'lg';
  /** 點擊回調 */
  onClick?: () => void;
  /** 懸停回調 */
  onHover?: (isHovering: boolean) => void;
}

// ═══════════════════════════════════════════════════════════
// 卡牌配置
// ═══════════════════════════════════════════════════════════

const cardTypeConfig: Record<CardType, { 
  icon: typeof Swords; 
  color: string; 
  label: string;
  labelEn: string;
}> = {
  attack: { icon: Swords, color: colors.cardType.attack, label: '攻擊', labelEn: 'Attack' },
  defense: { icon: Shield, color: colors.cardType.defense, label: '防禦', labelEn: 'Defense' },
  control: { icon: Lock, color: colors.cardType.control, label: '控制', labelEn: 'Control' },
  buff: { icon: TrendingUp, color: colors.cardType.buff, label: '增益', labelEn: 'Buff' },
  intel: { icon: Search, color: colors.cardType.intel, label: '情報', labelEn: 'Intel' },
  heal: { icon: Heart, color: colors.cardType.heal, label: '治療', labelEn: 'Heal' },
  social: { icon: Handshake, color: colors.cardType.social, label: '社交', labelEn: 'Social' },
  special: { icon: Star, color: colors.cardType.special, label: '特殊', labelEn: 'Special' },
};

const rarityConfig: Record<CardRarity, {
  borderColor: string;
  glowColor: string;
  label: string;
  labelEn: string;
  icon: string;
}> = {
  normal: { 
    borderColor: colors.rarity.normal, 
    glowColor: 'transparent',
    label: '普通', 
    labelEn: 'N',
    icon: '⚪',
  },
  rare: { 
    borderColor: colors.rarity.rare, 
    glowColor: `${colors.rarity.rare}40`,
    label: '稀有', 
    labelEn: 'R',
    icon: '🔵',
  },
  epic: { 
    borderColor: colors.rarity.epic, 
    glowColor: `${colors.rarity.epic}40`,
    label: '史詩', 
    labelEn: 'SR',
    icon: '🟣',
  },
  legendary: { 
    borderColor: colors.rarity.legendary, 
    glowColor: `${colors.rarity.legendary}50`,
    label: '傳說', 
    labelEn: 'SSR',
    icon: '🟡',
  },
};

// ═══════════════════════════════════════════════════════════
// 卡牌尺寸配置
// ═══════════════════════════════════════════════════════════

const sizeConfig = {
  sm: { 
    width: 150, 
    height: 210, 
    padding: 'p-2',
    iconSize: 16,
    titleSize: 'text-sm',
    effectSize: 'text-xs',
    costSize: 'text-xs',
  },
  md: { 
    width: 200, 
    height: 280, 
    padding: 'p-3',
    iconSize: 20,
    titleSize: 'text-base',
    effectSize: 'text-sm',
    costSize: 'text-sm',
  },
  lg: { 
    width: 300, 
    height: 420, 
    padding: 'p-4',
    iconSize: 24,
    titleSize: 'text-xl',
    effectSize: 'text-base',
    costSize: 'text-base',
  },
};

// ═══════════════════════════════════════════════════════════
// 卡背元件
// ═══════════════════════════════════════════════════════════

function CardBack({ width, height }: { width: number; height: number }) {
  return (
    <div 
      className="relative overflow-hidden rounded-xl"
      style={{
        width,
        height,
        background: `linear-gradient(135deg, ${colors.background.secondary}, ${colors.background.primary})`,
        border: `3px solid ${colors.accent.goldMuted}`,
        boxShadow: shadows.lg,
      }}
    >
      <ParchmentTexture />
      
      {/* 中央紋章圖案 */}
      <div className="absolute inset-0 flex items-center justify-center">
        <div 
          className="w-24 h-24 rounded-full border-4 flex items-center justify-center"
          style={{
            borderColor: colors.accent.gold,
            background: `radial-gradient(circle, ${colors.accent.gold}20, transparent)`,
          }}
        >
          {/* 皇冠圖案 */}
          <svg 
            viewBox="0 0 24 24" 
            className="w-12 h-12"
            fill={colors.accent.gold}
            opacity={0.6}
          >
            <path d="M12 2L15 8L22 9L17 14L18 21L12 18L6 21L7 14L2 9L9 8L12 2Z"/>
          </svg>
        </div>
      </div>
      
      {/* 裝飾邊框 */}
      <div 
        className="absolute inset-3 rounded-lg border-2 pointer-events-none"
        style={{ borderColor: `${colors.accent.gold}30` }}
      />
      
      {/* 角落裝飾 */}
      {['top-2 left-2', 'top-2 right-2', 'bottom-2 left-2', 'bottom-2 right-2'].map((pos, i) => (
        <div 
          key={i}
          className={`absolute ${pos} w-4 h-4`}
          style={{
            background: colors.accent.gold,
            clipPath: i < 2 
              ? 'polygon(0 0, 100% 0, 0 100%)' 
              : 'polygon(100% 0, 100% 100%, 0 100%)',
            opacity: 0.4,
            transform: i % 2 === 1 ? 'scaleX(-1)' : 'none',
          }}
        />
      ))}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 遊戲卡牌主元件
// ═══════════════════════════════════════════════════════════

export function GameCard({
  card,
  selectable = true,
  selected = false,
  disabled = false,
  hidden = false,
  size = 'md',
  onClick,
  onHover,
}: GameCardProps) {
  const [isHovered, setIsHovered] = useState(false);
  
  const config = sizeConfig[size];
  const typeInfo = cardTypeConfig[card.type];
  const rarityInfo = rarityConfig[card.rarity];
  const TypeIcon = typeInfo.icon;

  const handleHover = (hovering: boolean) => {
    setIsHovered(hovering);
    onHover?.(hovering);
  };

  // 卡背狀態
  if (hidden) {
    return <CardBack width={config.width} height={config.height} />;
  }

  return (
    <motion.div
      className={`relative overflow-hidden rounded-xl cursor-pointer select-none ${
        disabled ? 'opacity-50 cursor-not-allowed' : ''
      }`}
      style={{
        width: config.width,
        height: config.height,
        background: colors.background.overlay,
        border: `3px solid ${selected ? colors.accent.gold : rarityInfo.borderColor}`,
        boxShadow: selected 
          ? `${shadows.lg}, 0 0 20px ${colors.accent.gold}60`
          : isHovered 
            ? `${shadows.xl}, 0 0 15px ${rarityInfo.glowColor}`
            : shadows.md,
      }}
      whileHover={selectable && !disabled ? { 
        scale: 1.05, 
        y: -8,
        rotateY: 5,
      } : undefined}
      whileTap={selectable && !disabled ? { scale: 0.98 } : undefined}
      onHoverStart={() => handleHover(true)}
      onHoverEnd={() => handleHover(false)}
      onClick={() => selectable && !disabled && onClick?.()}
    >
      <ParchmentTexture />
      
      {/* 頂部欄：類型 + 消耗 + 稀有度 */}
      <div 
        className={`relative z-10 flex items-center justify-between ${config.padding} pb-1`}
        style={{ 
          borderBottom: `1px solid ${colors.accent.gold}30`,
          background: `linear-gradient(180deg, ${colors.background.secondary}, transparent)`,
        }}
      >
        {/* 類型標籤 */}
        <div 
          className="flex items-center gap-1 px-2 py-1 rounded"
          style={{ 
            background: `${typeInfo.color}20`,
            border: `1px solid ${typeInfo.color}40`,
          }}
        >
          <TypeIcon size={config.iconSize - 4} color={typeInfo.color} />
          <span 
            className={`${config.costSize} font-medium`}
            style={{ color: typeInfo.color }}
          >
            {typeInfo.label}
          </span>
        </div>
        
        {/* 消耗 */}
        <div className="flex items-center gap-2">
          {card.cost.influence && (
            <span 
              className={`${config.costSize} font-bold flex items-center gap-0.5`}
              style={{ color: colors.accent.gold }}
            >
              {card.cost.influence}🌟
            </span>
          )}
          {card.cost.gold && (
            <span 
              className={`${config.costSize} font-bold flex items-center gap-0.5`}
              style={{ color: colors.accent.goldMuted }}
            >
              {card.cost.gold}💰
            </span>
          )}
        </div>
        
        {/* 稀有度 */}
        <span className={`${config.costSize}`}>
          {rarityInfo.icon}
        </span>
      </div>
      
      {/* 插圖區域 */}
      <div 
        className="relative mx-3 my-2 rounded-lg overflow-hidden"
        style={{
          height: size === 'lg' ? 180 : size === 'md' ? 100 : 60,
          background: `linear-gradient(135deg, ${typeInfo.color}20, ${colors.background.primary})`,
          border: `1px solid ${typeInfo.color}30`,
          boxShadow: 'inset 0 2px 8px rgba(0, 0, 0, 0.3)',
        }}
      >
        {/* 中央圖標 */}
        <div className="absolute inset-0 flex items-center justify-center">
          <TypeIcon 
            size={size === 'lg' ? 64 : size === 'md' ? 40 : 24} 
            color={typeInfo.color}
            opacity={0.3}
          />
        </div>
        
        {/* 專屬卡標記 */}
        {card.isExclusive && (
          <div 
            className="absolute top-1 right-1 px-1.5 py-0.5 rounded text-xs"
            style={{
              background: colors.accent.gold,
              color: colors.background.primary,
              fontFamily: typography.fontFamily.primary,
            }}
          >
            專屬
          </div>
        )}
      </div>
      
      {/* 卡牌名稱 */}
      <div 
        className="relative z-10 text-center px-3 py-2"
        style={{
          background: `linear-gradient(180deg, transparent, ${colors.background.secondary}80)`,
        }}
      >
        <h4 
          className={`${config.titleSize} font-bold mb-0.5`}
          style={{ 
            color: card.rarity === 'legendary' ? colors.accent.gold : colors.text.primary,
            fontFamily: typography.fontFamily.primary,
            textShadow: card.rarity === 'legendary' 
              ? `0 0 10px ${colors.accent.gold}60` 
              : '0 1px 2px rgba(0, 0, 0, 0.5)',
          }}
        >
          【{card.nameChinese}】
        </h4>
        <p 
          className="text-xs italic opacity-60"
          style={{ 
            color: colors.text.secondary,
            fontFamily: typography.fontFamily.primary,
          }}
        >
          {card.nameEnglish}
        </p>
      </div>
      
      {/* 效果說明 */}
      <div 
        className={`relative z-10 mx-3 mb-3 ${config.padding} rounded-lg flex-1`}
        style={{
          background: 'rgba(0, 0, 0, 0.3)',
          border: `1px solid ${colors.accent.gold}20`,
        }}
      >
        <p 
          className={`${config.effectSize} leading-relaxed`}
          style={{ 
            color: colors.text.primary,
            fontFamily: typography.fontFamily.primary,
          }}
        >
          {card.effect}
        </p>
      </div>
      
      {/* 選中光暈 */}
      {selected && (
        <motion.div
          className="absolute inset-0 pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          style={{
            background: `radial-gradient(circle at center, ${colors.accent.gold}15, transparent 70%)`,
            boxShadow: `inset 0 0 20px ${colors.accent.gold}40`,
          }}
        />
      )}
      
      {/* 傳說卡閃光動畫 */}
      {card.rarity === 'legendary' && (
        <motion.div
          className="absolute inset-0 pointer-events-none"
          initial={{ x: '-100%' }}
          animate={{ x: '200%' }}
          transition={{ 
            duration: 3, 
            repeat: Infinity, 
            repeatDelay: 2,
            ease: 'linear',
          }}
          style={{
            background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.1), transparent)',
            width: '50%',
          }}
        />
      )}
    </motion.div>
  );
}

// ═══════════════════════════════════════════════════════════
// 手牌扇形展示
// ═══════════════════════════════════════════════════════════

interface HandDisplayProps {
  cards: GameCardData[];
  selectedId?: string;
  onSelectCard: (card: GameCardData) => void;
  /** 當前影響力 */
  currentInfluence?: number;
  /** 當前金幣 */
  currentGold?: number;
}

export function HandDisplay({ 
  cards, 
  selectedId, 
  onSelectCard,
  currentInfluence = 10,
  currentGold = 50,
}: HandDisplayProps) {
  const totalCards = cards.length;
  const maxRotation = 15; // 最大旋轉角度
  const cardSpacing = 60; // 卡牌間距
  
  return (
    <div 
      className="relative flex justify-center items-end py-4"
      style={{ minHeight: 320 }}
    >
      {cards.map((card, index) => {
        // 計算扇形排列
        const middleIndex = (totalCards - 1) / 2;
        const offset = index - middleIndex;
        const rotation = (offset / middleIndex) * maxRotation || 0;
        const translateX = offset * cardSpacing;
        const translateY = Math.abs(offset) * 5;
        
        // 檢查是否可用
        const canAfford = 
          (card.cost.influence ? currentInfluence >= card.cost.influence : true) &&
          (card.cost.gold ? currentGold >= card.cost.gold : true);
        
        return (
          <motion.div
            key={card.id}
            className="absolute"
            initial={{ 
              y: 100, 
              opacity: 0, 
              rotate: rotation,
            }}
            animate={{ 
              y: translateY, 
              x: translateX,
              opacity: 1, 
              rotate: rotation,
              zIndex: selectedId === card.id ? 100 : 50 - Math.abs(offset),
            }}
            transition={{ 
              delay: index * 0.05,
              type: 'spring',
              stiffness: 300,
              damping: 25,
            }}
            whileHover={{ 
              y: -30, 
              zIndex: 100,
              rotate: 0,
            }}
            style={{ 
              transformOrigin: 'bottom center',
            }}
          >
            <GameCard
              card={card}
              selected={selectedId === card.id}
              disabled={!canAfford}
              size="md"
              onClick={() => onSelectCard(card)}
            />
          </motion.div>
        );
      })}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 卡牌詳情彈窗
// ═══════════════════════════════════════════════════════════

interface CardDetailModalProps {
  card: GameCardData | null;
  isOpen: boolean;
  onClose: () => void;
  onUse?: () => void;
  canUse?: boolean;
}

export function CardDetailModal({ 
  card, 
  isOpen, 
  onClose, 
  onUse,
  canUse = true,
}: CardDetailModalProps) {
  if (!card) return null;
  
  const typeInfo = cardTypeConfig[card.type];
  const rarityInfo = rarityConfig[card.rarity];

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          {/* 背景遮罩 */}
          <motion.div 
            className="absolute inset-0 bg-black/70"
            onClick={onClose}
          />
          
          {/* 內容 */}
          <motion.div
            className="relative z-10 flex flex-col md:flex-row items-center gap-6"
            initial={{ scale: 0.8, y: 50 }}
            animate={{ scale: 1, y: 0 }}
            exit={{ scale: 0.8, y: 50 }}
          >
            {/* 大尺寸卡牌 */}
            <GameCard card={card} size="lg" selectable={false} />
            
            {/* 詳細說明 */}
            <div 
              className="max-w-sm p-6 rounded-xl"
              style={{
                background: colors.background.overlay,
                border: `2px solid ${colors.accent.gold}40`,
              }}
            >
              <h3 
                className="text-2xl font-bold mb-2"
                style={{ 
                  color: colors.text.primary,
                  fontFamily: typography.fontFamily.primary,
                }}
              >
                {card.nameChinese}
              </h3>
              
              <div className="flex items-center gap-3 mb-4">
                <span 
                  className="px-2 py-1 rounded text-sm"
                  style={{ 
                    background: `${typeInfo.color}20`,
                    color: typeInfo.color,
                  }}
                >
                  {typeInfo.label}
                </span>
                <span 
                  className="text-sm"
                  style={{ color: rarityInfo.borderColor }}
                >
                  {rarityInfo.icon} {rarityInfo.label}
                </span>
              </div>
              
              <p 
                className="text-base mb-6 leading-relaxed"
                style={{ 
                  color: colors.text.secondary,
                  fontFamily: typography.fontFamily.primary,
                }}
              >
                {card.effect}
              </p>
              
              {/* 按鈕組 */}
              <div className="flex gap-3">
                <button
                  className="flex-1 py-3 rounded-lg transition-all"
                  style={{
                    background: 'transparent',
                    border: `2px solid ${colors.text.muted}`,
                    color: colors.text.secondary,
                  }}
                  onClick={onClose}
                >
                  取消
                </button>
                
                {onUse && (
                  <button
                    className={`flex-1 py-3 rounded-lg font-bold transition-all ${
                      !canUse ? 'opacity-50 cursor-not-allowed' : ''
                    }`}
                    style={{
                      background: canUse 
                        ? `linear-gradient(135deg, ${colors.accent.gold}, ${colors.accent.goldMuted})`
                        : colors.text.muted,
                      color: colors.background.primary,
                      boxShadow: canUse ? shadows.gold : 'none',
                    }}
                    onClick={() => canUse && onUse()}
                    disabled={!canUse}
                  >
                    使用卡牌
                  </button>
                )}
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

export default GameCard;

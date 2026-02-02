// Parliament 1812 — 資源面板元件
// 設計：羅塞蒂 | 2025-01-31

import { motion, AnimatePresence } from 'motion/react';
import { Heart, Sparkles, Coins, AlertTriangle, Skull } from 'lucide-react';
import { colors, typography, shadows, factions, type FactionId } from '../theme/designTokens';
import { HexagonBadge, GearIcon } from './HexagonPattern';

// ═══════════════════════════════════════════════════════════
// 類型定義
// ═══════════════════════════════════════════════════════════

interface PlayerStats {
  reputation: number;
  maxReputation: number;
  influence: number;
  maxInfluence: number;
  gold: number;
  maxGold: number;
  handCount: number;
  status: 'normal' | 'weakened' | 'silenced' | 'sealed' | 'dead';
}

interface ResourcePanelProps {
  characterName: string;
  characterIcon: string;
  faction: FactionId;
  stats: PlayerStats;
  /** 是否為當前玩家 */
  isCurrentPlayer?: boolean;
  /** 是否為回合玩家 */
  isActivePlayer?: boolean;
  /** 是否緊湊模式 */
  compact?: boolean;
  className?: string;
}

// ═══════════════════════════════════════════════════════════
// 狀態配置
// ═══════════════════════════════════════════════════════════

const statusConfig = {
  normal: { label: '正常', color: colors.semantic.success, icon: null },
  weakened: { label: '虛弱', color: colors.semantic.warning, icon: AlertTriangle },
  silenced: { label: '沉默', color: colors.semantic.danger, icon: null },
  sealed: { label: '封印', color: colors.rarity.epic, icon: null },
  dead: { label: '政治死亡', color: '#666', icon: Skull },
};

// ═══════════════════════════════════════════════════════════
// 動畫資源條
// ═══════════════════════════════════════════════════════════

interface AnimatedBarProps {
  value: number;
  maxValue: number;
  color: string;
  secondaryColor?: string;
  showGlow?: boolean;
  height?: number;
}

function AnimatedBar({ 
  value, 
  maxValue, 
  color, 
  secondaryColor,
  showGlow = false,
  height = 12,
}: AnimatedBarProps) {
  const percentage = Math.min((value / maxValue) * 100, 100);
  const isLow = percentage < 30;
  
  return (
    <div 
      className="relative rounded-full overflow-hidden"
      style={{ 
        height,
        background: 'rgba(0, 0, 0, 0.5)',
        boxShadow: 'inset 0 2px 4px rgba(0, 0, 0, 0.4)',
        border: `1px solid ${color}30`,
      }}
    >
      <motion.div
        className="absolute inset-y-0 left-0 rounded-full"
        initial={{ width: 0 }}
        animate={{ width: `${percentage}%` }}
        transition={{ 
          duration: 0.6, 
          ease: 'easeOut',
          type: 'spring',
          stiffness: 100,
        }}
        style={{ 
          background: secondaryColor 
            ? `linear-gradient(90deg, ${color}, ${secondaryColor})`
            : color,
          boxShadow: showGlow ? `0 0 10px ${color}80` : 'none',
        }}
      />
      
      {/* 高光效果 */}
      <div 
        className="absolute inset-x-0 top-0 h-1/3 rounded-full opacity-30"
        style={{
          background: 'linear-gradient(180deg, rgba(255,255,255,0.4), transparent)',
        }}
      />
      
      {/* 低血量警告動畫 */}
      {isLow && (
        <motion.div
          className="absolute inset-0 rounded-full"
          animate={{ opacity: [0.3, 0.6, 0.3] }}
          transition={{ duration: 1, repeat: Infinity }}
          style={{ background: `${colors.semantic.danger}40` }}
        />
      )}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 資源項目
// ═══════════════════════════════════════════════════════════

interface ResourceItemProps {
  icon: typeof Heart;
  iconEmoji?: string;
  label: string;
  value: number;
  maxValue: number;
  color: string;
  secondaryColor?: string;
  compact?: boolean;
}

function ResourceItem({ 
  icon: Icon, 
  iconEmoji,
  label, 
  value, 
  maxValue, 
  color,
  secondaryColor,
  compact = false,
}: ResourceItemProps) {
  const percentage = (value / maxValue) * 100;
  const isLow = percentage < 30;
  
  return (
    <div className={compact ? 'flex items-center gap-2' : ''}>
      <div className="flex items-center justify-between mb-1">
        <div className="flex items-center gap-1.5">
          {iconEmoji ? (
            <span className="text-base">{iconEmoji}</span>
          ) : (
            <Icon size={16} color={color} />
          )}
          {!compact && (
            <span 
              className="text-xs uppercase tracking-wider"
              style={{ color: colors.text.muted }}
            >
              {label}
            </span>
          )}
        </div>
        <span 
          className={`text-sm font-bold tabular-nums ${isLow ? 'animate-pulse' : ''}`}
          style={{ 
            color: isLow ? colors.semantic.danger : colors.text.primary,
            fontFamily: typography.fontFamily.primary,
          }}
        >
          {value}/{maxValue}
        </span>
      </div>
      <AnimatedBar 
        value={value} 
        maxValue={maxValue} 
        color={color}
        secondaryColor={secondaryColor}
        showGlow={percentage > 70}
        height={compact ? 8 : 12}
      />
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 主資源面板元件
// ═══════════════════════════════════════════════════════════

export function ResourcePanel({
  characterName,
  characterIcon,
  faction,
  stats,
  isCurrentPlayer = false,
  isActivePlayer = false,
  compact = false,
  className = '',
}: ResourcePanelProps) {
  const factionInfo = factions[faction];
  const statusInfo = statusConfig[stats.status];
  const StatusIcon = statusInfo.icon;
  
  return (
    <motion.div
      className={`relative overflow-hidden ${className}`}
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      style={{
        background: colors.background.overlay,
        borderRadius: 16,
        border: `2px solid ${isActivePlayer ? colors.accent.gold : factionInfo.colors.primary}50`,
        boxShadow: isActivePlayer 
          ? `${shadows.lg}, 0 0 20px ${colors.accent.gold}30`
          : shadows.md,
        padding: compact ? 12 : 16,
      }}
    >
      {/* 回合指示器 */}
      {isActivePlayer && (
        <motion.div
          className="absolute top-0 left-0 right-0 h-1"
          style={{ background: colors.accent.gold }}
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ duration: 0.3 }}
        />
      )}
      
      {/* 頭部：角色資訊 */}
      <div className="flex items-center gap-3 mb-3">
        {/* 頭像 */}
        <div 
          className="relative w-12 h-12 rounded-full flex items-center justify-center"
          style={{
            background: `${factionInfo.colors.primary}30`,
            border: `2px solid ${factionInfo.colors.primary}`,
            boxShadow: isActivePlayer ? `0 0 12px ${colors.accent.gold}40` : 'none',
          }}
        >
          <span className="text-xl">{characterIcon}</span>
          
          {/* 回合標記 */}
          {isActivePlayer && (
            <motion.div
              className="absolute -top-1 -right-1 w-4 h-4 rounded-full flex items-center justify-center"
              style={{ 
                background: colors.accent.gold,
                boxShadow: `0 0 8px ${colors.accent.gold}`,
              }}
              animate={{ scale: [1, 1.2, 1] }}
              transition={{ duration: 1.5, repeat: Infinity }}
            >
              <GearIcon className="w-2.5 h-2.5" style={{ color: colors.background.primary }} spinning />
            </motion.div>
          )}
        </div>
        
        {/* 名稱與狀態 */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h4 
              className="text-base font-bold truncate"
              style={{ 
                color: colors.text.primary,
                fontFamily: typography.fontFamily.primary,
              }}
            >
              {characterName}
            </h4>
            {isCurrentPlayer && (
              <span 
                className="text-xs px-1.5 py-0.5 rounded"
                style={{ 
                  background: `${colors.accent.gold}20`,
                  color: colors.accent.gold,
                }}
              >
                你
              </span>
            )}
          </div>
          
          <div className="flex items-center gap-2 mt-0.5">
            <span 
              className="text-xs"
              style={{ color: factionInfo.colors.primary }}
            >
              {factionInfo.icon} {factionInfo.nameChinese}
            </span>
            
            {/* 狀態標籤 */}
            {stats.status !== 'normal' && (
              <span 
                className="text-xs px-1.5 py-0.5 rounded flex items-center gap-1"
                style={{ 
                  background: `${statusInfo.color}20`,
                  color: statusInfo.color,
                }}
              >
                {StatusIcon && <StatusIcon size={10} />}
                {statusInfo.label}
              </span>
            )}
          </div>
        </div>
        
        {/* 手牌數量 */}
        <div 
          className="flex flex-col items-center px-3 py-1 rounded-lg"
          style={{ 
            background: 'rgba(0, 0, 0, 0.3)',
            border: `1px solid ${colors.accent.gold}20`,
          }}
        >
          <span className="text-lg">🃏</span>
          <span 
            className="text-xs font-bold"
            style={{ color: colors.text.secondary }}
          >
            {stats.handCount}
          </span>
        </div>
      </div>
      
      {/* 資源條 */}
      <div className={`space-y-${compact ? '2' : '3'}`}>
        <ResourceItem
          icon={Heart}
          iconEmoji="❤️"
          label="聲望"
          value={stats.reputation}
          maxValue={stats.maxReputation}
          color={colors.semantic.danger}
          secondaryColor={colors.semantic.dangerLight}
          compact={compact}
        />
        
        <ResourceItem
          icon={Sparkles}
          iconEmoji="🌟"
          label="影響力"
          value={stats.influence}
          maxValue={stats.maxInfluence}
          color={colors.accent.gold}
          secondaryColor={colors.accent.goldMuted}
          compact={compact}
        />
        
        <ResourceItem
          icon={Coins}
          iconEmoji="💰"
          label="金幣"
          value={stats.gold}
          maxValue={stats.maxGold}
          color={colors.accent.goldMuted}
          secondaryColor="#8B6914"
          compact={compact}
        />
      </div>
      
      {/* 政治死亡遮罩 */}
      <AnimatePresence>
        {stats.status === 'dead' && (
          <motion.div
            className="absolute inset-0 flex items-center justify-center"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{
              background: 'rgba(0, 0, 0, 0.7)',
              borderRadius: 16,
            }}
          >
            <div className="text-center">
              <Skull size={32} color={colors.semantic.danger} className="mx-auto mb-2" />
              <span 
                className="text-sm font-bold"
                style={{ color: colors.semantic.danger }}
              >
                政治死亡
              </span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

// ═══════════════════════════════════════════════════════════
// 迷你資源條（用於對手顯示）
// ═══════════════════════════════════════════════════════════

interface MiniResourceBarProps {
  characterName: string;
  characterIcon: string;
  faction: FactionId;
  reputation: number;
  maxReputation?: number;
  isAlly?: boolean;
  isDead?: boolean;
  onClick?: () => void;
}

export function MiniResourceBar({
  characterName,
  characterIcon,
  faction,
  reputation,
  maxReputation = 100,
  isAlly = false,
  isDead = false,
  onClick,
}: MiniResourceBarProps) {
  const factionInfo = factions[faction];
  const percentage = (reputation / maxReputation) * 100;
  
  return (
    <motion.div
      className="flex items-center gap-2 p-2 rounded-lg cursor-pointer"
      style={{
        background: isDead ? 'rgba(0, 0, 0, 0.5)' : 'rgba(36, 27, 20, 0.8)',
        border: `1px solid ${isAlly ? colors.accent.gold : factionInfo.colors.primary}40`,
        opacity: isDead ? 0.6 : 1,
      }}
      whileHover={{ scale: 1.02, background: 'rgba(36, 27, 20, 0.95)' }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
    >
      {/* 頭像 */}
      <div 
        className="w-8 h-8 rounded-full flex items-center justify-center"
        style={{
          background: `${factionInfo.colors.primary}30`,
          border: `1.5px solid ${factionInfo.colors.primary}`,
        }}
      >
        <span className="text-sm">{characterIcon}</span>
      </div>
      
      {/* 資訊 */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-1.5 mb-1">
          <span 
            className="text-xs font-medium truncate"
            style={{ 
              color: isDead ? colors.text.muted : colors.text.primary,
              textDecoration: isDead ? 'line-through' : 'none',
            }}
          >
            {characterName}
          </span>
          {isAlly && (
            <span className="text-[10px] px-1 rounded bg-amber-500/20 text-amber-400">
              盟
            </span>
          )}
          {isDead && (
            <Skull size={10} color={colors.semantic.danger} />
          )}
        </div>
        
        {/* 聲望條 */}
        <AnimatedBar
          value={reputation}
          maxValue={maxReputation}
          color={percentage > 30 ? colors.semantic.danger : '#4A1A00'}
          height={6}
        />
      </div>
      
      {/* 數值 */}
      <span 
        className="text-xs font-bold tabular-nums w-8 text-right"
        style={{ 
          color: percentage > 30 ? colors.text.secondary : colors.semantic.danger,
        }}
      >
        {reputation}
      </span>
    </motion.div>
  );
}

// ═══════════════════════════════════════════════════════════
// 頂部遊戲狀態欄
// ═══════════════════════════════════════════════════════════

interface GameStatusBarProps {
  roundNumber: number;
  phaseName: string;
  phaseNameEn: string;
  timeLeft?: number;
  billTitle?: string;
}

export function GameStatusBar({
  roundNumber,
  phaseName,
  phaseNameEn,
  timeLeft,
  billTitle,
}: GameStatusBarProps) {
  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };
  
  return (
    <div 
      className="flex items-center justify-between px-4 py-3"
      style={{
        background: colors.background.overlay,
        borderBottom: `1px solid ${colors.accent.gold}30`,
        boxShadow: '0 2px 8px rgba(0, 0, 0, 0.3)',
      }}
    >
      {/* 左側：回合與階段 */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2">
          <GearIcon className="w-5 h-5" style={{ color: colors.accent.gold }} spinning />
          <span 
            className="text-sm font-medium"
            style={{ color: colors.text.secondary }}
          >
            第 <span style={{ color: colors.accent.gold }}>{roundNumber}</span> 回合
          </span>
        </div>
        
        <div 
          className="px-3 py-1 rounded-full"
          style={{
            background: `${colors.accent.gold}20`,
            border: `1px solid ${colors.accent.gold}40`,
          }}
        >
          <span 
            className="text-sm font-bold"
            style={{ 
              color: colors.accent.gold,
              fontFamily: typography.fontFamily.primary,
            }}
          >
            {phaseName}
            <span className="text-xs opacity-60 ml-1.5">{phaseNameEn}</span>
          </span>
        </div>
      </div>
      
      {/* 中間：議案標題 */}
      {billTitle && (
        <div className="hidden md:block">
          <span 
            className="text-sm"
            style={{ 
              color: colors.text.secondary,
              fontFamily: typography.fontFamily.primary,
            }}
          >
            議案：<span style={{ color: colors.text.primary }}>《{billTitle}》</span>
          </span>
        </div>
      )}
      
      {/* 右側：倒計時 */}
      {timeLeft !== undefined && (
        <div className="flex items-center gap-2">
          <motion.div
            className="w-2 h-2 rounded-full"
            style={{ background: timeLeft > 30 ? colors.semantic.success : colors.semantic.danger }}
            animate={{ opacity: [1, 0.5, 1] }}
            transition={{ duration: 1, repeat: Infinity }}
          />
          <span 
            className="text-lg font-bold tabular-nums"
            style={{ 
              color: timeLeft > 30 ? colors.accent.gold : colors.semantic.danger,
              fontFamily: typography.fontFamily.primary,
            }}
          >
            {formatTime(timeLeft)}
          </span>
        </div>
      )}
    </div>
  );
}

export default ResourcePanel;

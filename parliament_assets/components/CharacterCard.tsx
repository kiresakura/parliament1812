// Parliament 1812 — 角色卡片元件
// 設計：羅塞蒂 | 2025-01-31

import { motion } from 'motion/react';
import { colors, typography, factions, characters, type FactionId, type CharacterConfig } from '../theme/designTokens';
import { HexagonBadge, GearIcon } from './HexagonPattern';
import { ParchmentTexture, CornerFlourish } from './VictorianOrnament';

// ═══════════════════════════════════════════════════════════
// 類型定義
// ═══════════════════════════════════════════════════════════

interface CharacterCardProps {
  character: CharacterConfig;
  /** 是否顯示資源數值 */
  showStats?: boolean;
  /** 是否為選中狀態 */
  selected?: boolean;
  /** 尺寸變體 */
  size?: 'sm' | 'md' | 'lg';
  /** 點擊回調 */
  onClick?: () => void;
  /** 自定義類名 */
  className?: string;
}

interface ResourceBarProps {
  icon: string;
  label: string;
  value: number;
  maxValue: number;
  color: string;
}

// ═══════════════════════════════════════════════════════════
// 資源條元件
// ═══════════════════════════════════════════════════════════

function ResourceBar({ icon, label, value, maxValue, color }: ResourceBarProps) {
  const percentage = (value / maxValue) * 100;
  
  return (
    <div className="flex items-center gap-2">
      <span className="text-base w-6 text-center">{icon}</span>
      <div className="flex-1">
        <div 
          className="h-2 rounded-full overflow-hidden"
          style={{ 
            background: 'rgba(0, 0, 0, 0.4)',
            boxShadow: 'inset 0 1px 2px rgba(0, 0, 0, 0.3)',
          }}
        >
          <motion.div
            className="h-full rounded-full"
            initial={{ width: 0 }}
            animate={{ width: `${percentage}%` }}
            transition={{ duration: 0.8, ease: 'easeOut' }}
            style={{ 
              background: `linear-gradient(90deg, ${color}, ${color}99)`,
              boxShadow: `0 0 8px ${color}60`,
            }}
          />
        </div>
      </div>
      <span 
        className="text-xs tabular-nums w-12 text-right"
        style={{ 
          color: colors.text.secondary,
          fontFamily: typography.fontFamily.primary,
        }}
      >
        {value}/{maxValue}
      </span>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 派系徽章元件
// ═══════════════════════════════════════════════════════════

function FactionBadge({ factionId }: { factionId: FactionId }) {
  const faction = factions[factionId];
  
  return (
    <div 
      className="flex items-center gap-1.5 px-3 py-1.5 rounded-full border"
      style={{
        background: `${faction.colors.primary}20`,
        borderColor: `${faction.colors.primary}60`,
      }}
    >
      <span className="text-sm">{faction.icon}</span>
      <span 
        className="text-xs font-medium tracking-wide"
        style={{ 
          color: faction.colors.primary,
          fontFamily: typography.fontFamily.primary,
        }}
      >
        {faction.nameChinese}
      </span>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 角色卡片主元件
// ═══════════════════════════════════════════════════════════

export function CharacterCard({ 
  character, 
  showStats = true, 
  selected = false,
  size = 'md',
  onClick,
  className = '',
}: CharacterCardProps) {
  const faction = factions[character.faction];
  
  // 尺寸配置
  const sizeConfig = {
    sm: { width: 200, padding: 'p-3', titleSize: 'text-lg', subtitleSize: 'text-xs' },
    md: { width: 280, padding: 'p-4', titleSize: 'text-xl', subtitleSize: 'text-sm' },
    lg: { width: 340, padding: 'p-5', titleSize: 'text-2xl', subtitleSize: 'text-base' },
  };
  
  const config = sizeConfig[size];

  return (
    <motion.div
      className={`relative overflow-hidden cursor-pointer ${className}`}
      style={{
        width: config.width,
        background: colors.background.overlay,
        borderRadius: 16,
        border: `3px solid ${selected ? colors.accent.gold : faction.colors.primary}`,
        boxShadow: selected 
          ? `0 8px 32px rgba(0, 0, 0, 0.6), ${colors.accent.gold}40 0 0 20px`
          : '0 8px 24px rgba(0, 0, 0, 0.5)',
      }}
      whileHover={{ 
        scale: 1.02,
        boxShadow: `0 12px 40px rgba(0, 0, 0, 0.7), ${faction.colors.primary}40 0 0 15px`,
      }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
    >
      {/* 羊皮紙紋理背景 */}
      <ParchmentTexture />
      
      {/* 角落裝飾 */}
      <CornerFlourish 
        className="absolute -top-1 -left-1 w-8 h-8 opacity-40 pointer-events-none" 
        position="top-left" 
      />
      <CornerFlourish 
        className="absolute -top-1 -right-1 w-8 h-8 opacity-40 pointer-events-none" 
        position="top-right" 
      />
      
      {/* 裝飾齒輪 */}
      <GearIcon 
        className="absolute top-3 right-3 w-6 h-6 opacity-20" 
        style={{ color: faction.colors.primary }}
        spinning 
      />
      
      <div className={`relative z-10 ${config.padding}`}>
        {/* 頂部：派系徽章 */}
        <div className="flex justify-between items-start mb-4">
          <FactionBadge factionId={character.faction} />
          <span className="text-2xl">{character.icon}</span>
        </div>
        
        {/* 角色立繪區域 */}
        <div 
          className="relative mx-auto mb-4 rounded-lg overflow-hidden border-2"
          style={{
            width: '80%',
            aspectRatio: '3 / 4',
            background: `linear-gradient(135deg, ${faction.colors.secondary}, ${colors.background.primary})`,
            borderColor: colors.accent.goldMuted,
            boxShadow: 'inset 0 4px 12px rgba(0, 0, 0, 0.4)',
          }}
        >
          {/* 角色立繪圖片 */}
          {character.image ? (
            <img
              src={character.image}
              alt={character.nameChinese}
              className="absolute inset-0 w-full h-full object-cover object-top"
              style={{
                filter: 'contrast(1.05) saturate(1.1)',
              }}
            />
          ) : (
            /* Fallback: 六邊形徽章（無圖片時） */
            <div className="absolute inset-0 flex items-center justify-center">
              <HexagonBadge 
                className="w-20 h-20" 
                color={faction.colors.primary}
              >
                <span className="text-3xl">{character.icon}</span>
              </HexagonBadge>
            </div>
          )}
          
          {/* 底部漸層遮罩 */}
          <div 
            className="absolute bottom-0 left-0 right-0 h-1/3"
            style={{
              background: 'linear-gradient(to top, rgba(26, 22, 20, 0.9), transparent)',
            }}
          />
          
          {/* 派系色邊緣光暈 */}
          <div 
            className="absolute inset-0 pointer-events-none"
            style={{
              boxShadow: `inset 0 0 20px ${faction.colors.primary}40`,
            }}
          />
        </div>
        
        {/* 分隔線 */}
        <div 
          className="h-px mb-3"
          style={{
            background: `linear-gradient(90deg, transparent, ${colors.accent.gold}60, transparent)`,
          }}
        />
        
        {/* 角色名稱 */}
        <div className="text-center mb-3">
          <h3 
            className={`${config.titleSize} font-bold mb-1`}
            style={{ 
              color: colors.text.primary,
              fontFamily: typography.fontFamily.primary,
              textShadow: '0 2px 4px rgba(0, 0, 0, 0.5)',
            }}
          >
            {character.nameChinese}
          </h3>
          <p 
            className={`${config.subtitleSize} italic opacity-70`}
            style={{ 
              color: colors.text.secondary,
              fontFamily: typography.fontFamily.primary,
            }}
          >
            {character.nameEnglish}
          </p>
          <p 
            className="text-xs mt-1 tracking-wider uppercase"
            style={{ color: faction.colors.primary }}
          >
            {character.title}
          </p>
        </div>
        
        {/* 資源條 */}
        {showStats && (
          <div 
            className="p-3 rounded-lg space-y-2"
            style={{
              background: 'rgba(0, 0, 0, 0.3)',
              border: `1px solid ${colors.accent.gold}20`,
            }}
          >
            <ResourceBar 
              icon="❤️" 
              label="聲望" 
              value={character.stats.reputation} 
              maxValue={100}
              color={colors.semantic.danger}
            />
            <ResourceBar 
              icon="🌟" 
              label="影響力" 
              value={character.stats.influence} 
              maxValue={15}
              color={colors.accent.gold}
            />
            <ResourceBar 
              icon="💰" 
              label="金幣" 
              value={character.stats.gold} 
              maxValue={150}
              color={colors.accent.goldMuted}
            />
          </div>
        )}
      </div>
      
      {/* 選中狀態光暈 */}
      {selected && (
        <motion.div
          className="absolute inset-0 pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          style={{
            background: `radial-gradient(circle at center, ${colors.accent.gold}10, transparent 70%)`,
            boxShadow: `inset 0 0 30px ${colors.accent.gold}30`,
          }}
        />
      )}
    </motion.div>
  );
}

// ═══════════════════════════════════════════════════════════
// 角色選擇網格
// ═══════════════════════════════════════════════════════════

interface CharacterSelectGridProps {
  characters: CharacterConfig[];
  selectedId?: string;
  onSelect: (character: CharacterConfig) => void;
}

export function CharacterSelectGrid({ 
  characters: characterList, 
  selectedId, 
  onSelect 
}: CharacterSelectGridProps) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 p-6">
      {characterList.map((character) => (
        <CharacterCard
          key={character.id}
          character={character}
          selected={selectedId === character.id}
          onClick={() => onSelect(character)}
          showStats={true}
          size="md"
        />
      ))}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 迷你角色卡片（用於遊戲中顯示其他玩家）
// ═══════════════════════════════════════════════════════════

interface MiniCharacterCardProps {
  character: CharacterConfig;
  reputation: number;
  isAlly?: boolean;
  isDead?: boolean;
  onClick?: () => void;
}

export function MiniCharacterCard({
  character,
  reputation,
  isAlly = false,
  isDead = false,
  onClick,
}: MiniCharacterCardProps) {
  const faction = factions[character.faction];
  
  return (
    <motion.div
      className="flex items-center gap-3 p-2 rounded-lg cursor-pointer"
      style={{
        background: isDead 
          ? 'rgba(0, 0, 0, 0.6)' 
          : 'rgba(36, 27, 20, 0.8)',
        border: `2px solid ${isAlly ? colors.accent.gold : faction.colors.primary}50`,
        opacity: isDead ? 0.6 : 1,
      }}
      whileHover={{ scale: 1.02, background: 'rgba(36, 27, 20, 0.95)' }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
    >
      {/* 頭像 */}
      <div 
        className="w-10 h-10 rounded-full flex items-center justify-center border-2"
        style={{
          background: `${faction.colors.primary}30`,
          borderColor: faction.colors.primary,
        }}
      >
        <span className="text-lg">{character.icon}</span>
      </div>
      
      {/* 資訊 */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span 
            className="text-sm font-medium truncate"
            style={{ 
              color: isDead ? colors.text.muted : colors.text.primary,
              fontFamily: typography.fontFamily.primary,
              textDecoration: isDead ? 'line-through' : 'none',
            }}
          >
            {character.nameChinese}
          </span>
          {isAlly && (
            <span className="text-xs px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-400">
              盟友
            </span>
          )}
          {isDead && (
            <span className="text-xs px-1.5 py-0.5 rounded bg-red-500/20 text-red-400">
              ☠️
            </span>
          )}
        </div>
        
        {/* 聲望條 */}
        <div 
          className="h-1.5 mt-1 rounded-full overflow-hidden"
          style={{ background: 'rgba(0, 0, 0, 0.4)' }}
        >
          <div 
            className="h-full rounded-full transition-all duration-500"
            style={{ 
              width: `${reputation}%`,
              background: reputation > 30 
                ? `linear-gradient(90deg, ${colors.semantic.danger}, ${colors.semantic.dangerLight})`
                : `linear-gradient(90deg, #4A1A00, #6E1E00)`,
            }}
          />
        </div>
      </div>
      
      {/* 聲望數值 */}
      <span 
        className="text-sm tabular-nums font-medium"
        style={{ 
          color: reputation > 30 ? colors.text.secondary : colors.semantic.danger,
          fontFamily: typography.fontFamily.primary,
        }}
      >
        {reputation}
      </span>
    </motion.div>
  );
}

export default CharacterCard;

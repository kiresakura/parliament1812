// Parliament 1812 — 角色展示頁面
// MVP 角色：工人湯瑪斯、工廠主理查、記者愛德華、盧德派喬治
// 設計：羅塞蒂 | 2025-01-31

import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronRight, Users, Swords, Shield, Star } from 'lucide-react';
import { 
  colors, 
  typography, 
  shadows, 
  factions, 
  characters,
  type CharacterConfig,
} from '../theme/designTokens';
import { CharacterCard } from './CharacterCard';
import { GameCard, type GameCardData } from './GameCard';
import { HexagonPattern, HexagonBadge, GearIcon } from './HexagonPattern';
import { AtmosphereParticles, DividerLine, CrownIcon } from './VictorianOrnament';

// ═══════════════════════════════════════════════════════════
// MVP 角色專屬卡牌資料
// ═══════════════════════════════════════════════════════════

const characterCards: Record<string, GameCardData[]> = {
  thomas: [
    {
      id: 't01',
      nameChinese: '工人之怒',
      nameEnglish: "Worker's Fury",
      type: 'attack',
      rarity: 'epic',
      cost: { influence: 4 },
      effect: '對資方陣營角色造成聲望 -25（對非資方僅 -10）',
      isExclusive: true,
      exclusiveCharacter: 'thomas',
    },
    {
      id: 't02',
      nameChinese: '團結一心',
      nameEnglish: 'Unity',
      type: 'buff',
      rarity: 'rare',
      cost: { influence: 3 },
      effect: '所有勞工派盟友本回合獲得：攻擊 +5、防禦 +5',
      isExclusive: true,
      exclusiveCharacter: 'thomas',
    },
    {
      id: 't03',
      nameChinese: '苦情牌',
      nameEnglish: 'Plea of Hardship',
      type: 'special',
      rarity: 'normal',
      cost: { influence: 1 },
      effect: '犧牲 15 聲望，獲得 +6🌟 影響力',
      isExclusive: true,
      exclusiveCharacter: 'thomas',
    },
  ],
  richard: [
    {
      id: 'r01',
      nameChinese: '金錢攻勢',
      nameEnglish: 'Money Talks',
      type: 'control',
      rarity: 'epic',
      cost: { gold: 40 },
      effect: '指定目標本回合無法發言且無法打卡',
      isExclusive: true,
      exclusiveCharacter: 'richard',
    },
    {
      id: 'r02',
      nameChinese: '經濟威脅',
      nameEnglish: 'Economic Threat',
      type: 'attack',
      rarity: 'rare',
      cost: { influence: 3 },
      effect: '造成「你的金幣數 ÷ 10」點聲望傷害（最高 -15）',
      isExclusive: true,
      exclusiveCharacter: 'richard',
    },
    {
      id: 'r03',
      nameChinese: '產業聯盟',
      nameEnglish: 'Industrial Alliance',
      type: 'heal',
      rarity: 'normal',
      cost: { influence: 2 },
      effect: '所有資方陣營角色（包括你）回復 8 聲望',
      isExclusive: true,
      exclusiveCharacter: 'richard',
    },
  ],
  edward: [
    {
      id: 'e01',
      nameChinese: '獨家報導',
      nameEnglish: 'Exclusive Scoop',
      type: 'intel',
      rarity: 'epic',
      cost: { influence: 3 },
      effect: '公開揭露目標的秘密任務給所有人看',
      isExclusive: true,
      exclusiveCharacter: 'edward',
    },
    {
      id: 'e02',
      nameChinese: '深入調查',
      nameEnglish: 'Deep Investigation',
      type: 'intel',
      rarity: 'rare',
      cost: { influence: 2 },
      effect: '查看目標的全部手牌（不公開）',
      isExclusive: true,
      exclusiveCharacter: 'edward',
    },
    {
      id: 'e03',
      nameChinese: '輿論風暴',
      nameEnglish: 'Public Outrage',
      type: 'attack',
      rarity: 'normal',
      cost: { influence: 4 },
      effect: '若你本回合已使用過情報類卡牌，傷害 -25；否則 -10',
      isExclusive: true,
      exclusiveCharacter: 'edward',
    },
  ],
  george: [
    {
      id: 'g01',
      nameChinese: '暴力抗議',
      nameEnglish: 'Violent Protest',
      type: 'attack',
      rarity: 'epic',
      cost: { influence: 5 },
      effect: '對目標造成聲望 -30，但你自己也損失 -15 聲望',
      isExclusive: true,
      exclusiveCharacter: 'george',
    },
    {
      id: 'g02',
      nameChinese: '煽動群眾',
      nameEnglish: 'Incite the Masses',
      type: 'buff',
      rarity: 'rare',
      cost: { influence: 4 },
      effect: '本回合所有攻擊卡傷害 +10（包括你和盟友）',
      isExclusive: true,
      exclusiveCharacter: 'george',
    },
    {
      id: 'g03',
      nameChinese: '破壞機器',
      nameEnglish: 'Smash the Machine',
      type: 'special',
      rarity: 'normal',
      cost: { influence: 2 },
      effect: '隨機抽取工廠主理查的 1 張手牌並銷毀',
      isExclusive: true,
      exclusiveCharacter: 'george',
    },
  ],
};

// ═══════════════════════════════════════════════════════════
// 角色詳情面板
// ═══════════════════════════════════════════════════════════

interface CharacterDetailProps {
  character: CharacterConfig;
  cards: GameCardData[];
  onClose: () => void;
}

function CharacterDetail({ character, cards, onClose }: CharacterDetailProps) {
  const faction = factions[character.faction];
  
  return (
    <motion.div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 md:p-8"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      {/* 背景遮罩 */}
      <motion.div 
        className="absolute inset-0"
        style={{ background: 'rgba(0, 0, 0, 0.85)' }}
        onClick={onClose}
      />
      
      {/* 內容 */}
      <motion.div
        className="relative z-10 w-full max-w-5xl max-h-[90vh] overflow-y-auto rounded-2xl"
        style={{
          background: colors.background.overlay,
          border: `2px solid ${faction.colors.primary}60`,
          boxShadow: `${shadows.xl}, 0 0 40px ${faction.colors.primary}20`,
        }}
        initial={{ scale: 0.9, y: 50 }}
        animate={{ scale: 1, y: 0 }}
        exit={{ scale: 0.9, y: 50 }}
      >
        {/* 頂部裝飾條 */}
        <div 
          className="h-2"
          style={{ 
            background: `linear-gradient(90deg, ${faction.colors.primary}, ${faction.colors.accent})`,
          }}
        />
        
        <div className="p-6 md:p-8">
          {/* 關閉按鈕 */}
          <button
            className="absolute top-4 right-4 w-10 h-10 rounded-full flex items-center justify-center transition-colors"
            style={{
              background: 'rgba(0, 0, 0, 0.5)',
              border: `1px solid ${colors.text.muted}40`,
              color: colors.text.secondary,
            }}
            onClick={onClose}
          >
            ✕
          </button>
          
          {/* 角色資訊區 */}
          <div className="flex flex-col md:flex-row gap-8 mb-8">
            {/* 左側：角色卡 */}
            <div className="flex-shrink-0">
              <CharacterCard 
                character={character} 
                showStats={true}
                size="lg"
              />
            </div>
            
            {/* 右側：詳細資訊 */}
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-4">
                <span className="text-4xl">{character.icon}</span>
                <div>
                  <h2 
                    className="text-3xl font-bold"
                    style={{ 
                      color: colors.text.primary,
                      fontFamily: typography.fontFamily.primary,
                    }}
                  >
                    {character.nameChinese}
                  </h2>
                  <p 
                    className="text-lg italic opacity-70"
                    style={{ color: colors.text.secondary }}
                  >
                    {character.nameEnglish}
                  </p>
                </div>
              </div>
              
              <div 
                className="inline-flex items-center gap-2 px-4 py-2 rounded-full mb-6"
                style={{
                  background: `${faction.colors.primary}20`,
                  border: `1px solid ${faction.colors.primary}60`,
                }}
              >
                <span>{faction.icon}</span>
                <span style={{ color: faction.colors.primary }}>
                  {faction.nameChinese} · {character.title}
                </span>
              </div>
              
              {/* 角色描述 */}
              <div 
                className="p-4 rounded-lg mb-6"
                style={{
                  background: 'rgba(0, 0, 0, 0.3)',
                  border: `1px solid ${colors.accent.gold}20`,
                }}
              >
                <h3 
                  className="text-sm font-bold mb-2 uppercase tracking-wider"
                  style={{ color: colors.accent.gold }}
                >
                  角色定位
                </h3>
                <p 
                  className="leading-relaxed"
                  style={{ 
                    color: colors.text.secondary,
                    fontFamily: typography.fontFamily.primary,
                  }}
                >
                  {getCharacterDescription(character.id)}
                </p>
              </div>
              
              {/* 初始數值 */}
              <div className="grid grid-cols-3 gap-4">
                <StatBox 
                  icon="❤️" 
                  label="聲望" 
                  value={character.stats.reputation} 
                  color={colors.semantic.danger}
                />
                <StatBox 
                  icon="🌟" 
                  label="影響力" 
                  value={character.stats.influence} 
                  color={colors.accent.gold}
                />
                <StatBox 
                  icon="💰" 
                  label="金幣" 
                  value={character.stats.gold} 
                  color={colors.accent.goldMuted}
                />
              </div>
            </div>
          </div>
          
          <DividerLine className="my-6" />
          
          {/* 專屬卡牌區 */}
          <div>
            <h3 
              className="text-xl font-bold mb-4 flex items-center gap-2"
              style={{ 
                color: colors.accent.gold,
                fontFamily: typography.fontFamily.primary,
              }}
            >
              <Star size={20} />
              專屬卡牌
              <span 
                className="text-sm opacity-60 font-normal"
                style={{ color: colors.text.secondary }}
              >
                Exclusive Cards
              </span>
            </h3>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {cards.map((card) => (
                <GameCard
                  key={card.id}
                  card={card}
                  size="md"
                  selectable={false}
                />
              ))}
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}

// 統計數值框
function StatBox({ 
  icon, 
  label, 
  value, 
  color 
}: { 
  icon: string; 
  label: string; 
  value: number; 
  color: string;
}) {
  return (
    <div 
      className="p-3 rounded-lg text-center"
      style={{
        background: `${color}15`,
        border: `1px solid ${color}40`,
      }}
    >
      <span className="text-2xl block mb-1">{icon}</span>
      <span 
        className="text-2xl font-bold block"
        style={{ color }}
      >
        {value}
      </span>
      <span 
        className="text-xs uppercase tracking-wider"
        style={{ color: colors.text.muted }}
      >
        {label}
      </span>
    </div>
  );
}

// 角色描述
function getCharacterDescription(id: string): string {
  const descriptions: Record<string, string> = {
    thomas: '工人湯瑪斯是勞工派的核心人物，代表著無數在工廠中辛勤工作的勞動者。他的卡牌設計強調團隊協作——「工人之怒」對資方有額外傷害，「團結一心」能強化所有勞工派盟友，而「苦情牌」則體現了工人階級的犧牲精神。',
    richard: '工廠主理查是資方派的領袖，精通金錢遊戲的藝術。他擁有全場最高的初始金幣，可以用「金錢攻勢」讓任何人閉嘴，「經濟威脅」的傷害隨財富增長，而「產業聯盟」則確保資方勢力團結一致。',
    edward: '記者愛德華是輿論場上的操控者，以筆為劍揭露真相。「獨家報導」能公開任何人的秘密任務，「深入調查」讓他掌握情報優勢，而當他收集足夠情報後，「輿論風暴」將造成毀滅性的傷害。',
    george: '盧德派喬治是激進的機器破壞者，他的策略是高風險高回報。「暴力抗議」造成全場最高傷害但也會自傷，「煽動群眾」讓全場陷入混亂，而「破壞機器」則專門針對工廠主理查——歷史的宿敵。',
  };
  return descriptions[id] || '';
}

// ═══════════════════════════════════════════════════════════
// 角色展示頁面主元件
// ═══════════════════════════════════════════════════════════

export function CharacterShowcase() {
  const [selectedCharacter, setSelectedCharacter] = useState<CharacterConfig | null>(null);
  
  const characterList = Object.values(characters);
  
  return (
    <div 
      className="min-h-screen w-full overflow-hidden relative"
      style={{ background: colors.background.primary }}
    >
      {/* 背景裝飾 */}
      <HexagonPattern className="opacity-30" />
      <AtmosphereParticles />
      
      {/* 頂部標題 */}
      <div className="relative z-10 text-center py-12">
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <div className="flex justify-center mb-4">
            <HexagonBadge className="w-20 h-20">
              <CrownIcon className="w-10 h-10" style={{ color: colors.accent.gold }} />
            </HexagonBadge>
          </div>
          
          <h1 
            className="text-4xl md:text-5xl font-bold mb-2"
            style={{ 
              color: colors.accent.gold,
              fontFamily: typography.fontFamily.primary,
              letterSpacing: '0.1em',
              textShadow: `0 0 30px ${colors.accent.gold}40`,
            }}
          >
            1812 國會風雲
          </h1>
          
          <p 
            className="text-lg opacity-70 mb-2"
            style={{ 
              color: colors.text.secondary,
              fontFamily: typography.fontFamily.primary,
            }}
          >
            Parliament Debates
          </p>
          
          <DividerLine className="max-w-xs mx-auto" />
          
          <p 
            className="mt-4 text-sm tracking-wider uppercase"
            style={{ color: colors.text.muted }}
          >
            MVP 角色陣容
          </p>
        </motion.div>
      </div>
      
      {/* 角色卡片網格 */}
      <div className="relative z-10 px-6 pb-12">
        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8 justify-items-center">
            {characterList.map((character, index) => (
              <motion.div
                key={character.id}
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.15, duration: 0.5 }}
              >
                <CharacterCard
                  character={character}
                  showStats={true}
                  size="md"
                  onClick={() => setSelectedCharacter(character)}
                />
                
                {/* 查看詳情提示 */}
                <motion.div 
                  className="mt-3 text-center"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: index * 0.15 + 0.3 }}
                >
                  <button
                    className="text-sm flex items-center gap-1 mx-auto transition-colors"
                    style={{ color: colors.text.muted }}
                    onClick={() => setSelectedCharacter(character)}
                  >
                    查看專屬卡牌
                    <ChevronRight size={14} />
                  </button>
                </motion.div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
      
      {/* 底部說明 */}
      <div className="relative z-10 text-center pb-12">
        <div 
          className="inline-block px-6 py-3 rounded-lg"
          style={{
            background: 'rgba(36, 27, 20, 0.8)',
            border: `1px solid ${colors.accent.gold}20`,
          }}
        >
          <p 
            className="text-sm italic"
            style={{ 
              color: colors.text.secondary,
              fontFamily: typography.fontFamily.primary,
            }}
          >
            「在攝政王的注視下，國會的權力鬥爭即將展開」
          </p>
        </div>
      </div>
      
      {/* 角色詳情彈窗 */}
      <AnimatePresence>
        {selectedCharacter && (
          <CharacterDetail
            character={selectedCharacter}
            cards={characterCards[selectedCharacter.id] || []}
            onClose={() => setSelectedCharacter(null)}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

export default CharacterShowcase;

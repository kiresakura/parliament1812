import { Crown, Copy, Check, Users, Play, ArrowLeft, Shield, Circle, CheckCircle, TrendingUp, Sparkles } from 'lucide-react';
import { useState } from 'react';
import { motion } from 'motion/react';
import { CornerFlourish, ParchmentTexture, AtmosphereParticles, DividerLine } from './VictorianOrnament';
import { HexagonPattern, HexagonBadge, DataPanel, GearIcon, hexagonStyles } from './HexagonPattern';
import character1 from 'figma:asset/edf26726be2cd4acfdf7a72337cbbc8f76a7a792.png';
import character2 from 'figma:asset/ee4612f93cae6c1e572501d5432f2b2bba87b575.png';
import character3 from 'figma:asset/90ef05fab51fb681b2cef00049389b2cdfe98871.png';
import character4 from 'figma:asset/52069e18a652bd94327acf496665283c6f10cd5c.png';
import character5 from 'figma:asset/98f1baa2f4e39cb54248d5b5c22e109498d0313d.png';

interface WaitingRoom1812Props {
  roomCode: string;
  onStartGame: () => void;
  onBack: () => void;
}

const mockPlayers = [
  { id: 1, nickname: 'Alex_Tw', name: '格雷伯爵', nameEn: 'Earl Grey', isHost: true, isReady: true, avatar: character1 },
  { id: 2, nickname: 'SarahH', name: '利物浦伯爵', nameEn: 'Lord Liverpool', isHost: false, isReady: true, avatar: character2 },
  { id: 3, nickname: 'Mike1812', name: '卡斯爾雷子爵', nameEn: 'Lord Castlereagh', isHost: false, isReady: true, avatar: character3 },
  { id: 4, nickname: 'Emma_W', name: '霍蘭勳爵', nameEn: 'Lord Holland', isHost: false, isReady: false, avatar: character4 },
  { id: 5, nickname: 'David_Law', name: '亨利·布魯厄姆', nameEn: 'Henry Brougham', isHost: false, isReady: true, avatar: character5 },
  { id: 6, nickname: 'James_P', name: '艾爾登勳爵', nameEn: 'Lord Eldon', isHost: false, isReady: false, avatar: character2 },
];

export function WaitingRoom1812({ roomCode, onStartGame, onBack }: WaitingRoom1812Props) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(roomCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const readyCount = mockPlayers.filter(p => p.isReady).length;
  const minPlayers = 5;
  const canStart = mockPlayers.length >= minPlayers && readyCount === mockPlayers.length;

  return (
    <div className="h-screen w-full bg-[#1a1614] flex flex-col overflow-hidden relative">
      <style>{hexagonStyles}</style>
      
      {/* Background Elements */}
      <HexagonPattern className="text-[#d4af37]" />
      <AtmosphereParticles />

      {/* Top Navigation Bar */}
      <div className="relative z-20 p-3 border-b flex items-center justify-between bg-[#1a1614]/95 backdrop-blur-sm border-[#d4af37]/30 shadow-lg">
        <motion.button
          onClick={onBack}
          className="text-[#d4af37] flex items-center gap-2 px-3 py-1.5 rounded border border-[#d4af37]/40 hover:border-[#d4af37] hover:bg-[#d4af37]/10 transition-all group"
          whileHover={{ x: -2 }}
        >
          <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-1" />
          <span className="text-sm font-serif tracking-wider">退出</span>
        </motion.button>

        <div className="flex items-center gap-4">
          <div className="hidden md:flex items-center gap-2 text-[#b8a07e] text-xs font-serif tracking-widest uppercase opacity-70">
            <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            連線穩定
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col lg:flex-row overflow-hidden relative z-10">
        
        {/* LEFT PANEL (Desktop) / TOP (Mobile) - Room Info */}
        <div className="w-full lg:w-96 flex-none bg-[#1a1614]/80 lg:bg-[#1a1614]/40 border-b lg:border-b-0 lg:border-r border-[#d4af37]/20 p-6 flex flex-col gap-6 overflow-y-auto lg:overflow-visible z-20 shadow-[0_4px_20px_rgba(0,0,0,0.4)] backdrop-blur-sm">
           
           {/* Room Ticket - Optimized Design */}
           <motion.div 
             initial={{ opacity: 0, y: 20 }}
             animate={{ opacity: 1, y: 0 }}
             className="relative group"
           >
             <div className="absolute inset-0 bg-[#d4af37] blur-lg opacity-5 group-hover:opacity-10 transition-opacity"></div>
             <div className="relative bg-[#1a1614] border-2 border-[#d4af37] p-1 rounded-sm shadow-2xl">
                {/* Inner Border */}
                <div className="border border-[#d4af37]/50 border-dashed p-4 flex flex-col items-center gap-3 relative overflow-hidden">
                    <ParchmentTexture />
                    
                    {/* Ticket Header */}
                    <div className="flex items-center gap-2 mb-1">
                        <Crown className="w-4 h-4 text-[#d4af37]" />
                        <span className="text-[#8b7753] text-[10px] uppercase tracking-[0.3em] font-serif">皇家通行證</span>
                        <Crown className="w-4 h-4 text-[#d4af37]" />
                    </div>

                    {/* Room Code */}
                    <div className="relative py-2 px-6 border-y border-[#d4af37]/30 w-full text-center bg-[#000]/20">
                        <span className="text-[#f5e6d3] text-4xl font-mono font-bold tracking-[0.2em] drop-shadow-[0_2px_4px_rgba(0,0,0,0.8)]">
                            {roomCode}
                        </span>
                    </div>

                    {/* Copy Button */}
                    <button 
                        onClick={handleCopy}
                        className="mt-1 flex items-center gap-2 text-[10px] text-[#d4af37] hover:text-[#f5e6d3] border border-[#d4af37]/30 hover:border-[#d4af37] px-4 py-1.5 rounded-full transition-all uppercase tracking-widest hover:bg-[#d4af37]/10"
                    >
                        {copied ? <Check className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
                        {copied ? '已複製' : '複製通行碼'}
                    </button>
                    
                    {/* Corner Cuts */}
                    <div className="absolute top-0 left-0 w-2 h-2 border-r border-b border-[#d4af37]/50" />
                    <div className="absolute top-0 right-0 w-2 h-2 border-l border-b border-[#d4af37]/50" />
                    <div className="absolute bottom-0 left-0 w-2 h-2 border-r border-t border-[#d4af37]/50" />
                    <div className="absolute bottom-0 right-0 w-2 h-2 border-l border-t border-[#d4af37]/50" />
                </div>
                
                {/* Ticket Notches */}
                <div className="absolute top-1/2 -left-1.5 w-3 h-3 rounded-full bg-[#1a1614] border-r-2 border-[#d4af37]" />
                <div className="absolute top-1/2 -right-1.5 w-3 h-3 rounded-full bg-[#1a1614] border-l-2 border-[#d4af37]" />
             </div>
           </motion.div>

           {/* Stats Panel */}
           <div className="grid grid-cols-2 gap-3">
             <div className="p-3 bg-[#000]/20 border border-[#d4af37]/20 rounded text-center">
               <div className="text-[#8b7753] text-[10px] uppercase tracking-wider mb-1">在席成員</div>
               <div className="text-[#d4af37] text-xl font-serif">{mockPlayers.length} <span className="text-xs opacity-50">/ 20</span></div>
             </div>
             <div className="p-3 bg-[#000]/20 border border-[#d4af37]/20 rounded text-center">
               <div className="text-[#8b7753] text-[10px] uppercase tracking-wider mb-1">準備就緒</div>
               <div className={`${readyCount === mockPlayers.length ? 'text-[#2d5a27]' : 'text-[#b8a07e]'} text-xl font-serif`}>
                 {readyCount} <span className="text-xs opacity-50">/ {mockPlayers.length}</span>
               </div>
             </div>
           </div>

           {/* Desktop Only: Flavor Text */}
           <div className="hidden lg:block mt-auto mb-4 text-center opacity-60">
             <DividerLine className="mb-4" />
             <p className="text-[#8b7753] text-xs italic font-serif leading-relaxed">
               "諸位，帝國的命運取決於我們的審議。<br/>請保持莊重。"
             </p>
           </div>

           {/* Desktop Start Button (Hidden on Mobile) */}
           <div className="hidden lg:block">
               <StartButton canStart={canStart} minPlayers={minPlayers} onStart={onStartGame} />
           </div>
        </div>

        {/* MAIN AREA - Player Grid */}
        <div className="flex-1 overflow-y-auto p-4 lg:p-8 scrollable bg-gradient-to-b from-transparent to-[#000]/20">
            <div className="max-w-6xl mx-auto pb-24 lg:pb-0"> {/* Padding bottom for mobile sticky footer */}
                
                {/* Section Header */}
                <div className="flex flex-col items-center justify-center gap-2 mb-8 opacity-90">
                    <h3 className="text-[#d4af37] font-serif text-2xl lg:text-3xl tracking-[0.1em] text-shadow-dark flex items-center gap-4">
                        <span className="h-px bg-[#d4af37]/50 w-12 hidden md:block"></span>
                        國會議員名單
                        <span className="h-px bg-[#d4af37]/50 w-12 hidden md:block"></span>
                    </h3>
                    <span className="text-[#8b7753] text-[10px] uppercase tracking-[0.4em] font-serif opacity-70">
                        Members of Parliament
                    </span>
                </div>
                
                <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 lg:gap-6">
                    {mockPlayers.map((player, index) => (
                        <motion.div
                          key={player.id}
                          initial={{ opacity: 0, scale: 0.9 }}
                          animate={{ opacity: 1, scale: 1 }}
                          transition={{ delay: index * 0.05 }}
                          className="group relative"
                        >
                          {/* Player Card Background */}
                          <div className={`relative overflow-hidden rounded border transition-all duration-300 ${
                              player.isHost 
                                ? 'bg-[#1a1614] border-[#d4af37]' 
                                : 'bg-[#1a1614]/80 border-[#d4af37]/30 hover:border-[#d4af37]/60'
                            }`}
                            style={{ boxShadow: '0 4px 12px rgba(0,0,0,0.4)' }}
                          >
                            <ParchmentTexture />
                            
                            {/* Decorative Corners */}
                            <div className="absolute top-0 left-0 w-4 h-4 border-t border-l border-[#d4af37]/40 rounded-tl" />
                            <div className="absolute top-0 right-0 w-4 h-4 border-t border-r border-[#d4af37]/40 rounded-tr" />
                            <div className="absolute bottom-0 left-0 w-4 h-4 border-b border-l border-[#d4af37]/40 rounded-bl" />
                            <div className="absolute bottom-0 right-0 w-4 h-4 border-b border-r border-[#d4af37]/40 rounded-br" />

                            <div className="p-4 flex flex-col items-center gap-3">
                                {/* Avatar Container */}
                                <div className="relative w-20 h-20">
                                    <div className="absolute inset-0 border-2 border-[#d4af37] rotate-45 opacity-20 scale-90 group-hover:rotate-90 transition-transform duration-700"></div>
                                    <div className={`w-full h-full rounded-full overflow-hidden border-2 shadow-inner ${
                                        player.isHost ? 'border-[#d4af37]' : 'border-[#8b7753]'
                                    }`}>
                                        <img src={player.avatar} alt={player.name} className="w-full h-full object-cover filter sepia-[0.3] contrast-110" />
                                    </div>
                                    {/* Status Badge */}
                                    <div className="absolute -bottom-1 -right-1">
                                        {player.isHost ? (
                                            <div className="bg-[#d4af37] text-[#1a1a2e] w-6 h-6 rounded-full flex items-center justify-center border border-[#fff]/20 shadow-md" title="Host">
                                                <Crown className="w-3.5 h-3.5" />
                                            </div>
                                        ) : player.isReady ? (
                                            <div className="bg-[#2d5a27] text-[#fff] w-6 h-6 rounded-full flex items-center justify-center border border-[#fff]/20 shadow-md" title="Ready">
                                                <Check className="w-3.5 h-3.5" />
                                            </div>
                                        ) : (
                                            <div className="bg-[#3d3d3d] text-[#8b8b8b] w-6 h-6 rounded-full flex items-center justify-center border border-[#fff]/10 shadow-md" title="Waiting">
                                                <div className="w-1.5 h-1.5 bg-current rounded-full" />
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {/* Text Info */}
                                <div className="text-center w-full">
                                    {/* Player Nickname */}
                                    <h4 className="text-[#f5e6d3] font-bold tracking-wide truncate text-sm md:text-base mb-1">
                                        {player.nickname}
                                    </h4>
                                    
                                    {/* Divider */}
                                    <div className="w-1/2 mx-auto h-px bg-[#d4af37]/30 mb-1"></div>

                                    {/* Character Role */}
                                    <p className="text-[#d4af37] text-xs font-serif truncate">
                                        {player.name}
                                    </p>
                                    <p className="text-[#8b7753] text-[10px] italic font-serif truncate opacity-80">
                                        {player.nameEn}
                                    </p>
                                </div>

                                {/* Status Label */}
                                <div className={`text-[10px] uppercase tracking-widest px-2 py-0.5 rounded border ${
                                    player.isHost 
                                        ? 'bg-[#d4af37]/10 border-[#d4af37]/40 text-[#d4af37]' 
                                        : player.isReady 
                                            ? 'bg-[#2d5a27]/10 border-[#2d5a27]/40 text-[#5c8a56]' 
                                            : 'bg-[#ffffff]/5 border-[#ffffff]/10 text-[#717171]'
                                }`}>
                                    {player.isHost ? '議長' : player.isReady ? '已就緒' : '準備中'}
                                </div>
                            </div>
                          </div>
                        </motion.div>
                    ))}
                    
                    {/* Empty Slots visualization */}
                    {[...Array(Math.max(0, 8 - mockPlayers.length))].map((_, i) => (
                        <div key={`empty-${i}`} className="border border-[#d4af37]/10 rounded bg-[#000]/10 p-4 flex flex-col items-center justify-center gap-2 min-h-[160px] opacity-30">
                            <div className="w-16 h-16 rounded-full border-2 border-dashed border-[#d4af37]/20 flex items-center justify-center">
                                <Users className="w-6 h-6 text-[#d4af37]/20" />
                            </div>
                            <div className="h-2 w-20 bg-[#d4af37]/10 rounded"></div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
      </div>

      {/* MOBILE STICKY FOOTER */}
      <div className="lg:hidden absolute bottom-0 left-0 right-0 p-4 bg-[#1a1614]/95 border-t border-[#d4af37]/30 z-30 backdrop-blur shadow-[0_-4px_20px_rgba(0,0,0,0.5)]">
        <StartButton canStart={canStart} minPlayers={minPlayers} onStart={onStartGame} />
      </div>

    </div>
  );
}

function StartButton({ canStart, minPlayers, onStart }: { canStart: boolean; minPlayers: number; onStart: () => void }) {
    return (
        <motion.button
            onClick={onStart}
            disabled={!canStart}
            whileHover={canStart ? { scale: 1.02 } : {}}
            whileTap={canStart ? { scale: 0.98 } : {}}
            className={`w-full py-4 relative overflow-hidden group border-2 transition-all ${
                canStart 
                    ? 'bg-[#1a1614] border-[#d4af37] text-[#d4af37] shadow-[0_0_20px_rgba(212,175,55,0.2)]' 
                    : 'bg-[#1a1614] border-[#8b7753]/30 text-[#8b7753]/50 cursor-not-allowed'
            }`}
        >
            {canStart && (
                <div className="absolute inset-0 bg-[#d4af37] opacity-0 group-hover:opacity-10 transition-opacity duration-500"></div>
            )}
            
            <div className="relative z-10 flex flex-col items-center justify-center">
                <div className="flex items-center gap-2">
                    <span className="text-lg font-serif tracking-[0.2em] uppercase font-bold">
                        {canStart ? '召開議會' : '等待成員'}
                    </span>
                    {canStart && <Play className="w-4 h-4 fill-current" />}
                </div>
                {!canStart && (
                    <span className="text-[10px] uppercase tracking-widest mt-1 opacity-70">
                        {`需 ${minPlayers} 人即可開始`}
                    </span>
                )}
            </div>

            {/* Ornamental Corners for Button */}
            <div className={`absolute top-0 left-0 w-3 h-3 border-t-2 border-l-2 transition-colors ${canStart ? 'border-[#d4af37]' : 'border-[#8b7753]/30'}`} />
            <div className={`absolute top-0 right-0 w-3 h-3 border-t-2 border-r-2 transition-colors ${canStart ? 'border-[#d4af37]' : 'border-[#8b7753]/30'}`} />
            <div className={`absolute bottom-0 left-0 w-3 h-3 border-b-2 border-l-2 transition-colors ${canStart ? 'border-[#d4af37]' : 'border-[#8b7753]/30'}`} />
            <div className={`absolute bottom-0 right-0 w-3 h-3 border-b-2 border-r-2 transition-colors ${canStart ? 'border-[#d4af37]' : 'border-[#8b7753]/30'}`} />
        </motion.button>
    );
}

function HexagonIcon({ className = "", filled = false }: { className?: string; filled?: boolean }) {
  return (
    <svg className={className} viewBox="0 0 100 100" fill={filled ? "currentColor" : "none"} stroke="currentColor" strokeWidth="4">
      <polygon points="50,5 90,27.5 90,72.5 50,95 10,72.5 10,27.5" />
    </svg>
  );
}

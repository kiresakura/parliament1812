import { Crown, Copy, Check, Users, Play, ArrowLeft, Shield } from 'lucide-react';
import { useState } from 'react';
import { motion } from 'motion/react';
import character1 from 'figma:asset/edf26726be2cd4acfdf7a72337cbbc8f76a7a792.png';
import character2 from 'figma:asset/ee4612f93cae6c1e572501d5432f2b2bba87b575.png';
import character3 from 'figma:asset/90ef05fab51fb681b2cef00049389b2cdfe98871.png';
import character4 from 'figma:asset/52069e18a652bd94327acf496665283c6f10cd5c.png';
import character5 from 'figma:asset/98f1baa2f4e39cb54248d5b5c22e109498d0313d.png';

interface WaitingRoomProps {
  roomCode: string;
  onStartGame: () => void;
  onBack: () => void;
}

const mockPlayers = [
  { id: 1, name: '威靈頓公爵', isHost: true, character: character5, title: 'Duke of Wellington', party: 'Tory' },
  { id: 2, name: '艾希福德女伯爵', isHost: false, character: character1, title: 'Countess of Ashford', party: 'Whig' },
  { id: 3, name: '埃德蒙爵士', isHost: false, character: character2, title: 'Sir Edmund', party: 'Tory' },
  { id: 4, name: '格雷男爵夫人', isHost: false, character: character3, title: 'Baroness Grey', party: 'Whig' },
  { id: 5, name: '議會議長', isHost: false, character: character4, title: 'Speaker of the House', party: 'Neutral' },
  { id: 6, name: '帕默斯頓子爵', isHost: false, character: character2, title: 'Viscount Palmerston', party: 'Whig' },
];

// Victorian Ornament Component
function VictorianDivider() {
  return (
    <div className="flex justify-center items-center gap-2 my-4">
      <div className="w-16 h-px bg-gradient-to-r from-transparent to-[#8b7753]"></div>
      <div className="w-2 h-2 bg-[#8b7753] transform rotate-45"></div>
      <div className="w-16 h-px bg-gradient-to-l from-transparent to-[#8b7753]"></div>
    </div>
  );
}

export function WaitingRoom({ roomCode, onStartGame, onBack }: WaitingRoomProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(roomCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="relative overflow-hidden">
      {/* Desktop: Two-column layout */}
      <div className="lg:grid lg:grid-cols-[2fr_3fr] lg:gap-6">
        {/* Left Column - Room Info (Desktop) / Top (Mobile) */}
        <div className="relative mb-4 lg:mb-0">
          {/* 羊皮纸卡片背景 */}
          <div className="absolute inset-0 rounded-lg"
               style={{
                 background: 'linear-gradient(135deg, #f5e6d3 0%, #e8d4bc 50%, #f0ddc5 100%)',
                 boxShadow: '0 10px 40px rgba(0, 0, 0, 0.3), inset 0 0 80px rgba(139, 119, 83, 0.1)',
               }}></div>
          
          {/* 英式装饰边框 */}
          <div className="absolute inset-0 rounded-lg pointer-events-none"
               style={{
                 border: '3px double rgba(139, 119, 83, 0.4)',
               }}></div>
          
          {/* 羊皮纸纹理 */}
          <div className="absolute inset-0 opacity-20 mix-blend-multiply rounded-lg"
               style={{
                 backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
               }}></div>
          
          <div className="relative p-6 lg:p-8">
            {/* Back button */}
            <button
              onClick={onBack}
              className="absolute top-4 left-4 text-[#5c4a33] opacity-60 hover:opacity-100 transition-opacity z-10"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>

            {/* Header */}
            <motion.div 
              className="text-center mb-6 pt-8 lg:pt-4"
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <div className="flex justify-center mb-3">
                <div className="w-16 h-16 rounded-full flex items-center justify-center"
                     style={{
                       background: 'linear-gradient(135deg, #d4af37, #b8941f)',
                       boxShadow: '0 4px 15px rgba(212, 175, 55, 0.4)',
                     }}>
                  <Users className="w-8 h-8 text-[#3d2817]" strokeWidth={1.5} />
                </div>
              </div>
              <h2 className="text-[#5c4a33] mb-2 text-xl lg:text-2xl" style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.1em' }}>
                等候大廳
              </h2>
              <p className="text-[#8b7753] text-xs opacity-70 italic" style={{ fontFamily: 'Georgia, serif' }}>
                Waiting Chamber
              </p>
              <div className="flex justify-center items-center gap-2 mt-4">
                <div className="w-12 h-px bg-[#8b7753]"></div>
                <Shield className="w-3 h-3 text-[#8b7753] opacity-50" />
                <div className="w-12 h-px bg-[#8b7753]"></div>
              </div>
            </motion.div>

            {/* Room Code Display - Royal Seal Style */}
            <motion.div 
              className="rounded-lg p-5 lg:p-6 mb-6 border-3 relative overflow-hidden"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2 }}
              style={{
                background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 50%, #d4af37 100%)',
                borderWidth: '3px',
                borderStyle: 'double',
                borderColor: '#8b7753',
                boxShadow: '0 6px 20px rgba(139, 119, 83, 0.5), inset 0 1px 3px rgba(255, 255, 255, 0.4)',
              }}
            >
              {/* 皇家徽章水印 */}
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 opacity-10">
                <Crown className="w-20 h-20 text-[#3d2817]" />
              </div>

              <p className="text-[#3d2817] opacity-80 text-sm text-center mb-2 relative z-10" style={{ fontFamily: 'Georgia, serif' }}>
                會議代碼
              </p>
              <p className="text-[#8b7753] text-[0.65rem] text-center mb-3 opacity-60 italic relative z-10" style={{ fontFamily: 'Georgia, serif' }}>
                Chamber Code
              </p>
              <div className="flex items-center justify-center gap-3 relative z-10">
                <span className="text-[#3d2817] tracking-widest" 
                      style={{ fontFamily: 'monospace', fontSize: '1.8rem', textShadow: '0 1px 2px rgba(255,255,255,0.4)' }}>
                  {roomCode}
                </span>
                <button
                  onClick={handleCopy}
                  className="text-[#3d2817] hover:text-[#5c4a33] transition-colors p-2 rounded hover:bg-white hover:bg-opacity-20"
                  title="複製代碼"
                >
                  {copied ? <Check className="w-5 h-5" /> : <Copy className="w-5 h-5" />}
                </button>
              </div>
            </motion.div>

            {/* Player count */}
            <div className="text-center">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border-2"
                   style={{
                     borderColor: '#8b7753',
                     background: 'rgba(139, 119, 83, 0.1)',
                   }}>
                <Users className="w-4 h-4 text-[#5c4a33]" />
                <span className="text-[#5c4a33] text-sm" style={{ fontFamily: 'Georgia, serif' }}>
                  {mockPlayers.length} / 12 位成員
                </span>
              </div>
            </div>

            {/* Start Game Button - Desktop only in left column */}
            <motion.button
              onClick={onStartGame}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="hidden lg:block w-full mt-6 py-5 rounded-lg transition-all duration-300"
              style={{ 
                fontFamily: 'Georgia, serif',
                letterSpacing: '0.08em',
                background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 50%, #d4af37 100%)',
                color: '#3d2817',
                boxShadow: '0 6px 20px rgba(139, 119, 83, 0.4), inset 0 1px 2px rgba(255, 255, 255, 0.3)',
              }}
            >
              <div className="flex items-center justify-center gap-2">
                <Play className="w-5 h-5" strokeWidth={2} />
                <span>開始辯論</span>
              </div>
            </motion.button>
          </div>
        </div>

        {/* Right Column - Player List (Desktop) / Bottom (Mobile) */}
        <div className="relative">
          {/* 羊皮纸卡片背景 */}
          <div className="absolute inset-0 rounded-lg"
               style={{
                 background: 'linear-gradient(135deg, #f5e6d3 0%, #e8d4bc 50%, #f0ddc5 100%)',
                 boxShadow: '0 10px 40px rgba(0, 0, 0, 0.3), inset 0 0 80px rgba(139, 119, 83, 0.1)',
               }}></div>
          
          {/* 英式装饰边框 */}
          <div className="absolute inset-0 rounded-lg pointer-events-none"
               style={{
                 border: '3px double rgba(139, 119, 83, 0.4)',
               }}></div>
          
          {/* 羊皮纸纹理 */}
          <div className="absolute inset-0 opacity-20 mix-blend-multiply rounded-lg"
               style={{
                 backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
               }}></div>
          
          <div className="relative p-6 lg:p-8">
            {/* Player List Header */}
            <div className="mb-5">
              <h3 className="text-[#5c4a33] text-center mb-1 text-sm lg:text-base" 
                  style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.08em' }}>
                在場成員
              </h3>
              <p className="text-[#8b7753] text-xs text-center opacity-60 italic" style={{ fontFamily: 'Georgia, serif' }}>
                Members Present
              </p>
              <div className="w-24 h-px bg-[#8b7753] mx-auto mt-3 opacity-50"></div>
            </div>

            {/* Player List with Character Portraits */}
            <div className="space-y-3 lg:grid lg:grid-cols-2 lg:gap-3 lg:space-y-0">
              {mockPlayers.map((player, index) => (
                <motion.div
                  key={player.id}
                  className="rounded-md p-3 flex items-center gap-3 border-2 relative overflow-hidden"
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.3 + index * 0.1 }}
                  style={{
                    background: 'linear-gradient(135deg, #faf6ef 0%, #f0e6d8 100%)',
                    borderColor: player.isHost ? '#d4af37' : 'rgba(139, 119, 83, 0.3)',
                    borderWidth: player.isHost ? '2px' : '2px',
                    boxShadow: player.isHost 
                      ? '0 3px 12px rgba(212, 175, 55, 0.3)'
                      : '0 2px 8px rgba(139, 119, 83, 0.2)',
                  }}
                >
                  {/* 主持人特殊背景 */}
                  {player.isHost && (
                    <div className="absolute inset-0 opacity-5"
                         style={{ background: 'linear-gradient(135deg, #d4af37, #b8941f)' }}></div>
                  )}

                  {/* 羊皮纸纹理 */}
                  <div className="absolute inset-0 opacity-10 mix-blend-multiply"
                       style={{
                         backgroundImage: 'repeating-linear-gradient(90deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
                       }}></div>
                  
                  {/* Character Portrait with ornate frame */}
                  <div className="relative flex-shrink-0">
                    <div className="w-16 h-16 lg:w-14 lg:h-14 rounded-full overflow-hidden border-3"
                         style={{ 
                           borderColor: player.isHost ? '#d4af37' : '#8b7753',
                           borderWidth: '3px',
                           boxShadow: player.isHost 
                             ? '0 2px 10px rgba(212, 175, 55, 0.5)' 
                             : '0 2px 8px rgba(139, 119, 83, 0.3)',
                         }}>
                      <img 
                        src={player.character} 
                        alt={player.name}
                        className="w-full h-full object-cover"
                        style={{ objectPosition: 'center 20%' }}
                      />
                    </div>
                    {/* 装饰性角标 */}
                    {player.isHost && (
                      <div className="absolute -top-1 -right-1 w-5 h-5 rounded-full flex items-center justify-center"
                           style={{ background: 'linear-gradient(135deg, #d4af37, #b8941f)' }}>
                        <Crown className="w-3 h-3 text-[#3d2817]" />
                      </div>
                    )}
                  </div>

                  <div className="flex-1 min-w-0 relative z-10">
                    <p className="text-[#5c4a33] truncate" style={{ fontFamily: 'Georgia, serif' }}>
                      {player.name}
                    </p>
                    <p className="text-[#8b7753] text-xs opacity-70 italic truncate" style={{ fontFamily: 'Georgia, serif' }}>
                      {player.title}
                    </p>
                  </div>

                  {player.isHost && (
                    <div className="flex items-center gap-1 px-2 py-1 rounded relative z-10"
                         style={{ background: 'linear-gradient(135deg, #d4af37, #b8941f)' }}>
                      <span className="text-[#3d2817] text-xs" style={{ fontFamily: 'Georgia, serif' }}>主持</span>
                    </div>
                  )}
                </motion.div>
              ))}
            </div>

            {/* Start Game Button - Mobile only at bottom */}
            <motion.button
              onClick={onStartGame}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="lg:hidden w-full mt-6 py-5 rounded-lg transition-all duration-300"
              style={{ 
                fontFamily: 'Georgia, serif',
                letterSpacing: '0.08em',
                background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 50%, #d4af37 100%)',
                color: '#3d2817',
                boxShadow: '0 6px 20px rgba(139, 119, 83, 0.4), inset 0 1px 2px rgba(255, 255, 255, 0.3)',
              }}
            >
              <div className="flex items-center justify-center gap-2">
                <Play className="w-5 h-5" strokeWidth={2} />
                <span>開始辯論</span>
              </div>
            </motion.button>

            {/* Decorative footer */}
            <div className="mt-6 text-center">
              <p className="text-[#8b7753] opacity-60 text-xs italic" style={{ fontFamily: 'Georgia, serif' }}>
                「議事廳內，請保持肅靜」
              </p>
              <p className="text-[#8b7753] opacity-50 text-[0.65rem] mt-1" style={{ fontFamily: 'Georgia, serif' }}>
                "Order, order in the House"
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
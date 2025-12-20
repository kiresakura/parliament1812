import { useState } from 'react';
import { motion } from 'motion/react';
import { Users, Clock, Globe } from 'lucide-react';
import { CornerFlourish, DividerLine, CrownIcon, AtmosphereParticles } from './VictorianOrnament';
import { HexagonPattern, HexagonBadge, DataPanel, GearIcon, hexagonStyles } from './HexagonPattern';
import parliamentImage from 'figma:asset/dc70d59f64d5b8ff9b2c9149edc695e285b421e7.png';

interface HomeScreen1812Props {
  onCreateRoom: (nickname: string) => void;
  onJoinRoom: (nickname: string, code: string) => void;
}

export function HomeScreen1812({ onCreateRoom, onJoinRoom }: HomeScreen1812Props) {
  const [mode, setMode] = useState<'create' | 'join'>('create');
  const [nickname, setNickname] = useState('');
  const [roomCode, setRoomCode] = useState('');

  const handleSubmit = () => {
    if (!nickname.trim()) {
      alert('請輸入您的暱稱 / Please enter your nickname');
      return;
    }

    if (mode === 'create') {
      onCreateRoom(nickname.trim());
    } else {
      if (!roomCode.trim()) {
        alert('請輸入房間代碼 / Please enter room code');
        return;
      }
      onJoinRoom(nickname.trim(), roomCode.trim().toUpperCase());
    }
  };

  return (
    <div className="h-screen w-full overflow-hidden relative bg-[#1a1614] flex flex-col">
      <style>{hexagonStyles}</style>

      {/* Hexagon pattern background (Civ 6 style) */}
      <HexagonPattern className="text-[#d4af37]" />
      <AtmosphereParticles />

      {/* Parliament chamber background - dimmed */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 opacity-15">
          <img 
            src={parliamentImage} 
            alt="Parliament Chamber" 
            className="w-full h-full object-cover"
            style={{ filter: 'grayscale(100%) contrast(1.2)' }}
          />
        </div>
        {/* Vignette */}
        <div className="absolute inset-0 bg-gradient-radial from-transparent via-transparent to-[#1a1614] opacity-80"></div>
      </div>

      {/* Top Stats Bar (Victoria 3 style) */}
      <motion.div 
        className="relative z-10 p-3 border-b"
        initial={{ y: -50, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        style={{
          background: 'rgba(36, 27, 20, 0.95)',
          borderColor: 'rgba(212, 175, 55, 0.3)',
          boxShadow: '0 2px 8px rgba(0, 0, 0, 0.5)',
        }}
      >
        <div className="flex flex-col md:flex-row items-center justify-between max-w-6xl mx-auto gap-4 md:gap-0">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full flex items-center justify-center"
                 style={{ background: 'rgba(212, 175, 55, 0.2)', border: '2px solid #d4af37' }}>
              <CrownIcon className="w-5 h-5 text-[#d4af37]" />
            </div>
            <div>
              <div className="text-[#d4af37] text-sm tracking-wider" style={{ fontFamily: 'Georgia, serif' }}>
                REGENCY ERA
              </div>
              <div className="text-[#8b7753] text-xs" style={{ fontFamily: 'Georgia, serif' }}>
                1812 • British Parliament
              </div>
            </div>
          </div>

          <div className="flex items-center gap-4 w-full md:w-auto justify-between md:justify-end">
            <DataPanel
              title="玩家在線"
              value="847"
              icon={<Users className="w-4 h-4 text-[#d4af37]" />}
              trend="up"
              className="flex-1 md:flex-none"
            />
            <DataPanel
              title="活躍房間"
              value="23"
              icon={<Globe className="w-4 h-4 text-[#d4af37]" />}
              trend="neutral"
              className="flex-1 md:flex-none"
            />
          </div>
        </div>
      </motion.div>

      {/* Main Content - Perfectly centered */}
      <div className="relative z-10 flex-1 overflow-y-auto">
        <div className="min-h-full flex items-center justify-center p-6">
          <div className="w-full max-w-md">
            {/* Title Section */}
            <motion.div 
              className="text-center mb-8"
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
            >
              {/* Hexagon badge with crown */}
              <div className="flex justify-center mb-4">
                <HexagonBadge className="w-20 h-20">
                  <CrownIcon className="w-10 h-10 text-[#d4af37]" />
                </HexagonBadge>
              </div>

              {/* Main title with gears */}
              <div className="relative inline-block mb-4">
                {/* Decorative gears */}
                <GearIcon className="hidden sm:block absolute -left-12 top-1/2 -translate-y-1/2 w-8 h-8 text-[#8b7753] opacity-30" spinning />
                <GearIcon className="hidden sm:block absolute -right-12 top-1/2 -translate-y-1/2 w-8 h-8 text-[#8b7753] opacity-30" spinning />
                
                <h1 className="text-4xl sm:text-5xl md:text-7xl mb-2 relative"
                    style={{
                      fontFamily: 'Georgia, Times New Roman, serif',
                      color: '#d4af37',
                      letterSpacing: '0.2em',
                      textShadow: '0 0 30px rgba(212, 175, 55, 0.4), 0 4px 8px rgba(0, 0, 0, 0.9)',
                    }}>
                  1812
                </h1>
              </div>

            {/* Chinese subtitle */}
            <h2 className="text-2xl md:text-3xl mb-2"
                style={{
                  fontFamily: 'Georgia, serif',
                  color: '#b8a07e',
                  letterSpacing: '0.3em',
                  textShadow: '0 2px 4px rgba(0, 0, 0, 0.9)',
                }}>
              國會風雲
            </h2>

            {/* English subtitle */}
            <p className="text-xs md:text-sm uppercase tracking-[0.3em] opacity-60 mb-6 text-[#8b7753]"
               style={{
                 fontFamily: 'Georgia, serif',
                 textShadow: '0 1px 2px rgba(0, 0, 0, 0.8)',
               }}>
              Parliament Debates
            </p>

            <DividerLine />
          </motion.div>

          {/* Mode Toggle with Hexagons */}
          <motion.div 
            className="mb-6 grid grid-cols-2 gap-3"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            <button
              onClick={() => setMode('create')}
              className={`relative py-4 px-4 border-2 transition-all duration-300 overflow-hidden ${
                mode === 'create'
                  ? 'bg-[#d4af37] border-[#d4af37] text-[#1a1a2e]'
                  : 'bg-transparent border-[#d4af37] text-[#d4af37]'
              }`}
              style={{
                clipPath: 'polygon(10% 0%, 100% 0%, 90% 100%, 0% 100%)',
                boxShadow: mode === 'create' ? '0 4px 16px rgba(212, 175, 55, 0.4)' : 'none',
              }}
            >
              {/* Hexagon decoration */}
              <div className="absolute top-1 right-1 w-6 h-6 opacity-30">
                <HexagonIcon className="w-full h-full" filled={mode === 'create'} />
              </div>

              <div className="relative z-10" style={{ fontFamily: 'Georgia, serif' }}>
                <div className="text-sm font-bold">建立房間</div>
                <div className="text-xs opacity-70 uppercase" style={{ letterSpacing: '0.05em' }}>Create</div>
              </div>
            </button>

            <button
              onClick={() => setMode('join')}
              className={`relative py-4 px-4 border-2 transition-all duration-300 overflow-hidden ${
                mode === 'join'
                  ? 'bg-[#d4af37] border-[#d4af37] text-[#1a1a2e]'
                  : 'bg-transparent border-[#d4af37] text-[#d4af37]'
              }`}
              style={{
                clipPath: 'polygon(0% 0%, 90% 0%, 100% 100%, 10% 100%)',
                boxShadow: mode === 'join' ? '0 4px 16px rgba(212, 175, 55, 0.4)' : 'none',
              }}
            >
              <div className="absolute top-1 left-1 w-6 h-6 opacity-30">
                <HexagonIcon className="w-full h-full" filled={mode === 'join'} />
              </div>

              <div className="relative z-10" style={{ fontFamily: 'Georgia, serif' }}>
                <div className="text-sm font-bold">加入房間</div>
                <div className="text-xs opacity-70 uppercase" style={{ letterSpacing: '0.05em' }}>Join</div>
              </div>
            </button>
          </motion.div>

          {/* Input Fields */}
          <motion.div 
            className="space-y-4"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.6 }}
          >
            {/* Nickname Input */}
            <div className="relative">
              <label className="block text-[#b8a07e] text-sm mb-2"
                     style={{ fontFamily: 'Georgia, serif' }}>
                <span className="inline-flex items-center gap-2">
                  <HexagonIcon className="w-4 h-4 inline" />
                  您的暱稱 <span className="text-xs opacity-70">Your Nickname</span>
                </span>
              </label>
              <div className="relative">
                <input
                  type="text"
                  value={nickname}
                  onChange={(e) => setNickname(e.target.value)}
                  placeholder="輸入暱稱..."
                  maxLength={20}
                  className="w-full py-3 px-4 pr-10 border-2 focus:outline-none transition-all"
                  style={{
                    background: 'rgba(36, 27, 20, 0.8)',
                    borderColor: '#d4af37',
                    color: '#f5e6d3',
                    fontFamily: 'Georgia, serif',
                    clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%)',
                    boxShadow: '0 2px 8px rgba(0, 0, 0, 0.3)',
                  }}
                />
                <GearIcon className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-[#8b7753] opacity-40" />
              </div>
            </div>

            {/* Room Code Input - Conditional */}
            {mode === 'join' && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="relative"
              >
                <label className="block text-[#b8a07e] text-sm mb-2"
                       style={{ fontFamily: 'Georgia, serif' }}>
                  <span className="inline-flex items-center gap-2">
                    <HexagonIcon className="w-4 h-4 inline" />
                    房間代碼 <span className="text-xs opacity-70">Room Code</span>
                  </span>
                </label>
                <input
                  type="text"
                  value={roomCode}
                  onChange={(e) => setRoomCode(e.target.value.toUpperCase())}
                  placeholder="XXXXXX"
                  maxLength={6}
                  className="w-full py-3 px-4 border-2 focus:outline-none transition-all text-center tracking-widest"
                  style={{
                    background: 'rgba(36, 27, 20, 0.8)',
                    borderColor: '#d4af37',
                    color: '#f5e6d3',
                    fontFamily: 'monospace',
                    fontSize: '1.5rem',
                    clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%)',
                    boxShadow: '0 2px 8px rgba(0, 0, 0, 0.3)',
                  }}
                />
              </motion.div>
            )}

            {/* Submit Button */}
            <motion.button
              onClick={handleSubmit}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="w-full py-4 relative overflow-hidden"
              style={{
                background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 100%)',
                color: '#1a1a2e',
                fontFamily: 'Georgia, serif',
                fontSize: '1.1rem',
                letterSpacing: '0.15em',
                clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%)',
                boxShadow: '0 6px 20px rgba(212, 175, 55, 0.4)',
                border: '2px solid rgba(255, 255, 255, 0.3)',
              }}
            >
              {/* Animated shine */}
              <motion.div
                className="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-20"
                animate={{ x: ['-200%', '200%'] }}
                transition={{ duration: 3, repeat: Infinity, repeatDelay: 1 }}
              ></motion.div>

              <span className="relative z-10 flex items-center justify-center gap-2">
                <HexagonIcon className="w-5 h-5" filled />
                {mode === 'create' ? '建立新會議' : '進入議事廳'}
              </span>
            </motion.button>
          </motion.div>

          {/* Atmospheric Tagline */}
          <motion.div 
            className="mt-6 text-center"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1, delay: 0.8 }}
          >
            <div className="inline-block p-3 rounded border relative"
                 style={{
                   background: 'rgba(36, 27, 20, 0.6)',
                   borderColor: 'rgba(139, 119, 83, 0.3)',
                 }}>
              <Clock className="w-4 h-4 text-[#8b7753] absolute top-2 left-2 opacity-40" />
              
              <p className="text-[#b8a07e] text-sm italic leading-relaxed"
                 style={{ fontFamily: 'Georgia, serif' }}>
                「在攝政王的注視下，國會的權力鬥爭即將展開」
              </p>

              <p className="text-[#8b7753] text-xs mt-1 opacity-70"
                 style={{ fontFamily: 'Georgia, serif' }}>
                Under the Prince Regent's gaze...
              </p>
            </div>
          </motion.div>
        </div>
      </div>
    </div>

      <style>{`
        .bg-gradient-radial {
          background: radial-gradient(circle, var(--tw-gradient-stops));
        }
        input::placeholder {
          color: #8b8b8b;
        }
      `}</style>
    </div>
  );
}

function HexagonIcon({ className = "", filled = false }: { className?: string; filled?: boolean }) {
  return (
    <svg className={className} viewBox="0 0 100 100" fill={filled ? "currentColor" : "none"} stroke="currentColor" strokeWidth="4">
      <polygon points="50,5 90,27.5 90,72.5 50,95 10,72.5 10,27.5" />
    </svg>
  );
}

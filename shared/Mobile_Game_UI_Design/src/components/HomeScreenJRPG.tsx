import { useState } from 'react';
import { motion } from 'motion/react';
import character5 from 'figma:asset/98f1baa2f4e39cb54248d5b5c22e109498d0313d.png';
import parliamentImage from 'figma:asset/dc70d59f64d5b8ff9b2c9149edc695e285b421e7.png';

interface HomeScreenJRPGProps {
  onCreateRoom: () => void;
  onJoinRoom: (code: string) => void;
}

// Victorian Ornament Component
function VictorianOrnament({ className = "", flip = false }: { className?: string; flip?: boolean }) {
  return (
    <svg className={className} viewBox="0 0 200 40" fill="currentColor" style={{ transform: flip ? 'scaleX(-1)' : 'none' }}>
      <path d="M0,20 Q20,10 40,20 T80,20 Q85,15 90,20 Q95,25 100,20 Q120,10 140,20 T180,20 Q190,15 200,20" 
            stroke="currentColor" strokeWidth="1" fill="none" opacity="0.6"/>
      <circle cx="100" cy="20" r="3" opacity="0.8"/>
      <path d="M90,20 L92,15 L94,20 L92,25 Z" opacity="0.6"/>
      <path d="M106,20 L108,15 L110,20 L108,25 Z" opacity="0.6"/>
    </svg>
  );
}

export function HomeScreenJRPG({ onCreateRoom, onJoinRoom }: HomeScreenJRPGProps) {
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [joinCode, setJoinCode] = useState('');

  const handleJoinSubmit = () => {
    if (joinCode.trim()) {
      onJoinRoom(joinCode.trim().toUpperCase());
    }
  };

  return (
    <div className="min-h-screen w-full overflow-hidden relative"
         style={{
           background: 'linear-gradient(135deg, #2d1810 0%, #3d2817 30%, #2d1810 60%, #1a0f08 100%)',
         }}>
      {/* Victorian wallpaper pattern background */}
      <div className="absolute inset-0 opacity-15"
           style={{
             backgroundImage: `
               radial-gradient(circle at 20% 30%, rgba(212, 175, 55, 0.3) 0%, transparent 3%),
               radial-gradient(circle at 60% 70%, rgba(212, 175, 55, 0.2) 0%, transparent 3%),
               radial-gradient(circle at 40% 50%, rgba(212, 175, 55, 0.25) 0%, transparent 3%)
             `,
             backgroundSize: '80px 80px',
           }}></div>

      {/* Damask pattern overlay */}
      <div className="absolute inset-0 opacity-10 mix-blend-overlay"
           style={{
             backgroundImage: `repeating-linear-gradient(
               45deg,
               transparent,
               transparent 20px,
               rgba(139, 119, 83, 0.3) 20px,
               rgba(139, 119, 83, 0.3) 40px,
               transparent 40px,
               transparent 60px,
               rgba(139, 119, 83, 0.2) 60px,
               rgba(139, 119, 83, 0.2) 80px
             )`,
           }}></div>

      {/* Vignette effect */}
      <div className="absolute inset-0 bg-gradient-radial from-transparent via-transparent to-black opacity-60"></div>

      {/* Parliament chamber - styled as Victorian engraving */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 opacity-20">
          <img 
            src={parliamentImage} 
            alt="Parliament" 
            className="w-full h-full object-cover"
            style={{ 
              filter: 'grayscale(100%) contrast(1.8) brightness(0.3)',
              mixBlendMode: 'luminosity',
            }}
          />
        </div>
        
        {/* Engraving crosshatch effect */}
        <div className="absolute inset-0 opacity-30"
             style={{
               backgroundImage: `
                 repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.4) 2px, rgba(0,0,0,0.4) 3px),
                 repeating-linear-gradient(90deg, transparent, transparent 2px, rgba(0,0,0,0.4) 2px, rgba(0,0,0,0.4) 3px)
               `,
               backgroundSize: '6px 6px',
             }}></div>
      </div>

      {/* Victorian decorative corner flourishes */}
      <div className="absolute top-0 left-0 w-32 h-32 pointer-events-none">
        <svg viewBox="0 0 100 100" className="w-full h-full text-[#d4af37] opacity-40">
          <path d="M0,0 L40,0 Q35,5 30,10 L20,20 Q10,25 0,30 Z" fill="currentColor"/>
          <path d="M0,0 L0,40 Q5,35 10,30 L20,20 Q25,10 30,0 Z" fill="currentColor"/>
          <circle cx="15" cy="15" r="3" fill="currentColor"/>
        </svg>
      </div>
      
      <div className="absolute top-0 right-0 w-32 h-32 pointer-events-none transform scale-x-[-1]">
        <svg viewBox="0 0 100 100" className="w-full h-full text-[#d4af37] opacity-40">
          <path d="M0,0 L40,0 Q35,5 30,10 L20,20 Q10,25 0,30 Z" fill="currentColor"/>
          <path d="M0,0 L0,40 Q5,35 10,30 L20,20 Q25,10 30,0 Z" fill="currentColor"/>
          <circle cx="15" cy="15" r="3" fill="currentColor"/>
        </svg>
      </div>

      {/* Main Content Container */}
      <div className="relative z-10 min-h-screen flex flex-col p-4">
        {/* Victorian ornate header frame */}
        <motion.div
          className="mt-4 mb-6"
          initial={{ y: -50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8 }}
        >
          {/* Top decorative border */}
          <div className="flex items-center justify-center mb-3">
            <VictorianOrnament className="w-32 h-8 text-[#d4af37] opacity-70" />
            <div className="mx-3 flex flex-col items-center">
              <div className="w-12 h-12 rounded-full border-2 border-[#d4af37] flex items-center justify-center bg-gradient-radial from-[#3d2817] to-[#2d1810]"
                   style={{ boxShadow: '0 0 20px rgba(212, 175, 55, 0.4), inset 0 2px 8px rgba(0,0,0,0.6)' }}>
                <svg viewBox="0 0 24 24" className="w-6 h-6 text-[#d4af37]" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 2L15 8L22 9L17 14L18 21L12 18L6 21L7 14L2 9L9 8L12 2Z"/>
                </svg>
              </div>
              <div className="h-6 w-px bg-gradient-to-b from-[#d4af37] to-transparent mt-1"></div>
            </div>
            <VictorianOrnament className="w-32 h-8 text-[#d4af37] opacity-70" flip />
          </div>

          {/* Title with Victorian typography */}
          <div className="text-center relative">
            {/* Decorative banner */}
            <div className="absolute inset-0 -z-10 flex items-center justify-center">
              <div className="w-[85%] h-24 opacity-20"
                   style={{
                     background: 'linear-gradient(90deg, transparent, rgba(212,175,55,0.3) 20%, rgba(212,175,55,0.3) 80%, transparent)',
                     clipPath: 'polygon(5% 0%, 95% 0%, 100% 50%, 95% 100%, 5% 100%, 0% 50%)',
                   }}></div>
            </div>

            <h1 
              className="text-5xl mb-1 relative"
              style={{
                fontFamily: 'Times New Roman, Georgia, serif',
                color: '#d4af37',
                letterSpacing: '0.2em',
                textShadow: '0 2px 4px rgba(0,0,0,0.8), 0 0 20px rgba(212,175,55,0.4)',
              }}
            >
              1812
            </h1>
            
            <div className="flex justify-center items-center gap-2 my-2">
              <div className="w-16 h-px bg-gradient-to-r from-transparent to-[#8b7753]"></div>
              <div className="w-1.5 h-1.5 bg-[#8b7753] transform rotate-45"></div>
              <div className="w-16 h-px bg-gradient-to-l from-transparent to-[#8b7753]"></div>
            </div>
            
            <h2 
              className="text-2xl mb-2"
              style={{
                fontFamily: 'Times New Roman, Georgia, serif',
                color: '#c9a961',
                letterSpacing: '0.3em',
                textShadow: '0 1px 3px rgba(0,0,0,0.8)',
              }}
            >
              PARLIAMENT
            </h2>
            
            <p className="text-[#8b7753] text-sm italic tracking-wider"
               style={{ fontFamily: 'Georgia, serif' }}>
              議會辯論遊戲
            </p>
          </div>

          {/* Bottom decorative border */}
          <div className="flex items-center justify-center mt-3">
            <VictorianOrnament className="w-32 h-8 text-[#8b7753] opacity-50" />
            <div className="mx-3 w-2 h-2 bg-[#8b7753] rounded-full opacity-50"></div>
            <VictorianOrnament className="w-32 h-8 text-[#8b7753] opacity-50" flip />
          </div>
        </motion.div>

        {/* Character Portrait with Victorian Frame */}
        <motion.div
          className="flex-1 relative mb-6"
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, delay: 0.3 }}
        >
          {/* Victorian photo frame */}
          <div className="absolute inset-0 -m-4 pointer-events-none z-20">
            {/* Ornate frame corners */}
            <div className="absolute top-0 left-0 w-20 h-20">
              <svg viewBox="0 0 100 100" className="w-full h-full text-[#d4af37]">
                <path d="M0,20 L20,0 L80,0 L80,5 L25,5 L5,25 L5,80 L0,80 Z" fill="currentColor" opacity="0.8"/>
                <path d="M10,10 Q15,8 20,10 L20,15 Q15,13 10,15 Z" fill="currentColor"/>
              </svg>
            </div>
            <div className="absolute top-0 right-0 w-20 h-20 transform scale-x-[-1]">
              <svg viewBox="0 0 100 100" className="w-full h-full text-[#d4af37]">
                <path d="M0,20 L20,0 L80,0 L80,5 L25,5 L5,25 L5,80 L0,80 Z" fill="currentColor" opacity="0.8"/>
                <path d="M10,10 Q15,8 20,10 L20,15 Q15,13 10,15 Z" fill="currentColor"/>
              </svg>
            </div>
            <div className="absolute bottom-0 left-0 w-20 h-20 transform scale-y-[-1]">
              <svg viewBox="0 0 100 100" className="w-full h-full text-[#d4af37]">
                <path d="M0,20 L20,0 L80,0 L80,5 L25,5 L5,25 L5,80 L0,80 Z" fill="currentColor" opacity="0.8"/>
                <path d="M10,10 Q15,8 20,10 L20,15 Q15,13 10,15 Z" fill="currentColor"/>
              </svg>
            </div>
            <div className="absolute bottom-0 right-0 w-20 h-20 transform scale-[-1]">
              <svg viewBox="0 0 100 100" className="w-full h-full text-[#d4af37]">
                <path d="M0,20 L20,0 L80,0 L80,5 L25,5 L5,25 L5,80 L0,80 Z" fill="currentColor" opacity="0.8"/>
                <path d="M10,10 Q15,8 20,10 L20,15 Q15,13 10,15 Z" fill="currentColor"/>
              </svg>
            </div>
          </div>

          {/* Inner frame border */}
          <div className="absolute inset-0 border-4 border-[#8b7753] z-10"
               style={{ 
                 boxShadow: 'inset 0 0 20px rgba(0,0,0,0.6), 0 4px 20px rgba(0,0,0,0.8)',
               }}></div>

          {/* Character image */}
          <div className="relative h-96 overflow-hidden bg-gradient-to-b from-[#3d2817] to-[#2d1810]">
            <img 
              src={character5} 
              alt="British MP Character"
              className="w-full h-full object-contain object-bottom"
              style={{ 
                filter: 'sepia(0.15) contrast(1.1) brightness(0.95)',
              }}
            />
            
            {/* Victorian photo vignette */}
            <div className="absolute inset-0 pointer-events-none"
                 style={{
                   background: 'radial-gradient(ellipse at center, transparent 30%, rgba(45, 24, 16, 0.6) 70%, rgba(45, 24, 16, 0.9) 100%)',
                 }}></div>
          </div>

          {/* Character nameplate - Victorian style */}
          <div className="absolute -bottom-6 left-1/2 transform -translate-x-1/2 z-30">
            <div className="relative px-8 py-3"
                 style={{
                   background: 'linear-gradient(135deg, #2d1810 0%, #3d2817 50%, #2d1810 100%)',
                   border: '2px solid #d4af37',
                   boxShadow: '0 4px 16px rgba(0,0,0,0.8), inset 0 1px 2px rgba(212,175,55,0.3)',
                   clipPath: 'polygon(8% 0%, 92% 0%, 100% 50%, 92% 100%, 8% 100%, 0% 50%)',
                 }}>
              <p className="text-[#d4af37] text-sm tracking-widest text-center whitespace-nowrap"
                 style={{ fontFamily: 'Georgia, serif' }}>
                威靈頓公爵
              </p>
            </div>
          </div>
        </motion.div>

        {/* Victorian Button Panel */}
        <motion.div
          className="space-y-4"
          initial={{ y: 50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.6 }}
        >
          {/* Primary Button - Victorian Brass Plate */}
          <motion.button
            onClick={onCreateRoom}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="w-full relative"
          >
            <div className="relative px-6 py-5 overflow-hidden"
                 style={{
                   background: 'linear-gradient(135deg, #8b4513 0%, #654321 50%, #8b4513 100%)',
                   border: '3px solid #d4af37',
                   boxShadow: '0 6px 20px rgba(0,0,0,0.8), inset 0 2px 4px rgba(212,175,55,0.3), inset 0 -2px 4px rgba(0,0,0,0.6)',
                 }}>
              {/* Wood grain texture */}
              <div className="absolute inset-0 opacity-20 mix-blend-overlay"
                   style={{
                     backgroundImage: 'repeating-linear-gradient(90deg, transparent, transparent 3px, rgba(139,119,83,0.3) 3px, rgba(139,119,83,0.3) 6px)',
                   }}></div>

              {/* Victorian engraving pattern */}
              <div className="absolute top-2 left-2 right-2 bottom-2 border border-[#d4af37] opacity-30 pointer-events-none"></div>

              <div className="relative z-10 flex items-center justify-center gap-3">
                <svg viewBox="0 0 24 24" className="w-6 h-6 text-[#d4af37]" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 2L15 8L22 9L17 14L18 21L12 18L6 21L7 14L2 9L9 8L12 2Z"/>
                </svg>
                <span 
                  className="text-[#d4af37] text-xl tracking-widest"
                  style={{
                    fontFamily: 'Georgia, serif',
                    textShadow: '0 1px 2px rgba(0,0,0,0.8), 0 0 10px rgba(212,175,55,0.3)',
                  }}
                >
                  召集會議
                </span>
              </div>
            </div>
          </motion.button>

          {/* Secondary Button - Victorian Silver Plate */}
          <motion.button
            onClick={() => setShowJoinModal(true)}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="w-full relative"
          >
            <div className="relative px-6 py-4 overflow-hidden"
                 style={{
                   background: 'linear-gradient(135deg, #3d2817 0%, #2d1810 50%, #3d2817 100%)',
                   border: '2px solid #8b7753',
                   boxShadow: '0 4px 15px rgba(0,0,0,0.6), inset 0 1px 2px rgba(139,119,83,0.3)',
                 }}>
              <div className="relative z-10 flex items-center justify-center gap-3">
                <span 
                  className="text-[#c9a961] tracking-widest"
                  style={{
                    fontFamily: 'Georgia, serif',
                    textShadow: '0 1px 2px rgba(0,0,0,0.8)',
                  }}
                >
                  進入議事廳
                </span>
              </div>
            </div>
          </motion.button>

          {/* Victorian footer seal */}
          <div className="flex justify-center items-center gap-3 mt-4 opacity-60">
            <div className="w-12 h-px bg-[#8b7753]"></div>
            <div className="text-[#8b7753] text-xs tracking-widest" style={{ fontFamily: 'Georgia, serif' }}>
              EST. 1812
            </div>
            <div className="w-12 h-px bg-[#8b7753]"></div>
          </div>
        </motion.div>
      </div>

      {/* Join Room Modal - Victorian Style */}
      {showJoinModal && (
        <motion.div 
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          style={{ background: 'rgba(29, 24, 16, 0.95)' }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
        >
          <motion.div 
            className="w-full max-w-sm relative"
            initial={{ scale: 0.9, y: 20 }}
            animate={{ scale: 1, y: 0 }}
          >
            {/* Victorian modal frame */}
            <div className="relative p-8"
                 style={{
                   background: 'linear-gradient(135deg, #3d2817 0%, #2d1810 50%, #3d2817 100%)',
                   border: '4px solid #d4af37',
                   boxShadow: '0 20px 60px rgba(0,0,0,0.9), inset 0 0 30px rgba(212,175,55,0.1)',
                 }}>
              {/* Decorative corners */}
              <div className="absolute top-0 left-0 w-12 h-12 border-t-2 border-l-2 border-[#d4af37] opacity-50"></div>
              <div className="absolute top-0 right-0 w-12 h-12 border-t-2 border-r-2 border-[#d4af37] opacity-50"></div>
              <div className="absolute bottom-0 left-0 w-12 h-12 border-b-2 border-l-2 border-[#d4af37] opacity-50"></div>
              <div className="absolute bottom-0 right-0 w-12 h-12 border-b-2 border-r-2 border-[#d4af37] opacity-50"></div>

              <div className="relative z-10">
                {/* Ornamental header */}
                <div className="flex justify-center mb-4">
                  <VictorianOrnament className="w-32 h-8 text-[#d4af37] opacity-70" />
                </div>

                <h2 
                  className="text-[#d4af37] text-center mb-2 text-2xl"
                  style={{ 
                    fontFamily: 'Georgia, serif',
                    letterSpacing: '0.2em',
                    textShadow: '0 2px 4px rgba(0,0,0,0.8)',
                  }}
                >
                  輸入代碼
                </h2>
                
                <p className="text-[#8b7753] text-center mb-6 text-xs italic">Enter Chamber Code</p>

                <input
                  type="text"
                  value={joinCode}
                  onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                  placeholder="XXXXXX"
                  maxLength={6}
                  className="w-full text-center py-4 tracking-[0.5em] mb-6 border-2"
                  style={{ 
                    fontFamily: 'Georgia, serif',
                    fontSize: '1.5rem',
                    background: 'rgba(245, 230, 211, 0.1)',
                    borderColor: '#8b7753',
                    color: '#d4af37',
                    boxShadow: 'inset 0 2px 8px rgba(0,0,0,0.6)',
                  }}
                />

                <div className="flex gap-3">
                  <motion.button
                    onClick={() => setShowJoinModal(false)}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="flex-1 py-3 border-2"
                    style={{ 
                      fontFamily: 'Georgia, serif',
                      borderColor: '#8b7753',
                      color: '#8b7753',
                      background: 'rgba(139, 119, 83, 0.1)',
                    }}
                  >
                    取消
                  </motion.button>
                  
                  <motion.button
                    onClick={handleJoinSubmit}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="flex-1 py-3 border-2"
                    style={{ 
                      fontFamily: 'Georgia, serif',
                      background: 'linear-gradient(135deg, #8b4513 0%, #654321 100%)',
                      borderColor: '#d4af37',
                      color: '#d4af37',
                      boxShadow: '0 4px 12px rgba(212,175,55,0.4)',
                    }}
                  >
                    加入
                  </motion.button>
                </div>

                {/* Ornamental footer */}
                <div className="flex justify-center mt-4">
                  <VictorianOrnament className="w-32 h-8 text-[#8b7753] opacity-50" flip />
                </div>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}

      <style>{`
        .bg-gradient-radial {
          background: radial-gradient(circle, var(--tw-gradient-stops));
        }
      `}</style>
    </div>
  );
}

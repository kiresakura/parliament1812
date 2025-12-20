import { useState } from 'react';
import { Crown, Shield, Scroll } from 'lucide-react';
import parliamentImage from 'figma:asset/dc70d59f64d5b8ff9b2c9149edc695e285b421e7.png';
import { motion } from 'motion/react';

interface HomeScreenProps {
  onCreateRoom: () => void;
  onJoinRoom: (code: string) => void;
}

// Ornamental flourish component
function Flourish({ className = "" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 100 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M0 10 Q25 0, 50 10 T100 10" stroke="currentColor" strokeWidth="0.5" fill="none" opacity="0.4"/>
      <path d="M0 10 Q25 20, 50 10 T100 10" stroke="currentColor" strokeWidth="0.5" fill="none" opacity="0.4"/>
      <circle cx="50" cy="10" r="2" fill="currentColor" opacity="0.5"/>
    </svg>
  );
}

// Particle component for golden sparkles
function Particle({ delay }: { delay: number }) {
  const randomX = Math.random() * 100;
  const randomDuration = 3 + Math.random() * 2;
  
  return (
    <motion.div
      className="absolute w-1 h-1 bg-[#d4af37] rounded-full"
      style={{
        left: `${randomX}%`,
        bottom: '0%',
        boxShadow: '0 0 4px #d4af37',
      }}
      animate={{
        y: [-20, -300],
        opacity: [0, 1, 1, 0],
        scale: [0, 1, 1, 0],
      }}
      transition={{
        duration: randomDuration,
        repeat: Infinity,
        delay: delay,
        ease: 'easeOut',
      }}
    />
  );
}

export function HomeScreen({ onCreateRoom, onJoinRoom }: HomeScreenProps) {
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [joinCode, setJoinCode] = useState('');

  const handleJoinSubmit = () => {
    if (joinCode.trim()) {
      onJoinRoom(joinCode.trim().toUpperCase());
    }
  };

  return (
    <div className="relative overflow-hidden">
      {/* Desktop: Two-column layout, Mobile: Single column */}
      <div className="lg:grid lg:grid-cols-2 lg:gap-8">
        {/* Left Column - Image and Title (Desktop) / Top (Mobile) */}
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
                 boxShadow: 'inset 0 0 20px rgba(139, 119, 83, 0.1)',
               }}></div>
          
          <div className="relative p-6 lg:p-8 pb-8">
            {/* Parliament chamber image with ornate frame */}
            <motion.div 
              className="mb-6 rounded-lg overflow-hidden relative"
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 1, ease: 'easeOut' }}
            >
              {/* 华丽的金色画框 */}
              <div className="absolute inset-0 -m-3 rounded-lg"
                   style={{
                     background: 'linear-gradient(135deg, #8b7753 0%, #a0896a 25%, #d4af37 50%, #a0896a 75%, #8b7753 100%)',
                     boxShadow: 'inset 0 2px 8px rgba(0, 0, 0, 0.4), 0 4px 15px rgba(139, 119, 83, 0.5)',
                     padding: '12px',
                   }}></div>
              
              {/* 内层装饰框 */}
              <div className="absolute inset-0 -m-1.5 rounded-lg border-2"
                   style={{
                     borderColor: '#d4af37',
                     boxShadow: '0 0 10px rgba(212, 175, 55, 0.4)',
                   }}></div>
              
              <div className="relative m-3">
                <img 
                  src={parliamentImage} 
                  alt="Parliament Chamber" 
                  className="w-full h-48 lg:h-64 object-cover rounded"
                  style={{ filter: 'sepia(0.15) contrast(1.1) brightness(0.95)' }}
                />
                
                {/* 古典绘画质感叠加 */}
                <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[#8b7753] opacity-20 rounded"></div>
                
                {/* 顶部高光 */}
                <div className="absolute top-0 left-0 right-0 h-20 bg-gradient-to-b from-white to-transparent opacity-10 rounded-t"></div>
              </div>
            </motion.div>

            {/* Game Logo - British Elegance */}
            <motion.div 
              className="text-center mb-6 lg:mb-8 relative"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 1, delay: 0.3, ease: 'easeOut' }}
            >
              {/* Royal Crown with ornate styling */}
              <div className="flex justify-center mb-4">
                <div className="relative">
                  {/* 皇冠光晕 */}
                  <div className="absolute inset-0 blur-md">
                    <Crown className="w-14 h-14 lg:w-16 lg:h-16 text-[#d4af37]" strokeWidth={2} />
                  </div>
                  <Crown 
                    className="w-14 h-14 lg:w-16 lg:h-16 relative z-10" 
                    strokeWidth={2}
                    style={{
                      color: '#8b7753',
                      filter: 'drop-shadow(2px 2px 1px rgba(212, 175, 55, 0.4))',
                    }}
                  />
                </div>
              </div>

              {/* Decorative flourish above title */}
              <Flourish className="w-32 lg:w-40 h-4 mx-auto mb-3 text-[#8b7753]" />

              {/* Title with British elegance */}
              <div className="relative mb-3">
                <h1 
                  className="relative text-[#5c4a33] text-2xl lg:text-3xl"
                  style={{ 
                    fontFamily: 'Georgia, serif',
                    letterSpacing: '0.15em',
                    textShadow: '2px 2px 0px rgba(212, 175, 55, 0.15)',
                  }}
                >
                  1812 議會辯論
                </h1>
              </div>

              {/* Decorative line - Victorian style */}
              <div className="flex justify-center items-center gap-2 mb-3">
                <div className="flex items-center gap-1">
                  <div className="w-2 h-2 bg-[#8b7753] transform rotate-45"></div>
                  <div className="w-12 lg:w-16 h-px bg-gradient-to-r from-transparent to-[#8b7753]"></div>
                </div>
                <Scroll className="w-4 h-4 text-[#8b7753] opacity-60" />
                <div className="flex items-center gap-1">
                  <div className="w-12 lg:w-16 h-px bg-gradient-to-l from-transparent to-[#8b7753]"></div>
                  <div className="w-2 h-2 bg-[#8b7753] transform rotate-45"></div>
                </div>
              </div>
              
              {/* Decorative flourish below title */}
              <Flourish className="w-32 lg:w-40 h-4 mx-auto mb-3 text-[#8b7753] transform rotate-180" />
              
              {/* Subtitle with British flair */}
              <p 
                className="text-[#5c4a33] opacity-80 text-sm lg:text-base italic"
                style={{ 
                  fontFamily: 'Georgia, serif',
                }}
              >
                忠誠與欺騙的遊戲
              </p>
              
              {/* Royal motto */}
              <div className="mt-3 text-xs text-[#8b7753] opacity-60 italic"
                   style={{ fontFamily: 'Georgia, serif' }}>
                <p>Dieu et mon droit</p>
              </div>
            </motion.div>
          </div>
        </div>

        {/* Right Column - Buttons (Desktop) / Bottom (Mobile) */}
        <div className="relative mt-4 lg:mt-0">
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
                 boxShadow: 'inset 0 0 20px rgba(139, 119, 83, 0.1)',
               }}></div>
          
          <div className="relative p-6 lg:p-8 lg:flex lg:flex-col lg:justify-center lg:h-full">
            {/* Particles around buttons */}
            <div className="absolute left-0 right-0 top-[30%] h-64 overflow-hidden pointer-events-none">
              {Array.from({ length: 8 }).map((_, i) => (
                <Particle key={i} delay={i * 0.4} />
              ))}
            </div>

            {/* Ornate header for buttons section */}
            <div className="text-center mb-6">
              <h3 className="text-[#5c4a33] text-sm lg:text-base opacity-80 tracking-wider"
                  style={{ fontFamily: 'Georgia, serif' }}>
                開啟您的議會之旅
              </h3>
              <div className="w-24 h-px bg-[#8b7753] mx-auto mt-2 opacity-50"></div>
            </div>

            {/* Primary Button - Ornate British Style */}
            <motion.div
              className="mb-5 relative"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.6 }}
            >
              <motion.button
                onClick={onCreateRoom}
                className="w-full relative overflow-hidden rounded-lg"
                whileHover={{ scale: 1.02, y: -2 }}
                whileTap={{ scale: 0.98 }}
                style={{
                  background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 50%, #d4af37 100%)',
                  boxShadow: '0 6px 20px rgba(139, 119, 83, 0.4), inset 0 1px 2px rgba(255, 255, 255, 0.3), inset 0 -2px 4px rgba(0, 0, 0, 0.2)',
                }}
              >
                {/* 装饰性边框 */}
                <div className="absolute inset-0 border-2 rounded-lg pointer-events-none"
                     style={{ borderColor: 'rgba(139, 119, 83, 0.4)' }}></div>
                
                {/* 羊皮纸纹理叠加 */}
                <div className="absolute inset-0 opacity-15 mix-blend-overlay"
                     style={{ 
                       background: 'repeating-linear-gradient(90deg, transparent, transparent 2px, rgba(139, 119, 83, 0.3) 2px, rgba(139, 119, 83, 0.3) 4px)',
                     }}></div>

                <div className="relative py-5 lg:py-6 px-6 flex items-center justify-center gap-3">
                  <Crown className="w-6 h-6 text-[#3d2817]" strokeWidth={2.5} />
                  <span 
                    className="text-[#3d2817] text-lg lg:text-xl"
                    style={{ 
                      fontFamily: 'Georgia, serif',
                      letterSpacing: '0.1em',
                      textShadow: '0 1px 1px rgba(255, 255, 255, 0.3)',
                    }}
                  >
                    召集會議
                  </span>
                </div>
                
                {/* 顶部高光 */}
                <div className="absolute top-0 left-0 right-0 h-1/3 bg-gradient-to-b from-white to-transparent opacity-20 rounded-t-lg pointer-events-none"></div>
              </motion.button>
            </motion.div>

            {/* Secondary Button - Refined British Style */}
            <motion.div
              className="relative"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.8 }}
            >
              <motion.button
                onClick={() => setShowJoinModal(true)}
                className="w-full relative overflow-hidden rounded-lg border-3"
                whileHover={{ scale: 1.02, y: -2 }}
                whileTap={{ scale: 0.98 }}
                style={{
                  background: 'linear-gradient(135deg, #f5e6d3 0%, #e8d4bc 50%, #f5e6d3 100%)',
                  borderWidth: '3px',
                  borderStyle: 'double',
                  borderColor: '#8b7753',
                  boxShadow: '0 4px 15px rgba(139, 119, 83, 0.3), inset 0 1px 2px rgba(255, 255, 255, 0.5)',
                }}
              >
                {/* 装饰性内边框 */}
                <div className="absolute inset-1 border rounded-md pointer-events-none opacity-30"
                     style={{ borderColor: '#d4af37' }}></div>

                <div className="relative py-5 lg:py-6 px-6 flex items-center justify-center gap-3">
                  <Shield className="w-6 h-6 text-[#5c4a33]" strokeWidth={2} />
                  <span 
                    className="text-[#5c4a33] text-lg lg:text-xl"
                    style={{ 
                      fontFamily: 'Georgia, serif',
                      letterSpacing: '0.1em',
                    }}
                  >
                    進入議事廳
                  </span>
                </div>
              </motion.button>
            </motion.div>

            {/* Decorative footer with British elements */}
            <motion.div 
              className="mt-8 lg:mt-10 text-center"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 1, delay: 1 }}
            >
              <div className="flex justify-center items-center gap-3 text-[#8b7753] opacity-60 text-xs">
                <div className="w-8 h-px bg-[#8b7753]"></div>
                <div className="flex flex-col items-center">
                  <span style={{ 
                    fontFamily: 'Georgia, serif', 
                    letterSpacing: '0.2em',
                  }}>
                    EST. 1812
                  </span>
                  <span className="text-[0.6rem] mt-0.5 italic">London</span>
                </div>
                <div className="w-8 h-px bg-[#8b7753]"></div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>

      {/* Join Room Modal - Elegant British Design */}
      {showJoinModal && (
        <motion.div 
          className="fixed inset-0 flex items-center justify-center z-50 p-4"
          style={{ background: 'rgba(92, 74, 51, 0.85)' }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.3 }}
        >
          <motion.div 
            className="rounded-lg p-6 lg:p-8 w-full max-w-sm relative overflow-hidden border-4"
            initial={{ scale: 0.9, y: 20 }}
            animate={{ scale: 1, y: 0 }}
            transition={{ duration: 0.3 }}
            style={{ 
              background: 'linear-gradient(135deg, #f5e6d3 0%, #e8d4bc 50%, #f5e6d3 100%)',
              borderColor: '#8b7753',
              borderStyle: 'double',
              boxShadow: '0 10px 40px rgba(0, 0, 0, 0.5)',
            }}
          >
            {/* 羊皮纸纹理 */}
            <div className="absolute inset-0 opacity-20 mix-blend-multiply"
                 style={{
                   backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
                 }}></div>

            {/* 装饰性徽章 */}
            <div className="flex justify-center mb-4">
              <div className="w-12 h-12 rounded-full flex items-center justify-center"
                   style={{ 
                     background: 'linear-gradient(135deg, #d4af37, #b8941f)',
                     boxShadow: '0 4px 12px rgba(212, 175, 55, 0.4)',
                   }}>
                <Shield className="w-6 h-6 text-[#3d2817]" />
              </div>
            </div>

            <h2 
              className="text-[#5c4a33] text-center mb-2 relative z-10" 
              style={{ 
                fontFamily: 'Georgia, serif', 
                letterSpacing: '0.1em',
              }}
            >
              輸入會議代碼
            </h2>
            
            <p className="text-[#8b7753] text-xs text-center mb-6 opacity-70 italic"
               style={{ fontFamily: 'Georgia, serif' }}>
              Please enter your chamber code
            </p>

            <input
              type="text"
              value={joinCode}
              onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
              placeholder="XXXXXX"
              maxLength={6}
              className="w-full text-center py-4 rounded-md mb-6 tracking-widest relative z-10 border-2"
              style={{ 
                fontFamily: 'monospace', 
                fontSize: '1.4rem',
                background: '#faf6ef',
                borderColor: '#8b7753',
                color: '#5c4a33',
                boxShadow: 'inset 0 2px 6px rgba(139, 119, 83, 0.2)',
              }}
            />
            
            <div className="flex gap-3 relative z-10">
              <motion.button
                onClick={() => setShowJoinModal(false)}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="flex-1 py-3 rounded-md transition-all border-2"
                style={{ 
                  fontFamily: 'Georgia, serif', 
                  letterSpacing: '0.05em',
                  background: 'transparent',
                  borderColor: '#8b7753',
                  color: '#5c4a33',
                }}
              >
                取消
              </motion.button>
              <motion.button
                onClick={handleJoinSubmit}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="flex-1 py-3 rounded-md transition-all"
                style={{ 
                  fontFamily: 'Georgia, serif', 
                  letterSpacing: '0.05em',
                  background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 100%)',
                  color: '#3d2817',
                  boxShadow: '0 4px 12px rgba(212, 175, 55, 0.4)',
                }}
              >
                加入
              </motion.button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </div>
  );
}

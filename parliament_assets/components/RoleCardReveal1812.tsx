import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Eye, EyeOff, ChevronRight, Target, Users } from 'lucide-react';
import { CornerFlourish, ParchmentTexture, WaxSeal, AtmosphereParticles } from './VictorianOrnament';
import { HexagonPattern, HexagonBadge, GearIcon, hexagonStyles } from './HexagonPattern';
import { PARTY_COLORS, PARTY_NAMES } from '../data/characters';
import character1 from 'figma:asset/edf26726be2cd4acfdf7a72337cbbc8f76a7a792.png';

interface RoleCardReveal1812Props {
  onContinue: () => void;
}

// Mock role data - using historically accurate 1812 character
const mockRole = {
  party: 'whig' as const,
  nameChinese: '格雷伯爵',
  nameEnglish: 'Earl Grey',
  title: '輝格黨領袖',
  portrait: character1,
  description: '您代表改革派利益，主張天主教解放與國會改革。作為輝格黨領袖，您必須團結黨內力量，對抗托利黨的保守政策。',
  objective: '投票支持改革法案，並說服至少兩名中立議員加入您的陣營。',
  allies: ['霍蘭勳爵', '塞繆爾·惠特布雷德', '亨利·布魯厄姆'],
};

export function RoleCardReveal1812({ onContinue }: RoleCardReveal1812Props) {
  const [isHidden, setIsHidden] = useState(true); // Start hidden for dramatic reveal
  const [isBroken, setIsBroken] = useState(false);
  const partyColor = PARTY_COLORS[mockRole.party];
  const partyName = PARTY_NAMES[mockRole.party];

  const handleBreakSeal = () => {
    setIsBroken(true);
    setTimeout(() => {
      setIsHidden(false);
    }, 400); // Wait for seal break animation
  };

  const toggleHidden = () => {
    if (!isHidden) {
      setIsHidden(true);
      setIsBroken(false);
    } else {
      setIsBroken(true);
      setTimeout(() => setIsHidden(false), 400);
    }
  };

  return (
    <div className="h-screen w-full bg-[#1a1614] flex flex-col overflow-hidden">
      <style>{hexagonStyles}</style>

      {/* Hexagon pattern background */}
      <HexagonPattern className="text-[#d4af37]" />
      <AtmosphereParticles />

      {/* Top Bar */}
      <div className="relative z-10 p-3 border-b"
           style={{
             background: 'rgba(36, 27, 20, 0.95)',
             borderColor: 'rgba(212, 175, 55, 0.3)',
             boxShadow: '0 2px 8px rgba(0, 0, 0, 0.5)',
           }}>
        <div className="flex items-center justify-center gap-2">
          <GearIcon className="w-5 h-5 text-[#d4af37]" spinning />
          <h2 className="text-[#f5e6d3] text-lg"
              style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.1em' }}>
            您的身份 <span className="text-sm text-[#b8a07e] opacity-70">Your Role</span>
          </h2>
          <GearIcon className="w-5 h-5 text-[#d4af37]" spinning />
        </div>
      </div>

      {/* Main Content - Perfectly centered */}
      <div className="flex-1 flex items-center justify-center p-4 overflow-y-auto relative z-10">
        <div className="w-full max-w-2xl">
          <AnimatePresence mode="wait">
            {!isHidden ? (
              <motion.div
                key="revealed"
                className="grid md:grid-cols-2 gap-4"
                initial={{ opacity: 0, rotateY: -90 }}
                animate={{ opacity: 1, rotateY: 0 }}
                exit={{ opacity: 0, rotateY: 90 }}
                transition={{ duration: 0.6 }}
              >
                {/* Left Side - Portrait */}
                <div className="flex flex-col gap-4">
                  {/* Portrait Card */}
                  <div className="rounded-lg overflow-hidden border-2 relative"
                       style={{
                         background: 'rgba(36, 27, 20, 0.95)',
                         borderColor: '#d4af37',
                         boxShadow: '0 8px 32px rgba(0, 0, 0, 0.6)',
                         clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%)',
                       }}>
                    <ParchmentTexture />

                    {/* Decorative gears */}
                    <GearIcon className="absolute top-2 left-2 w-6 h-6 text-[#8b7753] opacity-20" spinning />
                    <GearIcon className="absolute top-2 right-2 w-6 h-6 text-[#8b7753] opacity-20" spinning />

                    <div className="relative z-10 p-4">
                      {/* Hexagon badge */}
                      <div className="flex justify-center mb-3">
                        <HexagonBadge className="w-16 h-16" color={partyColor}>
                          <Users className="w-8 h-8" style={{ color: partyColor }} />
                        </HexagonBadge>
                      </div>

                      {/* Portrait */}
                      <div className="relative w-full max-w-[280px] md:max-w-full mx-auto aspect-[3/4] rounded overflow-hidden border-4 mb-4"
                           style={{
                             borderColor: '#d4af37',
                             boxShadow: '0 4px 20px rgba(0, 0, 0, 0.5), inset 0 0 30px rgba(0, 0, 0, 0.3)',
                           }}>
                        <div className="relative h-full"
                             style={{
                               background: 'linear-gradient(to bottom, #3d2817 0%, #2d1810 100%)',
                             }}>
                          <img 
                            src={mockRole.portrait}
                            alt={mockRole.nameChinese}
                            className="w-full h-full object-cover"
                            style={{ 
                              filter: 'sepia(0.1) contrast(1.1)',
                              objectPosition: 'center 20%',
                            }}
                          />
                          
                          {/* Vignette */}
                          <div className="absolute inset-0"
                               style={{
                                 background: 'radial-gradient(ellipse at center, transparent 30%, rgba(29, 24, 16, 0.6) 80%)',
                               }}></div>
                        </div>
                      </div>

                      {/* Party Badge */}
                      <div className="py-3 px-4 rounded border-2 relative overflow-hidden"
                           style={{
                             background: `linear-gradient(135deg, ${partyColor}30, ${partyColor}10)`,
                             borderColor: partyColor,
                             boxShadow: `0 4px 16px ${partyColor}40`,
                             clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%)',
                           }}>
                        <div className="text-center">
                          <div className="text-lg tracking-widest mb-1"
                               style={{ 
                                 fontFamily: 'Georgia, serif',
                                 color: partyColor,
                                 textShadow: `0 0 10px ${partyColor}80`,
                               }}>
                            {partyName.chinese}
                          </div>
                          <div className="text-xs uppercase tracking-widest opacity-70"
                               style={{ fontFamily: 'Georgia, serif', color: partyColor }}>
                            {partyName.english}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Right Side - Information */}
                <div className="flex flex-col gap-4">
                  {/* Name Card */}
                  <div className="rounded-lg p-4 border-2 relative overflow-hidden"
                       style={{
                         background: 'rgba(36, 27, 20, 0.95)',
                         borderColor: 'rgba(212, 175, 55, 0.5)',
                         boxShadow: '0 4px 16px rgba(0, 0, 0, 0.4)',
                         clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%)',
                       }}>
                    <div className="absolute top-1 right-1 w-8 h-8 opacity-20">
                      <HexagonIcon className="w-full h-full text-[#d4af37]" filled />
                    </div>

                    <h3 className="text-[#f5e6d3] text-2xl mb-1"
                        style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.05em' }}>
                      {mockRole.nameChinese}
                    </h3>
                    <p className="text-[#b8a07e] italic text-sm mb-1"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      {mockRole.nameEnglish}
                    </p>
                    <p className="text-[#8b7753] text-xs"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      {mockRole.title}
                    </p>
                  </div>

                  {/* Description */}
                  <div className="rounded-lg p-4 border relative overflow-hidden"
                       style={{
                         background: 'rgba(36, 27, 20, 0.8)',
                         borderColor: 'rgba(212, 175, 55, 0.3)',
                         boxShadow: '0 2px 8px rgba(0, 0, 0, 0.3)',
                       }}>
                    <ParchmentTexture />
                    <p className="text-[#f5e6d3] text-sm leading-relaxed relative z-10"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      {mockRole.description}
                    </p>
                  </div>

                  {/* Objective */}
                  <div className="rounded-lg p-4 border-2 relative overflow-hidden"
                       style={{
                         background: 'rgba(212, 175, 55, 0.1)',
                         borderColor: '#d4af37',
                         boxShadow: 'inset 0 2px 8px rgba(0, 0, 0, 0.3), 0 4px 16px rgba(212, 175, 55, 0.3)',
                         clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%)',
                       }}>
                    <div className="absolute top-2 right-2 w-8 h-8 opacity-20">
                      <Target className="w-full h-full text-[#d4af37]" />
                    </div>

                    <h4 className="text-[#d4af37] text-sm mb-2 uppercase tracking-wider flex items-center gap-2"
                        style={{ fontFamily: 'Georgia, serif' }}>
                      <ChevronRight className="w-4 h-4" />
                      您的目標 <span className="text-xs opacity-70 normal-case">Objective</span>
                    </h4>
                    <p className="text-[#f5e6d3] text-sm leading-relaxed"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      {mockRole.objective}
                    </p>
                  </div>

                  {/* Allies */}
                  <div className="rounded-lg p-4 border relative overflow-hidden"
                       style={{
                         background: `${partyColor}10`,
                         borderColor: `${partyColor}40`,
                         boxShadow: '0 2px 8px rgba(0, 0, 0, 0.3)',
                       }}>
                    <h4 className="text-[#b8a07e] text-sm mb-3 uppercase tracking-wider flex items-center gap-2"
                        style={{ fontFamily: 'Georgia, serif' }}>
                      <Users className="w-4 h-4" />
                      已知盟友 <span className="text-xs opacity-70 normal-case">Known Allies</span>
                    </h4>
                    <div className="flex flex-wrap gap-2">
                      {mockRole.allies.map((ally, index) => (
                        <motion.div
                          key={index}
                          className="px-3 py-2 rounded border text-sm flex items-center gap-2"
                          initial={{ opacity: 0, scale: 0.8 }}
                          animate={{ opacity: 1, scale: 1 }}
                          transition={{ delay: 0.6 + index * 0.1 }}
                          style={{
                            background: `${partyColor}20`,
                            borderColor: `${partyColor}50`,
                            color: '#f5e6d3',
                            fontFamily: 'Georgia, serif',
                          }}
                        >
                          <HexagonIcon className="w-3 h-3" style={{ color: partyColor }} />
                          {ally}
                        </motion.div>
                      ))}
                    </div>
                  </div>
                </div>
              </motion.div>
            ) : (
              <motion.div
                key="hidden"
                className="rounded-lg overflow-hidden border-2 relative min-h-[400px] md:h-[500px] flex items-center justify-center"
                initial={{ opacity: 0, rotateY: -90 }}
                animate={{ opacity: 1, rotateY: 0 }}
                exit={{ opacity: 0, rotateY: 90 }}
                transition={{ duration: 0.6 }}
                style={{
                  background: 'rgba(36, 27, 20, 0.95)',
                  borderColor: '#8b7753',
                  boxShadow: '0 8px 32px rgba(0, 0, 0, 0.6)',
                }}
              >
                <ParchmentTexture />
                
                {/* Envelope Fold Lines (Visual Effect) */}
                <div className="absolute inset-0 opacity-10 pointer-events-none"
                     style={{
                       backgroundImage: 'linear-gradient(135deg, transparent 48%, #000 50%, transparent 52%), linear-gradient(45deg, transparent 48%, #000 50%, transparent 52%)',
                       backgroundPosition: 'center top',
                       backgroundSize: '100% 100%',
                     }}></div>

                <div className="flex flex-col items-center relative z-10">
                  <div className="relative mb-8">
                    <WaxSeal 
                      className="w-32 h-32" 
                      broken={isBroken}
                      onClick={handleBreakSeal}
                    />
                  </div>
                  
                  <p className="text-[#8b7753] text-lg uppercase tracking-widest mt-4"
                     style={{ fontFamily: 'Georgia, serif' }}>
                    {isBroken ? '正在解封...' : '點擊火漆以解密'}
                  </p>
                  <p className="text-[#8b7753] text-xs opacity-60 mt-2"
                     style={{ fontFamily: 'Georgia, serif' }}>
                    {isBroken ? 'Breaking Seal...' : 'Break the Seal to Reveal Identity'}
                  </p>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Action Buttons */}
          <div className="mt-4 grid grid-cols-2 gap-3">
            {/* Hide/Show Toggle */}
            <motion.button
              onClick={toggleHidden}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="py-3 border-2 flex items-center justify-center gap-2 transition-all"
              style={{
                background: 'transparent',
                borderColor: '#8b7753',
                color: '#b8a07e',
                fontFamily: 'Georgia, serif',
                clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%)',
              }}
            >
              {isHidden ? <Eye className="w-5 h-5" /> : <EyeOff className="w-5 h-5" />}
              <span>{isHidden ? '顯示' : '隱藏'}</span>
            </motion.button>

            {/* Continue Button */}
            <motion.button
              onClick={onContinue}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="py-3 relative overflow-hidden"
              style={{
                background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 100%)',
                color: '#1a1a2e',
                fontFamily: 'Georgia, serif',
                letterSpacing: '0.1em',
                clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%)',
                boxShadow: '0 6px 20px rgba(212, 175, 55, 0.4)',
                border: '2px solid rgba(255, 255, 255, 0.2)',
              }}
            >
              <motion.div
                className="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-20"
                animate={{ x: ['-200%', '200%'] }}
                transition={{ duration: 3, repeat: Infinity, repeatDelay: 1 }}
              ></motion.div>

              <span className="relative z-10 flex items-center justify-center gap-2">
                <HexagonIcon className="w-5 h-5" filled />
                繼續 CONTINUE
              </span>
            </motion.button>
          </div>
        </div>
      </div>
    </div>
  );
}

function HexagonIcon({ className = "", filled = false, style = {} }: { className?: string; filled?: boolean; style?: React.CSSProperties }) {
  return (
    <svg className={className} style={style} viewBox="0 0 100 100" fill={filled ? "currentColor" : "none"} stroke="currentColor" strokeWidth="4">
      <polygon points="50,5 90,27.5 90,72.5 50,95 10,72.5 10,27.5" />
    </svg>
  );
}

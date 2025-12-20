import { Crown, Eye, EyeOff, Shield, Scroll } from 'lucide-react';
import { useState } from 'react';
import { motion } from 'motion/react';
import character2 from 'figma:asset/ee4612f93cae6c1e572501d5432f2b2bba87b575.png';

interface RoleCardRevealProps {
  onContinue: () => void;
}

const mockRole = {
  title: "輝格黨成員",
  titleEn: "Member of the Whig Party",
  party: "輝格黨",
  partyEn: "Whig",
  description: "您代表憲政君主制和議會改革的利益。與您的輝格黨同伴合作，通過進步立法。",
  objective: "投票支持改革法案，並識別試圖阻礙進步的秘密托利黨成員。",
  allies: ["威靈頓公爵", "艾希福德女伯爵"],
  color: "#4a7c59",
  character: character2,
};

export function RoleCardReveal({ onContinue }: RoleCardRevealProps) {
  const [isRevealed, setIsRevealed] = useState(false);

  return (
    <div className="relative overflow-hidden">
      {/* 羊皮纸卡片背景 */}
      <div className="absolute inset-0 rounded-lg"
           style={{
             background: 'linear-gradient(135deg, #f5e6d3 0%, #e8d4bc 50%, #f0ddc5 100%)',
             boxShadow: '0 10px 40px rgba(0, 0, 0, 0.3), inset 0 0 80px rgba(139, 119, 83, 0.1)',
           }}></div>
      
      {/* 羊皮纸纹理 */}
      <div className="absolute inset-0 opacity-20 mix-blend-multiply rounded-lg"
           style={{
             backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
           }}></div>
      
      <div className="relative p-6 pb-8">
        {/* Header */}
        <motion.div 
          className="text-center mb-8"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className="flex justify-center mb-4">
            <Shield className="w-12 h-12 text-[#8b7753]" strokeWidth={1.5} />
          </div>
          <h2 className="text-[#5c4a33] mb-2" style={{ fontFamily: 'serif', letterSpacing: '0.1em' }}>
            您的委任狀
          </h2>
          <div className="flex justify-center items-center gap-2 mb-3">
            <div className="w-12 h-px bg-[#8b7753]"></div>
            <div className="w-2 h-2 bg-[#8b7753] rounded-full"></div>
            <div className="w-12 h-px bg-[#8b7753]"></div>
          </div>
          <p className="text-[#8b7753] opacity-80 mt-3 text-sm italic" style={{ fontFamily: 'serif' }}>
            以榮譽守護這個秘密
          </p>
        </motion.div>

        {/* Role Card */}
        <div 
          className="relative mb-6 cursor-pointer"
          onClick={() => setIsRevealed(!isRevealed)}
        >
          {/* Card Front (Hidden) */}
          <motion.div 
            className={`transition-all duration-500 ${isRevealed ? 'opacity-0 absolute inset-0 pointer-events-none' : 'opacity-100'}`}
            animate={{ rotateY: isRevealed ? 90 : 0 }}
            style={{ transformStyle: 'preserve-3d' }}
          >
            <div className="rounded-lg p-8 border-4 relative overflow-hidden"
                 style={{ 
                   background: 'linear-gradient(135deg, #faf6ef 0%, #f5f0e3 50%, #faf6ef 100%)',
                   borderColor: '#8b7753',
                   boxShadow: '0 8px 30px rgba(139, 119, 83, 0.4)',
                 }}>
              {/* 蜡封效果 */}
              <div className="absolute inset-0 opacity-10"
                   style={{
                     background: 'radial-gradient(circle at center, rgba(212, 175, 55, 0.3) 0%, transparent 60%)',
                   }}></div>
              
              <div className="flex flex-col items-center justify-center py-12">
                <EyeOff className="w-16 h-16 text-[#8b7753] mb-4 opacity-50" strokeWidth={1.5} />
                <p className="text-[#5c4a33] text-center" style={{ fontFamily: 'serif', letterSpacing: '0.05em' }}>
                  點擊揭曉您的角色
                </p>
              </div>
              
              {/* Decorative wax seal */}
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                <div className="w-24 h-24 rounded-full opacity-10 flex items-center justify-center"
                     style={{ background: 'radial-gradient(circle, #d4af37 0%, transparent 70%)' }}>
                  <Crown className="w-12 h-12 text-[#d4af37]" />
                </div>
              </div>
            </div>
          </motion.div>

          {/* Card Back (Revealed) */}
          <motion.div 
            className={`transition-all duration-500 ${isRevealed ? 'opacity-100' : 'opacity-0 absolute inset-0 pointer-events-none'}`}
            animate={{ rotateY: isRevealed ? 0 : -90 }}
            style={{ transformStyle: 'preserve-3d' }}
          >
            <div className="rounded-lg p-6 border-4 relative overflow-hidden"
                 style={{ 
                   background: 'linear-gradient(135deg, #faf6ef 0%, #f5f0e3 50%, #faf6ef 100%)',
                   borderColor: '#8b7753',
                   boxShadow: '0 8px 30px rgba(139, 119, 83, 0.4), inset 0 0 40px rgba(139, 119, 83, 0.05)',
                 }}>
              {/* 羊皮纸纹理 */}
              <div className="absolute inset-0 opacity-15 mix-blend-multiply"
                   style={{
                     backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 3px, rgba(139, 119, 83, 0.1) 3px, rgba(139, 119, 83, 0.1) 6px)',
                   }}></div>
              
              <div className="relative z-10">
                {/* Character Portrait */}
                <div className="flex justify-center mb-4">
                  <div className="w-32 h-32 rounded-full overflow-hidden border-4"
                       style={{ 
                         borderColor: mockRole.color,
                         boxShadow: `0 4px 15px ${mockRole.color}80`,
                       }}>
                    <img 
                      src={mockRole.character} 
                      alt={mockRole.title}
                      className="w-full h-full object-cover"
                      style={{ objectPosition: 'center 20%' }}
                    />
                  </div>
                </div>

                {/* Party Badge */}
                <div className="flex justify-center mb-4">
                  <div 
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-full border-2"
                    style={{ 
                      borderColor: mockRole.color,
                      backgroundColor: `${mockRole.color}30`,
                    }}
                  >
                    <Crown className="w-5 h-5" style={{ color: mockRole.color }} strokeWidth={2} />
                    <span style={{ color: mockRole.color, fontFamily: 'serif', letterSpacing: '0.08em' }}>
                      {mockRole.party.toUpperCase()}
                    </span>
                  </div>
                </div>

                {/* Title */}
                <h3 className="text-[#5c4a33] text-center mb-4" 
                    style={{ fontFamily: 'serif', letterSpacing: '0.05em' }}>
                  {mockRole.title}
                </h3>

                <div className="flex justify-center items-center gap-2 mb-4">
                  <div className="w-16 h-px bg-[#8b7753] opacity-50"></div>
                  <div className="w-1.5 h-1.5 bg-[#8b7753] rounded-full opacity-50"></div>
                  <div className="w-16 h-px bg-[#8b7753] opacity-50"></div>
                </div>

                {/* Description */}
                <p className="text-[#5c4a33] opacity-80 text-sm text-center mb-4 leading-relaxed" 
                   style={{ fontFamily: 'serif' }}>
                  {mockRole.description}
                </p>

                {/* Objective */}
                <div className="rounded-lg p-4 mb-4 border-2"
                     style={{
                       background: 'linear-gradient(135deg, #f5e6d3 0%, #e8d4bc 100%)',
                       borderColor: mockRole.color,
                       borderWidth: '2px',
                     }}>
                  <p className="text-[#5c4a33] opacity-70 text-xs mb-2 text-center" 
                     style={{ fontFamily: 'serif', letterSpacing: '0.05em' }}>
                    您的目標
                  </p>
                  <p className="text-[#5c4a33] text-sm text-center leading-relaxed" 
                     style={{ fontFamily: 'serif' }}>
                    {mockRole.objective}
                  </p>
                </div>

                {/* Allies */}
                <div>
                  <p className="text-[#5c4a33] opacity-70 text-xs mb-3 text-center" 
                     style={{ fontFamily: 'serif', letterSpacing: '0.05em' }}>
                    已知盟友
                  </p>
                  <div className="flex flex-wrap gap-2 justify-center">
                    {mockRole.allies.map((ally, index) => (
                      <div
                        key={index}
                        className="px-3 py-1 rounded-full border-2"
                        style={{
                          background: `${mockRole.color}20`,
                          borderColor: mockRole.color,
                        }}
                      >
                        <span className="text-sm" style={{ color: mockRole.color, fontFamily: 'serif' }}>
                          {ally}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Tap to hide hint */}
                <div className="flex justify-center mt-4">
                  <Eye className="w-5 h-5 text-[#8b7753] opacity-30" />
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Warning */}
        {isRevealed && (
          <motion.div 
            className="rounded-lg p-4 mb-6 border-2"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            style={{
              background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 100%)',
              borderColor: '#8b7753',
            }}
          >
            <p className="text-[#3d2817] text-center text-sm" style={{ fontFamily: 'serif' }}>
              ⚠️ 請勿向其他玩家透露您的角色
            </p>
          </motion.div>
        )}

        {/* Continue Button */}
        <motion.button
          onClick={onContinue}
          disabled={!isRevealed}
          whileHover={isRevealed ? { scale: 1.02 } : {}}
          whileTap={isRevealed ? { scale: 0.98 } : {}}
          className={`w-full py-5 rounded-lg transition-all duration-300 ${
            isRevealed
              ? ''
              : 'cursor-not-allowed opacity-50'
          }`}
          style={{ 
            fontFamily: 'serif',
            letterSpacing: '0.08em',
            background: isRevealed 
              ? 'linear-gradient(135deg, #d4af37 0%, #b8941f 50%, #d4af37 100%)'
              : 'linear-gradient(135deg, #c4c4c4 0%, #a8a8a8 100%)',
            color: isRevealed ? '#3d2817' : '#6a6a6a',
            boxShadow: isRevealed 
              ? '0 6px 20px rgba(139, 119, 83, 0.4), inset 0 1px 2px rgba(255, 255, 255, 0.3)'
              : '0 2px 8px rgba(0, 0, 0, 0.1)',
          }}
        >
          前往議事廳
        </motion.button>

        {/* Decorative footer */}
        <div className="mt-6 text-center">
          <p className="text-[#8b7753] opacity-60 text-xs italic" style={{ fontFamily: 'serif' }}>
            「忠於王國與國家」
          </p>
        </div>
      </div>
    </div>
  );
}
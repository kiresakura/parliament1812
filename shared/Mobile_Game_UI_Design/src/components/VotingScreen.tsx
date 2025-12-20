import { ThumbsUp, ThumbsDown, Clock, Users, ArrowLeft, Scroll } from 'lucide-react';
import { useState } from 'react';
import { motion } from 'motion/react';

interface VotingScreenProps {
  onBack: () => void;
}

const mockMotion = {
  title: "徵收貿易制裁動議",
  description: "一項限制與外國勢力貿易的法案，將影響王國的經濟利益。",
  proposer: "威靈頓公爵",
  proposerTitle: "Duke of Wellington",
  timeRemaining: 45,
};

const mockVotes = [
  { player: "艾希福德女伯爵", voted: true },
  { player: "埃德蒙爵士", voted: true },
  { player: "格雷男爵夫人", voted: false },
  { player: "威靈頓公爵", voted: true },
  { player: "議會議長", voted: false },
  { player: "帕默斯頓子爵", voted: true },
];

export function VotingScreen({ onBack }: VotingScreenProps) {
  const [selectedVote, setSelectedVote] = useState<'aye' | 'nay' | null>(null);
  const [hasVoted, setHasVoted] = useState(false);

  const handleVote = (vote: 'aye' | 'nay') => {
    setSelectedVote(vote);
    setHasVoted(true);
  };

  return (
    <div className="relative overflow-hidden">
      {/* Desktop: Two-column layout */}
      <div className="lg:grid lg:grid-cols-[3fr_2fr] lg:gap-6">
        {/* Left Column - Motion Card (Desktop) / Top (Mobile) */}
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
                <Scroll className="w-10 h-10 text-[#8b7753]" strokeWidth={1.5} />
              </div>
              <h2 className="text-[#5c4a33] mb-2 text-xl lg:text-2xl" style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.1em' }}>
                表決進行中
              </h2>
              <p className="text-[#8b7753] text-xs opacity-70 italic" style={{ fontFamily: 'Georgia, serif' }}>
                Division Called
              </p>
              <div className="flex justify-center items-center gap-2 mt-3">
                <div className="w-12 h-px bg-[#8b7753]"></div>
                <div className="w-2 h-2 bg-[#8b7753] rounded-full"></div>
                <div className="w-12 h-px bg-[#8b7753]"></div>
              </div>
            </motion.div>

            {/* Time Remaining */}
            <motion.div 
              className="rounded-lg p-4 mb-6 border-2"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.1 }}
              style={{
                background: 'linear-gradient(135deg, #faf6ef 0%, #f0e6d8 100%)',
                borderColor: '#8b7753',
                boxShadow: '0 2px 10px rgba(139, 119, 83, 0.2)',
              }}
            >
              <div className="flex items-center justify-center gap-2 text-[#5c4a33]">
                <Clock className="w-5 h-5" />
                <span style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.05em' }}>
                  剩餘 {mockMotion.timeRemaining} 秒
                </span>
              </div>
            </motion.div>

            {/* Motion Card - Elegant Scroll Style */}
            <motion.div 
              className="rounded-lg p-6 lg:p-8 border-4 relative overflow-hidden"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              style={{
                background: 'linear-gradient(135deg, #faf6ef 0%, #f5f0e3 50%, #faf6ef 100%)',
                borderColor: '#8b7753',
                borderStyle: 'double',
                boxShadow: '0 8px 25px rgba(139, 119, 83, 0.4), inset 0 0 40px rgba(139, 119, 83, 0.05)',
              }}
            >
              {/* 装饰性羊皮纸纹理 */}
              <div className="absolute inset-0 opacity-15 mix-blend-multiply"
                   style={{
                     backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 3px, rgba(139, 119, 83, 0.1) 3px, rgba(139, 119, 83, 0.1) 6px)',
                   }}></div>
              
              {/* 装饰性蜡封水印 */}
              <div className="absolute top-4 right-4 w-16 h-16 rounded-full opacity-5"
                   style={{ background: 'radial-gradient(circle, #d4af37 0%, transparent 70%)' }}></div>
              
              <div className="relative z-10">
                <div className="text-center mb-5">
                  <p className="text-[#8b7753] text-xs mb-2 opacity-80" style={{ fontFamily: 'Georgia, serif' }}>
                    提議者
                  </p>
                  <p className="text-[#5c4a33] mb-1" style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.05em' }}>
                    {mockMotion.proposer}
                  </p>
                  <p className="text-[#8b7753] text-xs opacity-60 italic" style={{ fontFamily: 'Georgia, serif' }}>
                    {mockMotion.proposerTitle}
                  </p>
                </div>
                
                <div className="flex justify-center items-center gap-2 mb-5">
                  <div className="w-16 h-px bg-[#8b7753] opacity-50"></div>
                  <div className="w-1.5 h-1.5 bg-[#8b7753] rounded-full opacity-50"></div>
                  <div className="w-16 h-px bg-[#8b7753] opacity-50"></div>
                </div>
                
                <h3 className="text-[#5c4a33] text-center mb-4 text-lg lg:text-xl" 
                    style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.05em' }}>
                  {mockMotion.title}
                </h3>
                
                <p className="text-[#5c4a33] opacity-80 text-center text-sm leading-relaxed" 
                   style={{ fontFamily: 'Georgia, serif' }}>
                  {mockMotion.description}
                </p>

                {/* 装饰性印章 */}
                <div className="mt-6 flex justify-center">
                  <div className="w-12 h-12 rounded-full border-2 flex items-center justify-center"
                       style={{ borderColor: '#8b7753', borderStyle: 'dashed', opacity: 0.3 }}>
                    <Scroll className="w-6 h-6 text-[#8b7753]" />
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </div>

        {/* Right Column - Voting Controls (Desktop) / Bottom (Mobile) */}
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
          
          <div className="relative p-6 lg:p-8 lg:flex lg:flex-col lg:justify-center lg:h-full">
            {/* Voting instruction */}
            <div className="text-center mb-6">
              <h3 className="text-[#5c4a33] text-sm lg:text-base mb-2" 
                  style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.08em' }}>
                請投下您的一票
              </h3>
              <p className="text-[#8b7753] text-xs opacity-60 italic" style={{ fontFamily: 'Georgia, serif' }}>
                Cast Your Vote
              </p>
              <div className="w-24 h-px bg-[#8b7753] mx-auto mt-3 opacity-50"></div>
            </div>

            {/* Voting Buttons - British Wax Seal Style */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <motion.button
                onClick={() => handleVote('aye')}
                disabled={hasVoted}
                whileHover={!hasVoted ? { scale: 1.05, y: -2 } : {}}
                whileTap={!hasVoted ? { scale: 0.95 } : {}}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 }}
                className={`py-8 lg:py-10 rounded-lg border-3 transition-all duration-300 relative overflow-hidden ${
                  hasVoted && selectedVote !== 'aye' ? 'opacity-40' : ''
                }`}
                style={{ 
                  fontFamily: 'Georgia, serif',
                  letterSpacing: '0.08em',
                  background: selectedVote === 'aye' 
                    ? 'linear-gradient(135deg, #4a7c59 0%, #3d6548 50%, #4a7c59 100%)'
                    : 'linear-gradient(135deg, #faf6ef 0%, #f0e6d8 100%)',
                  borderWidth: '3px',
                  borderStyle: selectedVote === 'aye' ? 'solid' : 'double',
                  borderColor: selectedVote === 'aye' ? '#2d4a35' : '#8b7753',
                  color: selectedVote === 'aye' ? '#f5e6d3' : '#5c4a33',
                  boxShadow: selectedVote === 'aye' 
                    ? '0 8px 25px rgba(74, 124, 89, 0.6), inset 0 2px 4px rgba(255, 255, 255, 0.2)'
                    : '0 4px 15px rgba(139, 119, 83, 0.3)',
                }}
              >
                {/* 装饰性纹理 */}
                <div className="absolute inset-0 opacity-10 mix-blend-overlay"
                     style={{
                       background: selectedVote === 'aye' 
                         ? 'radial-gradient(circle at center, rgba(255,255,255,0.3) 0%, transparent 70%)'
                         : 'repeating-linear-gradient(90deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
                     }}></div>
                
                <div className="flex flex-col items-center gap-3 relative z-10">
                  <ThumbsUp className="w-10 h-10 lg:w-12 lg:h-12" strokeWidth={1.5} />
                  <span className="text-xl lg:text-2xl">贊成</span>
                  <span className="text-[0.65rem] opacity-70 italic">Aye</span>
                </div>
              </motion.button>

              <motion.button
                onClick={() => handleVote('nay')}
                disabled={hasVoted}
                whileHover={!hasVoted ? { scale: 1.05, y: -2 } : {}}
                whileTap={!hasVoted ? { scale: 0.95 } : {}}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 }}
                className={`py-8 lg:py-10 rounded-lg border-3 transition-all duration-300 relative overflow-hidden ${
                  hasVoted && selectedVote !== 'nay' ? 'opacity-40' : ''
                }`}
                style={{ 
                  fontFamily: 'Georgia, serif',
                  letterSpacing: '0.08em',
                  background: selectedVote === 'nay'
                    ? 'linear-gradient(135deg, #8b4545 0%, #6e3636 50%, #8b4545 100%)'
                    : 'linear-gradient(135deg, #faf6ef 0%, #f0e6d8 100%)',
                  borderWidth: '3px',
                  borderStyle: selectedVote === 'nay' ? 'solid' : 'double',
                  borderColor: selectedVote === 'nay' ? '#5c2e2e' : '#8b7753',
                  color: selectedVote === 'nay' ? '#f5e6d3' : '#5c4a33',
                  boxShadow: selectedVote === 'nay'
                    ? '0 8px 25px rgba(139, 69, 69, 0.6), inset 0 2px 4px rgba(255, 255, 255, 0.2)'
                    : '0 4px 15px rgba(139, 119, 83, 0.3)',
                }}
              >
                {/* 装饰性纹理 */}
                <div className="absolute inset-0 opacity-10 mix-blend-overlay"
                     style={{
                       background: selectedVote === 'nay'
                         ? 'radial-gradient(circle at center, rgba(255,255,255,0.3) 0%, transparent 70%)'
                         : 'repeating-linear-gradient(90deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
                     }}></div>
                
                <div className="flex flex-col items-center gap-3 relative z-10">
                  <ThumbsDown className="w-10 h-10 lg:w-12 lg:h-12" strokeWidth={1.5} />
                  <span className="text-xl lg:text-2xl">反對</span>
                  <span className="text-[0.65rem] opacity-70 italic">Nay</span>
                </div>
              </motion.button>
            </div>

            {/* Vote Status */}
            {hasVoted && (
              <motion.div 
                className="rounded-lg p-4 mb-6 text-center border-2"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                style={{
                  background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 100%)',
                  borderColor: '#8b7753',
                  boxShadow: '0 4px 15px rgba(212, 175, 55, 0.4)',
                }}
              >
                <p className="text-[#3d2817] mb-1" style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.05em' }}>
                  您的投票已記錄
                </p>
                <p className="text-[#3d2817] text-xs opacity-70 italic" style={{ fontFamily: 'Georgia, serif' }}>
                  Your vote has been recorded
                </p>
              </motion.div>
            )}

            {/* Voting Progress */}
            <motion.div 
              className="rounded-lg p-4 lg:p-5 border-2"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
              style={{
                background: 'linear-gradient(135deg, #faf6ef 0%, #f0e6d8 100%)',
                borderColor: '#8b7753',
              }}
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <Users className="w-5 h-5 text-[#5c4a33]" />
                  <span className="text-[#5c4a33] text-sm" style={{ fontFamily: 'Georgia, serif' }}>
                    已投票
                  </span>
                </div>
                <span className="text-[#5c4a33]" style={{ fontFamily: 'Georgia, serif' }}>
                  {mockVotes.filter(v => v.voted).length}/{mockVotes.length}
                </span>
              </div>
              
              <div className="w-full rounded-full h-3 border-2"
                   style={{ background: '#e8d4bc', borderColor: '#8b7753' }}>
                <div 
                  className="h-full rounded-full transition-all duration-500 relative overflow-hidden"
                  style={{ 
                    width: `${(mockVotes.filter(v => v.voted).length / mockVotes.length) * 100}%`,
                    background: 'linear-gradient(90deg, #d4af37 0%, #b8941f 100%)',
                  }}>
                  {/* 进度条高光 */}
                  <div className="absolute inset-0 bg-gradient-to-b from-white to-transparent opacity-30"></div>
                </div>
              </div>
            </motion.div>

            {/* Decorative footer */}
            <div className="mt-6 text-center">
              <p className="text-[#8b7753] opacity-60 text-xs italic" style={{ fontFamily: 'Georgia, serif' }}>
                「贊成者勝，贊成者勝」
              </p>
              <p className="text-[#8b7753] opacity-50 text-[0.65rem] mt-1" style={{ fontFamily: 'Georgia, serif' }}>
                "The Ayes have it, the Ayes have it"
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Clock, ThumbsUp, ThumbsDown, CheckCircle, TrendingUp, BarChart3 } from 'lucide-react';
import { CornerFlourish, ParchmentTexture, InkStamp, AtmosphereParticles } from './VictorianOrnament';
import { HexagonPattern, HexagonBadge, DataPanel, GearIcon, hexagonStyles } from './HexagonPattern';

interface VotingScreen1812Props {
  onVoteComplete: () => void;
}

// Mock bill data - historically accurate 1812 topic
const bill = {
  titleChinese: '天主教解放法案',
  titleEnglish: 'Catholic Relief Act',
  description: '本法案旨在解除對天主教徒的政治限制，允許其擔任公職並進入議會。此舉將改變英國自宗教改革以來的基本國策，引發激烈爭論。',
  context: '當前英國法律禁止天主教徒擔任大多數公職，此法案若通過將是重大突破。',
};

export function VotingScreen1812({ onVoteComplete }: VotingScreen1812Props) {
  const [timeLeft, setTimeLeft] = useState(60);
  const [hasVoted, setHasVoted] = useState(false);
  const [selectedVote, setSelectedVote] = useState<'aye' | 'nay' | 'abstain' | null>(null);
  const [showResults, setShowResults] = useState(false);

  const results = {
    aye: 8,
    nay: 12,
    abstain: 2,
    total: 22,
  };

  useEffect(() => {
    if (timeLeft > 0 && !hasVoted) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    } else if (timeLeft === 0 && !hasVoted) {
      handleVote('abstain');
    }
  }, [timeLeft, hasVoted]);

  const handleVote = (vote: 'aye' | 'nay' | 'abstain') => {
    setSelectedVote(vote);
    setHasVoted(true);
    setTimeout(() => setShowResults(true), 2000);
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const progressPercent = (timeLeft / 60) * 100;

  return (
    <div className="h-screen w-full bg-[#1a1614] flex flex-col overflow-hidden">
      <style>{hexagonStyles}</style>

      {/* Hexagon pattern background */}
      <HexagonPattern className="text-[#d4af37]" />
      <AtmosphereParticles />

      {/* Top Bar */}
      <div className="relative z-10 p-3 border-b flex items-center justify-between flex-wrap gap-3"
           style={{
             background: 'rgba(36, 27, 20, 0.95)',
             borderColor: 'rgba(212, 175, 55, 0.3)',
             boxShadow: '0 2px 8px rgba(0, 0, 0, 0.5)',
           }}>
        <div className="flex items-center gap-2">
          <GearIcon className="w-5 h-5 text-[#d4af37]" spinning />
          <h2 className="text-[#f5e6d3] text-lg"
              style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.1em' }}>
            議案表決 <span className="text-sm text-[#b8a07e] opacity-70">Vote on Bill</span>
          </h2>
        </div>

        {!hasVoted && (
          <div className="flex items-center gap-3 ml-auto">
            <Clock className="w-5 h-5 text-[#d4af37]" />
            <span className="text-[#d4af37] text-xl tabular-nums"
                  style={{ fontFamily: 'Georgia, serif' }}>
              {formatTime(timeLeft)}
            </span>
          </div>
        )}
      </div>

      {/* Main Content - Two Column Layout */}
      <div className="flex-1 flex flex-col lg:flex-row overflow-hidden relative z-10">
        {/* Left Column - Bill Information */}
        <div className="w-full lg:w-[45%] flex-1 lg:flex-none min-h-0 border-b lg:border-b-0 lg:border-r p-4 flex flex-col overflow-y-auto scrollable"
             style={{
               background: 'rgba(36, 27, 20, 0.5)',
               borderColor: 'rgba(212, 175, 55, 0.2)',
             }}>
          {/* Bill Card */}
          <motion.div
            className="rounded-lg p-5 border-2 relative overflow-hidden mb-4"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            style={{
              background: 'rgba(36, 27, 20, 0.95)',
              borderColor: '#d4af37',
              boxShadow: '0 4px 20px rgba(0, 0, 0, 0.5)',
              clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%)',
            }}
          >
            <ParchmentTexture />

            <GearIcon className="absolute top-2 right-2 w-10 h-10 text-[#8b7753] opacity-15" spinning />

            <div className="relative z-10">
              {/* Icon Badge */}
              <div className="flex justify-center mb-4">
                <HexagonBadge className="w-16 h-16">
                  <BarChart3 className="w-8 h-8 text-[#d4af37]" strokeWidth={2} />
                </HexagonBadge>
              </div>

              {/* Bill Title */}
              <div className="text-center mb-4">
                <h3 className="text-[#d4af37] text-2xl mb-1"
                    style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.05em' }}>
                  《{bill.titleChinese}》
                </h3>
                <p className="text-[#b8a07e] italic text-sm"
                   style={{ fontFamily: 'Georgia, serif' }}>
                  {bill.titleEnglish}
                </p>
              </div>

              <div className="h-px bg-gradient-to-r from-transparent via-[#8b7753] to-transparent mb-4"></div>

              {/* Bill Description */}
              <div className="space-y-3">
                <p className="text-[#f5e6d3] text-sm leading-relaxed"
                   style={{ fontFamily: 'Georgia, serif' }}>
                  {bill.description}
                </p>
                
                <div className="p-3 rounded border"
                     style={{
                       background: 'rgba(139, 119, 83, 0.15)',
                       borderColor: 'rgba(139, 119, 83, 0.4)',
                     }}>
                  <p className="text-[#b8a07e] text-xs leading-relaxed italic"
                     style={{ fontFamily: 'Georgia, serif' }}>
                    💡 {bill.context}
                  </p>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Timer Progress (if not voted) */}
          {!hasVoted && (
            <motion.div
              className="rounded-lg p-4 border-2 mb-4"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              style={{
                background: 'rgba(36, 27, 20, 0.8)',
                borderColor: timeLeft > 20 ? '#d4af37' : timeLeft > 10 ? '#cc7722' : '#8b2500',
                boxShadow: '0 2px 12px rgba(0, 0, 0, 0.4)',
              }}
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-[#b8a07e] text-sm" style={{ fontFamily: 'Georgia, serif' }}>
                  投票倒計時
                </span>
                <span className="text-[#f5e6d3] text-xl tabular-nums"
                      style={{ fontFamily: 'Georgia, serif' }}>
                  {formatTime(timeLeft)}
                </span>
              </div>

              <div className="h-3 rounded-full overflow-hidden border"
                   style={{
                     background: 'rgba(36, 27, 20, 0.6)',
                     borderColor: 'rgba(212, 175, 55, 0.3)',
                   }}>
                <motion.div
                  className="h-full"
                  initial={{ width: '100%' }}
                  animate={{ width: `${progressPercent}%` }}
                  style={{
                    background: timeLeft > 20 
                      ? 'linear-gradient(90deg, #d4af37, #b8941f)' 
                      : timeLeft > 10
                      ? 'linear-gradient(90deg, #cc7722, #b8641f)'
                      : 'linear-gradient(90deg, #8b2500, #6e1e00)',
                    boxShadow: '0 0 10px rgba(212, 175, 55, 0.5)',
                  }}
                ></motion.div>
              </div>
            </motion.div>
          )}

          {/* Statistics Panel (Victoria 3 style) */}
          {hasVoted && !showResults && (
            <motion.div
              className="rounded-lg p-4 border text-center relative overflow-hidden"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              style={{
                background: 'rgba(36, 27, 20, 0.9)',
                borderColor: 'rgba(212, 175, 55, 0.4)',
              }}
            >
              <InkStamp type={selectedVote === 'aye' ? 'aye' : selectedVote === 'nay' ? 'nay' : 'voted'} />
              
              <CheckCircle className="w-12 h-12 text-[#d4af37] mx-auto mb-3 opacity-20" />
              
              <p className="text-[#f5e6d3] text-lg mb-2"
                 style={{ fontFamily: 'Georgia, serif' }}>
                您的票已記錄
              </p>
              
              <p className="text-[#b8a07e] text-sm mb-3"
                 style={{ fontFamily: 'Georgia, serif' }}>
                等待其他議員...
              </p>

              <div className="inline-block px-4 py-2 rounded border"
                   style={{
                     background: selectedVote === 'aye' ? 'rgba(45, 90, 39, 0.2)' :
                                 selectedVote === 'nay' ? 'rgba(139, 37, 0, 0.2)' :
                                 'rgba(139, 119, 83, 0.2)',
                     borderColor: selectedVote === 'aye' ? '#2d5a27' :
                                  selectedVote === 'nay' ? '#8b2500' :
                                  '#8b7753',
                   }}>
                <span className="text-sm uppercase tracking-wider"
                      style={{ 
                        fontFamily: 'Georgia, serif',
                        color: selectedVote === 'aye' ? '#2d5a27' :
                               selectedVote === 'nay' ? '#8b2500' :
                               '#8b7753'
                      }}>
                  {selectedVote === 'aye' ? '贊成 AYE' :
                   selectedVote === 'nay' ? '反對 NAY' :
                   '棄權 ABSTAIN'}
                </span>
              </div>
            </motion.div>
          )}
        </div>

        {/* Right Column - Voting Interface */}
        <div className="flex-none lg:flex-1 p-4 flex flex-col justify-center">
          <AnimatePresence mode="wait">
            {!hasVoted ? (
              <motion.div
                key="voting"
                className="space-y-3 md:space-y-4"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
              >
                <div className="grid grid-cols-2 lg:grid-cols-1 gap-3 md:gap-4">
                  {/* AYE Button */}
                  <motion.button
                    onClick={() => handleVote('aye')}
                    whileHover={{ scale: 1.02, x: -2 }}
                    whileTap={{ scale: 0.98 }}
                    className="w-full py-4 md:py-8 border-3 relative overflow-hidden group rounded-lg lg:rounded-none"
                    style={{
                      background: 'linear-gradient(135deg, #2d5a27 0%, #234a1f 100%)',
                      borderColor: '#2d5a27',
                      borderWidth: '3px',
                      boxShadow: '0 4px 12px rgba(45, 90, 39, 0.3)',
                    }}
                  >
                    {/* Hexagon decoration */}
                    <div className="absolute top-2 right-2 w-8 h-8 md:w-12 md:h-12 opacity-20">
                      <HexagonIcon className="w-full h-full text-white" filled />
                    </div>

                    <motion.div
                      className="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-10"
                      animate={{ x: ['-200%', '200%'] }}
                      transition={{ duration: 3, repeat: Infinity, repeatDelay: 1 }}
                    ></motion.div>

                    <div className="relative z-10 flex flex-col md:flex-row items-center justify-center gap-2 md:gap-4">
                      <HexagonBadge className="w-10 h-10 md:w-16 md:h-16" color="#2d5a27">
                        <ThumbsUp className="w-5 h-5 md:w-8 md:h-8 text-[#f5e6d3]" strokeWidth={2.5} />
                      </HexagonBadge>
                      <div className="text-center md:text-left">
                        <div className="text-[#f5e6d3] text-xl md:text-3xl mb-0 md:mb-1 font-serif tracking-widest">
                          贊成
                        </div>
                        <div className="text-[#b8a07e] uppercase tracking-widest text-[10px] md:text-sm hidden md:block">
                          AYE • 支持法案
                        </div>
                      </div>
                    </div>
                  </motion.button>

                  {/* NAY Button */}
                  <motion.button
                    onClick={() => handleVote('nay')}
                    whileHover={{ scale: 1.02, x: -2 }}
                    whileTap={{ scale: 0.98 }}
                    className="w-full py-4 md:py-8 border-3 relative overflow-hidden group rounded-lg lg:rounded-none"
                    style={{
                      background: 'linear-gradient(135deg, #8b2500 0%, #6e1e00 100%)',
                      borderColor: '#8b2500',
                      borderWidth: '3px',
                      boxShadow: '0 4px 12px rgba(139, 37, 0, 0.3)',
                    }}
                  >
                    <div className="absolute top-2 right-2 w-8 h-8 md:w-12 md:h-12 opacity-20">
                      <HexagonIcon className="w-full h-full text-white" filled />
                    </div>

                    <motion.div
                      className="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-10"
                      animate={{ x: ['-200%', '200%'] }}
                      transition={{ duration: 3, repeat: Infinity, repeatDelay: 1.5 }}
                    ></motion.div>

                    <div className="relative z-10 flex flex-col md:flex-row items-center justify-center gap-2 md:gap-4">
                      <HexagonBadge className="w-10 h-10 md:w-16 md:h-16" color="#8b2500">
                        <ThumbsDown className="w-5 h-5 md:w-8 md:h-8 text-[#f5e6d3]" strokeWidth={2.5} />
                      </HexagonBadge>
                      <div className="text-center md:text-left">
                        <div className="text-[#f5e6d3] text-xl md:text-3xl mb-0 md:mb-1 font-serif tracking-widest">
                          反對
                        </div>
                        <div className="text-[#b8a07e] uppercase tracking-widest text-[10px] md:text-sm hidden md:block">
                          NAY • 反對法案
                        </div>
                      </div>
                    </div>
                  </motion.button>
                </div>

                {/* Abstain Option */}
                <div className="text-center pt-1 md:pt-2">
                  <button
                    onClick={() => handleVote('abstain')}
                    className="text-[#8b7753] hover:text-[#b8a07e] transition-colors underline flex items-center justify-center gap-2 mx-auto py-2"
                    style={{ fontFamily: 'Georgia, serif' }}
                  >
                    <HexagonIcon className="w-4 h-4" />
                    <span className="text-sm">或選擇 <span className="uppercase tracking-wider">棄權 ABSTAIN</span></span>
                  </button>
                </div>
              </motion.div>
            ) : showResults && (
              <motion.div
                key="results"
                className="rounded-lg p-6 border-2"
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                style={{
                  background: 'rgba(36, 27, 20, 0.95)',
                  borderColor: '#d4af37',
                  boxShadow: '0 8px 32px rgba(0, 0, 0, 0.6)',
                  clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 20px), calc(100% - 20px) 100%, 0 100%)',
                }}
              >
                <ParchmentTexture />

                <div className="relative z-10">
                  <div className="flex items-center justify-center gap-3 mb-6">
                    <GearIcon className="w-6 h-6 text-[#d4af37]" spinning />
                    <h4 className="text-[#d4af37] text-center text-xl"
                        style={{ fontFamily: 'Georgia, serif', letterSpacing: '0.1em' }}>
                      投票結果
                    </h4>
                    <GearIcon className="w-6 h-6 text-[#d4af37]" spinning />
                  </div>

                  <div className="space-y-4 mb-6">
                    {/* Aye */}
                    <div>
                      <div className="flex justify-between items-center mb-2">
                        <span className="text-[#2d5a27] flex items-center gap-2" style={{ fontFamily: 'Georgia, serif' }}>
                          <HexagonIcon className="w-4 h-4 text-[#2d5a27]" filled />
                          贊成 (Aye)
                        </span>
                        <span className="text-[#f5e6d3] text-lg tabular-nums" style={{ fontFamily: 'Georgia, serif' }}>
                          {results.aye} 票
                        </span>
                      </div>
                      <div className="h-8 rounded overflow-hidden border-2"
                           style={{ background: 'rgba(0,0,0,0.3)', borderColor: 'rgba(45, 90, 39, 0.4)' }}>
                        <motion.div
                          className="h-full flex items-center justify-end pr-3"
                          initial={{ width: 0 }}
                          animate={{ width: `${(results.aye / results.total) * 100}%` }}
                          transition={{ duration: 1, delay: 0.3 }}
                          style={{ background: 'linear-gradient(90deg, #2d5a27, #1e3d1a)' }}
                        >
                          <span className="text-[#f5e6d3] text-sm font-bold"
                                style={{ fontFamily: 'Georgia, serif' }}>
                            {Math.round((results.aye / results.total) * 100)}%
                          </span>
                        </motion.div>
                      </div>
                    </div>

                    {/* Nay */}
                    <div>
                      <div className="flex justify-between items-center mb-2">
                        <span className="text-[#8b2500] flex items-center gap-2" style={{ fontFamily: 'Georgia, serif' }}>
                          <HexagonIcon className="w-4 h-4 text-[#8b2500]" filled />
                          反對 (Nay)
                        </span>
                        <span className="text-[#f5e6d3] text-lg tabular-nums" style={{ fontFamily: 'Georgia, serif' }}>
                          {results.nay} 票
                        </span>
                      </div>
                      <div className="h-8 rounded overflow-hidden border-2"
                           style={{ background: 'rgba(0,0,0,0.3)', borderColor: 'rgba(139, 37, 0, 0.4)' }}>
                        <motion.div
                          className="h-full flex items-center justify-end pr-3"
                          initial={{ width: 0 }}
                          animate={{ width: `${(results.nay / results.total) * 100}%` }}
                          transition={{ duration: 1, delay: 0.5 }}
                          style={{ background: 'linear-gradient(90deg, #8b2500, #6e1e00)' }}
                        >
                          <span className="text-[#f5e6d3] text-sm font-bold"
                                style={{ fontFamily: 'Georgia, serif' }}>
                            {Math.round((results.nay / results.total) * 100)}%
                          </span>
                        </motion.div>
                      </div>
                    </div>

                    {/* Abstain */}
                    <div>
                      <div className="flex justify-between items-center mb-2">
                        <span className="text-[#8b7753] flex items-center gap-2" style={{ fontFamily: 'Georgia, serif' }}>
                          <HexagonIcon className="w-4 h-4 text-[#8b7753]" />
                          棄權 (Abstain)
                        </span>
                        <span className="text-[#f5e6d3] text-lg tabular-nums" style={{ fontFamily: 'Georgia, serif' }}>
                          {results.abstain} 票
                        </span>
                      </div>
                      <div className="h-8 rounded overflow-hidden border-2"
                           style={{ background: 'rgba(0,0,0,0.3)', borderColor: 'rgba(139, 119, 83, 0.4)' }}>
                        <motion.div
                          className="h-full flex items-center justify-end pr-3"
                          initial={{ width: 0 }}
                          animate={{ width: `${(results.abstain / results.total) * 100}%` }}
                          transition={{ duration: 1, delay: 0.7 }}
                          style={{ background: 'linear-gradient(90deg, #8b7753, #5c4a33)' }}
                        >
                          <span className="text-[#f5e6d3] text-sm font-bold"
                                style={{ fontFamily: 'Georgia, serif' }}>
                            {Math.round((results.abstain / results.total) * 100)}%
                          </span>
                        </motion.div>
                      </div>
                    </div>
                  </div>

                  {/* Final Result */}
                  <motion.div
                    className="p-5 rounded border-2 text-center mb-4"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ delay: 1.2 }}
                    style={{
                      background: results.nay > results.aye 
                        ? 'rgba(139, 37, 0, 0.2)' 
                        : 'rgba(45, 90, 39, 0.2)',
                      borderColor: results.nay > results.aye ? '#8b2500' : '#2d5a27',
                      clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%)',
                    }}
                  >
                    <HexagonBadge className="w-20 h-20 mx-auto mb-3" 
                                  color={results.nay > results.aye ? '#8b2500' : '#2d5a27'}>
                      <TrendingUp className="w-10 h-10" 
                                  style={{ color: results.nay > results.aye ? '#8b2500' : '#2d5a27' }} />
                    </HexagonBadge>
                    
                    <p className="text-[#f5e6d3] text-2xl mb-1"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      {results.nay > results.aye ? '法案否決' : '法案通過'}
                    </p>
                    <p className="text-[#b8a07e]"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      {results.nay > results.aye ? 'Bill Rejected' : 'Bill Passed'}
                    </p>
                  </motion.div>

                  {/* Continue Button */}
                  <motion.button
                    onClick={onVoteComplete}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    className="w-full py-4"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ delay: 1.5 }}
                    style={{
                      background: 'linear-gradient(135deg, #d4af37 0%, #b8941f 100%)',
                      color: '#1a1a2e',
                      fontFamily: 'Georgia, serif',
                      letterSpacing: '0.1em',
                      clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%)',
                      boxShadow: '0 6px 20px rgba(212, 175, 55, 0.4)',
                    }}
                  >
                    繼續下一輪 CONTINUE →
                  </motion.button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
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

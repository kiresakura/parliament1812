import { useState } from 'react';
import { motion } from 'motion/react';
import { Crown, Shield, Scroll, Gavel, Users, TrendingUp, Coins, Award, BookOpen } from 'lucide-react';
import character4 from 'figma:asset/52069e18a652bd94327acf496665283c6f10cd5c.png';

interface HomeScreenDesktopProps {
  onCreateRoom: () => void;
  onJoinRoom: (code: string) => void;
}

// Mock data for game rooms
const mockRooms = [
  { id: 1, title: '威靈頓的議案', host: '威靈頓公爵', players: 8, maxPlayers: 12, status: 'waiting', difficulty: '中等' },
  { id: 2, title: '改革法案辯論', host: '格雷伯爵', players: 12, maxPlayers: 12, status: 'playing', difficulty: '困難' },
  { id: 3, title: '貿易制裁會議', host: '帕默斯頓子爵', players: 5, maxPlayers: 10, status: 'waiting', difficulty: '簡單' },
  { id: 4, title: '殖民地政策', host: '墨爾本勳爵', players: 3, maxPlayers: 8, status: 'waiting', difficulty: '中等' },
  { id: 5, title: '皇家海軍預算', host: '納爾遜將軍', players: 10, maxPlayers: 12, status: 'playing', difficulty: '困難' },
  { id: 6, title: '愛爾蘭自治討論', host: '奧康奈爾先生', players: 6, maxPlayers: 10, status: 'waiting', difficulty: '中等' },
];

export function HomeScreenDesktop({ onCreateRoom, onJoinRoom }: HomeScreenDesktopProps) {
  const [selectedNav, setSelectedNav] = useState('lobby');
  const [hoveredRoom, setHoveredRoom] = useState<number | null>(null);

  return (
    <div className="w-full h-screen overflow-hidden relative"
         style={{
           background: 'linear-gradient(135deg, #1a0f08 0%, #2d1810 30%, #3d2817 50%, #2d1810 70%, #1a0f08 100%)',
         }}>
      {/* Victorian damask wallpaper pattern */}
      <div className="absolute inset-0 opacity-10"
           style={{
             backgroundImage: `
               url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23d4af37' fill-opacity='1' fill-rule='evenodd'%3E%3Cpath d='M30 30c0-5.523-4.477-10-10-10s-10 4.477-10 10 4.477 10 10 10 10-4.477 10-10zm10 0c0-5.523-4.477-10-10-10s-10 4.477-10 10 4.477 10 10 10 10-4.477 10-10z'/%3E%3C/g%3E%3C/svg%3E")
             `,
             backgroundSize: '60px 60px',
           }}></div>

      {/* Leather texture overlay */}
      <div className="absolute inset-0 opacity-20 mix-blend-overlay"
           style={{
             backgroundImage: 'repeating-linear-gradient(90deg, transparent, transparent 5px, rgba(139, 119, 83, 0.2) 5px, rgba(139, 119, 83, 0.2) 10px)',
           }}></div>

      {/* Main Container */}
      <div className="relative z-10 h-full flex">
        {/* Left Sidebar - Victorian Bookshelf Navigation */}
        <motion.div 
          className="w-28 relative flex flex-col py-8"
          initial={{ x: -100 }}
          animate={{ x: 0 }}
          transition={{ duration: 0.8 }}
          style={{
            background: 'linear-gradient(to right, #3d2817 0%, #5c4a33 50%, #3d2817 100%)',
            boxShadow: '4px 0 30px rgba(0, 0, 0, 0.8), inset -2px 0 10px rgba(0, 0, 0, 0.6)',
          }}
        >
          {/* Leather book spine texture */}
          <div className="absolute inset-0 opacity-30"
               style={{
                 backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 8px, rgba(139, 119, 83, 0.3) 8px, rgba(139, 119, 83, 0.3) 16px)',
               }}></div>

          {/* Decorative bookshelf dividers */}
          <div className="absolute inset-y-0 left-0 w-1 bg-gradient-to-b from-transparent via-[#d4af37] to-transparent opacity-40"></div>
          <div className="absolute inset-y-0 right-0 w-1 bg-gradient-to-b from-transparent via-[#8b7753] to-transparent opacity-40"></div>

          {/* Navigation Items - Book Spines */}
          <div className="relative z-10 flex flex-col items-center gap-4 px-3">
            {[
              { id: 'lobby', icon: Crown, label: '大廳', color: '#d4af37' },
              { id: 'rooms', icon: Scroll, label: '房間', color: '#c9a961' },
              { id: 'players', icon: Users, label: '玩家', color: '#b8941f' },
              { id: 'rules', icon: BookOpen, label: '規則', color: '#8b7753' },
            ].map((item, index) => (
              <motion.button
                key={item.id}
                onClick={() => setSelectedNav(item.id)}
                whileHover={{ scale: 1.05, x: 5 }}
                whileTap={{ scale: 0.95 }}
                className={`relative w-full aspect-square rounded-sm group ${
                  selectedNav === item.id ? 'bg-gradient-to-br from-[#d4af37] to-[#b8941f]' : 'bg-gradient-to-br from-[#5c4a33] to-[#3d2817]'
                }`}
                style={{
                  boxShadow: selectedNav === item.id 
                    ? '0 4px 16px rgba(212, 175, 55, 0.6), inset 0 1px 2px rgba(255, 255, 255, 0.3), inset 0 -2px 4px rgba(0, 0, 0, 0.6)'
                    : '0 2px 8px rgba(0, 0, 0, 0.6), inset 0 1px 1px rgba(255, 255, 255, 0.1)',
                  border: selectedNav === item.id ? '2px solid #d4af37' : '1px solid rgba(139, 119, 83, 0.3)',
                }}
              >
                {/* Book spine lines */}
                <div className="absolute top-1 bottom-1 left-1 right-1 border border-current opacity-20 pointer-events-none"></div>
                
                <div className="relative z-10 w-full h-full flex flex-col items-center justify-center gap-1">
                  <item.icon 
                    className={selectedNav === item.id ? 'text-[#3d2817]' : 'text-[#d4af37]'} 
                    strokeWidth={2}
                    size={24}
                  />
                  <span className={`text-[0.6rem] tracking-wider ${selectedNav === item.id ? 'text-[#3d2817]' : 'text-[#d4af37]'}`}
                        style={{ fontFamily: 'Georgia, serif' }}>
                    {item.label}
                  </span>
                </div>

                {/* Tooltip */}
                <div className="absolute left-full ml-4 px-3 py-2 bg-[#3d2817] text-[#d4af37] text-sm whitespace-nowrap rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none border border-[#d4af37] z-50"
                     style={{ fontFamily: 'Georgia, serif', boxShadow: '0 4px 12px rgba(0,0,0,0.6)' }}>
                  {item.label}
                </div>
              </motion.button>
            ))}
          </div>

          {/* Victorian ornamental line at bottom */}
          <div className="mt-auto mx-3">
            <div className="h-px bg-gradient-to-r from-transparent via-[#d4af37] to-transparent opacity-50 mb-2"></div>
            <div className="text-center">
              <div className="text-[#8b7753] text-[0.6rem] tracking-widest" style={{ fontFamily: 'Georgia, serif' }}>
                1812
              </div>
            </div>
          </div>
        </motion.div>

        {/* Main Content Area */}
        <div className="flex-1 flex flex-col">
          {/* Header - Victorian Ornate Banner */}
          <motion.div 
            className="h-28 relative flex items-center justify-between px-12"
            initial={{ y: -100 }}
            animate={{ y: 0 }}
            transition={{ duration: 0.8 }}
            style={{
              background: 'linear-gradient(to bottom, #3d2817 0%, #2d1810 50%, #1a0f08 100%)',
              borderBottom: '3px solid #d4af37',
              boxShadow: '0 6px 30px rgba(0, 0, 0, 0.8)',
            }}
          >
            {/* Decorative header pattern */}
            <div className="absolute inset-0 opacity-10"
                 style={{
                   backgroundImage: 'repeating-linear-gradient(90deg, transparent, transparent 40px, rgba(212, 175, 55, 0.2) 40px, rgba(212, 175, 55, 0.2) 42px)',
                 }}></div>

            {/* Title Section */}
            <div className="relative z-10">
              <h1 
                className="text-4xl text-[#d4af37] mb-1"
                style={{
                  fontFamily: 'Times New Roman, Georgia, serif',
                  letterSpacing: '0.15em',
                  textShadow: '0 2px 8px rgba(0,0,0,0.8), 0 0 20px rgba(212,175,55,0.4)',
                }}
              >
                1812 PARLIAMENT DEBATES
              </h1>
              <div className="flex items-center gap-2">
                <div className="w-24 h-px bg-gradient-to-r from-transparent to-[#8b7753]"></div>
                <p className="text-[#8b7753] text-xs italic tracking-wider" style={{ fontFamily: 'Georgia, serif' }}>
                  Tactician's Chamber
                </p>
              </div>
            </div>

            {/* User Stats - Victorian Medallions */}
            <div className="relative z-10 flex gap-8">
              {/* Influence */}
              <div className="relative group">
                <div className="w-20 h-20 rounded-full relative"
                     style={{
                       background: 'linear-gradient(135deg, #3d2817 0%, #2d1810 100%)',
                       border: '3px solid #8b0000',
                       boxShadow: '0 4px 16px rgba(139, 0, 0, 0.6), inset 0 2px 8px rgba(0, 0, 0, 0.8)',
                     }}>
                  {/* Inner ring */}
                  <div className="absolute inset-2 rounded-full border border-[#8b0000] opacity-30"></div>
                  
                  {/* Icon */}
                  <div className="absolute inset-0 flex items-center justify-center">
                    <TrendingUp className="text-[#8b0000]" size={28} strokeWidth={2} />
                  </div>

                  {/* Rotating ring decoration */}
                  <motion.div
                    className="absolute inset-0 rounded-full"
                    style={{ border: '2px dashed rgba(139, 0, 0, 0.3)' }}
                    animate={{ rotate: 360 }}
                    transition={{ duration: 30, repeat: Infinity, ease: 'linear' }}
                  ></motion.div>
                </div>
                <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 text-center whitespace-nowrap">
                  <div className="text-2xl text-[#d4af37]" style={{ fontFamily: 'Times New Roman, serif' }}>850</div>
                  <div className="text-[0.65rem] text-[#8b7753] uppercase tracking-wider" style={{ fontFamily: 'Georgia, serif' }}>影響力</div>
                </div>
              </div>

              {/* Gold */}
              <div className="relative group">
                <div className="w-20 h-20 rounded-full relative"
                     style={{
                       background: 'linear-gradient(135deg, #3d2817 0%, #2d1810 100%)',
                       border: '3px solid #d4af37',
                       boxShadow: '0 4px 16px rgba(212, 175, 55, 0.6), inset 0 2px 8px rgba(0, 0, 0, 0.8)',
                     }}>
                  <div className="absolute inset-2 rounded-full border border-[#d4af37] opacity-30"></div>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <Coins className="text-[#d4af37]" size={28} strokeWidth={2} />
                  </div>
                  <motion.div
                    className="absolute inset-0 rounded-full"
                    style={{ border: '2px dashed rgba(212, 175, 55, 0.3)' }}
                    animate={{ rotate: -360 }}
                    transition={{ duration: 35, repeat: Infinity, ease: 'linear' }}
                  ></motion.div>
                </div>
                <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 text-center whitespace-nowrap">
                  <div className="text-2xl text-[#d4af37]" style={{ fontFamily: 'Times New Roman, serif' }}>2,450</div>
                  <div className="text-[0.65rem] text-[#8b7753] uppercase tracking-wider" style={{ fontFamily: 'Georgia, serif' }}>金幣</div>
                </div>
              </div>

              {/* Reputation */}
              <div className="relative group">
                <div className="w-20 h-20 rounded-full relative"
                     style={{
                       background: 'linear-gradient(135deg, #3d2817 0%, #2d1810 100%)',
                       border: '3px solid #c0c0c0',
                       boxShadow: '0 4px 16px rgba(192, 192, 192, 0.4), inset 0 2px 8px rgba(0, 0, 0, 0.8)',
                     }}>
                  <div className="absolute inset-2 rounded-full border border-[#c0c0c0] opacity-30"></div>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <Award className="text-[#c0c0c0]" size={28} strokeWidth={2} />
                  </div>
                  <motion.div
                    className="absolute inset-0 rounded-full"
                    style={{ border: '2px dashed rgba(192, 192, 192, 0.3)' }}
                    animate={{ rotate: 360 }}
                    transition={{ duration: 40, repeat: Infinity, ease: 'linear' }}
                  ></motion.div>
                </div>
                <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 text-center whitespace-nowrap">
                  <div className="text-2xl text-[#d4af37]" style={{ fontFamily: 'Times New Roman, serif' }}>A+</div>
                  <div className="text-[0.65rem] text-[#8b7753] uppercase tracking-wider" style={{ fontFamily: 'Georgia, serif' }}>聲望</div>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Main Dashboard */}
          <div className="flex-1 flex overflow-hidden">
            {/* Center/Left - Game Rooms as Victorian Documents */}
            <div className="flex-1 p-10 overflow-y-auto">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
              >
                {/* Section Header */}
                <div className="mb-8 relative">
                  <div className="flex items-center justify-between">
                    <div>
                      <h2 className="text-3xl text-[#d4af37] mb-2"
                          style={{ fontFamily: 'Times New Roman, Georgia, serif', letterSpacing: '0.1em' }}>
                        Parliamentary Sessions
                      </h2>
                      <div className="flex items-center gap-2">
                        <div className="w-20 h-px bg-gradient-to-r from-[#8b7753] to-transparent"></div>
                        <p className="text-[#8b7753] text-sm italic">可用會議列表</p>
                      </div>
                    </div>
                    
                    {/* Create Room Button - Victorian Wax Seal */}
                    <motion.button
                      onClick={onCreateRoom}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      className="relative px-8 py-4"
                      style={{
                        background: 'linear-gradient(135deg, #8b4513 0%, #654321 100%)',
                        border: '3px solid #d4af37',
                        boxShadow: '0 6px 20px rgba(0,0,0,0.6), inset 0 2px 4px rgba(212,175,55,0.3)',
                      }}
                    >
                      <div className="flex items-center gap-3">
                        <Crown className="text-[#d4af37]" size={24} strokeWidth={2} />
                        <span className="text-[#d4af37] tracking-wider text-lg"
                              style={{ fontFamily: 'Georgia, serif' }}>
                          CREATE SESSION
                        </span>
                      </div>
                    </motion.button>
                  </div>
                </div>

                {/* Rooms Grid - Victorian Documents on Desk */}
                <div className="grid grid-cols-3 gap-8">
                  {mockRooms.map((room, index) => (
                    <motion.div
                      key={room.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: index * 0.1 }}
                      whileHover={{ 
                        scale: 1.03,
                        y: -8,
                        rotateZ: hoveredRoom === room.id ? 1 : 0,
                      }}
                      onHoverStart={() => setHoveredRoom(room.id)}
                      onHoverEnd={() => setHoveredRoom(null)}
                      className="cursor-pointer relative"
                    >
                      {/* Victorian document/letter */}
                      <div 
                        className="relative p-6 h-56"
                        style={{
                          background: room.status === 'playing'
                            ? 'linear-gradient(135deg, #f5e6d3 0%, #e8d4bc 100%)'
                            : 'linear-gradient(135deg, #faf6ef 0%, #f0e6d8 100%)',
                          border: '2px solid #8b7753',
                          boxShadow: hoveredRoom === room.id
                            ? '0 16px 40px rgba(139, 119, 83, 0.6), 0 0 0 3px #d4af37'
                            : '0 8px 24px rgba(139, 119, 83, 0.4)',
                        }}
                      >
                        {/* Aged paper texture */}
                        <div className="absolute inset-0 opacity-20 mix-blend-multiply"
                             style={{
                               backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(139, 119, 83, 0.1) 2px, rgba(139, 119, 83, 0.1) 4px)',
                             }}></div>

                        {/* Decorative corner stamps */}
                        <div className="absolute top-2 left-2 w-8 h-8 opacity-30">
                          <svg viewBox="0 0 32 32" className="w-full h-full text-[#8b7753]">
                            <circle cx="16" cy="16" r="14" fill="none" stroke="currentColor" strokeWidth="1"/>
                            <path d="M16 8 L20 12 L16 16 L12 12 Z" fill="currentColor"/>
                          </svg>
                        </div>

                        {/* Status ribbon */}
                        <div className="absolute -top-2 -right-2 px-4 py-2"
                             style={{
                               background: room.status === 'playing' 
                                 ? 'linear-gradient(135deg, #8b0000 0%, #6e0000 100%)' 
                                 : 'linear-gradient(135deg, #4a7c59 0%, #3d6548 100%)',
                               border: '2px solid #d4af37',
                               transform: 'rotate(5deg)',
                               boxShadow: '0 2px 8px rgba(0,0,0,0.4)',
                             }}>
                          <span className="text-[#f5e6d3] text-xs uppercase tracking-wider"
                                style={{ fontFamily: 'Georgia, serif' }}>
                            {room.status === 'playing' ? '進行中' : '等待中'}
                          </span>
                        </div>

                        {/* Content */}
                        <div className="relative z-10 h-full flex flex-col pt-4">
                          {/* Title with decorative underline */}
                          <h3 className="text-[#5c4a33] mb-1 text-xl"
                              style={{ fontFamily: 'Times New Roman, Georgia, serif' }}>
                            {room.title}
                          </h3>
                          <div className="w-16 h-px bg-[#8b7753] mb-3"></div>
                          
                          {/* Host info */}
                          <div className="flex items-center gap-2 mb-2">
                            <Shield size={14} className="text-[#8b7753]" />
                            <p className="text-[#8b7753] text-sm italic">
                              {room.host}
                            </p>
                          </div>

                          {/* Difficulty badge */}
                          <div className="mb-4">
                            <span className="inline-block px-2 py-1 text-xs border"
                                  style={{
                                    borderColor: '#8b7753',
                                    color: '#5c4a33',
                                    fontFamily: 'Georgia, serif',
                                  }}>
                              {room.difficulty}
                            </span>
                          </div>

                          <div className="mt-auto">
                            {/* Player count with Victorian styling */}
                            <div className="flex items-center gap-2 mb-2">
                              <Users size={16} className="text-[#5c4a33]" />
                              <span className="text-[#5c4a33] text-sm"
                                    style={{ fontFamily: 'Georgia, serif' }}>
                                {room.players} / {room.maxPlayers} Members
                              </span>
                            </div>
                            <div className="h-2 border"
                                 style={{ borderColor: '#8b7753', background: '#f5e6d3' }}>
                              <div 
                                className="h-full transition-all duration-300"
                                style={{ 
                                  width: `${(room.players / room.maxPlayers) * 100}%`,
                                  background: 'linear-gradient(90deg, #d4af37 0%, #b8941f 100%)',
                                }}
                              ></div>
                            </div>
                          </div>
                        </div>

                        {/* Wax seal */}
                        <div 
                          className="absolute -bottom-4 -right-4 w-16 h-16 rounded-full flex items-center justify-center"
                          style={{
                            background: room.status === 'playing'
                              ? 'radial-gradient(circle, #8b0000 0%, #6e0000 100%)'
                              : 'radial-gradient(circle, #d4af37 0%, #b8941f 100%)',
                            border: '3px solid #3d2817',
                            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.6), inset 0 1px 2px rgba(255, 255, 255, 0.3)',
                          }}
                        >
                          <Crown size={24} className="text-[#3d2817]" strokeWidth={2.5} />
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </motion.div>
            </div>

            {/* Right Side - Victorian Portrait Panel */}
            <motion.div 
              className="w-[420px] relative"
              initial={{ x: 100, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ duration: 0.8, delay: 0.4 }}
              style={{
                background: 'linear-gradient(to left, #2d1810 0%, rgba(45, 24, 16, 0.8) 100%)',
                borderLeft: '3px solid #d4af37',
                boxShadow: 'inset 4px 0 20px rgba(0, 0, 0, 0.6)',
              }}
            >
              {/* Victorian wallpaper pattern */}
              <div className="absolute inset-0 opacity-10"
                   style={{
                     backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 40px, rgba(212, 175, 55, 0.2) 40px, rgba(212, 175, 55, 0.2) 42px)',
                   }}></div>

              <div className="relative h-full flex flex-col p-8">
                {/* Ornate header */}
                <div className="text-center mb-6">
                  <h3 className="text-2xl text-[#d4af37] mb-2"
                      style={{ fontFamily: 'Times New Roman, Georgia, serif', letterSpacing: '0.1em' }}>
                    Speaker of the House
                  </h3>
                  <div className="flex justify-center items-center gap-2">
                    <div className="w-12 h-px bg-[#8b7753]"></div>
                    <Crown size={16} className="text-[#8b7753]" />
                    <div className="w-12 h-px bg-[#8b7753]"></div>
                  </div>
                </div>

                {/* Character portrait with ornate Victorian frame */}
                <div className="flex-1 relative mb-6">
                  {/* Portrait frame */}
                  <div className="absolute inset-0 border-8 pointer-events-none z-20"
                       style={{
                         borderColor: '#d4af37',
                         boxShadow: 'inset 0 0 30px rgba(0, 0, 0, 0.6), 0 4px 20px rgba(212, 175, 55, 0.4)',
                       }}>
                    {/* Inner decorative border */}
                    <div className="absolute inset-2 border-2 border-[#8b7753] opacity-60"></div>
                  </div>

                  {/* Corner ornaments */}
                  <div className="absolute -top-4 -left-4 w-16 h-16 z-30">
                    <svg viewBox="0 0 64 64" className="w-full h-full text-[#d4af37]">
                      <path d="M0,16 L16,0 L48,0 Q56,8 64,16 L64,32 L60,32 L60,20 Q54,12 48,6 L20,6 L6,20 L6,48 Q12,54 18,58 L18,62 Q8,56 0,48 Z" fill="currentColor"/>
                    </svg>
                  </div>
                  <div className="absolute -top-4 -right-4 w-16 h-16 z-30 transform scale-x-[-1]">
                    <svg viewBox="0 0 64 64" className="w-full h-full text-[#d4af37]">
                      <path d="M0,16 L16,0 L48,0 Q56,8 64,16 L64,32 L60,32 L60,20 Q54,12 48,6 L20,6 L6,20 L6,48 Q12,54 18,58 L18,62 Q8,56 0,48 Z" fill="currentColor"/>
                    </svg>
                  </div>

                  {/* Character image */}
                  <div className="relative h-full overflow-hidden"
                       style={{ background: 'linear-gradient(to bottom, #3d2817 0%, #2d1810 100%)' }}>
                    <motion.img 
                      src={character4} 
                      alt="Speaker of the House"
                      className="w-full h-full object-contain object-bottom"
                      animate={{ y: [0, -8, 0] }}
                      transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
                      style={{
                        filter: 'sepia(0.1) contrast(1.1) brightness(0.95)',
                      }}
                    />
                    
                    {/* Victorian portrait vignette */}
                    <div className="absolute inset-0 pointer-events-none"
                         style={{
                           background: 'radial-gradient(ellipse at center, transparent 20%, rgba(45, 24, 16, 0.4) 60%, rgba(45, 24, 16, 0.8) 100%)',
                         }}></div>
                  </div>
                </div>

                {/* Victorian dialogue scroll */}
                <motion.div 
                  className="relative"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 1 }}
                >
                  <div className="relative p-5"
                       style={{
                         background: 'linear-gradient(135deg, #faf6ef 0%, #e8d4bc 100%)',
                         border: '3px solid #8b7753',
                         boxShadow: '0 6px 20px rgba(0, 0, 0, 0.6)',
                       }}>
                    {/* Aged paper texture */}
                    <div className="absolute inset-0 opacity-20 mix-blend-multiply"
                         style={{
                           backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 3px, rgba(139, 119, 83, 0.1) 3px, rgba(139, 119, 83, 0.1) 6px)',
                         }}></div>

                    {/* Decorative quote marks */}
                    <div className="absolute top-2 left-2 text-4xl text-[#8b7753] opacity-30 leading-none"
                         style={{ fontFamily: 'Georgia, serif' }}>
                      "
                    </div>

                    <p className="text-[#5c4a33] text-sm leading-relaxed relative z-10 px-4"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      「歡迎蒞臨英國議會。準備好在這場政治角力中展現您的智慧與修養了嗎？願上帝保佑女王陛下。」
                    </p>

                    <div className="absolute bottom-2 right-2 text-4xl text-[#8b7753] opacity-30 leading-none"
                         style={{ fontFamily: 'Georgia, serif' }}>
                      "
                    </div>
                  </div>

                  {/* Decorative nameplate */}
                  <div className="absolute -bottom-4 left-1/2 transform -translate-x-1/2 px-6 py-2"
                       style={{
                         background: 'linear-gradient(135deg, #3d2817 0%, #2d1810 100%)',
                         border: '2px solid #d4af37',
                         boxShadow: '0 4px 12px rgba(0, 0, 0, 0.6)',
                       }}>
                    <p className="text-[#d4af37] text-xs tracking-widest whitespace-nowrap"
                       style={{ fontFamily: 'Georgia, serif' }}>
                      議會議長
                    </p>
                  </div>
                </motion.div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Reusable Victorian/Georgian decorative elements

export function CornerFlourish({ className = "", position = "top-left" }: { className?: string; position?: string }) {
  const getRotation = () => {
    switch (position) {
      case 'top-right': return 'scale-x-[-1]';
      case 'bottom-left': return 'scale-y-[-1]';
      case 'bottom-right': return 'scale-[-1]';
      default: return '';
    }
  };

  return (
    <svg className={`${className} ${getRotation()}`} viewBox="0 0 40 40" fill="currentColor">
      <path d="M0,10 Q0,0 10,0 L30,0 Q35,5 40,10 L40,15 L35,15 Q32,10 30,8 L12,8 Q8,10 5,12 L5,30 Q8,32 10,35 L10,40 Q5,35 0,30 Z" 
            opacity="0.6"/>
      <circle cx="8" cy="8" r="2" opacity="0.8"/>
      <path d="M15,4 L17,6 L15,8 L13,6 Z" opacity="0.7"/>
    </svg>
  );
}

export function DividerLine({ className = "" }: { className?: string }) {
  return (
    <div className={`flex items-center justify-center gap-2 ${className}`}>
      <div className="h-px bg-gradient-to-r from-transparent to-[#d4af37] w-16 opacity-60"></div>
      <div className="w-1.5 h-1.5 bg-[#d4af37] rotate-45 opacity-80"></div>
      <div className="h-px bg-gradient-to-l from-transparent to-[#d4af37] w-16 opacity-60"></div>
    </div>
  );
}

export function CrownIcon({ className = "" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
      <path d="M12 2L15 8L22 9L17 14L18 21L12 18L6 21L7 14L2 9L9 8L12 2Z"/>
    </svg>
  );
}

export function OrnateFrame({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`relative ${className}`}>
      {/* Corner flourishes */}
      <CornerFlourish className="absolute -top-2 -left-2 w-8 h-8 text-[#d4af37] opacity-40 pointer-events-none" position="top-left" />
      <CornerFlourish className="absolute -top-2 -right-2 w-8 h-8 text-[#d4af37] opacity-40 pointer-events-none" position="top-right" />
      <CornerFlourish className="absolute -bottom-2 -left-2 w-8 h-8 text-[#d4af37] opacity-40 pointer-events-none" position="bottom-left" />
      <CornerFlourish className="absolute -bottom-2 -right-2 w-8 h-8 text-[#d4af37] opacity-40 pointer-events-none" position="bottom-right" />
      
      {/* Content */}
      {children}
    </div>
  );
}

export function ParchmentTexture() {
  return (
    <div className="absolute inset-0 opacity-10 mix-blend-overlay pointer-events-none"
         style={{
           backgroundImage: `
             repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(139, 119, 83, 0.3) 2px, rgba(139, 119, 83, 0.3) 3px),
             repeating-linear-gradient(90deg, transparent, transparent 2px, rgba(139, 119, 83, 0.2) 2px, rgba(139, 119, 83, 0.2) 3px)
           `,
         }}>
    </div>
  );
}

export function WaxSeal({ onClick, className = "", broken = false }: { onClick?: () => void; className?: string; broken?: boolean }) {
  return (
    <div 
      onClick={onClick}
      className={`relative cursor-pointer transition-transform duration-300 hover:scale-105 active:scale-95 ${className}`}
    >
      <svg viewBox="0 0 100 100" className={`w-full h-full drop-shadow-xl ${broken ? 'opacity-0 scale-150' : 'opacity-100 scale-100'} transition-all duration-500`}>
        {/* Wax Shape - Irregular Circle */}
        <path d="M50,5 C75,5 95,25 95,50 C95,75 75,95 50,95 C25,95 5,75 5,50 C5,25 25,5 50,5 Z" 
              fill="#8b2500" className="drop-shadow-md" />
        <path d="M50,8 C70,8 88,25 90,50 C92,70 75,90 50,92 C25,90 8,70 10,50 C12,30 30,8 50,8 Z" 
              fill="#a3320b" />
        
        {/* Inner Ring */}
        <circle cx="50" cy="50" r="30" fill="none" stroke="#6e1e00" strokeWidth="2" opacity="0.5" />
        
        {/* Crown Symbol inside */}
        <path d="M35 45 L42 55 L50 40 L58 55 L65 45 L65 65 L35 65 Z" fill="#6e1e00" opacity="0.6" />
        
        {/* Highlight */}
        <path d="M30,20 Q50,10 70,20" stroke="rgba(255,255,255,0.2)" strokeWidth="3" fill="none" />
      </svg>
      
      {/* Label */}
      <div className={`absolute inset-0 flex items-center justify-center pointer-events-none ${broken ? 'opacity-0' : 'opacity-100'} transition-opacity duration-300`}>
        <span className="text-[#3d1200] font-serif font-bold text-xs tracking-widest uppercase mt-12 opacity-70">
          TOP SECRET
        </span>
      </div>
    </div>
  );
}

export function InkStamp({ type = 'voted' }: { type?: 'voted' | 'aye' | 'nay' }) {
  const color = type === 'aye' ? '#2d5a27' : type === 'nay' ? '#8b2500' : '#8b7753';
  const text = type === 'aye' ? 'APPROVED' : type === 'nay' ? 'REJECTED' : 'RECORDED';
  
  return (
    <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-20">
      <div className="border-4 rounded px-6 py-2 rotate-[-15deg] opacity-0 animate-stamp-in"
           style={{ borderColor: color, color: color }}>
        <span className="text-4xl font-black tracking-widest uppercase font-serif" 
              style={{ textShadow: `0 0 2px ${color}` }}>
          {text}
        </span>
      </div>
      <style>{`
        @keyframes stamp-in {
          0% { opacity: 0; transform: scale(3) rotate(0deg); }
          50% { opacity: 1; transform: scale(0.8) rotate(-15deg); }
          70% { transform: scale(1.1) rotate(-15deg); }
          100% { opacity: 0.8; transform: scale(1) rotate(-15deg); }
        }
        .animate-stamp-in {
          animation: stamp-in 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
        }
      `}</style>
    </div>
  );
}

export function AtmosphereParticles() {
  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden z-0">
      {/* Dust particles */}
      {[...Array(20)].map((_, i) => (
        <div
          key={i}
          className="absolute rounded-full bg-[#d4af37]"
          style={{
            width: Math.random() * 2 + 1 + 'px',
            height: Math.random() * 2 + 1 + 'px',
            top: Math.random() * 100 + '%',
            left: Math.random() * 100 + '%',
            opacity: Math.random() * 0.3,
            animation: `float ${Math.random() * 10 + 10}s linear infinite`,
            animationDelay: `-${Math.random() * 10}s`,
          }}
        />
      ))}
      {/* Vignette */}
      <div className="absolute inset-0 bg-[radial-gradient(transparent_0%,rgba(0,0,0,0.6)_100%)]"></div>
      
      <style>{`
        @keyframes float {
          0% { transform: translateY(0) translateX(0); opacity: 0; }
          25% { opacity: 0.3; }
          75% { opacity: 0.3; }
          100% { transform: translateY(-100px) translateX(20px); opacity: 0; }
        }
      `}</style>
    </div>
  );
}
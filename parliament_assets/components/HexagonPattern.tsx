// Civilization VI inspired hexagon patterns and elements

export function HexagonIcon({ className = "", filled = false }: { className?: string; filled?: boolean }) {
  return (
    <svg className={className} viewBox="0 0 100 100" fill={filled ? "currentColor" : "none"} stroke="currentColor" strokeWidth="3">
      <polygon points="50,5 90,27.5 90,72.5 50,95 10,72.5 10,27.5" />
    </svg>
  );
}

export function HexagonPattern({ className = "" }: { className?: string }) {
  return (
    <div className={`absolute inset-0 overflow-hidden pointer-events-none ${className}`}>
      <svg className="w-full h-full opacity-5" viewBox="0 0 400 400">
        <defs>
          <pattern id="hexagons" x="0" y="0" width="80" height="70" patternUnits="userSpaceOnUse">
            <polygon points="40,5 70,22.5 70,57.5 40,75 10,57.5 10,22.5" 
                     fill="none" stroke="currentColor" strokeWidth="1"/>
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#hexagons)"/>
      </svg>
    </div>
  );
}

export function HexagonBadge({ 
  children, 
  className = "", 
  color = "#d4af37" 
}: { 
  children: React.ReactNode; 
  className?: string; 
  color?: string;
}) {
  return (
    <div className={`relative inline-flex items-center justify-center ${className}`}>
      <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 100">
        <polygon 
          points="50,2 95,27.5 95,72.5 50,98 5,72.5 5,27.5" 
          fill={`${color}20`}
          stroke={color}
          strokeWidth="2"
        />
      </svg>
      <div className="relative z-10 px-4 py-2">
        {children}
      </div>
    </div>
  );
}

export function GearIcon({ 
  className = "", 
  spinning = false,
  style = {},
}: { 
  className?: string; 
  spinning?: boolean;
  style?: React.CSSProperties;
}) {
  return (
    <svg 
      className={`${className} ${spinning ? 'animate-spin-slow' : ''}`} 
      style={style}
      viewBox="0 0 24 24" 
      fill="none" 
      stroke="currentColor" 
      strokeWidth="1.5"
    >
      <circle cx="12" cy="12" r="3"/>
      <path d="M12 1v6m0 6v6M1 12h6m6 0h6"/>
      <path d="m4.2 4.2 4.3 4.3m5 5 4.3 4.3M4.2 19.8l4.3-4.3m5-5 4.3-4.3"/>
    </svg>
  );
}

export function ConnectorLine({ 
  className = "", 
  direction = "horizontal" 
}: { 
  className?: string; 
  direction?: "horizontal" | "vertical" | "diagonal";
}) {
  const paths = {
    horizontal: "M0,50 L100,50",
    vertical: "M50,0 L50,100",
    diagonal: "M0,0 L100,100"
  };

  return (
    <svg className={className} viewBox="0 0 100 100" fill="none">
      <path 
        d={paths[direction]} 
        stroke="currentColor" 
        strokeWidth="2" 
        strokeDasharray="5,5"
        opacity="0.3"
      />
      <circle cx="50" cy="50" r="3" fill="currentColor" opacity="0.5"/>
    </svg>
  );
}

export function DataPanel({ 
  title, 
  value, 
  subtitle,
  icon,
  trend,
  className = ""
}: { 
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: React.ReactNode;
  trend?: 'up' | 'down' | 'neutral';
  className?: string;
}) {
  return (
    <div className={`relative ${className}`}>
      <div className="relative border-2 rounded-lg p-3 overflow-hidden"
           style={{
             background: 'rgba(36, 27, 20, 0.8)',
             borderColor: 'rgba(212, 175, 55, 0.4)',
             boxShadow: '0 2px 8px rgba(0, 0, 0, 0.4)',
           }}>
        {/* Corner hex decoration */}
        <div className="absolute top-1 right-1 w-4 h-4 opacity-20">
          <HexagonIcon className="w-full h-full text-[#d4af37]" />
        </div>

        <div className="flex items-start gap-2">
          {icon && (
            <div className="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded"
                 style={{ background: 'rgba(212, 175, 55, 0.1)' }}>
              {icon}
            </div>
          )}
          
          <div className="flex-1 min-w-0">
            <div className="text-[#b8a07e] text-xs uppercase tracking-wider mb-1"
                 style={{ fontFamily: 'Georgia, serif' }}>
              {title}
            </div>
            <div className="text-[#f5e6d3] text-xl tabular-nums flex items-baseline gap-1"
                 style={{ fontFamily: 'Georgia, serif', fontWeight: 'bold' }}>
              {value}
              {trend && (
                <span className={`text-xs ${
                  trend === 'up' ? 'text-[#2d5a27]' :
                  trend === 'down' ? 'text-[#8b2500]' :
                  'text-[#8b7753]'
                }`}>
                  {trend === 'up' ? '↑' : trend === 'down' ? '↓' : '−'}
                </span>
              )}
            </div>
            {subtitle && (
              <div className="text-[#8b7753] text-xs mt-0.5"
                   style={{ fontFamily: 'Georgia, serif' }}>
                {subtitle}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// Add custom animation
export const hexagonStyles = `
  @keyframes spin-slow {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
  .animate-spin-slow {
    animation: spin-slow 20s linear infinite;
  }
`;

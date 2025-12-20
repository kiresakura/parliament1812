// Historically Accurate 1812 British Parliament Characters
// Time Period: Regency Era, 1812

export interface Character {
  id: string;
  nameChinese: string;
  nameEnglish: string;
  title: string;
  party: 'tory' | 'whig' | 'neutral';
  imageAsset: string;
  description: string;
  objective: string;
  historicalContext: string;
}

export const CHARACTERS_1812: Character[] = [
  // TORY PARTY (Government)
  {
    id: 'perceval',
    nameChinese: '斯賓塞·珀西瓦爾',
    nameEnglish: 'Spencer Perceval',
    title: '首相',
    party: 'tory',
    imageAsset: 'character1',
    description: '托利黨首相，主張維護國教會與君主權力。反對天主教解放。',
    objective: '阻止任何削弱國教會地位的改革，維持戰時政府穩定。',
    historicalContext: '1812年5月將遭暗殺（英國史上唯一被暗殺的首相）',
  },
  {
    id: 'liverpool',
    nameChinese: '利物浦伯爵',
    nameEnglish: 'Lord Liverpool',
    title: '戰爭與殖民大臣',
    party: 'tory',
    imageAsset: 'character2',
    description: '托利黨保守派領袖，珀西瓦爾遇刺後將接任首相。',
    objective: '確保戰時內閣穩定，反對激進改革。',
    historicalContext: '羅伯特·詹金遜，將成為在位最長的首相之一（1812-1827）',
  },
  {
    id: 'castlereagh',
    nameChinese: '卡斯爾雷子爵',
    nameEnglish: 'Lord Castlereagh',
    title: '外交大臣',
    party: 'tory',
    imageAsset: 'character3',
    description: '托利黨外交政策主導者，專注於對抗拿破崙。',
    objective: '維持反法同盟，確保外交政策不受內政爭議干擾。',
    historicalContext: '羅伯特·斯圖爾特，將主導維也納會議',
  },
  {
    id: 'eldon',
    nameChinese: '艾爾登勳爵',
    nameEnglish: 'Lord Eldon',
    title: '大法官',
    party: 'tory',
    imageAsset: 'character4',
    description: '極端保守派，堅決反對任何改革。',
    objective: '阻止天主教解放與議會改革，維護既有秩序。',
    historicalContext: '約翰·斯科特，擔任大法官長達25年',
  },
  {
    id: 'vansittart',
    nameChinese: '范西塔特',
    nameEnglish: 'Nicholas Vansittart',
    title: '財政大臣',
    party: 'tory',
    imageAsset: 'character5',
    description: '托利黨財政官員，管理戰時經濟。',
    objective: '確保戰爭經費充足，控制政府開支。',
    historicalContext: '尼古拉斯·范西塔特，將於1812年接任財政大臣',
  },

  // WHIG PARTY (Opposition)
  {
    id: 'grey',
    nameChinese: '格雷伯爵',
    nameEnglish: 'Earl Grey',
    title: '輝格黨領袖',
    party: 'whig',
    imageAsset: 'character1',
    description: '輝格黨領袖，主張議會改革與天主教解放。',
    objective: '推動改革法案，爭取中立議員支持。',
    historicalContext: '查爾斯·格雷，將於1832年推動通過《大改革法案》',
  },
  {
    id: 'holland',
    nameChinese: '霍蘭勳爵',
    nameEnglish: 'Lord Holland',
    title: '輝格黨元老',
    party: 'whig',
    imageAsset: 'character2',
    description: '輝格黨顯赫貴族，支持宗教寬容政策。',
    objective: '推動天主教解放，維護輝格黨傳統價值。',
    historicalContext: '亨利·瓦瑟爾·福克斯，霍蘭府為輝格黨政治沙龍中心',
  },
  {
    id: 'whitbread',
    nameChinese: '塞繆爾·惠特布雷德',
    nameEnglish: 'Samuel Whitbread',
    title: '激進派議員',
    party: 'whig',
    imageAsset: 'character3',
    description: '輝格黨激進派，批評政府戰爭政策與社會不公。',
    objective: '揭露政府腐敗，推動社會改革。',
    historicalContext: '富有的啤酒商，積極支持廢奴運動與勞工權益',
  },
  {
    id: 'brougham',
    nameChinese: '亨利·布魯厄姆',
    nameEnglish: 'Henry Brougham',
    title: '改革派律師',
    party: 'whig',
    imageAsset: 'character4',
    description: '輝格黨改革派，雄辯的議會演說家。',
    objective: '通過雄辯說服議員支持改革。',
    historicalContext: '蘇格蘭律師，將成為大法官並推動法律改革',
  },
  {
    id: 'grenville',
    nameChinese: '格倫維爾勳爵',
    nameEnglish: 'Lord Grenville',
    title: '前首相',
    party: 'whig',
    imageAsset: 'character5',
    description: '前托利黨人，因支持天主教解放而轉投輝格黨。',
    objective: '利用經驗與聲望推動漸進改革。',
    historicalContext: '威廉·格倫維爾，1806-1807年擔任首相的「賢能內閣」',
  },
];

export const PARTY_COLORS = {
  tory: '#1e3a5f', // Royal Blue
  whig: '#cc7722', // Orange/Buff
  neutral: '#8b7753', // Brown
};

export const PARTY_NAMES = {
  tory: { chinese: '托利黨', english: 'TORY PARTY' },
  whig: { chinese: '輝格黨', english: 'WHIG PARTY' },
  neutral: { chinese: '中立', english: 'NEUTRAL' },
};

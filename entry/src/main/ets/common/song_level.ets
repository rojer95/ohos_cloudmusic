export  interface SongLevel {
  value: string;
  label: string;
  level: number;
}

export const SongLevels: Array<SongLevel> = [
  {
    value: 'standard',
    label: '标准音质',
    level: 0,
  },
  {
    value: 'higher',
    label: '较高音质',
    level: 1,
  },
  {
    value: 'exhigh',
    label: '极高音质',
    level: 3,
  },
  {
    value: 'lossless',
    label: '无损音质',
    level: 4,
  },
  {
    value: 'hires',
    label: 'Hi-Res',
    level: 5,
  },
  {
    value: 'jyeffect',
    label: '高清环绕声',
    level: 6,
  },
  {
    value: 'sky',
    label: '沉浸环绕声',
    level: 7,
  },
  {
    value: 'dolby',
    label: '杜比全景声',
    level: 8,
  },
  {
    value: 'jymaster',
    label: '超清母带',
    level: 9,
  },
]
import { Album } from './album';
import { Artist } from './artist';

export class SongDetail {
  name: string = '';
  id: number = 0;
  dt: number = 0
  al?: Album = undefined;
  ar?: Artist [] = [];
}

export  interface  SongPrivilege{
  id: number;
  // 是否为云盘歌曲
  cs: boolean;
  // 小于0时为灰色歌曲, 使用上传云盘的方法解灰后 st == 0
  st: number;
  // 是否「由于版权保护，您所在的地区暂时无法使用。」
  toast: boolean;
  // 免费用户的该歌曲播放音质
  flLevel: string;
  // 当前用户的该歌曲最高试听音质
  plLevel:string;
  // 当前用户的该歌曲最高下载音质
  dlLevel: string;
  maxBrLevel: string;
  playMaxBrLevel:string;
  downloadMaxBrLevel: string;
}

export  interface  SongDetailWithPrivilege {
  detail: SongDetail
  privilege: SongPrivilege
}
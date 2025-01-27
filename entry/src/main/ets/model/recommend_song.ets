import { SongDetail } from './song_detail';

interface  RecommendReason {
  songId: number,
  reason: string,
  reasonId: string,
}
export class RecommendSong {
  dailySongs: SongDetail[] = []
  recommendReasons: RecommendReason[] = []
}
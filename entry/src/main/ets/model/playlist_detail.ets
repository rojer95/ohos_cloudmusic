import { SongDetail } from './song_detail';

export class TrackId {
  id?: number;
  at?: number;
}


export class PlaylistCreator {
  userId?: number;
  nickname?: string;
  avatarUrl?: string;
}


export class Playlist {
  id?: number;
  name?: string;
  tags?: string[];
  coverImgUrl?: string;
  backgroundCoverUrl?: string;
  titleImageUrl?: string;
  detailPageTitle?: string;
  description?: string;
  updateFrequency?: string;
  creator?: PlaylistCreator
  trackIds?: TrackId[];
  tracks?: SongDetail[];
  subscribed?: boolean
  subscribedCount?: number
  cloudTrackCount?: number
  trackCount?: number
  playCount?: number
}

export class PlaylistDetailResponseData {
  playlist?: Playlist
}
import { apiMusicSongDetail } from '../api/music_song_detail';
import { PlaylistItem } from '../api/user_playlist';
import { SongDetailWithPrivilege } from './song_detail';

class BasicDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private originDataArray: T[] = [];

  public totalCount(): number {
    return 0;
  }

  public getData(index: number): T {
    return this.originDataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    })
  }

  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to);
    })
  }

  notifyDatasetChange(operations: DataOperation[]): void {
    this.listeners.forEach(listener => {
      listener.onDatasetChange(operations);
    })
  }
}


export class TrackDataSource extends BasicDataSource<SongDetailWithPrivilege> {
  private dataArray: SongDetailWithPrivilege[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): SongDetailWithPrivilege {
    return this.dataArray[index];
  }


  public clean(): void {
    this.dataArray = []
    this.notifyDataReload();
  }


  public pushData(data: SongDetailWithPrivilege): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }

  public deleteData(index: number): void {
    this.dataArray.splice(index, 1);
    this.notifyDataDelete(index);
  }

  public deleteBySongId(songId: string): void {
    const index = this.dataArray.findIndex(i => String(i.detail.id) === songId);
    if (index !== -1) {
      this.deleteData(index)
    }
  }

  public async pushBySongIds(songIds: Array<string>): Promise<void> {
    const songs = await apiMusicSongDetail(songIds)
    for (const song of songs) {
      this.pushData(song)
    }
  }
}


export class PlaylistDataSource extends BasicDataSource<PlaylistItem> {
  private dataArray: PlaylistItem[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): PlaylistItem {
    return this.dataArray[index];
  }

  public clean(): void {
    this.dataArray = []
    this.notifyDataReload();
  }


  public pushData(data: PlaylistItem): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }
}

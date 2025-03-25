import { debuglog } from '../utils/log';
import { fileIo as fs } from '@kit.CoreFileKit';
import { ListFileOptions } from '@kit.CoreFileKit';
import { SongLevels } from '../common/song_level';


interface CacheFileItem {
  songId: string;
  level: string;
  sort: number
}

export class CacheUtil {
  static findCacheBySongId(songId: string | number): Array<CacheFileItem> {
    const listFileOption: ListFileOptions = {
      recursion: false,
      listNum: 0,
      filter: {
        displayName: [`${songId}_*`],
      }
    };
    const files = fs.listFileSync(getContext().cacheDir, listFileOption);
    const songs = files.filter(i => !i.endsWith('.download')).map(filename => {
      const names = filename.split('_', 2)
      return {
        songId: names[0],
        level: names[1],
        sort: SongLevels.find(s => s.value === names[1])?.level || 0
      } as CacheFileItem
    }).sort((a, b) => b.sort - a.sort)

    debuglog('cache songs', songs)
    return songs
  }


  static loadSongIds() {
    const listFileOption: ListFileOptions = {
      recursion: false,
      listNum: 0,
      filter: {
        displayName: [`*_*`],
      }
    };
    const files = fs.listFileSync(getContext().cacheDir, listFileOption);
    debuglog('cache list', files)
    const songIds: string[] = []
    for (const file of files) {
      if (file.endsWith('.download')) {
        continue;
      }
      const names = file.split('_')
      if (names.length === 2) {
        if (songIds.some(i => i === names[0])) {
          continue;
        }

        songIds.push(names[0])
      }
    }

    return songIds
  }

  static removeBySongId(songId: number | string) {
    const listFileOption: ListFileOptions = {
      recursion: false,
      listNum: 0,
      filter: {
        displayName: [`${songId}_*`],
      }
    };
    const files = fs.listFileSync(getContext().cacheDir, listFileOption);
    const task: Array<Promise<void>> = []
    for (const file of files) {
      task.push(fs.unlink(getContext().cacheDir + '/' + file))
    }

    return Promise.all(task)
  }
}
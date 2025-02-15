import common from '@ohos.app.ability.common';
import { HttpProxyCacheServer, CacheListener, FileNameGenerator, HeaderInjector } from '@ohos/video-cache';
import { debuglog } from '../utils/log';
import { HashMap } from '@kit.ArkTS';
import { fileIo as fs } from '@kit.CoreFileKit';
import { ListFileOptions } from '@kit.CoreFileKit';
import { SongLevels } from '../common/song_level';

export class MyHeaderInject implements HeaderInjector {
  addHeaders(url: string): HashMap<string, string> {
    let header: HashMap<string, string> = new HashMap<string, string>();
    return header;
  }
}

export class MyCacheListener implements CacheListener {
  onCacheAvailable(cacheFilePath: string, url: string, percentsAvailable: number) {
    debuglog('cacheFilePath', cacheFilePath)
    debuglog('url', url)
    debuglog('percentsAvailable', percentsAvailable)
  }
}

export class MyFileNameGenerator implements FileNameGenerator {
  generate(): string {
    const filename = GlobalProxyServer.getInstance().getCurrentFileName() as string
    // debuglog('cache filename', filename)
    return filename
  }
}

export default class GlobalProxyServer {
  private CONTEXT_STR: string = 'getContext';
  private SERVER_STR: string = 'getServer';
  private static instance: GlobalProxyServer;
  private _objects: Map<string, Object | null> = new Map<string, Object | null>();
  private FILE_NAME_STR: string = ''

  private constructor() {
  }

  public static getInstance(): GlobalProxyServer {
    if (!GlobalProxyServer.instance) {
      GlobalProxyServer.instance = new GlobalProxyServer()
    }
    return GlobalProxyServer.instance;
  }

  getContext(): common.UIAbilityContext {
    return this._objects.get(this.CONTEXT_STR) as common.UIAbilityContext;
  }

  setContext(objectClass: common.UIAbilityContext) {
    this._objects.set(this.CONTEXT_STR, objectClass);
  }

  setCurrentFileName(fileName: string) {
    this._objects.set(this.FILE_NAME_STR, fileName);
  }

  getCurrentFileName() {
    return this._objects.get(this.FILE_NAME_STR);
  }

  getServer(): HttpProxyCacheServer {
    return this._objects.get(this.SERVER_STR) as HttpProxyCacheServer;
  }

  setServer(objectClass: HttpProxyCacheServer) {
    try {
      let currentServer: HttpProxyCacheServer = this.getServer();
      currentServer.shutdown()
    } catch (err) {
    }
    this._objects.set(this.SERVER_STR, objectClass);
  }
}

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
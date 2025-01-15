import common from '@ohos.app.ability.common';
import {
  HttpProxyCacheServer,
  HttpProxyCacheServerBuilder,
  CacheListener,
  FileNameGenerator,
  HeaderInjector
} from '@ohos/video-cache';
import { debuglog } from '../utils/log';
import { buffer, HashMap } from '@kit.ArkTS';
import CryptoJS from '@ohos/crypto-js';

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
    debuglog('cache filename', filename)
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
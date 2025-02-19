import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { HttpProxyCacheServer, HttpProxyCacheServerBuilder } from '@ohos/video-cache';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import { emitter } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { apiCheckMusic } from '../api/music_check';
import { apiMusicSongDetail } from '../api/music_song_detail';
import { SongDetail, SongDetailWithPrivilege } from '../model/song_detail';
import { apiMusicSongUrl } from '../api/music_song_url';
import { common, WantAgent, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { apiPlaylistDetails } from '../api/playlist_detail';
import { apiGetLyric } from '../api/lyric';
import { apiLikeList } from '../api/likelist';
import { apiLike } from '../api/like';
import { apiDailyRecommendSongs } from '../api/recommend';
import { apiPersonalFm } from '../api/personal_fm';
import { apiIntelligenceList } from '../api/intelligence_list';
import { apiSemiSong } from '../api/simi_song';
import { apiSemiArtist } from '../api/simi_artist';
import { apiArtistSongs } from '../api/artist_songs';
import { debuglog } from '../utils/log';
import { SongLevel, SongLevels } from '../common/song_level';
import GlobalProxyServer, { CacheUtil, MyCacheListener, MyFileNameGenerator, MyHeaderInject } from './cache';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoginInfo } from './loginInfo';

export type PlayType = 'fm' | 'similarSong' | 'similarArtist' | 'star' | 'playList' | 'dailySongs' | 'ids'

export interface PlayOptions {
  avQueueName?: string;
  songId?: string;
  ids?: string[]
}

export const LoopNextMap: Record<number, number> = {
  0: 1, // 顺序播放 --> 单曲循环
  1: 2, // 单曲循环 --> 表单循环
  2: 3, // 表单循环 --> 随机播放
  3: 0, // 随机播放 --> 顺序播放
}

export const UnLimitLoopNextMap: Record<number, number> = {
  1: 3, // 单曲循环 --> 随机播放
  3: 1, // 随机播放 --> 单曲循环
}


@ObservedV2
class Player {
  /** 应用上下文 **/
  context?: common.UIAbilityContext;
  /** 当前播放列表的唯一ID **/
  uuid?: string;
  /** 当前播放模式 **/
  type?: PlayType;
  /** 播放媒体对象 **/
  avPlayer?: media.AVPlayer;
  /** 播控组件 **/
  avSession?: AVSessionManager.AVSession;
  /** 音频会话管理器 **/
  audioSessionManager?: audio.AudioSessionManager;
  /** 0: 免费或无版权 1: VIP 歌曲 4: 购买专辑  8: 非会员可免费播放低音质，会员可播放高音质及下载 **/
  fee?: number
  /** 是否试听 **/
  isTry?: boolean
  /** 播放列表 **/
  // songs: SongDetail[] = []
  songIds: number[] = []
  /** 缓存列表 **/
  cachedSongs: Map<number, SongDetailWithPrivilege> = new Map([])
  /** 相似歌手列表 **/
  similarArtists: number[] = []
  similarArtistsIndex: number = 0;
  /** 喜欢id列表 **/
  likeList: number[] = []
  /** 当前播放歌曲ID **/
  @Trace songId?: number;
  /** 歌单名称 **/
  @Trace avQueueName?: string;
  /** 歌单id **/
  @Trace avQueueId?: string;
  /** 播放器播放状态 **/
  @Trace playingState: string = 'idle'
  /** 当前播放是否喜欢 **/
  @Trace playingIsFavorite: boolean = false
  /** 当前播放进度 **/
  @Trace playingTime: number = 0
  /** 总时长 **/
  @Trace duration?: number;
  /** 已播放时长 **/
  @Trace time?: number;
  /** 当前播放实际长度（试听） **/
  @Trace playingRealDuration: number = 0;
  /** 当前播放类型 **/
  @Trace playingType: string = '';
  /** 当前播放的歌词 **/
  @Trace playingLyric: string = '';
  /** 循环模式 **/
  @Trace loopMode: number = AVSessionManager.LoopMode.LOOP_MODE_SEQUENCE
  @Trace oldLoopMode?: number = undefined
  /** 当前播放歌曲信息 **/
  @Trace playingTitle: string | undefined = undefined;
  @Trace playingArtist: string | undefined = undefined;
  @Trace playingMediaImage: string | undefined = undefined;
  @Trace playingAlbum: string | undefined = undefined;
  @Trace playingMaxLevel: string | undefined = undefined;
  /** 播放音质等级 standard => 标准,higher => 较高, exhigh=>极高, lossless=>无损, hires=>Hi-Res, jyeffect => 高清环绕声, sky => 沉浸环绕声, jymaster => 超清母带 **/
  @Trace userPlayLevel: string = 'standard';
  @Trace level: string = '';
  /** 是否处于切换音质 **/
  @Trace isToggleLeveling: boolean = false;
  // @Trace toggleUrl: string = ''
  /** 切换音质进度临时保持 **/
  toggleLevelPreTime: undefined | number = undefined;
  /** 当前打开的文件，播放缓存歌曲 **/
  openedCacheFile: undefined | fs.File = undefined
  private _inited: boolean = false
  cacheListener: MyCacheListener = new MyCacheListener()

  @Computed
  get levelName(): string {
    let level: undefined | SongLevel = SongLevels.find(i => i.value === this.level);
    return level?.label || '标准音质'
  }

  @Computed
  get activeLevels(): SongLevel[] {
    const maxLevel = SongLevels.find(l => l.value === this.playingMaxLevel);
    return SongLevels.filter(l => l.level <= (maxLevel?.level || 0))
  }

  constructor(_context: common.UIAbilityContext) {
    this.context = _context
  }

  /**
   * 初始化
   */
  async init(userPlayLevel: string) {
    if (this._inited) {
      return
    }
    let server: HttpProxyCacheServer = new HttpProxyCacheServerBuilder(getContext())
      // Set the cache folder (that is, folder that stores the cached files) to the cache directory of the application sandbox.
      .cacheDirectory(getContext().cacheDir)
      .setFileNameGenerator(new MyFileNameGenerator())
      .maxCacheSize(2048 * 1024 * 1024)
      .setHeaderInjector(new MyHeaderInject())
      .build()
    GlobalProxyServer?.getInstance()?.setServer(server);
    this.avPlayer = await media.createAVPlayer()
    await this.initAudioSessionManager()
    await this.createAudioSession()
    await this.startContinuousTask()
    this.startListener()
    this._inited = true
    debuglog('user cached Level', userPlayLevel)
    this.userPlayLevel = userPlayLevel || 'standard'
  }

  /**
   * 释放资源
   */
  async release() {
    this.stopListener()
    await this.avPlayer?.release()
    this.avPlayer = undefined
    await this.destroyAudioSessionManager()
    await this.destroyAudioSession()
    await this.stopContinuousTask()
    /** 关闭文件 **/
    if (this.openedCacheFile) {
      fs.closeSync(this.openedCacheFile)
    }

    GlobalProxyServer.getInstance().getServer()?.shutdown()
  }

  /**
   * 创建播控中心
   */
  async createAudioSession() {
    if (!this.context) {
      return;
    }

    this.avSession = await AVSessionManager.createAVSession(this.context, 'Player', 'audio')

    // 激活接口要在元数据、控制命令注册完成之后再执行
    await this.avSession.activate();
    debuglog('Player', `session create done : ` + this.avSession.sessionId)
  }

  /**
   * 开启后台任务
   */
  async startContinuousTask() {
    if (!this.context) {
      return
    }
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: "com.rojer.music",
          abilityName: "com.rojer.music.EntryAbility"
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
    const wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);

    try {
      await backgroundTaskManager.startBackgroundRunning(this.context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, wantAgentObj)
      debuglog('Player', `Succeeded in operationing startBackgroundRunning.`)
    } catch (err) {
      debuglog('Player', `Failed to operation startBackgroundRunning. Code is ${err.code}, message is ${err.message}`)
    }
  }

  /**
   * 停止后台任务
   */
  async stopContinuousTask() {
    if (!this.context) {
      return
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      debuglog('Player', `Succeeded in operationing stopBackgroundRunning.`)
    } catch (err) {
      debuglog('Player', `Failed to operation stopBackgroundRunning. Code is ${err.code}, message is ${err.message}`)
    }
  }

  /**
   * 销毁播控中心
   */
  async destroyAudioSession() {
    await this.avSession?.destroy()
    this.avSession = undefined
  }

  async initAudioSessionManager() {
    this.audioSessionManager = audio.getAudioManager().getSessionManager();
    await this.activateAudioSession()
  }

  async destroyAudioSessionManager() {
    if (!this.audioSessionManager) {
      return
    }
    await this.audioSessionManager.deactivateAudioSession()
  }

  async activateAudioSession() {
    if (!this.audioSessionManager) {
      return
    }
    const isActivated = this.audioSessionManager.isAudioSessionActivated();
    if (isActivated) {
      return
    }
    let strategy: audio.AudioSessionStrategy = {
      concurrencyMode: audio.AudioConcurrencyMode.CONCURRENCY_MIX_WITH_OTHERS
    };
    await this.audioSessionManager.activateAudioSession(strategy)
    debuglog('activateAudioSession', 'success')
  }

  /**
   * 开始监听事件
   */
  startListener() {
    if (this.avPlayer) {
      this.avPlayer.on('stateChange', (state) => {
        // AppStorage.setOrCreate('playingState', state)
        this.playingState = state
        debuglog('this.playingState', this.playingState)
        const position: AVSessionManager.PlaybackPosition = {
          elapsedTime: this.time || 0,
          updateTime: new Date().getTime(),
        }
        switch (state) {
          case 'idle':
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_IDLE,
            })
            break;
          case 'initialized':
            // debuglog('state', 'initialized')
            this.avPlayer?.prepare()
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_BUFFERING,
              position,
            })
            break;
          case 'prepared':
            // debuglog('state', 'prepared')
            // debuglog('this.likeList', this.likeList)
            const isFavorite = this.likeList?.some((i: number) => this.songId === i)
            this.avSession?.setAVPlaybackState({
              isFavorite
            })
            // AppStorage.setOrCreate('playingIsFavorite', isFavorite)
            this.playingIsFavorite = isFavorite
            if (this.isToggleLeveling) {
              // 移动到上次位置
              this.avPlayer?.seek(this.toggleLevelPreTime)
              this.time = this.toggleLevelPreTime
            }
            this.avPlayer!.audioInterruptMode = audio.InterruptMode.INDEPENDENT_MODE
            this.activateAudioSession()
            this.avPlayer!.play()
            break;
          case 'playing':
            // debuglog('state', 'playing')
            if (this.isToggleLeveling) {
              this.isToggleLeveling = false
              this.toggleLevelPreTime = undefined
            }
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY,
              position
            })
            break;
          case 'paused':
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
              position
            })
            break;
          case 'completed':
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_COMPLETED,
              position
            })
            if (this.isTry) {
              promptAction.showToast({
                message: '试听已结束'
              })
            }

            // 单曲循环
            if (this.loopMode === AVSessionManager.LoopMode.LOOP_MODE_SINGLE) {
              this.rePlay()
            } else {
              this.playNext()
            }
            break;
          case 'stopped':
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_STOP,
              position
            })
            break;
          case 'released':
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_RELEASED,
              position
            })
            break;
          case 'error':
            this.avSession?.setAVPlaybackState({
              state: AVSessionManager.PlaybackState.PLAYBACK_STATE_ERROR,
              position
            })
            break;
          default:
            break;
        }
      })
      this.avPlayer.on('error', (error) => {
        console.info('error happened,and error message is :' + error.message)
        console.info('error happened,and error code is :' + error.code)
      })

      /**
       * 监听进度条
       */
      this.avPlayer.on('timeUpdate', (time) => {
        // AppStorage.setOrCreate('playingTime', this.time)
        this.time = time
      })

      this.avPlayer.on('audioInterrupt', (info: audio.InterruptEvent) => {
        debuglog('audioInterrupt called,and InterruptEvent info is:', info)
        if (info.eventType === audio.InterruptType.INTERRUPT_TYPE_END &&
          info.forceType === audio.InterruptForceType.INTERRUPT_SHARE &&
          info.hintType === audio.InterruptHint.INTERRUPT_HINT_RESUME) {
          if (this.playingState === 'paused') {
            this.avPlayer?.play()
          }
        }
      })

    }

    if (this.avSession) {
      this.avSession.on('play', () => {
        this.play()
      });

      this.avSession.on('pause', () => {
        this.pause()
      });

      this.avSession.on('stop', () => {
        console.info(`on stop , do stop task`);
      });

      this.avSession.on('playNext', () => {
        this.playNext()
      });

      this.avSession.on('playPrevious', () => {
        this.playPrevious()
      });

      this.avSession.on('seek', (time) => {
        console.info(`on seek , the seek time is ${time}`);
        this.setSeek(time)
      });

      this.avSession.on('setLoopMode', () => {
        this.toggleLoopMode()
      });

      this.avSession.on('toggleFavorite', (assetId) => {
        console.info(`on toggleFavorite , the target asset Id is ${assetId}`);
        const isFavorite = this.likeList?.some((i: number) => `${assetId}` === `${i}`)
        this.like(assetId, !isFavorite)
      });
    }

  }

  /**
   * 停止监听事件
   */
  stopListener() {
    if (this.avPlayer) {
      this.avPlayer.off('stateChange')
      this.avPlayer.off('error')
      // this.avPlayer.off('durationUpdate')
      this.avPlayer.off('timeUpdate')
      this.avPlayer.off('audioInterrupt')
    }

    if (this.avSession) {
      this.avSession.off('play');
      this.avSession.off('pause');
      this.avSession.off('stop');
      this.avSession.off('playNext');
      this.avSession.off('playPrevious');
      this.avSession.off('fastForward');
      this.avSession.off('rewind');
      this.avSession.off('seek');
      this.avSession.off('setSpeed');
      this.avSession.off('setLoopMode');
      this.avSession.off('toggleFavorite');
    }
  }

  /**
   * 播放
   */
  async rePlay() {
    if (this.isToggleLeveling) {
      return
    }

    this.avPlayer?.seek(0)
    this.avPlayer?.play()
  }

  /**
   * 播放
   */
  async play() {
    if (this.isToggleLeveling) {
      return
    }

    // console.log('this.avPlayer?.state', this.avPlayer?.state)
    if (this.avPlayer?.state === 'paused') {
      this.avPlayer?.play()
    }
  }

  /**
   * 暂停
   */
  async pause() {
    if (this.isToggleLeveling) {
      return
    }

    if (this.avPlayer?.state === 'playing') {
      this.avPlayer?.pause()
    }
  }

  /**
   * 修改进度
   * @param time
   */
  async setSeek(time: number) {

    if (this.isToggleLeveling) {
      return
    }

    this.avPlayer?.seek(time)
    this.avSession?.setAVPlaybackState({
      position: {
        elapsedTime: time,
        updateTime: new Date().getTime(),
      }
    })
  }

  /**
   * 添加到缓存列表
   * @param songs
   */
  pushToCache(songs: SongDetailWithPrivilege[]) {
    for (const song of songs) {
      if (!this.cachedSongs.has(song.detail.id)) {
        this.cachedSongs.set(song.detail.id, song)
      }
    }
  }

  pushToIds(songIds: number[]) {
    this.songIds.push(...songIds.filter(i => !this.songIds.includes(i)))
  }

  /**
   * 是否是无限歌单模式
   * @param type
   * @returns
   */
  isUnLimitMode(type?: PlayType) {
    return type && ['fm', 'similarSong', 'similarArtist'].includes(type)
  }

  /**
   * 加载列表并播放
   * @param id 列表id 或者 id集
   * @param type 类型
   * @param options 配置
   * @returns
   */
  async start(targetId: string, targetType: string,
    options?: PlayOptions): Promise<void> {
    try {


      if (!this.avPlayer || !this.avSession) {
        promptAction.showToast({ message: "播放媒体未初始化成功" })
        return
      }

      debuglog('[START TYPE]', targetType)
      debuglog('[START ID]', targetId)
      debuglog('[START OPTIONS]', options)

      let avQueueName: string = '';
      let avQueueId: string = '';

      if (targetType === 'similar_song') {
        targetType = 'similarSong'
      }

      if (targetType === 'userfm') {
        targetType = 'fm'
      }

      let _uuid: string | undefined = `${targetType}_${targetId}`;
      // 重复播放系统歌单，跳过
      if (this.uuid === _uuid) {
        if (!options?.songId) {
          return;
        }

        if (options?.songId === (this.songId || '')) {
          return;
        }

        if (this.songIds.includes(Number(options.songId))) {
          await this.playSong(Number(options.songId))
          return
        }
      }

      if (targetType === 'star') {
        promptAction.showToast({ message: "正在开启心动模式...", alignment: Alignment.Center })
      } else {
        promptAction.showToast({ message: "正在加载歌单...", alignment: Alignment.Center })
      }


      /**
       * 歌单模式
       */
      if (targetType === 'playList' || targetType === 'list' || targetType === 'toplist') {
        const playlist = await apiPlaylistDetails(targetId); // 获取歌单详情
        if (!playlist) {
          promptAction.showToast({ message: "歌单获取失败" })
          return
        }
        // this.pushToCache(playlist.tracks || [])
        this.songIds = (playlist.trackIds?.map(i => i.id || 0) || []).filter(i => !!i)
        avQueueId = `${playlist.id || ''}`
        avQueueName = `${playlist.name || ''}`
      }

      /**
       * 每日推荐
       */
      else if (targetType === 'dailySongs') {
        const dailySongsResponse = await apiDailyRecommendSongs(); // 获取歌单详情
        if (!dailySongsResponse?.dailySongs || dailySongsResponse?.dailySongs?.length === 0) {
          promptAction.showToast({ message: "歌单获取失败" })
          return
        }
        // this.pushToCache(dailySongsResponse?.dailySongs || [])
        this.songIds = (dailySongsResponse?.dailySongs || []).map(i => i.id)
        avQueueName = `每日推荐`
      }

      /**
       * 心动模式
       */
      else if (targetType === 'star' && options?.songId) {
        const playlist = await apiIntelligenceList(options?.songId, targetId, options?.songId); // 获取心动歌单详情
        if (!playlist || playlist.length === 0) {
          promptAction.showToast({ message: "歌单获取失败" })
          return
        }
        // this.pushToCache(playlist || [])
        this.songIds = playlist.map(i => i.id)
        avQueueName = `心动模式`
      }

      /**
       * FM
       */
      else if (targetType === 'fm') {
        this.songIds = []
        await this.loadMoreFmSongs()
        avQueueName = `私人漫游`
      }

      /**
       * 相似歌曲
       */
      else if (targetType === 'similarSong') {
        const songs = await apiMusicSongDetail(targetId.split(',')); // 获取歌单详情
        if (songs?.length === 0) {
          promptAction.showToast({ message: "歌单获取失败" })
          return
        }
        // this.pushToCache(songs)
        this.songIds = songs.map(i => i.detail.id)
        avQueueName = '相似歌曲推荐'
      }

      /**
       * 相似歌手
       */
      else if (targetType === 'similarArtist') {
        this.songIds = [];
        this.similarArtists = targetId.split(',').map(i => Number(i));
        this.similarArtistsIndex = 0;
        await this.loadMoreSemiArtist(); // 获取歌单详情
        avQueueName = '相似歌手推荐'
      }

      /**
       * ids
       */
      else if (targetType === 'ids') {
        const songs = await apiMusicSongDetail(options?.ids || []); // 获取歌单详情
        if (songs?.length === 0) {
          promptAction.showToast({ message: "歌单获取失败" })
          return
        }
        // this.pushToCache(songs)
        this.songIds = songs.map(i => i.detail.id)
        avQueueName = options?.avQueueName || ''
      } else {
        promptAction.showToast({ message: `暂不支持的播放方式: ${targetType}` })
        return
      }

      this.uuid = _uuid
      this.type = targetType as PlayType;
      // AppStorage.setOrCreate('playingType', type)
      this.playingType = targetType;

      /**
       * 无限制模式， 播放循环模式进行变更
       */
      if (this.isUnLimitMode(this.type)) {
        if (!Object.keys(UnLimitLoopNextMap).map(i => Number(i)).includes(this.loopMode)) {
          this.oldLoopMode = this.loopMode // 记录旧的循环模式
          this.updateLoopMode(AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE)
        }
      } else {
        if (this.oldLoopMode !== undefined && this.loopMode !== this.oldLoopMode) {
          // 还原原来的模式
          this.updateLoopMode(this.oldLoopMode)
          this.oldLoopMode = undefined
        }
      }

      let songId: number | undefined = this.songIds?.find(id => options?.songId && id === Number(options?.songId))

      if (!songId) {
        songId = this.songIds?.[0];
      }

      if (!songId) {
        promptAction.showToast({ message: "资源ID不存在" })
        return;
      }


      if (avQueueName) {
        this.avQueueName = avQueueName
      }

      if (avQueueId) {
        this.avQueueId = avQueueId
      }

      await this.playSong(songId)


    } catch (e) {
      debuglog('Player', `play fail code is ${e.code} message is ${e.message}`)
    }
  }

  /**
   * 加载歌词
   * @param id
   * @returns
   */
  private async loadLyric(id: string) {
    const lyric = await apiGetLyric(id);
    return lyric?.lyric
  }

  private async getSongFromCache(songId: number) {
    if (this.cachedSongs.has(songId)) {
      return this.cachedSongs.get(songId);
    }
    const details = await apiMusicSongDetail([String(songId)])
    if (details.length > 0) {
      this.cachedSongs.set(songId, details[0])
      return details[0]
    }
    return undefined
  }

  private playFailAndNext(songId: number, message: string) {
    promptAction.showToast({ message: message })
    this.songId = songId
    setTimeout(() => {
      this.playNext()
    }, 200)
  }

  private async getUrlWithCache(songUrl: string) {
    /** 关闭上一首 **/
    if (this.openedCacheFile) {
      fs.closeSync(this.openedCacheFile)
      this.openedCacheFile = undefined
    }

    GlobalProxyServer.getInstance().setCurrentFileName(`${this.songId}_${this.level}`)
    let tempUrl = await GlobalProxyServer?.getInstance()?.getServer()?.getProxyUrl(songUrl)
    let proxyUrl: string | undefined = tempUrl ? tempUrl : songUrl
    if (proxyUrl.startsWith(this.context!.cacheDir)) {
      this.openedCacheFile = fs.openSync(proxyUrl, fs.OpenMode.READ_ONLY);
      proxyUrl = `fd://${this.openedCacheFile.fd}`;
    }

    debuglog('play url', proxyUrl)
    return proxyUrl
  }

  /**
   * 播放歌曲
   * @param song
   */
  private async playSong(songId: number) {

    if (!this.avPlayer || !this.avSession) {
      promptAction.showToast({ message: "播放媒体未初始化成功" })
      return
    }

    const song = await this.getSongFromCache(songId);

    if (!song) {
      this.playFailAndNext(songId, '歌曲信息加载失败')
      return
    }


    // 时长
    this.duration = song?.detail.dt;
    // 当前播放id
    this.songId = song.detail.id

    const cacheFiles = CacheUtil.findCacheBySongId(songId);

    /**
     * 最大可播放音质
     */
    this.playingMaxLevel = song?.privilege?.plLevel

    if (this.playingMaxLevel === 'none') {
      this.playingMaxLevel = 'standard';
    }

    if (cacheFiles.length === 0) {
      /**
       * 自动调整播放音质
       * 默认按用户选择音质
       * 如果用户选择的音质超过当前音乐可播放最大音质，需要降低音质到最大可播放音质
       */
      this.level = this.userPlayLevel || 'standard';


      const userSelectLevel = SongLevels.find(l => l.value === this.userPlayLevel);
      const maxCanPlayLevel = SongLevels.find(l => l.value === this.playingMaxLevel);

      if (userSelectLevel && maxCanPlayLevel && userSelectLevel?.level > maxCanPlayLevel?.level) {
        this.level = maxCanPlayLevel.value
      }

      debuglog('level adjust to', this.level)

      // 验证版权
      const checkResult = await apiCheckMusic(`${song.detail.id}`);
      if (!checkResult.success) {
        this.playFailAndNext(songId, `亲爱的，暂时还没有《${song?.detail?.name}》的版权`)
        return
      }
    } else {
      // 如有缓存，优先播放最高已缓存的音质
      this.level = cacheFiles[0].level
    }

    const songUrl = await apiMusicSongUrl(`${song.detail.id}`, this.level)
    if (!songUrl) {
      this.playFailAndNext(songId, `获取播放url失败`)
      return
    }

    // 试听
    this.isTry = (songUrl.time || 0) < this.duration;

    // 实际歌曲长度
    this.playingRealDuration = (this.isTry ? songUrl.time : this.duration) || this.duration;

    // 已播放时长
    this.time = 0

    // 加载歌词
    const lyric = await this.loadLyric(String(song.detail.id))


    const playingInfo: AVSessionManager.AVMetadata = {
      assetId: String(song.detail.id),
      title: song.detail?.name,
      artist: song.detail?.ar?.map?.(i => i.name)?.join('/') || '',
      mediaImage: song.detail?.al?.picUrl,
      duration: this.duration,
      album: song.detail?.al?.name,
    }

    this.playingTitle = playingInfo.title
    this.playingArtist = playingInfo.artist
    this.playingMediaImage = playingInfo.mediaImage as string
    this.playingAlbum = playingInfo.album


    if (this.avQueueName) {
      playingInfo.avQueueName = this.avQueueName
    }

    if (this.avQueueId) {
      playingInfo.avQueueId = this.avQueueId
    }

    if (lyric) {
      playingInfo.lyric = lyric
      this.playingLyric = lyric
    }

    const avMetaData: AVSessionManager.AVMetadata = playingInfo
    avMetaData.mediaImage = `${song.detail?.al?.picUrl}?param=300y300`

    debuglog('setPlayingInfo', JSON.stringify(playingInfo))
    debuglog('setAVMetadata', JSON.stringify(avMetaData))

    try {
      await this.avSession?.setAVMetadata(avMetaData)
    } catch (e) {
      promptAction.showToast({
        message: '推送到播控中心失败...'
      })
    }


    if (this.avPlayer.state !== 'idle') {
      await this.avPlayer.reset();
    }

    this.avPlayer.url = await this.getUrlWithCache(songUrl.url)
  }

  /**
   * 切换音质
   * @param level
   */
  async toggleMusicLevel(level: string) {
    const songUrl = await apiMusicSongUrl(`${this.songId}`, level)
    if (!songUrl || !this.avPlayer) {
      promptAction.showToast({
        message: '切换音质失败'
      })
      return
    }

    this.userPlayLevel = level // 保存用户选择音质
    let eventData: emitter.EventData = {
      data: {
        level
      }
    }
    emitter.emit('userPlayLevelChange', eventData)
    this.level = level // 设置当前播放音质
    this.isToggleLeveling = true;
    this.toggleLevelPreTime = this.time
    if (this.avPlayer.state !== 'idle') {
      await this.avPlayer.reset();
    }
    this.avPlayer.url = await this.getUrlWithCache(songUrl.url);
  }

  /**
   * 随机数
   * @param min
   * @param max
   * @returns
   */
  private randomIndex(min: number, max: number) {
    return Math.floor(Math.random() * (max - min + 1)) + min
  }

  /**
   * 加载相似歌手
   */
  private async loadMoreSemiArtist() {
    const currentIndex = this.songIds.findIndex(id => id === this.songId);
    if ((currentIndex + 1 >= this.songIds.length || currentIndex === -1)) {
      // 获取歌手id
      let artistId = this.similarArtists?.[this.similarArtistsIndex];
      this.similarArtistsIndex++;
      debuglog('artistId', artistId)

      if (!artistId) {
        // 不存在歌手id，拉取相似歌手
        const artists = await apiSemiArtist(String(this.similarArtists[0]))
        this.similarArtists.push(...artists.map(i => i.id))
        artistId = this.similarArtists?.[this.similarArtistsIndex];
      }


      debuglog('artistId', artistId)

      if (artistId) {
        const songs = await apiArtistSongs(String(artistId));
        const song = songs[this.randomIndex(0, songs.length - 1)]
        // this.pushToCache([song])
        this.pushToIds([song.id])
      }
    }
  }

  /**
   * 加载相似歌曲
   */
  private async loadMoreSemiSongs() {
    const currentIndex = this.songIds.findIndex(id => id === this.songId);
    if ((currentIndex + 1 >= this.songIds.length || currentIndex === -1) && this.songId) {
      try {
        const fmSongs = await apiSemiSong(String(this.songId))
        const songs = fmSongs.map(fmSong => fmSong as SongDetail);
        // this.pushToCache(songs)
        this.pushToIds(songs.map(i => i.id))
      } catch (e) {
        console.error(e.stack)
      }
    }
  }

  /**
   * 加载FM
   */
  private async loadMoreFmSongs() {
    const currentIndex = this.songIds.findIndex(id => id === this.songId);
    if (currentIndex + 1 >= this.songIds.length || currentIndex === -1) {
      const fmSongs = await apiPersonalFm()
      const songs = fmSongs.map(fmSong => fmSong as SongDetail)
      // this.pushToCache(songs)
      this.pushToIds(songs.map(i => i.id))
    }
  }

  /**
   * 播放下一首
   */
  async playNext() {
    if (this.isToggleLeveling) {
      return
    }
    if (this.songIds.length === 0) {
      return
    }

    let index = this.songIds.findIndex(id => id === this.songId)

    if (index < 0) {
      return;
    }

    let songId: number | undefined = undefined
    let handleMode = this.loopMode;
    console.log('[PLAY NEXT TYPE]', this.type)
    console.log('[PLAY NEXT CURRENT INDEX]', index)
    console.log('[PLAY NEXT SONG LENGTH]', this.songIds.length)

    /**
     * 用户点击下一首
     * 无限制模式 & 单区循环模式
     * 实际是以顺序播放进行的
     */
    if (this.isUnLimitMode(this.type) || handleMode === AVSessionManager.LoopMode.LOOP_MODE_SINGLE) {
      handleMode = AVSessionManager.LoopMode.LOOP_MODE_SEQUENCE
    }


    if (this.type === 'similarArtist') {
      // 加载更多相似歌手的曲
      await this.loadMoreSemiArtist()
    }


    if (this.type === 'similarSong') {
      // 加载更多相似歌曲
      await this.loadMoreSemiSongs()
    }

    if (this.type === 'fm') {
      // 加载更多FM歌曲
      await this.loadMoreFmSongs()
    }


    // 顺序播放
    if (handleMode === AVSessionManager.LoopMode.LOOP_MODE_SEQUENCE) {
      songId = this.songIds?.[index + 1]
    }


    // 表单循环
    if (handleMode === AVSessionManager.LoopMode.LOOP_MODE_LIST) {
      if (index + 1 > this.songIds?.length - 1) {
        songId = this.songIds[0] // 回第一首
      } else {
        songId = this.songIds?.[index + 1]
      }
    }

    // 随机播放
    if (handleMode === AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE) {
      songId = this.songIds?.[this.randomIndex(0, this.songIds.length - 1)]
    }

    if (songId !== undefined) {
      await this.playSong(songId)
    } else {
      promptAction.showToast({ message: '已经到最后一首了' })
    }
  }

  /**
   * 播放上一首
   */
  async playPrevious() {

    if (this.isToggleLeveling) {
      return
    }

    if (this.songIds.length === 0) {
      return
    }

    let index = this.songIds.findIndex(id => id === this.songId)

    if (index < 0) {
      return;
    }

    let songId: number | undefined = undefined

    let handleMode = this.loopMode;


    /**
     * 用户点击下一首
     * 无限制模式 & 单区循环模式
     * 实际是以顺序播放进行的
     */
    if (this.isUnLimitMode(this.type) || handleMode === AVSessionManager.LoopMode.LOOP_MODE_SINGLE) {
      handleMode = AVSessionManager.LoopMode.LOOP_MODE_SEQUENCE
    }


    // 顺序播放
    if (handleMode === AVSessionManager.LoopMode.LOOP_MODE_SEQUENCE) {
      songId = this.songIds?.[index - 1]
    }

    // 表单循环
    if (handleMode === AVSessionManager.LoopMode.LOOP_MODE_LIST) {
      if (index === 0) {
        songId = this.songIds[this.songIds?.length - 1] // 最后一首
      } else {
        songId = this.songIds?.[index - 1]
      }
    }

    // 随机播放
    if (handleMode === AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE) {
      songId = this.songIds?.[this.randomIndex(0, this.songIds.length - 1)]
    }

    if (songId !== undefined) {
      await this.playSong(songId)
    } else {
      promptAction.showToast({ message: '前面没有歌曲了' })
    }

  }

  /**
   * 切换播放模式
   */
  toggleLoopMode() {
    if (this.isUnLimitMode(this.type)) {
      this.updateLoopMode(UnLimitLoopNextMap[this.loopMode])
    } else {
      this.updateLoopMode(LoopNextMap[this.loopMode])
    }
  }

  /**
   * 更新播放模式
   * @param mode
   */
  updateLoopMode(mode: AVSessionManager.LoopMode) {
    // AppStorage.setOrCreate('playingLoopMode', mode)
    this.loopMode = mode
    this.avSession?.setAVPlaybackState({
      loopMode: mode
    })
  }

  /**
   * 加载喜欢列表
   */
  async loadLikeList() {
    if (this._inited) {
      this.likeList = await apiLikeList()
    }
  }

  /**
   * 喜欢/不喜欢
   * @param id
   * @param like
   */
  async like(id: number | string, like: boolean) {
    await apiLike(id, like)
    if (like) {
      this.likeList.push(Number(id))
    } else {
      this.likeList = this.likeList.filter(i => i !== Number(id))
    }

    if (this.songId === Number(id)) {
      const isFavorite = like;
      this.avSession?.setAVPlaybackState({
        isFavorite
      })
      // AppStorage.setOrCreate('playingIsFavorite', isFavorite)
      this.playingIsFavorite = isFavorite
    }
  }
}


export { Player }
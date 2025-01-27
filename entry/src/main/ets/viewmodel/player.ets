import { media } from '@kit.MediaKit';
import { apiCheckMusic } from '../api/music_check';
import { apiMusicSongDetail } from '../api/music_song_detail';
import { SongDetail, SongDetailWithPrivilege } from '../model/song_detail';
import { apiMusicSongUrl } from '../api/music_song_url';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import hilog from '@ohos.hilog';
import { promptAction } from '@kit.ArkUI';
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
import { HttpProxyCacheServer, HttpProxyCacheServerBuilder } from '@ohos/video-cache';
import GlobalProxyServer, { MyCacheListener, MyFileNameGenerator, MyHeaderInject } from './cache';
import fs from '@ohos.file.fs'

export type PlayType = string

export interface PlayOptions {
  avQueueName?: string;
  songId?: string;
}

export const LoopNextMap: Record<number, number> = {
  0: 1, // 顺序播放 --> 单曲循环
  1: 2, // 单曲循环 --> 表单循环
  2: 3, // 表单循环 --> 随机播放
  3: 0, // 随机播放 --> 顺序播放
}

export const FmLoopNextMap: Record<number, number> = {
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
  type?: string;
  /** 播放媒体对象 **/
  avPlayer?: media.AVPlayer;
  /** 播控组件 **/
  avSession?: AVSessionManager.AVSession;
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
  @Trace level: string = '';
  /** 是否处于切换音质 **/
  @Trace isToggleLeveling: boolean = false;
  /** 切换音质进度临时保持 **/
  toggleLevelPreTime: undefined | number = undefined;
  /** 当前打开的文件，播放缓存歌曲 **/
  openedCacheFile: undefined | fs.File = undefined
  private _inited: boolean = false

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
  async init() {
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
    await this.createAudioSession()
    await this.startContinuousTask()
    this.startListener()
    this._inited = true
  }

  /**
   * 释放资源
   */
  async release() {
    this.stopListener()
    await this.avPlayer?.release()
    this.avPlayer = undefined
    await this.destroyAudioSession()
    await this.stopContinuousTask()
    /** 关闭文件 **/
    if (this.openedCacheFile) {
      fs.closeSync(this.openedCacheFile)
    }
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
    hilog.info(0x0000, 'Player', `session create done : %{public}s`, this.avSession.sessionId);
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
      hilog.info(0, 'Player', `Succeeded in operationing startBackgroundRunning.`);
    } catch (err) {
      hilog.error(0, 'Player',
        `Failed to operation startBackgroundRunning. Code is %{public}d, message is %{public}s`, err.code, err.message
      );
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
      hilog.info(0, 'Player', `Succeeded in operationing stopBackgroundRunning.`);
    } catch (err) {
      hilog.error(0, 'Player',
        `Failed to operation stopBackgroundRunning. Code is %{public}d, message is %{public}s`, err.code, err.message
      );
    }
  }

  /**
   * 销毁播控中心
   */
  async destroyAudioSession() {
    await this.avSession?.destroy()
    this.avSession = undefined
  }

  /**
   * 开始监听事件
   */
  startListener() {
    if (this.avPlayer) {
      this.avPlayer.on('stateChange', (state) => {
        // AppStorage.setOrCreate('playingState', state)
        this.playingState = state
        debuglog('this.playingState',this.playingState)
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
            this.avPlayer?.play()
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
    this.songIds.push(...songIds.filter(i =>!this.songIds.includes(i)))
  }

  /**
   * 加载列表并播放
   * @param id 列表id 或者 id集
   * @param type 类型
   * @param options 配置
   * @returns
   */
  async start(id: string, type: PlayType, options?: PlayOptions): Promise<void> {
    try {


      if (!this.avPlayer || !this.avSession) {
        promptAction.showToast({ message: "播放媒体未初始化成功" })
        return
      }

      debuglog('[START TYPE]', type)
      debuglog('[START ID]', id)
      debuglog('[START OPTIONS]', options)

      let avQueueName: string = '';
      let avQueueId: string = '';

      if (type === 'similar_song') {
        type = 'similarSong'
      }

      if (type === 'userfm') {
        type = 'fm'
      }

      let _uuid: string | undefined = `${type}_${id}`;
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

      if (type === 'star') {
        promptAction.showToast({ message: "正在开启心动模式...", alignment: Alignment.Center })
      } else {
        promptAction.showToast({ message: "正在加载歌单...", alignment: Alignment.Center })
      }


      /**
       * 歌曲模式
       */
      if (type === 'song') {
        this.songIds = [Number(id)]
        avQueueName = '歌曲'
      }

      /**
       * 歌单模式
       */
      else if (type === 'playList' || type === 'list' || type === 'toplist') {
        const playlist = await apiPlaylistDetails(id); // 获取歌单详情
        if (!playlist) {
          promptAction.showToast({ message: "歌单获取失败" })
          return
        }
        // this.pushToCache(playlist.tracks || [])
        this.songIds = (playlist.trackIds?.map(i => i.id || 0) || []).filter(i =>!!i)
        avQueueId = `${playlist.id || ''}`
        avQueueName = `${playlist.name || ''}`
      }

      /**
       * 每日推荐
       */
      else if (type === 'dailySongs') {
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
      else if (type === 'star' && options?.songId) {
        const playlist = await apiIntelligenceList(options?.songId, id, options?.songId); // 获取心动歌单详情
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
      else if (type === 'fm') {
        this.songIds = []
        await this.loadMoreFmSongs()
        avQueueName = `私人漫游`
      }

      /**
       * 相似歌曲
       */
      else if (type === 'similarSong') {
        const songs = await apiMusicSongDetail(id.split(',')); // 获取歌单详情
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
      else if (type === 'similarArtist') {
        this.songIds = [];
        this.similarArtists = id.split(',').map(i => Number(i));
        this.similarArtistsIndex = 0;
        await this.loadMoreSemiArtist(); // 获取歌单详情
        avQueueName = '相似歌手推荐'
      }

      /**
       * ids
       */
      else if (type === 'ids') {
        const songs = await apiMusicSongDetail(id.split(',')); // 获取歌单详情
        if (songs?.length === 0) {
          promptAction.showToast({ message: "歌单获取失败" })
          return
        }
        // this.pushToCache(songs)
        this.songIds = songs.map(i => i.detail.id)
        avQueueName = options?.avQueueName || ''
      } else {
        promptAction.showToast({ message: `暂不支持的播放方式: ${type}` })
        return
      }

      this.uuid = _uuid
      this.type = type;
      // AppStorage.setOrCreate('playingType', type)
      this.playingType = type;

      /**
       * FM 模式， 播放循环模式进行变更
       */
      if (
      ['fm', 'similarSong', 'similarArtist'].includes(this.type)
      ) {
        if (![AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE,
          AVSessionManager.LoopMode.LOOP_MODE_SINGLE].includes(this.loopMode)) {
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
      hilog.error(0, 'Player', 'play fail: %{public}s', e.message)
      hilog.error(0, 'Player', 'play fail: %{public}s', e.stack)
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

    debuglog('proxyUrl', proxyUrl)
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

    /**
     * 检查是否可播放
     */
    const checkResult = await apiCheckMusic(`${song.detail.id}`);
    // console.log('check ---> ', JSON.stringify(checkResult))

    if (!checkResult.success) {
      this.playFailAndNext(songId, `亲爱的，暂时还没有《${song?.detail?.name}》的版权`)
      return
    }

    /**
     * 获取播放url
     */

    this.playingMaxLevel = song?.privilege?.plLevel

    if (this.playingMaxLevel === 'none') {
      this.playingMaxLevel = 'standard';
    }


    debuglog('this.playingMaxLevel', this.playingMaxLevel)
    /**
     * 如果当前音质超过最大音质，需要降低音质
     */
    if (!this.level) {
      this.level = this.playingMaxLevel || 'standard';
    }


    const currentLevel = SongLevels.find(l => l.value === this.level);
    const maxLevel = SongLevels.find(l => l.value === this.playingMaxLevel);

    if (currentLevel && maxLevel && currentLevel?.level > maxLevel?.level) {
      this.level = this.playingMaxLevel || 'standard';
    }

    debuglog('this.level', this.level)


    const songUrl = await apiMusicSongUrl(`${song.detail.id}`, this.level)

    if (!songUrl) {
      this.playFailAndNext(songId, `获取播放url失败`)
      return
    }

    // 时长
    this.duration = song?.detail.dt;

    // 试听
    this.isTry = (songUrl.time || 0) < this.duration;

    // 已播放时长
    this.time = 0

    // 当前播放id
    this.songId = song.detail.id


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
      // AppStorage.setOrCreate('playingLyric', lyric)
      this.playingLyric = lyric
    }

    const avMetaData: AVSessionManager.AVMetadata = playingInfo
    avMetaData.mediaImage = `${song.detail?.al?.picUrl}?param=300y300`

    hilog.info(0, 'Player', 'setPlayingInfo: %{public}s', JSON.stringify(playingInfo))
    hilog.info(0, 'Player', 'setAVMetadata: %{public}s', JSON.stringify(avMetaData))

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
    // AppStorage.setOrCreate('playingInfo', playingInfo)
    // AppStorage.setOrCreate('playingDuration', this.duration)
    // AppStorage.setOrCreate('playingRealDuration', songUrl.time || this.duration)
    // AppStorage.setOrCreate('playingTime', this.time)

    this.playingRealDuration = songUrl.time || this.duration
    // this.playingTime = this.time
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

    this.level = level
    this.isToggleLeveling = true;
    this.toggleLevelPreTime = this.time

    if (this.avPlayer.state !== 'idle') {
      await this.avPlayer.reset();
    }

    this.avPlayer.url = await this.getUrlWithCache(songUrl.url)
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

      if (!artistId) {
        // 不存在歌手id，拉取相似歌手
        const artists = await apiSemiArtist(String(this.similarArtists[0]))
        this.similarArtists.push(...artists.map(i => i.id))
        artistId = this.similarArtists?.[this.similarArtistsIndex];
      }


      if (artistId) {
        const songs = await apiArtistSongs(String(artistId));
        const song = songs[this.randomIndex(0, Math.min(4, songs.length - 1))]
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
     * FM 模式下: 只有顺序模式
     */
    if (['fm', 'similarSong', 'similarArtist'].includes(this.type || '')) {
      handleMode = AVSessionManager.LoopMode.LOOP_MODE_SEQUENCE

      if (['similarArtist'].includes(this.type || '')) {
        await this.loadMoreSemiArtist()
        // 加载更多相似歌曲
      }


      if (['similarSong'].includes(this.type || '')) {
        await this.loadMoreSemiSongs()
        // 加载更多相似歌曲

        debuglog('songIds', this.songIds)
      }

      if (['fm'].includes(this.type || '')) {
        await this.loadMoreFmSongs()
        // 加载更多FM歌曲
      }
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
      promptAction.showToast({ message: '没有可播放的歌曲' })
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
     * FM 模式下: 只有顺序模式
     */
    if (['fm', 'similarSong', 'similarArtist'].includes(this.type || '')) {
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
      promptAction.showToast({ message: '没有可播放的歌曲' })
    }

  }

  /**
   * 切换播放模式
   */
  toggleLoopMode() {
    if (['fm', 'similarSong', 'similarArtist'].includes(this.type || '')) {
      this.updateLoopMode(FmLoopNextMap[this.loopMode])
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
    this.likeList = await apiLikeList()
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
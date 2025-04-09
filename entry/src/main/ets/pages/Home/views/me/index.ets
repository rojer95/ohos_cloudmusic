import { LengthMetrics, PersistenceV2, promptAction, SwipeRefresher } from "@kit.ArkUI"
import { LoginInfo } from "../../../../viewmodel/loginInfo"
import { ImageKnifeComponent } from "@ohos/imageknife";
import { userDetailApi, UserDetailResponseBody } from "../../../../api/user_detail";
import { debuglog } from "../../../../utils/log";
import emitter from '@ohos.events.emitter';
import { PlaylistItem, userPlaylistApi } from "../../../../api/user_playlist";
import { PlaylistDataSource, TrackDataSource } from "../../../../model/datasource";
import { Utils } from '../../../../common/utils'
import { Player } from "../../../../viewmodel/player";
import { getGlobal, getPlayer, GlobalContent } from "../../../../viewmodel/global";
import { CacheUtil } from '../../../../viewmodel/cache';
import { CommonSongList } from "../../../../components/common_song_list";
import { getInvateUrl } from "../../../../api/invate";
import { pasteboard } from "@kit.BasicServicesKit";
import { INTERVAL } from "../../../../common/vars";


@ObservedV2
class UserDetail {
  @Trace nickname?: string
  @Trace signature?: string;
  @Trace backgroundUrl?: string
  @Trace avatarUrl?: string
  @Trace follows?: number
  @Trace followeds?: number
  @Trace level?: number
  @Trace createDays?: number

  @Computed
  get createYear() {
    return Math.floor((this.createDays || 0) / 365)
  }

  fill(data: UserDetailResponseBody) {
    this.nickname = data?.profile?.nickname;
    this.signature = data?.profile?.signature;
    this.backgroundUrl = data?.profile?.backgroundUrl;
    this.avatarUrl = data?.profile?.avatarUrl;
    this.follows = data?.profile?.follows;
    this.followeds = data?.profile?.followeds;
    this.level = data?.level;
    this.createDays = data?.createDays;
  }
}

interface TabItem {
  key: 'myPlaylist' | 'collectPlaylist' | 'cached';
  name: string;
}

@ComponentV2
export struct MeTabContent {
  tabs: Array<TabItem> = [
    { key: 'myPlaylist', name: '创建的歌单' },
    { key: 'collectPlaylist', name: '收藏的歌单' },
    { key: 'cached', name: '缓存歌曲' },
  ]
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Local detail?: UserDetail = undefined
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local player: Player | undefined = getPlayer()
  @Local global: GlobalContent | undefined = getGlobal()
  @Local playlistLoading: boolean = false
  @Local isPlaylistNotMore: boolean = false
  @Local isCacheSongNotMore: boolean = false
  @Local cacheSongLoading: boolean = false
  @Local tabKey: 'myPlaylist' | 'collectPlaylist' | 'cached' | 'cached' = 'myPlaylist'
  @Local cachedSongIds: Array<string> = [];
  @Local invateUrl: string = '';
  private playlist: PlaylistDataSource = new PlaylistDataSource();
  private scroller: Scroller = new Scroller()
  private cacheDatasource = new TrackDataSource()

  @Monitor('tabKey')
  onTabKeyChange() {

    if (this.tabKey === 'myPlaylist') {
      this.loadPlaylist(true)
    }

    if (this.tabKey === 'collectPlaylist') {
      this.loadPlaylist(false)
    }


    if (this.tabKey === 'cached') {
      this.loadCachedList()
    }
  }

  aboutToAppear(): void {
    this.load()
    this.loadInvateUrl()
    this.onEventListing()
  }

  aboutToDisappear(): void {
    this.offEventListing()
  }

  loadInvateUrl = async () => {
    this.invateUrl = await getInvateUrl()
  }

  onEventListing() {
    emitter.on('refresh', (data) => {
      if (data.data?.['index'] === 1) {
        this.load()
      }
    })

    emitter.on('logined', (data) => {
      this.load()
    })

  }

  offEventListing() {
    emitter.off('logined')
    emitter.off('refresh')
  }

  async load() {
    if (this.loginInfo.accountId) {
      const res = await userDetailApi(this.loginInfo.accountId)
      if (res) {
        debuglog('user detail', res)
        if (!this.detail) {
          this.detail = new UserDetail()
        }
        this.detail.fill(res);
      }
      this.loadPlaylist(this.tabKey === 'myPlaylist')
    }
  }

  loadPlaylist = async (creator: boolean) => {
    if (!this.loginInfo.accountId) {
      return;
    }

    this.isPlaylistNotMore = false
    this.playlist.clean()
    this.loadMorePlaylist(creator);
  }
  loadMorePlaylist = async (creator: boolean) => {
    const loadedCount = this.playlist.totalCount();
    if (this.isPlaylistNotMore) {
      return
    }

    if (this.playlistLoading) {
      return;
    }

    this.playlistLoading = true

    try {

      const playlistRes = await userPlaylistApi(this.loginInfo.accountId!, loadedCount)
      debuglog('playlist', playlistRes)

      for (const playlistItem of playlistRes?.playlist || []) {
        debuglog('item', JSON.stringify(({
          creator,
          userId: playlistItem.creator?.userId,
          accountId: this.loginInfo.accountId
        })))
        if (creator && playlistItem.creator?.userId === this.loginInfo.accountId) {
          this.playlist.pushData(playlistItem)
        }

        if (!creator && playlistItem.creator?.userId !== this.loginInfo.accountId) {
          this.playlist.pushData(playlistItem)
        }
      }

      this.isPlaylistNotMore = !playlistRes?.more

      // debuglog('this.isNotMore', this.isNotMore)
    } finally {
      this.playlistLoading = false
    }
  }
  loadCachedList = () => {
    this.cachedSongIds = CacheUtil.loadSongIds()
    this.isCacheSongNotMore = false;
    this.cacheDatasource.clean()
    this.loadMoreCache()
  }
  loadMoreCache = async () => {
    if (this.isCacheSongNotMore) {
      return
    }

    if (this.cacheSongLoading) {
      return;
    }

    this.cacheSongLoading = true

    try {
      const loadedCount = this.cacheDatasource.totalCount();
      const ids = this.cachedSongIds.slice(loadedCount, loadedCount + 20);
      if (ids.length > 0) {
        await this.cacheDatasource.pushBySongIds(ids)
      }
      this.isCacheSongNotMore = this.cachedSongIds.length >= this.cacheDatasource.totalCount()
    } finally {
      this.cacheSongLoading = false
    }
  }

  /**
   * 顶部用户信息
   */
  @Builder
  buildHeader() {
    Stack() {
      // 背景
      if (this.loginInfo.isLogin) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.detail?.backgroundUrl,
            objectFit: ImageFit.Cover
          }
        }).height(300).width('100%')
      } else {
        Column().backgroundColor('#ffffaeae').height(300).width('100%')
      }

      Column() {
        // 头像
        if (this.loginInfo.isLogin) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: this.detail?.avatarUrl
            }
          })
            .height(60)
            .width(60)
            .borderRadius(30)
            .clip(true)
            .border({ width: 1, color: '#FFFFFF' })
            .margin({ bottom: 12 })

        } else {
          Column()
            .height(60)
            .width(60)
            .borderRadius(30)
            .clip(true)
            .backgroundColor('#4dffffff')
            .border({ width: 1, color: '#FFFFFF' })
            .margin({ bottom: 12 })
        }

        // 昵称
        Row() {
          Text(this.loginInfo.isLogin ? this.detail?.nickname : '')
            .fontColor('#FFFFFF')
            .fontWeight(500)

          Button(this.loginInfo.isLogin ? '退出登录' : '立即登录')
            .backgroundColor('#25000000')
            .fontColor('#FFFFFF')
            .padding(4)
            .height(20)
            .fontSize(10)
            .onClick(async () => {
              if (this.loginInfo.isLogin) {
                this.loginInfo.cookie = '';
                emitter.emit('loadLoginStatus')
                promptAction.showToast({
                  message: '退出登录成功'
                })
                this.detail = undefined
              } else {
                this.pathStack.pushPath({ name: 'LoginPage' })
              }
            })
            .margin({ left: 4 })
        }.margin({ bottom: 12 })

        if (this.loginInfo.isLogin) {


          // 签名
          if (this.detail?.signature) {
            Text(this.detail?.signature)
              .fontColor('#FFFFFF')
              .opacity(0.6)
              .fontSize(12)
              .margin({ bottom: 12 })
          }

          // 信息栏
          Flex({ space: { main: LengthMetrics.px(38) }, justifyContent: FlexAlign.Center }) {
            Row() {
              Text(`${this.detail?.follows || 0}`).fontColor('#FFFFFF').fontSize(12).margin({ right: 2 })
              Text(`关注`).fontColor('#FFFFFF').opacity(0.6).fontSize(10)
            }.alignItems(VerticalAlign.Bottom)

            Row() {
              Text(`${this.detail?.followeds || 0}`).fontColor('#FFFFFF').fontSize(12).margin({ right: 2 })
              Text(`粉丝`).fontColor('#FFFFFF').opacity(0.6).fontSize(10)
            }.alignItems(VerticalAlign.Bottom)

            Row() {
              Text(`Lv.${this.detail?.level || 0}`).fontColor('#FFFFFF').fontSize(12).margin({ right: 2 })
              Text(`等级`).fontColor('#FFFFFF').opacity(0.6).fontSize(10)
            }.alignItems(VerticalAlign.Bottom)

            Row() {
              Text(`${this.detail?.createYear || 0}年`)
                .fontColor('#FFFFFF')
                .fontSize(12)
                .margin({ right: 2 })
              Text(`村龄`).fontColor('#FFFFFF').opacity(0.6).fontSize(10)
            }.alignItems(VerticalAlign.Bottom)
          }
        }

      }
      .justifyContent(FlexAlign.Center)
      .height(300)
      .padding({ top: 58 })
      .width('100%')
      .linearGradient({
        colors: [
          ['#27000000', 0],
          ['#8b000000', 1],
        ]
      })
    }.height(300).width('100%')
  }

  /**
   * tabs
   */
  @Builder
  buildTabs() {
    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      ForEach(this.tabs, (tab: TabItem) => {
        Stack() {
          Text(tab.name).fontSize(14)
          Column().height(2).width(14).backgroundColor(
            this.tabKey === tab.key ? $r('app.color.primary') :
              '#00ffffff').offset({ top: 4 })
        }
        .alignContent(Alignment.Bottom)
        .flexShrink(0)
        .margin({ right: 24 })
        .onClick(() => {
          this.tabKey = tab.key
        })
      })
      /**
       if (this.invateUrl) {
       Column() {
       Text('邀请好友')
       .fontSize(10)
       .padding({
       top: 2,
       bottom: 2,
       left: 4,
       right: 4
       })
       .align(Alignment.Center)
       .textAlign(TextAlign.Center)
       .border({ width: 1, color: $r('app.color.primary') })
       .fontColor($r('app.color.primary'))
       .borderRadius(14)
       .margin({ left: 12 })
       .onClick(async () => {
       const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.invateUrl);
       let systemPasteboard = pasteboard.getSystemPasteboard();
       await systemPasteboard.setData(pasteData);
       promptAction.showDialog({
       title: '复制成功',
       message: '内测链接已复制到您的剪切板，您可以将链接分享给Next用户好友。内测邀请名额数量有限先到先得。',
       buttons: [{
       text: '我知道了',
       color: $r('app.color.normal_text_color')
       },]
       })
       })
       }
       .alignItems(HorizontalAlign.End)
       .flexGrow(1)
       }
       **/
    }
    .width('100%')
    .padding(16)

  }

  /**
   * 歌单项
   * @param item
   */
  @Builder
  buildPlaylistItem(item: PlaylistItem, index: number) {
    Flex({ alignItems: ItemAlign.Center }) {
      // 歌单封面
      ImageKnifeComponent({
        imageKnifeOption: {
          loadSrc: Utils.getCoverUrl(item.coverImgUrl, 90, 90)
        }
      })
        .borderRadius(6)
        .clip(true)
        .width(45)
        .height(45)
        .flexShrink(0)

      // 名称&详情
      Column() {
        Text(item.name)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontWeight(500)
          .fontSize(14)
        Text([
          `${item.trackCount}首`,
          item?.creator?.nickname
        ].filter(i => !!i).join(' · '))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity(0.6)
          .fontSize(10)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .flexGrow(1)
      .margin({ left: 8 })
    }
    .animation({
      duration: 500
    }) // 显示动画
    .transition(
      index < 20 ? TransitionEffect.OPACITY
        .combine(TransitionEffect.move(TransitionEdge.END)
          .animation({ curve: Curve.Ease, delay: INTERVAL * index })) : undefined
    )
    .padding({
      top: 4,
      bottom: 4,
      left: 14,
      right: 14
    })
    .width('100%')
    .onClick(() => {
      const param: Record<string, string> = { 'id': `${item.id}`, 'type': 'id' }
      this.pathStack.pushPathByName('PlaylistPage', param)
    })
  }

  /**
   * 加载更多
   */
  @Builder
  buildLoadMore() {
    if (this.playlistLoading) {
      ListItem() {
        SwipeRefresher({
          content: '正在加载中',
          isLoading: true
        })
      }.margin({
        bottom: this.player?.playingTitle ? 50 : 10
      })
    }

    if (this.isPlaylistNotMore) {
      ListItem() {
        Text('没有更多歌单')
          .fontSize(12)
          .fontColor('#94000000')
          .width('100%')
          .textAlign(
            TextAlign.Center
          )
          .padding({ top: 10, bottom: 20 })
          .margin({ bottom: px2vp(this.global?.bottomRectHeight || 0) * 3 })
      }
    }
  }

  /**
   * 歌单列表
   */
  @Builder
  buildPlaylist() {
    Column() {
      List({ space: 6 }) {
        LazyForEach(this.playlist, (item: PlaylistItem, index: number) => {
          ListItem() {
            this.buildPlaylistItem(item, index)
          }
        }, (i: PlaylistItem) => `${i.id}`)
        this.buildLoadMore()
      }
    }
  }

  @Builder
  buildCachedList() {
    CommonSongList({
      data: this.cacheDatasource,
      showCover: true,
      isNotMore: this.isCacheSongNotMore,
      loading: this.cacheSongLoading,
      onMusicClick: (music) => {
        getPlayer()?.start('cached', 'ids', {
          ids: this.cachedSongIds,
          songId: String(music.detail.id),
          avQueueName: '缓存的歌曲'
        })
      },
      deleteAble: true,
      onDelete: music => {
        CacheUtil.removeBySongId(music.detail.id).then(() => {
          this.cacheDatasource.deleteBySongId(`${music.detail.id}`)
        })
      }
    })
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        this.buildHeader()
        this.buildTabs()
        if (this.tabKey === 'cached') {
          this.buildCachedList()
        } else {
          this.buildPlaylist()
        }
      }.margin({
        bottom: this.player?.playingTitle ? 50 : 10
      })
    }
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .onScrollEdge((side) => {
      if (side === Edge.Bottom) {


        if (this.tabKey === 'cached') {
          this.loadMoreCache()
        } else {
          this.loadMorePlaylist(this.tabKey === 'myPlaylist')

        }
      }
    })
    .height('100%')

  }
}
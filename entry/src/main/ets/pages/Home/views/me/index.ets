import { LengthMetrics, PersistenceV2, promptAction, SwipeRefresher } from "@kit.ArkUI"
import { LoginInfo } from "../../../../viewmodel/loginInfo"
import { ImageKnifeComponent } from "@ohos/imageknife";
import { userDetailApi, UserDetailResponseBody } from "../../../../api/user_detail";
import { debuglog } from "../../../../utils/log";
import emitter from '@ohos.events.emitter';
import { PlaylistItem, userPlaylistApi } from "../../../../api/user_playlist";
import { PlaylistDataSource } from "../../../../model/datasource";
import { Utils } from '../../../../common/utils'
import { Player } from "../../../../viewmodel/player";
import { getGlobal, getPlayer, GlobalContent } from "../../../../viewmodel/global";

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

@ComponentV2
export struct MeTabContent {
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Local detail?: UserDetail = undefined
  scroller: Scroller = new Scroller()
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local player: Player | undefined = getPlayer()
  @Local global: GlobalContent | undefined = getGlobal()
  private data: PlaylistDataSource = new PlaylistDataSource();
  @Local _loading: boolean = false
  @Local isNotMore: boolean = false
  @Local tabKey: string = 'playlist'

  aboutToAppear(): void {
    this.load()
    this.onEventListing()
  }

  aboutToDisappear(): void {
    this.offEventListing()
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
    if (this.loginInfo.account?.id) {
      const res = await userDetailApi(this.loginInfo.account?.id)
      if (res) {
        debuglog('user detail', res)
        if (!this.detail) {
          this.detail = new UserDetail()
        }
        this.detail.fill(res);
      }
      this.loadPlaylist()

    }
  }

  loadPlaylist = async () => {
    if (!this.loginInfo.account?.id) {
      return;
    }

    this.isNotMore = false
    this.data.clean()
    this.loadMorePlaylist();
  }
  loadMorePlaylist = async () => {
    const loadedCount = this.data.totalCount();
    if (this.isNotMore) {
      return
    }

    if (this._loading) {
      return;
    }

    this._loading = true

    try {

      const playlistRes = await userPlaylistApi(this.loginInfo.account!.id!, loadedCount)
      debuglog('playlist', playlistRes)

      for (const playlistItem of playlistRes?.playlist || []) {
        this.data.pushData(playlistItem)

      }
      this.isNotMore = !playlistRes?.more

      // debuglog('this.isNotMore', this.isNotMore)
    } finally {
      this._loading = false
    }
  }

  @Builder
  buildHeader() {
    /**
     * 顶部用户信息
     */
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
                await this.loginInfo.loadLoginStatus()
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

  @Builder
  buildTabs() {
    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      Stack() {
        Text('歌单')
        Column().height(2).width(18).backgroundColor(
          this.tabKey === 'playlist' ? $r('app.color.primary') :
            '#00ffffff').offset({ top: 4 })
      }
      .alignContent(Alignment.Bottom)
      .flexShrink(0)
      .onClick(() => {
        this.tabKey = 'playlist'
      })

      Stack() {
        Text('已缓存')
        Column().height(2).width(18).backgroundColor(
          this.tabKey === 'cached' ? $r('app.color.primary') :
            '#00ffffff').offset({ top: 4 })
      }
      .alignContent(Alignment.Bottom)
      .flexShrink(0)
      .margin({ left: 20 })
      .onClick(() => {
        this.tabKey = 'cached'
      })
    }
    .width('100%')
    .padding(16)

  }

  @Builder
  buildPlaylistItem(item: PlaylistItem) {
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

  @Builder
  buildLoadMore() {
    if (this._loading) {
      ListItem() {
        SwipeRefresher({
          content: '正在加载中',
          isLoading: true
        })
      }.margin({
        bottom: this.player?.playingTitle ? 50 : 10
      })
    }

    if (this.isNotMore) {
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

  build() {
    Scroll(this.scroller) {
      Column() {
        this.buildHeader()
        this.buildTabs()
        Column() {
          List({ space: 6 }) {
            LazyForEach(this.data, (item: PlaylistItem) => {
              ListItem() {
                this.buildPlaylistItem(item)
              }
            }, (i: PlaylistItem) => `${i.id}`)
            this.buildLoadMore()
          }
        }
      }

    }
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .onScrollEdge((side) => {
      if (side === Edge.Bottom) {
        this.loadMorePlaylist()
      }
    })
    .height('100%')
  }
}
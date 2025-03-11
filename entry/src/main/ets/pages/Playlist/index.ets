import { apiPlaylistDetails } from "../../api/playlist_detail";
import { Playlist } from "../../model/playlist_detail";
import { debuglog } from "../../utils/log";
import { ImageKnifeComponent } from '@ohos/imageknife'
import { SongDetailWithPrivilege } from "../../model/song_detail";
import tinycolor from "ohos_tinycolor2";
import { ImageMainColorResult, Utils } from "../../common/utils";
import { getGlobal, getPlayer, GlobalContent } from "../../viewmodel/global";
import { apiMusicSongDetail } from "../../api/music_song_detail";
import { MusicBar } from "../../components/music_bar";
import { Player } from "../../viewmodel/player";
import { TrackDataSource } from "../../model/datasource";
import { PersistenceV2 } from "@kit.ArkUI";
import { LoginInfo } from "../../viewmodel/loginInfo";
import { playlistSubscribe } from "../../api/playlist_subscribe";
import { CommonSongList } from "../../components/common_song_list";
import { BreakpointState, BreakpointSystem } from "../../common/breakpointsystem";

interface PlaylistParam {
  id: string;
  type: string;
  detail: Playlist;
}


@Builder
function pageBuilder() {
  PlaylistPage()
}

@ComponentV2
struct PlaylistPage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Local detail: Playlist | undefined = undefined
  @Local playlistId: string = ''
  @Local playlistType: string = ''
  playlistDetail?: Playlist
  scroller: Scroller = new Scroller()
  @Local mainColor: string = '#ff838383';
  @Local mainSecondColor: string = '#ff0c0c0c';
  @Local displayMode: BreakpointState<'1' | '2'> = BreakpointState.of({ sm: '1', md: '1', lg: '2' })
  @Local global: GlobalContent | undefined = getGlobal()
  @Local player: Player | undefined = getPlayer()
  @Local tracks: SongDetailWithPrivilege[] = []
  private data: TrackDataSource = new TrackDataSource();
  @Local titleBarAlp: number = 0
  @Local loading: boolean = false
  private pageSize = 20
  @Local isNotMore: boolean = false

  aboutToAppear(): void {
    BreakpointSystem.getInstance().attach(this.displayMode)
    const params = this.pathStack.getParamByName("PlaylistPage") as Array<PlaylistParam>
    debuglog('params', params)
    this.playlistId = params?.[0]?.id
    this.playlistType = params?.[0]?.type
    this.playlistDetail = params?.[0]?.detail
    this.load()
  }

  aboutToDisappear() {
    BreakpointSystem.getInstance().detach(this.displayMode)
  }

  reloadDetail = async () => {
    this.detail = await apiPlaylistDetails(this.playlistId)
  }
  load = async () => {
    if (!this.playlistId) {
      return;
    }

    debuglog('this.playlistType', this.playlistType)
    debuglog('this.playlistDetail', this.playlistDetail)
    if (this.playlistType === 'detail' && this.playlistDetail) {
      this.detail = this.playlistDetail
    } else {
      this.detail = await apiPlaylistDetails(this.playlistId)
    }

    debuglog('[PLAYLIST DETAIL]', this.detail)

    let colors: ImageMainColorResult;

    const url = this.detail?.backgroundCoverUrl ? Utils.getCoverUrl(this.detail?.backgroundCoverUrl) :
    Utils.getCoverUrl(this.detail?.coverImgUrl)
    this.isNotMore = this.data.totalCount() >= (this.detail?.trackIds?.length || 0)
    this.loadMore();

    if (url) {
      colors = await Utils.getImageMainColor(url);
      if (colors.colors['main']) {
        let color = tinycolor.fromEffectKitColor(colors.colors['main'])

        if (color.isLight()) {
          color = color.darken(40)
        }

        this.mainColor = color.toHexString()
        this.mainSecondColor = color.darken(20).toHexString()
      }
    }
  }
  loadMore = async () => {
    const loadedCount = this.data.totalCount();
    if (this.isNotMore) {
      return
    }

    if (this.loading) {
      return;
    }

    this.loading = true

    try {
      const ids = (this.detail?.trackIds || []).slice(loadedCount, loadedCount + this.pageSize)
      if (ids.length > 0) {
        const songs = await apiMusicSongDetail(ids.map(i => String(i.id)))
        for (const song of songs) {
          // debuglog('add', song)
          this.data.pushData(song)
        }
      }
      this.isNotMore = this.data.totalCount() >= (this.detail?.trackIds?.length || 0)

      // debuglog('this.isNotMore', this.isNotMore)
    } finally {
      this.loading = false
    }
  }
  goBack = () => {
    this.pathStack.pop()
  }

  @Builder
  buildSubButton(justifyContent?: FlexAlign) {
    if (this.playlistId && this.detail?.creator?.userId !== this.loginInfo?.accountId) {
      Flex({ justifyContent }) {
        Button(`${this.detail?.subscribed ? '取消收藏' : '收藏歌单'}`)
          .backgroundColor('#39ffffff')
          .fontSize(12)
          .height(24)
          .onClick(async () => {
            await playlistSubscribe(this.playlistId, !this.detail?.subscribed)
            await this.reloadDetail()
          })
      }.margin({ top: 12 }).width('100%')
    }
  }

  @Builder
  buildHeaderStyle1() {
    Stack({
      alignContent: this.playlistType === 'detail' || this.displayMode.value === '2' ? Alignment.Center :
      Alignment.Bottom
    }) {
      ImageKnifeComponent({
        imageKnifeOption: {
          loadSrc: Utils.getCoverUrl(this.detail?.backgroundCoverUrl, 400, 400),
          objectFit: ImageFit.Cover
        }
      })
        .width('100%')
        .height(this.displayMode.value === '1' ? 350 : '100%')

      Column() {
      }
      .width('100%')
      .height(this.displayMode.value === '1' ? 350 : '100%')
      .backgroundColor('#ff000000')
      .opacity(0.5)

      Column() {
        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Text(this.detail?.detailPageTitle?.replace(/\s/ig, ''))
            .fontColor('#FFFFFF')
            .fontSize(28)
            .fontWeight(700)
            .textAlign(TextAlign.Center)
        }.width('100%')

        this.buildSubButton(FlexAlign.Center)


        Text(this.detail?.updateFrequency)
          .fontColor('#FFFFFF')
          .fontSize(10)
          .margin({ top: 12 })
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(this.detail?.description)
          .fontColor('#FFFFFF')
          .fontSize(10)
          .margin({ top: 12, bottom: 30 })
          .fontWeight(200)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .padding({
        top: this.playlistType === 'detail' ? 40 : 0
      })

    }
  }

  @Builder
  buildHeaderStyle2() {
    Column() {
      Flex({
        direction: this.displayMode.value === '1' ? FlexDirection.Row : FlexDirection.Column,
        alignItems: this.displayMode.value === '1' ? undefined : ItemAlign.Center,
        justifyContent: this.displayMode.value === '1' ? undefined : FlexAlign.Center,
      }) {
        Column() {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: Utils.getCoverUrl(this.detail?.coverImgUrl, 400, 400),
              objectFit: ImageFit.Cover
            }
          })
            .width(this.displayMode.value === '1' ? 90 : 150)
            .height(this.displayMode.value === '1' ? 90 : 150)
            .borderRadius(14)
            .clip(true)
        }
        .flexShrink(0)
        .margin({ bottom: this.displayMode.value === '1' ? 0 : 24 })

        Column() {
          // 歌单名称
          Column() {
            Text(this.detail?.name).fontColor('#FFFFFF').fontWeight(500)
          }
          .alignItems(HorizontalAlign.Start)


          // 歌单按钮
          this.buildSubButton(this.displayMode.value === '1' ? FlexAlign.Start : FlexAlign.Center)


          // 创建人
          Flex({
            alignItems: ItemAlign.Center,
            justifyContent: this.displayMode.value === '1' ? FlexAlign.Start : FlexAlign.Center
          }) {
            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: Utils.getCoverUrl(this.detail?.creator?.avatarUrl),
                objectFit: ImageFit.Cover
              }
            })
              .width(20)
              .height(20)
              .borderRadius(8)
              .clip(true)
              .margin({ right: 8 })

            Text(this.detail?.creator?.nickname || '').fontSize(12).fontWeight(500).fontColor('#d5ffffff')
          }
          .margin({ top: 12 })

          // 标签
          Flex({ justifyContent: this.displayMode.value === '1' ? FlexAlign.Start : FlexAlign.Center }) {
            Repeat(this.detail?.tags || []).each((i: RepeatItem<string>) => {
              Text(i.item)
                .fontSize(8)
                .fontColor('#FFFFFF')
                .backgroundColor('#37ffffff')
                .padding({
                  top: 2,
                  left: 2,
                  bottom: 2,
                  right: 2
                })
                .borderRadius(4)
                .margin({ right: 5 })
            })
          }
          .margin({ top: 12 })
        }
        .flexGrow(this.displayMode.value === '1' ? 1 : 0)
        .alignItems(this.displayMode.value === '1' ? HorizontalAlign.Start : HorizontalAlign.Center)
        .margin({ left: 12 })
      }.height(this.displayMode.value === '1' ? 'auto' : '60%')

      Text(this.detail?.description?.replace(/\s/g, ''))
        .fontColor('#FFFFFF')
        .fontSize(10)
        .margin({ top: 16 })
        .fontWeight(200)
        .maxLines(1)
        .width('100%')
        .textAlign(this.displayMode.value === '1' ? TextAlign.Start : TextAlign.Center)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

    }
    .padding({
      left: 20,
      right: 20,
      top: px2vp(this.global?.topRectHeight || 0) + 56,
      bottom: 20
    })
    .backgroundColor(this.mainColor)
    .height(this.displayMode.value === '1' ? 'auto' : '100%')
  }

  @Builder
  buildHeader() {
    if (this.detail?.backgroundCoverUrl) {
      this.buildHeaderStyle1()
    } else if (this.detail?.coverImgUrl) {
      this.buildHeaderStyle2()
    }
  }

  @Builder
  buildTitle() {
    Column() {
      Text(this.detail?.name)
        .fontColor('#FFFFFF')
        .fontSize(16)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .opacity(this.displayMode.value === '1' ? this.titleBarAlp : 1)
    }
    .padding({ left: 8 })
    .justifyContent(FlexAlign.Center)
    .height('100%')
  }

  @Builder
  buildTitleBar() {
    Column() {
      Flex() {
        Button() {
          Image($r('sys.media.ohos_ic_compnent_titlebar_back'))
            .fillColor('#ccffffff')
            .width(28)
            .height(22)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .flexShrink(0)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.goBack()
        })

        this.buildTitle()
      }
      .height(48)
      .width('100%')
    }
    .padding({ top: px2vp(this.global?.topRectHeight || 0) })
    .flexShrink(0)
  }

  @Builder
  build() {
    NavDestination() {
      Flex() {
        if (this.displayMode.value === '2') {
          Flex({ direction: FlexDirection.Column }) {
            this.buildTitleBar()
            Stack({ alignContent: Alignment.Bottom }) {
              this.buildHeader()
              MusicBar({ textColor: $r('app.color.playlist_music_bar_text_color') })
                .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
                .height(this.player?.playingTitle ? `${48 + px2vp(this.global?.bottomRectHeight || 0)}vp` : 0)
                .width('100%')
                .padding({
                  bottom: this.player?.playingTitle ? px2vp(this.global?.bottomRectHeight || 0) : 0
                })
            }.flexGrow(1)
          }.flexGrow(1)
        }
        Column() {
          Stack({ alignContent: Alignment.Bottom }) {
            Scroll(this.scroller) {
              Column() {
                if (this.displayMode.value === '1') {
                  this.buildHeader()
                } else {
                  // 大屏模式占位高度
                  Column().height(px2vp(this.global?.topRectHeight || 0))
                }
                CommonSongList({
                  data: this.data,
                  loading: this.loading,
                  isNotMore: this.isNotMore,
                  color: '#FFFFFF',
                  withBottomSafeArea: this.displayMode.value === '1',
                  onMusicClick: (item: SongDetailWithPrivilege) => {
                    if (this.playlistType === 'detail') {
                      getPlayer()?.start(this.playlistId, 'ids', {
                        avQueueName: this.detail?.name?.replace(/\s/ig, ''),
                        songId: String(item.detail.id),
                        ids: this.detail?.trackIds?.map(i => String(i.id))
                      })
                    } else {
                      getPlayer()?.start(this.playlistId, 'playList', {
                        songId: String(item.detail.id)
                      })
                    }
                  }
                })
              }
            }
            .align(Alignment.Top)
            .scrollBar(BarState.Off)
            .onScrollEdge((side) => {
              if (side === Edge.Bottom) {
                this.loadMore()
              }
            })
            .height('100%')
            .onDidScroll(() => {
              let alp = this.scroller.currentOffset().yOffset > 100 ? 1 : 0
              if (alp < 0) {
                alp = 0
              }
              if (alp > 1) {
                alp = 1
              }

              if (this.titleBarAlp === alp) {
                return
              }


              this.getUIContext()?.animateTo({
                duration: 500
              }, () => {
                this.titleBarAlp = alp
              })

            })

            if (this.displayMode.value === '1') {
              MusicBar({ textColor: $r('app.color.playlist_music_bar_text_color') })
                .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
                .height(this.player?.playingTitle ? `${48 + px2vp(this.global?.bottomRectHeight || 0)}vp` : 0)
                .width('100%')
                .padding({
                  bottom: this.player?.playingTitle ? px2vp(this.global?.bottomRectHeight || 0) : 0
                })
            }
          }.height('100%')
        }.flexGrow(1)
      }
      .width('100%')
      .height('100%')
    }
    .title(this.buildTitle(), {
      barStyle: BarStyle.STACK,
      backgroundBlurStyle: this.titleBarAlp === 0 ? BlurStyle.NONE : BlurStyle.BACKGROUND_THICK
    })
    .hideTitleBar(this.displayMode.value === '2')
    .backgroundColor(this.mainSecondColor)
    .backButtonIcon($r('app.media.icon_back_white'))
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
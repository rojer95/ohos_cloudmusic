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
import { SongItem } from "../../components/song_item";
import { LengthMetrics, LengthMetricsUnit, PersistenceV2 } from "@kit.ArkUI";
import { LoginInfo } from "../../viewmodel/loginInfo";
import { playlistSubscribe } from "../../api/playlist_subscribe";

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
  // @Local titleBgColor: string = '#00ffffff'
  // @Local titleTextColor: string = '#00ffffff'
  @Local global: GlobalContent | undefined = getGlobal()
  @Local player: Player | undefined = getPlayer()
  @Local tracks: SongDetailWithPrivilege[] = []
  private data: TrackDataSource = new TrackDataSource();
  @Local titleBarAlp: number = 0
  private loading = false
  private pageSize = 20
  @Local isNotMore: boolean = false

  aboutToAppear(): void {
    const params = this.pathStack.getParamByName("PlaylistPage") as Array<PlaylistParam>
    debuglog('params', params)
    this.playlistId = params?.[0]?.id
    this.playlistType = params?.[0]?.type
    this.playlistDetail = params?.[0]?.detail
    this.load()
  }

  reloadDetail = async  ()=>{
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

  @Builder
  buildSubButton(justifyContent?: FlexAlign) {
    if (this.playlistId && this.detail?.creator?.userId !== this.loginInfo?.account?.id) {
      Flex({ justifyContent }) {
        Button(`${this.detail?.subscribed ? '取消收藏' : '收藏歌单'}`)
          .backgroundColor('#39ffffff')
          .fontSize(12)
          .height(24)
          .onClick(async ()=>{
            await playlistSubscribe(this.playlistId, !this.detail?.subscribed)
            await this.reloadDetail()
          })
      }.margin({ top: 12 }).width('100%')
    }
  }

  @Builder
  buildHeader() {
    if (this.detail?.backgroundCoverUrl) {
      Stack({ alignContent: this.playlistType === 'detail' ? Alignment.Center : Alignment.Bottom }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: Utils.getCoverUrl(this.detail?.backgroundCoverUrl, 400, 400),
            objectFit: ImageFit.Cover
          }
        })
          .width('100%')
          .height(350)
        Column() {
        }.width('100%')
        .height(350).backgroundColor('#ff000000').opacity(0.5)

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
        }.padding({
          top: this.playlistType === 'detail' ? 40 : 0
        })

      }
    } else if (this.detail?.coverImgUrl) {
      Column() {
        Flex() {
          Column() {
            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: Utils.getCoverUrl(this.detail?.coverImgUrl, 400, 400),
                objectFit: ImageFit.Cover
              }
            })
              .width(90)
              .height(90)
              .borderRadius(14)
              .clip(true)
          }.flexShrink(0)

          Column() {
            Column() {
              Text(this.detail?.name).fontColor('#FFFFFF').fontWeight(500)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            this.buildSubButton()


            Flex({ alignItems: ItemAlign.Center }) {
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
            }.width('100%')
            .margin({ top: 12 })

            Flex() {
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
            .width('100%')
            .margin({ top: 12 })
          }
          .flexGrow(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')

        Text(this.detail?.description?.replace(/\s/g, ''))
          .fontColor('#FFFFFF')
          .fontSize(10)
          .margin({ top: 16 })
          .fontWeight(200)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

      }
      .padding({
        left: 20,
        right: 20,
        top: px2vp(this.global?.topRectHeight || 0) + 56,
        bottom: 20
      })

      .backgroundColor(this.mainColor)
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
        .opacity(this.titleBarAlp)
    }
    .padding({ left: 8 })
    .justifyContent(FlexAlign.Center)
    .height('100%')
  }

  @Builder
  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll(this.scroller) {
          Column() {
            this.buildHeader()
            Column() {
              List({ space: 6 }) {
                LazyForEach(this.data, (item: SongDetailWithPrivilege, index: number) => {
                  ListItem() {
                    SongItem({
                      index: index + 1,
                      detail: item.detail,
                      privilege: item.privilege,
                      color: '#FFFFFF'
                    })
                      .onClick(() => {
                        // st < 0 没有版权，设置灰色
                        if ((item?.privilege?.st || 0) < 0) {
                          return;
                        }
                        if (this.playlistType === 'detail') {
                          getPlayer()?.start(this.detail?.trackIds?.map(i => i.id)?.join(',') || '', 'ids', {
                            avQueueName: this.detail?.name?.replace(/\s/ig, ''),
                            songId: String(item.detail.id)
                          })
                        } else {
                          getPlayer()?.start(this.playlistId, 'playList', {
                            songId: String(item.detail.id)
                          })
                        }
                      })
                  }
                }, (item: SongDetailWithPrivilege) => `${item.detail.id}`)

                if (this.isNotMore) {
                  ListItem() {
                    Text('没有更多歌曲')
                      .fontSize(12)
                      .fontColor('#9affffff')
                      .width('100%')
                      .textAlign(
                        TextAlign.Center
                      )
                      .padding({ top: 10, bottom: 20 })
                      .margin({ bottom: px2vp(this.global?.bottomRectHeight || 0) * 2 })
                  }
                }
              }
            }.padding({ top: 20, bottom: 20 })
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

        MusicBar({ textColor: $r('app.color.playlist_music_bar_text_color') })
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
          .height(this.player?.playingTitle ? `${48 + px2vp(this.global?.bottomRectHeight || 0)}vp` : 0).width('100%')
          .padding({
            bottom: this.player?.playingTitle ? px2vp(this.global?.bottomRectHeight || 0) : 0
          })
      }.height('100%')
    }
    .title(this.buildTitle(), {
      barStyle: BarStyle.STACK,
      backgroundBlurStyle: this.titleBarAlp === 0 ? BlurStyle.NONE : BlurStyle.BACKGROUND_THICK
    })
    .backgroundColor(this.mainSecondColor)
    .backButtonIcon($r('app.media.icon_back_white'))
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
import { Playlist } from "../../model/playlist_detail";
import { debuglog } from "../../utils/log";
import { SongDetailWithPrivilege } from "../../model/song_detail";
import { getGlobal, getPlayer, GlobalContent } from "../../viewmodel/global";
import { apiMusicSongDetail } from "../../api/music_song_detail";
import { MusicBar } from "../../components/music_bar";
import { Player } from "../../viewmodel/player";
import { TrackDataSource } from "../../model/datasource";
import { apiSearch } from "../../api/search";
import { BusinessError } from "@kit.BasicServicesKit";
import { SongItem } from "../../components/song_item";

interface PlaylistParam {
  id: string;
  type: string;
  detail: Playlist;
}


@Builder
function pageBuilder() {
  SearchPage()
}

@ComponentV2
struct SearchPage {
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local keyword: string = '';
  scroller: Scroller = new Scroller()
  @Local global: GlobalContent | undefined = getGlobal()
  @Local player: Player | undefined = getPlayer()
  private data: TrackDataSource = new TrackDataSource();
  private loading = false
  private _offset = 0;
  @Local hasMore: boolean = true

  aboutToAppear(): void {
  }

  load = async () => {
    debuglog('this.keyword', this.keyword)
    if (!this.keyword.trim()) {
      return;
    }
    this._offset = 0;
    this.hasMore = true;
    this.data.clean();
    this.loadMore()
  }
  loadMore = async () => {
    if (this.loading || !this.hasMore) {
      return;
    }

    this.loading = true

    try {
      const result = await apiSearch(this.keyword, this._offset)
      const songs = await apiMusicSongDetail(result?.songs?.map?.(i => String(i.id)) || [])


      for (const detail of songs) {
        debuglog('detail', detail, 2)
        this.data.pushData(detail)
      }

      this._offset += (result?.songs || []).length
      this.hasMore = !!result?.hasMore
      debuglog('hasMore', `${this.hasMore}`)
      debuglog('len', `${this.data.totalCount()}`)
      // debuglog('this.isNotMore', this.isNotMore)
    } catch (e) {
      debuglog('search', (e as BusinessError).message)
    } finally {
      this.loading = false
    }
  }

  @Builder
  buildTitle() {
    Flex({ alignItems: ItemAlign.Center }) {
      TextInput({ placeholder: '请输入歌曲名搜索', text: $$this.keyword, })
        .enterKeyType(EnterKeyType.Search)
        .defaultFocus(true)
        .onSubmit(() => {
          this.load()
        })
      Text('搜索').margin({ left: 12, right: 12 }).flexShrink(0).onClick(() => {
        this.load()
      })
    }
    .padding({ left: 8 })
    .height('100%')
  }

  @Builder
  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll(this.scroller) {
          Column() {
            Column() {
              List({ space: 6 }) {
                LazyForEach(this.data, (item: SongDetailWithPrivilege, index: number) => {
                  ListItem() {
                    SongItem({
                      index: index + 1,
                      detail: item.detail,
                      privilege: item.privilege,
                    })
                      .onClick(() => {
                        // st < 0 没有版权，设置灰色
                        if ((item?.privilege?.st ?? 0) < 0) {
                          return;
                        }
                        getPlayer()?.start(`${item.detail.id}`, 'ids', {
                          avQueueName: item.detail.name,
                          songId: `${item.detail.id}`
                        })
                      })
                  }

                }, (item: SongDetailWithPrivilege) => `${item.detail.id}`)

                if (!this.hasMore) {
                  ListItem() {
                    Text('没有更多歌曲')
                      .fontSize(12)
                      .fontColor('#9a000000')
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

        MusicBar()
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
          .height(this.player?.playingTitle ? `${48 + px2vp(this.global?.bottomRectHeight || 0)}vp` : 0).width('100%')
          .padding({
            bottom: this.player?.playingTitle ? px2vp(this.global?.bottomRectHeight || 0) : 0
          })
      }.height('100%')
    }
    .title(this.buildTitle(), {})
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
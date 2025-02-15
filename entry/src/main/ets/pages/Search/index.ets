import { debuglog } from "../../utils/log";
import { getGlobal, getPlayer, GlobalContent } from "../../viewmodel/global";
import { MusicBar } from "../../components/music_bar";
import { Player } from "../../viewmodel/player";
import { TrackDataSource } from "../../model/datasource";
import { apiSearch } from "../../api/search";
import { CommonSongList } from "../../components/common_song_list";


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
  @Local loading: boolean = false
  private _offset = 0;
  @Local hasMore: boolean = true
  private datasource = new TrackDataSource()

  aboutToAppear(): void {
  }

  onSearch = async () => {
    debuglog('this.keyword', this.keyword)
    if (!this.keyword.trim()) {
      return;
    }
    this.datasource.clean();
    this._offset = 0;
    this.hasMore = true;
    this.loadMore()
  }
  loadMore = async () => {
    if (this.loading || !this.hasMore) {
      return;
    }
    this.loading = true
    try {
      const result = await apiSearch(this.keyword, this._offset)
      const ids = result?.songs?.map?.(i => String(i.id)) || []
      if (ids.length > 0) {
        await this.datasource.pushBySongIds(ids);
      }
      this._offset += (result?.songs || []).length
      this.hasMore = result?.hasMore ?? false
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
          this.onSearch()
        })
      Text('搜索').margin({ left: 12, right: 12 }).flexShrink(0).onClick(() => {
        this.onSearch()
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
            CommonSongList({
              data: this.datasource,
              isNotMore: this.hasMore !== true,
              loading: this.loading,
              showCover: true,
              onMusicClick: (music) => {
                getPlayer()?.start('search', 'ids', {
                  ids: [String(music.detail.id)],
                  songId: String(music.detail.id),
                  avQueueName: music.detail.name
                })
              },
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
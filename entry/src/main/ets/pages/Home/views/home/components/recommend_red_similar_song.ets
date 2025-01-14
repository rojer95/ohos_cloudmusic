import { PAGE_RECOMMEND_PRIVATE_RCMD_SONG } from '../../../../../model/home_block'
import { debuglog } from '../../../../../utils/log'
import { CommonSongListSwiper, CommonSongListSwiperItem, CommonSongListSwiperItemSong } from './common_songlist_swiper'
import { CommonTitle } from './common_title'

@ComponentV2
export struct RecommendPrivateRcmdSong {
  @Require @Param resources: PAGE_RECOMMEND_PRIVATE_RCMD_SONG.Items[]
  @Param title: string = ''
  @Param dslShowTitle: boolean = false

  aboutToAppear(): void {
    debuglog('resources', this.resources)
  }

  build() {
    Column() {

      if (this.dslShowTitle && this.title) {
        CommonTitle({ title: this.title })
      }

      CommonSongListSwiper(
        {
          title: this.title,
          list: this.resources
          ?.map((list: PAGE_RECOMMEND_PRIVATE_RCMD_SONG.Items) => {
            const item: CommonSongListSwiperItem = {
              songs: list.items?.map((item: PAGE_RECOMMEND_PRIVATE_RCMD_SONG.Item) => {
                const song: CommonSongListSwiperItemSong = {
                  resourceId: item.resourceId,
                  resourceType: item.resourceType,
                  cover: item.cover,
                  title: item.title,
                  tag: item.tag,
                  recReason: item.recReason,
                  artistName: item.artistName
                }
                return song
              }) || []
            }
            return item
          })
        }
      )
    }.width('100%')
  }
}
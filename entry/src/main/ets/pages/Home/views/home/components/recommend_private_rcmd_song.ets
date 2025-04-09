import { PageItemSpace, PageSpace } from '../../../../../common/vars'
import { PAGE_RECOMMEND_RED_SIMILAR_SONG } from '../../../../../model/home_block'
import { CommonSongListSwiper, CommonSongListSwiperItem, CommonSongListSwiperItemSong } from './common_songlist_swiper'
import { CommonTitle } from './common_title'

@ComponentV2
export struct RecommendRedSimilarSong {
  @Require @Param resources: PAGE_RECOMMEND_RED_SIMILAR_SONG.HomeCommonRcmdSongContent
  @Param title: string = ''
  @Param dslShowTitle: boolean = false

  build() {
    if (this?.resources?.items && this?.resources?.items?.length > 0) {

      Column() {

        if (this.dslShowTitle && this.title) {
          CommonTitle({ title: this.title })
        }

        CommonSongListSwiper(
          {
            title: this.title,
            list: this?.resources?.items
            ?.map?.((list: PAGE_RECOMMEND_RED_SIMILAR_SONG.HomeCommonRcmdSongContentItem) => {
              const item: CommonSongListSwiperItem = {
                songs: list?.items?.map?.((item: PAGE_RECOMMEND_RED_SIMILAR_SONG.HomeCommonRcmdSongContentItemItem) => {
                  const song: CommonSongListSwiperItemSong = {
                    resourceId: item.resourceId,
                    resourceType: item.resourceType,
                    cover: item.coverUrl,
                    title: item.title,
                    tag: item.tag,
                    artistName: item.artistName
                  }
                  return song
                }) || []
              }
              return item
            }) || []
          }
        )
      }.width('100%')
    }
  }
}
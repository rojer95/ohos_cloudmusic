import { PageSpace } from '../../../../../common/vars';
import { CommonTitle } from './common_title';
import { HomeDailyRecommendCard, HomeDailyRecommendCardObject } from './daily_recommend_card';

const ListSpace = 8;

@ComponentV2
export struct HomeDailyRecommend {
  @Require @Param resources: HomeDailyRecommendCardObject[]
  @Param title: string = ''
  @Param dslShowTitle: boolean = false

  build() {

    Column() {
      if (this.dslShowTitle && this.title) {
        CommonTitle({ title: this.title })
      }

      List({ space: ListSpace }) {
        ListItem().width(PageSpace - ListSpace) // 占位

        ForEach(this.resources,
          (blockResourceItem: HomeDailyRecommendCardObject) => {
            ListItem() {
              HomeDailyRecommendCard(blockResourceItem)
            }
          })

        ListItem().width(PageSpace - ListSpace) // 占位
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
    }
    .alignItems(HorizontalAlign.Start)
  }
}
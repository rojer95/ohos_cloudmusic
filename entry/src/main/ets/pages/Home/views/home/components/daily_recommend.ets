import { BreakpointState, BreakpointSystem } from '../../../../../common/breakpointsystem';
import { ListSpace, PageSpace } from '../../../../../common/vars';
import { CommonTitle } from './common_title';
import { HomeDailyRecommendCard, HomeDailyRecommendCardObject } from './daily_recommend_card';


@ComponentV2
export struct HomeDailyRecommend {
  @Require @Param resources: HomeDailyRecommendCardObject[]
  @Param title: string = ''
  @Param dslShowTitle: boolean = false
  @Local listSpace: BreakpointState<number> = BreakpointState.of(ListSpace)

  aboutToAppear() {
    BreakpointSystem.getInstance().attach(this.listSpace)
  }

  aboutToDisappear() {
    BreakpointSystem.getInstance().detach(this.listSpace)
  }

  build() {

    Column() {
      if (this.dslShowTitle && this.title) {
        CommonTitle({ title: this.title })
      }

      List({ space: (this.listSpace.value || 8) }) {
        ListItem() // 占位
        ForEach(this.resources,
          (blockResourceItem: HomeDailyRecommendCardObject) => {
            ListItem() {
              HomeDailyRecommendCard(blockResourceItem)
            }
          })
       ListItem() // 占位
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
    }
    .alignItems(HorizontalAlign.Start)
  }
}
import { ImageKnifeComponent } from '@ohos/imageknife'
import { BreakpointState, BreakpointSystem } from '../../../../../common/breakpointsystem'
import { Utils } from '../../../../../common/utils'
import { ListSpace, PageSpace } from '../../../../../common/vars'

@ComponentV2
export struct CommonTitle {
  @Require @Param title: string
  @Param iconUrl: string = ''
  @Local listSpace: BreakpointState<number> = BreakpointState.of(ListSpace)

  aboutToAppear() {
    BreakpointSystem.getInstance().attach(this.listSpace)
  }

  aboutToDisappear() {
    BreakpointSystem.getInstance().detach(this.listSpace)
  }

  build() {

    Row({ space: this.listSpace.value || 8 }) {
      if (this.iconUrl) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: Utils.getCoverUrl(this.iconUrl),
            objectFit: ImageFit.Cover
          }
        })
          .borderRadius(15)
          .clip(true)
          .height(30)
          .width(30)

      }
      Text(this.title)
        .fontWeight(900)
        .fontSize(14)
    }
    .padding({
      left: this.listSpace.value || 8,
      right: this.listSpace.value || 8,
      bottom: this.listSpace.value || 8
    })
    .alignItems(VerticalAlign.Center)
    .width('100%')
  }
}
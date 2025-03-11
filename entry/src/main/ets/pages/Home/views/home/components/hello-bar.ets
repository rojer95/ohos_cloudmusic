import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';
import { BreakpointState, BreakpointSystem } from '../../../../../common/breakpointsystem';
import { ListSpace } from '../../../../../common/vars';

@ComponentV2
export struct HelloBar {
  @Param hello: string = '';
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local listSpace: BreakpointState<number> = BreakpointState.of(ListSpace)

  aboutToAppear() {
    BreakpointSystem.getInstance().attach(this.listSpace)
  }

  aboutToDisappear() {
    BreakpointSystem.getInstance().detach(this.listSpace)
  }

  build() {
    Flex({
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center
    }) {
      Text(this.hello).fontSize(22).fontWeight(600)

      Image($r('sys.media.ohos_ic_public_search_filled'))
        .draggable(false)
        .width(24)
        .height(24)
        .fillColor($r('app.color.music_bar_text_color'))
        .onClick(() => {
          this.pathStack.pushPath({ name: 'SearchPage' })
        })

    }.padding({
      left: this.listSpace.value || 8,
      right: this.listSpace.value || 8,
      bottom: 0
    })
  }
}


import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';

@ComponentV2
export struct HelloBar {
  @Param hello: string = '';
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();

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
        .fillColor('#ae000000')
        .onClick(() => {
          this.pathStack.pushPath({ name: 'SearchPage' })
        })

    }.padding({
      left: 12,
      right: 12,
      bottom: 0
    })
  }
}


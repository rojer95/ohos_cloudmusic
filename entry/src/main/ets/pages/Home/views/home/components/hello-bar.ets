import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';

@ComponentV2
export struct HelloBar {
  @Param hello: string = '';


  build() {
    Flex({
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center
    }) {
      Text(this.hello).fontSize(22).fontWeight(600)

    }.padding({
      left: 12,
      right: 12,
      top: 12,
      bottom: 0
    })
  }
}


import { LengthMetrics } from '@ohos.arkui.node'
import { PageSpace } from '../../../../../common/vars'
import { SearchBar } from './search-bar'

@ComponentV2
export struct HeaderBar {
  build() {
    Flex({ alignItems: ItemAlign.Center, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
      Button() {
        Image($r('app.media.icon_menu')).width(18).height(18).objectFit(ImageFit.ScaleDown).fillColor('#111111')
      }
      .width(30)
      .height(30)
      .flexShrink(0)
      .backgroundColor(Color.Transparent)
      .borderRadius(0)

      SearchBar()

      Button() {
        Image($r('app.media.icon_voice')).width(24).height(24).objectFit(ImageFit.ScaleDown).fillColor('#111111')
      }
      .width(30)
      .height(30)
      .flexShrink(0)
      .backgroundColor(Color.Transparent)
      .borderRadius(0)

    }.padding({
      top: 6,
      bottom: 6,
      left: PageSpace,
      right: PageSpace
    })
  }
}
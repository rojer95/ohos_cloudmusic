import { LengthMetrics } from '@kit.ArkUI'
import { SearchDefault } from '../../../../../model/search_default'

@ComponentV2
export struct SearchBar {
  @Param searchDefault?: SearchDefault = undefined;

  build() {
    Flex({ alignItems: ItemAlign.Center, space: { main: LengthMetrics.vp(6), cross: LengthMetrics.vp(6) } }) {
      Image($r('app.media.icon_search'))
        .height(14).width(14)
        .objectFit(ImageFit.ScaleDown)
        .fillColor('#a0a0a0')
      Column() {
        Text(this.searchDefault?.showKeyword)
          .fontSize(14)
          .fontColor('#a0a0a0')
          .width('100%')
          .height(18)
          .lineHeight(18)
      }.flexGrow(1)
      Image($r('app.media.icon_scan')).height(22).width(22).objectFit(ImageFit.ScaleDown).fillColor('#a0a0a0')
    }
    .flexGrow(1)
    .backgroundColor('#eee')
    .borderRadius(18)
    .height(36)
    .padding({
      left: 12, right: 12
    })
  }
}
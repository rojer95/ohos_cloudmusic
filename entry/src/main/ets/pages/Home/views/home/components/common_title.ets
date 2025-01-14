import { ImageKnifeComponent } from '@ohos/imageknife'
import { Utils } from '../../../../../common/utils'
import { PageSpace } from '../../../../../common/vars'

@ComponentV2
export struct CommonTitle {
  @Require @Param title: string
  @Param iconUrl: string = ''

  build() {

    Row({ space: 12 }) {
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
      left: PageSpace,
      right: PageSpace,
      bottom: PageSpace
    })
    .alignItems(VerticalAlign.Center)
    .width('100%')
  }
}
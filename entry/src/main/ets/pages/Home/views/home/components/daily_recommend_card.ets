import tinyColor from 'ohos_tinycolor2';
import { Utils, ImageMainColorRegion } from '../../../../../common/utils';
import { getPlayer } from '../../../../../viewmodel/global';
import { HomeBlockResourceItemExtInfo } from '../../../../../model/home_block';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { debuglog } from '../../../../../utils/log';
import { promptAction } from '@kit.ArkUI';


const SIZE = 140;
const SUB_TITLE_SIZE = 40;

export interface HomeDailyRecommendCardObject {
  resourceId?: string
  resourceType?: string
  subTitle?: string;
  coverImg?: string;
  tagText?: string;
  title?: string;
  singleLineTitle?: string;
  iconUrl?: string;
  titleBg?: boolean;
  extInfo?: HomeBlockResourceItemExtInfo
}

@ComponentV2
export struct HomeDailyRecommendCard {
  @Param coverImg: string | undefined = undefined
  @Param subTitle: string | undefined = undefined
  @Param singleLineTitle: string | undefined = undefined
  @Param tagText: string | undefined = undefined
  @Param title: string | undefined = undefined
  @Param iconUrl: string | undefined = undefined
  @Param titleBg: boolean = true
  @Param resourceId: string | undefined = undefined
  @Param resourceType: string | undefined = undefined
  @Param extInfo: HomeBlockResourceItemExtInfo | undefined = undefined
  @Local subTitleColor: Array<[string, number]> = []
  @Local titleColor: Array<[string, number]> = []
  @Local img?: PixelMap | string = undefined;
  @Local aniScale: number = 1
  @Local aniOpacity: number = 1

  @Monitor('coverImg','titleBg')
  async loadCoverImg() {
    if (!this.coverImg) {
      return;
    }

    if (!this.titleBg) {
      this.img = this.coverImg
      return
    }

    const regions: Array<ImageMainColorRegion> = [
      { key: 'top', region: [0, 0, 0.4, 0.4] },
      { key: 'bottom', region: [0.6, 0.6, 1, 1] },
    ]

    // 从主图获取配色策略，
    const colors = await Utils.getImageMainColor(this.coverImg, regions);

    this.img = colors.img

    if (colors.colors['top']) {
      let color = tinyColor.fromEffectKitColor(colors.colors['top'])
      if (color.getBrightness() >= 230) {
        color = color.darken(40)
      }
      if (color.getBrightness() <= 25) {
        color = color.lighten(40)
      }

      this.subTitleColor = [
        [color.toHex8String(), 0],
        [color.setAlpha(0.8).toHex8String(), 0.4],
        [color.setAlpha(0).toHex8String(), 0.8],
      ]
    }

    if (colors.colors['bottom']) {
      let color = tinyColor.fromEffectKitColor(colors.colors['bottom'])

      if (color.isLight()) {
        color = color.darken(40)
      }



      this.titleColor = [
        [color.setAlpha(0.8).toHex8String(), 0],
        [color.setAlpha(0.5).toHex8String(), 1],
      ]
    }

  }

  aboutToAppear(): void {
    this.loadCoverImg()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景图
      ImageKnifeComponent({
        imageKnifeOption: {
          loadSrc: this.coverImg,
          objectFit: ImageFit.Cover
        }
      })
        .height(this.singleLineTitle ? SIZE : SIZE + SUB_TITLE_SIZE)
        .width(SIZE)


      if (this.subTitle || this.tagText) {
        // 顶部标题背景
        Column()
          .height(50)
          .width('100%')
          .linearGradient({ colors: this.subTitleColor })

        // 顶部标题
        Row() {
          // 图标
          if (this.iconUrl) {
            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: this.iconUrl,
                objectFit: ImageFit.Contain
              }
            })
              .width(22)
              .height(22)
              .margin({ right: 4 })
              .draggable(false)
          }
          Text(this.subTitle || this.tagText).fontSize(14).fontColor('#ffffffff').fontWeight(900)
        }.padding({ left: 8, top: 8 })

        if (this.subTitle && this.tagText) {
          // Tag标题
          Column() {
            Text(this.tagText).fontSize(10).fontColor('#ffffffff').fontWeight(900)
          }
          .margin({
            left: 8,
            top: SIZE - 24
          })
          .padding({
            left: 4,
            top: 2,
            right: 4,
            bottom: 2
          })
          .backgroundColor('#4d000000')
          .borderRadius(4)
        }
      }


      // 底部标题-单行
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Text(this.singleLineTitle ? this.singleLineTitle : this.title)
          .width('100%')
          .fontColor('#ffffffff')
          .fontSize(10)
          .maxLines(this.singleLineTitle ? 1 : 2)
          .padding({ left: 10, right: 10 })
          .fontWeight(700)
          .textAlign(this.singleLineTitle ? TextAlign.Center : TextAlign.Start)
      }
      .height(SUB_TITLE_SIZE)
      .width('100%')
      .linearGradient(
        {
          colors: this.titleColor
        }
      )
      .backgroundColor(this.titleBg ? '#00000000' : Color.Transparent)
      .margin({ top: SIZE })

    }
    .height(SIZE + SUB_TITLE_SIZE)
    .width(SIZE)
    .backgroundColor('#ffffffff')
    .borderRadius(8)
    .clip(true)
    // 按下动画
    .stateStyles({
      normal: {
        .opacity(1)
        .scale({
          x: 1,
          y: 1,
        })
      },
      pressed: {
        .opacity(0.8)
        .scale({
          x: 0.95,
          y: 0.95,
        })
      }
    })
    .animation({
      duration: 500
    })
    // 显示动画
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.6, y: 0.6 }).animation({ curve: Curve.Ease }))
    )

    .onClick(() => {

      const player = getPlayer()
      if (!player || !this.resourceId || !this.resourceType) {
        return;
      }
      try {
        const tempId: string[] | number = JSON.parse(this.resourceId);
        let id: string = ''
        if (Array.isArray(tempId)) {
          id = tempId.join(',')
        } else {
          id = String(tempId)
        }

        player.start(id, this.resourceType, {
          songId: this.extInfo?.songId ? String(this.extInfo?.songId) : undefined
        })
      } catch (e) {
        promptAction.showToast({ message: "暂不支持的特性" })
      }
    })
  }
}
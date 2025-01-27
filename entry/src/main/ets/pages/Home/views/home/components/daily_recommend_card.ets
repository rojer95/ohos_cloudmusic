import tinyColor from 'ohos_tinycolor2';
import { Utils, ImageMainColorRegion } from '../../../../../common/utils';
import { getPlayer } from '../../../../../viewmodel/global';
import { HomeBlockResourceItemExtInfo } from '../../../../../model/home_block';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { debuglog } from '../../../../../utils/log';
import { promptAction } from '@kit.ArkUI';
import { MusicPlayBtn } from '../../../../../components/music_play_btn';
import { Playlist, TrackId } from '../../../../../model/playlist_detail';
import { apiDailyRecommendSongs } from '../../../../../api/recommend';


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
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
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
      { key: 'top', region: [0, 0, 0.3, 0.3] },
      { key: 'bottom', region: [0.7, 0.7, 1, 1] },
    ]

    // 从主图获取配色策略，
    const colors = await Utils.getImageMainColor(this.coverImg, regions);

    this.img = colors.img

    if (colors.colors['top']) {
      let color = tinyColor('#000000')
      this.subTitleColor = [
        [color.setAlpha(0.6).toHex8String(), 0],
        [color.setAlpha(0.3).toHex8String(), 0.4],
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

  play() {
    debuglog('resourceType', this.resourceType);
    debuglog('resourceId', this.resourceId);


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
  }

  async gotoDetail() {
    if (this.resourceType == 'dailySongs') {
      const dailySongsResponse = await apiDailyRecommendSongs(); // 获取歌单详情
      const detail: Playlist = {
        trackIds: (dailySongsResponse.dailySongs || []).map(song => ({
          id: song.id
        } as TrackId)),
        tracks: [],
        backgroundCoverUrl: this.coverImg,
        detailPageTitle: dailySongsResponse.recommendReasons?.[0]?.reason,
        description: dailySongsResponse.recommendReasons?.[1]?.reason,
        name: dailySongsResponse.recommendReasons?.[0]?.reason,
      }
      const param: Record<string, string | Playlist> =
        {
          'id': String(this.resourceId),
          'type': 'detail',
          'detail': detail
        };
      this.pathStack.pushPathByName('PlaylistPage', param)
      return true
    }
    return false
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景图
      ImageKnifeComponent({
        imageKnifeOption: {
          loadSrc: Utils.getCoverUrl(this.coverImg),
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
                loadSrc: Utils.getCoverUrl(this.iconUrl),
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

      if (this.resourceType === 'dailySongs') {
        MusicPlayBtn({
          playType: this.resourceType,
          color: '#FFFFFF'
        })
          .onClick(() => {
            this.play()
          })
          .margin({ top: SIZE - 30, left: SIZE - 30 })
          .width(20)
          .height(20)
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
    .onClick(async () => {
      const isJump = await this.gotoDetail();
      debuglog('isJump', isJump)
      if (!isJump) {
        this.play()
      }
    })
  }
}
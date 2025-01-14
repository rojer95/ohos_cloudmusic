import { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import { Player } from '../viewmodel/player';
import { Utils } from '../common/utils';
import { getPlayer, getGlobal, GlobalContent } from '../viewmodel/global';
import { LyricBox } from './lyric';
import { emitter } from '@kit.BasicServicesKit';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { SongLevel } from '../common/songLevel';
import { debuglog } from '../utils/log';
import { SwipeRefresher } from '@kit.ArkUI';

enum DisplayMode {
  Cover = 0,
  Lyric = 1
}

const barAniPlayOption: AnimatorOptions = {
  duration: 300,
  easing: 'linear',
  delay: 0,
  fill: "forwards",
  direction: "normal",
  iterations: 1,
  begin: -45,
  end: 0,
}

const barAniStopOption: AnimatorOptions = {
  duration: 300,
  easing: 'linear',
  delay: 0,
  fill: "forwards",
  direction: "normal",
  iterations: 1,
  begin: 0,
  end: -45,
}

@ComponentV2
export struct MusicPage {
  @Local global: GlobalContent | undefined = getGlobal()
  @Local player: Player | undefined = getPlayer()
  @Local angle: number = 0
  @Local barAngle: number = -45
  @Local mode: DisplayMode = DisplayMode.Cover;
  @Local isShowLevelToggle: boolean = false
  /** 旋转动画 **/
  private ani?: AnimatorResult
  /** 拨杆动画 **/
  private barAni?: AnimatorResult
  private aniIng: boolean = false;

  aboutToAppear(): void {
    // console.log('MusicPage aboutToAppear...')
    this.ani = this.getUIContext().createAnimator({
      duration: 30000,
      easing: 'linear',
      delay: 0,
      fill: "forwards",
      direction: "normal",
      iterations: -1,
      begin: 0,
      end: 360,
    });


    this.ani.onFrame = (progress: number) => {
      this.angle = progress
    }

    this.barAni = this.getUIContext().createAnimator(barAniPlayOption);

    this.barAni.onFrame = (progress: number) => {
      this.barAngle = progress
    }

    this.onPlayChange()
  }

  aboutToDisappear(): void {
    console.log('MusicPage aboutToDisappear...')
    this.ani?.cancel()
    this.ani = undefined
    this.barAni?.cancel()
    this.barAni = undefined
  }

  @Monitor('player.playingState','player.isToggleLeveling')
  onPlayChange() {
    // 拖动音质情况下，不切换动画
    if (this.player?.isToggleLeveling) {
      return
    }

    if (this.player?.playingState === 'playing') {
      if (!this.aniIng) {
        this.startAni()
        this.aniIng = true
      }
    } else {
      if (this.aniIng) {
        this.stopAni()
        this.aniIng = false
      }
    }
  }

  startAni() {
    this.ani?.play()
    this.barAni?.reset(barAniPlayOption)
    this.barAni?.play()
  }

  stopAni() {
    this.ani?.pause()
    this.barAni?.reset(barAniStopOption)
    this.barAni?.play()
  }

  toggle() {
    if (this.player?.playingState === 'playing') {
      getPlayer()?.pause()
    } else {
      getPlayer()?.play()
    }
  }

  getLoopIcon(n: number): Resource | undefined {
    if (n === 0) {
      return $r('app.media.icon_loop_0')
    }
    if (n === 1) {
      return $r('app.media.icon_loop_1')
    }
    if (n === 2) {
      return $r('app.media.icon_loop_2')
    }
    if (n === 3) {
      return $r('app.media.icon_loop_3')
    }

    return undefined
  }

  goBack() {
    let eventData: emitter.EventData = {
      data: {
        show: false,
        page: 'music'
      }
    }
    emitter.emit('globalModal', eventData)
  }

  /**
   * 音质选择器
   */
  @Builder
  levelToggleBuilder() {

    Column() {
      // 第一步：自定义滚动容器
      List({ space: '10vp' }) {
        ForEach(this.player?.activeLevels || [], (item: SongLevel) => {
          ListItem() {
            Text(String(item.label)).fontSize(14).fontWeight(
              this.player?.level === item.value ?
              FontWeight.Bold : FontWeight.Normal)
          }
          .width('90%')
          .height('40vp')
          .border({
            width: 1, color:
            this.player?.level === item.value ?
              '#a3000000' : '#12000000'
          })
          .borderRadius(10)
          .onClick(() => {

            if (this.player?.level === item.value) {
              return;
            }
            this.player?.toggleMusicLevel(item.value)
            this.isShowLevelToggle = false
          })
        })
      }
      .alignListItem(ListItemAlign.Center)
      .margin({ top: '10vp' })
      .width('100%')
      .height('300vp')
    }.width('100%')
  }

  build() {
    Stack() {
      // 背景
      Column() {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.player?.playingMediaImage ? Utils.getCoverUrl(this.player?.playingMediaImage, 400, 400) :
              undefined
          }
        })
          .height('100%')
          .width('100%')
          .blur(400)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .height('100%')
      .width('100%')
      .opacity(0.3)
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])


      Column() {
        // 顶部栏
        Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
          // 关闭按钮
          Button() {
            Image($r('app.media.icon_down'))
              .fillColor('#ccffffff')
              .width(28)
              .height(22)
              .draggable(false)
          }
          .width(42)
          .height(42)
          .flexShrink(0)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.goBack()
          })

          // 歌单名
          Text(this.player?.avQueueName || '')
            .fontColor('#ccffffff')
            .flexGrow(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .fontSize(14)

          // 占位
          Column() {
          }
          .width(42)
          .height(42)
          .flexShrink(0)
        }
        .padding({ left: 22, right: 22, top: px2vp(this.global?.topRectHeight || 0) })
        .flexShrink(0)
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM))


        // 歌词、音乐碟
        Column() {
          Swiper() {

            // 音乐碟
            Stack() {
              Column() {
                // 封面图
                Stack() {
                  Image($r('app.media.disc'))
                    .height(280)
                    .width(280)
                    .draggable(false)

                  if (this.player?.playingMediaImage) {
                    ImageKnifeComponent({
                      imageKnifeOption: {
                        loadSrc: Utils.getCoverUrl(this.player?.playingMediaImage, 400, 400)
                      }
                    })
                      .height(280 * 0.6)
                      .width(280 * 0.6)
                      .borderRadius(280 * 0.6 / 2)
                      .clip(true)
                      .rotate({ angle: this.angle })
                  }
                }
                .width('100%')
              }
              .margin({ top: 133 })

              // 指针
              Image($r('app.media.disc_bar'))
                .width(200)
                .height(200)
                .objectFit(ImageFit.Contain)
                .rotate({ angle: this.barAngle, centerX: 100, centerY: 100 })
                .draggable(false)
            }

            .alignContent(Alignment.Top)
            .height('100%')


            // 歌词
            Column() {
              LyricBox()
            }
            .height('100%')
            .padding({
              left: 24,
              right: 24,
            })

          }
          .height('100%')
          .width('100%')
          .indicator(false)
          .loop(false)

        }
        .height(0)
        .flexGrow(1)
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM))

        // 歌曲信息
        Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
          Column() {
            // 歌名
            Text(this.player?.playingTitle)
              .fontColor('#ffffffff')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize(18)
              .fontWeight(900)

            // 歌手
            if (this.player?.playingArtist) {
              Text(this.player?.playingArtist)
                .fontColor('#ccffffff')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(14)
                .margin({ top: 6 })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .flexGrow(1)

        }
        .margin({ top: 22 })
        .padding({ left: 22, right: 22 })
        .flexShrink(0)
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM))


        // 进度
        Column() {
          Slider({
            value: this.player?.time || 0,
            min: 0,
            max: this.player?.duration || 0,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .selectedColor('#ffffffff')
            .trackColor('#99ffffff')
            .trackThickness(2)
            .slideRange({
              from: 0,
              to: this.player?.playingRealDuration || this.player?.duration
            })
            .blockSize({
              height: 6,
              width: 6
            })
            .onChange((_v: number, _mode: SliderChangeMode) => {
              if (_mode === SliderChangeMode.End) {
                getPlayer()?.setSeek(_v)
              }
            })

        }
        .margin({ top: 22 })
        .padding({ left: 16, right: 16 })
        .flexShrink(0)
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM))


        // 时间

        Row() {
          Text(Utils.duration2timeString(this.player?.time || 0)).fontColor('#99ffffff').fontSize(10)
          Row() {
            if (this.player?.isToggleLeveling) {
              SwipeRefresher({
                isLoading: true,
              }).height(16).width(16)
            }
            Text(this.player?.isToggleLeveling ? '切换中...' : this.player?.levelName)
              .fontColor('#99ffffff')
              .fontSize(10)
              .onClick(() => {
                if (this.player?.isToggleLeveling) {
                  return
                }
                this.isShowLevelToggle = !this.isShowLevelToggle
              })
          }.justifyContent(FlexAlign.Center)

          Text(Utils.duration2timeString(this.player?.duration || 0)).fontColor('#99ffffff').fontSize(10)
        }
        .width('100%')
        .height(16)
        .padding({ left: 22, right: 22 })
        .justifyContent(FlexAlign.SpaceBetween)
        .flexShrink(0)
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM))


        // 播放控制器
        Row() {
          // 循环模式
          Button() {
            Image(this.getLoopIcon(this.player?.loopMode || 0))
              .width(20)
              .height(20)
              .fillColor('#FFFFFF')
              .objectFit(ImageFit.Contain)
              .draggable(false)
          }
          .width(45)
          .height(45)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            getPlayer()?.toggleLoopMode()
          })

          // 上一首
          Button() {
            Image($r('app.media.icon_pre'))
              .width(30)
              .height(30)
              .draggable(false)
              .objectFit(ImageFit.Contain)
              .fillColor('#ccffffff')
          }
          .width(45)
          .height(45)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            getPlayer()?.playPrevious()
          })

          // 播放暂停

          Button() {
            Image(this.player?.playingState === 'playing' || this.player?.isToggleLeveling ?
            $r('app.media.icon_pause') : $r('app.media.icon_play'))
              .width(60)
              .height(60)
              .draggable(false)
              .objectFit(ImageFit.Contain)
              .fillColor('#ccffffff')
          }
          .width(80)
          .height(80)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.toggle()
          })


          // 下首
          Button() {
            Image($r('app.media.icon_next'))
              .width(30)
              .height(30)
              .draggable(false)
              .objectFit(ImageFit.Contain)
              .fillColor('#ccffffff')
          }
          .width(45)
          .height(45)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            getPlayer()?.playNext()
          })


          // 点赞
          Button() {
            Image(
              this.player?.playingIsFavorite ? $r('app.media.icon_liked') : $r('app.media.icon_like'))
              .width(22)
              .height(22)
              .fillColor('#FFFFFF')
              .objectFit(ImageFit.Contain)
              .draggable(false)
          }
          .width(45)
          .height(45)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            const player = getPlayer();
            if (!player || !player.songId) {
              return;
            }

            if (this.player?.playingIsFavorite) {
              player.like(player.songId, false)
            } else {
              player?.like(player.songId, true)
            }
          })
        }
        .width('100%')
        .margin({ bottom: 20, top: 20 })
        .padding({ left: 22, right: 22 })
        .justifyContent(FlexAlign.SpaceAround)
        .flexShrink(0)
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM))
      }
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)

    }
    .bindSheet($$this.isShowLevelToggle, this.levelToggleBuilder(), {
      preferType: SheetType.BOTTOM,
      height: '400vp',
      blurStyle: BlurStyle.COMPONENT_REGULAR,
      title: { title: '选择音质' },
    })
    .alignContent(Alignment.Top)
  }
}
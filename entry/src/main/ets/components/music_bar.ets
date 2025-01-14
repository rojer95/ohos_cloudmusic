import { PageSpace } from '../common/vars';
import { LengthMetrics } from '@kit.ArkUI';
import { AnimatorResult } from '@ohos.animator';
import { getPlayer } from '../viewmodel/global';
import { emitter } from '@kit.BasicServicesKit';
import { Player } from '../viewmodel/player';
import { ImageKnifeComponent } from '@ohos/imageknife';
import tinycolor from 'ohos_tinycolor2';

@ComponentV2
export struct MusicBar {
  // @StorageProp('playingInfo') playingInfo?: avSession.AVMetadata = undefined
  // @StorageProp('playingState') @Watch('onPlayChange') playingState: media.AVPlayerState = 'idle'
  // @StorageProp('playingTime') time: number = 0;
  // @StorageProp('playingDuration') duration: number = 0;
  @Param bgColor: string = '#faffffff'
  @Param textColor: string = '#111111'
  @Local player: Player | undefined = getPlayer()
  @Local angle: number = 0
  private ani?: AnimatorResult
  private aniIng: boolean = false;

  aboutToAppear(): void {
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

    this.onPlayChange()
  }

  aboutToDisappear(): void {
    this.ani?.cancel()
    this.ani = undefined
  }

  @Monitor('player.playingState')
  onPlayChange() {
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
  }

  stopAni() {
    this.ani?.pause()
  }

  build() {
    if (this.player?.playingTitle) {

      Flex({
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween,
        space: {
          main: LengthMetrics.vp(8),
          cross: LengthMetrics.vp(8),
        }
      }) {
        // 音乐碟
        Stack() {
          Image($r('app.media.disc'))
            .height(40)
            .width(40)
            .draggable(false)

          if (this.player?.playingMediaImage) {

            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: `${this.player?.playingMediaImage}?param=100y100`
              }
            })
              .height(16)
              .width(16)
              .borderRadius(8)
              .clip(true)
              .rotate({ angle: this.angle })

          }
        }
        .height(40)
        .width(40)
        .flexShrink(0)


        // 音乐信息
        Text() {
          Span(this.player?.playingTitle || '').fontColor(this.textColor).fontSize(14)
          Span(this.player?.playingArtist ? ` - ${this.player?.playingArtist}` : '')
            .fontColor(tinycolor(this.textColor).setAlpha(0.6).toHex8String()).fontSize(12)
        }
        .width(0)
        .flexGrow(1)
        .maxLines(1)
        .lineHeight(14)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

        Stack() {
          Progress({ value: this.player?.time, total: this.player?.duration, type: ProgressType.Ring })
            .height(20)
            .width(20)
            .color('#ff5f5f5f')
            .backgroundColor('#ffcbcbcb')
            .style({
              strokeWidth: 2
            })
          // 播放按钮
          Button() {
            Image(this.player?.playingState === 'playing' ? $r('app.media.icon_pause') : $r('app.media.icon_play'))
              .height(10)
              .width(10)
              .objectFit(ImageFit.Contain)
              .fillColor('#ff5f5f5f')
              .draggable(false)
          }
          .height(30)
          .width(30)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.player?.playingState === 'playing') {
              getPlayer()?.pause()
            } else {
              getPlayer()?.play()
            }
          })
        }
      }.padding({
        left: PageSpace,
        top: 4,
        right: PageSpace,
        bottom: 4
      })
      .backgroundColor(this.bgColor)
      .onClick(() => {
        let eventData: emitter.EventData = {
          data: {
            show: true,
            page: 'music'
          }
        }
        emitter.emit('globalModal', eventData)
      })
    } else {
      Column()
    }
  }
}
import { getPlayer } from '../viewmodel/global';
import { Player } from '../viewmodel/player';

@ComponentV2
export struct MusicPlayBtn {
  @Param songId: string | undefined = undefined
  @Param avQueueId: string | undefined = undefined
  @Param playType: string | undefined = undefined
  @Param color: string = '#717171'
  @Local isActive: boolean = false;
  @Local player: Player | undefined = getPlayer()

  @Monitor('songId', 'playType','avQueueId', 'player.type', 'player.songId', 'player.avQueueId')
  onActive() {
    if (this.songId) {
      this.isActive = `${this.songId}` === `${this.player?.songId}`
    } else if (this.playType) {
      this.isActive = `${this.playType}` === `${this.player?.type}`
    }  else if (this.avQueueId) {
      this.isActive = `${this.avQueueId}` === `${this.player?.avQueueId}`
    } else {
      this.isActive = false
    }
  }

  aboutToAppear(): void {
    this.onActive()
  }

  build() {
    Image(
      this.isActive && this.player?.playingState === 'playing' ?
      $r('app.media.icon_pause') :
      $r('app.media.icon_play'))
      .draggable(false)
      .objectFit(ImageFit.ScaleDown)
      .width('100%')
      .height('100%')
      .fillColor(this.color)
  }
}
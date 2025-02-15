import { fileIo as fs } from '@kit.CoreFileKit';
import { CacheUtil } from '../viewmodel/cache'

@ComponentV2
export struct MusicCached {
  @Param mode: 'icon' | 'text' = 'icon'
  @Param songId: string | undefined = undefined
  @Param level: string | undefined = undefined
  @Param color: string | undefined = undefined
  @Local isActive: boolean = false;

  @Monitor('songId','level')
  onActive() {
    const songs = CacheUtil.findCacheBySongId(this.songId || '-1')
    if (this.level) {
      this.isActive = songs.some(s => s.level === this.level)
    } else {
      this.isActive = songs.length > 0
    }
  }

  aboutToAppear(): void {
    this.onActive()
  }

  build() {
    if (this.isActive) {
      if (this.mode === 'icon') {
        Image(
          $r('app.media.icon_cached')
        )
          .draggable(false)
          .objectFit(ImageFit.ScaleDown)
          .opacity(0.6)
          .height(12)
          .width(12)
          .fillColor(this.color ?? $r('app.color.normal_text_color'))

      } else {
        Text('已缓存')
          .opacity(0.6)
          .fontSize(8)
          .padding(3)
          .borderRadius(12)
          .fontColor(this.color ?? $r('app.color.normal_text_color'))
          .border({ width: 1, color: this.color ?? $r('app.color.normal_text_color') })
      }
    }
  }
}
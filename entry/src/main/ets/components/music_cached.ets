import fs from '@ohos.file.fs'
import { SongLevels } from '../common/song_level';

@ComponentV2
export struct MusicCached {
  @Param songId: string | undefined = undefined
  @Param color: string | undefined = undefined
  @Local isActive: boolean = false;

  onActive() {
    this.isActive = fs.accessSync(getContext().cacheDir + '/' + `${this.songId}`)
  }

  aboutToAppear(): void {
    this.onActive()
  }

  build() {
    if (this.isActive) {
      Image(
        $r('app.media.icon_cached')
      )
        .draggable(false)
        .objectFit(ImageFit.ScaleDown)
        .width('100%')
        .height('100%')
        .opacity(0.6)
        .fillColor(this.color ?? $r('app.color.normal_text_color'))
    }
  }
}
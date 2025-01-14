import { LyricController, LyricParser, LyricView2 } from '@seagazer/cclyric'
import { getPlayer } from '../viewmodel/global'
import { Player } from '../viewmodel/player';

@ComponentV2
export struct LyricBox {
  @Local player: Player | undefined = getPlayer()
  // @StorageProp('playingTime') @Watch('onTimeChange') time: number = 0;
  // @StorageProp('playingLyric') @Watch('onLyricChange') playingLyric: string = '';
  // 1.初始化controller
  private lyricController: LyricController = new LyricController()
  private parser = new LyricParser()

  aboutToAppear(): void {
    // 2.自定义样式属性
    this.lyricController
    ?.setTextSize(12)
    ?.setCacheSize(4)
    ?.setTextColor("#66000000")
    ?.setHighlightColor("#b3000000")
    ?.setLineSpace(8)
    ?.setEmptyHint("当前没有歌词")
    ?.setAlignMode("center")

  }

  onDidBuild(): void {
    this.onLyricChange()
  }

  @Monitor('player.playingLyric')
  onLyricChange() {
    this.lyricController?.updatePosition(0)
    this.lyricController?.setLyric(null);

    setTimeout(() => {
      const lyricList = (this.player?.playingLyric || '').split('\n').filter(i => String(i || '').trim()) || []
      if (lyricList.length === 0) {
        this.lyricController?.setLyric(null)
        return;
      }

      // 3.解析歌词
      let lyric = this.parser.parse(lyricList)
      console.log('set lyric', JSON.stringify(lyric))

      // 4.设置歌词
      this.lyricController?.setLyric(lyric)
    }, 500)

  }

  @Monitor('player.time')
  onTimeChange() {
    this.lyricController?.updatePosition(this.player?.time || 0)
  }

  build() {

    Column() {
      LyricView2({
        controller: this.lyricController,
        enableSeek: true, // 开启滑动歌词seek能力
        seekUIColor: "#ff4a4a4a", // 滑动定位的按钮和文本颜色
        seekLineColor: "#00ffffff", // 滑动定位线颜色
        seekUIStyle: "listItem", // 滑动定位样式（seekLine传统样式，listItem类似抖音汽水音乐样式）
        onSeekAction: (position) => { // 滑动歌词触发seek定位回调
          // this.player.seekTo(position)
          console.log('onSeekAction ---->', position)
          getPlayer()?.setSeek(position)
          return true
        },
      }).height("100%").width("100%").layoutWeight(1)

    }

  }
}
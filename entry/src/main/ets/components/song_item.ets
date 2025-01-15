import { SongDetail, SongPrivilege } from "../model/song_detail";
import { MusicPlayBtn } from "./music_play_btn";

@ComponentV2
export struct SongItem {
  @Require @Param index: number;
  @Require @Param detail: SongDetail
  @Require @Param privilege: SongPrivilege
  @Param color: string | undefined = undefined

  build() {
    Flex({ alignItems: ItemAlign.Center }) {
      Column() {
        Text(`${this.index}`).fontColor(this.color)
      }.width(50)
      .flexShrink(0)

      Column() {
        Text(this.detail.name).fontSize(14).fontColor(this.color)
          .margin({ bottom: 8 })
        Row() {
          Text([
            this.detail.ar?.map(ar => ar.name).join('/'),
            this.detail.al?.name
          ].filter(i =>!!i).join(' - '))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(12)
            .fontColor(this.color)
            .opacity(0.6)
        }
      }.alignItems(HorizontalAlign.Start)
      .flexGrow(1)

      Column() {
        MusicPlayBtn({
          color: this.color,
          songId: `${this.detail.id}`,
        }).width(14).height(14).opacity(0.7)
      }
    }
    .opacity((this?.privilege?.st || 0) < 0 ? 0.3 : 1)
    .padding({
      top: 10,
      bottom: 10,
      left: 0,
      right: 20
    })
    .width('100%')
  }
}
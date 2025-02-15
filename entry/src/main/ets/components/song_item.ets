import { ImageKnifeComponent } from "@ohos/imageknife";
import { Utils } from "../common/utils";
import { SongDetail, SongPrivilege } from "../model/song_detail";
import { MusicCached } from "./music_cached";
import { MusicPlayBtn } from "./music_play_btn";
import { LengthMetrics } from "@ohos.arkui.node";

@ComponentV2
export struct SongItem {
  @Require @Param index: number;
  @Param showCover: boolean = false;
  @Require @Param detail: SongDetail
  @Require @Param privilege: SongPrivilege
  @Param color: string | undefined = undefined

  build() {
    Flex({ alignItems: ItemAlign.Center }) {

      Column() {
        if (this.showCover && this?.detail?.al?.picUrl) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: Utils.getCoverUrl(this?.detail?.al?.picUrl, 100, 100),
            }
          })
            .height(50)
            .width(50)
            .borderRadius(8)
            .clip(true)
        } else {
          Text(`${this.index}`).fontColor(this.color)
        }

      }
      .margin({ left: 12, right: 12 })
      .width(50)
      .flexShrink(0)

      Column() {
        Text(this.detail.name).fontSize(14).fontColor(this.color)
          .margin({ bottom: 8 })
        Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start, space: { main: LengthMetrics.px(4) } }) {

          MusicCached({ songId: `${this.detail.id}`, color: this.color })
            .flexShrink(0)

          Text([
            this.detail.ar?.map(ar => ar.name).join('/'),
            this.detail.al?.name
          ].filter(i => !!i).join(' - '))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(12)
            .fontColor(this.color)
            .opacity(0.6)


        }
      }
      .alignItems(HorizontalAlign.Start)
      .flexGrow(1)

      Column() {
        MusicPlayBtn({
          color: this.color,
          songId: `${this.detail.id}`,
        }).width(14).height(14).opacity(0.7).margin({ left: 4 })
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
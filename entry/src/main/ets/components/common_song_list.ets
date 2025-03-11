import { SongDetailWithPrivilege } from "../model/song_detail";
import { getGlobal, GlobalContent } from "../viewmodel/global";
import { TrackDataSource } from "../model/datasource";
import { SongItem } from "../components/song_item";
import { SwipeRefresher } from "@kit.ArkUI";
import { debuglog } from "../utils/log";


@ComponentV2
export struct CommonSongList {
  @Require @Param data: TrackDataSource;
  @Require @Param isNotMore: boolean = false
  @Require @Param loading: boolean = false
  @Param color: string | undefined = undefined
  @Param withBottomSafeArea: boolean = true
  @Param showCover: boolean = false;
  @Event onMusicClick: (x: SongDetailWithPrivilege) => void = (x: SongDetailWithPrivilege) => {
  }
  @Param deleteAble: boolean = false;
  @Event onDelete: ((x: SongDetailWithPrivilege) => void) | undefined;
  @Local global: GlobalContent | undefined = getGlobal()

  @Builder
  buildAction(item: SongDetailWithPrivilege) {
    // 构建尾端滑出组件
    Column() {
      Text('删除').fontSize(12).fontColor('#FFFFFF')
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width(100)
    .height('100%')
    .backgroundColor('red')
    .onClick(() => {
      this.onDelete?.(item)
    })
  }

  @Builder
  build() {
    Column() {
      List({ space: 6 }) {
        LazyForEach(this.data, (item: SongDetailWithPrivilege, index: number) => {
          ListItem() {
            SongItem({
              index: index + 1,
              detail: item.detail,
              privilege: item.privilege,
              showCover: this.showCover,
              color: this.color
            })
              .onClick(() => {
                // st < 0 没有版权，设置灰色
                if ((item?.privilege?.st || 0) < 0) {
                  return;
                }

                this.onMusicClick(item)

              })
          }.swipeAction(this.deleteAble ? {
            end: {
              builder: () => {
                this.buildAction(item)
              }
            }
          } : undefined)
        }, (item: SongDetailWithPrivilege) => `${item.detail.id}`)

        if (this.loading) {
          ListItem() {
            SwipeRefresher({
              content: '正在加载中',
              isLoading: true,
            })
          }
        }

        if (this.isNotMore) {
          ListItem() {
            Text('没有更多歌曲')
              .fontSize(12)
              .width('100%')
              .textAlign(
                TextAlign.Center
              )
              .fontColor(this.color)
              .opacity(0.7)
              .padding({ top: 10, bottom: 20 })
              .margin({ bottom: px2vp(this.global?.bottomRectHeight || 0) * (this.withBottomSafeArea ? 3 : 1) })
          }
        }
      }
    }
  }
}
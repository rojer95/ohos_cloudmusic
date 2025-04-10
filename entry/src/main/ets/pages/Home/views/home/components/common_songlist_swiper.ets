import { ListSpace, PageSpace } from '../../../../../common/vars'
import { curves, LengthMetrics } from '@kit.ArkUI'
import { MusicPlayBtn } from '../../../../../components/music_play_btn';
import { getPlayer } from '../../../../../viewmodel/global';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { Utils } from '../../../../../common/utils'
import { BreakpointState, BreakpointSystem } from '../../../../../common/breakpointsystem';

export interface CommonSongListSwiperItemSong {
  resourceId?: string;
  resourceType?: string;
  cover?: string;
  title?: string;
  tag?: string;
  recReason?: string;
  artistName?: string;
}

export interface CommonSongListSwiperItem {
  songs: CommonSongListSwiperItemSong[]
}

@ComponentV2
export struct CommonSongListSwiper {
  @Require @Param list: CommonSongListSwiperItem[]
  @Require @Param title: string
  @Local displayCount: BreakpointState<number> = BreakpointState.of({ sm: 1, md: 2, lg: 3 })
  @Local listSpace: BreakpointState<number> = BreakpointState.of(ListSpace)

  aboutToAppear() {
    BreakpointSystem.getInstance().attach(this.displayCount)
    BreakpointSystem.getInstance().attach(this.listSpace)
  }

  aboutToDisappear() {
    BreakpointSystem.getInstance().detach(this.displayCount)
    BreakpointSystem.getInstance().detach(this.listSpace)
  }

  getIds(_list: CommonSongListSwiperItem[]) {

    const ids: string[] = [];
    for (let items of _list) {
      for (let item of (items?.songs || [])) {
        if (item.resourceId) {
          ids.push(item.resourceId)
        }
      }
    }

    return ids
  }

  build() {

    Swiper() {
      ForEach(this.list, (list: CommonSongListSwiperItem) => {
        Column() {
          ForEach(list.songs, (song: CommonSongListSwiperItemSong) => {
            Flex({
              space: { cross: LengthMetrics.vp(PageSpace), main: LengthMetrics.vp(PageSpace) },
              alignItems: ItemAlign.Center,
              justifyContent: FlexAlign.SpaceBetween
            }) {
              // 左侧封面图
              Column() {

                ImageKnifeComponent({
                  imageKnifeOption: {
                    loadSrc: Utils.getCoverUrl(song.cover),
                    objectFit: ImageFit.Contain
                  }
                })
                  .height(40)
                  .width(40)
                  .backgroundColor('#ffffff')
                  .borderRadius(8)
                  .clip(true)
              }.flexShrink(0)

              // 右侧信息栏目
              Column({ space: 4 }) {
                // 歌名
                Text(song.title)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontWeight(900)
                  .maxLines(1)
                  .fontSize(14)

                Row({ space: 6 }) {

                  // 推荐原因


                  // TAG
                  if (song.tag) {
                    Text(song.tag)
                      .fontSize(8)
                      .fontColor('#ffff0c0c')
                      .border({
                        width: 1,
                        color: '#ffff0c0c'
                      })
                      .padding({
                        left: 2,
                        right: 2,
                        top: 1,
                        bottom: 1
                      })
                      .borderRadius(6)
                  } else if (song.recReason) {
                    Text(song.recReason)
                      .fontSize(8)
                      .fontColor('#ffe50000')
                      .backgroundColor('#ffffdfdf')
                      .padding({
                        left: 2,
                        right: 2,
                        top: 1,
                        bottom: 1
                      })
                      .borderRadius(6)
                  }

                  // 歌手
                  Text(song.artistName)
                    .fontSize(12)
                    .fontColor('#99000000')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                    .flexGrow(1)
                }
              }
              .width(0)
              .alignItems(HorizontalAlign.Start)
              .flexGrow(1)

              // 播放按钮
              Column() {
                MusicPlayBtn({
                  songId: song.resourceId,
                })
                  .width(18)
                  .height(18)
              }.flexShrink(0)

              Column() // 占位

            }

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

            .margin({
              bottom: PageSpace
            })
            .onClick(() => {
              if (song.resourceId && song.resourceType) {
                getPlayer()?.start(song.resourceId, 'ids', {
                  avQueueName: this.title,
                  songId: song.resourceId,
                  ids: this.getIds(this.list)
                })
              }
            })
          })
        }

        .padding({ left: this.listSpace.value || 8 })
        .alignItems(HorizontalAlign.Start)
      })

    }

    .loop(false)
    .nextMargin(32)
    .displayCount(this.displayCount.value || 1)
    .indicator(false)

  }
}
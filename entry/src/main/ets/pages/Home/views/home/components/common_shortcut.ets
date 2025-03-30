import { ListSpace, PageSpace } from '../../../../../common/vars'
import { HomeBlockResourceItemExtInfo } from '../../../../../model/home_block';
import { PlayOptions } from '../../../../../viewmodel/player';
import { getPlayer } from '../../../../../viewmodel/global';
import { CommonTitle } from './common_title'
import { ImageKnifeComponent } from '@ohos/imageknife'
import { Utils } from '../../../../../common/utils';
import { BreakpointState, BreakpointSystem } from '../../../../../common/breakpointsystem';


export interface CommonShortcutItem {
  coverImg?: string;
  title?: string
  iconImg?: string;
  tag?: string;
  resourceId?: string;
  resourceType?: string
  extInfo?: HomeBlockResourceItemExtInfo
}

@ComponentV2
export struct CommonShortcut {
  @Require @Param resources: CommonShortcutItem[]
  @Param title: string = ''
  @Param dslShowTitle: boolean = false
  @Local listSpace: BreakpointState<number> = BreakpointState.of(ListSpace)

  aboutToAppear() {
    BreakpointSystem.getInstance().attach(this.listSpace)
  }

  aboutToDisappear() {
    BreakpointSystem.getInstance().detach(this.listSpace)
  }

  build() {
    Column() {
      if (this.dslShowTitle && this.title) {
        Column() {
          CommonTitle({ title: this.title })
        }
      }

      List({ space: (this.listSpace.value || 8) }) {

        ListItem()// 占位
        ForEach(this.resources || [], (item: CommonShortcutItem) => {
          ListItem() {
            Column() {
              // 歌单卡片
              Stack() {

                // 背景图
                ImageKnifeComponent({
                  imageKnifeOption: {
                    loadSrc: Utils.getCoverUrl(item.coverImg)
                  }
                }).width(80).height(80)


                // 标题
                if (item?.title) {
                  Text(item?.title)
                    .fontColor('#FFFFFF')
                    .fontSize(10)
                    .fontWeight(900)
                    .textShadow({
                      color: '#66000000',
                      radius: 3
                    })
                    .margin({ top: 6, left: 6 })
                }

                if (item?.iconImg) {
                  // icon
                  ImageKnifeComponent({
                    imageKnifeOption: {
                      loadSrc: Utils.getCoverUrl(item.iconImg),
                      objectFit: ImageFit.Contain
                    }
                  })
                    .draggable(false)
                    .width(30)
                    .height(30)
                    .margin({
                      top: 25,
                      left: 25
                    })
                } else if (item.tag) {
                  Text(item?.tag)
                    .fontColor('#FFFFFF')
                    .fontSize(8)
                    .fontWeight(900)
                    .backgroundColor('#cc000000')
                    .padding({
                      top: 4,
                      left: 4,
                      right: 5,
                      bottom: 4
                    })
                    .borderRadius(4)
                    .margin({ top: 60, left: 6 })
                }
              }
              .alignContent(Alignment.TopStart)
              .borderRadius(8)
              .clip(true)
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
            .onClick(() => {
              if (item.resourceId && item.resourceType) {
                const player = getPlayer();
                let id = item.resourceId;
                let type = item.resourceType;
                let options: PlayOptions | undefined = undefined
                if (item.resourceType === 'virtualPlaylist') {
                  id = item.extInfo?.songIdList?.join(',') || ''
                  type = 'ids'
                  options = { avQueueName: '私人推荐' }
                }
                player?.start(id, type, options)
              }
            })
          }
        })
        ListItem() // 占位

      }
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
    }.alignItems(HorizontalAlign.Start)
  }
}
import { LengthMetrics } from '@kit.ArkUI';
import { BreakpointSystem, BreakpointState } from '../../common/breakpointsystem';
import { MusicBar } from '../../components/music_bar';
import { MusicPage } from '../../components/music_page';
import { getGlobal, GlobalContent, getPlayer } from '../../viewmodel/global';
import { Player } from '../../viewmodel/player';
import { HomeTabContext } from './views/home';
import { MeTabContent } from './views/me';
import { emitter } from '@kit.BasicServicesKit';

@Builder
function pageBuilder() {
  HomePage()
}

interface TabBarProps {
  vertical: boolean;
  barPosition: BarPosition;
  compBarWidth: string;
  compBarHeight: string;
  compDirection: FlexDirection
}

interface Tab {
  icon: Resource
  label: string
  view: string
  index: number
}

@ComponentV2
struct HomePage {
  @Local currentTabIndex: number = 0;
  @Local global: GlobalContent | undefined = getGlobal()
  @Local player: Player | undefined = getPlayer()

  tabs: Tab[] = [
    {
      icon: $r("app.media.tabs_icon_home"),
      label: '发现',
      view: 'home',
      index: 0
    },
    {
      icon: $r("app.media.tabs_icon_me"),
      label: '我的',
      view: 'me',
      index: 1
    },
  ]

  aboutToAppear() {
  }

  aboutToDisappear() {
  }

  @Builder
  buildMusicPage() {
    MusicPage()
      .width('100%')
      .height('100%')
  }

  @Builder
  buildBar() {
    Column() {
      if (this.player?.playingTitle) {
        MusicBar().height('48vp').width('100%')
        Column().height('1vp').width('100%').backgroundColor('#08000000')
      }
      Flex({ justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
        ForEach(this.tabs, (tab: Tab) => {
          Flex({
            direction: FlexDirection.Column,
            justifyContent: FlexAlign.Center,
            alignItems: ItemAlign.Center,
            space: { main: LengthMetrics.px(8), cross: LengthMetrics.px(8) },
          }) {
            Image(tab.icon)
              .size({ width: 20, height: 20 })
              .fillColor(this.currentTabIndex === tab.index ? $r('app.color.primary') :
              $r('app.color.tab_text_color_un_active'))
              .draggable(false)

            Text(tab.label)
              .fontColor(this.currentTabIndex === tab.index ? $r('app.color.primary') :
              $r('app.color.tab_text_color_un_active'))
              .fontSize(10)
          }
          .flexGrow(1)
          .onClick(() => {
            if (this.currentTabIndex === tab.index) {
              emitter.emit('refresh', { data: { 'index': tab.index } })
            } else {
              this.currentTabIndex = tab.index
            }
          })
        }, (tab: Tab) => tab.view)
      }
      .padding({
        bottom: px2vp(this.global?.bottomRectHeight || 0)
      })
      .height('78vp')
      .width('100%')
    }
    .height(this.player?.playingTitle ? `127vp` : '78vp')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
  }

  @Builder
  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
        TabContent() {
          HomeTabContext({})
        }

        TabContent() {
          MeTabContent()
        }
      }
      .vertical(false)
      .barWidth('100%')
      .barHeight(0)
      .animationDuration(0)
      .scrollable(false)
      .height('100%')
      .width('100%')
      .overlay(this.buildBar(), { align: Alignment.BottomStart })
    }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM, LayoutSafeAreaEdge.TOP])
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}
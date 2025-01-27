import { LengthMetrics } from '@kit.ArkUI';
import { BreakpointSystem, BreakpointState } from '../../common/breakpointsystem';
import { MusicBar } from '../../components/music_bar';
import { MusicPage } from '../../components/music_page';
import { getGlobal, getPlayer, GlobalContent } from '../../viewmodel/global';
import { Player } from '../../viewmodel/player';
import { HomeTabContext } from './views/home';
import { MeTabContent } from './views/me';

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

  /**
   @Local tabBarProps: BreakpointState<TabBarProps> = BreakpointState.of({
   sm: {
   vertical: false,
   barPosition: BarPosition.End,
   compBarWidth: '100%',
   compBarHeight: '72vp',
   compDirection: FlexDirection.Column
   } as TabBarProps,
   md: {
   vertical: false,
   barPosition: BarPosition.End,
   compBarWidth: '100%',
   compBarHeight: '56vp',
   compDirection: FlexDirection.Row
   } as TabBarProps,
   lg: {
   vertical: true,
   barPosition: BarPosition.Start,
   compBarWidth: '96vp',
   compBarHeight: '60%',
   compDirection: FlexDirection.Column
   } as TabBarProps,
   })

   **/

  aboutToAppear() {
    // BreakpointSystem.getInstance().attach(this.tabBarProps)
    // BreakpointSystem.getInstance().start()
  }

  aboutToDisappear() {
    // BreakpointSystem.getInstance().detach(this.tabBarProps)
    // BreakpointSystem.getInstance().stop()
  }

  @Builder
  tabBuilder(title: string, targetIndex: number, icon: Resource) {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center,
      space: { main: LengthMetrics.px(8), cross: LengthMetrics.px(8) }
    }) {
      Image(icon)
        .size({ width: 20, height: 20 })
        .fillColor(this.currentTabIndex === targetIndex ? $r('app.color.primary') : '#6c6c77')
        .draggable(false)

      Text(title)
        .fontColor(this.currentTabIndex === targetIndex ? $r('app.color.primary') : '#6c6c77')
        .fontSize(12)
    }
    .width('100%')
    .margin({ bottom: px2vp(this.global?.bottomRectHeight || 0) })
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
      if (this.currentTabIndex === 0 && this.player?.playingTitle) {
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
              .fillColor(this.currentTabIndex === tab.index ? $r('app.color.primary') : '#6c6c77')
              .draggable(false)

            Text(tab.label)
              .fontColor(this.currentTabIndex === tab.index ? $r('app.color.primary') : '#6c6c77')
              .fontSize(10)
          }
          .flexGrow(1)
          .onClick(() => {
            this.currentTabIndex = tab.index
          })
        }, (tab: Tab) => tab.view)
      }
      .padding({
        bottom: px2vp(this.global?.bottomRectHeight || 0)
      })
      .height('78vp')
      .width('100%')
    }
    .height(this.currentTabIndex === 0 && this.player?.playingTitle ? `127vp` : '78vp')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
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
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM,LayoutSafeAreaEdge.TOP])
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}
import { LengthMetrics } from '@kit.ArkUI';
import { BreakpointSystem, BreakpointState } from '../../common/breakpointsystem';
import { MusicPage } from '../../components/music_page';
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

@ComponentV2
struct HomePage {
  @Local currentTabIndex: number = 0;
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

  aboutToAppear() {
    BreakpointSystem.getInstance().attach(this.tabBarProps)
    BreakpointSystem.getInstance().start()
  }

  aboutToDisappear() {
    BreakpointSystem.getInstance().detach(this.tabBarProps)
    BreakpointSystem.getInstance().stop()
  }

  @Builder
  tabBuilder(title: string, targetIndex: number, icon: Resource) {
    Flex({
      direction: this.tabBarProps.value?.compDirection,
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center,
      space: { main: LengthMetrics.px(6), cross: LengthMetrics.px(6) }
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
    .height(50)
  }

  @Builder
  buildMusicPage() {
    MusicPage()
      .width('100%')
      .height('100%')
  }

  @Builder
  build() {
    NavDestination() {
      Tabs({ barPosition: this.tabBarProps.value?.barPosition }) {
        TabContent() {
          HomeTabContext()
        }
        .tabBar(this.tabBuilder('发现', 0, $r("app.media.tabs_icon_home")))

        TabContent() {
          MeTabContent()
        }
        .tabBar(this.tabBuilder('我的', 1, $r("app.media.tabs_icon_me")))
      }
      .vertical(this.tabBarProps.value?.vertical)
      .onChange((index) => {
        this.currentTabIndex = index;
      })
      .barWidth(this.tabBarProps.value?.compBarWidth)
      .barHeight(this.tabBarProps.value?.compBarHeight)
      .animationDuration(0)
      .scrollable(false)
      .height('100%')
      .width('100%')

    }
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}
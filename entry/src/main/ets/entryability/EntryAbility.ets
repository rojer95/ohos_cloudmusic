import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { debuglog } from '../utils/log';
import { getGlobal, initPlayer } from '../viewmodel/global';
import dayjs from 'dayjs';
import duration from 'dayjs/plugin/duration';


dayjs.extend(duration)

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    debuglog('Ability', 'onWindowStageCreate')

    const global = getGlobal()!
    initPlayer(this.context)

    windowStage.loadContent('pages/index', async (err) => {
      if (err.code) {
        debuglog('Ability', `Failed to load the content. Cause: ${JSON.stringify(err)}s`)
        return;
      }

      // Main window is created, set main page for this ability
      let windowClass: window.Window = windowStage.getMainWindowSync();
      // 状态栏高度
      const topAvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      global.topRectHeight = topAvoidArea.topRect.height // 获取状态栏区域高度

      // 导航条高度
      const bottomAvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      debuglog('bottomAvoidArea', bottomAvoidArea)
      global.bottomRectHeight = bottomAvoidArea.bottomRect.height

      debuglog('Ability', 'Succeeded in loading the content.')
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
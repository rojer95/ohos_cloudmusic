import { Player } from './player'
import { common } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';


export function getPlayer(): Player {
  return GlobalPlayer.getPlayer()
}


@ObservedV2
export class GlobalContent {
  @Trace topRectHeight: number = 0
  @Trace bottomRectHeight: number = 0
}

export function getGlobal(): GlobalContent | undefined {
  return AppStorageV2.connect(GlobalContent, () => new GlobalContent())
}

export class GlobalPlayer {
  static player: Player;

  static getPlayer() {
    if (!GlobalPlayer.player) {
      GlobalPlayer.player = new Player()
    }
    return GlobalPlayer.player
  }
}


import { Player } from './player'
import { common } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';


export function getPlayer(): Player | undefined {
  return AppStorageV2.connect(Player)
}

export function initPlayer(context: common.UIAbilityContext) {
  AppStorageV2.connect(Player, () => new Player(context))
}


export async function destroyPlayer() {
  AppStorageV2.remove(Player)
}


@ObservedV2
export class GlobalContent {
  @Trace topRectHeight: number = 0
}

export function getGlobal(): GlobalContent | undefined {
  return AppStorageV2.connect(GlobalContent, () => new GlobalContent())
}



import { MusicPage } from '../components/music_page';
import { emitter } from '@kit.BasicServicesKit';
import { generateConfig } from '../api/core/generateConfig';
import { getPlayer } from '../viewmodel/global';
import { PersistenceV2 } from '@kit.ArkUI';
import { LoginInfo } from '../api/core/loginInfo';
import { Player } from '../viewmodel/player';
import { debuglog } from '../utils/log';
import { HomePage } from './Home/Index';
import { PlaylistPage } from './Playlist';

@Entry
@ComponentV2
struct Index {
  @Provider('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Local globalModal: Map<string, boolean> = new Map([
    ['music', false],
    ['login', false]
  ])
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo, () => new LoginInfo())!
  @Local player: Player = getPlayer()!

  async onInit() {
    try {
      const context: Context = getContext(this);
      await generateConfig(this.loginInfo, context.resourceManager)
      if (!this.player.avPlayer) {
        await this.player?.init()
      }
      if (this.loginInfo.isLogin) {
        await this.player.loadLikeList()
      }

      if (this.pathStack.getParamByName('Home').length === 0) {
        this.pathStack.pushPath({ name: 'Home' });
      }
    } catch (e) {
      debuglog('Index',e.message)
      debuglog('Index',e.stack, 2)
    }
  }

  onMusicPageEvent() {
    emitter.on('globalModal', data => {
      this.onGlobalModalChange(data?.data?.page as string, data?.data?.show as boolean)
    })
  }

  offMusicPageEvent() {
    emitter.off('globalModal')
  }

  onGlobalModalChange(page: string, visible: boolean) {
    this.getUIContext()?.animateTo({
      duration: 300
    }, () => {
      this.globalModal.set(page, visible)
    })
  }

  aboutToAppear(): void {
    this.onInit()
    this.onMusicPageEvent()
  }

  aboutToDisappear(): void {
    this.offMusicPageEvent()
  }

  @Builder
  buildMusicPage() {
    MusicPage()
      .transition(
        TransitionEffect.OPACITY
          .combine(
            TransitionEffect.move(TransitionEdge.BOTTOM)
          )
      )
  }

  @Builder
  PagesMap(name: string) {

    if (name === 'Home') {
      HomePage()
    }

    if (name === 'Playlist'){
      PlaylistPage()
    }
  }


  build() {
    Navigation(this.pathStack)
      .hideNavBar(true)
      .hideTitleBar(true)
      .hideBackButton(true)
      .hideToolBar(true)
      .mode(NavigationMode.Stack)
      .navDestination(this.PagesMap)
      .bindContentCover(this.globalModal.get('music'), this.buildMusicPage(), {
        modalTransition: ModalTransition.NONE,
        onDisappear: () => {
          if (this.globalModal.get('music')) {
            this.onGlobalModalChange('music', false)
          }
        }
      })
  }
}
import { MusicPage } from '../components/music_page';
import { emitter } from '@kit.BasicServicesKit';
import { generateConfig } from '../api/core/generateConfig';
import { getPlayer } from '../viewmodel/global';
import { PersistenceV2, promptAction } from '@kit.ArkUI';
import { LoginInfo } from '../viewmodel/loginInfo';
import { Player } from '../viewmodel/player';
import { debuglog } from '../utils/log';
import { loginStatusApi } from '../api/login_status';
import { BreakpointSystem } from '../common/breakpointsystem';

// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});

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
      debuglog('LoginInfo', this.loginInfo, 2)
      await generateConfig(this.loginInfo, context.resourceManager)
      if (!this.player.avPlayer) {
        await this.player?.init(this.loginInfo.userPlayLevel || 'standard')
      }
      if (this.loginInfo.isLogin) {
        await this.player.loadLikeList()
      }

      if (this.pathStack.getParamByName('HomePage').length === 0) {
        this.pathStack.pushPath({ name: 'HomePage' });
      }

      await this.loadLoginStatus()
    } catch (e) {
      debuglog('Index', e.message)
      debuglog('Index', e.stack, 2)
    }
  }

  async loadLoginStatus() {
    this.loginInfo.nickname = undefined
    this.loginInfo.accountId = undefined
    // debuglog('cookie', this.cookie)
    const loginStatus = await loginStatusApi()
    debuglog('loginStatus', loginStatus)
    if (loginStatus?.body?.account) {
      this.loginInfo.accountId = loginStatus?.body?.account.id;
      if (loginStatus.body?.account?.anonimousUser) {
        this.loginInfo.isLogin = false
      } else {
        this.loginInfo.isLogin = true;
        this.loginInfo.nickname = loginStatus?.body?.profile?.nickname
      }

      getPlayer()?.loadLikeList()
      emitter.emit('logined')
    } else {
      promptAction.showToast({
        message: '拉取登录信息失败！'
      })
    }
  }

  onEvent() {

    emitter.on('loadLoginStatus', () => {
      this.loadLoginStatus()
    })

    emitter.on('globalModal', data => {
      this.onGlobalModalChange(data?.data?.page as string, data?.data?.show as boolean)
    })

    emitter.on('userPlayLevelChange', data => {
      this.loginInfo.userPlayLevel = data?.data?.['level'] as string
    })
  }

  offEvent() {
    emitter.off('loadLoginStatus')
    emitter.off('globalModal')
    emitter.off('userPlayLevelChange')
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
    this.onEvent()
  }

  aboutToDisappear(): void {
    BreakpointSystem.getInstance().stop()
    this.offEvent()
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

  build() {
    Navigation(this.pathStack)
      .hideNavBar(true)
      .hideTitleBar(true)
      .hideBackButton(true)
      .hideToolBar(true)
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
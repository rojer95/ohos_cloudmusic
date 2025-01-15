import { PersistenceV2, promptAction } from "@kit.ArkUI"
import { LoginInfo } from "../../../../api/core/loginInfo"
import emitter from '@ohos.events.emitter';


@ComponentV2
export struct MeTabContent {
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();

  build() {
    Column() {

      if (!this.loginInfo.isLogin) {
        Column() {
          Button('立即登录').onClick(() => {
            this.pathStack.pushPath({ name: 'LoginPage' })
          }).margin({ top: 12 })
        }.padding(10)
      } else {
        Column() {
          Text(`欢迎您，${this.loginInfo.nickname}！`)

          Button('退出登录').onClick(() => {
            this.loginInfo.logout()
            emitter.emit('logined')
            promptAction.showToast({
              message: '退出登录成功'
            })
          }).margin({ top: 12 })
        }
      }
    }
  }
}
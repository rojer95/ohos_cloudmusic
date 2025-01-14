import { PersistenceV2, promptAction } from "@kit.ArkUI"
import { LoginInfo } from "../../../../api/core/loginInfo"
import { QrcodeLoginPage } from "../../../../components/qrcode_login_page";
import { TelLoginPage } from "../../../../components/tel_login_page";
import emitter from '@ohos.events.emitter';


@ComponentV2
export struct MeTabContent {
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Local qrcode: string = '';

  build() {
    Column() {

      if (!this.loginInfo.isLogin) {
        Column() {
          Tabs({ barPosition: BarPosition.Start }) {
            TabContent() {
              QrcodeLoginPage()
            }.tabBar('扫码登录')

            // TabContent() {
            //   TelLoginPage()
            // }.tabBar('手机登录')
          }
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
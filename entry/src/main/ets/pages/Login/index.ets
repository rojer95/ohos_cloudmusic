import { QrcodeLoginPage } from "../../components/qrcode_login_page"
import { TelLoginPage } from "../../components/tel_login_page"

@Builder
function pageBuilder() {
  LoginPage()
}

@ComponentV2
struct LoginPage {
  build() {
    NavDestination() {
      Tabs() {
        TabContent() {
          QrcodeLoginPage()
        }.tabBar('扫码登录')

        TabContent() {
          TelLoginPage()
        }.tabBar('手机登录')

      }.height('100%').width('100%')
    }.title('登录')
  }
}
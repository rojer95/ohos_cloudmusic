import { BusinessError, emitter } from "@kit.BasicServicesKit";
import { webview } from "@kit.ArkWeb";
import { debuglog } from "../utils/log";
import { PersistenceV2, promptAction } from "@kit.ArkUI";
import { LoginInfo } from "../viewmodel/loginInfo";

@ComponentV2
export struct TelLoginPage {
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();
  controller: webview.WebviewController = new webview.WebviewController()
  timer?: number

  aboutToAppear(): void {
    webview.WebCookieManager.clearAllCookiesSync();
    this.timer = setInterval(async () => {
      try {
        let cookie = webview.WebCookieManager.fetchCookieSync('https://music.163.com')
        if (cookie) {
          debuglog('cookie', cookie)
          if (cookie.indexOf('__remember_me=true') > 0) {
            clearInterval(this.timer)
            this.timer = undefined
            this.loginInfo.cookie = cookie;
            await this.loginInfo.loadLoginStatus()
            promptAction.showToast({
              message: '登录成功'
            })
            this.pathStack.pop()
            return
          }
        }

      } catch (error) {
        console.error('获取Cookie失败', error.message)

      }
    }, 1000)
  }

  aboutToDisappear(): void {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = undefined
    }
  }

  build() {
    Column() {
      Web({
        src: '',
        controller: this.controller
      })
        .width('100%')
        .height('100%')
        .onControllerAttached(() => {
          console.log("onControllerAttached")
          try {
            this.controller.setCustomUserAgent('Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36'
            )
            this.controller.loadUrl("https://music.163.com/#/login")
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code}, Message: ${(error as BusinessError).message}`)
          }
        })

    }
    .width('100%')
    .height('100%')
  }
}
import { loginQrKeyApi } from "../api/login_qr_key"
import { qrcodegen } from '@ohos/qr-code-generator'
import { loginQrCheckApi } from "../api/login_qr_check";
import { debuglog } from "../utils/log";
import { PersistenceV2, promptAction } from "@kit.ArkUI";
import { LoginInfo } from "../api/core/loginInfo";
import { loginStatusApi } from "../api/login_status";
import { generateConfig } from "../api/core/generateConfig";
import emitter from '@ohos.events.emitter';

@ComponentV2
export struct QrcodeLoginPage {
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Local message: string = '';
  @Local qrkey: string | undefined = ''
  @Local showQrcode: boolean = false
  tempCookies: string[] = []
  context: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))

  aboutToAppear(): void {
  }

  login = async () => {
    const status = await loginStatusApi();
    debuglog('status', status)

    if (status.body?.account?.anonimousUser) {
      this.showQrcode = true
      const res = await loginQrKeyApi()
      if (res.body?.unikey) {
        this.qrkey = res?.body?.unikey
        const qrcode: qrcodegen.QrCode =
          qrcodegen.QrCode.encodeText(`https://music.163.com/login?codekey=${res.body?.unikey}`,
            qrcodegen.QrCode.Ecc.MEDIUM)
        qrcode.drawCanvas(8, 1, this.context)
        this.tempCookies = res.cookie

        setTimeout(() => {
          this.check()
        }, 1000)
      }
    } else {
      this.loginInfo.setLoginState(true, status?.body?.profile?.nickname || '', status?.body?.profile?.avatarUrl || '')
    }
  }
  check = async () => {
    if (!this.qrkey) {
      return
    }
    const res = await loginQrCheckApi(this.qrkey, this.tempCookies.join(';'))

    debuglog('check code', `${res.body?.code}`)
    debuglog('check message', res.body?.message)
    this.tempCookies = res.cookie
    this.message = res?.body?.message || ''


    if (res.body?.code === 803) {
      this.loginInfo.cookie = res.cookie.join(';')
      this.tempCookies = []
      await generateConfig(this.loginInfo, getContext(this).resourceManager)
      promptAction.showToast({
        message: '登录成功'
      })
      emitter.emit('logined')
      return
    }

    setTimeout(() => {
      this.check()
    }, 1000)

  }

  build() {
    Column() {
      if (this.showQrcode) {
        Canvas(this.context).width(300).height(300)
        Column() {
          Text(this.message)
        }
      } else {
        Button('开始扫码登录').onClick(() => {
          this.login();
        })
      }
    }
  }
}
import { debuglog } from "../utils/log";
import { PersistenceV2, promptAction } from "@kit.ArkUI";
import { LoginInfo } from "../api/core/loginInfo";
import { loginStatusApi } from "../api/login_status";
import { captchaSentApi } from "../api/captcha_sent";
import { loginCellphoneApi } from "../api/login_cellphone";
import { generateConfig } from "../api/core/generateConfig";
import emitter from '@ohos.events.emitter';

@ComponentV2
export struct TelLoginPage {
  @Local loginInfo: LoginInfo = PersistenceV2.connect(LoginInfo)!
  @Local tel: string = '';
  @Local code: string = '';
  @Local isSend: boolean = false;

  aboutToAppear(): void {
  }

  login = async () => {
    const status = await loginStatusApi();
    debuglog('status', status)

    if (status.body?.account?.anonimousUser) {

    } else {
      this.loginInfo.setLoginState(true, status?.body?.profile?.nickname || '', status?.body?.profile?.avatarUrl || '')
    }
  }

  build() {
    Column() {


      TextInput({ placeholder: '请输入手机', text: $$this.tel }).margin({ bottom: 12 })

      if (this.isSend) {
        TextInput({ placeholder: '请输入验证码', text: $$this.code }).margin({ bottom: 12 })
        Button('登录').width('100%').onClick(async () => {
          if (this.tel.length !== 11 || this.code.length !== 4) {
            promptAction.showToast({
              message: '请输入正确的手机号或验证码'
            })
            return
          }
          const res = await loginCellphoneApi(this.tel, this.code)
          if (res.cookie) {
            this.loginInfo.cookie = res.cookie.join(';')
            await generateConfig(this.loginInfo, getContext(this).resourceManager)
            promptAction.showToast({
              message: '登录成功'
            })
            emitter.emit('logined')
            return
          }
          debuglog('res', res)
        })
      } else {
        Button('发送验证码').width('100%').onClick(async () => {
          if (this.tel.length !== 11) {
            promptAction.showToast({
              message: '请输入正确的手机号'
            })
            return
          }
          await captchaSentApi(this.tel)
          this.code = '';
          this.isSend = true
          promptAction.showToast({
            message: '验证码发送成功'
          })
        })
      }
    }
  }
}
import { cookieToJson } from './';
import { registerAnonimous } from '../register_anonimous';
import { LoginInfo } from './loginInfo';
import { debuglog } from '../../utils/log';
import { resourceManager } from '@kit.LocalizationKit';
import { loginStatusApi } from '../login_status';


export async function generateConfig(loginInfo: LoginInfo, resourceManager: resourceManager.ResourceManager) {

  if (!loginInfo.anonymous_token) {
    const res = await registerAnonimous(resourceManager)
    const cookie = res?.body?.cookie
    if (cookie) {
      const cookieObj = cookieToJson(cookie)
      loginInfo.anonymous_token = cookieObj['MUSIC_A']
    }
  }

  const loginStatus = await loginStatusApi()

  debuglog('loginStatus', loginStatus)

  if (loginStatus.body?.account?.anonimousUser) {
    loginInfo.setLoginState(false)
  } else {
    loginInfo.setLoginState(true, loginStatus?.body?.profile?.nickname || '', loginStatus?.body?.profile?.avatarUrl || '')
  }
}
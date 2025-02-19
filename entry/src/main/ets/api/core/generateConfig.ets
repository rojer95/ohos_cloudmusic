import { cookieToJson } from './';
import { registerAnonimous } from '../register_anonimous';
import { LoginInfo } from '../../viewmodel/loginInfo';
import { resourceManager } from '@kit.LocalizationKit';


export async function generateConfig(loginInfo: LoginInfo, resourceManager: resourceManager.ResourceManager) {
  if (!loginInfo.anonymous_token) {
    const res = await registerAnonimous(loginInfo, resourceManager)
    const cookie = res?.body?.cookie
    if (cookie) {
      const cookieObj = cookieToJson(cookie)
      loginInfo.anonymous_token = cookieObj['MUSIC_A']
    }
  }
}
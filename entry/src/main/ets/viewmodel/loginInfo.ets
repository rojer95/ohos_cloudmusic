import { getPlayer } from "./global"
import emitter from '@ohos.events.emitter';
import { loginStatusApi } from "../api/login_status";
import { debuglog } from "../utils/log";
import { PersistenceV2, promptAction } from "@kit.ArkUI";

export interface UserAccount {
  id?: number
  anonimousUser?: boolean;
}

export interface UserProfile {
  // 用户id
  userId?: number;

  // 昵称
  nickname?: string;

  // 头像
  avatarUrl?: string
}

@ObservedV2
export class LoginInfo {
  @Trace anonymous_token: string = ''
  @Trace deviceId: string = ''
  @Trace cookie: string = ''
  @Trace isLogin: boolean = false
  @Trace profile?: UserProfile
  @Trace account?: UserAccount

  async loadLoginStatus() {
    this.profile = undefined
    this.account = undefined
    // debuglog('cookie', this.cookie)
    const loginStatus = await loginStatusApi()
    debuglog('loginStatus', loginStatus)
    if (loginStatus?.body?.account) {
      this.account = loginStatus?.body?.account;
      if (loginStatus.body?.account?.anonimousUser) {
        this.isLogin = false
      } else {
        this.isLogin = true;
        this.profile = loginStatus?.body?.profile
      }

      getPlayer()?.loadLikeList()
      emitter.emit('logined')
    } else {
      promptAction.showToast({
        message: '拉取登录信息失败！'
      })
    }

    PersistenceV2.save(LoginInfo)
  }
}
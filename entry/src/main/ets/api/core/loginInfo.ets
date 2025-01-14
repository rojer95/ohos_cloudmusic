import { getPlayer } from "../../viewmodel/global"

@ObservedV2
export class LoginInfo {
  @Trace anonymous_token: string = ''
  @Trace deviceId: string = ''
  @Trace cookie: string = ''
  @Trace isLogin: boolean = false
  @Trace nickname: string = ''
  @Trace avatarUrl: string = ''

  setLoginState(is: boolean, nickname?: string, avatarUrl?: string) {
    if (is) {
      this.isLogin = true
      if (nickname) {
        this.nickname = nickname
      }
      if (avatarUrl) {
        this.avatarUrl = avatarUrl
      }
    } else {
      this.isLogin = false
      this.nickname = '';
      this.avatarUrl = ''
    }
    getPlayer()?.loadLikeList()
  }

  logout() {
    this.cookie = '';
    this.setLoginState(false)
  }
}
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
  @Trace nickname?: string;
  @Trace accountId?: number;
  @Trace userPlayLevel?: string = 'standard'
}
import { createOption } from "./core/createOption";
import { CommonResponseBody, InputDataType } from "./core/interface";
import { createRequest } from "./core/request";

interface UserDetailUserProfile {
  // 昵称
  nickname?: string
  // 头像
  avatarUrl?: string
  // 背景图
  backgroundUrl?: string
  // 粉丝数
  followeds?: number;

  // 关注数
  follows?: number
  // 签名
  signature?: string

}

export interface UserDetailResponseBody extends CommonResponseBody {
  createDays?: number
  level?: number
  listenSongs?: number;
  profile: UserDetailUserProfile
}

export const userDetailApi = async (uid: string | number) => {
  const data: InputDataType = {}
  const res = await createRequest<UserDetailResponseBody>(
    `/api/v1/user/detail/${uid}`,
    data,
    createOption({}, 'weapi'),
  )

  return res.body;
}

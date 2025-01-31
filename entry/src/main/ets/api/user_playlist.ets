import { createOption } from "./core/createOption";
import { CommonResponseBody, InputDataType } from "./core/interface";
import { createRequest } from "./core/request";

interface PlaylistItemCreator {
  userId?: number;
  nickname?: string
}

export  interface PlaylistItem {
  id?: number;
  coverImgUrl?: string;
  name?: string;
  trackCount?: number;
  playCount?: number;
  creator?: PlaylistItemCreator
}

export interface ResponseBody extends CommonResponseBody {
  more?: boolean
  playlist?: Array<PlaylistItem>
}

export const userPlaylistApi = async (uid: string | number, offset = 0) => {
  const data: InputDataType = {
    'uid': uid,
    'limit': 30,
    'offset': offset,
    'includeVideo': false
  }

  const res = await createRequest<ResponseBody>(
    `/api/user/playlist`,
    data,
    createOption({}, 'weapi'),
  )

  return res.body;
}

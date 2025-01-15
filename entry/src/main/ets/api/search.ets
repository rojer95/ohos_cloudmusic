import { SongDetail } from '../model/song_detail';
import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';


interface Result {
  songs: SongDetail[];
  hasMore: boolean;
  songCount: number;
}

interface ResponseBody extends CommonResponseBody {
  result: Result
}

export const apiSearch = async (keywords: string, offset = 0, limit = 30, type = 1) => {
  const response = await apiSearchReq(keywords, offset, limit, type);
  return response.body?.result
}

export const apiSearchReq = async (keywords: string, offset = 0, limit = 30, type = 1) => {
  let data: InputDataType = {
    's': keywords,
    'type': type, // 1: 单曲, 10: 专辑, 100: 歌手, 1000: 歌单, 1002: 用户, 1004: MV, 1006: 歌词, 1009: 电台, 1014: 视频
    'limit': limit,
    'offset': offset,
  }
  return await createRequest<ResponseBody>(`/api/search/get`,
    data, createOption(undefined))
}
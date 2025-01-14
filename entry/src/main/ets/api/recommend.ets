import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

import { RecommendSong } from '../model/recommend_song';

interface ResponseBody extends CommonResponseBody {
  data: RecommendSong
}


export const apiDailyRecommendSongs = async () => {
  const response = await request()
  return  response.body?.data as RecommendSong
}


const request = async () => {
  const data: InputDataType = {}
  return await createRequest<ResponseBody>(`/api/v3/discovery/recommend/songs`, data, createOption(undefined, 'weapi'))
}
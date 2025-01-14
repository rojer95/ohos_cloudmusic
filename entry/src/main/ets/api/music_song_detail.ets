import { SongDetail } from '../model/song_detail';
import { debuglog } from '../utils/log';
import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';




interface ResponseBody extends CommonResponseBody {
  songs: object[];
}

export const apiMusicSongDetail = async (ids: string[]): Promise<SongDetail[]> => {
  // const response: AxiosResponse<SongsResult> = await request.get(`/song/detail`, { params: { ids } })
  const responses = await request(ids)
  debuglog('responses',responses)
  return responses.body?.songs.map(i => i as SongDetail) || []
}


const request = async (ids: string[]) => {
  const data: InputDataType = {
    'c': '[' + ids.map((id) => '{"id":' + id + '}').join(',') + ']',
  }
  return await createRequest<ResponseBody>(`/api/v3/song/detail`, data, createOption(undefined, 'weapi'))
}
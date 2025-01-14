import { SongDetail, SongDetailWithPrivilege, SongPrivilege } from '../model/song_detail';
import { debuglog } from '../utils/log';
import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';


interface ResponseBody extends CommonResponseBody {
  songs: object[];
  privileges: object[];
}

export const apiMusicSongDetail = async (ids: string[]): Promise<SongDetailWithPrivilege[]> => {
  // const response: AxiosResponse<SongsResult> = await request.get(`/song/detail`, { params: { ids } })
  const responses = await request(ids)
  return responses.body?.songs.map<SongDetailWithPrivilege>(i => {
    const detail = i as SongDetail;
    const privilege = responses.body?.privileges?.find((p) => (p as SongPrivilege)?.id === detail.id) as SongPrivilege;
    return {
      detail,
      privilege
    } as SongDetailWithPrivilege
  }) || []
}


const request = async (ids: string[]) => {
  const data: InputDataType = {
    'c': '[' + ids.map((id) => '{"id":' + id + '}').join(',') + ']',
  }
  return await createRequest<ResponseBody>(`/api/v3/song/detail`, data, createOption(undefined, 'weapi'))
}
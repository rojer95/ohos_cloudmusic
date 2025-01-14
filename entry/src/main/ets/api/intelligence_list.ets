import { SongDetail } from '../model/song_detail';
import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

interface GeneratedTypeLiteralInterface_2 {
  songInfo: object;
}


interface ResponseBody extends CommonResponseBody {
  data: GeneratedTypeLiteralInterface_2[];
}


export const apiIntelligenceList = async (id: string, pid: string, sid: string) => {
  const response = await apiIntelligenceListReq(id, pid, sid)
  return response.body?.data.map(i => i.songInfo as SongDetail) || []
}


export const apiIntelligenceListReq = async (id: string, pid: string, sid?: string, count = 1) => {
  let data: InputDataType = {
    'songId': id,
    'type': 'fromPlayOne',
    'playlistId': pid,
    'startMusicId': sid || id,
    'count': count
  }

  return await createRequest<ResponseBody>(`/api/playmode/intelligence/list`,
    data, createOption(undefined, 'weapi'))
}
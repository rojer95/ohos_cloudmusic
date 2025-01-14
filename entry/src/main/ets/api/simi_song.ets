import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

import { PersonalFm } from '../model/personal_fm';



interface ResponseBody extends CommonResponseBody {
  songs: object[];
}

export const apiSemiSong = async (id: string) => {
  const response = await request(id)
  return response.body?.songs.map(i =>i as PersonalFm) || []
}


const request = async (id: string) => {
  const data: InputDataType = {
    'songid': id,
    'limit': 50,
    'offset': 0,
  }
  return await createRequest<ResponseBody>(`/api/discovery/simiSong`, data, createOption(undefined, 'weapi'))
}
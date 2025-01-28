import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

import { Artist } from '../model/artist';

interface GeneratedTypeLiteralInterface_1 {
}

interface ResponseBody extends CommonResponseBody {
  artists: object[];
}

export const apiSemiArtist = async (id: string) => {
  const response = await request(id)
  return response.body?.artists.map(i => i as Artist) || []
}


const request = async (id: string) => {
  const data: InputDataType = {
    'artistid': id
  }
  return await createRequest<ResponseBody>(`/api/discovery/simiArtist`, data, createOption(undefined, 'weapi'))
}
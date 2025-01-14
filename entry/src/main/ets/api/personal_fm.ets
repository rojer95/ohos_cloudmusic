import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

import { PersonalFm } from '../model/personal_fm';



interface ResponseBody extends CommonResponseBody {
  data: object[];
}


export const apiPersonalFm = async () => {
  const response = await request()
  return response.body?.data.map(i => i as PersonalFm) || []
}


const request = async () => {
  const data: InputDataType = {}
  return await createRequest<ResponseBody>(`/api/v1/radio/get`, data, createOption(undefined, 'weapi'))
}
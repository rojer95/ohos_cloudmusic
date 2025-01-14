import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';



interface ResponseBody extends CommonResponseBody {
  ids: number[]
}


export const apiLikeList = async (): Promise<number[]> => {
  const response = await apiLikeListReq()
  return response.body?.ids || []
}

export const apiLikeListReq = async (uid?: string) => {
  const data: InputDataType = {}

  if (uid) {
    data['uid'] = uid
  }

  return await createRequest<ResponseBody>(`/api/song/like/get`, data, createOption())
}
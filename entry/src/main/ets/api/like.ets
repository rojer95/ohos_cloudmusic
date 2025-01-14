import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';


export const apiLike = async (id: string | number, like: boolean): Promise<void> => {
  const data: InputDataType = {
    'alg': 'itembased',
    'trackId': id,
    'like': like,
    'time': '3',
  }
  await createRequest<CommonResponseBody>(`/api/radio/like`, data, createOption(undefined, 'weapi'))
}


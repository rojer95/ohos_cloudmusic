import { Lrc } from '../model/lyric';
import { debuglog } from '../utils/log';
import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

interface ResponseBody extends CommonResponseBody {
  lrc?: Lrc
}

export const apiGetLyric = async (id: string) => {
  const responses = await request(id)
  debuglog('lyric', responses)
  return responses.body?.lrc
}

const request = async (id: string) => {
  const data: InputDataType = {
    'id': id,
    'tv': -1,
    'lv': -1,
    'rv': -1,
    'kv': -1,
    '_nmclfl': 1,
  }
  return createRequest<ResponseBody>(`/api/song/lyric`, data, createOption())
}
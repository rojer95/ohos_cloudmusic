import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

interface SongUrl {
  url: string;
  time?: number
}


interface ResponseBody extends CommonResponseBody {
  data: Array<SongUrl>
}

export const apiMusicSongUrl = async (id: string, level: string): Promise<SongUrl | undefined> => {
  // const responses: AxiosResponse<SongsResult> = await request.get(`/song/url/v1`, { params: { id, level } })
  const responses = await request(id, level)
  return responses.body?.data?.[0]
}

const request = async (id: string, level: string) => {
  const data: InputDataType = {
    'ids': '[' + id + ']',
    'level': level,
    'encodeType': 'flac',
  }

  if (data.level == 'sky') {
    data.immerseType = 'c51'
  }

  return await createRequest<ResponseBody>(`/api/song/enhance/player/url/v1`, data, createOption())
}
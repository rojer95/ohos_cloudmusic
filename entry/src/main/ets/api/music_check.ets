import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

interface CheckResult {
  success: boolean;
  message?: string
}

export const apiCheckMusic = async (id: string) => {
  return await request(id)
}

interface GeneratedTypeLiteralInterface_1 {
  code: number;
}

interface ResponseBody extends CommonResponseBody {
  data: Array<GeneratedTypeLiteralInterface_1>
}

const request = async (id: string, br = 999000) => {
  const data: InputDataType = {
    'ids': '[' + parseInt(id) + ']',
    'br': br
  }
  const response = await createRequest<ResponseBody>(`/api/song/enhance/player/url`,
    data,
    createOption(undefined, 'weapi'),)

  let playable = false
  if (response.body?.code == 200) {
    if (response.body.data[0].code == 200) {
      playable = true
    }
  }
  if (playable) {
    return { success: true, message: 'ok' } as CheckResult
  } else {
    return { success: false, message: '亲爱的,暂无版权' } as CheckResult
  }

}
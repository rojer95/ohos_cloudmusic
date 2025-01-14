import { debuglog } from "../utils/log"
import { createOption } from "./core/createOption"
import { CommonResponseBody, InputDataType } from "./core/interface"
import { createRequest } from "./core/request"

interface GeneratedTypeLiteralInterface_1 extends CommonResponseBody {
  data?: boolean;
  message?: string;
}

interface GeneratedObjectLiteralInterface_1 {
  success: boolean;
  msg: string;
}

export const captchaSentApi = async (phone: string, ctcode?: string): Promise<GeneratedObjectLiteralInterface_1> => {


  const data: InputDataType = {
    'ctcode': ctcode || '86',
    'cellphone': phone,
  }

  const response = await createRequest<GeneratedTypeLiteralInterface_1>(`/api/sms/captcha/sent`, data,
    createOption({
      'realIP': '112.49.79.192'
    }, 'weapi'))

  debuglog('captchaSentApi', response)

  if (response.body?.code === 200) {
    return ({ success: true, msg: '发送验证码成功' } as GeneratedObjectLiteralInterface_1)
  }
  return { success: false, msg: response.body?.message || '发送验证码失败' }
}
import { createOption } from "./core/createOption"
import { CommonResponseBody, InputDataType } from "./core/interface"
import { createRequest } from "./core/request"

interface ResponseBody extends CommonResponseBody {
}


export const loginQrCheckApi = async (key: string, cookie: string) => {
  const data: InputDataType = {
    'type': 3,
    'key': key
  }
  return await createRequest<ResponseBody>(
    `/api/login/qrcode/client/login`,
    data,
    createOption({ 'cookie': cookie }),
  )
}
import { createOption } from "./core/createOption"
import { CommonResponseBody, InputDataType } from "./core/interface"
import { createRequest } from "./core/request"

interface ResponseBody extends CommonResponseBody {
  unikey: string
}


export const loginQrKeyApi = async () => {
  const data: InputDataType = {
    'type': 3
  }
 return  await createRequest<ResponseBody>(
    `/api/login/qrcode/unikey`,
    data,
    createOption(),
  )
}
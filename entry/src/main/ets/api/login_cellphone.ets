import { debuglog } from "../utils/log"
import { createOption } from "./core/createOption"
import { CommonResponseBody, InputDataType } from "./core/interface"
import { createRequest } from "./core/request"

interface ResponseBody extends CommonResponseBody {}


export const loginCellphoneApi = async (phone: string, captcha: string, countrycode?: string) => {
  const data: InputDataType = {
    'type': '1',
    'https': 'true',
    'phone': phone,
    'countrycode': countrycode || '86',
    'captcha': captcha,
    'rememberLogin': 'true',
  }
  let result = await createRequest<ResponseBody>(
    `/api/w/login/cellphone`,
    data,
    createOption({
      'realIP': '112.49.79.192'
    }),
  )

  debuglog('login_cellphone', result)

  // if (result.body.code === 200) {
  //   result = {
  //     status: 200,
  //     body: {
  //       ...JSON.parse(
  //         JSON.stringify(result.body).replace(
  //           /avatarImgId_str/g,
  //           'avatarImgIdStr',
  //         ),
  //       ),
  //       cookie: result.cookie.join(';'),
  //     },
  //     cookie: result.cookie,
  //   }

  return result
}
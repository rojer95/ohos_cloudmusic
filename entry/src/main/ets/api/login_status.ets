import { createOption } from "./core/createOption"
import { CommonResponseBody, InputDataType } from "./core/interface"
import { UserAccount, UserProfile } from "../viewmodel/loginInfo";
import { createRequest } from "./core/request"



interface ResponseBody extends CommonResponseBody {
  account?: UserAccount;
  profile?: UserProfile
}


export const loginStatusApi = async () => {
  const data: InputDataType = {}
  return await createRequest<ResponseBody>(
    `/api/w/nuser/account/get`,
    data,
    createOption({}, 'weapi'),
  )
}
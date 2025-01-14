import { createOption } from "./core/createOption"
import { CommonResponseBody, InputDataType } from "./core/interface"
import { createRequest } from "./core/request"

interface GeneratedTypeLiteralInterface_1 {
  anonimousUser?: boolean;
}

interface GeneratedTypeLiteralInterface_2 {
  avatarUrl: string;
  nickname: string;
}

interface ResponseBody extends CommonResponseBody {
  account?: GeneratedTypeLiteralInterface_1;
  profile?: GeneratedTypeLiteralInterface_2
}


export const loginStatusApi = async () => {
  const data: InputDataType = {}
  return await createRequest<ResponseBody>(
    `/api/w/nuser/account/get`,
    data,
    createOption({}, 'weapi'),
  )
}
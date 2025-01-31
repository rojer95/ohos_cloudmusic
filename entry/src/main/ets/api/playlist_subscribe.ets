import { createOption } from "./core/createOption";
import { InputDataType } from "./core/interface";
import { createRequest } from "./core/request";
import { ResponseBody } from "./user_playlist";

export const playlistSubscribe = async (id: string | number, is: boolean) => {
  const data: InputDataType = {
    'id': id,
  }

  await createRequest<ResponseBody>(
    `/api/playlist/${is ? 'subscribe' : 'unsubscribe'}`,
    data,
    createOption({}, 'weapi'),
  )
}

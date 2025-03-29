import axios, { AxiosResponse } from "@ohos/axios"

interface InvateType { url?: string }

export const getInvateUrl = async () => {
  try {
    const res: AxiosResponse<InvateType> =
      await axios.get<InvateType>('http://cdn.eqistu.cn/yunyinyue/invate.json?t=' + (new Date().valueOf()))
    return res?.data?.url
  } catch (e) {
    return ''
  }
}
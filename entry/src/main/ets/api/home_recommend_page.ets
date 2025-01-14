import { InputDataType } from './core/interface';
import { HomeBlockResponse } from '../model/home_block';
import { debuglog } from '../utils/log';
import { createOption } from './core/createOption';
import { CommonResponseBody } from './core/interface';
import { createRequest } from './core/request';

export interface ApiHomeRecommendPageParams {
  cursor?: number;
  clientCacheBlockCode?: string
  loadedPositionCodes?: string
  requestBlockOrder?: string[]
  blockCodeOrderList?: string
}

interface  ResponseBody extends CommonResponseBody{
  data: HomeBlockResponse
}

export const apiHomeRecommendPage = async (params: ApiHomeRecommendPageParams) => {
  const response = await apiHomeRecommendPageApi(params)
  // debuglog('apiHomeRecommendPage', response.body?.data)
  return response.body?.data as HomeBlockResponse
}



interface GeneratedObjectLiteralInterface_2 {
  fmTitle: string;
  fmLongTitle: string;
}


interface GeneratedObjectLiteralInterface_3 {
  fmNameTest0422: string;
  similarFmNameTest0422: string;
}

export const apiHomeRecommendPageApi = async (params: ApiHomeRecommendPageParams) => {
  let data: InputDataType = {
    'extJson': JSON.stringify({
      fmName: ({ fmTitle: '漫游', fmLongTitle: '私人漫游' } as GeneratedObjectLiteralInterface_2),
      netstate: 1,
      currentExploreHomeType: 'main',
      firstRequestPerLaunch: false,
      clientLibraAbTest: ({ fmNameTest0422: 'c', similarFmNameTest0422: 'c' } as GeneratedObjectLiteralInterface_3),
      clientMobileSize: JSON.stringify({ width: 414, length: 736 }),
      refreshAction: 'other',
      requestLongVideoBanner: false,
    }),
    'pageCode': 'HOME_RECOMMEND_PAGE',
    'isFirstScreen': true,
    'reqTimeStamp': new Date().valueOf() + '',
    'refresh': 1,
  }

  if (params.cursor) {
    data.cursor = Number(params.cursor)
    data.isFirstScreen = false
  }

  // 已缓存的block
  if (params.clientCacheBlockCode) {
    data.clientCacheBlockCode = params.clientCacheBlockCode
  }

  // 所有已请求到的 requestBlockOrder
  if (params.loadedPositionCodes) {
    data.loadedPositionCodes = params.loadedPositionCodes
  }

  // 上个请求的返回的 blockCodeOrderList
  if (params.blockCodeOrderList) {
    data.blockCodeOrderList = params.blockCodeOrderList
  }

  debuglog('resource data', data)
  return await createRequest<ResponseBody>(`/api/link/page/rcmd/resource/show`,
    data , createOption(params as Record<string, string>, 'weapi'))
}
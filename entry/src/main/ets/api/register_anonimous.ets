import resourceManager from "@ohos.resourceManager";
import { util } from "@kit.ArkTS";
import { CryptoJS } from '@ohos/crypto-js';
import { createOption } from "./core/createOption";
import { CommonResponseBody } from "./core/interface";
import { createRequest } from "./core/request";
import { PersistenceV2 } from "@kit.ArkUI";
import { LoginInfo } from "../viewmodel/loginInfo";

const ID_XOR_KEY_1 = '3go8&$8*3*3h0k(2)2'

function getRandomFromList(list: string[]) {
  return list[Math.floor(Math.random() * list.length)]
}

function cloudmusic_dll_encode_id(some_id: string) {
  let xoredString = ''
  for (let i = 0; i < some_id.length; i++) {
    const charCode =
      some_id.charCodeAt(i) ^ ID_XOR_KEY_1.charCodeAt(i % ID_XOR_KEY_1.length)
    xoredString += String.fromCharCode(charCode)
  }
  const wordArray = CryptoJS.enc.Utf8.parse(xoredString)
  const digest = CryptoJS.MD5(wordArray)
  return CryptoJS.enc.Base64.stringify(digest)
}


export const getDeviceIdList = (resourceManager: resourceManager.ResourceManager) => {
  const deviceId: Uint8Array = resourceManager.getRawFileContentSync('deviceid.txt');
  if (!deviceId) {
    return []
  }
  let textDecoder = util.TextDecoder.create('utf-8', {
    ignoreBOM: true
  });
  let deviceIdText: string = textDecoder.decodeWithStream(deviceId, {
    stream: false
  });

  return deviceIdText.split('\n') || []
}

interface ResponseBody extends CommonResponseBody {
  cookie: string
}

export const registerAnonimous = async (loginInfo: LoginInfo, resourceManager: resourceManager.ResourceManager) => {
  if (!loginInfo.deviceId) {
    const deviceId = await getRandomFromList(getDeviceIdList(resourceManager))
    loginInfo.deviceId = deviceId
  }

  const encodedId = CryptoJS.enc.Base64.stringify(
    CryptoJS.enc.Utf8.parse(
      `${loginInfo!.deviceId} ${cloudmusic_dll_encode_id(loginInfo!.deviceId)}`,
    ),
  )

  const data: Record<string, string> = {
    'username': encodedId,
  }

  // debuglog('data', data)

  let result = await createRequest<ResponseBody>(
    `/api/register/anonimous`,
    data,
    createOption({ 'cookie': '{}', 'deviceId': loginInfo.deviceId }, 'weapi'),
  )

  if (result?.body?.code === 200) {
    result.status = 200;
    result.body.cookie = result.cookie.join(';')
    loginInfo.cookie = result.body.cookie
  }

  return result
}


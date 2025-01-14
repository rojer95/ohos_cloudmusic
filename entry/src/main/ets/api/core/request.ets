import * as encrypt from './crypto'
import CryptoJS from '@ohos/crypto-js';
import axios, { AxiosRequestConfig, AxiosResponse } from '@ohos/axios';
import { cookieToJson, cookieObjToString, toBoolean } from './index'
import { CommonResponse, CommonResponseBody, InputDataType, RequestOptions } from './interface';
import { buffer, url } from '@kit.ArkTS';
import { LoginInfo } from './loginInfo';
import { PersistenceV2, promptAction } from '@kit.ArkUI';
import { debuglog } from '../../utils/log';

const URLSearchParams = url.URLSearchParams

type StringMap<T = string> = Record<string, Record<string, T>>;

const config: StringMap<string | boolean> = {
  "resourceTypeMap": {
    "0": "R_SO_4_",
    "1": "R_MV_5_",
    "2": "A_PL_0_",
    "3": "R_AL_3_",
    "4": "A_DJ_1_",
    "5": "R_VI_62_",
    "6": "A_EV_2_",
    "7": "A_DR_14_"
  },
  "APP_CONF": {
    "apiDomain": "https://interface.music.163.com",
    "domain": "https://music.163.com",
    "encrypt": true,
    "encryptResponse": false
  }
}
// request.debug = true // 开启可看到更详细信息

const WNMCID = (() => {
  const characters = 'abcdefghijklmnopqrstuvwxyz';
  let randomString = '';
  for (let i = 0; i < 6; i++) {
    randomString += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return `${randomString}.${Date.now().toString()}.01.0`;
})()


const osMap: StringMap = {
  'pc': {
    'os': 'pc',
    'appver': '3.0.18.203152',
    'osver': 'Microsoft-Windows-10-Professional-build-22631-64bit',
    'channel': 'netease',
  },
  'linux': {
    'os': 'linux',
    'appver': '1.2.1.0428',
    'osver': 'Deepin 20.9',
    'channel': 'netease',
  },
  'android': {
    'os': 'android',
    'appver': '8.20.20.231215173437',
    'osver': '14',
    'channel': 'xiaomi',
  },
  'iphone': {
    'os': 'iPhone OS',
    'appver': '9.0.90',
    'osver': '16.2',
    'channel': 'distribution',
  },
}

const chooseUserAgent = (crypto: string, uaType = 'pc'): string => {
  const userAgentMap: StringMap = {
    'weapi': {
      'pc': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0',
    },
    'linuxapi': {
      'linux':
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36',
    },
    'api': {
      'pc': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Safari/537.36 Chrome/91.0.4472.164 NeteaseMusicDesktop/3.0.18.203152',
      'android':
      'NeteaseMusic/9.1.65.240927161425(9001065);Dalvik/2.1.0 (Linux; U; Android 14; 23013RK75C Build/UKQ1.230804.001)',
      'iphone': 'NeteaseMusic 9.0.90/5038 (iPhone; iOS 16.2; zh_CN)',
    },
  }
  return userAgentMap[crypto][uaType] || ''
}


export async function createRequest<T extends CommonResponseBody>
(uri: string, data: InputDataType,
  options: RequestOptions): Promise<CommonResponse<T>> {
  const loginInfo = PersistenceV2.connect(LoginInfo)
  let headers = options.headers || {}
  let ip: string = options.realIP || options.ip || ''
  // console.log(ip)
  if (ip) {
    headers['X-Real-IP'] = ip
    headers['X-Forwarded-For'] = ip
  }
  // headers['X-Real-IP'] = '118.88.88.88'

  let cookie: string | Record<string, string> = options.cookie || loginInfo?.cookie || {}
  if (typeof cookie === 'string') {
    cookie = cookieToJson(cookie)
  }

  if (typeof cookie === 'object') {
    let _ntes_nuid = CryptoJS.lib.WordArray.random(32).toString()
    let os = osMap[cookie.os as string] || osMap['iphone']


    cookie['__remember_me'] = 'true';
    cookie['ntes_kaola_ad'] = '1';
    cookie['_ntes_nuid'] = cookie._ntes_nuid || _ntes_nuid
    cookie['_ntes_nnid'] = cookie._ntes_nnid || `${_ntes_nuid},${Date.now().toString()}`
    cookie['WNMCID'] = cookie.WNMCID || WNMCID
    cookie['WEVNSM'] = cookie.WEVNSM || '1.0.0'
    cookie['osver'] = (cookie.osver || os.osver)
    cookie['deviceId'] = cookie.deviceId || loginInfo?.deviceId || ''
    cookie['os'] = (cookie.os || os.os)
    cookie['channel'] = (cookie.channel || os.channel)
    cookie['appver'] = (cookie.appver || os.appver)


    if (uri.indexOf('login') === -1) {
      cookie['NMTID'] = CryptoJS.lib.WordArray.random(16).toString()
    }
    if (!cookie.MUSIC_U) {
      // 游客
      cookie['MUSIC_A'] = cookie.MUSIC_A || loginInfo?.anonymous_token || ''
    }
    headers['Cookie'] = cookieObjToString(cookie)
  }

  let url = '',
    encryptData: string | object = '',
    crypto = options.crypto,
    csrfToken = cookie['__csrf'] || ''

  if (crypto === '') {
    // 加密方式为空，以配置文件的加密方式为准
    if (config.APP_CONF.encrypt) {
      crypto = 'eapi'
    } else {
      crypto = 'api'
    }
  }

  // 根据加密方式加密请求数据；目前任意uri都支持四种加密方式
  switch (crypto) {
    case 'weapi':
      headers['Referer'] = config.APP_CONF.domain as string
      headers['User-Agent'] = options.ua || chooseUserAgent('weapi')
      data.csrf_token = csrfToken
      encryptData = await encrypt.weapi(data)
      url = config.APP_CONF.domain + '/weapi/' + uri.substr(5)
      break

    case 'linuxapi':
      headers['User-Agent'] =
        options.ua || chooseUserAgent('linuxapi', 'linux')
      encryptData = encrypt.linuxapi({
        'method': 'POST',
        'url': config.APP_CONF.domain + uri,
        'params': data,
      })
      url = config.APP_CONF.domain + '/api/linux/forward'
      break

    case 'eapi':
    case 'api':
      // 两种加密方式，都应生成客户端的cookie
      const header: Record<string, string> = {
        'osver': cookie.osver, //系统版本
        'deviceId': cookie.deviceId,
        'os': cookie.os, //系统类型
        'appver': cookie.appver, // app版本
        'versioncode': cookie.versioncode || '140', //版本号
        'mobilename': cookie.mobilename || '', //设备model
        'buildver': cookie.buildver || Date.now().toString().substr(0, 10),
        'resolution': cookie.resolution || '1920x1080', //设备分辨率
        '__csrf': csrfToken,
        'channel': cookie.channel, //下载渠道
        'requestId': `${Date.now()}_${Math.floor(Math.random() * 1000)
          .toString()
          .padStart(4, '0')}`,
      }
      if (cookie.MUSIC_U) {
        header['MUSIC_U'] = cookie.MUSIC_U
      }
      if (cookie.MUSIC_A) {
        header['MUSIC_A'] = cookie.MUSIC_A
      }
      headers['Cookie'] = Object.keys(header)
        .map(
          (key) =>
          encodeURIComponent(key) + '=' + encodeURIComponent(header[key]),
        )
        .join('; ')
      headers['User-Agent'] = options.ua || chooseUserAgent('api', 'iphone')

      if (crypto === 'eapi') {
        // 使用eapi加密
        data.header = header
        data.e_r =
          options.e_r != undefined
            ? options.e_r
            : data.e_r != undefined
            ? data.e_r
            : config.APP_CONF.encryptResponse // 用于加密接口返回值
        data.e_r = toBoolean(data.e_r as string)
        encryptData = encrypt.eapi(uri, data)
        url = config.APP_CONF.apiDomain + '/eapi/' + uri.substr(5)
        // debuglog('data', data)
        // debuglog('encryptData', encryptData)
        // debuglog('url', url)

      } else if (crypto === 'api') {
        // 不使用任何加密
        url = config.APP_CONF.apiDomain + uri
        encryptData = data
      }
      break

    default:
    // 未知的加密方式
      console.log('[ERR]', 'Unknown Crypto:', crypto)
      break
  }


  const answer: CommonResponse<CommonResponseBody> = { status: 500, cookie: [] }

  // console.log(headers, 'headers')
  let settings: AxiosRequestConfig<string> = {
    method: 'POST',
    url: url,
    headers: headers,
    //TODO
    data: new URLSearchParams(encryptData as Record<string, string>).toString(),
    // httpAgent: new http.Agent({ keepAlive: true }),
    // httpsAgent: new https.Agent({ keepAlive: true }),
    proxy: false
  }

  if (data.e_r) {
    settings.responseEncoding = undefined
    settings.responseType = 'array_buffer'
  }


  try {

    // debuglog('[REQ COOKIE]', cookie, 2)
    // debuglog('req data', data)
    // debuglog('req data', settings.data)
    // debuglog('[DATA]', data)
    // debuglog('[CRYPTO]', crypto)
    const res: AxiosResponse<object> = await axios(settings)
    // debuglog('res headers', res.headers)
    const body = res.data
    debuglog('[OK]', settings.url)
    debuglog('[RES DATA]', body)
    answer.cookie = (res.headers['set-cookie'] || []).map((x) => x.replace(/\s*Domain=[^(;|$)]+;*/, ''))
    try {
      if (data.e_r) {
        // eapi接口返回值被加密，需要解密
        answer.body = encrypt.eapiResDecrypt(
          (body as buffer.Buffer).toString('hex').toUpperCase(),
        ) as CommonResponseBody
      } else {
        answer.body =
          (typeof body == 'object' ? body : JSON.parse((body as string).toString())) as
          CommonResponseBody
      }


      let code = answer?.body?.code
      if (typeof code === 'string') {
        code = Number(code)
      }

      answer.status = Number(code || res.status)

      if (
        [201, 302, 400, 502, 800, 801, 802, 803].indexOf(answer.status) >
          -1
      ) {
        // 特殊状态码
        answer.status = 200
      }
    } catch (e) {
      console.error(e.stack)
      // console.log(e)
      // can't decrypt and can't parse directly
      answer.body = body as CommonResponseBody
      answer.status = res.status
    }

    answer.status =
      100 < answer.status && answer.status < 600 ? answer.status : 400
    if (answer.status === 200) {
      return answer as CommonResponse<T>
    }
    throw new Error(answer.body.msg || answer.body.message)
  } catch (err) {
    console.error(err.stack)
    answer.status = 502
    answer.body = { code: 502, msg: typeof err === 'string' ? err : err?.message }
    promptAction.showToast({
      message: answer.body.msg
    })
  }
  throw new Error(answer.body.msg)
}

import { CryptoJS } from '@ohos/crypto-js'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { buffer } from '@kit.ArkTS'
import { InputDataType } from './interface'

const iv = '0102030405060708'
const presetKey = '0CoJUm6Qyw8W8jud'
const linuxapiKey = 'rFgB&h#%2?^eDg:Q'
const base62 = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
const publicKey = `-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ37BUrX/aKzmFbt7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvaklV8k4cBFK9snQXE9/DDaFt6Rr7iVZMldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44oncaTWz7OBGLbCiK45wIDAQAB
-----END PUBLIC KEY-----`
const eapiKey = 'e82ckenh8dichen8'


const aesEncrypt = (text: string, mode: string, key: string, iv: string,
  format = 'base64') => {
  let encrypted: CryptoJS.lib.CipherParams | undefined;

  // 'CBC' | 'CFB' | 'CTR' | 'CTRGladman' | 'OFB' | 'ECB'
  if (mode.toUpperCase() === 'CBC') {
    encrypted = CryptoJS.AES.encrypt(
      CryptoJS.enc.Utf8.parse(text),
      CryptoJS.enc.Utf8.parse(key),
      {
        iv: CryptoJS.enc.Utf8.parse(iv),
        mode: CryptoJS.mode.CBC,
        padding: CryptoJS.pad.Pkcs7,
      },
    )
  }

  if (mode.toUpperCase() === 'CFB') {
    encrypted = CryptoJS.AES.encrypt(
      CryptoJS.enc.Utf8.parse(text),
      CryptoJS.enc.Utf8.parse(key),
      {
        iv: CryptoJS.enc.Utf8.parse(iv),
        mode: CryptoJS.mode.CFB,
        padding: CryptoJS.pad.Pkcs7,
      },
    )
  }

  if (mode.toUpperCase() === 'CTR') {
    encrypted = CryptoJS.AES.encrypt(
      CryptoJS.enc.Utf8.parse(text),
      CryptoJS.enc.Utf8.parse(key),
      {
        iv: CryptoJS.enc.Utf8.parse(iv),
        mode: CryptoJS.mode.CTR,
        padding: CryptoJS.pad.Pkcs7,
      },
    )
  }

  if (mode.toUpperCase() === 'CTRGladman') {
    encrypted = CryptoJS.AES.encrypt(
      CryptoJS.enc.Utf8.parse(text),
      CryptoJS.enc.Utf8.parse(key),
      {
        iv: CryptoJS.enc.Utf8.parse(iv),
        mode: CryptoJS.mode.CTR,
        padding: CryptoJS.pad.Pkcs7,
      },
    )
  }

  if (mode.toUpperCase() === 'OFB') {
    encrypted = CryptoJS.AES.encrypt(
      CryptoJS.enc.Utf8.parse(text),
      CryptoJS.enc.Utf8.parse(key),
      {
        iv: CryptoJS.enc.Utf8.parse(iv),
        mode: CryptoJS.mode.OFB,
        padding: CryptoJS.pad.Pkcs7,
      },
    )
  }

  if (mode.toUpperCase() === 'ECB') {
    encrypted = CryptoJS.AES.encrypt(
      CryptoJS.enc.Utf8.parse(text),
      CryptoJS.enc.Utf8.parse(key),
      {
        iv: CryptoJS.enc.Utf8.parse(iv),
        mode: CryptoJS.mode.ECB,
        padding: CryptoJS.pad.Pkcs7,
      },
    )
  }

  if (!encrypted) {
    return ''
  }

  if (format === 'base64') {
    return encrypted.toString()
  }

  return encrypted.ciphertext.toString().toUpperCase()
}

const aesDecrypt = (ciphertext: string, key: string, iv: string, format = 'base64') => {
  let bytes: CryptoJS.lib.WordArray

  if (format === 'base64') {
    bytes = CryptoJS.AES.decrypt(ciphertext, CryptoJS.enc.Utf8.parse(key), {
      iv: CryptoJS.enc.Utf8.parse(iv),
      mode: CryptoJS.mode.ECB,
      padding: CryptoJS.pad.Pkcs7,
    })
  } else {
    bytes = CryptoJS.AES.decrypt(
      {
        ciphertext: CryptoJS.enc.Hex.parse(ciphertext)
      } as CryptoJS.lib.CipherParams,
      CryptoJS.enc.Utf8.parse(key),
      {
        iv: CryptoJS.enc.Utf8.parse(iv),
        mode: CryptoJS.mode.ECB,
        padding: CryptoJS.pad.Pkcs7,
      },
    )
  }
  return bytes.toString(CryptoJS.enc.Utf8)
}

async function rsaEncryptBySegment(pubKey: cryptoFramework.PubKey, plainText: cryptoFramework.DataBlob) {
  let cipher = cryptoFramework.createCipher('RSA1024|NoPadding');
  await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, pubKey, null);
  let plainTextSplitLen = 128;
  let chunkSize = Math.ceil(plainText.data.length / plainTextSplitLen);
  let paddingLength = chunkSize * plainTextSplitLen - plainText.data.length
  let zeros: Uint8Array = new Uint8Array(paddingLength).fill(0x00);
  let fullData = new Uint8Array(chunkSize * plainTextSplitLen);
  fullData.set(zeros)
  fullData.set(plainText.data, zeros.length);

  let cipherText = new Uint8Array();
  for (let i = 0; i < chunkSize; i++) {
    let chunk = fullData.subarray(i * plainTextSplitLen, (i + 1) * plainTextSplitLen);
    // 将原文按64字符进行拆分，循环调用doFinal进行加密，使用1024bit密钥时，每次加密生成128字节长度的密文
    let updateMessageBlob: cryptoFramework.DataBlob = { data: chunk };
    let updateOutput = await cipher.doFinal(updateMessageBlob);
    let mergeText = new Uint8Array(cipherText.length + updateOutput.data.length);
    mergeText.set(cipherText);
    mergeText.set(updateOutput.data, cipherText.length);
    cipherText = mergeText;
  }
  let cipherBlob: cryptoFramework.DataBlob = { data: cipherText };
  return cipherBlob;
}

export const rsaEncrypt = async (str: string, key?: string) => {
  try {
    let asyKeyGenerator = cryptoFramework.createAsyKeyGenerator("RSA1024"); // 创建非对称密钥生成器对象
    let keyPair = await asyKeyGenerator.convertPemKeySync(key || publicKey, null); // 随机生成RSA密钥
    let plainText: cryptoFramework.DataBlob =
      { data: new Uint8Array(buffer.from(str, 'utf-8').buffer) };
    let encryptText = await rsaEncryptBySegment(keyPair.pubKey, plainText);
    return buffer.from(encryptText.data).toString('hex')
  } catch (e) {
    return ''
  }
}

type CommonResult = Record<string, string>

const weapi = async (object: object): Promise<CommonResult> => {
  const text = JSON.stringify(object)
  let secretKey = ''
  for (let i = 0; i < 16; i++) {
    secretKey += base62.charAt(Math.round(Math.random() * 61))
  }
  return {
    'params': aesEncrypt(aesEncrypt(text, 'cbc', presetKey, iv), 'cbc', secretKey, iv),
    'encSecKey': await rsaEncrypt(secretKey.split('').reverse().join(''), publicKey),
  }
}


const linuxapi = (object: Record<string, string | InputDataType>): CommonResult => {
  const text = JSON.stringify(object)
  return { 'eparams': aesEncrypt(text, 'ecb', linuxapiKey, '', 'hex'), }
}


const eapi = (url: string, object: object | string): CommonResult => {
  const text = typeof object === 'object' ? JSON.stringify(object) : object
  const message = `nobody${url}use${text}md5forencrypt`
  const digest = CryptoJS.MD5(message).toString()
  const data = `${url}-36cd479b6b5-${text}-36cd479b6b5-${digest}`
  return { 'params': aesEncrypt(data, 'ecb', eapiKey, '', 'hex'), }
}

const eapiResDecrypt = (encryptedParams: string): object => {
  // 使用aesDecrypt解密参数
  const decryptedData = aesDecrypt(encryptedParams, eapiKey, '', 'hex')
  return JSON.parse(decryptedData)
}

interface EapiReqDecryptResult {
  url: string,
  data: object
}

const eapiReqDecrypt = (encryptedParams: string): EapiReqDecryptResult | null => {
  // 使用aesDecrypt解密参数
  const decryptedData = aesDecrypt(encryptedParams, eapiKey, '', 'hex')
  // 使用正则表达式解析出URL和数据
  const match = decryptedData.match(/(.*?)-36cd479b6b5-(.*?)-36cd479b6b5-(.*)/)
  if (match) {
    const url = match[1]
    const data: object = JSON.parse(match[2])
    return { url, data }
  }

  // 如果没有匹配到，返回null
  return null
}
const decrypt = (cipher: string) => {
  const decipher = CryptoJS.AES.decrypt(
    {
      ciphertext: CryptoJS.enc.Hex.parse(cipher),
    } as CryptoJS.lib.CipherParams,
    eapiKey,
    {
      mode: CryptoJS.mode.ECB,
    },
  )
  const decryptedBytes = CryptoJS.enc.Utf8.stringify(decipher)
  return decryptedBytes
}

export {
  weapi, linuxapi, eapi, decrypt, aesEncrypt, aesDecrypt, eapiReqDecrypt, eapiResDecrypt, }

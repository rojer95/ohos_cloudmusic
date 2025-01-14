// 生成一个随机整数
function getRandomInt(min: number, max: number) {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

// 生成一个随机IP地址段
function generateIPSegment(): number {
  return getRandomInt(1, 255)
}


export function toBoolean(val: boolean | string): boolean | string {
  if (typeof val === 'boolean') {
    return val
  }
  if (val === '') {
    return val
  }
  return val === 'true' || val == '1'
}

export function cookieToJson(cookie: string): Record<string, string> {
  if (!cookie) {
    return {}
  }
  let cookieArr = cookie.split(';')
  let obj: Record<string, string> = {}
  cookieArr.forEach((i) => {
    let arr = i.split('=')
    if (arr.length == 2) {
      obj[arr[0].trim()] = arr[1].trim()
    }
  })
  return obj
}

export function cookieObjToString(cookie: Record<string, string>) {
  return Object.keys(cookie)
    .map(
      (key) =>
      `${encodeURIComponent(key)}=${encodeURIComponent(cookie[key])}`,
    )
    .join('; ')
}

export function getRandom(num: number) {
  return Math.floor(
    (Math.random() + Math.floor(Math.random() * 9 + 1)) *
    Math.pow(10, num - 1),
  )
}

export function generateRandomChineseIP() {
  const chinaIPPrefixes = ['116.25', '116.76', '116.77', '116.78']

  const randomPrefix =
    chinaIPPrefixes[Math.floor(Math.random() * chinaIPPrefixes.length)]
  return `${randomPrefix}.${generateIPSegment()}.${generateIPSegment()}`
}



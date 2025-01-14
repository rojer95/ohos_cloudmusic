import { RequestOptions } from "./interface"

const createOption = (query?: Record<string, string> , crypto?: string): RequestOptions => {
  return {
    crypto: query?.crypto || crypto || '',
    cookie: query?.cookie,
    ua: query?.ua || '',
    realIP: query?.realIP,
    e_r: query?.e_r || undefined,
  }
}

export { createOption }
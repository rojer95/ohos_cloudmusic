import { buffer } from "@kit.ArkTS"

export type InputDataType = Record<string, string | number | boolean | Record<string, string>>

export type ResponseData = InputDataType | string | buffer.Buffer


export interface CommonResponseBody {
  msg?: string
  message?: string
  code: number;
}

export interface CommonResponse<T extends CommonResponseBody> {
  status: number,
  body?: T,
  cookie: string[]
}


export interface RequestOptions {
  headers?: Record<string, string>;
  realIP?: string;
  cookie?: string | Record<string, string>
  crypto?: string;
  ip?: string
  ua?: string
  e_r?: string
}

export type IRequest<T> = (url: string, data: Record<string, string>, option: RequestOptions) => Promise<T>

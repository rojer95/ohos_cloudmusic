import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios'
import promptAction from '@ohos.promptAction'

const request = axios.create({
  baseURL: 'http://192.168.0.88:3000',
  timeout: 5000,
  headers: {}
});

// 添加请求拦截器
request.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  // console.debug(`request ->  [${config.method}] ${config.baseURL}${config.url} ${JSON.stringify(config.params)}`);
  const loginCookie = AppStorage.get<string>('login_cookie')
  if (loginCookie) {
    // console.debug(`request cookie ->  [${loginCookie}`);
    config.headers.Cookie = loginCookie;
  }
  return config;
}, (error: AxiosError) => {
  console.debug(`request fail -> ${error.message}`);
  promptAction.showToast({
    message: error.message,
  })
  return Promise.reject(error);
});


// 添加响应拦截器
request.interceptors.response.use((response: AxiosResponse) => {
  if (response?.data?.code !== 200) {
    return Promise.reject(new Error(response.data.message));
  }
  // console.log(`response result -> ${JSON.stringify(response.data)}`);
  return response;
}, (error: AxiosError) => {
  console.debug(`response fail -> ${error.message}`);
  promptAction.showToast({
    message: error.message,
  })
  return Promise.reject(error);
});

export { request }
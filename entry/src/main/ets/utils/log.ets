import hilog from "@ohos.hilog"

export const debuglog = (name: string, value?: object | object[] | string | number | boolean, l = 0) => {
  hilog.debug(0, 'debug', `%{public}s%{public}s`, name,
    value ? ` ---> ` + JSON.stringify(value, null, l) : '')
}
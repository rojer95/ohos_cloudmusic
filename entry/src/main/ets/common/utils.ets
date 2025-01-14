import { effectKit } from '@kit.ArkGraphics2D';
import axios, { AxiosResponse } from '@ohos/axios';
import { image } from '@kit.ImageKit';
import dayjs from 'dayjs';

export interface ImageMainColorResult {
  img: PixelMap | string
  colors: Record<string, effectKit.Color>
}

export interface ImageMainColorRegion {
  key: string;
  region: number[]
}

/**
 * 工具类
 */
export class Utils {
  public static async downloadImage(url: string, options?: image.DecodingOptions): Promise<PixelMap> {
    const response: AxiosResponse<ArrayBuffer> = await axios.get<ArrayBuffer>(Utils.getCoverUrl(url) as string, {
      responseType: 'array_buffer',
    })
    const imageSource: image.ImageSource = image.createImageSource(response.data);
    return await imageSource.createPixelMap(options);
  }

  /**
   * 获取图片的主色调，并返回图片数据
   * @param img
   * @param regions
   * @returns
   */
  public static async getImageMainColor(img: string,
    regions: Array<ImageMainColorRegion> = [{ key: 'main', region: [0, 0, 1, 1] }]): Promise<ImageMainColorResult> {
    const pixelMap = await Utils.downloadImage(img)

    const result: ImageMainColorResult = {
      img: pixelMap,
      colors: {}
    };

    for (const region of regions) {

      const colorPicker: effectKit.ColorPicker = await effectKit.createColorPicker(pixelMap,
        region.region);
      const color = await colorPicker.getAverageColor()
      result.colors[region.key] = color
    }

    return result
  }

  public static duration2timeString(duration: number):string {
    try {
      const _duration = dayjs.duration(duration)
      return _duration.format('mm:ss')
    } catch (e) {
      return '00:00'
    }
  }

  public static getCoverUrl(url?: string, width = 200, height = 200) {
    if (!url || url.indexOf('?') > 0) {
      return url
    }
    return `${url}?param=${width}y${height}`
  }
}
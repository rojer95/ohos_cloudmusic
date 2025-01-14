import { SongDetail } from '../model/song_detail';
import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';


interface ResponseBody extends CommonResponseBody {
  songs: object[];
}

export const apiArtistSongs = async (id: string): Promise<SongDetail[]> => {
  const response = await apiArtistSongsReq(id);
  return response.body?.songs.map(i =>  i as SongDetail) || [];
}

export const apiArtistSongsReq = async (id: string) => {
  let data: InputDataType = {
    'id': id
  }

  return await createRequest<ResponseBody>(`/api/artist/top/song`,
    data, createOption(undefined, 'weapi'))
}
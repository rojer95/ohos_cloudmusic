import { createOption } from './core/createOption';
import { CommonResponseBody, InputDataType } from './core/interface';
import { createRequest } from './core/request';

import { Playlist, PlaylistDetailResponseData } from '../model/playlist_detail';


interface ResponseBody extends CommonResponseBody {
  playlist?: Playlist
}


export const apiPlaylistDetails = async (id: string): Promise<Playlist | undefined> => {
  const responses = await request(id)
  return (responses.body as PlaylistDetailResponseData)?.playlist
}


const request = async (id: string) => {
  const data: InputDataType = {
    'id': id,
    'n': 100000,
    's': 8,
  }
  return await createRequest<ResponseBody>(`/api/v6/playlist/detail`, data, createOption())
}
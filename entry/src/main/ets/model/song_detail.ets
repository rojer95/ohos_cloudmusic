import { Album } from './album';
import { Artist } from './artist';

export class SongDetail {
  name: string = '';
  id: number = 0;
  dt: number = 0
  al?: Album = undefined;
  ar?: Artist [] = [];
}

import { Album } from './album';
import { Artist } from './artist';


export class PersonalFm {
  id: number = 0;
  name: string = '';
  dt: number = 0
  al?: Album = undefined;
  ar?: Artist [] = [];
}
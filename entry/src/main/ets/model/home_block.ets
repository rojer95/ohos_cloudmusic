
import { Artist } from './artist'

export abstract class DslData {
  dslShowTitle?: boolean
}

export class HomeBlockResourceItemIconDesc {
  image?: string
}

export class HomeBlockResourceItemResourceInteractInfo {
  playCount?: string
}

export class HomeBlockResourceItemResourceExtInfo {
  artists?: Artist[]
}

export class HomeBlockResourceItemExtInfo {
  songId?: number
  songIdList?: number[]
}


class CommonPlaylistItemPlayBtnPlayAction {
  songIds?: number[];
}

export class CommonPlaylistItemPlayBtn {
  playAction?: CommonPlaylistItemPlayBtnPlayAction;
}


export class HomeBlockResourceItem {
  title?: string
  name?: string
  resourceId?: string
  coverImg?: string
  subTitle?: string
  singleLineTitle?: string
  tagText?: string
  tag?: string
  tags?: string[]
  playCount?: string;
  songIdsStr?: string
  rankTitle?: string
  resourceType?: string
  iconDesc?: HomeBlockResourceItemIconDesc
  resourceInteractInfo?: HomeBlockResourceItemResourceInteractInfo
  resourceExtInfo?: HomeBlockResourceItemResourceExtInfo;
  extInfo?: HomeBlockResourceItemExtInfo
  playBtn?: CommonPlaylistItemPlayBtn
}

export class HomeBlockResource {
  title?: string
  showMore?: boolean
  resources?: HomeBlockResourceItem[]
}


/**
 * 你的红心歌曲和相似推荐
 */
export namespace PAGE_RECOMMEND_RED_SIMILAR_SONG {


  export class HomeCommonRcmdSongContentItemItem {
    resourceId?: string;
    title?: string;
    coverUrl?: string;
    artistName?: string;
    resourceType?: string;
    tag?: string;
  }

  export class HomeCommonRcmdSongContentItem {
    items?: Array<HomeCommonRcmdSongContentItemItem>
  }

  export class HomeCommonRcmdSongContent {
    items?: Array<HomeCommonRcmdSongContentItem>
  }


  export class HomeCommonRcmdSongHeader {
    showMore?: boolean
    title?: string
  }

  export class HomeCommonRcmdSong {
    header?: HomeCommonRcmdSongHeader
    content?: HomeCommonRcmdSongContent
  }

  export class Data extends DslData {
    home_common_rcmd_songs_module_8pim9hfovz?: HomeCommonRcmdSong
  }
}

/**
 * 每日推荐
 */
export namespace PAGE_RECOMMEND_DAILY_RECOMMEND {
  export class Data extends DslData {
    blockResource?: HomeBlockResource
  }
}


export namespace PAGE_RECOMMEND_SPECIAL_CLOUD_VILLAGE_PLAYLIST {

  export class Data extends DslData {
    blockResource?: HomeBlockResource
  }
}

export namespace PAGE_RECOMMEND_RANK {

  export class Rcmd_rank_module_l0hao53bru {
    title?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Data extends DslData {
    rcmd_rank_module_l0hao53bru?: Rcmd_rank_module_l0hao53bru
  }
}


export namespace PAGE_RECOMMEND_SHORTCUT {

  export class Home_recent_play_module0807_2omxsh5w83 {
    title?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Data extends DslData {
    home_recent_play_module0807_2omxsh5w83?: Home_recent_play_module0807_2omxsh5w83
  }
}


export namespace PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST {

  export class BlockResource {
    title?: string;
    iconUrl?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Data extends DslData {
    blockResource?: BlockResource
  }
}


export namespace PAGE_RECOMMEND_SCENE_PLAYLIST_LOCATION {

  export class BlockResource {
    title?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Home_page_common_playlist_module_85enrjqhk4 {
    blockResource?: BlockResource
  }

  export class Data extends DslData {
    home_page_common_playlist_module_85enrjqhk4?: Home_page_common_playlist_module_85enrjqhk4
  }
}


export namespace PAGE_RECOMMEND_FIRM_PLAYLIST {

  export class BlockResource {
    title?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Home_page_common_playlist_module_d1r94fwj80 {
    blockResource?: BlockResource
  }

  export class Data extends DslData {
    home_page_common_playlist_module_d1r94fwj80?: Home_page_common_playlist_module_d1r94fwj80
  }
}


export namespace PAGE_RECOMMEND_AWARDS_PLAYLIST {

  export class BlockResource {
    title?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Home_page_common_playlist_module_d1r94fwj80 {
    blockResource?: BlockResource
  }

  export class Data extends DslData {
    home_page_common_playlist_module_d1r94fwj80?: Home_page_common_playlist_module_d1r94fwj80
  }
}

export namespace PAGE_RECOMMEND_SPECIAL_ORIGIN_SONG_LOCATION {

  export class BlockResource {
    title?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Home_page_common_playlist_module_65o1euutmu {
    blockResource?: BlockResource
  }

  export class Data extends DslData {
    home_page_common_playlist_module_65o1euutmu?: Home_page_common_playlist_module_65o1euutmu
  }
}

export namespace PAGE_RECOMMEND_LBS {

  export class BlockResourceVO {
    title?: string;
    resources?: HomeBlockResourceItem[]
  }

  export class Home_position_rank_module_naik97twi1 {
    blockResourceVO?: BlockResourceVO
  }

  export class Data extends DslData {
    home_position_rank_module_naik97twi1?: Home_position_rank_module_naik97twi1
  }
}


export namespace PAGE_RECOMMEND_PRIVATE_RCMD_SONG {

  export class Block {
    title?: string
  }

  export class Item {
    cover?: string
    resourceId?: string
    tagIcon?: string
    showTag?: boolean
    recReason?: string
    name?: string
    artistName?: string
    tag?: string
    title?: string
    resourceType?: string
  }

  export class Items {
    items?: Item[]
  }

  export class Content {
    items?: Items[]
  }

  export class Data extends DslData {
    block?: Block
    content?: Content
  }
}

export namespace PAGE_RECOMMEND_GREETING {
  export class Home_greet_rcmd_title_resource {
    title?: string
  }

  export class ExtraMap {
    arrowIconJson?: string
  }

  export class CommonResourceList {
    home_greet_rcmd_title_resource?: Home_greet_rcmd_title_resource
    extraMap?: ExtraMap;
    title?: string
    icon?: string;
    resourceType?: string;
  }

  export class Page_rcmd_top_greeting_2bnzys1v1e {
    commonResourceList?: CommonResourceList[]
  }

  export class Data extends DslData {
    page_rcmd_top_greeting_2bnzys1v1e?: Page_rcmd_top_greeting_2bnzys1v1e
  }
}

export class HomeBlockItem {
  bizCode: string = '';
  showTitle: boolean = false;
  positionCode: string = '';

  dslData?: PAGE_RECOMMEND_DAILY_RECOMMEND.Data |
  PAGE_RECOMMEND_SPECIAL_CLOUD_VILLAGE_PLAYLIST.Data |
  PAGE_RECOMMEND_SHORTCUT.Data |
  PAGE_RECOMMEND_PRIVATE_RCMD_SONG.Data |
  PAGE_RECOMMEND_RANK.Data |
  PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST.Data |
  PAGE_RECOMMEND_FIRM_PLAYLIST.Data |
  PAGE_RECOMMEND_DAILY_RECOMMEND.Data |
  PAGE_RECOMMEND_AWARDS_PLAYLIST.Data |
  PAGE_RECOMMEND_SCENE_PLAYLIST_LOCATION.Data |
  PAGE_RECOMMEND_SPECIAL_ORIGIN_SONG_LOCATION.Data |
  PAGE_RECOMMEND_LBS.Data |
  PAGE_RECOMMEND_RED_SIMILAR_SONG.Data
}

export class HomeBlockResponse {
  cursor: number = 0
  hasMore: boolean = false
  callbackParameters: string = '';
  blockCodeOrderList: string = '';
  requestBlockOrder: string[] = [];
  blocks: HomeBlockItem[] = [];
}
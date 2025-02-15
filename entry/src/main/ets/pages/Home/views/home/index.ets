import { PageItemSpace } from '../../../../common/vars';
import {
  HomeBlockResponse,
  HomeBlockItem,
  PAGE_RECOMMEND_LBS,
  PAGE_RECOMMEND_DAILY_RECOMMEND,
  PAGE_RECOMMEND_RED_SIMILAR_SONG,
  PAGE_RECOMMEND_SPECIAL_CLOUD_VILLAGE_PLAYLIST,
  PAGE_RECOMMEND_RANK,
  PAGE_RECOMMEND_SHORTCUT,
  PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST,
  PAGE_RECOMMEND_FIRM_PLAYLIST,
  PAGE_RECOMMEND_AWARDS_PLAYLIST,
  PAGE_RECOMMEND_SPECIAL_ORIGIN_SONG_LOCATION,
  PAGE_RECOMMEND_GREETING,
  PAGE_RECOMMEND_SCENE_PLAYLIST_LOCATION,
} from '../../../../model/home_block';
import { HomeDailyRecommend } from './components/daily_recommend';
import { HelloBar } from './components/hello-bar';
import { RecommendRedSimilarSong } from './components/recommend_private_rcmd_song';
import { CommonPlaylistItem, CommonPlaylistResourcesItem } from './components/common_playlist';
import { HomeDailyRecommendCardObject } from './components/daily_recommend_card';
import { apiHomeRecommendPage, ApiHomeRecommendPageParams } from '../../../../api/home_recommend_page';
import { CommonShortcut, CommonShortcutItem } from './components/common_shortcut';
import { PersistenceV2, SwipeRefresher } from '@kit.ArkUI';
import { getGlobal, GlobalContent, getPlayer } from '../../../../viewmodel/global';
import emitter from '@ohos.events.emitter';
import { LoginInfo } from '../../../../viewmodel/loginInfo';
import { debuglog } from '../../../../utils/log';
import { Player } from '../../../../viewmodel/player';

@ComponentV2
export struct HomeTabContext {
  private blockRequestParams: ApiHomeRecommendPageParams = {}
  private _loadLook = false
  private _hasMore = true
  @Local dataSource: HomeBlockItem[] = []
  @Local loading: boolean = false;
  @Local global: GlobalContent | undefined = getGlobal()
  @Local player: Player | undefined = getPlayer()
  @Local loginInfo: LoginInfo | undefined = PersistenceV2.connect(LoginInfo)

  aboutToAppear(): void {
    this.load(true)
    this.onEventListing()
  }

  aboutToDisappear(): void {
    this.offEventListing()
  }

  onEventListing() {
    emitter.on('refresh', (data) => {
      if (data.data?.['index'] === 0){
        this.load(true)
      }
    })

    emitter.on('logined', (data) => {
      this.load(true)
    })
  }

  offEventListing() {
    emitter.off('refresh')
    emitter.off('logined')
  }

  async load(reload = false) {
    if (this._loadLook) {
      return
    }

    if (!reload && !this._hasMore) {
      return
    }

    this._loadLook = true
    this.loading = true
    try {

      if (reload) {
        this.blockRequestParams = {}
        this.dataSource = []
      }

      console.log('load cursor ----> ', this.blockRequestParams.cursor)

      const response: HomeBlockResponse = await apiHomeRecommendPage({
        cursor: this.blockRequestParams.cursor,
        loadedPositionCodes: this.blockRequestParams.requestBlockOrder ?
        JSON.stringify(this.blockRequestParams.requestBlockOrder) : undefined,
        blockCodeOrderList: this.blockRequestParams.blockCodeOrderList
      });

      for (const block of response.blocks) {
        if (block.bizCode === 'PAGE_RECOMMEND_VIP_CARD') {
          debuglog('vip', block.dslData)
        }
      }
      this.dataSource.push(...response.blocks)
      this.blockRequestParams.cursor = response.cursor;
      this.blockRequestParams.blockCodeOrderList = response.blockCodeOrderList;
      if (!this.blockRequestParams.requestBlockOrder) {
        this.blockRequestParams.requestBlockOrder = []
      }
      this.blockRequestParams.requestBlockOrder.push(...response.requestBlockOrder);
      this._hasMore = response.hasMore;
    } finally {
      this._loadLook = false
      this.loading = false
    }
  }

  @Builder
  blockRender(block: HomeBlockItem) {


    /** 欢迎 **/
    if (block.bizCode === 'PAGE_RECOMMEND_GREETING') {
      ListItem() {
        HelloBar({
          hello: (block.dslData as PAGE_RECOMMEND_GREETING.Data)?.page_rcmd_top_greeting_2bnzys1v1e
          ?.commonResourceList
          ?.find(i => i?.resourceType === 'nonstandard')
          ?.home_greet_rcmd_title_resource
          ?.title,
        })
      }
    }

    /** 每日推荐 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_DAILY_RECOMMEND') {
      ListItem() {
        HomeDailyRecommend({
          resources: ((block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.resources ||
            []).map(item => {
            const homeDailyRecommendCardObject: HomeDailyRecommendCardObject = {
              title: item.title,
              subTitle: item.subTitle,
              tagText: item.tagText,
              singleLineTitle: item.singleLineTitle,
              coverImg: item.coverImg,
              iconUrl: item.iconDesc?.image,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              extInfo: item.extInfo
            }
            return homeDailyRecommendCardObject
          }),
          title: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.dslShowTitle
        })
      }

    }

    /** 你可能喜欢的新歌 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_NEW_SONG_AND_ALBUM') {
      ListItem() {
        HomeDailyRecommend({
          resources: ((block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.resources ||
            []).map(item => {
            const homeDailyRecommendCardObject: HomeDailyRecommendCardObject = {
              subTitle: item.title,
              title: item.subTitle,
              coverImg: item.coverImg,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              extInfo: item.extInfo
            }
            return homeDailyRecommendCardObject
          }),
          title: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.dslShowTitle
        })
      }

    }

    /** 从你喜欢的歌曲开始漫游 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_MUSIC_FM_LIST') {
      ListItem() {
        HomeDailyRecommend({
          resources: ((block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.resources ||
            []).map(item => {
            const homeDailyRecommendCardObject: HomeDailyRecommendCardObject = {
              subTitle: item.title,
              title: item.subTitle,
              coverImg: item.coverImg,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              extInfo: item.extInfo
            }
            return homeDailyRecommendCardObject
          }),
          title: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.dslShowTitle
        })
      }

    }

    /** 从你喜欢的XXX开始漫游 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_ARTIST_FM_LIST') {
      ListItem() {
        HomeDailyRecommend({
          resources: ((block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.resources ||
            []).map(item => {
            const homeDailyRecommendCardObject: HomeDailyRecommendCardObject = {
              subTitle: item.title,
              title: item.subTitle,
              coverImg: item.resourceExtInfo?.artists?.[0]?.imgUrl,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              extInfo: item.extInfo
            }
            return homeDailyRecommendCardObject
          }),
          title: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_DAILY_RECOMMEND.Data)?.dslShowTitle
        })
      }
    }


    /** 各种歌单 **/
    else if (
      block.bizCode === 'PAGE_RECOMMEND_RADAR' ||
        block.bizCode === 'PAGE_RECOMMEND_MY_SHEET' ||
        block.bizCode === 'PAGE_RECOMMEND_SPECIAL_CLOUD_VILLAGE_PLAYLIST' ||
        block.bizCode === 'PAGE_RECOMMEND_FEELING_PLAYLIST_LOCATION' ||
        block.bizCode === 'PAGE_RECOMMEND_STYLE_PLAYLIST_1' ||
        block.bizCode === 'PAGE_RECOMMEND_STYLE_PLAYLIST_2' ||
        block.bizCode === 'PAGE_RECOMMEND_STYLE_PLAYLIST_2' ||
        block.bizCode === 'PAGE_RECOMMEND_COMBINATION'
    ) {
      ListItem() {
        CommonPlaylistItem({
          resources:
          ((block.dslData as PAGE_RECOMMEND_SPECIAL_CLOUD_VILLAGE_PLAYLIST.Data)?.blockResource?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item.playCount || item.resourceInteractInfo?.playCount,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              title: item.title || item.subTitle,
              coverTitle: item.rankTitle,
              extra: item
            }
            return commonPlaylistItem
          })
        ,
          title: `${
          ['PAGE_RECOMMEND_RADAR', 'PAGE_RECOMMEND_MY_SHEET'].includes(block.bizCode)
            ?
            (this.loginInfo?.profile?.nickname ? `${this.loginInfo?.profile?.nickname}的` : '') : ''
          }${(block.dslData as PAGE_RECOMMEND_SPECIAL_CLOUD_VILLAGE_PLAYLIST.Data)?.blockResource?.title}`,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_SPECIAL_CLOUD_VILLAGE_PLAYLIST.Data)?.dslShowTitle
        })
      }

    }


    /** 排行榜 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_RANK') {
      ListItem() {
        CommonPlaylistItem({
          resources: ((block.dslData as PAGE_RECOMMEND_RANK.Data)?.rcmd_rank_module_l0hao53bru?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item.playCount,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              title: item.subTitle,
              coverTitle: item.rankTitle,
            }
            return commonPlaylistItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_RANK.Data)?.rcmd_rank_module_l0hao53bru?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_RANK.Data)?.dslShowTitle
        })
      }

    }

    /** 定位地推荐歌单 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_LBS') {
      ListItem() {
        CommonPlaylistItem({
          resources: ((block.dslData as PAGE_RECOMMEND_LBS.Data)?.home_position_rank_module_naik97twi1?.blockResourceVO?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item.playCount,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              title: item.subTitle,
              coverTitle: item.title,
              playBtn: item.playBtn,
              name: item.name
            }
            return commonPlaylistItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_LBS.Data)?.home_position_rank_module_naik97twi1?.blockResourceVO?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_LBS.Data)?.dslShowTitle
        })
      }

    }

    /** 奖项音乐 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_AWARDS_PLAYLIST') {
      ListItem() {
        CommonPlaylistItem({
          resources: ((block.dslData as PAGE_RECOMMEND_AWARDS_PLAYLIST.Data)?.home_page_common_playlist_module_d1r94fwj80?.blockResource?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item.playCount,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              title: item.title || item.subTitle,
              coverTitle: item.rankTitle
            }
            return commonPlaylistItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_FIRM_PLAYLIST.Data)?.home_page_common_playlist_module_d1r94fwj80?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_FIRM_PLAYLIST.Data)?.dslShowTitle
        })
      }

    }

    /** 影视原声音乐 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_FIRM_PLAYLIST') {
      ListItem() {
        CommonPlaylistItem({
          resources: ((block.dslData as PAGE_RECOMMEND_FIRM_PLAYLIST.Data)?.home_page_common_playlist_module_d1r94fwj80?.blockResource?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item.playCount,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              title: item.title || item.subTitle,
              coverTitle: item.rankTitle
            }
            return commonPlaylistItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_FIRM_PLAYLIST.Data)?.home_page_common_playlist_module_d1r94fwj80?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_FIRM_PLAYLIST.Data)?.dslShowTitle
        })
      }

    }

    /** 场景歌单 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_SCENE_PLAYLIST_LOCATION') {
      ListItem() {
        CommonPlaylistItem({
          resources: ((block.dslData as PAGE_RECOMMEND_SCENE_PLAYLIST_LOCATION.Data)?.home_page_common_playlist_module_85enrjqhk4?.blockResource?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item.resourceInteractInfo?.playCount,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              title: item.title || item.subTitle,
              coverTitle: item.rankTitle
            }
            return commonPlaylistItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_SCENE_PLAYLIST_LOCATION.Data)?.home_page_common_playlist_module_85enrjqhk4?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_SCENE_PLAYLIST_LOCATION.Data)?.dslShowTitle
        })
      }

    } else if (block.bizCode === 'PAGE_RECOMMEND_SPECIAL_ORIGIN_SONG_LOCATION') {
      ListItem() {
        CommonPlaylistItem({
          resources: ((block.dslData as PAGE_RECOMMEND_SPECIAL_ORIGIN_SONG_LOCATION.Data)?.home_page_common_playlist_module_65o1euutmu?.blockResource?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item.resourceInteractInfo?.playCount,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              title: item.title || item.subTitle,
              coverTitle: item.rankTitle
            }
            return commonPlaylistItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_SPECIAL_ORIGIN_SONG_LOCATION.Data)?.home_page_common_playlist_module_65o1euutmu?.blockResource?.title,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_SPECIAL_ORIGIN_SONG_LOCATION.Data)?.dslShowTitle
        })
      }

    }

    /** 歌手推荐歌单 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST') {
      ListItem() {
        CommonPlaylistItem({
          resources: ((block.dslData as PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST.Data)?.blockResource?.resources ||
            []).map(item => {
            const commonPlaylistItem: CommonPlaylistResourcesItem = {
              coverImg: item.coverImg,
              playCount: item?.resourceInteractInfo?.playCount,
              resourceType: item.resourceType,
              title: item.title || item.subTitle,
              resourceId: item.resourceId,
            }
            return commonPlaylistItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST.Data)?.blockResource?.title,
          iconUrl: (block.dslData as PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST.Data)?.blockResource?.iconUrl,
          dslShowTitle: (block.dslData as PAGE_RECOMMEND_MIXED_ARTIST_PLAYLIST.Data)?.dslShowTitle
        })
      }

    }

    /** 你的红心歌曲相似推荐 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_RED_SIMILAR_SONG') {
      ListItem() {
        RecommendRedSimilarSong({
          resources: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.home_common_rcmd_songs_module_8pim9hfovz?.content,
          title: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.home_common_rcmd_songs_module_8pim9hfovz?.header?.title,
          dslShowTitle: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.dslShowTitle
        })
      }

    }

    /** 私人推荐歌单 **/
    else if (block.bizCode === 'PAGE_RECOMMEND_PRIVATE_RCMD_SONG') {

      ListItem() {
        RecommendRedSimilarSong({
          resources: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.home_common_rcmd_songs_module_8pim9hfovz?.content,
          title: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.home_common_rcmd_songs_module_8pim9hfovz?.header?.title,
          dslShowTitle: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.dslShowTitle
        })
      }

    } else if (block.bizCode === 'PAGE_RECOMMEND_SHORTCUT') {
      ListItem() {
        CommonShortcut({
          resources: ((block.dslData as PAGE_RECOMMEND_SHORTCUT.Data)?.home_recent_play_module0807_2omxsh5w83?.resources ||
            []).map(item => {
            const commonShortcutItem: CommonShortcutItem = {
              coverImg: item.coverImg,
              title: item.title,
              iconImg: item.iconDesc?.image,
              tag: item.tag,
              resourceId: item.resourceId,
              resourceType: item.resourceType,
              extInfo: item.extInfo
            }
            return commonShortcutItem
          }),
          title: (block.dslData as PAGE_RECOMMEND_SHORTCUT.Data)?.home_recent_play_module0807_2omxsh5w83?.title,
          dslShowTitle: true
        })
      }
    } else if (block.bizCode === 'PAGE_RECOMMEND_VIP_CARD') {
      ListItem() {
        RecommendRedSimilarSong({
          resources: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.home_common_rcmd_songs_module_8pim9hfovz?.content,
          title: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.home_common_rcmd_songs_module_8pim9hfovz?.header?.title,
          dslShowTitle: (block?.dslData as PAGE_RECOMMEND_RED_SIMILAR_SONG.Data)?.dslShowTitle
        })
      }
    }
  }

  build() {
    Column() {
      List({ space: PageItemSpace }) {
        ListItem() {
          Column().height(px2vp(this.global?.topRectHeight || 0))
        }

        Repeat(this.dataSource).each((item: RepeatItem<HomeBlockItem>) => {
          this.blockRender(item.item)
        }).key(item => item.bizCode)
        ListItem() {
          if (this.loading) {
            SwipeRefresher({
              content: '正在加载中',
              isLoading: true
            })
          }
        }.margin({
          bottom: this.player?.playingTitle ? 50 : 10
        })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .contentEndOffset(30)
      .onReachEnd(() => {
        this.load()
      })
    }
  }
}
import { ImageKnifeComponent } from '@ohos/imageknife';
import { PageSpace } from '../../../../../common/vars'
import { MusicPlayBtn } from '../../../../../components/music_play_btn';
import { CommonPlaylistItemPlayBtn } from '../../../../../model/home_block';
import { Playlist, TrackId } from '../../../../../model/playlist_detail';
import { getPlayer } from '../../../../../viewmodel/global';
import { CommonTitle } from './common_title'

const ListSpace = 8;


export interface CommonPlaylistItem {
  coverImg?: string;
  playCount?: string;
  resourceId?: string;
  resourceType?: string;
  title?: string;
  coverTitle?: string;
  name?: string;
  extra?: object
  playBtn?: CommonPlaylistItemPlayBtn
}

@ComponentV2
export struct CommonPlaylist {
  @Require @Param resources: CommonPlaylistItem[]
  @Param title: string = ''
  @Param iconUrl: string = ''
  @Param dslShowTitle: boolean = false
  @Consumer('pathStack') pathStack: NavPathStack = new NavPathStack();

  build() {
    Column() {
      if (this.dslShowTitle && this.title) {
        Column() {
          CommonTitle({ title: this.title, iconUrl: this.iconUrl })
        }
      }

      List({ space: ListSpace }) {

        ListItem().width(PageSpace - ListSpace) // 占位

        ForEach(this.resources || [], (item: CommonPlaylistItem) => {
          ListItem() {
            Column() {
              // 歌单卡片
              Stack() {

                // 背景图
                ImageKnifeComponent({
                  imageKnifeOption: {
                    loadSrc: item.coverImg,
                    objectFit: ImageFit.Cover
                  }
                })
                  .draggable(false)
                  .width(100)
                  .height(100)


                // 播放数量
                if (item?.playCount) {
                  Row({ space: 2 }) {
                    Image($r('app.media.icon_headset'))
                      .height(10)
                      .width(10)
                      .objectFit(ImageFit.Contain)
                      .draggable(false)
                      .fillColor('#FFFFFF')


                    Text(item?.playCount)
                      .fontColor('#FFFFFF')
                      .fontSize(10)
                      .fontWeight(900)
                      .textShadow({
                        color: '#66000000',
                        radius: 3
                      })
                  }.margin({ top: 6, left: 6 })
                }

                if (item?.coverTitle) {
                  Text(item?.coverTitle)
                    .fontColor('#FFFFFF')
                    .fontSize(14)
                    .fontWeight(900)
                    .width(100)
                    .height(100)
                    .textAlign(TextAlign.Center)
                    .lineHeight('100%')
                    .maxLines(2)
                }

                // 按钮
                if (item.resourceId && item.resourceType) {
                  MusicPlayBtn({
                    avQueueId: item.resourceId,
                    color: '#FFFFFF'
                  })
                    .width(18)
                    .height(18)
                    .margin({
                      left: 77,
                      top: 77
                    }).onClick((e) => {
                    if (item.resourceId && item.resourceType) {
                      if (item.resourceId.indexOf('CITY_STYLE_SONG_CHART') >= 0) {
                        getPlayer()?.start((item?.playBtn?.playAction?.songIds || [])?.join(',') || '', 'ids', {
                          avQueueName: item?.name?.replace(/\s/ig, ''),
                          songId: String(item.playBtn?.playAction?.songIds?.[0] || '')
                        })
                      } else {
                        getPlayer()?.start(item.resourceId, item.resourceType)

                      }
                    }
                  })
                }

              }
              .alignContent(Alignment.TopStart)
              .borderRadius(8)
              .clip(true)

              // 歌单名称

              Text(item.title)
                .margin({ top: 6 })
                .width(100)
                .maxLines(2)
                .fontSize(12)
            }

            .onClick(() => {
              if (item.resourceId) {
                if (item.resourceId.indexOf('CITY_STYLE_SONG_CHART') >= 0) {
                  const detail: Playlist = {
                    trackIds: (item?.playBtn?.playAction?.songIds || []).map(id => ({
                      id
                    } as TrackId)),
                    backgroundCoverUrl: item.coverImg,
                    tracks: [],
                    detailPageTitle: item.coverTitle,
                    description: item.title,
                    name: item.name
                  }
                  const param: Record<string, string | Playlist> =
                    {
                      'id': item.resourceId,
                      'type': 'detail',
                      'detail': detail
                    };
                  this.pathStack.pushPathByName('Playlist', param)
                } else {

                  const param: Record<string, string> = { 'id': item.resourceId, 'type': 'id' }
                  this.pathStack.pushPathByName('Playlist', param)
                }
              }
            })

          }
        })

        ListItem().width(PageSpace - ListSpace) // 占位

      }
      .width('100%')
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
    }
  }
}
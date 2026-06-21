import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ContinuationState } from '../common/ContinuationState';
import {
  Breakpoint,
  BreakpointConstants,
  BreakpointObserver,
  ResponsiveStyle
} from '../common/BreakpointConstants';

interface RouteParams {
  inputValid: boolean;
  qqNumber?: string;
}

@Entry
@Component
struct VideoPage {
  @State inputValid: boolean = false;
  @State isPlaying: boolean = false;
  @StorageLink('currentBreakpoint') currentBp: Breakpoint = Breakpoint.SM;
  videoController: VideoController = new VideoController();
  private observer: BreakpointObserver = new BreakpointObserver();

  aboutToAppear(): void {
    // 尝试从路由参数获取
    const params = router.getParams() as RouteParams;
    if (params && params.inputValid) {
      this.inputValid = params.inputValid;
    }

    // 检查是否由迁移恢复启动
    if (ContinuationState.isRestored) {
      const data = ContinuationState.get();
      console.info('[VideoPage] 迁移恢复, currentPage: ' + data.currentPage);
      if (data.currentPage === 'pages/VideoPage') {
        this.inputValid = true;
      }
      ContinuationState.reset();
    }

    // 监听断点变化
    this.observer.init(this.getUIContext(), (bp: Breakpoint) => {
      AppStorage.setOrCreate('currentBreakpoint', bp);
    });
  }

  goBack(): void {
    router.back();
  }

  /** 获取视频页面专用样式 */
  private style(): ResponsiveStyle {
    return BreakpointConstants.getVideoPageStyle(this.currentBp);
  }

  /** 保存当前状态到迁移存储 */
  onPageShow(): void {
    ContinuationState.save({
      currentPage: 'pages/VideoPage',
      qqNumber: '',
      timestamp: Date.now()
    });
  }

  build() {
    if (this.inputValid) {
      // 验证通过 —— 显示视频播放器
      this.videoPlayerView();
    } else {
      // 验证未通过 —— 错误提示
      this.errorView();
    }
  }

  /** 视频播放区域 */
  @Builder
  videoPlayerView() {
    Scroll() {
      Column() {
        // 顶部导航
        this.topNavBar()

        // 流转提示条
        Row({ space: 6 }) {
          Text('↔')
            .fontSize(16)
            .fontColor('#007DFF')
          Text('支持跨设备流转：在另一设备Dock栏点击图标可继续观看')
            .fontSize(this.style().captionFontSize)
            .fontColor('#007DFF')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8, bottom: 8 })
        .backgroundColor('#E8F4FD')
        .borderRadius(8)
        .margin({ bottom: this.style().spacing * 0.5 })

        // 内容区：宽屏横排 / 窄屏竖排
        if (this.style().isWideLayout) {
          // =========== 大屏：左右分栏 ===========
          Row({ space: this.style().spacing }) {
            // 左侧：视频
            Column({ space: this.style().spacing * 0.5 }) {
              this.videoComponent()
              this.playbackControls()
            }
            .layoutWeight(3)

            // 右侧：诈骗信息 + 提示
            Column({ space: this.style().spacing }) {
              this.warningCard()
            }
            .layoutWeight(2)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        } else {
          // =========== 小屏：竖排 ===========
          Column({ space: this.style().spacing * 0.6 }) {
            this.videoComponent()
            this.playbackControls()
            this.warningCard()
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .padding({
        left: this.style().contentPadding,
        right: this.style().contentPadding
      })
      .constraintSize({ maxWidth: this.style().maxWidth })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .scrollBar(BarState.Auto)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** 顶部导航栏 */
  @Builder
  topNavBar() {
    Row({ space: 20 }) {
      Button('←')
        .width(40)
        .height(40)
        .fontSize(20)
        .fontColor(Color.White)
        .backgroundColor('#007DFF')
        .borderRadius(20)
        .onClick(() => {
          this.goBack();
        })

      Text('网络安全反诈宣传')
        .fontSize(this.style().titleFontSize * 0.7)
        .fontWeight(FontWeight.Bold)
        .fontColor('#D32F2F')
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ top: 40, bottom: 20 })
  }

  /** 视频组件 */
  @Builder
  videoComponent() {
    Column({ space: this.style().spacing * 0.4 }) {
      Text('你被骗了')
        .fontSize(this.style().bodyFontSize + 4)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)

      Video({
        src: $rawfile('video.mp4'),
        controller: this.videoController
      })
        .width(this.style().videoWidthPercent)
        .height(this.style().videoHeight)
        .backgroundColor('#000000')
        .controls(true)
        .autoPlay(false)
        .loop(false)
        .muted(false)
        .objectFit(ImageFit.Contain)
        .onStart(() => {
          console.info('视频开始播放');
          this.isPlaying = true;
        })
        .onPause(() => {
          console.info('视频暂停');
          this.isPlaying = false;
        })
        .onFinish(() => {
          console.info('视频播放完成');
          this.isPlaying = false;
        })
        .onError(() => {
          console.error('视频播放错误');
          promptAction.showToast({
            message: '反诈视频播放失败，请检查视频文件',
            duration: 3000
          });
        })
        .onPrepared((event) => {
          console.info('视频准备完成，时长：' + event.duration + '秒');
          try {
            this.videoController.start();
            this.isPlaying = true;
          } catch (e) {
            console.error('start调用失败: ' + e);
          }
        })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }

  /** 播放控制按钮 */
  @Builder
  playbackControls() {
    Column({ space: this.style().spacing * 0.3 }) {
      // 状态指示
      Text(this.isPlaying ? '▶ 播放中...' : '⏸ 未播放')
        .fontSize(this.style().bodyFontSize)
        .fontColor(this.isPlaying ? '#007DFF' : '#666666')
        .fontWeight(FontWeight.Medium)

      // 控制按钮
      Row({ space: this.style().spacing }) {
        Button('播放', { type: ButtonType.Normal })
          .width(this.style().buttonWidth * 0.45)
          .height(this.style().buttonHeight * 0.75)
          .fontSize(this.style().buttonFontSize * 0.8)
          .backgroundColor('#34C759')
          .fontColor(Color.White)
          .borderRadius(this.style().borderRadius * 0.7)
          .onClick(() => {
            try {
              this.videoController.start();
              this.isPlaying = true;
            } catch (e) {
              console.error('播放失败: ' + e);
            }
          })

        Button('暂停', { type: ButtonType.Normal })
          .width(this.style().buttonWidth * 0.45)
          .height(this.style().buttonHeight * 0.75)
          .fontSize(this.style().buttonFontSize * 0.8)
          .backgroundColor('#FF9500')
          .fontColor(Color.White)
          .borderRadius(this.style().borderRadius * 0.7)
          .onClick(() => {
            try {
              this.videoController.pause();
              this.isPlaying = false;
            } catch (e) {
              console.error('暂停失败: ' + e);
            }
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .margin({ top: this.style().spacing, bottom: this.style().spacing * 0.5 })
    .width('100%')
  }

  /** 安全警告卡 */
  @Builder
  warningCard() {
    Column({ space: this.style().spacing * 0.4 }) {
      Text('⚠️ 重要提醒：您刚刚输入了QQ号！')
        .fontSize(this.style().bodyFontSize)
        .fontColor('#D32F2F')
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)

      Divider()
        .strokeWidth(1)
        .color('#E0E0E0')
        .margin({ top: 4, bottom: 4 })

      Text('在网络上随意输入个人信息存在安全风险')
        .fontSize(this.style().captionFontSize + 1)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .width('90%')

      Text('请提高个人信息安全意识，谨防网络诈骗')
        .fontSize(this.style().captionFontSize + 1)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .width('90%')

      Divider()
        .strokeWidth(1)
        .color('#E0E0E0')
        .margin({ top: 4, bottom: 4 })

      Text('视频内容：个人信息保护与反诈骗知识')
        .fontSize(this.style().captionFontSize)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(this.style().contentPadding * 0.8)
    .backgroundColor('#FFF3E0')
    .borderRadius(this.style().borderRadius)
    .margin({ top: this.style().spacing })
  }

  /** 验证失败错误页 */
  @Builder
  errorView() {
    Column({ space: 20 }) {
      Text('🔒')
        .fontSize(80)
        .margin({ bottom: 20 })

      Text('安全验证失败')
        .fontSize(this.style().titleFontSize * 0.75)
        .fontColor('#D32F2F')
        .fontWeight(FontWeight.Bold)

      Text('请输入完整的10位QQ号以继续')
        .fontSize(this.style().bodyFontSize)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      Text('这是为了保护您的个人信息安全')
        .fontSize(this.style().captionFontSize + 1)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })

      Button('返回重新输入', { type: ButtonType.Capsule })
        .width(this.style().buttonWidth)
        .height(this.style().buttonHeight)
        .fontSize(this.style().buttonFontSize)
        .fontColor(Color.White)
        .backgroundColor('#1A73E8')
        .onClick(() => {
          this.goBack();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .padding({ left: this.style().contentPadding, right: this.style().contentPadding })
  }
}

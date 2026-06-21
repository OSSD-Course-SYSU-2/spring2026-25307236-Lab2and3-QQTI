import router from '@ohos.router';
import { ContinuationState } from '../common/ContinuationState';
import {
  Breakpoint,
  BreakpointConstants,
  BreakpointObserver,
  ResponsiveStyle
} from '../common/BreakpointConstants';

@Entry
@Component
struct Index {
  @State inputText: string = '';
  @State errorMessage: string = '';
  @StorageLink('currentBreakpoint') currentBp: Breakpoint = Breakpoint.SM;
  private observer: BreakpointObserver = new BreakpointObserver();

  aboutToAppear(): void {
    this.observer.init(this.getUIContext(), (bp: Breakpoint) => {
      AppStorage.setOrCreate('currentBreakpoint', bp);
    });

    // 检查是否由迁移恢复启动，恢复QQ号
    if (ContinuationState.isRestored) {
      const data = ContinuationState.get();
      if (data.qqNumber) {
        this.inputText = data.qqNumber;
        console.info('[Index] 迁移恢复 QQ号: ' + data.qqNumber);
      }
      ContinuationState.reset();
    }
  }

  /** 获取当前断点的样式 */
  private style(): ResponsiveStyle {
    return BreakpointConstants.getResponsiveStyle(this.currentBp);
  }

  /** 验证输入是否为10位数字 */
  validateInput(): boolean {
    return this.inputText.length === 10;
  }

  /** 保存当前状态到迁移存储 */
  private saveContinuationState(): void {
    ContinuationState.save({
      currentPage: 'pages/Index',
      qqNumber: this.inputText,
      timestamp: Date.now()
    });
  }

  /** 跳转到视频播放页面 */
  handleConfirm(): void {
    if (this.validateInput()) {
      this.errorMessage = '';
      this.saveContinuationState();
      router.pushUrl({
        url: 'pages/VideoPage',
        params: {
          inputValid: true,
          qqNumber: this.inputText
        }
      });
    } else {
      this.errorMessage = '请输入10位QQ号码';
    }
  }

  /** 输入变化处理：只允许数字，限制10位 */
  handleInputChange(value: string): void {
    const numericValue = value.replace(/[^\d]/g, '');
    if (numericValue.length <= 10) {
      this.inputText = numericValue;
      this.saveContinuationState();
    }
  }

  build() {
    Scroll() {
      Column() {
        // ======================== 标题 ========================
        Text('QQTI分析系统')
          .fontSize(this.style().titleFontSize)
          .fontWeight(FontWeight.Bold)
          .margin({ top: this.style().contentPadding * 2, bottom: this.style().spacing })
          .fontColor('#1A73E8')

        // ======================== 流转提示条 ========================
        Row({ space: 8 }) {
          Text('↔')
            .fontSize(18)
            .fontColor('#007DFF')
          Text('支持跨设备流转：在另一设备Dock栏点击应用图标即可接续')
            .fontSize(this.style().captionFontSize)
            .fontColor('#007DFF')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8, bottom: 4 })
        .backgroundColor('#E8F4FD')
        .borderRadius(8)
        .margin({ bottom: this.style().spacing * 0.5 })

        // ======================== 输入区域 ========================
        Column({ space: this.style().spacing * 0.6 }) {
          Text('请输入您的QQ号（不足10位后面补0）')
            .fontSize(this.style().bodyFontSize + 2)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: this.style().spacing * 0.4 })

          // 输入框
          TextInput({ placeholder: '请输入10位QQ号码', text: this.inputText })
            .placeholderColor('#999999')
            .placeholderFont({ size: this.style().bodyFontSize })
            .fontSize(this.style().bodyFontSize + 2)
            .fontColor(Color.Black)
            .backgroundColor('#F8F9FA')
            .borderRadius(this.style().borderRadius)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 20, right: 20, top: 14, bottom: 14 })
            .margin({ bottom: 8 })
            .width('100%')
            .maxLength(10)
            .type(InputType.Number)
            .onChange((value: string) => {
              this.handleInputChange(value);
            })

          // 长度提示
          Row({ space: 8 }) {
            Text('当前长度:')
              .fontSize(this.style().captionFontSize + 1)
              .fontColor('#666666')
            Text(this.inputText.length.toString())
              .fontSize(this.style().captionFontSize + 1)
              .fontColor(this.inputText.length === 10 ? '#34C759' : '#FF9500')
              .fontWeight(FontWeight.Bold)
            Text('/10')
              .fontSize(this.style().captionFontSize + 1)
              .fontColor('#666666')
          }
          .margin({ bottom: 4 })

          // 错误提示
          if (this.errorMessage) {
            Row({ space: 8 }) {
              Text('⚠️').fontSize(this.style().bodyFontSize)
              Text(this.errorMessage)
                .fontSize(this.style().bodyFontSize)
                .fontColor(Color.Red)
            }
            .justifyContent(FlexAlign.Center)
          }

          // 分析按钮
          Button('开始人格分析', { type: ButtonType.Capsule })
            .width(this.style().buttonWidth)
            .height(this.style().buttonHeight)
            .fontSize(this.style().buttonFontSize)
            .fontColor(Color.White)
            .backgroundColor(this.inputText.length === 10 ? '#1A73E8' : '#CCCCCC')
            .margin({ top: this.style().spacing * 0.5 })
            .enabled(this.inputText.length === 10)
            .onClick(() => {
              this.handleConfirm();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // ======================== 说明区域 ========================
        Column({ space: this.style().spacing * 0.5 }) {
          Text('📊 测试说明')
            .fontSize(this.style().bodyFontSize + 2)
            .fontColor('#1A73E8')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 6 })

          this.instructionItem('1. 请输入您的10位QQ号码进行人格类型分析')
          this.instructionItem('2. 系统将根据QQ号分析您的性格特点')
          this.instructionItem('3. 测试结果仅供娱乐参考')
          this.instructionItem('4. 如有雷同阿哈全责')
          this.instructionItem('5. 本应用支持跨设备流转，可在手机/平板间无缝接续')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: this.style().spacing * 1.5 })
        .padding({
          top: this.style().spacing * 0.8,
          bottom: this.style().spacing * 0.8,
          left: this.style().contentPadding * 0.8,
          right: this.style().contentPadding * 0.8
        })
        .backgroundColor('#E8F4FD')
        .borderRadius(this.style().borderRadius)

        // ======================== 底部信息 ========================
        Column({ space: 4 }) {
          Text('🎯')
            .fontSize(this.style().isWideLayout ? 60 : 50)
            .margin({ bottom: 8 })
            .opacity(0.7)

          Text('基于QQ号的人格类型分析系统')
            .fontSize(this.style().bodyFontSize)
            .fontColor('#1A73E8')
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)

          Text('通过算法分析QQ号数字特征，揭示性格特点')
            .fontSize(this.style().captionFontSize)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)

          Text('分析结果将以个性化视频形式呈现')
            .fontSize(this.style().captionFontSize)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: this.style().spacing, bottom: this.style().spacing })
        .margin({ top: this.style().spacing })
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
    .align(Alignment.Top)
  }

  @Builder
  instructionItem(text: string) {
    Text(text)
      .fontSize(this.style().captionFontSize + 1)
      .fontColor('#666666')
      .textAlign(TextAlign.Start)
      .width('100%')
  }
}

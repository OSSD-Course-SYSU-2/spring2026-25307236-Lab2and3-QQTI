import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ContinuationState } from '../common/ContinuationState';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // 检查是否为迁移启动
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      ContinuationState.isRestored = true;
      // 从 want.parameters 恢复迁移数据
      if (want.parameters) {
        const params = want.parameters as Record<string, Object>;
        ContinuationState.save({
          currentPage: (params.currentPage as string) || 'pages/Index',
          qqNumber: (params.qqNumber as string) || '',
          timestamp: (params.timestamp as number) || Date.now()
        });
        hilog.info(DOMAIN, 'testTag', `迁移恢复数据: ${JSON.stringify(ContinuationState.get())}`);
      }
    }

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 正常冷启动加载主页面
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s',
          JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  /**
   * 迁移恢复 —— 当应用从其他设备迁移到本设备时触发
   * 注意：迁移时不走 onWindowStageCreate，只走 onWindowStageRestore
   */
  onWindowStageRestore(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', 'onWindowStageRestore - 从其他设备迁移恢复');

    // 读取迁移数据
    const data = ContinuationState.get();
    const targetPage = data.currentPage || 'pages/Index';
    hilog.info(DOMAIN, 'testTag', `恢复页面: ${targetPage}`);

    // 迁移恢复时加载目标页面
    windowStage.loadContent(targetPage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load content in onWindowStageRestore. Cause: %{public}s',
          JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in restoring content.');
    });
  }

  /**
   * 迁移保存 —— 系统发起迁移时回调，保存当前页面状态
   * wantParam 中传递的数据需控制在 100KB 以下
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    const data = ContinuationState.get();
    hilog.info(DOMAIN, 'testTag', `onContinue - 保存迁移数据: ${JSON.stringify(data)}`);

    // 将迁移数据写入 wantParam，由系统传递给目标设备
    wantParam.currentPage = data.currentPage;
    wantParam.qqNumber = data.qqNumber;
    wantParam.timestamp = Date.now();

    return AbilityConstant.OnContinueResult.AGREE;
  }

  /**
   * onNewWant —— 处理已运行应用收到新 Want（如迁移热启动）
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', `onNewWant, launchReason: ${launchParam.launchReason}`);

    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      ContinuationState.isRestored = true;
      if (want.parameters) {
        const params = want.parameters as Record<string, Object>;
        ContinuationState.save({
          currentPage: (params.currentPage as string) || 'pages/Index',
          qqNumber: (params.qqNumber as string) || '',
          timestamp: (params.timestamp as number) || Date.now()
        });
      }
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}

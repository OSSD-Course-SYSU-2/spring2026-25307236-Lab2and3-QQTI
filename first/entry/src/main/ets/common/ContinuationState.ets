/**
 * 跨端迁移状态管理
 * 用于在 EntryAbility 和页面之间传递迁移数据
 */
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';

export interface ContinuationData {
  /** 当前页面路径 */
  currentPage: string;
  /** QQ号输入值 */
  qqNumber: string;
  /** 时间戳 */
  timestamp: number;
}

export class ContinuationState {
  /** 迁移数据 */
  static data: ContinuationData = {
    currentPage: 'pages/Index',
    qqNumber: '',
    timestamp: 0
  };

  /** 是否是迁移启动 */
  static isRestored: boolean = false;

  /** 保存迁移数据 */
  static save(data: ContinuationData): void {
    ContinuationState.data = data;
    console.info('[ContinuationState] 保存迁移数据: ' + JSON.stringify(data));
  }

  /** 获取迁移数据 */
  static get(): ContinuationData {
    return ContinuationState.data;
  }

  /** 重置迁移标记 */
  static reset(): void {
    ContinuationState.isRestored = false;
    ContinuationState.data = {
      currentPage: 'pages/Index',
      qqNumber: '',
      timestamp: 0
    };
  }
}

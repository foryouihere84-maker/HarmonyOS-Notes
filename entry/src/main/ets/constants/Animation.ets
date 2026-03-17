/**
 * 动画规范常量定义
 * 遵循开发规则文档第5.7节交互动画规范
 * 
 * @author 开发者
 * @date 2026-03-12
 */

/**
 * 动画规范类
 * 定义应用中使用的所有动画相关常量
 */
export class Animation {
  // 动画时长
  public static readonly DURATION_FAST: number = 150;   // 快速动画
  public static readonly DURATION_NORMAL: number = 200;  // 正常动画
  public static readonly DURATION_SLOW: number = 300;   // 慢速动画
  public static readonly DURATION_SLOWER: number = 500;  // 更慢动画
  
  // 页面切换动画时长
  public static readonly PAGE_TRANSITION_DURATION: number = 300;
  
  // 列表项展开/收起动画时长
  public static readonly LIST_ITEM_DURATION: number = 200;
  
  // 按钮点击动画时长
  public static readonly BUTTON_CLICK_DURATION: number = 150;
  
  // 对话框动画时长
  public static readonly DIALOG_DURATION: number = 250;
  
  // 加载动画时长
  public static readonly LOADING_DURATION: number = 1000;
  
  // 动画曲线
  public static readonly CURVE_EASE_IN_OUT: string = 'ease-in-out';
  public static readonly CURVE_EASE_IN: string = 'ease-in';
  public static readonly CURVE_EASE_OUT: string = 'ease-out';
  public static readonly CURVE_LINEAR: string = 'linear';
  public static readonly CURVE_SPRING: string = 'spring';
  
  // 按钮点击缩放比例
  public static readonly BUTTON_CLICK_SCALE: number = 0.95;
  public static readonly BUTTON_HOVER_SCALE: number = 1.05;
  
  // 页面切换透明度
  public static readonly PAGE_TRANSITION_OPACITY_START: number = 0;
  public static readonly PAGE_TRANSITION_OPACITY_END: number = 1;
  
  // 列表项滑动距离
  public static readonly LIST_ITEM_SLIDE_DISTANCE: number = 100;
  
  // 对话框缩放比例
  public static readonly DIALOG_SCALE_START: number = 0.9;
  public static readonly DIALOG_SCALE_END: number = 1;
  
  // 加载进度条颜色
  public static readonly LOADING_COLOR: string = '#0078D4';
  
  // 错误提示震动时长
  public static readonly ERROR_VIBRATION_DURATION: number = 200;
  
  // 成功提示动画时长
  public static readonly SUCCESS_DURATION: number = 2000;
  
  // Toast显示时长
  public static readonly TOAST_DURATION_SHORT: number = 1500;
  public static readonly TOAST_DURATION_NORMAL: number = 2000;
  public static readonly TOAST_DURATION_LONG: number = 3000;
}

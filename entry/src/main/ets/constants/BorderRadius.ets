/**
 * 圆角规范常量定义
 * 遵循开发规则文档第5.5节圆角规范
 * 
 * @author 开发者
 * @date 2026-03-12
 */

/**
 * 圆角规范类
 * 定义应用中使用的所有圆角常量
 */
export class BorderRadius {
  // 基础圆角
  public static readonly RADIUS_XS: number = 4;    // 小圆角
  public static readonly RADIUS_SM: number = 8;    // 小圆角
  public static readonly RADIUS_MD: number = 12;   // 中等圆角
  public static readonly RADIUS_LG: number = 16;   // 大圆角
  public static readonly RADIUS_XL: number = 20;   // 特大圆角
  public static readonly RADIUS_FULL: number = 999; // 完全圆角
  
  // 组件圆角
  public static readonly BUTTON_RADIUS: number = 12;
  public static readonly CARD_RADIUS: number = 16;
  public static readonly DIALOG_RADIUS: number = 20;
  public static readonly INPUT_RADIUS: number = 12;
  public static readonly CHIP_RADIUS: number = 20;
  
  // 列表项圆角
  public static readonly LIST_ITEM_RADIUS: number = 16;
  
  // 头像圆角
  public static readonly AVATAR_RADIUS: number = 999;
  
  // 缩略图圆角
  public static readonly THUMBNAIL_RADIUS: number = 12;
  
  // 图标按钮圆角
  public static readonly ICON_BUTTON_RADIUS: number = 12;
  
  // 浮动按钮圆角
  public static readonly FAB_RADIUS: number = 30;
  
  // 工具栏按钮圆角
  public static readonly TOOLBAR_BUTTON_RADIUS: number = 12;
  
  // 分隔条圆角
  public static readonly DIVIDER_RADIUS: number = 2;
  
  // 待办事项圆角
  public static readonly TODO_CHECKBOX_RADIUS: number = 6;
  public static readonly TODO_ITEM_RADIUS: number = 12;
}

/**
 * 间距规范常量定义
 * 遵循开发规则文档第5.4节间距规范
 * 
 * @author 开发者
 * @date 2026-03-12
 */

/**
 * 间距规范类
 * 定义应用中使用的所有间距常量
 */
export class Spacing {
  // 基础间距
  public static readonly SPACE_XS: number = 4;    // 极小间距
  public static readonly SPACE_SM: number = 8;    // 小间距
  public static readonly SPACE_MD: number = 16;   // 中等间距
  public static readonly SPACE_LG: number = 24;   // 大间距
  public static readonly SPACE_XL: number = 32;   // 特大间距
  public static readonly SPACE_XXL: number = 48;  // 超大间距
  
  // 组件内边距
  public static readonly PADDING_XS: number = 4;
  public static readonly PADDING_SM: number = 8;
  public static readonly PADDING_MD: number = 16;
  public static readonly PADDING_LG: number = 24;
  public static readonly PADDING_XL: number = 32;
  
  // 组件外边距
  public static readonly MARGIN_XS: number = 4;
  public static readonly MARGIN_SM: number = 8;
  public static readonly MARGIN_MD: number = 16;
  public static readonly MARGIN_LG: number = 24;
  public static readonly MARGIN_XL: number = 32;
  
  // 列表项间距
  public static readonly LIST_ITEM_SPACING: number = 10;
  public static readonly LIST_ITEM_PADDING: number = 16;
  
  // 卡片间距
  public static readonly CARD_PADDING: number = 14;
  public static readonly CARD_MARGIN: number = 10;
  
  // 对话框间距
  public static readonly DIALOG_PADDING: number = 24;
  public static readonly DIALOG_MARGIN: number = 28;
  
  // 按钮间距
  public static readonly BUTTON_PADDING_H: number = 20;
  public static readonly BUTTON_PADDING_V: number = 12;
  public static readonly BUTTON_SPACING: number = 12;
  
  // 输入框间距
  public static readonly INPUT_HEIGHT: number = 48;
  public static readonly INPUT_PADDING: number = 16;
  
  // 工具栏间距
  public static readonly TOOLBAR_PADDING: number = 8;
  public static readonly TOOLBAR_BUTTON_SIZE: number = 44;
  
  // 图标按钮间距
  public static readonly ICON_BUTTON_SIZE: number = 44;
  public static readonly ICON_BUTTON_PADDING: number = 12;
  
  // 浮动按钮间距
  public static readonly FAB_SIZE: number = 60;
  public static readonly FAB_MARGIN: number = 20;
  
  // 头部间距
  public static readonly HEADER_HEIGHT: number = 64;
  public static readonly HEADER_PADDING: number = 16;
  public static readonly HEADER_PADDING_V: number = 12;
  
  // 分隔线间距
  public static readonly DIVIDER_HEIGHT: number = 1;
  public static readonly DIVIDER_MARGIN: number = 24;
  
  // 头像间距
  public static readonly AVATAR_SIZE_SM: number = 32;
  public static readonly AVATAR_SIZE_MD: number = 44;
  public static readonly AVATAR_SIZE_LG: number = 60;
  public static readonly AVATAR_SIZE_XL: number = 100;
  
  // 缩略图间距
  public static readonly THUMBNAIL_SIZE_SM: number = 60;
  public static readonly THUMBNAIL_SIZE_MD: number = 100;
  public static readonly THUMBNAIL_SIZE_LG: number = 200;
  
  // 阴影相关
  public static readonly SHADOW_RADIUS: number = 8;
  public static readonly SHADOW_RADIUS_LG: number = 12;
  public static readonly SHADOW_RADIUS_XL: number = 20;
  public static readonly SHADOW_OFFSET: number = 2;
  public static readonly SHADOW_OFFSET_LG: number = 4;
  public static readonly SHADOW_OFFSET_XL: number = 10;
  
  // 刷新相关
  public static readonly REFRESH_OFFSET: number = 60;
  public static readonly REFRESH_FRICTION: number = 80;
  static SPACING_SMALL: Length | undefined;
  static SPACING_LARGE: Length | Padding | LocalizedPadding;
  static SPACING_MEDIUM: Length | undefined;
  static SM: Length | LengthMetrics | undefined;
}

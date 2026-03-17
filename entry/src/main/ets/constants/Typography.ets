/**
 * 字体规范常量定义
 * 遵循开发规则文档第5.3节字体规范
 * 
 * @author 开发者
 * @date 2026-03-12
 */

/**
 * 字体规范类
 * 定义应用中使用的所有字体相关常量
 */
export class Typography {
  // 字体大小
  public static readonly FONT_SIZE_XS: number = 12;   // 极小字体
  public static readonly FONT_SIZE_SM: number = 14;   // 小字体
  public static readonly FONT_SIZE_MD: number = 16;   // 中等字体（正文）
  public static readonly FONT_SIZE_LG: number = 18;   // 大字体（副标题）
  public static readonly FONT_SIZE_XL: number = 20;   // 特大字体（标题）
  public static readonly FONT_SIZE_XXL: number = 24;  // 超大字体（主标题）
  public static readonly FONT_SIZE_XXXL: number = 32; // 超超大字体（FAB按钮）
  public static readonly FONT_SIZE_DISPLAY: number = 28; // 展示字体
  
  // 字体粗细
  public static readonly FONT_WEIGHT_LIGHT: number = 300;
  public static readonly FONT_WEIGHT_NORMAL: number = 400;
  public static readonly FONT_WEIGHT_MEDIUM: number = 500;
  public static readonly FONT_WEIGHT_BOLD: number = 700;
  
  // 行高
  public static readonly LINE_HEIGHT_TIGHT: number = 1.2;
  public static readonly LINE_HEIGHT_NORMAL: number = 1.5;
  public static readonly LINE_HEIGHT_LOOSE: number = 1.8;
  public static readonly LINE_HEIGHT_MD: number = 20;   // 中等行高
  public static readonly LINE_HEIGHT_LG: number = 22;  // 大行高
  
  // 字母间距
  public static readonly LETTER_SPACING_TIGHT: number = -0.5;
  public static readonly LETTER_SPACING_NORMAL: number = 0;
  public static readonly LETTER_SPACING_WIDE: number = 0.5;
  
  // 编辑器字体大小范围
  public static readonly EDITOR_FONT_SIZE_MIN: number = 24;
  public static readonly EDITOR_FONT_SIZE_MAX: number = 54;
  public static readonly EDITOR_FONT_SIZE_DEFAULT: number = 36;
  public static readonly EDITOR_FONT_SIZE_STEP: number = 2;
  
  // 特殊字体大小
  public static readonly ICON_SIZE_SM: number = 16;
  public static readonly ICON_SIZE_MD: number = 20;
  public static readonly ICON_SIZE_LG: number = 24;
  public static readonly ICON_SIZE_XL: number = 28;
  public static readonly ICON_SIZE_XXL: number = 32;
  
  // 表情符号大小
  public static readonly EMOJI_SIZE_MD: number = 48;
  public static readonly EMOJI_SIZE_LG: number = 64;
  public static readonly EMOJI_SIZE_XL: number = 96;
}

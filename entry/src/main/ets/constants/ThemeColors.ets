import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';

export class ThemeColors {
  public static readonly PRIMARY: string = '#6366f1';
  public static readonly PRIMARY_LIGHT: string = '#818cf8';
  public static readonly PRIMARY_DARK: string = '#4f46e5';
  
  public static readonly GRADIENT_PURPLE_START: string = '#6366f1';
  public static readonly GRADIENT_PURPLE_END: string = '#8b5cf6';
  public static readonly GRADIENT_BLUE_START: string = '#3b82f6';
  public static readonly GRADIENT_BLUE_END: string = '#06b6d4';
  public static readonly GRADIENT_GREEN_START: string = '#10b981';
  public static readonly GRADIENT_GREEN_END: string = '#34d399';
  public static readonly GRADIENT_ORANGE_START: string = '#f59e0b';
  public static readonly GRADIENT_ORANGE_END: string = '#fbbf24';
  public static readonly GRADIENT_PINK_START: string = '#ec4899';
  public static readonly GRADIENT_PINK_END: string = '#f472b6';
  public static readonly GRADIENT_CYAN_START: string = '#06b6d4';
  public static readonly GRADIENT_CYAN_END: string = '#22d3d3';
  
  public static readonly WHITE: string = '#FFFFFF';
  public static readonly GRAY_50: string = '#F8F9FA';
  public static readonly GRAY_100: string = '#F1F3F4';
  public static readonly GRAY_200: string = '#E8EAED';
  public static readonly GRAY_300: string = '#DADCE0';
  public static readonly GRAY_500: string = '#9AA0A6';
  public static readonly GRAY_700: string = '#5F6368';
  public static readonly GRAY_900: string = '#202124';
  public static readonly TRANSPARENT: string = 'transparent';
  
  public static readonly DARK_BG_PRIMARY: string = '#0F172A';
  public static readonly DARK_BG_SECONDARY: string = '#1E293B';
  public static readonly DARK_BG_TERTIARY: string = '#334155';
  public static readonly DARK_TEXT_PRIMARY: string = '#F1F5F9';
  public static readonly DARK_TEXT_SECONDARY: string = '#94A3B8';
  public static readonly DARK_TEXT_TERTIARY: string = '#64748B';
  public static readonly DARK_BORDER: string = '#334155';
  public static readonly DARK_DIVIDER: string = '#1E293B';
  
  public static readonly LIGHT_BG_PRIMARY: string = '#FFFFFF';
  public static readonly LIGHT_BG_SECONDARY: string = '#FAFAFA';
  public static readonly LIGHT_BG_TERTIARY: string = '#F5F3FF';
  public static readonly LIGHT_TEXT_PRIMARY: string = '#1F2937';
  public static readonly LIGHT_TEXT_SECONDARY: string = '#4B5563';
  public static readonly LIGHT_TEXT_TERTIARY: string = '#9CA3AF';
  public static readonly LIGHT_BORDER: string = '#E5E7EB';
  public static readonly LIGHT_DIVIDER: string = '#F3F4F6';
  public static readonly LIGHT_CARD_BG: string = '#FFFFFF';
  public static readonly LIGHT_INPUT_BG: string = '#F5F3FF';
  
  public static readonly SUCCESS: string = '#10b981';
  public static readonly SUCCESS_LIGHT: string = '#F6FFED';
  public static readonly WARNING: string = '#f59e0b';
  public static readonly ERROR: string = '#ef4444';
  public static readonly INFO: string = '#6366f1';
  
  public static readonly TEXT_PRIMARY: string = '#F1F5F9';
  public static readonly TEXT_SECONDARY: string = '#94A3B8';
  public static readonly TEXT_TERTIARY: string = '#64748B';
  public static readonly TEXT_DISABLED: string = '#475569';
  
  public static readonly BACKGROUND_PRIMARY: string = '#0F172A';
  public static readonly BACKGROUND_SECONDARY: string = '#0F172A';
  public static readonly BACKGROUND_TERTIARY: string = '#1E293B';
  public static readonly BACKGROUND_DISABLED: string = '#1E293B';
  
  public static readonly BORDER_COLOR: string = '#334155';
  public static readonly DIVIDER_COLOR: string = '#1E293B';
  
  public static readonly SHADOW_COLOR: string = '#00000020';
  public static readonly SHADOW_COLOR_DARK: string = '#00000040';
  public static readonly SHADOW_COLOR_PRIMARY: string = '#6366f140';
  
  public static readonly NOTEBOOK_COLORS: string[] = [
    '#6366f1', '#3b82f6', '#10b981', '#f59e0b',
    '#ec4899', '#06b6d4', '#8b5cf6', '#f472b6'
  ];
  
  public static readonly PAGE_BACKGROUND_COLORS: string[] = [
    '#FFFFFF',
    '#FFF9E6',
    '#E6F7FF',
    '#F6FFED',
    '#FFF0F6',
    '#F0F5FF',
    '#FFF2E8',
    '#F9F0FF',
    '#E8F8F5',
    '#FAFAFA',
    '#F5F5F5',
    '#EEEEEE'
  ];
  
  public static readonly TODO_CHECKED: string = '#10b981';
  public static readonly TODO_UNCHECKED: string = '#334155';
  public static readonly TODO_CHECKED_BG: string = '#F6FFED';
  public static readonly TODO_BORDER: string = '#334155';
  
  public static getColors(): ThemeColorsInterface {
    return ThemeManager.getInstance().getColors();
  }
  
  public static get isLight(): boolean {
    return ThemeManager.getInstance().isLightTheme();
  }
  
  public static get isDark(): boolean {
    return ThemeManager.getInstance().isDarkTheme();
  }
}

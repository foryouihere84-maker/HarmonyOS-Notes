import { Logger } from '../utils/Logger';

export type ThemeMode = 'light' | 'dark' | 'auto';
export type ActualTheme = 'light' | 'dark';

export interface ThemeColorsInterface {
  PRIMARY: string;
  PRIMARY_LIGHT: string;
  PRIMARY_DARK: string;
  
  BACKGROUND_PRIMARY: string;
  BACKGROUND_SECONDARY: string;
  BACKGROUND_TERTIARY: string;
  BACKGROUND_DISABLED: string;
  
  TEXT_PRIMARY: string;
  TEXT_SECONDARY: string;
  TEXT_TERTIARY: string;
  TEXT_DISABLED: string;
  
  BORDER_COLOR: string;
  DIVIDER_COLOR: string;
  
  SHADOW_COLOR: string;
  SHADOW_COLOR_DARK: string;
  SHADOW_COLOR_PRIMARY: string;
  
  CARD_BACKGROUND: string;
  INPUT_BACKGROUND: string;
  DIALOG_BACKGROUND: string;
  ERROR: string;
  
  TODO_CHECKED: string;
  TODO_UNCHECKED: string;
  TODO_BORDER: string;
  TODO_CHECKED_BG: string;
  
  SUCCESS: string;
  SUCCESS_LIGHT: string;
  WARNING: string;
  INFO: string;
}

export class ThemeManager {
  private static instance: ThemeManager;
  private static readonly TAG: string = 'ThemeManager';
  
  public static readonly STORAGE_KEY_THEME_MODE = 'themeMode';
  public static readonly STORAGE_KEY_ACTUAL_THEME = 'actualTheme';
  
  private lightColors: ThemeColorsInterface = {
    PRIMARY: '#6366f1',
    PRIMARY_LIGHT: '#818cf8',
    PRIMARY_DARK: '#4f46e5',
    
    BACKGROUND_PRIMARY: '#FFFFFF',
    BACKGROUND_SECONDARY: '#FAFAFA',
    BACKGROUND_TERTIARY: '#F5F3FF',
    BACKGROUND_DISABLED: '#F1F3F4',
    
    TEXT_PRIMARY: '#1F2937',
    TEXT_SECONDARY: '#4B5563',
    TEXT_TERTIARY: '#9CA3AF',
    TEXT_DISABLED: '#D1D5DB',
    
    BORDER_COLOR: '#E5E7EB',
    DIVIDER_COLOR: '#F3F4F6',
    
    SHADOW_COLOR: '#00000010',
    SHADOW_COLOR_DARK: '#00000020',
    SHADOW_COLOR_PRIMARY: '#6366f120',
    
    CARD_BACKGROUND: '#FFFFFF',
    INPUT_BACKGROUND: '#F5F3FF',
    DIALOG_BACKGROUND: '#FFFFFF',
    ERROR: '#EF4444',
    
    TODO_CHECKED: '#10B981',
    TODO_UNCHECKED: '#F3F4F6',
    TODO_BORDER: '#D1D5DB',
    TODO_CHECKED_BG: '#ECFDF5',
    
    SUCCESS: '#10B981',
    SUCCESS_LIGHT: '#F6FFED',
    WARNING: '#F59E0B',
    INFO: '#6366F1'
  };
  
  private darkColors: ThemeColorsInterface = {
    PRIMARY: '#6366f1',
    PRIMARY_LIGHT: '#818cf8',
    PRIMARY_DARK: '#4f46e5',
    
    BACKGROUND_PRIMARY: '#0F172A',
    BACKGROUND_SECONDARY: '#0F172A',
    BACKGROUND_TERTIARY: '#1E293B',
    BACKGROUND_DISABLED: '#1E293B',
    
    TEXT_PRIMARY: '#F1F5F9',
    TEXT_SECONDARY: '#94A3B8',
    TEXT_TERTIARY: '#64748B',
    TEXT_DISABLED: '#475569',
    
    BORDER_COLOR: '#334155',
    DIVIDER_COLOR: '#1E293B',
    
    SHADOW_COLOR: '#00000020',
    SHADOW_COLOR_DARK: '#00000040',
    SHADOW_COLOR_PRIMARY: '#6366f140',
    
    CARD_BACKGROUND: '#1E293B',
    INPUT_BACKGROUND: '#1E293B',
    DIALOG_BACKGROUND: '#1E293B',
    ERROR: '#EF4444',
    
    TODO_CHECKED: '#10B981',
    TODO_UNCHECKED: '#334155',
    TODO_BORDER: '#475569',
    TODO_CHECKED_BG: '#064E3B',
    
    SUCCESS: '#10B981',
    SUCCESS_LIGHT: '#F6FFED',
    WARNING: '#F59E0B',
    INFO: '#6366F1'
  };
  
  private constructor() {
    Logger.i(ThemeManager.TAG, 'ThemeManager initialized');
  }
  
  public static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }
  
  public initialize(themeMode: ThemeMode): void {
    AppStorage.setOrCreate(ThemeManager.STORAGE_KEY_THEME_MODE, themeMode);
    const actualTheme = this.resolveActualTheme(themeMode);
    AppStorage.setOrCreate(ThemeManager.STORAGE_KEY_ACTUAL_THEME, actualTheme);
    Logger.i(ThemeManager.TAG, `Theme initialized: ${themeMode} -> ${actualTheme}`);
  }
  
  public setThemeMode(themeMode: ThemeMode): void {
    AppStorage.setOrCreate(ThemeManager.STORAGE_KEY_THEME_MODE, themeMode);
    const actualTheme = this.resolveActualTheme(themeMode);
    AppStorage.setOrCreate(ThemeManager.STORAGE_KEY_ACTUAL_THEME, actualTheme);
    Logger.i(ThemeManager.TAG, `Theme changed: ${themeMode} -> ${actualTheme}`);
  }
  
  public getThemeMode(): ThemeMode {
    return AppStorage.get<ThemeMode>(ThemeManager.STORAGE_KEY_THEME_MODE) || 'light';
  }
  
  public getActualTheme(): ActualTheme {
    return AppStorage.get<ActualTheme>(ThemeManager.STORAGE_KEY_ACTUAL_THEME) || 'light';
  }
  
  public getColors(): ThemeColorsInterface {
    const actualTheme = this.getActualTheme();
    return actualTheme === 'light' ? this.lightColors : this.darkColors;
  }
  
  public getLightColors(): ThemeColorsInterface {
    return this.lightColors;
  }
  
  public getDarkColors(): ThemeColorsInterface {
    return this.darkColors;
  }
  
  private resolveActualTheme(themeMode: ThemeMode): ActualTheme {
    if (themeMode === 'auto') {
      return this.getSystemTheme();
    }
    return themeMode;
  }
  
  private getSystemTheme(): ActualTheme {
    try {
      const systemColorMode = AppStorage.get<string>('systemColorMode');
      if (systemColorMode === 'dark') {
        return 'dark';
      }
      return 'light';
    } catch (error) {
      Logger.e(ThemeManager.TAG, `Failed to get system theme: ${error}`);
      return 'light';
    }
  }
  
  public onSystemThemeChange(systemColorMode: string): void {
    const currentThemeMode = this.getThemeMode();
    if (currentThemeMode === 'auto') {
      const actualTheme: ActualTheme = systemColorMode === 'dark' ? 'dark' : 'light';
      AppStorage.setOrCreate(ThemeManager.STORAGE_KEY_ACTUAL_THEME, actualTheme);
      Logger.i(ThemeManager.TAG, `System theme changed: ${systemColorMode} -> ${actualTheme}`);
    }
  }
  
  public isLightTheme(): boolean {
    return this.getActualTheme() === 'light';
  }
  
  public isDarkTheme(): boolean {
    return this.getActualTheme() === 'dark';
  }
}

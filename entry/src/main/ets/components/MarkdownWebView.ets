import { webview } from '@kit.ArkWeb';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { Logger } from '../utils/Logger';

interface GeneratedObjectLiteralInterface_1 {
  action: string;
  markdown: string;
  isDark: boolean;
}

@Component
export struct MarkdownWebView {
  @Prop markdown: string = '';
  @Prop textColor: string = '#333333';
  @Prop fontSize: number = 15;
  @Prop isDark: boolean = false;
  
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  @State private currentMarkdown: string = '';
  @State private currentIsDark: boolean = false;
  
  private webviewController: webview.WebviewController = new webview.WebviewController();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private static readonly UPDATE_DEBOUNCE_MS = 100;
  private updateTimer: number = -1;
  
  aboutToAppear() {
    this.updateThemeColors();
    this.currentMarkdown = this.markdown;
    this.currentIsDark = this.isDark;
  }
  
  aboutToUpdate() {
    if (this.markdown !== this.currentMarkdown || this.isDark !== this.currentIsDark) {
      this.scheduleUpdate();
    }
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  private scheduleUpdate(): void {
    if (this.updateTimer !== -1) {
      clearTimeout(this.updateTimer);
    }
    
    this.updateTimer = setTimeout(() => {
      this.updateWebView();
    }, MarkdownWebView.UPDATE_DEBOUNCE_MS);
  }
  
  private updateWebView(): void {
    try {
      this.currentMarkdown = this.markdown;
      this.currentIsDark = this.isDark;
      
      const markdown = this.markdown || '';
      const isDark = this.isDark;
      
      const jsCode = `
        (function() {
          if (typeof window.updateMarkdown === 'function') {
            window.updateMarkdown(${JSON.stringify(markdown)}, ${isDark});
          }
        })();
      `;
      
      this.webviewController.runJavaScript(jsCode).catch((error: Error) => {
        Logger.e('MarkdownWebView', `JavaScript 执行失败: ${error.message}`);
      });
    } catch (error) {
      Logger.e('MarkdownWebView', `更新 WebView 异常: ${error}`);
    }
  }
  
  build() {
    Web({ src: $rawfile('markdown_preview.html'), controller: this.webviewController })
      .width('100%')
      .height('100%')
      .domStorageAccess(true)
      .javaScriptAccess(true)
      .fileAccess(true)
      .mixedMode(MixedMode.All)
      .onPageBegin(() => {
        Logger.i('MarkdownWebView', 'WebView 页面开始加载');
      })
      .onPageEnd(() => {
        Logger.i('MarkdownWebView', 'WebView 页面加载完成');
        setTimeout(() => {
          this.updateWebView();
        }, 200);
      })
      .onErrorReceive((event) => {
        Logger.e('MarkdownWebView', `WebView 错误: ${JSON.stringify(event)}`);
      })
  }
}

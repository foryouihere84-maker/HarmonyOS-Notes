import { router } from '@kit.ArkUI';
import { AIService, AIStreamChunk } from '../services/AIService';
import { ThemeColors } from '../constants/ThemeColors';
import { Animation } from '../constants/Animation';
import { AppConstants } from '../constants/AppConstants';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { Logger } from '../utils/Logger';
import { MarkdownText } from '../components/MarkdownText';

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

@Entry
@Component
struct AIChatPage {
  @State private messages: ChatMessage[] = [];
  @State private inputText: string = '';
  @State private isLoading: boolean = false;
  @State private pageOpacity: number = 0;
  @State private sessionId: string = '';
  @State private currentAssistantContent: string = '';
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  private aiService: AIService = AIService.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private scrollScroller: Scroller = new Scroller();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  aboutToAppear() {
    this.updateThemeColors();
    this.sessionId = this.generateSessionId();
    
    animateTo({
      duration: Animation.PAGE_TRANSITION_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.pageOpacity = 1;
    });
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  private sendMessage() {
    const trimmedText = this.inputText.trim();
    if (trimmedText.length === 0 || this.isLoading) {
      return;
    }
    
    const userMessage: ChatMessage = {
      id: `msg_${Date.now()}_user`,
      role: 'user',
      content: trimmedText,
      timestamp: Date.now()
    };
    
    this.messages.push(userMessage);
    this.inputText = '';
    this.isLoading = true;
    this.currentAssistantContent = '';
    
    const assistantMessage: ChatMessage = {
      id: `msg_${Date.now()}_assistant`,
      role: 'assistant',
      content: '',
      timestamp: Date.now()
    };
    
    this.messages.push(assistantMessage);
    
    setTimeout(() => {
      this.scrollScroller.scrollEdge(Edge.Bottom);
    }, 100);
    
    this.aiService.chatStream(
      trimmedText,
      (chunk: AIStreamChunk) => {
        Logger.i('AIChatPage', `收到chunk - content: "${chunk.content}", done: ${chunk.done}`);
        
        if (chunk.content && chunk.content !== 'null') {
          this.currentAssistantContent += chunk.content;
          Logger.i('AIChatPage', `累积内容：${this.currentAssistantContent}`);
          
          const index = this.messages.findIndex(msg => msg.id === assistantMessage.id);
          Logger.i('AIChatPage', `找到消息索引：${index}`);
          
          if (index !== -1) {
            this.messages = this.messages.map((msg, i) => {
              if (i === index) {
                return {
                  id: msg.id,
                  role: msg.role,
                  content: this.currentAssistantContent,
                  timestamp: msg.timestamp
                };
              }
              return msg;
            });
            Logger.i('AIChatPage', `更新消息内容：${this.messages[index].content}`);
          }
        }
        
        if (chunk.done) {
          Logger.i('AIChatPage', 'chunk.done = true，设置 isLoading = false');
          this.isLoading = false;
        }
      },
      () => {
        Logger.i('AIChatPage', '流式传输完成');
        this.isLoading = false;
      },
      (error: string) => {
        Logger.e('AIChatPage', `流式传输错误：${error}`);
        const index = this.messages.findIndex(msg => msg.id === assistantMessage.id);
        if (index !== -1) {
          this.messages = this.messages.map((msg, i) => {
            if (i === index) {
              return {
                id: msg.id,
                role: msg.role,
                content: `抱歉，发生了错误：${error}`,
                timestamp: msg.timestamp
              };
            }
            return msg;
          });
        }
        this.isLoading = false;
      },
      this.sessionId,
      undefined
    );
  }
  
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }
  
  build() {
    Column() {
      this.buildHeader()
      this.buildChatArea()
      this.buildInputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    .opacity(this.pageOpacity)
  }
  
  @Builder
  buildHeader() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Text('←')
          .fontSize(20)
          .fontColor(this.themeColors.TEXT_PRIMARY)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
      .onClick(() => {
        router.back();
      })
      
      Column() {
        Text('AI对话')
          .fontSize(18)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        
        Text('智能助手')
          .fontSize(12)
          .fontColor(this.themeColors.TEXT_TERTIARY)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  buildChatArea() {
    Scroll(this.scrollScroller) {
      Column() {
        if (this.messages.length === 0) {
          this.buildEmptyState()
        } else {
          ForEach(this.messages, (message: ChatMessage) => {
            this.buildMessageBubble(message)
          }, (message: ChatMessage) => `${message.id}_${message.content.length}_${message.timestamp}`)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
  }
  
  @Builder
  buildEmptyState() {
    Column() {
      Text('🤖')
        .fontSize(64)
        .margin({ bottom: 16 })
      
      Text('AI智能助手')
        .fontSize(20)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })
      
      Text('有什么可以帮助您的吗？')
        .fontSize(14)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ bottom: 24 })
      
      Row() {
        this.buildSuggestionButton('帮我写一篇笔记')
        this.buildSuggestionButton('总结我的笔记')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      
      Row() {
        this.buildSuggestionButton('翻译文本')
        this.buildSuggestionButton('优化写作')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  buildSuggestionButton(text: string) {
    Button(text)
      .fontSize(13)
      .fontColor(this.themeColors.TEXT_PRIMARY)
      .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
      .borderRadius(20)
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .onClick(() => {
        this.inputText = text;
      })
  }
  
  @Builder
  buildMessageBubble(message: ChatMessage) {
    Row() {
      if (message.role === 'user') {
        Blank()
      }
      
      Column() {
        Row() {
          if (message.role === 'assistant') {
            Text('🤖')
              .fontSize(20)
              .margin({ right: 8 })
              .flexShrink(0)
          }
          
          if (message.role === 'assistant') {
            Column() {
              MarkdownText({
                markdown: message.content,
                textColor: this.themeColors.TEXT_PRIMARY,
                fontSize: 15
              })
            }
            .constraintSize({ minWidth: 50, maxWidth: '85%' })
            .layoutWeight(1)
          } else {
            Text(message.content)
              .fontSize(15)
              .fontColor(ThemeColors.WHITE)
              .lineHeight(22)
              .constraintSize({ maxWidth: '100%' })
          }
          
          if (message.role === 'user') {
            Text('👤')
              .fontSize(20)
              .margin({ left: 8 })
              .flexShrink(0)
          }
        }
        .padding(12)
        .borderRadius(16)
        .backgroundColor(message.role === 'user' ? this.themeColors.PRIMARY : this.themeColors.BACKGROUND_TERTIARY)
        .alignItems(VerticalAlign.Top)
        
        Text(this.formatTime(message.timestamp))
          .fontSize(11)
          .fontColor(this.themeColors.TEXT_TERTIARY)
          .margin({ top: 4 })
          .opacity(0.7)
      }
      .constraintSize({ maxWidth: '85%' })
      .alignItems(message.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
      
      if (message.role === 'assistant') {
        Blank()
      }
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
  }
  
  @Builder
  buildInputArea() {
    Column() {
      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .layoutWeight(1)
          .height(48)
          .fontSize(15)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(24)
          .placeholderColor(this.themeColors.TEXT_TERTIARY)
          .enabled(!this.isLoading)
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })
        
        Button({ type: ButtonType.Circle }) {
          if (this.isLoading) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(ThemeColors.WHITE)
          } else {
            Text('➤')
              .fontSize(18)
              .fontColor(ThemeColors.WHITE)
          }
        }
        .width(48)
        .height(48)
        .backgroundColor(this.inputText.trim().length > 0 && !this.isLoading ? this.themeColors.PRIMARY : this.themeColors.TEXT_TERTIARY)
        .margin({ left: 8 })
        .enabled(this.inputText.trim().length > 0 && !this.isLoading)
        .onClick(() => {
          this.sendMessage();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
}

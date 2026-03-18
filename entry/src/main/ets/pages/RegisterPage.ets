import { router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { UserStore } from '../services/UserStore';
import { ThemeColors } from '../constants/ThemeColors';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { Logger } from '../utils/Logger';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct RegisterPage {
  @State private username: string = '';
  @State private email: string = '';
  @State private password: string = '';
  @State private confirmPassword: string = '';
  @State private isLoading: boolean = false;
  @State private errorMessage: string = '';
  @State private showPassword: boolean = false;
  @State private showConfirmPassword: boolean = false;
  @State private pageOpacity: number = 0;
  @State private buttonScale: number = 1;
  @State private errorShake: number = 0;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  private authService: AuthService = AuthService.getInstance();
  private userStore: UserStore = UserStore.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  aboutToAppear() {
    try {
      this.updateThemeColors();
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.pageOpacity = 1;
      });
    } catch (error) {
      Logger.e('RegisterPage', `页面初始化失败: ${error}`);
    }
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  private async handleRegister() {
    if (!this.username || this.username.trim().length === 0) {
      this.showError('请输入用户名');
      return;
    }
    
    if (!this.email || this.email.trim().length === 0) {
      this.showError('请输入邮箱');
      return;
    }
    
    if (!this.isValidEmail(this.email)) {
      this.showError('请输入有效的邮箱地址');
      return;
    }
    
    if (!this.password || this.password.trim().length === 0) {
      this.showError('请输入密码');
      return;
    }
    
    if (this.password.length < 6) {
      this.showError('密码长度至少为6位');
      return;
    }
    
    if (!this.confirmPassword || this.confirmPassword.trim().length === 0) {
      this.showError('请确认密码');
      return;
    }
    
    if (this.password !== this.confirmPassword) {
      this.showError('两次输入的密码不一致');
      return;
    }
    
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      const response = await this.authService.register(
        this.username.trim(),
        this.email.trim(),
        this.password,
        this.confirmPassword
      );
      
      if (response.success && response.data) {
        await this.userStore.login(response.data.user, response.data.token);
        
        promptAction.showToast({
          message: '注册成功',
          duration: 2000
        });
        
        setTimeout(() => {
          router.replaceUrl({
            url: 'pages/MainPage'
          });
        }, 500);
      } else {
        this.showError(response.message || '注册失败');
      }
    } catch (error) {
      Logger.e('RegisterPage', `注册失败: ${error}`);
      this.showError('网络请求失败，请稍后重试');
    } finally {
      this.isLoading = false;
    }
  }
  
  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
  
  private showError(message: string) {
    this.errorMessage = message;
    this.triggerErrorShake();
  }
  
  private triggerErrorShake() {
    animateTo({
      duration: 50,
      curve: Curve.EaseInOut
    }, () => {
      this.errorShake = 10;
    });
    setTimeout(() => {
      animateTo({
        duration: 50,
        curve: Curve.EaseInOut
      }, () => {
        this.errorShake = -10;
      });
    }, 50);
    setTimeout(() => {
      animateTo({
        duration: 50,
        curve: Curve.EaseInOut
      }, () => {
        this.errorShake = 10;
      });
    }, 100);
    setTimeout(() => {
      animateTo({
        duration: 50,
        curve: Curve.EaseInOut
      }, () => {
        this.errorShake = 0;
      });
    }, 150);
  }
  
  private navigateToLogin() {
    router.back();
  }
  
  build() {
    Column() {
      this.buildHeader()
      this.buildRegisterForm()
      this.buildFooter()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors?.BACKGROUND_PRIMARY || '#FFFFFF')
    .opacity(this.pageOpacity)
  }
  
  @Builder
  buildHeader() {
    Column() {
      Text('✨')
        .fontSize(64)
        .margin({ bottom: 16 })
      
      Text('创建账户')
        .fontSize(28)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })
      
      Text('填写信息以开始使用')
        .fontSize(14)
        .fontColor(this.themeColors.TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ top: 60, bottom: 40 })
  }
  
  @Builder
  buildRegisterForm() {
    Scroll() {
      Column() {
        Column() {
          Text('用户名')
            .fontSize(14)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ bottom: 8 })
          
          TextInput({ placeholder: '请输入用户名', text: this.username })
            .width('100%')
            .height(48)
            .fontSize(15)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
            .borderRadius(12)
            .placeholderColor(this.themeColors.TEXT_TERTIARY)
            .onChange((value: string) => {
              this.username = value;
            })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        Column() {
          Text('邮箱')
            .fontSize(14)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ bottom: 8 })
          
          TextInput({ placeholder: '请输入邮箱', text: this.email })
            .width('100%')
            .height(48)
            .fontSize(15)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
            .borderRadius(12)
            .placeholderColor(this.themeColors.TEXT_TERTIARY)
            .type(InputType.Email)
            .onChange((value: string) => {
              this.email = value;
            })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        Column() {
          Text('密码')
            .fontSize(14)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ bottom: 8 })
          
          Row() {
            TextInput({ placeholder: '请输入密码（至少6位）', text: this.password })
              .layoutWeight(1)
              .height(48)
              .fontSize(15)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(12)
              .placeholderColor(this.themeColors.TEXT_TERTIARY)
              .type(this.showPassword ? InputType.Normal : InputType.Password)
              .onChange((value: string) => {
                this.password = value;
              })
            
            Button() {
              Text(this.showPassword ? '👁️' : '👁️‍🗨️')
                .fontSize(18)
            }
            .width(48)
            .height(48)
            .backgroundColor(ThemeColors.TRANSPARENT)
            .onClick(() => {
              this.showPassword = !this.showPassword;
            })
          }
          .width('100%')
          .height(48)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(12)
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        Column() {
          Text('确认密码')
            .fontSize(14)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ bottom: 8 })
          
          Row() {
            TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
              .layoutWeight(1)
              .height(48)
              .fontSize(15)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(12)
              .placeholderColor(this.themeColors.TEXT_TERTIARY)
              .type(this.showConfirmPassword ? InputType.Normal : InputType.Password)
              .onChange((value: string) => {
                this.confirmPassword = value;
              })
            
            Button() {
              Text(this.showConfirmPassword ? '👁️' : '👁️‍🗨️')
                .fontSize(18)
            }
            .width(48)
            .height(48)
            .backgroundColor(ThemeColors.TRANSPARENT)
            .onClick(() => {
              this.showConfirmPassword = !this.showConfirmPassword;
            })
          }
          .width('100%')
          .height(48)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(12)
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor(ThemeColors.ERROR)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 20 })
        }
        
        Button(this.isLoading ? '注册中...' : '注册')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor(ThemeColors.WHITE)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(ThemeColors.PRIMARY)
          .borderRadius(12)
          .enabled(!this.isLoading)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.buttonScale = 0.95;
            setTimeout(() => {
              this.buttonScale = 1;
              this.handleRegister();
            }, 100);
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .translate({ x: this.errorShake })
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  @Builder
  buildFooter() {
    Column() {
      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor(this.themeColors.TEXT_SECONDARY)
        
        Text('立即登录')
          .fontSize(14)
          .fontColor(ThemeColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.navigateToLogin();
          })
      }
    }
    .width('100%')
    .padding({ bottom: 40 })
  }
}

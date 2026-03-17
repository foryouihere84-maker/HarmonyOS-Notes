import { router } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { NotebookViewModel } from '../viewmodels/NotebookViewModel';
import { Notebook } from '../models/Notebook';
import { DateUtils } from '../utils/DateUtils';
import { AppConstants } from '../constants/AppConstants';
import { ThemeColors } from '../constants/ThemeColors';
import { Animation } from '../constants/Animation';
import { SYNC_COMPLETED_EVENT_ID } from '../viewmodels/SyncSettingsViewModel';
import { StatisticsService, StatisticsData } from '../services/StatisticsService';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';

type SortType = 'name' | 'createdTime' | 'modifiedTime';
type SortOrder = 'asc' | 'desc';

@Entry
@Component
struct MainPage {
  @State private notebookViewModel: NotebookViewModel = NotebookViewModel.getInstance();
  @State private notebooks: Notebook[] = [];
  @State private isLoading: boolean = false;
  @State private showCreateDialog: boolean = false;
  @State private newNotebookTitle: string = '';
  @State private newNotebookCoverImage: string = '';
  @State private sortType: SortType = 'modifiedTime';
  @State private sortOrder: SortOrder = 'desc';
  @State private showSortDialog: boolean = false;
  @State private showEditDialog: boolean = false;
  @State private editingNotebook: Notebook | null = null;
  @State private editTitle: string = '';
  @State private editCoverImage: string = '';
  @State private showDeleteNotebookDialog: boolean = false;
  @State private searchText: string = '';
  @State private pageOpacity: number = 0;
  @State private searchFocused: boolean = false;
  @State private errorShake: number = 0;
  @State private dialogScale: number = 0.9;
  @State private totalPageCount: number = 0;
  @State private todayEditCount: number = 0;
  @State private notebookCount: number = 0;
  @State private syncStatusText: string = '未同步';
  @State private syncStatusColor: string = '#9CA3AF';
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  private statisticsService: StatisticsService = StatisticsService.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  aboutToAppear() {
    this.updateThemeColors();
    this.loadNotebooks();
    
    emitter.on({ eventId: SYNC_COMPLETED_EVENT_ID }, (eventData: emitter.EventData) => {
      setTimeout(() => {
        this.loadNotebooks();
      }, 100);
    });
    
    animateTo({
      duration: Animation.PAGE_TRANSITION_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.pageOpacity = 1;
    });
  }
  
  aboutToDisappear() {
    emitter.off(SYNC_COMPLETED_EVENT_ID);
  }
  
  onPageShow() {
    this.updateThemeColors();
    this.loadNotebooks();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
    this.syncStatusColor = this.themeColors.TEXT_TERTIARY;
  }
  
  private async loadNotebooks() {
    try {
      this.isLoading = true;
      await this.notebookViewModel.loadNotebooks();
      const invalidNotebooks = this.notebookViewModel.notebooks.filter(notebook => 
        !notebook.title || notebook.title.trim().length === 0
      );
      
      for (const notebook of invalidNotebooks) {
        await this.deleteNotebook(notebook);
      }
      
      this.filterNotebooks();
      await this.loadStatistics();
    } catch (error) {
      console.error('加载笔记本失败:', error);
    } finally {
      this.isLoading = false;
    }
  }
  
  private async loadStatistics() {
    const data: StatisticsData = await this.statisticsService.refreshStatistics();
    this.notebookCount = data.notebookCount;
    this.totalPageCount = data.pageCount;
    this.todayEditCount = data.todayEditCount;
    this.syncStatusText = data.syncStatus;
    this.updateSyncStatusColor(data.syncStatus);
  }
  
  private updateSyncStatusColor(status: string) {
    switch (status) {
      case '同步中':
        this.syncStatusColor = ThemeColors.INFO;
        break;
      case '已同步':
        this.syncStatusColor = ThemeColors.SUCCESS;
        break;
      case '同步失败':
        this.syncStatusColor = ThemeColors.ERROR;
        break;
      default:
        this.syncStatusColor = this.themeColors.TEXT_TERTIARY;
        break;
    }
  }
  
  private sortNotebooks() {
    this.notebooks.sort((a, b) => {
      let comparison = 0;
      
      switch (this.sortType) {
        case 'name':
          comparison = a.title.localeCompare(b.title, 'zh-CN');
          break;
        case 'createdTime':
          comparison = a.createdTime - b.createdTime;
          break;
        case 'modifiedTime':
          comparison = a.modifiedTime - b.modifiedTime;
          break;
      }
      
      return this.sortOrder === 'asc' ? comparison : -comparison;
    });
  }
  
  private async createNotebook() {
    if (this.newNotebookTitle.trim().length === 0) {
      this.showErrorShake();
      return;
    }
    
    try {
      await this.notebookViewModel.createNotebook(this.newNotebookTitle, this.newNotebookCoverImage);
      this.notebooks = this.notebookViewModel.notebooks;
      this.sortNotebooks();
      await this.loadStatistics();
      this.showCreateDialog = false;
      this.newNotebookTitle = '';
      this.newNotebookCoverImage = '';
    } catch (error) {
      console.error('创建笔记本失败:', error);
    }
  }
  
  private async deleteNotebook(notebook: Notebook) {
    try {
      await this.notebookViewModel.deleteNotebook(notebook.id);
      this.notebooks = this.notebookViewModel.notebooks;
      await this.loadStatistics();
    } catch (error) {
      console.error('删除笔记本失败:', error);
    }
  }
  
  private navigateToNotebook(notebook: Notebook) {
    router.pushUrl({
      url: AppConstants.ROUTE_NOTEBOOK_LIST,
      params: {
        notebookId: notebook.id,
        notebookTitle: notebook.title
      }
    });
  }
  
  private getSortTypeName(): string {
    switch (this.sortType) {
      case 'name':
        return '名称';
      case 'createdTime':
        return '创建时间';
      case 'modifiedTime':
        return '修改时间';
      default:
        return '修改时间';
    }
  }
  
  private onSearchTextChange(value: string) {
    this.searchText = value;
    this.filterNotebooks();
  }
  
  private filterNotebooks() {
    if (this.searchText.trim().length === 0) {
      this.notebooks = this.notebookViewModel.notebooks.filter(notebook => 
        notebook.title && notebook.title.trim().length > 0
      );
    } else {
      const searchLower = this.searchText.toLowerCase().trim();
      this.notebooks = this.notebookViewModel.notebooks.filter(notebook => {
        if (!notebook.title || notebook.title.trim().length === 0) {
          return false;
        }
        return notebook.title.toLowerCase().includes(searchLower) ||
               (notebook.description && notebook.description.toLowerCase().includes(searchLower));
      });
    }
    this.sortNotebooks();
  }
  
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }
  
  private async openEditDialog(notebook: Notebook) {
    try {
      const latestNotebook = await this.notebookViewModel.getNotebookById(notebook.id);
      if (latestNotebook) {
        this.editingNotebook = latestNotebook;
        this.editTitle = latestNotebook.title;
        this.editCoverImage = latestNotebook.coverImage;
      } else {
        this.editingNotebook = notebook;
        this.editTitle = notebook.title;
        this.editCoverImage = notebook.coverImage;
      }
      this.showEditDialog = true;
      this.animateDialogOpen();
    } catch (error) {
      console.error('获取笔记本信息失败:', error);
      this.editingNotebook = notebook;
      this.editTitle = notebook.title;
      this.editCoverImage = notebook.coverImage;
      this.showEditDialog = true;
    }
  }
  
  private async saveEdit() {
    if (!this.editingNotebook) {
      return;
    }
    
    if (this.editTitle.trim().length === 0) {
      this.showErrorShake();
      return;
    }
    
    try {
      this.editingNotebook.title = this.editTitle.trim();
      this.editingNotebook.coverImage = this.editCoverImage;
      await this.notebookViewModel.updateNotebook(this.editingNotebook);
      this.notebooks = this.notebookViewModel.notebooks;
      this.showEditDialog = false;
      this.editingNotebook = null;
      this.editTitle = '';
      this.editCoverImage = '';
    } catch (error) {
      console.error('更新笔记本失败:', error);
    }
  }
  
  private async confirmDeleteNotebook() {
    if (!this.editingNotebook) {
      return;
    }
    
    try {
      await this.deleteNotebook(this.editingNotebook);
      this.showDeleteNotebookDialog = false;
      this.showEditDialog = false;
      this.editingNotebook = null;
      this.editTitle = '';
      this.editCoverImage = '';
    } catch (error) {
      console.error('删除笔记本失败:', error);
    }
  }
  
  private async selectCoverImage() {
    try {
      const photoSelectOptions: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      };
      
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        if (this.showEditDialog) {
          this.editCoverImage = photoSelectResult.photoUris[0];
        } else {
          this.newNotebookCoverImage = photoSelectResult.photoUris[0];
        }
      }
    } catch (error) {
      console.error('选择图片失败:', error);
    }
  }
  
  private showErrorShake() {
    animateTo({
      duration: Animation.ERROR_VIBRATION_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.errorShake = 10;
    });
    setTimeout(() => {
      animateTo({
        duration: Animation.ERROR_VIBRATION_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.errorShake = -10;
      });
    }, Animation.ERROR_VIBRATION_DURATION);
    setTimeout(() => {
      animateTo({
        duration: Animation.ERROR_VIBRATION_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.errorShake = 10;
      });
    }, Animation.ERROR_VIBRATION_DURATION * 2);
    setTimeout(() => {
      animateTo({
        duration: Animation.ERROR_VIBRATION_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.errorShake = 0;
      });
    }, Animation.ERROR_VIBRATION_DURATION * 3);
  }
  
  private animateDialogOpen() {
    this.dialogScale = 0.9;
    setTimeout(() => {
      animateTo({
        duration: Animation.DIALOG_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.dialogScale = 1;
      });
    }, 10);
  }
  
  private getNotebookColor(index: number): string {
    const colors = ThemeColors.NOTEBOOK_COLORS;
    return colors[index % colors.length];
  }
  
  build() {
    Stack() {
      Column() {
        this.buildHeader()
        this.buildStatsSection()
        this.buildQuickActions()
        this.buildNotebookSection()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
      .opacity(this.pageOpacity)
      
      if (this.showCreateDialog) {
        this.buildCreateDialog()
      }
      
      if (this.showSortDialog) {
        this.buildSortDialog()
      }
      
      if (this.showEditDialog) {
        this.buildEditDialog()
      }
      
      if (this.showDeleteNotebookDialog) {
        this.buildDeleteNotebookDialog()
      }
    }
  }
  
  @Builder
  buildHeader() {
    Column() {
      Row() {
        Column() {
          Text('神')
            .width(44)
            .height(44)
            .fontSize(20)
            .fontColor(ThemeColors.WHITE)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .borderRadius(22)
            .backgroundColor(ThemeColors.PRIMARY)
        }
        
        Column() {
          Text('欢迎来到我的世界')
            .fontSize(18)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          
          Text('娇贵的小公主')
            .fontSize(12)
            .fontColor(this.themeColors.TEXT_TERTIARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
        
        Row() {
          Button({ type: ButtonType.Circle }) {
            Text('⚙')
              .fontSize(18)
              .fontColor(this.themeColors.TEXT_SECONDARY)
          }
          .width(40)
          .height(40)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .onClick(() => {
            router.pushUrl({
              url: AppConstants.ROUTE_SETTINGS_PAGE
            });
          })
        }
      }
      .width('100%')
      .margin({ bottom: 20 })
      
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ left: 12, right: 8 })
        
        TextInput({ placeholder: '搜索笔记、笔记本...', text: this.searchText })
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(22)
          .placeholderColor(this.themeColors.TEXT_TERTIARY)
          .onChange((value: string) => {
            this.onSearchTextChange(value);
          })
      }
      .width('100%')
      .height(44)
      .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
      .borderRadius(22)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 20 })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  buildStatsSection() {
    Row() {
      this.buildStatItem('📚', this.notebookCount.toString(), '笔记本')
      this.buildStatItem('📄', this.totalPageCount.toString(), '页面')
      this.buildStatItem('✏️', this.todayEditCount.toString(), '今日')
      this.buildStatItemWithColor('☁️', this.syncStatusText, '状态', this.syncStatusColor)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  buildStatItemWithColor(icon: string, value: string, label: string, valueColor: string) {
    Column() {
      Text(icon)
        .fontSize(20)
        .margin({ bottom: 4 })
      
      Text(value)
        .fontSize(16)
        .fontColor(valueColor)
        .fontWeight(FontWeight.Bold)
      
      Text(label)
        .fontSize(11)
        .fontColor(this.themeColors.TEXT_TERTIARY)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .padding(8)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(12)
    .margin({ left: 4, right: 4 })
  }
  
  @Builder
  buildStatItem(icon: string, value: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(20)
        .margin({ bottom: 4 })
      
      Text(value)
        .fontSize(16)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      
      Text(label)
        .fontSize(11)
        .fontColor(this.themeColors.TEXT_TERTIARY)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .padding(8)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(12)
    .margin({ left: 4, right: 4 })
  }
  
  @Builder
  buildQuickActions() {
    Column() {
      Row() {
        Text('快捷操作')
          .fontSize(16)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      Row() {
        this.buildActionButton('➕', '新建', this.themeColors.PRIMARY, () => {
          this.showCreateDialog = true;
          this.animateDialogOpen();
        })
        
        this.buildActionButton('☁️', '同步', ThemeColors.INFO, () => {
          router.pushUrl({
            url: AppConstants.ROUTE_SYNC_SETTINGS
          });
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  buildActionButton(icon: string, label: string, color: string, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(24)
        .margin({ bottom: 6 })
      
      Text(label)
        .fontSize(12)
        .fontColor(this.themeColors.TEXT_PRIMARY)
    }
    .width(80)
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(color)
    .borderRadius(12)
    .margin({ right: 12 })
    .onClick(() => {
      action();
    })
  }
  
  @Builder
  buildNotebookSection() {
    Column() {
      Row() {
        Text('我的笔记本')
          .fontSize(16)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        
        Blank()
        
        Row() {
          Text(this.getSortTypeName())
            .fontSize(12)
            .fontColor(this.themeColors.PRIMARY)
          
          Text(this.sortOrder === 'asc' ? ' ↑' : ' ↓')
            .fontSize(12)
            .fontColor(this.themeColors.PRIMARY)
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(12)
        .onClick(() => {
          this.showSortDialog = true;
          this.animateDialogOpen();
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      if (this.isLoading) {
        this.buildLoadingView()
      } else if (this.notebooks.length === 0) {
        this.buildEmptyView()
      } else {
        this.buildNotebookList()
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.themeColors.PRIMARY)
      
      Text('加载中...')
        .fontSize(14)
        .fontColor(this.themeColors.TEXT_TERTIARY)
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  buildEmptyView() {
    Column() {
      Text('📝')
        .fontSize(48)
        .margin({ bottom: 16 })
      
      Text('还没有笔记本')
        .fontSize(16)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })
      
      Text('点击上方"新建"按钮创建第一个笔记本')
        .fontSize(14)
        .fontColor(this.themeColors.TEXT_SECONDARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  buildNotebookList() {
    List({ space: 10 }) {
      ForEach(this.notebooks, (notebook: Notebook, index: number) => {
        ListItem() {
          this.buildNotebookCard(notebook, index)
        }
      }, (notebook: Notebook) => notebook.id)
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
  }
  
  @Builder
  buildNotebookCard(notebook: Notebook, index: number) {
    Row() {
      Column() {
        Text(notebook.title.charAt(0).toUpperCase())
          .fontSize(22)
          .fontColor(ThemeColors.WHITE)
          .fontWeight(FontWeight.Bold)
      }
      .width(48)
      .height(48)
      .borderRadius(12)
      .backgroundColor(this.getNotebookColor(index))
      .justifyContent(FlexAlign.Center)
      
      Column() {
        Text(notebook.title)
          .fontSize(15)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Row() {
          Text(`${notebook.pageCount} 页`)
            .fontSize(12)
            .fontColor(this.themeColors.TEXT_SECONDARY)
          
          Text(' · ')
            .fontSize(12)
            .fontColor(this.themeColors.TEXT_TERTIARY)
          
          Text(DateUtils.getRelativeTime(notebook.modifiedTime))
            .fontSize(12)
            .fontColor(this.themeColors.TEXT_SECONDARY)
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(12)
    .onClick(() => {
      this.navigateToNotebook(notebook);
    })
    .gesture(LongPressGesture().onAction(() => {
      this.openEditDialog(notebook);
    }))
  }
  
  @Builder
  buildCreateDialog() {
    Column() {
      Text('创建笔记本')
        .fontSize(18)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      TextInput({ placeholder: '请输入笔记本标题', text: this.newNotebookTitle })
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(12)
        .translate({ x: this.errorShake, y: 0 })
        .placeholderColor(this.themeColors.TEXT_TERTIARY)
        .onChange((value: string) => {
          this.newNotebookTitle = value;
        })
      
      Row() {
        if (this.newNotebookCoverImage && this.newNotebookCoverImage.length > 0) {
          Image(this.newNotebookCoverImage)
            .width(80)
            .height(80)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .margin({ right: 12 })
        } else {
          Column() {
            Text('无封面')
              .fontSize(13)
              .fontColor(this.themeColors.TEXT_SECONDARY)
          }
          .width(80)
          .height(80)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .margin({ right: 12 })
        }
        
        Column() {
          Button('选择封面')
            .width('100%')
            .height(36)
            .fontSize(14)
            .fontColor(ThemeColors.WHITE)
            .backgroundColor(this.themeColors.PRIMARY)
            .borderRadius(10)
            .onClick(() => {
              this.selectCoverImage();
            })
          
          if (this.newNotebookCoverImage && this.newNotebookCoverImage.length > 0) {
            Button('移除封面')
              .width('100%')
              .height(36)
              .fontSize(14)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(10)
              .margin({ top: 8 })
              .onClick(() => {
                this.newNotebookCoverImage = '';
              })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 16 })
      
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(10)
          .onClick(() => {
            this.showCreateDialog = false;
            this.newNotebookTitle = '';
            this.newNotebookCoverImage = '';
          })
        
        Button('创建')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(ThemeColors.WHITE)
          .backgroundColor(this.themeColors.PRIMARY)
          .borderRadius(10)
          .margin({ left: 12 })
          .onClick(() => {
            this.createNotebook();
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('85%')
    .padding(20)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(16)
    .scale({ x: this.dialogScale, y: this.dialogScale })
  }
  
  @Builder
  buildSortDialog() {
    Column() {
      Text('选择排序方式')
        .fontSize(18)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Column() {
        this.buildSortOption('name', '名称')
        this.buildSortOption('createdTime', '创建时间')
        this.buildSortOption('modifiedTime', '修改时间')
      }
      .width('100%')
    }
    .width('75%')
    .padding(20)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(16)
    .scale({ x: this.dialogScale, y: this.dialogScale })
  }
  
  @Builder
  buildSortOption(sortType: SortType, label: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.sortType === sortType ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
        .fontWeight(this.sortType === sortType ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)
      
      if (this.sortType === sortType) {
        Text('✓')
          .fontSize(16)
          .fontColor(this.themeColors.PRIMARY)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 4, right: 4 })
    .backgroundColor(this.sortType === sortType ? this.themeColors.BACKGROUND_TERTIARY : ThemeColors.TRANSPARENT)
    .borderRadius(10)
    .margin({ bottom: 4 })
    .onClick(() => {
      if (this.sortType === sortType) {
        this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
      } else {
        this.sortType = sortType;
      }
      this.sortNotebooks();
      this.showSortDialog = false;
    })
  }
  
  @Builder
  buildEditDialog() {
    Column() {
      Text('编辑笔记本')
        .fontSize(18)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      TextInput({ placeholder: '请输入笔记本标题', text: this.editTitle })
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(12)
        .translate({ x: this.errorShake, y: 0 })
        .placeholderColor(this.themeColors.TEXT_TERTIARY)
        .onChange((value: string) => {
          this.editTitle = value;
        })
      
      Row() {
        if (this.editCoverImage && this.editCoverImage.length > 0) {
          Image(this.editCoverImage)
            .width(80)
            .height(80)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .margin({ right: 12 })
        } else {
          Column() {
            Text('无封面')
              .fontSize(13)
              .fontColor(this.themeColors.TEXT_SECONDARY)
          }
          .width(80)
          .height(80)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .margin({ right: 12 })
        }
        
        Column() {
          Button('选择封面')
            .width('100%')
            .height(36)
            .fontSize(14)
            .fontColor(ThemeColors.WHITE)
            .backgroundColor(this.themeColors.PRIMARY)
            .borderRadius(10)
            .onClick(() => {
              this.selectCoverImage();
            })
          
          if (this.editCoverImage && this.editCoverImage.length > 0) {
            Button('移除封面')
              .width('100%')
              .height(36)
              .fontSize(14)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(10)
              .margin({ top: 8 })
              .onClick(() => {
                this.editCoverImage = '';
              })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 16 })
      
      if (this.editingNotebook) {
        Column() {
          Text('笔记本详情')
            .fontSize(14)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 12 })
          
          Row() {
            Text('📝 页面数量')
              .fontSize(13)
              .fontColor(this.themeColors.TEXT_SECONDARY)
              .layoutWeight(1)
            
            Text(`${this.editingNotebook.pageCount} 页`)
              .fontSize(13)
              .fontColor(this.themeColors.PRIMARY)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ bottom: 8 })
          
          Row() {
            Text('📅 创建时间')
              .fontSize(13)
              .fontColor(this.themeColors.TEXT_SECONDARY)
              .layoutWeight(1)
            
            Text(this.formatDate(this.editingNotebook.createdTime))
              .fontSize(13)
              .fontColor(this.themeColors.TEXT_SECONDARY)
          }
          .width('100%')
          .margin({ bottom: 8 })
          
          Row() {
            Text('🕒 修改时间')
              .fontSize(13)
              .fontColor(this.themeColors.TEXT_SECONDARY)
              .layoutWeight(1)
            
            Text(this.formatDate(this.editingNotebook.modifiedTime))
              .fontSize(13)
              .fontColor(this.themeColors.TEXT_SECONDARY)
          }
          .width('100%')
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(12)
        .margin({ top: 16 })
      }
      
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(10)
          .onClick(() => {
            this.showEditDialog = false;
            this.editingNotebook = null;
            this.editTitle = '';
            this.editCoverImage = '';
          })
        
        Button('删除')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(ThemeColors.WHITE)
          .backgroundColor(ThemeColors.ERROR)
          .borderRadius(10)
          .margin({ left: 8 })
          .onClick(() => {
            this.showDeleteNotebookDialog = true;
          })
        
        Button('保存')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(ThemeColors.WHITE)
          .backgroundColor(this.themeColors.PRIMARY)
          .borderRadius(10)
          .margin({ left: 8 })
          .onClick(() => {
            this.saveEdit();
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('85%')
    .padding(20)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(16)
    .scale({ x: this.dialogScale, y: this.dialogScale })
  }
  
  @Builder
  buildDeleteNotebookDialog() {
    Column() {
      Text('确认删除')
        .fontSize(18)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
      
      Text('确定要删除这个笔记本吗？删除后将无法恢复。')
        .fontSize(14)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .margin({ bottom: 20 })
      
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(10)
          .onClick(() => {
            this.showDeleteNotebookDialog = false;
          })
        
        Button('删除')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(ThemeColors.WHITE)
          .backgroundColor(ThemeColors.ERROR)
          .borderRadius(10)
          .margin({ left: 12 })
          .onClick(() => {
            this.confirmDeleteNotebook();
          })
      }
      .width('100%')
    }
    .width('75%')
    .padding(20)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(16)
    .scale({ x: this.dialogScale, y: this.dialogScale })
  }
}

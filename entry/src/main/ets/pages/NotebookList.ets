import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { PageViewModel } from '../viewmodels/PageViewModel';
import { Page } from '../models/Page';
import { DateUtils } from '../utils/DateUtils';
import { AppConstants } from '../constants/AppConstants';
import { ThemeColors } from '../constants/ThemeColors';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { AIProcessDialog } from './AIProcessDialog';
import { Logger } from '../utils/Logger';
import { LoadingSpinner } from '../components/LoadingSpinner';

type PageSortType = 'title' | 'createdTime' | 'modifiedTime' | 'contentLength' | 'order';
type PageSortOrder = 'asc' | 'desc';

interface AIPageProcessData {
  id: string;
  title: string;
  content: string;
}

@Entry
@Component
struct NotebookList {
  @State private pageViewModel: PageViewModel = PageViewModel.getInstance();
  @State private pages: Page[] = [];
  @State private isLoading: boolean = false;
  @State private showCreateDialog: boolean = false;
  @State private newPageTitle: string = '';
  @State private notebookId: string = '';
  @State private notebookTitle: string = '';
  @State private showDeleteDialog: boolean = false;
  @State private pageToDelete: Page | null = null;
  @State private pageSortType: PageSortType = 'modifiedTime';
  @State private pageSortOrder: PageSortOrder = 'desc';
  @State private showSortDialog: boolean = false;
  @State private isRefreshing: boolean = false;
  @State private isSelectionMode: boolean = false;
  @State private selectedPages: Set<string> = new Set<string>();
  @State private showBatchDeleteDialog: boolean = false;
  @State private showAIMenu: boolean = false;
  @State private aiButtonScale: number = 1;
  @State private isProcessingAI: boolean = false;
  @State private showAIProcessDialog: boolean = false;
  @State private aiProcessAction: 'extract' | 'polish' | 'summarize' | 'expand' = 'extract';
  @State private selectedPagesForAI: AIPageProcessData[] = [];
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  @State private pageOpacity: number = Animation.PAGE_TRANSITION_OPACITY_END;
  @State private buttonScale: number = 1;
  @State private dialogScale: number = Animation.DIALOG_SCALE_END;
  @State private dialogOpacity: number = 1;
  @State private cardScale: number = 1;
  @State private showErrorHighlight: boolean = false;
  private themeManager: ThemeManager = ThemeManager.getInstance();

  onThemeChange(): void {
    this.updateThemeColors();
  }

  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }

  aboutToAppear() {
    this.updateThemeColors();
    const params = router.getParams() as Record<string, Object>;
    this.notebookId = params['notebookId'] as string;
    this.notebookTitle = params['notebookTitle'] as string;

    // 页面淡入动画
    this.pageOpacity = Animation.PAGE_TRANSITION_OPACITY_START;
    setTimeout(() => {
      animateTo({
        duration: Animation.PAGE_TRANSITION_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.pageOpacity = Animation.PAGE_TRANSITION_OPACITY_END;
      });
    }, 50);

    this.loadPages();
  }

  onPageShow() {
    this.loadPages();
  }

  private async loadPages() {
    try {
      this.isLoading = true;
      await this.pageViewModel.loadPages(this.notebookId);
      this.pages = this.pageViewModel.pages;
      this.sortPages();
    } catch (error) {
      console.error('加载页面失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private async refreshPages() {
    try {
      const currentSelectedIds = Array.from(this.selectedPages);
      await this.pageViewModel.loadPages(this.notebookId);
      this.pages = this.pageViewModel.pages;
      this.selectedPages.clear();
      currentSelectedIds.forEach(id => {
        if (this.pages.find(p => p.id === id)) {
          this.selectedPages.add(id);
        }
      });
      this.sortPages();
    } catch (error) {
      console.error('刷新页面失败:', error);
    }
  }

  private sortPages() {
    const sortedPages = [...this.pages];
    sortedPages.sort((a, b) => {
      let comparison = 0;

      switch (this.pageSortType) {
        case 'title':
          comparison = a.title.localeCompare(b.title, 'zh-CN');
          break;
        case 'createdTime':
          comparison = a.createdTime - b.createdTime;
          break;
        case 'modifiedTime':
          comparison = a.modifiedTime - b.modifiedTime;
          break;
        case 'contentLength':
          comparison = (a.content ? a.content.length : 0) - (b.content ? b.content.length : 0);
          break;
        case 'order':
          comparison = a.order - b.order;
          break;
      }

      return this.pageSortOrder === 'asc' ? comparison : -comparison;
    });

    sortedPages.sort((a, b) => {
      if (a.isPinned !== b.isPinned) {
        return b.isPinned ? 1 : -1;
      }
      return 0;
    });

    this.pages = sortedPages;
  }

  private toggleSortOrder() {
    this.pageSortOrder = this.pageSortOrder === 'asc' ? 'desc' : 'asc';
    this.sortPages();
  }

  private async createPage() {
    if (this.newPageTitle.trim().length === 0) {
      return;
    }

    try {
      await this.pageViewModel.createPage(this.notebookId, this.newPageTitle);
      this.pages = this.pageViewModel.pages;
      this.showCreateDialog = false;
      this.newPageTitle = '';
    } catch (error) {
      console.error('创建页面失败:', error);
    }
  }

  private async deletePage(page: Page) {
    try {
      await this.pageViewModel.deletePage(page.id);
      this.pages = this.pageViewModel.pages;
    } catch (error) {
      console.error('删除页面失败:', error);
    }
  }

  private showDeleteConfirm(page: Page) {
    this.pageToDelete = page;
    this.showDeleteDialog = true;
  }

  private async confirmDeletePage() {
    if (!this.pageToDelete) {
      return;
    }

    try {
      await this.pageViewModel.deletePage(this.pageToDelete.id);
      this.pages = this.pageViewModel.pages;
      this.showDeleteDialog = false;
      this.pageToDelete = null;
    } catch (error) {
      console.error('删除页面失败:', error);
    }
  }

  private toggleSelectionMode() {
    this.isSelectionMode = !this.isSelectionMode;
    if (!this.isSelectionMode) {
      this.selectedPages.clear();
    }
  }

  private togglePageSelection(pageId: string) {
    if (this.selectedPages.has(pageId)) {
      this.selectedPages.delete(pageId);
    } else {
      this.selectedPages.add(pageId);
    }
  }

  private isPageSelected(pageId: string): boolean {
    return this.selectedPages.has(pageId);
  }

  private selectAllPages() {
    this.selectedPages.clear();
    this.pages.forEach(page => {
      this.selectedPages.add(page.id);
    });
  }

  private deselectAllPages() {
    this.selectedPages.clear();
  }

  private toggleAIMenu() {
    if (!this.isSelectionMode) {
      return;
    }
    this.showAIMenu = !this.showAIMenu;
  }

  private async showAIAction(action: string): Promise<void> {
    Logger.i('NotebookList', `showAIAction 被调用，action: ${action}`);
    
    if (this.selectedPages.size === 0) {
      Logger.i('NotebookList', '没有选择笔记，显示提示');
      promptAction.showToast({
        message: '请先选择要处理的笔记',
        duration: 2000
      });
      return;
    }
    
    this.showAIMenu = false;
    
    const selectedPageIds = Array.from(this.selectedPages);
    const selectedPages = this.pages.filter(p => selectedPageIds.includes(p.id));
    
    this.selectedPagesForAI = selectedPages.map((p: Page): AIPageProcessData => ({
      id: p.id,
      title: p.title,
      content: p.content || ''
    }));
    
    this.aiProcessAction = action as 'extract' | 'polish' | 'summarize' | 'expand';
    this.showAIProcessDialog = true;
    
    Logger.i('NotebookList', `AIProcessDialog 显示，action: ${this.aiProcessAction}, pages: ${this.selectedPagesForAI.length}`);
  }

  /**
   * AI 按钮点击缩放动画
   */
  private animateAIButtonClick(callback: () => void) {
    animateTo({
      duration: Animation.BUTTON_CLICK_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.aiButtonScale = Animation.BUTTON_CLICK_SCALE;
    });

    setTimeout(() => {
      animateTo({
        duration: Animation.BUTTON_CLICK_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.aiButtonScale = 1;
      });
      callback();
    }, Animation.BUTTON_CLICK_DURATION);
  }

  private showBatchDeleteConfirm() {
    if (this.selectedPages.size === 0) {
      return;
    }
    this.showBatchDeleteDialog = true;
  }

  private async confirmBatchDelete() {
    try {
      const pageIds = Array.from(this.selectedPages);
      for (const pageId of pageIds) {
        await this.pageViewModel.deletePage(pageId);
      }
      this.pages = this.pageViewModel.pages;
      this.selectedPages.clear();
      this.isSelectionMode = false;
      this.showBatchDeleteDialog = false;
    } catch (error) {
      console.error('批量删除页面失败:', error);
    }
  }

  private async togglePin(page: Page) {
    try {
      await this.pageViewModel.togglePinPage(page.id, !page.isPinned);
      this.pages = this.pageViewModel.pages;
    } catch (error) {
      console.error('操作失败:', error);
    }
  }

  private navigateToPageEditor(page: Page) {
    router.pushUrl({
      url: AppConstants.ROUTE_PAGE_EDITOR,
      params: {
        pageId: page.id,
        notebookId: this.notebookId,
        notebookTitle: this.notebookTitle
      }
    });
  }

  private navigateBack() {
    router.back();
  }

  /**
   * 按钮点击缩放动画
   */
  private animateButtonClick(callback: () => void) {
    animateTo({
      duration: Animation.BUTTON_CLICK_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.buttonScale = Animation.BUTTON_CLICK_SCALE;
    });

    setTimeout(() => {
      animateTo({
        duration: Animation.BUTTON_CLICK_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.buttonScale = 1;
      });
      callback();
    }, Animation.BUTTON_CLICK_DURATION);
  }

  /**
   * 对话框显示动画
   */
  private animateDialogShow() {
    this.dialogScale = Animation.DIALOG_SCALE_START;
    this.dialogOpacity = 0;
    setTimeout(() => {
      animateTo({
        duration: Animation.DIALOG_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.dialogScale = Animation.DIALOG_SCALE_END;
        this.dialogOpacity = 1;
      });
    }, 50);
  }

  /**
   * 对话框隐藏动画
   */
  private animateDialogHide(callback: () => void) {
    animateTo({
      duration: Animation.DIALOG_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.dialogScale = Animation.DIALOG_SCALE_START;
      this.dialogOpacity = 0;
    });

    setTimeout(() => {
      this.dialogScale = Animation.DIALOG_SCALE_START;
      this.dialogOpacity = 0;
      callback();
    }, Animation.DIALOG_DURATION);
  }

  /**
   * 错误提示震动动画
   */
  private animateErrorHighlight(callback: () => void) {
    this.showErrorHighlight = true;
    setTimeout(() => {
      this.showErrorHighlight = false;
      callback();
    }, Animation.ERROR_VIBRATION_DURATION);
  }

  /**
   * 卡片悬浮动画
   */
  private animateCardHover(isHover: boolean) {
    animateTo({
      duration: Animation.DURATION_FAST,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.cardScale = isHover ? 1.05 : 1;
    });
  }

  build() {
    Stack() {
      Column() {
        this.buildHeader()

        if (this.isLoading) {
          this.buildLoadingView()
        } else if (this.pages.length === 0) {
          this.buildEmptyView()
        } else {
          this.buildPageList()
        }

        this.buildFloatingButton()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
      .opacity(this.pageOpacity)
      .animation({ duration: Animation.PAGE_TRANSITION_DURATION, curve: Animation.CURVE_EASE_IN_OUT })

      if (this.showCreateDialog) {
        Column() {
          this.buildCreateDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR)
        .justifyContent(FlexAlign.Center)
        .opacity(this.dialogOpacity)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showCreateDialog = false;
            this.newPageTitle = '';
          });
        })
      }

      if (this.showDeleteDialog) {
        Column() {
          this.buildDeleteDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR)
        .justifyContent(FlexAlign.Center)
        .opacity(this.dialogOpacity)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showDeleteDialog = false;
            this.pageToDelete = null;
          });
        })
      }

      if (this.showSortDialog) {
        Column() {
          this.buildSortDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR)
        .justifyContent(FlexAlign.Center)
        .opacity(this.dialogOpacity)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showSortDialog = false;
          });
        })
      }

      if (this.showBatchDeleteDialog) {
        Column() {
          this.buildBatchDeleteDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR)
        .justifyContent(FlexAlign.Center)
        .opacity(this.dialogOpacity)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showBatchDeleteDialog = false;
          });
        })
      }

      if (this.showAIMenu && this.isSelectionMode) {
        Column() {
          this.buildAIMenu()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showAIMenu = false;
        })
      }
      
      if (this.showAIProcessDialog) {
        AIProcessDialog({
          action: this.aiProcessAction,
          pages: this.selectedPagesForAI,
          show: this.showAIProcessDialog,
          onClose: () => {
            this.showAIProcessDialog = false;
          }
        })
      }
    }
  }

  @Builder
  buildHeader() {
    Row() {
      if (this.isSelectionMode) {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(Color.Transparent)
          .fontColor(this.themeColors.PRIMARY)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.toggleSelectionMode();
            });
          })

        Text(`已选择 ${this.selectedPages.size} 项`)
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .margin({ left: Spacing.MARGIN_SM, right: Spacing.MARGIN_SM })

        Button(this.pages.length > 0 && this.selectedPages.size === this.pages.length ? '取消全选' : '全选')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(Color.Transparent)
          .fontColor(this.themeColors.PRIMARY)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              if (this.pages.length > 0 && this.selectedPages.size === this.pages.length) {
                this.deselectAllPages();
              } else {
                this.selectAllPages();
              }
            });
          })

        Button('删除')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.ERROR)
          .fontColor(ThemeColors.WHITE)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.showBatchDeleteConfirm();
            });
          })

        Button() {
          Text('🤖')
            .fontSize(Typography.FONT_SIZE_MD)
        }
        .backgroundColor(this.themeColors.PRIMARY)
        .fontColor(ThemeColors.WHITE)
        .borderRadius(BorderRadius.RADIUS_MD)
        .width(Spacing.TOOLBAR_BUTTON_SIZE)
        .height(Spacing.TOOLBAR_BUTTON_SIZE)
        .scale({ x: this.aiButtonScale, y: this.aiButtonScale })
        .onClick(() => {
          this.animateAIButtonClick(() => {
            this.toggleAIMenu();
          });
        })
      } else {
        Button() {
          Text('<')
            .fontSize(Typography.FONT_SIZE_XXL)
            .fontColor(this.themeColors.PRIMARY)
            .fontWeight(Typography.FONT_WEIGHT_LIGHT)
        }
        .backgroundColor(Color.Transparent)
        .width(Spacing.TOOLBAR_BUTTON_SIZE)
        .height(Spacing.TOOLBAR_BUTTON_SIZE)
        .scale({ x: this.buttonScale, y: this.buttonScale })
        .onClick(() => {
          this.animateButtonClick(() => {
            this.navigateBack();
          });
        })

        Column() {
          Text(this.notebookTitle)
            .fontSize(Typography.FONT_SIZE_XL)
            .fontWeight(Typography.FONT_WEIGHT_BOLD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${this.pages.length} 个页面`)
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .margin({ top: Spacing.MARGIN_XS })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: Spacing.MARGIN_SM, right: Spacing.MARGIN_SM })

        Button() {
          Row() {
            Text('排序')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.PRIMARY)

            Text(this.pageSortOrder === 'asc' ? '↑' : '↓')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.PRIMARY)
              .margin({ left: Spacing.MARGIN_XS })
          }
        }
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_LG)
        .padding({
          left: Spacing.PADDING_MD,
          right: Spacing.PADDING_MD,
          top: Spacing.PADDING_SM,
          bottom: Spacing.PADDING_SM
        })
        .scale({ x: this.buttonScale, y: this.buttonScale })
      }
    }
    .width('100%')
    .height(Spacing.HEADER_HEIGHT)
    .padding({
      left: Spacing.PADDING_MD,
      right: Spacing.PADDING_MD,
      top: Spacing.PADDING_MD,
      bottom: Spacing.PADDING_MD
    })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }

  @Builder
  buildLoadingView() {
    Column() {
      LoadingSpinner({
        color: this.themeColors.PRIMARY,
        spinnerSize: Spacing.AVATAR_SIZE_MD
      })

      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_TERTIARY)
        .margin({ top: Spacing.MARGIN_SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildEmptyView() {
    Column() {
      Text('📄')
        .fontSize(Typography.EMOJI_SIZE_LG)
        .margin({ bottom: Spacing.MARGIN_LG })

      Text('还没有页面')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_SM })

      Text('点击右下角按钮创建第一个页面')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildPageList() {
    Refresh({ refreshing: $$this.isRefreshing, offset: Spacing.REFRESH_OFFSET, friction: Spacing.REFRESH_FRICTION }) {
      List({ space: Spacing.LIST_ITEM_SPACING }) {
        ForEach(this.pages, (page: Page) => {
          ListItem() {
            this.buildPageItem(page)
          }
          .transition({ type: TransitionType.All, opacity: 0, translate: { x: Animation.LIST_ITEM_SLIDE_DISTANCE } })
          .animation({ duration: Animation.LIST_ITEM_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
        }, (page: Page) => page.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: Spacing.PADDING_MD,
        right: Spacing.PADDING_MD,
        top: Spacing.PADDING_SM,
        bottom: Spacing.PADDING_SM
      })
    }
    .onStateChange((state: number) => {
      if (state === 1) {
        this.refreshPages();
      } else if (state === 0) {
        this.isRefreshing = false;
      }
    })
  }

  @Builder
  buildPageItem(page: Page) {
    Row() {
      if (this.isSelectionMode) {
        Checkbox({ name: page.id, group: this.isPageSelected(page.id) ? 'selected' : '' })
          .selectedColor(this.themeColors.PRIMARY)
          .width(20)
          .height(20)
          .margin({ right: Spacing.MARGIN_SM })
          .onChange((value: boolean) => {
            this.togglePageSelection(page.id);
          })
      }

      Column() {
        Row() {
          Text(page.title)
            .fontSize(Typography.FONT_SIZE_MD)
            .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (page.isPinned) {
            Text('📌')
              .fontSize(Typography.FONT_SIZE_MD)
              .margin({ left: Spacing.MARGIN_XS })
          }
        }
        .width('100%')

        Text(page.content || '无内容')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(Typography.LINE_HEIGHT_MD)
          .margin({ top: Spacing.MARGIN_XS })

        Row() {
          Text(DateUtils.getRelativeTime(page.modifiedTime))
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(this.themeColors.TEXT_TERTIARY)
        }
        .width('100%')
        .margin({ top: Spacing.MARGIN_SM })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.RADIUS_LG)
    .shadow({
      radius: Spacing.SHADOW_RADIUS,
      color: this.themeColors.SHADOW_COLOR,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET
    })
    .scale({ x: this.cardScale, y: this.cardScale })
    .onClick(() => {
      if (this.isSelectionMode) {
        this.togglePageSelection(page.id);
      } else {
        this.navigateToPageEditor(page);
      }
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (!this.isSelectionMode) {
            this.toggleSelectionMode();
            this.togglePageSelection(page.id);
          }
        })
    )
    .onHover((isHover: boolean) => {
      this.animateCardHover(isHover);
    })
  }

  @Builder
  buildFloatingButton() {
    Button() {
      Text('+')
        .fontSize(Typography.FONT_SIZE_XXXL)
        .fontWeight(Typography.FONT_WEIGHT_LIGHT)
        .fontColor(ThemeColors.WHITE)
    }
    .width(Spacing.FAB_SIZE)
    .height(Spacing.FAB_SIZE)
    .borderRadius(Spacing.FAB_SIZE / 2)
    .backgroundColor(this.themeColors.PRIMARY)
    .shadow({
      radius: Spacing.SHADOW_RADIUS_LG,
      color: this.themeColors.PRIMARY + '40',
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET_LG
    })
    .position({ x: '80%', y: '80%' })
    .scale({ x: this.buttonScale, y: this.buttonScale })
    .onClick(() => {
      this.animateButtonClick(() => {
        this.showCreateDialog = true;
        this.animateDialogShow();
      });
    })
  }

  @Builder
  buildCreateDialog() {
    Column() {
      Text('创建页面')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })

      TextInput({ placeholder: '请输入页面标题', text: this.newPageTitle })
        .width('100%')
        .height(Spacing.INPUT_HEIGHT)
        .fontSize(Typography.FONT_SIZE_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .border(this.showErrorHighlight ? { width: 2, color: this.themeColors.ERROR } : { width: 0 })
        .onChange((value: string) => {
          this.newPageTitle = value;
        })

      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showCreateDialog = false;
                this.newPageTitle = '';
              });
            });
          })

        Button('创建')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.PRIMARY)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.PADDING_MD })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              if (this.newPageTitle.trim().length === 0) {
                this.animateErrorHighlight(() => {
                });
                return;
              }
              this.createPage();
            });
          })
      }
      .width('100%')
    }
    .width('85%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({
      radius: Spacing.SHADOW_RADIUS_XL,
      color: this.themeColors.SHADOW_COLOR_DARK,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET_XL
    })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }

  @Builder
  buildDeleteDialog() {
    Column() {
      Text('确认删除')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_MD })

      Text('确定要删除这个页面吗？删除后将无法恢复。')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(Typography.LINE_HEIGHT_LG)
        .margin({ bottom: Spacing.MARGIN_XL })

      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showDeleteDialog = false;
                this.pageToDelete = null;
              });
            });
          })

        Button('删除')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.ERROR)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.PADDING_MD })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.confirmDeletePage();
            });
          })
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({
      radius: Spacing.SHADOW_RADIUS_XL,
      color: this.themeColors.SHADOW_COLOR_DARK,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET_XL
    })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }

  @Builder
  buildSortDialog() {
    Column() {
      Text('排序方式')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })

      Column() {
        Row() {
          Text('名称')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.pageSortType === 'title' ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
            .fontWeight(this.pageSortType === 'title' ? Typography.FONT_WEIGHT_MEDIUM : Typography.FONT_WEIGHT_NORMAL)
            .layoutWeight(1)

          if (this.pageSortType === 'title') {
            Text(this.pageSortOrder === 'asc' ? '↑' : '↓')
              .fontSize(Typography.FONT_SIZE_MD)
              .fontColor(this.themeColors.PRIMARY)
              .margin({ right: Spacing.MARGIN_SM })
              .onClick(() => {
                this.toggleSortOrder();
              })
          }
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .onClick(() => {
          if (this.pageSortType !== 'title') {
            this.pageSortType = 'title';
            this.sortPages();
          }
        })

        Row() {
          Text('创建时间')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.pageSortType === 'createdTime' ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
            .fontWeight(this.pageSortType === 'createdTime' ? Typography.FONT_WEIGHT_MEDIUM : Typography.FONT_WEIGHT_NORMAL)
            .layoutWeight(1)

          if (this.pageSortType === 'createdTime') {
            Text(this.pageSortOrder === 'asc' ? '↑' : '↓')
              .fontSize(Typography.FONT_SIZE_MD)
              .fontColor(this.themeColors.PRIMARY)
              .margin({ right: Spacing.MARGIN_SM })
              .onClick(() => {
                this.toggleSortOrder();
              })
          }
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .onClick(() => {
          if (this.pageSortType !== 'createdTime') {
            this.pageSortType = 'createdTime';
            this.sortPages();
          }
        })

        Row() {
          Text('修改时间')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.pageSortType === 'modifiedTime' ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
            .fontWeight(this.pageSortType === 'modifiedTime' ? Typography.FONT_WEIGHT_MEDIUM : Typography.FONT_WEIGHT_NORMAL)
            .layoutWeight(1)

          if (this.pageSortType === 'modifiedTime') {
            Text(this.pageSortOrder === 'asc' ? '↑' : '↓')
              .fontSize(Typography.FONT_SIZE_MD)
              .fontColor(this.themeColors.PRIMARY)
              .margin({ right: Spacing.MARGIN_SM })
              .onClick(() => {
                this.toggleSortOrder();
              })
          }
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .onClick(() => {
          if (this.pageSortType !== 'modifiedTime') {
            this.pageSortType = 'modifiedTime';
            this.sortPages();
          }
        })

        Row() {
          Text('内容长度')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.pageSortType === 'contentLength' ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
            .fontWeight(this.pageSortType === 'contentLength' ? Typography.FONT_WEIGHT_MEDIUM : Typography.FONT_WEIGHT_NORMAL)
            .layoutWeight(1)

          if (this.pageSortType === 'contentLength') {
            Text(this.pageSortOrder === 'asc' ? '↑' : '↓')
              .fontSize(Typography.FONT_SIZE_MD)
              .fontColor(this.themeColors.PRIMARY)
              .margin({ right: Spacing.MARGIN_SM })
              .onClick(() => {
                this.toggleSortOrder();
              })
          }
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .onClick(() => {
          if (this.pageSortType !== 'contentLength') {
            this.pageSortType = 'contentLength';
            this.sortPages();
          }
        })

        Row() {
          Text('自定义顺序')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.pageSortType === 'order' ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
            .fontWeight(this.pageSortType === 'order' ? Typography.FONT_WEIGHT_MEDIUM : Typography.FONT_WEIGHT_NORMAL)
            .layoutWeight(1)

          if (this.pageSortType === 'order') {
            Text(this.pageSortOrder === 'asc' ? '↑' : '↓')
              .fontSize(Typography.FONT_SIZE_MD)
              .fontColor(this.themeColors.PRIMARY)
              .margin({ right: Spacing.MARGIN_SM })
              .onClick(() => {
                this.toggleSortOrder();
              })
          }
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .onClick(() => {
          if (this.pageSortType !== 'order') {
            this.pageSortType = 'order';
            this.sortPages();
          }
        })
      }
      .width('100%')
      .margin({ bottom: Spacing.MARGIN_LG })

      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showSortDialog = false;
              });
            });
          })
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({
      radius: Spacing.SHADOW_RADIUS_XL,
      color: this.themeColors.SHADOW_COLOR_DARK,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET_XL
    })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }

  @Builder
  buildAIMenu() {
    Column() {
      Text('AI 功能')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })

      Column() {
        Row() {
          Text('📝')
            .fontSize(Typography.FONT_SIZE_LG)
            .margin({ right: Spacing.MARGIN_SM })

          Text('AI 提炼')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .scale({ x: this.buttonScale, y: this.buttonScale })
        .onClick(() => {
          this.animateButtonClick(() => {
            this.showAIAction('extract');
          });
        })

        Row() {
          Text('✨')
            .fontSize(Typography.FONT_SIZE_LG)
            .margin({ right: Spacing.MARGIN_SM })

          Text('AI 润色')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .scale({ x: this.buttonScale, y: this.buttonScale })
        .onClick(() => {
          this.animateButtonClick(() => {
            this.showAIAction('polish');
          });
        })

        Row() {
          Text('📊')
            .fontSize(Typography.FONT_SIZE_LG)
            .margin({ right: Spacing.MARGIN_SM })

          Text('AI 总结')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .scale({ x: this.buttonScale, y: this.buttonScale })
        .onClick(() => {
          this.animateButtonClick(() => {
            this.showAIAction('summarize');
          });
        })

        Row() {
          Text('🚀')
            .fontSize(Typography.FONT_SIZE_LG)
            .margin({ right: Spacing.MARGIN_SM })

          Text('AI 拓展')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.PADDING_MD)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .scale({ x: this.buttonScale, y: this.buttonScale })
        .onClick(() => {
          this.animateButtonClick(() => {
            this.showAIAction('expand');
          });
        })
      }
      .width('100%')
      .margin({ bottom: Spacing.MARGIN_LG })

      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.showAIMenu = false;
            });
          })
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({
      radius: Spacing.SHADOW_RADIUS_XL,
      color: this.themeColors.SHADOW_COLOR_DARK,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET_XL
    })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }

  @Builder
  buildBatchDeleteDialog() {
    Column() {
      Text('确认删除')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_MD })

      Text(`确定要删除选中的 ${this.selectedPages.size} 个页面吗？删除后将无法恢复。`)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(Typography.LINE_HEIGHT_LG)
        .margin({ bottom: Spacing.MARGIN_XL })

      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showBatchDeleteDialog = false;
              });
            });
          })

        Button('删除')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.ERROR)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.PADDING_MD })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.confirmBatchDelete();
            });
          })
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({
      radius: Spacing.SHADOW_RADIUS_XL,
      color: this.themeColors.SHADOW_COLOR_DARK,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET_XL
    })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }
}

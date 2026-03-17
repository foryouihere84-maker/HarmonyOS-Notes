import { Page } from '../models/Page';
import { PageService } from '../services/PageService';
import { Logger } from '../utils/Logger';

/**
 * 页面视图模型
 * 负责页面列表和编辑的业务逻辑
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class PageViewModel {
  private static instance: PageViewModel;
  private pageService: PageService;
  
  public pages: Page[] = [];
  public currentPage: Page | null = null;
  public isLoading: boolean = false;
  public errorMessage: string = '';
  
  private constructor() {
    this.pageService = PageService.getInstance();
  }
  
  public static getInstance(): PageViewModel {
    if (!PageViewModel.instance) {
      PageViewModel.instance = new PageViewModel();
    }
    return PageViewModel.instance;
  }
  
  /**
   * 加载笔记本的所有页面
   * @param notebookId 笔记本ID
   */
  public async loadPages(notebookId: string): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      this.pages = await this.pageService.getPagesByNotebookId(notebookId);
      Logger.i('PageViewModel', `加载页面成功, 数量: ${this.pages.length}`);
    } catch (error) {
      this.errorMessage = '加载页面失败';
      Logger.e('PageViewModel', `加载页面失败: ${error}`);
      throw new Error('加载页面失败');
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 创建新页面
   * @param notebookId 笔记本ID
   * @param title 页面标题
   * @param content 页面内容
   */
  public async createPage(notebookId: string, title: string, content: string = ''): Promise<void> {
    try {
      this.errorMessage = '';
      
      const newPage: Page = await this.pageService.createPage(notebookId, title, content);
      this.pages.unshift(newPage);
      
      Logger.i('PageViewModel', `创建页面成功: ${newPage.title}`);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '创建页面失败';
      Logger.e('PageViewModel', `创建页面失败: ${error}`);
      throw new Error(this.errorMessage);
    }
  }
  
  /**
   * 加载页面详情
   * @param pageId 页面ID
   */
  public async loadPage(pageId: string): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      this.currentPage = await this.pageService.getPageById(pageId);
      
      if (!this.currentPage) {
        throw new Error('页面不存在');
      }
      
      Logger.i('PageViewModel', `加载页面成功: ${this.currentPage.title}`);
    } catch (error) {
      this.errorMessage = '加载页面失败';
      Logger.e('PageViewModel', `加载页面失败: ${error}`);
      throw new Error('加载页面失败');
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 保存页面
   * @param page 页面对象
   */
  public async savePage(page: Page): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.pageService.updatePage(page);
      
      const index: number = this.pages.findIndex(p => p.id === page.id);
      if (index !== -1) {
        this.pages[index] = page;
      }
      
      if (this.currentPage && this.currentPage.id === page.id) {
        this.currentPage = page;
      }
      
      Logger.i('PageViewModel', `保存页面成功: ${page.title}`);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存页面失败';
      Logger.e('PageViewModel', `保存页面失败: ${error}`);
      throw new Error(this.errorMessage);
    }
  }
  
  /**
   * 删除页面
   * @param pageId 页面ID
   */
  public async deletePage(pageId: string): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.pageService.deletePage(pageId);
      
      this.pages = this.pages.filter(p => p.id !== pageId);
      
      if (this.currentPage && this.currentPage.id === pageId) {
        this.currentPage = null;
      }
      
      Logger.i('PageViewModel', `删除页面成功, ID: ${pageId}`);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '删除页面失败';
      Logger.e('PageViewModel', `删除页面失败: ${error}`);
      throw new Error(this.errorMessage);
    }
  }
  
  /**
   * 搜索页面
   * @param keyword 关键词
   */
  public async searchPages(keyword: string): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      this.pages = await this.pageService.searchPages(keyword);
      
      Logger.i('PageViewModel', `搜索页面成功, 关键词: ${keyword}, 结果数: ${this.pages.length}`);
    } catch (error) {
      this.errorMessage = '搜索页面失败';
      Logger.e('PageViewModel', `搜索页面失败: ${error}`);
      throw new Error('搜索页面失败');
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 置顶/取消置顶页面
   * @param pageId 页面ID
   * @param isPinned 是否置顶
   */
  public async togglePinPage(pageId: string, isPinned: boolean): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.pageService.togglePinPage(pageId, isPinned);
      
      const page: Page | undefined = this.pages.find(p => p.id === pageId);
      if (page) {
        page.isPinned = isPinned;
      }
      
      if (this.currentPage && this.currentPage.id === pageId) {
        this.currentPage.isPinned = isPinned;
      }
      
      Logger.i('PageViewModel', `${isPinned ? '置顶' : '取消置顶'}页面成功, ID: ${pageId}`);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '操作失败';
      Logger.e('PageViewModel', `操作失败: ${error}`);
      throw new Error(this.errorMessage);
    }
  }
}
import { Page } from '../models/Page';
import { PageDao } from '../database/PageDao';
import { NotebookDao } from '../database/NotebookDao';
import { AppConstants } from '../constants/AppConstants';
import { Logger } from '../utils/Logger';
import { StringUtils } from '../utils/StringUtils';

/**
 * 页面服务
 * 提供页面相关的业务逻辑处理
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class PageService {
  private static instance: PageService;
  private pageDao: PageDao;
  private notebookDao: NotebookDao;
  
  private constructor() {
    this.pageDao = PageDao.getInstance();
    this.notebookDao = NotebookDao.getInstance();
  }
  
  public static getInstance(): PageService {
    if (!PageService.instance) {
      PageService.instance = new PageService();
    }
    return PageService.instance;
  }
  
  /**
   * 创建新页面
   * @param notebookId 笔记本ID
   * @param title 页面标题
   * @param content 页面内容
   * @returns 创建的页面对象
   */
  public async createPage(notebookId: string, title: string, content: string = ''): Promise<Page> {
    if (StringUtils.isEmpty(title)) {
      throw new Error('页面标题不能为空');
    }
    
    if (title.trim().length > AppConstants.MAX_PAGE_TITLE_LENGTH) {
      throw new Error(`页面标题不能超过${AppConstants.MAX_PAGE_TITLE_LENGTH}个字符`);
    }
    
    if (content.length > AppConstants.MAX_PAGE_CONTENT_LENGTH) {
      throw new Error(`页面内容不能超过${AppConstants.MAX_PAGE_CONTENT_LENGTH}个字符`);
    }
    
    const notebook = await this.notebookDao.getById(notebookId);
    if (!notebook) {
      throw new Error('笔记本不存在');
    }
    
    const pages = await this.pageDao.getByNotebookId(notebookId);
    const page: Page = new Page(
      this.generateId(),
      notebookId,
      '',
      title.trim(),
      content,
      Date.now(),
      Date.now(),
      pages.length,
      false,
      false
    );
    
    await this.pageDao.insert(page);
    
    notebook.pageCount = pages.length + 1;
    await this.notebookDao.update(notebook);
    
    Logger.i('PageService', `创建页面成功: ${page.title}`);
    
    return page;
  }
  
  /**
   * 获取所有页面
   * @param notebookId 笔记本ID
   * @returns 页面列表
   */
  public async getPagesByNotebookId(notebookId: string): Promise<Page[]> {
    const pages: Page[] = await this.pageDao.getByNotebookId(notebookId);
    
    pages.sort((a, b) => {
      if (a.isPinned !== b.isPinned) {
        return b.isPinned ? 1 : -1;
      }
      return b.modifiedTime - a.modifiedTime;
    });
    
    return pages;
  }
  
  /**
   * 根据ID获取页面
   * @param id 页面ID
   * @returns 页面对象
   */
  public async getPageById(id: string): Promise<Page | null> {
    return await this.pageDao.getById(id);
  }
  
  /**
   * 更新页面
   * @param page 页面对象
   */
  public async updatePage(page: Page): Promise<void> {
    if (!page.validate()) {
      throw new Error('页面数据无效');
    }
    
    page.modifiedTime = Date.now();
    await this.pageDao.update(page);
    Logger.i('PageService', `更新页面成功: ${page.title}`);
  }
  
  /**
   * 删除页面
   * @param id 页面ID
   */
  public async deletePage(id: string): Promise<void> {
    const page: Page | null = await this.pageDao.getById(id);
    
    if (!page) {
      throw new Error('页面不存在');
    }
    
    await this.pageDao.delete(id);
    
    const notebook = await this.notebookDao.getById(page.notebookId);
    if (notebook) {
      const pages = await this.pageDao.getByNotebookId(page.notebookId);
      notebook.pageCount = pages.length;
      await this.notebookDao.update(notebook);
    }
    
    Logger.i('PageService', `删除页面成功: ${page.title}`);
  }
  
  /**
   * 搜索页面
   * @param keyword 关键词
   * @returns 页面列表
   */
  public async searchPages(keyword: string): Promise<Page[]> {
    if (StringUtils.isEmpty(keyword) || keyword.trim().length < AppConstants.MIN_SEARCH_LENGTH) {
      return [];
    }
    
    const pages: Page[] = await this.pageDao.search(keyword.trim());
    
    const limitedPages = pages.slice(0, AppConstants.MAX_SEARCH_RESULTS);
    Logger.i('PageService', `搜索页面成功, 关键词: ${keyword}, 结果数: ${limitedPages.length}`);
    
    return limitedPages;
  }
  
  /**
   * 置顶/取消置顶页面
   * @param id 页面ID
   * @param isPinned 是否置顶
   */
  public async togglePinPage(id: string, isPinned: boolean): Promise<void> {
    const page: Page | null = await this.pageDao.getById(id);
    
    if (!page) {
      throw new Error('页面不存在');
    }
    
    page.isPinned = isPinned;
    page.modifiedTime = Date.now();
    await this.pageDao.update(page);
    
    Logger.i('PageService', `${isPinned ? '置顶' : '取消置顶'}页面成功: ${page.title}`);
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID
   */
  private generateId(): string {
    return `page_${Date.now()}_${StringUtils.generateRandomString(8)}`;
  }
}
import { Notebook } from '../models/Notebook';
import { NotebookDao } from '../database/NotebookDao';
import { PageDao } from '../database/PageDao';
import { AppConstants } from '../constants/AppConstants';
import { Logger } from '../utils/Logger';
import { StringUtils } from '../utils/StringUtils';

/**
 * 笔记本服务
 * 提供笔记本相关的业务逻辑处理
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class NotebookService {
  private static instance: NotebookService;
  private notebookDao: NotebookDao;
  private pageDao: PageDao;
  
  private constructor() {
    this.notebookDao = NotebookDao.getInstance();
    this.pageDao = PageDao.getInstance();
  }
  
  public static getInstance(): NotebookService {
    if (!NotebookService.instance) {
      NotebookService.instance = new NotebookService();
    }
    return NotebookService.instance;
  }
  
  /**
   * 创建新笔记本
   * @param title 笔记本标题
   * @param coverImage 封面图片
   * @returns 创建的笔记本对象
   */
  public async createNotebook(title: string, coverImage: string = ''): Promise<Notebook> {
    if (StringUtils.isEmpty(title)) {
      throw new Error('笔记本标题不能为空');
    }
    
    if (title.trim().length > AppConstants.MAX_NOTEBOOK_TITLE_LENGTH) {
      throw new Error(`笔记本标题不能超过${AppConstants.MAX_NOTEBOOK_TITLE_LENGTH}个字符`);
    }
    
    const notebook: Notebook = new Notebook(
      this.generateId(),
      title.trim(),
      '',
      this.getRandomColor(),
      AppConstants.DEFAULT_NOTEBOOK_ICON,
      coverImage
    );
    
    await this.notebookDao.insert(notebook);
    Logger.i('NotebookService', `创建笔记本成功: ${notebook.title}`);
    
    return notebook;
  }
  
  /**
   * 获取所有笔记本
   * @returns 笔记本列表
   */
  public async getAllNotebooks(): Promise<Notebook[]> {
    const notebooks: Notebook[] = await this.notebookDao.getAll();
    
    for (const notebook of notebooks) {
      const pages = await this.pageDao.getByNotebookId(notebook.id);
      notebook.pageCount = pages.length;
    }
    
    return notebooks;
  }
  
  /**
   * 根据ID获取笔记本
   * @param id 笔记本ID
   * @returns 笔记本对象
   */
  public async getNotebookById(id: string): Promise<Notebook | null> {
    const notebook: Notebook | null = await this.notebookDao.getById(id);
    
    if (notebook) {
      const pages = await this.pageDao.getByNotebookId(notebook.id);
      notebook.pageCount = pages.length;
    }
    
    return notebook;
  }
  
  /**
   * 更新笔记本
   * @param notebook 笔记本对象
   */
  public async updateNotebook(notebook: Notebook): Promise<void> {
    if (!notebook.validate()) {
      throw new Error('笔记本数据无效');
    }
    
    notebook.modifiedTime = Date.now();
    await this.notebookDao.update(notebook);
    Logger.i('NotebookService', `更新笔记本成功: ${notebook.title}`);
  }
  
  /**
   * 删除笔记本
   * @param id 笔记本ID
   */
  public async deleteNotebook(id: string): Promise<void> {
    const notebook: Notebook | null = await this.notebookDao.getById(id);
    
    if (!notebook) {
      throw new Error('笔记本不存在');
    }
    
    await this.notebookDao.delete(id);
    Logger.i('NotebookService', `删除笔记本成功: ${notebook.title}`);
  }
  
  /**
   * 更新笔记本颜色
   * @param id 笔记本ID
   * @param color 颜色
   */
  public async updateNotebookColor(id: string, color: string): Promise<void> {
    const notebook: Notebook | null = await this.notebookDao.getById(id);
    
    if (!notebook) {
      throw new Error('笔记本不存在');
    }
    
    notebook.color = color;
    notebook.modifiedTime = Date.now();
    await this.notebookDao.update(notebook);
  }
  
  /**
   * 更新笔记本图标
   * @param id 笔记本ID
   * @param icon 图标
   */
  public async updateNotebookIcon(id: string, icon: string): Promise<void> {
    const notebook: Notebook | null = await this.notebookDao.getById(id);
    
    if (!notebook) {
      throw new Error('笔记本不存在');
    }
    
    notebook.icon = icon;
    notebook.modifiedTime = Date.now();
    await this.notebookDao.update(notebook);
  }
  
  /**
   * 更新笔记本封面图片
   * @param id 笔记本ID
   * @param coverImage 封面图片路径
   */
  public async updateNotebookCoverImage(id: string, coverImage: string): Promise<void> {
    const notebook: Notebook | null = await this.notebookDao.getById(id);
    
    if (!notebook) {
      throw new Error('笔记本不存在');
    }
    
    notebook.coverImage = coverImage;
    notebook.modifiedTime = Date.now();
    await this.notebookDao.update(notebook);
  }
  
  /**
   * 搜索笔记本
   * @param keyword 关键词
   * @returns 笔记本列表
   */
  public async searchNotebooks(keyword: string): Promise<Notebook[]> {
    const allNotebooks: Notebook[] = await this.notebookDao.getAll();
    const lowerKeyword = keyword.toLowerCase();
    
    const filteredNotebooks: Notebook[] = allNotebooks.filter(notebook => {
      return notebook.title.toLowerCase().includes(lowerKeyword) ||
        notebook.description.toLowerCase().includes(lowerKeyword);
    });
    
    for (const notebook of filteredNotebooks) {
      const pages = await this.pageDao.getByNotebookId(notebook.id);
      notebook.pageCount = pages.length;
    }
    
    return filteredNotebooks;
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID
   */
  private generateId(): string {
    return `notebook_${Date.now()}_${StringUtils.generateRandomString(8)}`;
  }
  
  /**
   * 获取随机颜色
   * @returns 随机颜色
   */
  private getRandomColor(): string {
    const colors: string[] = AppConstants.NOTEBOOK_COLORS;
    return colors[Math.floor(Math.random() * colors.length)];
  }
}
import { Notebook } from '../models/Notebook';
import { NotebookService } from '../services/NotebookService';
import { Logger } from '../utils/Logger';

/**
 * 笔记本视图模型
 * 负责笔记本列表的业务逻辑
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class NotebookViewModel {
  private static instance: NotebookViewModel;
  private notebookService: NotebookService;
  
  public notebooks: Notebook[] = [];
  public isLoading: boolean = false;
  public errorMessage: string = '';
  
  private constructor() {
    this.notebookService = NotebookService.getInstance();
  }
  
  public static getInstance(): NotebookViewModel {
    if (!NotebookViewModel.instance) {
      NotebookViewModel.instance = new NotebookViewModel();
    }
    return NotebookViewModel.instance;
  }
  
  /**
   * 加载所有笔记本
   */
  public async loadNotebooks(): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      this.notebooks = await this.notebookService.getAllNotebooks();
      Logger.i('NotebookViewModel', `加载笔记本成功, 数量: ${this.notebooks.length}`);
    } catch (error) {
      this.errorMessage = '加载笔记本失败';
      Logger.e('NotebookViewModel', `加载笔记本失败: ${error}`);
      throw new Error('加载笔记本失败');
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 创建新笔记本
   * @param title 笔记本标题
   * @param coverImage 封面图片
   */
  public async createNotebook(title: string, coverImage: string = ''): Promise<void> {
    try {
      this.errorMessage = '';
      
      const newNotebook: Notebook = await this.notebookService.createNotebook(title, coverImage);
      this.notebooks.unshift(newNotebook);
      
      Logger.i('NotebookViewModel', `创建笔记本成功: ${newNotebook.title}`);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '创建笔记本失败';
      Logger.e('NotebookViewModel', `创建笔记本失败: ${error}`);
      throw new Error(this.errorMessage);
    }
  }
  
  /**
   * 更新笔记本
   * @param notebook 笔记本对象
   */
  public async updateNotebook(notebook: Notebook): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.notebookService.updateNotebook(notebook);
      
      const index: number = this.notebooks.findIndex(n => n.id === notebook.id);
      if (index !== -1) {
        this.notebooks[index] = notebook;
      }
      
      Logger.i('NotebookViewModel', `更新笔记本成功: ${notebook.title}`);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '更新笔记本失败';
      Logger.e('NotebookViewModel', `更新笔记本失败: ${error}`);
      throw new Error(this.errorMessage);
    }
  }
  
  /**
   * 删除笔记本
   * @param id 笔记本ID
   */
  public async deleteNotebook(id: string): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.notebookService.deleteNotebook(id);
      
      this.notebooks = this.notebooks.filter(n => n.id !== id);
      
      Logger.i('NotebookViewModel', `删除笔记本成功, ID: ${id}`);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '删除笔记本失败';
      Logger.e('NotebookViewModel', `删除笔记本失败: ${error}`);
      throw new Error(this.errorMessage);
    }
  }
  
  /**
   * 根据ID获取笔记本
   * @param id 笔记本ID
   * @returns 笔记本对象
   */
  public async getNotebookById(id: string): Promise<Notebook | null> {
    try {
      this.errorMessage = '';
      
      const notebook: Notebook | null = await this.notebookService.getNotebookById(id);
      return notebook;
    } catch (error) {
      this.errorMessage = '获取笔记本失败';
      Logger.e('NotebookViewModel', `获取笔记本失败: ${error}`);
      throw new Error('获取笔记本失败');
    }
  }
  
  /**
   * 搜索笔记本
   * @param keyword 关键词
   */
  public async searchNotebooks(keyword: string): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      this.notebooks = await this.notebookService.searchNotebooks(keyword);
      
      Logger.i('NotebookViewModel', `搜索笔记本成功, 关键词: ${keyword}, 结果数: ${this.notebooks.length}`);
    } catch (error) {
      this.errorMessage = '搜索笔记本失败';
      Logger.e('NotebookViewModel', `搜索笔记本失败: ${error}`);
      throw new Error('搜索笔记本失败');
    } finally {
      this.isLoading = false;
    }
  }
}
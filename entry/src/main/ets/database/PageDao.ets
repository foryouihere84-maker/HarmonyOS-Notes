import relationalStore from '@ohos.data.relationalStore';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { Page } from '../models/Page';
import { DatabaseHelper } from './DatabaseHelper';
import { Logger } from '../utils/Logger';

/**
 * 页面数据访问对象
 * 负责页面数据的CRUD操作
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class PageDao {
  private static instance: PageDao;
  
  private constructor() {}
  
  public static getInstance(): PageDao {
    if (!PageDao.instance) {
      PageDao.instance = new PageDao();
    }
    return PageDao.instance;
  }
  
  /**
   * 插入页面
   * @param page 页面对象
   * @returns 插入的行ID
   */
  public async insert(page: Page): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_ID] = page.id;
    valueBucket[DatabaseConstants.FIELD_NOTEBOOK_ID] = page.notebookId;
    valueBucket[DatabaseConstants.FIELD_SECTION_ID] = page.sectionId;
    valueBucket[DatabaseConstants.FIELD_TITLE] = page.title;
    valueBucket[DatabaseConstants.FIELD_CONTENT] = page.content;
    valueBucket[DatabaseConstants.FIELD_CREATED_TIME] = page.createdTime;
    valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = page.modifiedTime;
    valueBucket[DatabaseConstants.FIELD_ORDER] = page.order;
    valueBucket[DatabaseConstants.FIELD_IS_PINNED] = page.isPinned ? 1 : 0;
    valueBucket[DatabaseConstants.FIELD_IS_DELETED] = page.isDeleted ? 1 : 0;
    valueBucket[DatabaseConstants.FIELD_BACKGROUND_COLOR] = page.backgroundColor;
    valueBucket[DatabaseConstants.FIELD_FONT_SIZE] = page.fontSize;
    
    try {
      const rowId: number = await rdbStore.insert(DatabaseConstants.TABLE_PAGES, valueBucket);
      Logger.i('PageDao', `插入页面成功, ID: ${page.id}`);
      return rowId;
    } catch (error) {
      Logger.e('PageDao', `插入页面失败: ${error}`);
      throw new Error('插入页面失败');
    }
  }
  
  /**
   * 更新页面
   * @param page 页面对象
   * @returns 更新的行数
   */
  public async update(page: Page): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_TITLE] = page.title;
    valueBucket[DatabaseConstants.FIELD_CONTENT] = page.content;
    valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = page.modifiedTime;
    valueBucket[DatabaseConstants.FIELD_IS_PINNED] = page.isPinned ? 1 : 0;
    valueBucket[DatabaseConstants.FIELD_IS_DELETED] = page.isDeleted ? 1 : 0;
    valueBucket[DatabaseConstants.FIELD_BACKGROUND_COLOR] = page.backgroundColor;
    valueBucket[DatabaseConstants.FIELD_FONT_SIZE] = page.fontSize;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_PAGES);
    predicates.equalTo(DatabaseConstants.FIELD_ID, page.id);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('PageDao', `更新页面成功, ID: ${page.id}`);
      return rows;
    } catch (error) {
      Logger.e('PageDao', `更新页面失败: ${error}`);
      throw new Error('更新页面失败');
    }
  }
  
  /**
   * 删除页面
   * @param id 页面ID
   * @returns 删除的行数
   */
  public async delete(id: string): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_PAGES);
    predicates.equalTo(DatabaseConstants.FIELD_ID, id);
    
    try {
      const rows: number = await rdbStore.delete(predicates);
      Logger.i('PageDao', `删除页面成功, ID: ${id}`);
      return rows;
    } catch (error) {
      Logger.e('PageDao', `删除页面失败: ${error}`);
      throw new Error('删除页面失败');
    }
  }
  
  /**
   * 根据ID查询页面
   * @param id 页面ID
   * @returns 页面对象
   */
  public async getById(id: string): Promise<Page | null> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_PAGES);
    predicates.equalTo(DatabaseConstants.FIELD_ID, id);
    
    try {
      const resultSet = await rdbStore.query(predicates);
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const page: Page = this.resultSetToPage(resultSet);
      resultSet.close();
      
      return page;
    } catch (error) {
      Logger.e('PageDao', `查询页面失败: ${error}`);
      throw new Error('查询页面失败');
    }
  }
  
  /**
   * 根据笔记本ID查询所有页面
   * @param notebookId 笔记本ID
   * @returns 页面列表
   */
  public async getByNotebookId(notebookId: string): Promise<Page[]> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_PAGES);
    predicates.equalTo(DatabaseConstants.FIELD_NOTEBOOK_ID, notebookId);
    predicates.equalTo(DatabaseConstants.FIELD_IS_DELETED, 0);
    predicates.orderByDesc(DatabaseConstants.FIELD_MODIFIED_TIME);
    
    try {
      const resultSet = await rdbStore.query(predicates);
      const pages: Page[] = [];
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          pages.push(this.resultSetToPage(resultSet));
        } while (resultSet.goToNextRow());
      }
      
      resultSet.close();
      return pages;
    } catch (error) {
      Logger.e('PageDao', `查询笔记本页面失败: ${error}`);
      throw new Error('查询笔记本页面失败');
    }
  }
  
  /**
   * 搜索页面
   * @param keyword 关键词
   * @returns 页面列表
   */
  public async search(keyword: string): Promise<Page[]> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_PAGES);
    predicates.equalTo(DatabaseConstants.FIELD_IS_DELETED, 0);
    predicates.or();
    predicates.contains(DatabaseConstants.FIELD_TITLE, keyword);
    predicates.or();
    predicates.contains(DatabaseConstants.FIELD_CONTENT, keyword);
    predicates.orderByDesc(DatabaseConstants.FIELD_MODIFIED_TIME);
    
    try {
      const resultSet = await rdbStore.query(predicates);
      const pages: Page[] = [];
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          pages.push(this.resultSetToPage(resultSet));
        } while (resultSet.goToNextRow());
      }
      
      resultSet.close();
      return pages;
    } catch (error) {
      Logger.e('PageDao', `搜索页面失败: ${error}`);
      throw new Error('搜索页面失败');
    }
  }
  
  /**
   * 获取所有页面总数
   * @returns 页面总数
   */
  public async getTotalPageCount(): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_PAGES);
    predicates.equalTo(DatabaseConstants.FIELD_IS_DELETED, 0);
    
    try {
      const resultSet = await rdbStore.query(predicates, ['COUNT(*) as count']);
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(resultSet.getColumnIndex('count'));
      }
      resultSet.close();
      return count;
    } catch (error) {
      Logger.e('PageDao', `获取页面总数失败: ${error}`);
      return 0;
    }
  }
  
  /**
   * 获取今天修改过的页面数量
   * @returns 今日编辑页面数
   */
  public async getTodayEditedCount(): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStart = today.getTime();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_PAGES);
    predicates.equalTo(DatabaseConstants.FIELD_IS_DELETED, 0);
    predicates.greaterThanOrEqualTo(DatabaseConstants.FIELD_MODIFIED_TIME, todayStart);
    
    try {
      const resultSet = await rdbStore.query(predicates, ['COUNT(*) as count']);
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(resultSet.getColumnIndex('count'));
      }
      resultSet.close();
      return count;
    } catch (error) {
      Logger.e('PageDao', `获取今日编辑数失败: ${error}`);
      return 0;
    }
  }
  
  /**
   * 将结果集转换为页面对象
   * @param resultSet 结果集
   * @returns 页面对象
   */
  private resultSetToPage(resultSet: relationalStore.ResultSet): Page {
    try {
      const backgroundColorIndex = resultSet.getColumnIndex(DatabaseConstants.FIELD_BACKGROUND_COLOR);
      const backgroundColor = backgroundColorIndex >= 0 ? 
        resultSet.getString(backgroundColorIndex) : '#FFFFFF';
      
      const fontSizeIndex = resultSet.getColumnIndex(DatabaseConstants.FIELD_FONT_SIZE);
      const fontSize = fontSizeIndex >= 0 ? 
        resultSet.getLong(fontSizeIndex) : 36;
      
      return new Page(
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ID)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_NOTEBOOK_ID)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_SECTION_ID)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_TITLE)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_CONTENT)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_CREATED_TIME)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_MODIFIED_TIME)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ORDER)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_IS_PINNED)) === 1,
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_IS_DELETED)) === 1,
        [],
        backgroundColor,
        fontSize
      );
    } catch (error) {
      Logger.e('PageDao', `转换结果集失败: ${error}`);
      return new Page();
    }
  }
}
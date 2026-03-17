import relationalStore from '@ohos.data.relationalStore';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { Notebook } from '../models/Notebook';
import { DatabaseHelper } from './DatabaseHelper';
import { Logger } from '../utils/Logger';

/**
 * 笔记本数据访问对象
 * 负责笔记本数据的CRUD操作
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class NotebookDao {
  private static instance: NotebookDao;
  
  private constructor() {}
  
  public static getInstance(): NotebookDao {
    if (!NotebookDao.instance) {
      NotebookDao.instance = new NotebookDao();
    }
    return NotebookDao.instance;
  }
  
  /**
   * 插入笔记本
   * @param notebook 笔记本对象
   * @returns 插入的行ID
   */
  public async insert(notebook: Notebook): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_ID] = notebook.id;
    valueBucket[DatabaseConstants.FIELD_TITLE] = notebook.title;
    valueBucket[DatabaseConstants.FIELD_DESCRIPTION] = notebook.description;
    valueBucket[DatabaseConstants.FIELD_COLOR] = notebook.color;
    valueBucket[DatabaseConstants.FIELD_ICON] = notebook.icon;
    valueBucket[DatabaseConstants.FIELD_COVER_IMAGE] = notebook.coverImage;
    valueBucket[DatabaseConstants.FIELD_CREATED_TIME] = notebook.createdTime;
    valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = notebook.modifiedTime;
    valueBucket[DatabaseConstants.FIELD_PAGE_COUNT] = notebook.pageCount;
    
    try {
      const rowId: number = await rdbStore.insert(DatabaseConstants.TABLE_NOTEBOOKS, valueBucket);
      Logger.i('NotebookDao', `插入笔记本成功, ID: ${notebook.id}`);
      return rowId;
    } catch (error) {
      Logger.e('NotebookDao', `插入笔记本失败: ${error}`);
      throw new Error('插入笔记本失败');
    }
  }
  
  /**
   * 更新笔记本
   * @param notebook 笔记本对象
   * @returns 更新的行数
   */
  public async update(notebook: Notebook): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_TITLE] = notebook.title;
    valueBucket[DatabaseConstants.FIELD_DESCRIPTION] = notebook.description;
    valueBucket[DatabaseConstants.FIELD_COLOR] = notebook.color;
    valueBucket[DatabaseConstants.FIELD_ICON] = notebook.icon;
    valueBucket[DatabaseConstants.FIELD_COVER_IMAGE] = notebook.coverImage;
    valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = notebook.modifiedTime;
    valueBucket[DatabaseConstants.FIELD_PAGE_COUNT] = notebook.pageCount;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_NOTEBOOKS);
    predicates.equalTo(DatabaseConstants.FIELD_ID, notebook.id);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('NotebookDao', `更新笔记本成功, ID: ${notebook.id}`);
      return rows;
    } catch (error) {
      Logger.e('NotebookDao', `更新笔记本失败: ${error}`);
      throw new Error('更新笔记本失败');
    }
  }
  
  /**
   * 删除笔记本
   * @param id 笔记本ID
   * @returns 删除的行数
   */
  public async delete(id: string): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_NOTEBOOKS);
    predicates.equalTo(DatabaseConstants.FIELD_ID, id);
    
    try {
      const rows: number = await rdbStore.delete(predicates);
      Logger.i('NotebookDao', `删除笔记本成功, ID: ${id}`);
      return rows;
    } catch (error) {
      Logger.e('NotebookDao', `删除笔记本失败: ${error}`);
      throw new Error('删除笔记本失败');
    }
  }
  
  /**
   * 根据ID查询笔记本
   * @param id 笔记本ID
   * @returns 笔记本对象
   */
  public async getById(id: string): Promise<Notebook | null> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_NOTEBOOKS);
    predicates.equalTo(DatabaseConstants.FIELD_ID, id);
    
    try {
      const resultSet = await rdbStore.query(predicates);
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const notebook: Notebook = this.resultSetToNotebook(resultSet);
      resultSet.close();
      
      return notebook;
    } catch (error) {
      Logger.e('NotebookDao', `查询笔记本失败: ${error}`);
      throw new Error('查询笔记本失败');
    }
  }
  
  /**
   * 查询所有笔记本
   * @returns 笔记本列表
   */
  public async getAll(): Promise<Notebook[]> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_NOTEBOOKS);
    predicates.orderByDesc(DatabaseConstants.FIELD_MODIFIED_TIME);
    
    try {
      const resultSet = await rdbStore.query(predicates);
      const notebooks: Notebook[] = [];
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          notebooks.push(this.resultSetToNotebook(resultSet));
        } while (resultSet.goToNextRow());
      }
      
      resultSet.close();
      return notebooks;
    } catch (error) {
      Logger.e('NotebookDao', `查询所有笔记本失败: ${error}`);
      throw new Error('查询所有笔记本失败');
    }
  }
  
  /**
   * 更新笔记本页面数量
   * @param id 笔记本ID
   * @param count 页面数量
   * @returns 更新的行数
   */
  public async updatePageCount(id: string, count: number): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_PAGE_COUNT] = count;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_NOTEBOOKS);
    predicates.equalTo(DatabaseConstants.FIELD_ID, id);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      return rows;
    } catch (error) {
      Logger.e('NotebookDao', `更新页面数量失败: ${error}`);
      throw new Error('更新页面数量失败');
    }
  }
  
  /**
   * 将结果集转换为笔记本对象
   * @param resultSet 结果集
   * @returns 笔记本对象
   */
  private resultSetToNotebook(resultSet: relationalStore.ResultSet): Notebook {
    try {
      return new Notebook(
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ID)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_TITLE)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_DESCRIPTION)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_COLOR)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ICON)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_COVER_IMAGE)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_CREATED_TIME)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_MODIFIED_TIME)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_PAGE_COUNT))
      );
    } catch (error) {
      Logger.e('NotebookDao', `转换结果集失败: ${error}`);
      return new Notebook();
    }
  }
}
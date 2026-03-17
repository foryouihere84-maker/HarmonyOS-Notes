import relationalStore from '@ohos.data.relationalStore';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { UserSettings } from '../models/UserSettings';
import { DatabaseHelper } from './DatabaseHelper';
import { Logger } from '../utils/Logger';

/**
 * 用户设置数据访问对象
 * 负责用户设置数据的CRUD操作
 * 
 * @author 开发者
 * @date 2026-03-12
 */
export class UserSettingsDao {
  private static instance: UserSettingsDao;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   * @returns UserSettingsDao实例
   */
  public static getInstance(): UserSettingsDao {
    if (!UserSettingsDao.instance) {
      UserSettingsDao.instance = new UserSettingsDao();
    }
    return UserSettingsDao.instance;
  }
  
  /**
   * 插入用户设置
   * @param settings 用户设置对象
   * @returns 插入的行ID
   */
  public async insert(settings: UserSettings): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_USER_ID] = settings.userId;
    valueBucket[DatabaseConstants.FIELD_USERNAME] = settings.username;
    valueBucket[DatabaseConstants.FIELD_AVATAR] = settings.avatar;
    valueBucket[DatabaseConstants.FIELD_THEME_MODE] = settings.themeMode;
    valueBucket[DatabaseConstants.FIELD_CACHE_SIZE] = settings.cacheSize;
    valueBucket[DatabaseConstants.FIELD_LAST_CLEAR_CACHE_TIME] = settings.lastClearCacheTime;
    
    try {
      const rowId: number = await rdbStore.insert(DatabaseConstants.TABLE_USER_SETTINGS, valueBucket);
      Logger.i('UserSettingsDao', `插入用户设置成功, UserID: ${settings.userId}`);
      return rowId;
    } catch (error) {
      Logger.e('UserSettingsDao', `插入用户设置失败: ${error}`);
      throw new Error('插入用户设置失败');
    }
  }
  
  /**
   * 更新用户设置
   * @param settings 用户设置对象
   * @returns 更新的行数
   */
  public async update(settings: UserSettings): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_USERNAME] = settings.username;
    valueBucket[DatabaseConstants.FIELD_AVATAR] = settings.avatar;
    valueBucket[DatabaseConstants.FIELD_THEME_MODE] = settings.themeMode;
    valueBucket[DatabaseConstants.FIELD_CACHE_SIZE] = settings.cacheSize;
    valueBucket[DatabaseConstants.FIELD_LAST_CLEAR_CACHE_TIME] = settings.lastClearCacheTime;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, settings.userId);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('UserSettingsDao', `更新用户设置成功, UserID: ${settings.userId}`);
      return rows;
    } catch (error) {
      Logger.e('UserSettingsDao', `更新用户设置失败: ${error}`);
      throw new Error('更新用户设置失败');
    }
  }
  
  /**
   * 删除用户设置
   * @param userId 用户ID
   * @returns 删除的行数
   */
  public async delete(userId: string): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
    
    try {
      const rows: number = await rdbStore.delete(predicates);
      Logger.i('UserSettingsDao', `删除用户设置成功, UserID: ${userId}`);
      return rows;
    } catch (error) {
      Logger.e('UserSettingsDao', `删除用户设置失败: ${error}`);
      throw new Error('删除用户设置失败');
    }
  }
  
  /**
   * 根据用户ID查询设置
   * @param userId 用户ID
   * @returns 用户设置对象，不存在返回null
   */
  public async getByUserId(userId: string): Promise<UserSettings | null> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
    
    try {
      const resultSet = await rdbStore.query(predicates);
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const settings: UserSettings = this.resultSetToUserSettings(resultSet);
      resultSet.close();
      
      return settings;
    } catch (error) {
      Logger.e('UserSettingsDao', `查询用户设置失败: ${error}`);
      throw new Error('查询用户设置失败');
    }
  }
  
  /**
   * 查询所有用户设置
   * @returns 用户设置列表
   */
  public async getAll(): Promise<UserSettings[]> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    
    try {
      const resultSet = await rdbStore.query(predicates);
      const settingsList: UserSettings[] = [];
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          settingsList.push(this.resultSetToUserSettings(resultSet));
        } while (resultSet.goToNextRow());
      }
      
      resultSet.close();
      return settingsList;
    } catch (error) {
      Logger.e('UserSettingsDao', `查询所有用户设置失败: ${error}`);
      throw new Error('查询所有用户设置失败');
    }
  }
  
  /**
   * 检查用户设置是否存在
   * @param userId 用户ID
   * @returns 是否存在
   */
  public async exists(userId: string): Promise<boolean> {
    const settings: UserSettings | null = await this.getByUserId(userId);
    return settings !== null;
  }
  
  /**
   * 更新用户名
   * @param userId 用户ID
   * @param username 用户名
   * @returns 更新的行数
   */
  public async updateUsername(userId: string, username: string): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_USERNAME] = username;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('UserSettingsDao', `更新用户名成功, UserID: ${userId}, Username: ${username}`);
      return rows;
    } catch (error) {
      Logger.e('UserSettingsDao', `更新用户名失败: ${error}`);
      throw new Error('更新用户名失败');
    }
  }
  
  /**
   * 更新头像
   * @param userId 用户ID
   * @param avatar 头像路径
   * @returns 更新的行数
   */
  public async updateAvatar(userId: string, avatar: string): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_AVATAR] = avatar;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('UserSettingsDao', `更新头像成功, UserID: ${userId}`);
      return rows;
    } catch (error) {
      Logger.e('UserSettingsDao', `更新头像失败: ${error}`);
      throw new Error('更新头像失败');
    }
  }
  
  /**
   * 更新主题模式
   * @param userId 用户ID
   * @param themeMode 主题模式
   * @returns 更新的行数
   */
  public async updateThemeMode(userId: string, themeMode: 'light' | 'dark' | 'auto'): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_THEME_MODE] = themeMode;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('UserSettingsDao', `更新主题模式成功, UserID: ${userId}, Theme: ${themeMode}`);
      return rows;
    } catch (error) {
      Logger.e('UserSettingsDao', `更新主题模式失败: ${error}`);
      throw new Error('更新主题模式失败');
    }
  }
  
  /**
   * 更新缓存大小
   * @param userId 用户ID
   * @param cacheSize 缓存大小
   * @returns 更新的行数
   */
  public async updateCacheSize(userId: string, cacheSize: string): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_CACHE_SIZE] = cacheSize;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('UserSettingsDao', `更新缓存大小成功, UserID: ${userId}, CacheSize: ${cacheSize}`);
      return rows;
    } catch (error) {
      Logger.e('UserSettingsDao', `更新缓存大小失败: ${error}`);
      throw new Error('更新缓存大小失败');
    }
  }
  
  /**
   * 更新最后清除缓存时间
   * @param userId 用户ID
   * @param lastClearCacheTime 最后清除缓存时间
   * @returns 更新的行数
   */
  public async updateLastClearCacheTime(userId: string, lastClearCacheTime: number): Promise<number> {
    const rdbStore: relationalStore.RdbStore = DatabaseHelper.getInstance().getRdbStore();
    
    const valueBucket: relationalStore.ValuesBucket = {};
    valueBucket[DatabaseConstants.FIELD_LAST_CLEAR_CACHE_TIME] = lastClearCacheTime;
    
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_USER_SETTINGS);
    predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
    
    try {
      const rows: number = await rdbStore.update(valueBucket, predicates);
      Logger.i('UserSettingsDao', `更新最后清除缓存时间成功, UserID: ${userId}`);
      return rows;
    } catch (error) {
      Logger.e('UserSettingsDao', `更新最后清除缓存时间失败: ${error}`);
      throw new Error('更新最后清除缓存时间失败');
    }
  }
  
  /**
   * 将结果集转换为用户设置对象
   * @param resultSet 结果集
   * @returns 用户设置对象
   */
  private resultSetToUserSettings(resultSet: relationalStore.ResultSet): UserSettings {
    try {
      return new UserSettings(
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_USER_ID)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_USERNAME)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_AVATAR)),
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_THEME_MODE)) as 'light' | 'dark' | 'auto',
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_CACHE_SIZE)),
        resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_LAST_CLEAR_CACHE_TIME))
      );
    } catch (error) {
      Logger.e('UserSettingsDao', `转换结果集失败: ${error}`);
      return new UserSettings();
    }
  }
}

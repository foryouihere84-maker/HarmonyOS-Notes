import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { Logger } from '../utils/Logger';

/**
 * 数据库帮助类
 * 负责数据库的初始化和管理
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: common.Context | null = null;
  
  private constructor() {}
  
  public static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }
  
  /**
   * 初始化数据库
   * @param context 上下文
   */
  public async init(context: common.Context): Promise<void> {
    if (this.rdbStore) {
      return;
    }
    
    this.context = context;
    
    const config: relationalStore.StoreConfig = {
      name: DatabaseConstants.DATABASE_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      await this.createIndexes();
      await this.upgradeDatabase();
      Logger.i('DatabaseHelper', '数据库初始化成功');
    } catch (error) {
      Logger.e('DatabaseHelper', '数据库初始化失败');
      throw new Error('数据库初始化失败');
    }
  }
  
  /**
   * 创建数据表
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    
    try {
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_NOTEBOOKS_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_PAGES_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_SECTIONS_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_TAGS_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_PAGE_TAGS_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_USER_SETTINGS_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_SYNC_CONFIGS_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_SYNC_HISTORY_TABLE);
      await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_LOGIN_INFO_TABLE);
      Logger.i('DatabaseHelper', '数据表创建成功');
    } catch (error) {
      Logger.e('DatabaseHelper', '创建数据表失败');
      throw new Error('创建数据表失败');
    }
  }
  
  /**
   * 创建索引
   */
  private async createIndexes(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    
    try {
      for (const sql of DatabaseConstants.SQL_CREATE_INDEXS) {
        try {
          await this.rdbStore.executeSql(sql);
        } catch (indexError) {
          Logger.w('DatabaseHelper', `创建索引失败: ${indexError}`);
        }
      }
      Logger.i('DatabaseHelper', '索引创建成功');
    } catch (error) {
      Logger.e('DatabaseHelper', '创建索引失败');
      throw new Error('创建索引失败');
    }
  }
  
  /**
   * 升级数据库
   */
  private async upgradeDatabase(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    
    try {
      await this.addCoverImageColumn();
      await this.addBackgroundColorColumn();
      await this.addFontSizeColumn();
      await this.addConflictResolutionColumn();
      Logger.i('DatabaseHelper', '数据库升级成功');
    } catch (error) {
      Logger.e('DatabaseHelper', `数据库升级失败: ${error}`);
    }
  }
  
  /**
   * 添加cover_image列到notebooks表
   */
  private async addCoverImageColumn(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    
    try {
      const sql = `ALTER TABLE ${DatabaseConstants.TABLE_NOTEBOOKS} ADD COLUMN ${DatabaseConstants.FIELD_COVER_IMAGE} TEXT DEFAULT ''`;
      await this.rdbStore.executeSql(sql);
      Logger.i('DatabaseHelper', '添加cover_image列成功');
    } catch (error) {
      if (error instanceof Error && error.message.includes('duplicate column')) {
        Logger.i('DatabaseHelper', 'cover_image列已存在，跳过添加');
      } else {
        Logger.w('DatabaseHelper', `添加cover_image列失败: ${error}`);
      }
    }
  }
  
  /**
   * 添加background_color列到pages表
   */
  private async addBackgroundColorColumn(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    
    try {
      const sql = `ALTER TABLE ${DatabaseConstants.TABLE_PAGES} ADD COLUMN ${DatabaseConstants.FIELD_BACKGROUND_COLOR} TEXT DEFAULT '#FFFFFF'`;
      await this.rdbStore.executeSql(sql);
      Logger.i('DatabaseHelper', '添加background_color列成功');
    } catch (error) {
      if (error instanceof Error && error.message.includes('duplicate column')) {
        Logger.i('DatabaseHelper', 'background_color列已存在，跳过添加');
      } else {
        Logger.w('DatabaseHelper', `添加background_color列失败: ${error}`);
      }
    }
  }
  
  private async addFontSizeColumn(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    
    try {
      const sql = `ALTER TABLE ${DatabaseConstants.TABLE_PAGES} ADD COLUMN ${DatabaseConstants.FIELD_FONT_SIZE} INTEGER DEFAULT 36`;
      await this.rdbStore.executeSql(sql);
      Logger.i('DatabaseHelper', '添加font_size列成功');
    } catch (error) {
      if (error instanceof Error && error.message.includes('duplicate column')) {
        Logger.i('DatabaseHelper', 'font_size列已存在，跳过添加');
      } else {
        Logger.w('DatabaseHelper', `添加font_size列失败: ${error}`);
      }
    }
  }
  
  /**
   * 添加conflict_resolution列到sync_configs表
   */
  private async addConflictResolutionColumn(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    
    try {
      const sql = `ALTER TABLE ${DatabaseConstants.TABLE_SYNC_CONFIGS} ADD COLUMN ${DatabaseConstants.FIELD_CONFLICT_RESOLUTION} TEXT DEFAULT 'latest'`;
      await this.rdbStore.executeSql(sql);
      Logger.i('DatabaseHelper', '添加conflict_resolution列成功');
    } catch (error) {
      if (error instanceof Error && error.message.includes('duplicate column')) {
        Logger.i('DatabaseHelper', 'conflict_resolution列已存在，跳过添加');
      } else {
        Logger.w('DatabaseHelper', `添加conflict_resolution列失败: ${error}`);
      }
    }
  }
  
  /**
   * 获取数据库实例
   * @returns 数据库实例
   */
  public getRdbStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    return this.rdbStore;
  }
  
  /**
   * 关闭数据库
   */
  public async close(): Promise<void> {
    if (this.rdbStore) {
      try {
        await this.rdbStore.close();
        this.rdbStore = null;
        Logger.i('DatabaseHelper', '数据库已关闭');
      } catch (error) {
        Logger.e('DatabaseHelper', `关闭数据库失败: ${error}`);
      }
    }
  }
  
  /**
   * 删除数据库
   */
  public async delete(): Promise<void> {
    if (this.context) {
      try {
        await relationalStore.deleteRdbStore(this.context, DatabaseConstants.DATABASE_NAME);
        this.rdbStore = null;
        Logger.i('DatabaseHelper', '数据库已删除');
      } catch (error) {
        Logger.e('DatabaseHelper', `删除数据库失败: ${error}`);
      }
    }
  }
}
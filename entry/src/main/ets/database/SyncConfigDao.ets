/**
 * 同步配置数据访问对象
 * 负责同步配置的数据库操作
 * 
 * @author 开发者
 * @date 2026-03-12
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseHelper } from './DatabaseHelper';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { SyncConfig } from '../models/SyncConfig';
import { ConflictResolution } from '../models/SyncHistory';
import { Logger } from '../utils/Logger';

export class SyncConfigDao {
  private static instance: SyncConfigDao;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   * @returns SyncConfigDao实例
   */
  public static getInstance(): SyncConfigDao {
    if (!SyncConfigDao.instance) {
      SyncConfigDao.instance = new SyncConfigDao();
    }
    return SyncConfigDao.instance;
  }
  
  /**
   * 获取数据库实例
   * @returns RdbStore实例
   */
  private getRdbStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getRdbStore();
  }
  
  /**
   * 插入同步配置
   * @param config 同步配置
   * @returns 插入的行ID
   */
  public async insert(config: SyncConfig): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const valueBucket: relationalStore.ValuesBucket = {};
      valueBucket[DatabaseConstants.FIELD_ID] = config.id;
      valueBucket[DatabaseConstants.FIELD_USER_ID] = config.userId;
      valueBucket[DatabaseConstants.FIELD_EMAIL] = config.email;
      valueBucket[DatabaseConstants.FIELD_SYNC_PATH] = config.syncPath;
      valueBucket[DatabaseConstants.FIELD_ACCESS_TOKEN] = config.accessToken;
      valueBucket[DatabaseConstants.FIELD_REFRESH_TOKEN] = config.refreshToken;
      valueBucket[DatabaseConstants.FIELD_CLIENT_ID] = config.clientId;
      valueBucket[DatabaseConstants.FIELD_CLIENT_SECRET] = config.clientSecret;
      valueBucket[DatabaseConstants.FIELD_AUTO_SYNC] = config.autoSync ? 1 : 0;
      valueBucket[DatabaseConstants.FIELD_SYNC_INTERVAL] = config.syncInterval;
      valueBucket[DatabaseConstants.FIELD_LAST_SYNC_TIME] = config.lastSyncTime;
      valueBucket[DatabaseConstants.FIELD_ENABLED] = config.enabled ? 1 : 0;
      valueBucket[DatabaseConstants.FIELD_CONFLICT_RESOLUTION] = config.conflictResolution;
      valueBucket[DatabaseConstants.FIELD_CREATED_TIME] = config.createdTime;
      valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = config.modifiedTime;
      valueBucket[DatabaseConstants.FIELD_ENCRYPTION_KEY] = config.encryptionKey;
      
      const rowId = await rdbStore.insert(DatabaseConstants.TABLE_SYNC_CONFIGS, valueBucket);
      Logger.i('SyncConfigDao', `插入同步配置成功: ${config.email}`);
      return rowId;
    } catch (error) {
      Logger.e('SyncConfigDao', `插入同步配置失败: ${error}`);
      throw new Error('插入同步配置失败');
    }
  }
  
  /**
   * 更新同步配置
   * @param config 同步配置
   * @returns 更新的行数
   */
  public async update(config: SyncConfig): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const valueBucket: relationalStore.ValuesBucket = {};
      valueBucket[DatabaseConstants.FIELD_USER_ID] = config.userId;
      valueBucket[DatabaseConstants.FIELD_EMAIL] = config.email;
      valueBucket[DatabaseConstants.FIELD_SYNC_PATH] = config.syncPath;
      valueBucket[DatabaseConstants.FIELD_ACCESS_TOKEN] = config.accessToken;
      valueBucket[DatabaseConstants.FIELD_REFRESH_TOKEN] = config.refreshToken;
      valueBucket[DatabaseConstants.FIELD_CLIENT_ID] = config.clientId;
      valueBucket[DatabaseConstants.FIELD_CLIENT_SECRET] = config.clientSecret;
      valueBucket[DatabaseConstants.FIELD_AUTO_SYNC] = config.autoSync ? 1 : 0;
      valueBucket[DatabaseConstants.FIELD_SYNC_INTERVAL] = config.syncInterval;
      valueBucket[DatabaseConstants.FIELD_LAST_SYNC_TIME] = config.lastSyncTime;
      valueBucket[DatabaseConstants.FIELD_ENABLED] = config.enabled ? 1 : 0;
      valueBucket[DatabaseConstants.FIELD_CONFLICT_RESOLUTION] = config.conflictResolution;
      valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = config.modifiedTime;
      valueBucket[DatabaseConstants.FIELD_ENCRYPTION_KEY] = config.encryptionKey;
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_ID, config.id);
      
      const rowsAffected = await rdbStore.update(valueBucket, predicates);
      Logger.i('SyncConfigDao', `更新同步配置成功: ${config.email}`);
      return rowsAffected;
    } catch (error) {
      Logger.e('SyncConfigDao', `更新同步配置失败: ${error}`);
      throw new Error('更新同步配置失败');
    }
  }
  
  /**
   * 删除同步配置
   * @param id 配置ID
   * @returns 删除的行数
   */
  public async delete(id: string): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_ID, id);
      
      const rowsAffected = await rdbStore.delete(predicates);
      Logger.i('SyncConfigDao', `删除同步配置成功: ${id}`);
      return rowsAffected;
    } catch (error) {
      Logger.e('SyncConfigDao', `删除同步配置失败: ${error}`);
      throw new Error('删除同步配置失败');
    }
  }
  
  /**
   * 根据ID获取同步配置
   * @param id 配置ID
   * @returns 同步配置对象
   */
  public async getById(id: string): Promise<SyncConfig | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_ID, id);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const config = this.fromResultSet(resultSet);
      resultSet.close();
      
      return config;
    } catch (error) {
      Logger.e('SyncConfigDao', `获取同步配置失败: ${error}`);
      throw new Error('获取同步配置失败');
    }
  }
  
  /**
   * 根据用户ID获取同步配置
   * @param userId 用户ID
   * @returns 同步配置对象
   */
  public async getByUserId(userId: string): Promise<SyncConfig | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const config = this.fromResultSet(resultSet);
      resultSet.close();
      
      return config;
    } catch (error) {
      Logger.e('SyncConfigDao', `获取同步配置失败: ${error}`);
      throw new Error('获取同步配置失败');
    }
  }
  
  /**
   * 根据邮箱获取同步配置
   * @param email 邮箱
   * @returns 同步配置对象
   */
  public async getByEmail(email: string): Promise<SyncConfig | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_EMAIL, email);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const config = this.fromResultSet(resultSet);
      resultSet.close();
      
      return config;
    } catch (error) {
      Logger.e('SyncConfigDao', `获取同步配置失败: ${error}`);
      throw new Error('获取同步配置失败');
    }
  }
  
  /**
   * 获取所有同步配置
   * @returns 同步配置列表
   */
  public async getAll(): Promise<SyncConfig[]> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.orderByDesc(DatabaseConstants.FIELD_MODIFIED_TIME);
      
      const resultSet = await rdbStore.query(predicates);
      const configs: SyncConfig[] = [];
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          configs.push(this.fromResultSet(resultSet));
        } while (resultSet.goToNextRow());
      }
      
      resultSet.close();
      return configs;
    } catch (error) {
      Logger.e('SyncConfigDao', `获取所有同步配置失败: ${error}`);
      throw new Error('获取所有同步配置失败');
    }
  }
  
  /**
   * 获取已启用的同步配置
   * @returns 同步配置列表
   */
  public async getEnabled(): Promise<SyncConfig[]> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_ENABLED, 1);
      predicates.orderByDesc(DatabaseConstants.FIELD_MODIFIED_TIME);
        
      const resultSet = await rdbStore.query(predicates);
      const configs: SyncConfig[] = [];
        
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          configs.push(this.fromResultSet(resultSet));
        } while (resultSet.goToNextRow());
      }
        
      resultSet.close();
      return configs;
    } catch (error) {
      Logger.e('SyncConfigDao', `获取已启用的同步配置失败：${error}`);
      throw new Error('获取已启用的同步配置失败');
    }
  }
    
  /**
   * 设置同步配置的启用状态
   * @param configId 配置 ID
   * @param enabled 是否启用
   */
  public async setEnabled(configId: string, enabled: boolean): Promise<void> {
    try {
      const rdbStore = this.getRdbStore();
      const valueBucket: relationalStore.ValuesBucket = {};
      valueBucket[DatabaseConstants.FIELD_ENABLED] = enabled ? 1 : 0;
      valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = Date.now();
        
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_ID, configId);
        
      await rdbStore.update(valueBucket, predicates);
      Logger.i('SyncConfigDao', `设置同步配置启用状态成功：${configId}, ${enabled}`);
    } catch (error) {
      Logger.e('SyncConfigDao', `设置同步配置启用状态失败：${error}`);
      throw new Error('设置同步配置启用状态失败');
    }
  }
    
  /**
   * 检查邮箱是否已存在
   * @param email 邮箱
   * @param excludeId 排除的ID（用于更新时检查）
   * @returns 是否存在
   */
  public async emailExists(email: string, excludeId?: string): Promise<boolean> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_CONFIGS);
      predicates.equalTo(DatabaseConstants.FIELD_EMAIL, email);
      
      if (excludeId) {
        predicates.notEqualTo(DatabaseConstants.FIELD_ID, excludeId);
      }
      
      const resultSet = await rdbStore.query(predicates);
      const exists = resultSet.rowCount > 0;
      resultSet.close();
      
      return exists;
    } catch (error) {
      Logger.e('SyncConfigDao', `检查邮箱是否存在失败: ${error}`);
      throw new Error('检查邮箱是否存在失败');
    }
  }
  
  /**
   * 从ResultSet转换为SyncConfig对象
   * @param resultSet ResultSet对象
   * @returns SyncConfig对象
   */
  private fromResultSet(resultSet: relationalStore.ResultSet): SyncConfig {
    // 尝试获取 conflictResolution 字段，如果不存在则使用默认值
    let conflictResolution: ConflictResolution = ConflictResolution.LATEST;
    try {
      const conflictResolutionIndex = resultSet.getColumnIndex(DatabaseConstants.FIELD_CONFLICT_RESOLUTION);
      if (conflictResolutionIndex >= 0) {
        const conflictResolutionStr = resultSet.getString(conflictResolutionIndex);
        if (conflictResolutionStr) {
          conflictResolution = conflictResolutionStr as ConflictResolution;
        }
      }
    } catch (error) {
      // 字段不存在，使用默认值
      Logger.w('SyncConfigDao', 'conflictResolution字段不存在，使用默认值');
    }
    
    // 尝试获取 encryptionKey 字段，如果不存在则使用空字符串
    let encryptionKey: string = '';
    try {
      const encryptionKeyIndex = resultSet.getColumnIndex(DatabaseConstants.FIELD_ENCRYPTION_KEY);
      if (encryptionKeyIndex >= 0) {
        encryptionKey = resultSet.getString(encryptionKeyIndex) || '';
      }
    } catch (error) {
      // 字段不存在，使用默认值
      Logger.w('SyncConfigDao', 'encryptionKey字段不存在，使用默认值');
    }
    
    return new SyncConfig(
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ID)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_USER_ID)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_EMAIL)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_SYNC_PATH)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ACCESS_TOKEN)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_REFRESH_TOKEN)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_CLIENT_ID)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_CLIENT_SECRET)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_AUTO_SYNC)) === 1,
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_SYNC_INTERVAL)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_LAST_SYNC_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ENABLED)) === 1,
      conflictResolution,
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_CREATED_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_MODIFIED_TIME)),
      encryptionKey
    );
  }
}

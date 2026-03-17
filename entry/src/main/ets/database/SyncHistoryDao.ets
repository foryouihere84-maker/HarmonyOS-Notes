import relationalStore from '@ohos.data.relationalStore';
import { DatabaseHelper } from './DatabaseHelper';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { SyncHistory, ConflictResolution } from '../models/SyncHistory';
import { SyncType, SyncState } from '../models/SyncStatus';
import { Logger } from '../utils/Logger';

const MAX_HISTORY_COUNT = 50;

export interface SyncStatistics {
  totalCount: number;
  successCount: number;
  failedCount: number;
  totalUploaded: number;
  totalDownloaded: number;
  totalConflicts: number;
  avgDuration: number;
}

export class SyncHistoryDao {
  private static instance: SyncHistoryDao;
  
  private constructor() {}
  
  public static getInstance(): SyncHistoryDao {
    if (!SyncHistoryDao.instance) {
      SyncHistoryDao.instance = new SyncHistoryDao();
    }
    return SyncHistoryDao.instance;
  }
  
  public async insert(history: SyncHistory): Promise<number> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const valueBucket: relationalStore.ValuesBucket = {};
      valueBucket[DatabaseConstants.FIELD_ID] = history.id;
      valueBucket[DatabaseConstants.FIELD_SYNC_TYPE] = history.syncType;
      valueBucket[DatabaseConstants.FIELD_STATE] = history.state;
      valueBucket[DatabaseConstants.FIELD_CONFIG_ID] = history.configId;
      valueBucket[DatabaseConstants.FIELD_CONFIG_EMAIL] = history.configEmail;
      valueBucket[DatabaseConstants.FIELD_START_TIME] = history.startTime;
      valueBucket[DatabaseConstants.FIELD_END_TIME] = history.endTime;
      valueBucket[DatabaseConstants.FIELD_DURATION] = history.duration;
      valueBucket[DatabaseConstants.FIELD_ITEMS_UPLOADED] = history.itemsUploaded;
      valueBucket[DatabaseConstants.FIELD_ITEMS_DOWNLOADED] = history.itemsDownloaded;
      valueBucket[DatabaseConstants.FIELD_ITEMS_SKIPPED] = history.itemsSkipped;
      valueBucket[DatabaseConstants.FIELD_ITEMS_FAILED] = history.itemsFailed;
      valueBucket[DatabaseConstants.FIELD_BYTES_UPLOADED] = history.bytesUploaded;
      valueBucket[DatabaseConstants.FIELD_BYTES_DOWNLOADED] = history.bytesDownloaded;
      valueBucket[DatabaseConstants.FIELD_CONFLICT_COUNT] = history.conflictCount;
      valueBucket[DatabaseConstants.FIELD_CONFLICT_RESOLUTION] = history.conflictResolution;
      valueBucket[DatabaseConstants.FIELD_ERROR_MESSAGE] = history.errorMessage;
      valueBucket[DatabaseConstants.FIELD_IS_AUTO_SYNC] = history.isAutoSync ? 1 : 0;
      
      const rows = await rdbStore.insert(DatabaseConstants.TABLE_SYNC_HISTORY, valueBucket);
      Logger.i('SyncHistoryDao', `插入同步历史记录成功: ${history.id}`);
      
      await this.enforceMaxHistoryLimit();
      
      return rows;
    } catch (error) {
      Logger.e('SyncHistoryDao', `插入同步历史记录失败: ${error}`);
      throw new Error('插入同步历史记录失败');
    }
  }
  
  private async enforceMaxHistoryLimit(): Promise<void> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const countPredicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      const countResultSet = await rdbStore.query(countPredicates);
      const totalCount = countResultSet.rowCount;
      countResultSet.close();
      
      if (totalCount > MAX_HISTORY_COUNT) {
        const deletePredicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
        deletePredicates.orderByAsc(DatabaseConstants.FIELD_START_TIME);
        
        const oldestResultSet = await rdbStore.query(deletePredicates);
        const idsToDelete: string[] = [];
        let count = 0;
        const deleteCount = totalCount - MAX_HISTORY_COUNT;
        
        while (oldestResultSet.goToNextRow() && count < deleteCount) {
          const id = oldestResultSet.getString(oldestResultSet.getColumnIndex(DatabaseConstants.FIELD_ID));
          idsToDelete.push(id);
          count++;
        }
        oldestResultSet.close();
        
        for (const id of idsToDelete) {
          await this.delete(id);
        }
        
        Logger.i('SyncHistoryDao', `清理超出限制的历史记录，删除数量: ${idsToDelete.length}`);
      }
    } catch (error) {
      Logger.e('SyncHistoryDao', `清理历史记录失败: ${error}`);
    }
  }
  
  /**
   * 更新同步历史记录
   * @param history 同步历史对象
   * @returns 更新的行数
   */
  public async update(history: SyncHistory): Promise<number> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const valueBucket: relationalStore.ValuesBucket = {};
      valueBucket[DatabaseConstants.FIELD_SYNC_TYPE] = history.syncType;
      valueBucket[DatabaseConstants.FIELD_STATE] = history.state;
      valueBucket[DatabaseConstants.FIELD_CONFIG_ID] = history.configId;
      valueBucket[DatabaseConstants.FIELD_CONFIG_EMAIL] = history.configEmail;
      valueBucket[DatabaseConstants.FIELD_START_TIME] = history.startTime;
      valueBucket[DatabaseConstants.FIELD_END_TIME] = history.endTime;
      valueBucket[DatabaseConstants.FIELD_DURATION] = history.duration;
      valueBucket[DatabaseConstants.FIELD_ITEMS_UPLOADED] = history.itemsUploaded;
      valueBucket[DatabaseConstants.FIELD_ITEMS_DOWNLOADED] = history.itemsDownloaded;
      valueBucket[DatabaseConstants.FIELD_ITEMS_SKIPPED] = history.itemsSkipped;
      valueBucket[DatabaseConstants.FIELD_ITEMS_FAILED] = history.itemsFailed;
      valueBucket[DatabaseConstants.FIELD_BYTES_UPLOADED] = history.bytesUploaded;
      valueBucket[DatabaseConstants.FIELD_BYTES_DOWNLOADED] = history.bytesDownloaded;
      valueBucket[DatabaseConstants.FIELD_CONFLICT_COUNT] = history.conflictCount;
      valueBucket[DatabaseConstants.FIELD_CONFLICT_RESOLUTION] = history.conflictResolution;
      valueBucket[DatabaseConstants.FIELD_ERROR_MESSAGE] = history.errorMessage;
      valueBucket[DatabaseConstants.FIELD_IS_AUTO_SYNC] = history.isAutoSync ? 1 : 0;
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.equalTo(DatabaseConstants.FIELD_ID, history.id);
      
      const rows = await rdbStore.update(valueBucket, predicates);
      Logger.i('SyncHistoryDao', `更新同步历史记录成功: ${history.id}`);
      return rows;
    } catch (error) {
      Logger.e('SyncHistoryDao', `更新同步历史记录失败: ${error}`);
      throw new Error('更新同步历史记录失败');
    }
  }
  
  /**
   * 删除同步历史记录
   * @param id 记录ID
   * @returns 删除的行数
   */
  public async delete(id: string): Promise<number> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.equalTo(DatabaseConstants.FIELD_ID, id);
      
      const rows = await rdbStore.delete(predicates);
      Logger.i('SyncHistoryDao', `删除同步历史记录成功: ${id}`);
      return rows;
    } catch (error) {
      Logger.e('SyncHistoryDao', `删除同步历史记录失败: ${error}`);
      throw new Error('删除同步历史记录失败');
    }
  }
  
  /**
   * 根据ID获取同步历史记录
   * @param id 记录ID
   * @returns 同步历史对象
   */
  public async getById(id: string): Promise<SyncHistory | null> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.equalTo(DatabaseConstants.FIELD_ID, id);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const history = this.parseResultSet(resultSet);
      resultSet.close();
      
      return history;
    } catch (error) {
      Logger.e('SyncHistoryDao', `获取同步历史记录失败: ${error}`);
      throw new Error('获取同步历史记录失败');
    }
  }
  
  /**
   * 获取所有同步历史记录
   * @param limit 限制数量
   * @param offset 偏移量
   * @returns 同步历史记录列表
   */
  public async getAll(limit: number = 100, offset: number = 0): Promise<SyncHistory[]> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.orderByDesc(DatabaseConstants.FIELD_START_TIME);
      predicates.limitAs(limit);
      predicates.offsetAs(offset);
      
      const resultSet = await rdbStore.query(predicates);
      const histories: SyncHistory[] = [];
      
      while (resultSet.goToNextRow()) {
        const history = this.parseResultSet(resultSet);
        histories.push(history);
      }
      
      resultSet.close();
      Logger.i('SyncHistoryDao', `获取同步历史记录成功，数量: ${histories.length}`);
      return histories;
    } catch (error) {
      Logger.e('SyncHistoryDao', `获取同步历史记录失败: ${error}`);
      throw new Error('获取同步历史记录失败');
    }
  }
  
  /**
   * 根据配置ID获取同步历史记录
   * @param configId 配置ID
   * @param limit 限制数量
   * @param offset 偏移量
   * @returns 同步历史记录列表
   */
  public async getByConfigId(configId: string, limit: number = 100, offset: number = 0): Promise<SyncHistory[]> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.equalTo(DatabaseConstants.FIELD_CONFIG_ID, configId);
      predicates.orderByDesc(DatabaseConstants.FIELD_START_TIME);
      predicates.limitAs(limit);
      predicates.offsetAs(offset);
      
      const resultSet = await rdbStore.query(predicates);
      const histories: SyncHistory[] = [];
      
      while (resultSet.goToNextRow()) {
        const history = this.parseResultSet(resultSet);
        histories.push(history);
      }
      
      resultSet.close();
      Logger.i('SyncHistoryDao', `根据配置ID获取同步历史记录成功，数量: ${histories.length}`);
      return histories;
    } catch (error) {
      Logger.e('SyncHistoryDao', `根据配置ID获取同步历史记录失败: ${error}`);
      throw new Error('根据配置ID获取同步历史记录失败');
    }
  }
  
  /**
   * 获取指定时间范围内的同步历史记录
   * @param startTime 开始时间
   * @param endTime 结束时间
   * @returns 同步历史记录列表
   */
  public async getByTimeRange(startTime: number, endTime: number): Promise<SyncHistory[]> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.between(DatabaseConstants.FIELD_START_TIME, startTime, endTime);
      predicates.orderByDesc(DatabaseConstants.FIELD_START_TIME);
      
      const resultSet = await rdbStore.query(predicates);
      const histories: SyncHistory[] = [];
      
      while (resultSet.goToNextRow()) {
        const history = this.parseResultSet(resultSet);
        histories.push(history);
      }
      
      resultSet.close();
      Logger.i('SyncHistoryDao', `获取时间范围内的同步历史记录成功，数量: ${histories.length}`);
      return histories;
    } catch (error) {
      Logger.e('SyncHistoryDao', `获取时间范围内的同步历史记录失败: ${error}`);
      throw new Error('获取时间范围内的同步历史记录失败');
    }
  }
  
  /**
   * 获取失败的同步历史记录
   * @param limit 限制数量
   * @returns 同步历史记录列表
   */
  public async getFailedHistories(limit: number = 50): Promise<SyncHistory[]> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.equalTo(DatabaseConstants.FIELD_STATE, SyncState.FAILED);
      predicates.orderByDesc(DatabaseConstants.FIELD_START_TIME);
      predicates.limitAs(limit);
      
      const resultSet = await rdbStore.query(predicates);
      const histories: SyncHistory[] = [];
      
      while (resultSet.goToNextRow()) {
        const history = this.parseResultSet(resultSet);
        histories.push(history);
      }
      
      resultSet.close();
      Logger.i('SyncHistoryDao', `获取失败的同步历史记录成功，数量: ${histories.length}`);
      return histories;
    } catch (error) {
      Logger.e('SyncHistoryDao', `获取失败的同步历史记录失败: ${error}`);
      throw new Error('获取失败的同步历史记录失败');
    }
  }
  
  /**
   * 获取有冲突的同步历史记录
   * @param limit 限制数量
   * @returns 同步历史记录列表
   */
  public async getConflictHistories(limit: number = 50): Promise<SyncHistory[]> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.greaterThan(DatabaseConstants.FIELD_CONFLICT_COUNT, 0);
      predicates.orderByDesc(DatabaseConstants.FIELD_START_TIME);
      predicates.limitAs(limit);
      
      const resultSet = await rdbStore.query(predicates);
      const histories: SyncHistory[] = [];
      
      while (resultSet.goToNextRow()) {
        const history = this.parseResultSet(resultSet);
        histories.push(history);
      }
      
      resultSet.close();
      Logger.i('SyncHistoryDao', `获取有冲突的同步历史记录成功，数量: ${histories.length}`);
      return histories;
    } catch (error) {
      Logger.e('SyncHistoryDao', `获取有冲突的同步历史记录失败: ${error}`);
      throw new Error('获取有冲突的同步历史记录失败');
    }
  }
  
  /**
   * 获取自动同步的历史记录
   * @param limit 限制数量
   * @returns 同步历史记录列表
   */
  public async getAutoSyncHistories(limit: number = 50): Promise<SyncHistory[]> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.equalTo(DatabaseConstants.FIELD_IS_AUTO_SYNC, 1);
      predicates.orderByDesc(DatabaseConstants.FIELD_START_TIME);
      predicates.limitAs(limit);
      
      const resultSet = await rdbStore.query(predicates);
      const histories: SyncHistory[] = [];
      
      while (resultSet.goToNextRow()) {
        const history = this.parseResultSet(resultSet);
        histories.push(history);
      }
      
      resultSet.close();
      Logger.i('SyncHistoryDao', `获取自动同步的历史记录成功，数量: ${histories.length}`);
      return histories;
    } catch (error) {
      Logger.e('SyncHistoryDao', `获取自动同步的历史记录失败: ${error}`);
      throw new Error('获取自动同步的历史记录失败');
    }
  }
  
  /**
   * 获取统计信息
   * @param configId 配置 ID（可选）
   * @returns 统计信息
   */
  public async getStatistics(configId?: string): Promise<SyncStatistics> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      if (configId) {
        predicates.equalTo(DatabaseConstants.FIELD_CONFIG_ID, configId);
      }
      
      const resultSet = await rdbStore.query(predicates);
      
      let totalCount = 0;
      let successCount = 0;
      let failedCount = 0;
      let totalUploaded = 0;
      let totalDownloaded = 0;
      let totalConflicts = 0;
      let totalDuration = 0;
      
      while (resultSet.goToNextRow()) {
        totalCount++;
        const state = resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_STATE));
        if (state === SyncState.SUCCESS) {
          successCount++;
        } else if (state === SyncState.FAILED) {
          failedCount++;
        }
        
        totalUploaded += resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ITEMS_UPLOADED));
        totalDownloaded += resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ITEMS_DOWNLOADED));
        totalConflicts += resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_CONFLICT_COUNT));
        totalDuration += resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_DURATION));
      }
      
      resultSet.close();
      
      const avgDuration = totalCount > 0 ? Math.floor(totalDuration / totalCount) : 0;
      
      Logger.i('SyncHistoryDao', `获取统计信息成功`);
      const statistics: SyncStatistics = {
        totalCount,
        successCount,
        failedCount,
        totalUploaded,
        totalDownloaded,
        totalConflicts,
        avgDuration
      };
      return statistics;
    } catch (error) {
      Logger.e('SyncHistoryDao', `获取统计信息失败: ${error}`);
      throw new Error('获取统计信息失败');
    }
  }
  
  /**
   * 清理旧的同步历史记录
   * @param days 保留天数
   * @returns 删除的行数
   */
  public async cleanOldHistories(days: number = 30): Promise<number> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const cutoffTime = Date.now() - (days * 24 * 60 * 60 * 1000);
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      predicates.lessThan(DatabaseConstants.FIELD_START_TIME, cutoffTime);
      
      const rows = await rdbStore.delete(predicates);
      Logger.i('SyncHistoryDao', `清理旧的同步历史记录成功，删除数量: ${rows}`);
      return rows;
    } catch (error) {
      Logger.e('SyncHistoryDao', `清理旧的同步历史记录失败: ${error}`);
      throw new Error('清理旧的同步历史记录失败');
    }
  }
  
  /**
   * 清空所有同步历史记录
   * @returns 删除的行数
   */
  public async clearAll(): Promise<number> {
    try {
      const rdbStore = DatabaseHelper.getInstance().getRdbStore();
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_SYNC_HISTORY);
      const rows = await rdbStore.delete(predicates);
      
      Logger.i('SyncHistoryDao', `清空所有同步历史记录成功，删除数量: ${rows}`);
      return rows;
    } catch (error) {
      Logger.e('SyncHistoryDao', `清空所有同步历史记录失败: ${error}`);
      throw new Error('清空所有同步历史记录失败');
    }
  }
  
  /**
   * 解析结果集
   * @param resultSet 结果集
   * @returns 同步历史对象
   */
  private parseResultSet(resultSet: relationalStore.ResultSet): SyncHistory {
    return new SyncHistory(
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ID)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_SYNC_TYPE)) as SyncType,
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_STATE)) as SyncState,
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_CONFIG_ID)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_CONFIG_EMAIL)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_START_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_END_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_DURATION)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ITEMS_UPLOADED)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ITEMS_DOWNLOADED)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ITEMS_SKIPPED)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_ITEMS_FAILED)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_BYTES_UPLOADED)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_BYTES_DOWNLOADED)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_CONFLICT_COUNT)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_CONFLICT_RESOLUTION)) as ConflictResolution,
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ERROR_MESSAGE)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_IS_AUTO_SYNC)) === 1
    );
  }
}

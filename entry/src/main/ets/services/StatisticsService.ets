import fs from '@ohos.file.fs';
import { NotebookDao } from '../database/NotebookDao';
import { PageDao } from '../database/PageDao';
import { SyncService } from '../services/SyncService';
import { AppConstants } from '../constants/AppConstants';
import { Logger } from '../utils/Logger';
import { FileUtils } from '../utils/FileUtils';

export interface StatisticsData {
  notebookCount: number;
  pageCount: number;
  todayEditCount: number;
  syncStatus: string;
  lastUpdateTime: number;
}

export class StatisticsService {
  private static instance: StatisticsService;
  private notebookDao: NotebookDao;
  private pageDao: PageDao;
  private syncService: SyncService;
  private statisticsFilePath: string;
  
  private constructor() {
    this.notebookDao = NotebookDao.getInstance();
    this.pageDao = PageDao.getInstance();
    this.syncService = SyncService.getInstance();
    this.statisticsFilePath = `${AppConstants.STORAGE_PATH}/statistics.json`;
  }
  
  public static getInstance(): StatisticsService {
    if (!StatisticsService.instance) {
      StatisticsService.instance = new StatisticsService();
    }
    return StatisticsService.instance;
  }
  
  public async refreshStatistics(): Promise<StatisticsData> {
    try {
      const notebooks = await this.notebookDao.getAll();
      const notebookCount = notebooks.length;
      
      const pageCount = await this.pageDao.getTotalPageCount();
      
      const todayEditCount = await this.pageDao.getTodayEditedCount();
      
      let syncStatus = '未同步';
      const currentSyncStatus = this.syncService.getCurrentSyncStatus();
      if (currentSyncStatus) {
        if (currentSyncStatus.isInProgress()) {
          syncStatus = '同步中';
        } else if (currentSyncStatus.isSuccess()) {
          syncStatus = '已同步';
        } else if (currentSyncStatus.isFailed()) {
          syncStatus = '同步失败';
        }
      }
      
      const data: StatisticsData = {
        notebookCount: notebookCount,
        pageCount: pageCount,
        todayEditCount: todayEditCount,
        syncStatus: syncStatus,
        lastUpdateTime: Date.now()
      };
      
      await this.saveStatisticsToFile(data);
      
      Logger.i('StatisticsService', `统计数据已更新: 笔记本=${notebookCount}, 页面=${pageCount}, 今日编辑=${todayEditCount}`);
      return data;
    } catch (error) {
      Logger.e('StatisticsService', `刷新统计数据失败: ${error}`);
      return this.getDefaultStatistics();
    }
  }
  
  public async getStatistics(): Promise<StatisticsData> {
    try {
      const data = await this.loadStatisticsFromFile();
      if (data) {
        return data;
      }
      return await this.refreshStatistics();
    } catch (error) {
      Logger.e('StatisticsService', `获取统计数据失败: ${error}`);
      return this.getDefaultStatistics();
    }
  }
  
  private async saveStatisticsToFile(data: StatisticsData): Promise<void> {
    try {
      await FileUtils.ensureDirectoryExists(AppConstants.STORAGE_PATH);
      
      const jsonStr = JSON.stringify(data, null, 2);
      const file = await fs.open(this.statisticsFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, jsonStr);
      await fs.close(file);
      
      Logger.i('StatisticsService', '统计数据已保存到文件');
    } catch (error) {
      Logger.e('StatisticsService', `保存统计数据到文件失败: ${error}`);
    }
  }
  
  private async loadStatisticsFromFile(): Promise<StatisticsData | null> {
    try {
      if (!FileUtils.fileExists(this.statisticsFilePath)) {
        return null;
      }
      
      const file = await fs.open(this.statisticsFilePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(this.statisticsFilePath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file);
      
      const uint8Array = new Uint8Array(buffer);
      let content = '';
      for (let i = 0; i < uint8Array.length; i++) {
        content += String.fromCharCode(uint8Array[i]);
      }
      
      const data: StatisticsData = JSON.parse(content) as StatisticsData;
      Logger.i('StatisticsService', '从文件加载统计数据成功');
      return data;
    } catch (error) {
      Logger.e('StatisticsService', `从文件加载统计数据失败: ${error}`);
      return null;
    }
  }
  
  private getDefaultStatistics(): StatisticsData {
    return {
      notebookCount: 0,
      pageCount: 0,
      todayEditCount: 0,
      syncStatus: '未同步',
      lastUpdateTime: 0
    };
  }
  
  public async clearStatistics(): Promise<void> {
    try {
      if (FileUtils.fileExists(this.statisticsFilePath)) {
        await FileUtils.deleteFile(this.statisticsFilePath);
        Logger.i('StatisticsService', '统计数据文件已清除');
      }
    } catch (error) {
      Logger.e('StatisticsService', `清除统计数据文件失败: ${error}`);
    }
  }
}

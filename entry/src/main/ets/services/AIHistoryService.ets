/**
 * AI处理历史服务
 * 用于管理AI处理历史记录的增删改查
 * 
 * @author 开发者
 * @date 2026-03-19
 */

import { http } from '@kit.NetworkKit';
import { Logger } from '../utils/Logger';
import { AIProcessHistory, AIProcessHistoryJSON, AIProcessType } from '../models/AIProcessHistory';
import { AppConstants } from '../constants/AppConstants';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export interface AIStatistics {
  total: number;
  extract: number;
  polish: number;
  summarize: number;
  expand: number;
}

export interface AIBackendResponse<T = Record<string, Object>> {
  success: boolean;
  message: string;
  data?: T;
}

export interface AIHistoryItem extends Record<string, Object> {
  id: string;
  name: string;
  content: string;
  processType: string;
  relatedNotes: string;
  createdTime: number;
}

export class AIHistoryService {
  private static instance: AIHistoryService;
  private static readonly BASE_URL: string = AppConstants.API_BASE_URL;
  private static readonly HISTORY_ENDPOINT: string = '/api/v16/ai/history';
  private static readonly TIMEOUT: number = 30000;
  private static readonly PAGE_SIZE: number = 20;
  private static readonly LOCAL_PREF_NAME: string = 'ai_history_store';
  private static readonly KEY_HISTORY_LIST: string = 'history_list';
  
  private preferencesStore: preferences.Preferences | null = null;
  private context: common.Context | null = null;
  
  private constructor() {}
  
  public static getInstance(): AIHistoryService {
    if (!AIHistoryService.instance) {
      AIHistoryService.instance = new AIHistoryService();
    }
    return AIHistoryService.instance;
  }
  
  public async init(context: common.Context): Promise<void> {
    try {
      this.context = context;
      this.preferencesStore = await preferences.getPreferences(context, AIHistoryService.LOCAL_PREF_NAME);
      Logger.i('AIHistoryService', 'AI历史记录本地存储初始化成功');
    } catch (error) {
      Logger.e('AIHistoryService', `AI历史记录本地存储初始化失败: ${error}`);
    }
  }
  
  /**
   * 获取所有历史记录（分页）
   * @param userId 用户ID
   * @param page 页码（从0开始）
   * @param size 每页大小
   * @returns 历史记录列表
   */
  public async getAllHistory(
    userId: string = '1',
    page: number = 0,
    size: number = AIHistoryService.PAGE_SIZE
  ): Promise<AIProcessHistory[]> {
    try {
      const url = `${AIHistoryService.BASE_URL}${AIHistoryService.HISTORY_ENDPOINT}?userId=${userId}&page=${page}&size=${size}`;
      Logger.i('AIHistoryService', `获取历史记录：${url}`);
          
      const response = await this.httpRequest(url);
      const responseText = response.result.toString();
      Logger.i('AIHistoryService', `后端响应: ${responseText}`);
      
      const data: AIBackendResponse<AIHistoryItem[]> = JSON.parse(responseText);
      Logger.i('AIHistoryService', `解析后的数据: ${JSON.stringify(data)}`);
          
      if (data.success === true && data.data) {
        const histories: AIProcessHistory[] = data.data.map((item: AIHistoryItem) => {
          const history = AIProcessHistory.fromBackend(item);
          Logger.i('AIHistoryService', `转换后的历史记录: ${JSON.stringify(history)}`);
          return history;
        });
        Logger.i('AIHistoryService', `获取到 ${histories.length} 条历史记录`);
        
        await this.saveToLocal(histories);
        
        return histories;
      } else {
        Logger.e('AIHistoryService', `获取历史记录失败：${data.message}`);
        return await this.loadFromLocal();
      }
    } catch (error) {
      Logger.e('AIHistoryService', `获取历史记录异常：${error}`);
      return await this.loadFromLocal();
    }
  }
  
  /**
   * 根据类型获取历史记录
   * @param userId 用户ID
   * @param processType 处理类型
   * @returns 历史记录列表
   */
  public async getHistoryByType(
    userId: string = '1',
    processType: AIProcessType
  ): Promise<AIProcessHistory[]> {
    try {
      const url = `${AIHistoryService.BASE_URL}${AIHistoryService.HISTORY_ENDPOINT}?userId=${userId}&processType=${processType}`;
      Logger.i('AIHistoryService', `获取${processType}类型的历史记录：${url}`);
        
      const response = await this.httpRequest(url);
      const data: AIBackendResponse<AIHistoryItem[]> = JSON.parse(response.result.toString());
        
      if (data.success === true && data.data) {
        const histories: AIProcessHistory[] = data.data.map((item: AIHistoryItem) => AIProcessHistory.fromBackend(item));
        Logger.i('AIHistoryService', `获取到 ${histories.length} 条${processType}类型的历史记录`);
        return histories;
      } else {
        Logger.e('AIHistoryService', `获取历史记录失败: ${data.message}`);
        return [];
      }
    } catch (error) {
      Logger.e('AIHistoryService', `获取历史记录异常: ${error}`);
      return [];
    }
  }
  
  /**
   * 根据ID获取历史记录
   * @param id 记录ID
   * @returns 历史记录
   */
  public async getHistoryById(id: string): Promise<AIProcessHistory | null> {
    try {
      const url = `${AIHistoryService.BASE_URL}${AIHistoryService.HISTORY_ENDPOINT}/${id}`;
      Logger.i('AIHistoryService', `获取历史记录详情：${url}`);
        
      const response = await this.httpRequest(url);
      const data: AIBackendResponse<AIHistoryItem> = JSON.parse(response.result.toString());
        
      if (data.success === true && data.data) {
        const history = AIProcessHistory.fromBackend(data.data);
        Logger.i('AIHistoryService', `获取到历史记录: ${history.name}`);
        return history;
      } else {
        Logger.e('AIHistoryService', `获取历史记录失败: ${data.message}`);
        return null;
      }
    } catch (error) {
      Logger.e('AIHistoryService', `获取历史记录异常: ${error}`);
      return null;
    }
  }
  
  /**
   * 删除历史记录
   * @param id 记录ID
   * @returns 是否成功
   */
  public async deleteHistory(id: string): Promise<boolean> {
    try {
      const url = `${AIHistoryService.BASE_URL}${AIHistoryService.HISTORY_ENDPOINT}/${id}`;
      Logger.i('AIHistoryService', `删除历史记录: ${url}`);
      
      const httpRequest = http.createHttp();
      await new Promise<void>((resolve, reject) => {
        httpRequest.request(url, {
          method: http.RequestMethod.DELETE,
          header: {
            'Content-Type': 'application/json'
          },
          connectTimeout: AIHistoryService.TIMEOUT,
          readTimeout: AIHistoryService.TIMEOUT
        }, (err) => {
          if (err) {
            Logger.e('AIHistoryService', `删除历史记录失败: ${JSON.stringify(err)}`);
            reject(err);
          } else {
            Logger.i('AIHistoryService', `删除历史记录成功: ${id}`);
            resolve();
          }
        });
      });
      
      return true;
    } catch (error) {
      Logger.e('AIHistoryService', `删除历史记录异常: ${error}`);
      return false;
    }
  }
  
  /**
   * 批量删除历史记录
   * @param ids 记录ID列表
   * @returns 成功删除的数量
   */
  public async batchDeleteHistory(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      const success = await this.deleteHistory(id);
      if (success) {
        successCount++;
      }
    }
    
    Logger.i('AIHistoryService', `批量删除完成，成功 ${successCount}/${ids.length}`);
    return successCount;
  }
  
  /**
   * 搜索历史记录
   * @param userId 用户ID
   * @param keyword 搜索关键词
   * @returns 匹配的历史记录列表
   */
  public async searchHistory(userId: string = '1', keyword: string): Promise<AIProcessHistory[]> {
    try {
      const allHistory = await this.getAllHistory(userId);
      
      if (!keyword || keyword.trim().length === 0) {
        return allHistory;
      }
      
      const lowerKeyword = keyword.toLowerCase();
      const filtered = allHistory.filter(history => {
        return history.name.toLowerCase().includes(lowerKeyword) ||
               history.content.toLowerCase().includes(lowerKeyword) ||
               history.relatedNotes.toLowerCase().includes(lowerKeyword);
      });
      
      Logger.i('AIHistoryService', `搜索历史记录，关键词: ${keyword}，结果: ${filtered.length} 条`);
      return filtered;
    } catch (error) {
      Logger.e('AIHistoryService', `搜索历史记录异常: ${error}`);
      return [];
    }
  }
  
  /**
   * 获取统计信息
   * @param userId 用户ID
   * @returns 统计信息
   */
  public async getStatistics(userId: string = '1'): Promise<AIStatistics> {
    try {
      const allHistory = await this.getAllHistory(userId);
      
      const stats: AIStatistics = {
        total: allHistory.length,
        extract: 0,
        polish: 0,
        summarize: 0,
        expand: 0
      };
      
      allHistory.forEach(history => {
        switch (history.processType) {
          case AIProcessType.EXTRACT:
            stats.extract++;
            break;
          case AIProcessType.POLISH:
            stats.polish++;
            break;
          case AIProcessType.SUMMARIZE:
            stats.summarize++;
            break;
          case AIProcessType.EXPAND:
            stats.expand++;
            break;
        }
      });
      
      Logger.i('AIHistoryService', `获取统计信息: ${JSON.stringify(stats)}`);
      return stats;
    } catch (error) {
      Logger.e('AIHistoryService', `获取统计信息异常: ${error}`);
      return {
        total: 0,
        extract: 0,
        polish: 0,
        summarize: 0,
        expand: 0
      };
    }
  }
  
  /**
   * HTTP 请求封装
   * @param url 请求URL
   * @returns 响应结果
   */
  private async httpRequest(url: string): Promise<http.HttpResponse> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();
      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: AIHistoryService.TIMEOUT,
        readTimeout: AIHistoryService.TIMEOUT
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data as http.HttpResponse);
        }
      });
    });
  }
  
  /**
   * 保存历史记录到本地存储
   * @param histories 历史记录列表
   */
  private async saveToLocal(histories: AIProcessHistory[]): Promise<void> {
    try {
      if (!this.preferencesStore) {
        Logger.w('AIHistoryService', '本地存储未初始化，无法保存');
        return;
      }
      
      const jsonStr = JSON.stringify(histories.map(h => h.toJSON()));
      await this.preferencesStore.put(AIHistoryService.KEY_HISTORY_LIST, jsonStr);
      await this.preferencesStore.flush();
      Logger.i('AIHistoryService', `已保存 ${histories.length} 条历史记录到本地`);
    } catch (error) {
      Logger.e('AIHistoryService', `保存历史记录到本地失败: ${error}`);
    }
  }
  
  /**
   * 从本地存储加载历史记录
   * @returns 历史记录列表
   */
  private async loadFromLocal(): Promise<AIProcessHistory[]> {
    try {
      if (!this.preferencesStore) {
        Logger.w('AIHistoryService', '本地存储未初始化，无法加载');
        return [];
      }
      
      const jsonStr = await this.preferencesStore.get(AIHistoryService.KEY_HISTORY_LIST, '') as string;
      if (!jsonStr || jsonStr.trim().length === 0) {
        Logger.i('AIHistoryService', '本地存储中没有历史记录');
        return [];
      }
      
      const data = JSON.parse(jsonStr) as AIProcessHistoryJSON[];
      const histories = data.map(item => AIProcessHistory.fromJSON(item));
      Logger.i('AIHistoryService', `从本地加载了 ${histories.length} 条历史记录`);
      return histories;
    } catch (error) {
      Logger.e('AIHistoryService', `从本地加载历史记录失败: ${error}`);
      return [];
    }
  }
  
  /**
   * 清除本地存储的历史记录
   */
  public async clearLocalHistory(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        Logger.w('AIHistoryService', '本地存储未初始化，无法清除');
        return;
      }
      
      await this.preferencesStore.delete(AIHistoryService.KEY_HISTORY_LIST);
      await this.preferencesStore.flush();
      Logger.i('AIHistoryService', '已清除本地历史记录');
    } catch (error) {
      Logger.e('AIHistoryService', `清除本地历史记录失败: ${error}`);
    }
  }
}

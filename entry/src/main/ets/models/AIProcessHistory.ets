/**
 * AI处理历史数据模型
 * 用于记录AI处理操作的历史记录
 * 
 * @author 开发者
 * @date 2026-03-19
 */

import { Logger } from '../utils/Logger';

/**
 * AI处理类型枚举
 */
export enum AIProcessType {
  EXTRACT = 'extract',     // 提炼
  POLISH = 'polish',       // 润色
  SUMMARIZE = 'summarize', // 总结
  EXPAND = 'expand'        // 拓展
}

/**
 * AI处理历史 JSON 接口
 */
export interface AIProcessHistoryJSON {
  id: string;
  name: string;
  createTime: string;
  relatedNotes: string;
  content: string;
  processType: string;
  userId: string;
  createdTime: string;
  updatedTime: string;
}

/**
 * 关联笔记项接口
 */
export interface RelatedNoteItem {
  id: string;
  title: string;
}

/**
 * AI处理历史数据类
 */
export class AIProcessHistory {
  id: string;
  name: string;
  createTime: string;
  relatedNotes: string;
  content: string;
  processType: AIProcessType;
  userId: string;
  createdTime: string;
  updatedTime: string;
  
  constructor(
    id: string = '',
    name: string = '',
    createTime: string = '',
    relatedNotes: string = '',
    content: string = '',
    processType: AIProcessType = AIProcessType.EXTRACT,
    userId: string = '',
    createdTime: string = '',
    updatedTime: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.createTime = createTime;
    this.relatedNotes = relatedNotes;
    this.content = content;
    this.processType = processType;
    this.userId = userId;
    this.createdTime = createdTime;
    this.updatedTime = updatedTime;
  }
  
  /**
   * 转换为JSON对象
   * @returns JSON对象
   */
  toJSON(): AIProcessHistoryJSON {
    return {
      id: this.id,
      name: this.name,
      createTime: this.createTime,
      relatedNotes: this.relatedNotes,
      content: this.content,
      processType: this.processType,
      userId: this.userId,
      createdTime: this.createdTime,
      updatedTime: this.updatedTime
    };
  }
  
  /**
   * 从 JSON 对象创建实例
   * @param json JSON 对象
   * @returns AIProcessHistory 实例
   */
  static fromJSON(json: AIProcessHistoryJSON | Record<string, Object>): AIProcessHistory {
    return new AIProcessHistory(
      json.id as string || '',
      json.name as string || '',
      json.createTime as string || '',
      json.relatedNotes as string || '',
      json.content as string || '',
      json.processType as AIProcessType || AIProcessType.EXTRACT,
      json.userId as string || '',
      json.createdTime as string || '',
      json.updatedTime as string || ''
    );
  }
  
  /**
   * 从后端响应创建实例
   * @param data 后端数据
   * @returns AIProcessHistory实例
   */
  static fromBackend(data: Record<string, Object>): AIProcessHistory {
    let createTime = '';
    let createdTime = '';
    
    if (data.createTime) {
      if (typeof data.createTime === 'number') {
        createTime = new Date(data.createTime).toISOString();
      } else if (typeof data.createTime === 'string') {
        const timeStr = String(data.createTime);
        if (timeStr.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/)) {
          createTime = new Date(timeStr.replace(' ', 'T') + '+08:00').toISOString();
        } else {
          createTime = timeStr;
        }
      } else {
        createTime = String(data.createTime || '');
      }
    }
    
    if (data.createdTime) {
      if (typeof data.createdTime === 'number') {
        createdTime = new Date(data.createdTime).toISOString();
      } else if (typeof data.createdTime === 'string') {
        const timeStr = String(data.createdTime);
        if (timeStr.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/)) {
          createdTime = new Date(timeStr.replace(' ', 'T') + '+08:00').toISOString();
        } else {
          createdTime = timeStr;
        }
      } else {
        createdTime = String(data.createdTime || '');
      }
    }
    
    if (!createTime && createdTime) {
      createTime = createdTime;
    }
    
    return new AIProcessHistory(
      String(data.id || ''),
      data.name as string || '',
      createTime,
      data.relatedNotes as string || '',
      data.content as string || '',
      data.processType as AIProcessType || AIProcessType.EXTRACT,
      String(data.userId || ''),
      createdTime,
      data.updatedTime as string || ''
    );
  }
  
  /**
   * 验证数据有效性
   * @returns 是否有效
   */
  validate(): boolean {
    if (!this.id || this.id.trim().length === 0) {
      return false;
    }
    
    if (!this.name || this.name.trim().length === 0) {
      return false;
    }
    
    if (!this.createTime || this.createTime.trim().length === 0) {
      return false;
    }
    
    return true;
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID
   */
  static generateId(): string {
    return `ai_history_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * 获取处理类型的显示名称
   * @returns 显示名称
   */
  getProcessTypeName(): string {
    switch (this.processType) {
      case AIProcessType.EXTRACT:
        return '提炼';
      case AIProcessType.POLISH:
        return '润色';
      case AIProcessType.SUMMARIZE:
        return '总结';
      case AIProcessType.EXPAND:
        return '拓展';
      default:
        return '处理';
    }
  }
  
  /**
   * 获取格式化的创建时间
   * @returns 格式化的时间字符串
   */
  getFormattedCreateTime(): string {
    if (!this.createTime) {
      return '';
    }
    try {
      const date = new Date(this.createTime);
      return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });
    } catch (e) {
      Logger.e('AIProcessHistory', `格式化时间失败: ${e}`);
      return this.createTime;
    }
  }
  
  /**
   * 获取内容的预览
   * @param maxLength 最大长度
   * @returns 预览字符串
   */
  getContentPreview(maxLength: number = 100): string {
    if (!this.content) {
      return '';
    }
    if (this.content.length <= maxLength) {
      return this.content;
    }
    return this.content.substring(0, maxLength) + '...';
  }
  
  /**
   * 获取关联笔记的预览
   * @param maxLength 最大长度
   * @returns 预览字符串
   */
  getRelatedNotesPreview(maxLength: number = 100): string {
    if (!this.relatedNotes) {
      return '';
    }
    
    try {
      const notes: Array<Record<string, Object>> = JSON.parse(this.relatedNotes);
      if (Array.isArray(notes) && notes.length > 0) {
        const titles = notes.map((note: Record<string, Object>) => 
          (note['title'] as string) || (note['id'] as string)
        ).filter(Boolean);
        const preview = titles.join('、');
        if (preview.length <= maxLength) {
          return preview;
        }
        return preview.substring(0, maxLength) + '...';
      }
    } catch (e) {
      Logger.e('AIProcessHistory', `解析关联笔记失败：${e}`);
    }
    
    if (this.relatedNotes.length <= maxLength) {
      return this.relatedNotes;
    }
    return this.relatedNotes.substring(0, maxLength) + '...';
  }
  
  /**
   * 获取关联笔记列表
   * @returns 笔记列表
   */
  getRelatedNotesList(): RelatedNoteItem[] {
    if (!this.relatedNotes) {
      return [];
    }
    
    try {
      const notes: Array<Record<string, Object>> = JSON.parse(this.relatedNotes);
      if (Array.isArray(notes)) {
        return notes.map((note: Record<string, Object>): RelatedNoteItem => ({
          id: (note['id'] as string) || '',
          title: (note['title'] as string) || (note['id'] as string) || '未知笔记'
        })).filter(note => note.id);
      }
    } catch (e) {
      Logger.e('AIProcessHistory', `解析关联笔记列表失败：${e}`);
    }
    
    return [];
  }
  
  /**
   * 检查是否为指定类型
   * @param type 处理类型
   * @returns 是否匹配
   */
  isType(type: AIProcessType): boolean {
    return this.processType === type;
  }
  
  /**
   * 检查内容是否为空
   * @returns 是否为空
   */
  isEmpty(): boolean {
    return !this.content || this.content.trim().length === 0;
  }
  
  /**
   * 获取内容的长度
   * @returns 内容长度
   */
  getContentLength(): number {
    return this.content ? this.content.length : 0;
  }
  
  /**
   * 获取格式化的内容长度
   * @returns 格式化的长度字符串
   */
  getFormattedContentLength(): string {
    const length = this.getContentLength();
    if (length < 1024) {
      return `${length} 字符`;
    } else if (length < 1024 * 1024) {
      return `${(length / 1024).toFixed(2)} KB`;
    } else {
      return `${(length / (1024 * 1024)).toFixed(2)} MB`;
    }
  }
}

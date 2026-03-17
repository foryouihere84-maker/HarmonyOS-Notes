/**
 * 页面数据模型
 * 用于表示笔记页面的基本信息
 * 
 * @author 开发者
 * @date 2026-03-11
 */

export interface PageJSON {
  id: string;
  notebookId: string;
  sectionId: string;
  title: string;
  content: string;
  createdTime: number;
  modifiedTime: number;
  order: number;
  isPinned: number;
  isDeleted: number;
  tags: string[];
  backgroundColor: string;
  fontSize: number;
}

export class Page {
  id: string;
  notebookId: string;
  sectionId: string;
  title: string;
  content: string;
  createdTime: number;
  modifiedTime: number;
  order: number;
  isPinned: boolean;
  isDeleted: boolean;
  tags: string[];
  backgroundColor: string;
  fontSize: number;
  
  constructor(
    id: string = '',
    notebookId: string = '',
    sectionId: string = '',
    title: string = '',
    content: string = '',
    createdTime: number = Date.now(),
    modifiedTime: number = Date.now(),
    order: number = 0,
    isPinned: boolean = false,
    isDeleted: boolean = false,
    tags: string[] = [],
    backgroundColor: string = '#FFFFFF',
    fontSize: number = 36
  ) {
    this.id = id;
    this.notebookId = notebookId;
    this.sectionId = sectionId;
    this.title = title;
    this.content = content;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
    this.order = order;
    this.isPinned = isPinned;
    this.isDeleted = isDeleted;
    this.tags = tags;
    this.backgroundColor = backgroundColor;
    this.fontSize = fontSize;
  }
  
  toJSON(): PageJSON {
    const result: PageJSON = {
      id: this.id,
      notebookId: this.notebookId,
      sectionId: this.sectionId,
      title: this.title,
      content: this.content,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime,
      order: this.order,
      isPinned: this.isPinned ?1 : 0,
      isDeleted: this.isDeleted ?1 : 0,
      tags: this.tags,
      backgroundColor: this.backgroundColor,
      fontSize: this.fontSize
    };
    return result;
  }
  
  static fromJSON(json: Record<string, Object>): Page {
    return new Page(
      json.id as string || '',
      json.notebookId as string || '',
      json.sectionId as string || '',
      json.title as string || '',
      json.content as string || '',
      json.createdTime as number || Date.now(),
      json.modifiedTime as number || Date.now(),
      json.order as number || 0,
      json.isPinned === 1 || json.isPinned === true,
      json.isDeleted === 1 || json.isDeleted === true,
      json.tags as string[] || [],
      json.backgroundColor as string || '#FFFFFF',
      json.fontSize as number || 36
    );
  }
  
  validate(): boolean {
    if (!this.title || this.title.trim().length === 0) {
      return false;
    }
    if (this.title.length > 200) {
      return false;
    }
    if (this.content && this.content.length > 100000) {
      return false;
    }
    return true;
  }
}
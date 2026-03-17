/**
 * 笔记本数据模型
 * 用于表示笔记本的基本信息
 * 
 * @author 开发者
 * @date 2026-03-11
 */

export interface NotebookJSON {
  id: string;
  title: string;
  description: string;
  color: string;
  icon: string;
  coverImage: string;
  createdTime: number;
  modifiedTime: number;
  pageCount: number;
}

export class Notebook {
  id: string;
  title: string;
  description: string;
  color: string;
  icon: string;
  coverImage: string;
  createdTime: number;
  modifiedTime: number;
  pageCount: number;
  
  constructor(
    id: string = '',
    title: string = '',
    description: string = '',
    color: string = '#0078D4',
    icon: string = 'notebook',
    coverImage: string = '',
    createdTime: number = Date.now(),
    modifiedTime: number = Date.now(),
    pageCount: number = 0
  ) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.color = color;
    this.icon = icon;
    this.coverImage = coverImage;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
    this.pageCount = pageCount;
  }
  
  toJSON(): NotebookJSON {
    const result: NotebookJSON = {
      id: this.id,
      title: this.title,
      description: this.description,
      color: this.color,
      icon: this.icon,
      coverImage: this.coverImage,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime,
      pageCount: this.pageCount
    };
    return result;
  }
  
  static fromJSON(json: Record<string, Object>): Notebook {
    return new Notebook(
      json.id as string || '',
      json.title as string || '',
      json.description as string || '',
      json.color as string || '#0078D4',
      json.icon as string || 'notebook',
      json.coverImage as string || '',
      json.createdTime as number || Date.now(),
      json.modifiedTime as number || Date.now(),
      json.pageCount as number || 0
    );
  }
  
  validate(): boolean {
    if (!this.title || this.title.trim().length === 0) {
      return false;
    }
    if (this.title.length > 100) {
      return false;
    }
    return true;
  }
}
/**
 * 分区数据模型
 * 用于表示笔记本中的分区
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class Section {
  id: string;
  notebookId: string;
  parentId: string;
  title: string;
  order: number;
  createdTime: number;
  modifiedTime: number;
  
  constructor(
    id: string = '',
    notebookId: string = '',
    parentId: string = '',
    title: string = '',
    order: number = 0,
    createdTime: number = Date.now(),
    modifiedTime: number = Date.now()
  ) {
    this.id = id;
    this.notebookId = notebookId;
    this.parentId = parentId;
    this.title = title;
    this.order = order;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
  }
  
  toJSON(): Object {
    return {
      id: this.id,
      notebookId: this.notebookId,
      parentId: this.parentId,
      title: this.title,
      order: this.order,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime
    };
  }
  
  static fromJSON(json: Object): Section {
    return new Section(
      json['id'] || '',
      json['notebookId'] || '',
      json['parentId'] || '',
      json['title'] || '',
      json['order'] || 0,
      json['createdTime'] || Date.now(),
      json['modifiedTime'] || Date.now()
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
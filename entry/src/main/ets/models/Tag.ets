/**
 * 标签数据模型
 * 用于表示笔记的标签
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class Tag {
  id: string;
  name: string;
  createdTime: number;
  
  constructor(
    id: string = '',
    name: string = '',
    createdTime: number = Date.now()
  ) {
    this.id = id;
    this.name = name;
    this.createdTime = createdTime;
  }
  
  toJSON(): Object {
    return {
      id: this.id,
      name: this.name,
      createdTime: this.createdTime
    };
  }
  
  static fromJSON(json: Object): Tag {
    return new Tag(
      json['id'] || '',
      json['name'] || '',
      json['createdTime'] || Date.now()
    );
  }
  
  validate(): boolean {
    if (!this.name || this.name.trim().length === 0) {
      return false;
    }
    if (this.name.length > 50) {
      return false;
    }
    return true;
  }
}
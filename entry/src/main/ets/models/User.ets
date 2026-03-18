export interface UserJSON {
  id: string;
  username: string;
  email: string;
  displayName: string;
  avatar?: string;
  createdTime: number;
  lastLoginTime: number;
}

export class User {
  id: string;
  username: string;
  email: string;
  displayName: string;
  avatar?: string;
  createdTime: number;
  lastLoginTime: number;
  
  constructor(
    id: string = '',
    username: string = '',
    email: string = '',
    displayName: string = '',
    avatar?: string,
    createdTime: number = Date.now(),
    lastLoginTime: number = Date.now()
  ) {
    this.id = id;
    this.username = username;
    this.email = email;
    this.displayName = displayName;
    this.avatar = avatar;
    this.createdTime = createdTime;
    this.lastLoginTime = lastLoginTime;
  }
  
  toJSON(): UserJSON {
    return {
      id: this.id,
      username: this.username,
      email: this.email,
      displayName: this.displayName,
      avatar: this.avatar,
      createdTime: this.createdTime,
      lastLoginTime: this.lastLoginTime
    };
  }
  
  static fromJSON(json: UserJSON): User {
    return new User(
      json.id as string || '',
      json.username as string || '',
      json.email as string || '',
      json.displayName as string || '',
      json.avatar as string || undefined,
      json.createdTime as number || Date.now(),
      json.lastLoginTime as number || Date.now()
    );
  }
  
  validate(): boolean {
    if (!this.id || this.id.trim().length === 0) {
      return false;
    }
    if (!this.username || this.username.trim().length === 0) {
      return false;
    }
    if (!this.email || this.email.trim().length === 0) {
      return false;
    }
    return true;
  }
}

/**
 * 日期工具类
 * 提供日期格式化和处理功能
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class DateUtils {
  /**
   * 格式化日期
   * @param timestamp 时间戳
   * @param format 格式字符串
   * @returns 格式化后的日期字符串
   */
  public static format(timestamp: number, format: string = 'yyyy-MM-dd HH:mm:ss'): string {
    const date: Date = new Date(timestamp);
    
    const year: number = date.getFullYear();
    const month: number = date.getMonth() + 1;
    const day: number = date.getDate();
    const hours: number = date.getHours();
    const minutes: number = date.getMinutes();
    const seconds: number = date.getSeconds();
    
    return format
      .replace('yyyy', year.toString())
      .replace('MM', month.toString().padStart(2, '0'))
      .replace('dd', day.toString().padStart(2, '0'))
      .replace('HH', hours.toString().padStart(2, '0'))
      .replace('mm', minutes.toString().padStart(2, '0'))
      .replace('ss', seconds.toString().padStart(2, '0'));
  }
  
  /**
   * 获取当前时间戳
   * @returns 当前时间戳
   */
  public static now(): number {
    return Date.now();
  }
  
  /**
   * 判断是否是今天
   * @param timestamp 时间戳
   * @returns 是否是今天
   */
  public static isToday(timestamp: number): boolean {
    const date: Date = new Date(timestamp);
    const today: Date = new Date();
    
    return date.getFullYear() === today.getFullYear() &&
      date.getMonth() === today.getMonth() &&
      date.getDate() === today.getDate();
  }
  
  /**
   * 判断是否是昨天
   * @param timestamp 时间戳
   * @returns 是否是昨天
   */
  public static isYesterday(timestamp: number): boolean {
    const date: Date = new Date(timestamp);
    const yesterday: Date = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    return date.getFullYear() === yesterday.getFullYear() &&
      date.getMonth() === yesterday.getMonth() &&
      date.getDate() === yesterday.getDate();
  }
  
  /**
   * 获取相对时间描述
   * @param timestamp 时间戳
   * @returns 相对时间描述
   */
  public static getRelativeTime(timestamp: number): string {
    const now: number = Date.now();
    const diff: number = now - timestamp;
    
    const minute: number = 60 * 1000;
    const hour: number = 60 * minute;
    const day: number = 24 * hour;
    const week: number = 7 * day;
    const month: number = 30 * day;
    const year: number = 365 * day;
    
    if (diff < minute) {
      return '刚刚';
    } else if (diff < hour) {
      return `${Math.floor(diff / minute)}分钟前`;
    } else if (diff < day) {
      return `${Math.floor(diff / hour)}小时前`;
    } else if (diff < week) {
      return `${Math.floor(diff / day)}天前`;
    } else if (diff < month) {
      return `${Math.floor(diff / week)}周前`;
    } else if (diff < year) {
      return `${Math.floor(diff / month)}个月前`;
    } else {
      return `${Math.floor(diff / year)}年前`;
    }
  }
  
  /**
   * 比较两个日期是否是同一天
   * @param timestamp1 时间戳1
   * @param timestamp2 时间戳2
   * @returns 是否是同一天
   */
  public static isSameDay(timestamp1: number, timestamp2: number): boolean {
    const date1: Date = new Date(timestamp1);
    const date2: Date = new Date(timestamp2);
    
    return date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth() &&
      date1.getDate() === date2.getDate();
  }
}
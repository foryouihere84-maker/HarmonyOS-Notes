/**
 * 字符串工具类
 * 提供字符串处理相关功能
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class StringUtils {
  /**
   * 判断字符串是否为空
   * @param str 字符串
   * @returns 是否为空
   */
  public static isEmpty(str: string | null | undefined): boolean {
    return str === null || str === undefined || str.trim().length === 0;
  }
  
  /**
   * 截断字符串
   * @param str 字符串
   * @param maxLength 最大长度
   * @param suffix 后缀
   * @returns 截断后的字符串
   */
  public static truncate(str: string, maxLength: number, suffix: string = '...'): string {
    if (str.length <= maxLength) {
      return str;
    }
    return str.substring(0, maxLength - suffix.length) + suffix;
  }
  
  /**
   * 高亮关键词
   * @param text 文本
   * @param keyword 关键词
   * @param highlightColor 高亮颜色
   * @returns 高亮后的文本
   */
  public static highlightKeyword(text: string, keyword: string, highlightColor: string = '#FF0000'): string {
    if (StringUtils.isEmpty(keyword)) {
      return text;
    }
    
    const regex: RegExp = new RegExp(`(${keyword})`, 'gi');
    return text.replace(regex, `<span style="color:${highlightColor}">$1</span>`);
  }
  
  /**
   * 移除HTML标签
   * @param html HTML字符串
   * @returns 纯文本
   */
  public static stripHtmlTags(html: string): string {
    return html.replace(/<[^>]*>/g, '');
  }
  
  /**
   * 转义HTML特殊字符
   * @param text 文本
   * @returns 转义后的文本
   */
  public static escapeHtml(text: string): string {
    const map: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    };
    
    return text.replace(/[&<>"']/g, (m: string) => map[m]);
  }
  
  /**
   * 生成随机字符串
   * @param length 长度
   * @returns 随机字符串
   */
  public static generateRandomString(length: number): string {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result: string = '';
    for (let i: number = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }
  
  /**
   * 首字母大写
   * @param str 字符串
   * @returns 首字母大写的字符串
   */
  public static capitalize(str: string): string {
    if (StringUtils.isEmpty(str)) {
      return str;
    }
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
  
  /**
   * 驼峰命名转下划线命名
   * @param str 驼峰命名字符串
   * @returns 下划线命名字符串
   */
  public static camelToSnake(str: string): string {
    return str.replace(/[A-Z]/g, (letter: string) => `_${letter.toLowerCase()}`);
  }
  
  /**
   * 下划线命名转驼峰命名
   * @param str 下划线命名字符串
   * @returns 驼峰命名字符串
   */
  public static snakeToCamel(str: string): string {
    return str.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase());
  }
}
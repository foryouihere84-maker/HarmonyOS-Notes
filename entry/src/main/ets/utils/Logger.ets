/**
 * 日志工具类
 * 提供日志记录功能
 * 
 * @author 开发者
 * @date 2026-03-11
 */
import hilog from '@ohos.hilog';

export class Logger {
  private static readonly TAG: string = 'NotebookApp';
  private static isDebug: boolean = true;
  private static readonly DOMAIN: number = 0x0001;
  
  /**
   * 设置调试模式
   * @param debug 是否开启调试模式
   */
  public static setDebug(debug: boolean): void {
    Logger.isDebug = debug;
  }
  
  /**
   * 输出调试日志
   * @param tag 标签
   * @param message 消息
   */
  public static d(tag: string, message: string): void {
    if (Logger.isDebug) {
      hilog.debug(Logger.DOMAIN, tag, message);
    }
  }
  
  /**
   * 输出信息日志
   * @param tag 标签
   * @param message 消息
   */
  public static i(tag: string, message: string): void {
    hilog.info(Logger.DOMAIN, tag, message);
  }
  
  /**
   * 输出警告日志
   * @param tag 标签
   * @param message 消息
   */
  public static w(tag: string, message: string): void {
    hilog.warn(Logger.DOMAIN, tag, message);
  }
  
  /**
   * 输出错误日志
   * @param tag 标签
   * @param message 消息
   */
  public static e(tag: string, message: string): void {
    hilog.error(Logger.DOMAIN, tag, message);
  }
  
  /**
   * 输出错误日志（带异常）
   * @param tag 标签
   * @param message 消息
   * @param error 异常对象
   */
  public static ex(tag: string, message: string, error: Error): void {
    hilog.error(Logger.DOMAIN, tag, `${message}: ${error.message}`);
  }
}
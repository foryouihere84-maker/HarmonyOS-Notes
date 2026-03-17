import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import { Logger } from './Logger';

/**
 * 权限工具类
 * 用于检查和请求应用权限
 * 
 * @author 开发者
 * @date 2026-03-13
 */
export class PermissionUtils {
  private static atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

  /**
   * 检查权限是否已授予
   * @param context 应用上下文
   * @param permission 权限名称
   * @returns 是否已授予
   */
  public static async checkPermission(context: Context, permission: Permissions): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus: abilityAccessCtrl.GrantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        permission
      );
      
      const isGranted = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      Logger.i('PermissionUtils', `权限检查 ${permission}: ${isGranted ? '已授予' : '未授予'}`);
      
      return isGranted;
    } catch (error) {
      const err = error as BusinessError;
      Logger.e('PermissionUtils', `检查权限失败 ${permission}: ${err.message}`);
      return false;
    }
  }

  /**
   * 检查多个权限是否已授予
   * @param context 应用上下文
   * @param permissions 权限名称数组
   * @returns 权限授予状态对象
   */
  public static async checkPermissions(context: Context, permissions: Permissions[]): Promise<Record<string, boolean>> {
    const results: Record<string, boolean> = {};
    
    for (const permission of permissions) {
      results[permission] = await PermissionUtils.checkPermission(context, permission);
    }
    
    return results;
  }

  /**
   * 请求权限
   * @param context 应用上下文
   * @param permissions 权限名称数组
   * @returns 权限授予结果对象
   */
  public static async requestPermissions(context: Context, permissions: Permissions[]): Promise<Record<string, boolean>> {
    try {
      Logger.i('PermissionUtils', `请求权限: ${JSON.stringify(permissions)}`);
      
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(
        context,
        permissions
      );
      
      const results: Record<string, boolean> = {};
      for (let i = 0; i < permissions.length; i++) {
        const isGranted = result.authResults[i] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        results[permissions[i]] = isGranted;
        Logger.i('PermissionUtils', `权限 ${permissions[i]}: ${isGranted ? '已授予' : '未授予'}`);
      }
      
      return results;
    } catch (error) {
      const err = error as BusinessError;
      Logger.e('PermissionUtils', `请求权限失败: ${err.message}`);
      
      const results: Record<string, boolean> = {};
      for (const permission of permissions) {
        results[permission] = false;
      }
      return results;
    }
  }

  /**
   * 检查网络权限
   * @param context 应用上下文
   * @returns 网络权限是否已授予
   */
  public static async checkInternetPermission(context: Context): Promise<boolean> {
    return await PermissionUtils.checkPermission(context, 'ohos.permission.INTERNET' as Permissions);
  }

  /**
   * 检查网络信息权限
   * @param context 应用上下文
   * @returns 网络信息权限是否已授予
   */
  public static async checkNetworkInfoPermission(context: Context): Promise<boolean> {
    return await PermissionUtils.checkPermission(context, 'ohos.permission.GET_NETWORK_INFO' as Permissions);
  }

  /**
   * 检查所有网络相关权限
   * @param context 应用上下文
   * @returns 所有网络权限的授予状态
   */
  public static async checkAllNetworkPermissions(context: Context): Promise<Record<string, boolean>> {
    const permissions: Permissions[] = [
      'ohos.permission.INTERNET' as Permissions,
      'ohos.permission.GET_NETWORK_INFO' as Permissions
    ];
    
    return await PermissionUtils.checkPermissions(context, permissions);
  }

  /**
   * 请求所有网络相关权限
   * @param context 应用上下文
   * @returns 所有网络权限的授予结果
   */
  public static async requestAllNetworkPermissions(context: Context): Promise<Record<string, boolean>> {
    const permissions: Permissions[] = [
      'ohos.permission.INTERNET' as Permissions,
      'ohos.permission.GET_NETWORK_INFO' as Permissions
    ];
    
    return await PermissionUtils.requestPermissions(context, permissions);
  }

  /**
   * 打印所有权限状态
   * @param context 应用上下文
   */
  public static async printAllPermissionStatus(context: Context): Promise<void> {
    Logger.i('PermissionUtils', '========== 权限状态检查 ==========');
    
    const internetPermission = await PermissionUtils.checkInternetPermission(context);
    const networkInfoPermission = await PermissionUtils.checkNetworkInfoPermission(context);
    
    Logger.i('PermissionUtils', `ohos.permission.INTERNET: ${internetPermission ? '✓ 已授予' : '✗ 未授予'}`);
    Logger.i('PermissionUtils', `ohos.permission.GET_NETWORK_INFO: ${networkInfoPermission ? '✓ 已授予' : '✗ 未授予'}`);
    
    Logger.i('PermissionUtils', '====================================');
  }
}
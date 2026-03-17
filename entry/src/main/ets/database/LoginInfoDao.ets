/**
 * 登录信息数据访问对象
 * 负责登录信息的数据库操作
 * 
 * @author 开发者
 * @date 2026-03-14
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseHelper } from './DatabaseHelper';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { LoginInfo } from '../models/LoginInfo';
import { Logger } from '../utils/Logger';

export class LoginInfoDao {
  private static instance: LoginInfoDao;
  
  private constructor() {}
  
  public static getInstance(): LoginInfoDao {
    if (!LoginInfoDao.instance) {
      LoginInfoDao.instance = new LoginInfoDao();
    }
    return LoginInfoDao.instance;
  }
  
  private getRdbStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getRdbStore();
  }
  
  public async insert(loginInfo: LoginInfo): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const valueBucket: relationalStore.ValuesBucket = {};
      valueBucket[DatabaseConstants.FIELD_ID] = loginInfo.id;
      valueBucket[DatabaseConstants.FIELD_USER_ID] = loginInfo.userId;
      valueBucket[DatabaseConstants.FIELD_EMAIL] = loginInfo.email;
      valueBucket[DatabaseConstants.FIELD_DISPLAY_NAME] = loginInfo.displayName;
      valueBucket[DatabaseConstants.FIELD_ACCESS_TOKEN] = loginInfo.accessToken;
      valueBucket[DatabaseConstants.FIELD_REFRESH_TOKEN] = loginInfo.refreshToken;
      valueBucket[DatabaseConstants.FIELD_LOGIN_TIME] = loginInfo.loginTime;
      valueBucket[DatabaseConstants.FIELD_EXPIRE_TIME] = loginInfo.expireTime;
      valueBucket[DatabaseConstants.FIELD_LAST_ACTIVE_TIME] = loginInfo.lastActiveTime;
      valueBucket[DatabaseConstants.FIELD_CREATED_TIME] = loginInfo.createdTime;
      valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = loginInfo.modifiedTime;
      
      const rowId = await rdbStore.insert(DatabaseConstants.TABLE_LOGIN_INFO, valueBucket);
      Logger.i('LoginInfoDao', `插入登录信息成功: ${loginInfo.email}`);
      return rowId;
    } catch (error) {
      Logger.e('LoginInfoDao', `插入登录信息失败: ${error}`);
      throw new Error('插入登录信息失败');
    }
  }
  
  public async update(loginInfo: LoginInfo): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const valueBucket: relationalStore.ValuesBucket = {};
      valueBucket[DatabaseConstants.FIELD_USER_ID] = loginInfo.userId;
      valueBucket[DatabaseConstants.FIELD_EMAIL] = loginInfo.email;
      valueBucket[DatabaseConstants.FIELD_DISPLAY_NAME] = loginInfo.displayName;
      valueBucket[DatabaseConstants.FIELD_ACCESS_TOKEN] = loginInfo.accessToken;
      valueBucket[DatabaseConstants.FIELD_REFRESH_TOKEN] = loginInfo.refreshToken;
      valueBucket[DatabaseConstants.FIELD_LOGIN_TIME] = loginInfo.loginTime;
      valueBucket[DatabaseConstants.FIELD_EXPIRE_TIME] = loginInfo.expireTime;
      valueBucket[DatabaseConstants.FIELD_LAST_ACTIVE_TIME] = loginInfo.lastActiveTime;
      valueBucket[DatabaseConstants.FIELD_MODIFIED_TIME] = loginInfo.modifiedTime;
      
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.equalTo(DatabaseConstants.FIELD_ID, loginInfo.id);
      
      const rowsAffected = await rdbStore.update(valueBucket, predicates);
      Logger.i('LoginInfoDao', `更新登录信息成功: ${loginInfo.email}`);
      return rowsAffected;
    } catch (error) {
      Logger.e('LoginInfoDao', `更新登录信息失败: ${error}`);
      throw new Error('更新登录信息失败');
    }
  }
  
  public async delete(id: string): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.equalTo(DatabaseConstants.FIELD_ID, id);
      
      const rowsAffected = await rdbStore.delete(predicates);
      Logger.i('LoginInfoDao', `删除登录信息成功: ${id}`);
      return rowsAffected;
    } catch (error) {
      Logger.e('LoginInfoDao', `删除登录信息失败: ${error}`);
      throw new Error('删除登录信息失败');
    }
  }
  
  public async deleteAll(): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      
      const rowsAffected = await rdbStore.delete(predicates);
      Logger.i('LoginInfoDao', `删除所有登录信息成功，共${rowsAffected}条`);
      return rowsAffected;
    } catch (error) {
      Logger.e('LoginInfoDao', `删除所有登录信息失败: ${error}`);
      throw new Error('删除所有登录信息失败');
    }
  }
  
  public async getById(id: string): Promise<LoginInfo | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.equalTo(DatabaseConstants.FIELD_ID, id);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const loginInfo = this.fromResultSet(resultSet);
      resultSet.close();
      
      return loginInfo;
    } catch (error) {
      Logger.e('LoginInfoDao', `获取登录信息失败: ${error}`);
      throw new Error('获取登录信息失败');
    }
  }
  
  public async getByUserId(userId: string): Promise<LoginInfo | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.equalTo(DatabaseConstants.FIELD_USER_ID, userId);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const loginInfo = this.fromResultSet(resultSet);
      resultSet.close();
      
      return loginInfo;
    } catch (error) {
      Logger.e('LoginInfoDao', `根据用户ID获取登录信息失败: ${error}`);
      throw new Error('根据用户ID获取登录信息失败');
    }
  }
  
  public async getByEmail(email: string): Promise<LoginInfo | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.equalTo(DatabaseConstants.FIELD_EMAIL, email);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const loginInfo = this.fromResultSet(resultSet);
      resultSet.close();
      
      return loginInfo;
    } catch (error) {
      Logger.e('LoginInfoDao', `根据邮箱获取登录信息失败: ${error}`);
      throw new Error('根据邮箱获取登录信息失败');
    }
  }
  
  public async getLatest(): Promise<LoginInfo | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.orderByDesc(DatabaseConstants.FIELD_LOGIN_TIME);
      predicates.limitAs(1);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const loginInfo = this.fromResultSet(resultSet);
      resultSet.close();
      
      return loginInfo;
    } catch (error) {
      Logger.e('LoginInfoDao', `获取最新登录信息失败: ${error}`);
      throw new Error('获取最新登录信息失败');
    }
  }
  
  public async getValidLogin(): Promise<LoginInfo | null> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.greaterThan(DatabaseConstants.FIELD_EXPIRE_TIME, Date.now());
      predicates.orderByDesc(DatabaseConstants.FIELD_LOGIN_TIME);
      predicates.limitAs(1);
      
      const resultSet = await rdbStore.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }
      
      resultSet.goToFirstRow();
      const loginInfo = this.fromResultSet(resultSet);
      resultSet.close();
      
      return loginInfo;
    } catch (error) {
      Logger.e('LoginInfoDao', `获取有效登录信息失败: ${error}`);
      throw new Error('获取有效登录信息失败');
    }
  }
  
  public async getAll(): Promise<LoginInfo[]> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.orderByDesc(DatabaseConstants.FIELD_LOGIN_TIME);
      
      const resultSet = await rdbStore.query(predicates);
      const loginInfos: LoginInfo[] = [];
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          loginInfos.push(this.fromResultSet(resultSet));
        } while (resultSet.goToNextRow());
      }
      
      resultSet.close();
      return loginInfos;
    } catch (error) {
      Logger.e('LoginInfoDao', `获取所有登录信息失败: ${error}`);
      throw new Error('获取所有登录信息失败');
    }
  }
  
  public async deleteExpired(): Promise<number> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.lessThanOrEqualTo(DatabaseConstants.FIELD_EXPIRE_TIME, Date.now());
      
      const rowsAffected = await rdbStore.delete(predicates);
      Logger.i('LoginInfoDao', `删除过期登录信息成功，共${rowsAffected}条`);
      return rowsAffected;
    } catch (error) {
      Logger.e('LoginInfoDao', `删除过期登录信息失败: ${error}`);
      throw new Error('删除过期登录信息失败');
    }
  }
  
  public async emailExists(email: string): Promise<boolean> {
    try {
      const rdbStore = this.getRdbStore();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_LOGIN_INFO);
      predicates.equalTo(DatabaseConstants.FIELD_EMAIL, email);
      
      const resultSet = await rdbStore.query(predicates);
      const exists = resultSet.rowCount > 0;
      resultSet.close();
      
      return exists;
    } catch (error) {
      Logger.e('LoginInfoDao', `检查邮箱是否存在失败: ${error}`);
      throw new Error('检查邮箱是否存在失败');
    }
  }
  
  private fromResultSet(resultSet: relationalStore.ResultSet): LoginInfo {
    return new LoginInfo(
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ID)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_USER_ID)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_EMAIL)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_DISPLAY_NAME)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_ACCESS_TOKEN)),
      resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.FIELD_REFRESH_TOKEN)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_LOGIN_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_EXPIRE_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_LAST_ACTIVE_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_CREATED_TIME)),
      resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.FIELD_MODIFIED_TIME))
    );
  }
}

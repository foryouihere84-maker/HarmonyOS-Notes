/**
 * 同步配置DAO测试套件
 * 测试同步配置数据访问功能（F3.1-F3.5）
 *
 * 测试范围：
 * - F3.1 同步配置存储
 * - F3.2 配置加密
 * - F3.3 配置验证
 * - F3.4 配置修改
 * - F3.5 配置删除
 *
 * @author 测试工程师
 * @date 2026-03-12
 */
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { SyncConfigDao } from '../../main/ets/database/SyncConfigDao';
import { DatabaseHelper } from '../../main/ets/database/DatabaseHelper';
import { SyncConfig } from '../../main/ets/models/SyncConfig';
import { ConflictResolution } from '../../main/ets/models/SyncHistory';
import common from '@ohos.app.ability.common';

export default function SyncConfigDaoTest() {
  describe('同步配置DAO功能测试', () => {
    let syncConfigDao: SyncConfigDao;
    let testConfigId: string = 'test_config_001';
    let testUserId: string = 'test_user_001';
    let testEmail: string = 'dao_test@example.com';
    let context: common.Context;

    beforeAll(async () => {
      console.info('[SyncConfigDaoTest] 测试套件初始化开始');

      try {
        // 初始化数据库
        await DatabaseHelper.getInstance().init(context);

        // 初始化DAO
        syncConfigDao = SyncConfigDao.getInstance();

        console.info('[SyncConfigDaoTest] 测试套件初始化完成');
      } catch (error) {
        console.error('[SyncConfigDaoTest] 测试套件初始化失败: ' + error);
        throw error;
      }
    });

    beforeEach(async () => {
      console.info('[SyncConfigDaoTest] 测试用例前置处理开始');

      try {
        // 清理测试数据
        const existingConfig = await syncConfigDao.getByEmail(testEmail);
        if (existingConfig) {
          await syncConfigDao.delete(existingConfig.id);
        }

        console.info('[SyncConfigDaoTest] 测试用例前置处理完成');
      } catch (error) {
        console.error('[SyncConfigDaoTest] 测试用例前置处理失败: ' + error);
        throw error;
      }
    });

    afterEach(async () => {
      console.info('[SyncConfigDaoTest] 测试用例后置处理开始');

      try {
        // 清理测试数据
        const existingConfig = await syncConfigDao.getByEmail(testEmail);
        if (existingConfig) {
          await syncConfigDao.delete(existingConfig.id);
        }

        console.info('[SyncConfigDaoTest] 测试用例后置处理完成');
      } catch (error) {
        console.error('[SyncConfigDaoTest] 测试用例后置处理失败: ' + error);
      }
    });

    afterAll(async () => {
      console.info('[SyncConfigDaoTest] 测试套件清理开始');

      try {
        // 清理所有测试数据
        const existingConfig = await syncConfigDao.getByEmail(testEmail);
        if (existingConfig) {
          await syncConfigDao.delete(existingConfig.id);
        }

        console.info('[SyncConfigDaoTest] 测试套件清理完成');
      } catch (error) {
        console.error('[SyncConfigDaoTest] 测试套件清理失败: ' + error);
      }
    });

    /**
     * ========================================
     * F3.1 同步配置存储测试
     * ========================================
     */
    describe('F3.1 同步配置存储', () => {
      it('F3.1.1 插入同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.1.1 插入同步配置成功');

        // 创建同步配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        // 插入配置
        const rowId = await syncConfigDao.insert(config);

        // 验证插入成功
        expect(rowId).assertLarger(0);

        // 验证可以查询到
        const insertedConfig = await syncConfigDao.getById(testConfigId);
        expect(insertedConfig).not.toBeNull();
        expect(insertedConfig.email).assertEqual(testEmail);

        console.info('[SyncConfigDaoTest] F3.1.1 插入同步配置成功验证通过');
      });

      it('F3.1.2 根据ID获取同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.1.2 根据ID获取同步配置成功');

        // 创建并插入配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        // 根据ID获取配置
        const retrievedConfig = await syncConfigDao.getById(testConfigId);

        // 验证获取成功
        expect(retrievedConfig).not.toBeNull();
        expect(retrievedConfig.id).assertEqual(testConfigId);
        expect(retrievedConfig.userId).assertEqual(testUserId);
        expect(retrievedConfig.email).assertEqual(testEmail);

        console.info('[SyncConfigDaoTest] F3.1.2 根据ID获取同步配置成功验证通过');
      });

      it('F3.1.3 根据用户ID获取同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.1.3 根据用户ID获取同步配置成功');

        // 创建并插入配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        // 根据用户ID获取配置
        const retrievedConfig = await syncConfigDao.getByUserId(testUserId);

        // 验证获取成功
        expect(retrievedConfig).not.toBeNull();
        expect(retrievedConfig.userId).assertEqual(testUserId);
        expect(retrievedConfig.email).assertEqual(testEmail);

        console.info('[SyncConfigDaoTest] F3.1.3 根据用户ID获取同步配置成功验证通过');
      });

      it('F3.1.4 根据邮箱获取同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.1.4 根据邮箱获取同步配置成功');

        // 创建并插入配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        // 根据邮箱获取配置
        const retrievedConfig = await syncConfigDao.getByEmail(testEmail);

        // 验证获取成功
        expect(retrievedConfig).not.toBeNull();
        expect(retrievedConfig.email).assertEqual(testEmail);
        expect(retrievedConfig.userId).assertEqual(testUserId);

        console.info('[SyncConfigDaoTest] F3.1.4 根据邮箱获取同步配置成功验证通过');
      });

      it('F3.1.5 获取所有同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.1.5 获取所有同步配置成功');

        // 创建多个配置
        const config1 = new SyncConfig(
          'test_config_001',
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        const email2 = 'test2@example.com';
        const config2 = new SyncConfig(
          'test_config_002',
          testUserId,
          email2,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        await syncConfigDao.insert(config1);
        await syncConfigDao.insert(config2);

        // 获取所有配置
        const allConfigs = await syncConfigDao.getAll();

        // 验证获取成功
        expect(allConfigs).not.toBeNull();
        expect(Array.isArray(allConfigs)).assertEqual(true);
        expect(allConfigs.length).assertLargerOrEqual(2);

        // 清理第二个配置
        const config2Retrieved = await syncConfigDao.getByEmail(email2);
        if (config2Retrieved) {
          await syncConfigDao.delete(config2Retrieved.id);
        }

        console.info('[SyncConfigDaoTest] F3.1.5 获取所有同步配置成功验证通过');
      });

      it('F3.1.6 获取已启用的同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.1.6 获取已启用的同步配置成功');

        // 创建启用的配置
        const enabledConfig = new SyncConfig(
          'test_config_enabled',
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          true,  // enabled
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(enabledConfig);

        // 创建未启用的配置
        const disabledConfig = new SyncConfig(
          'test_config_disabled',
          testUserId,
          'disabled@example.com',
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,  // enabled
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(disabledConfig);

        // 获取已启用的配置
        const enabledConfigs = await syncConfigDao.getEnabled();

        // 验证获取成功
        expect(enabledConfigs).not.toBeNull();
        expect(Array.isArray(enabledConfigs)).assertEqual(true);
        expect(enabledConfigs.length).assertLargerOrEqual(1);

        // 验证所有配置都是已启用的
        for (const config of enabledConfigs) {
          expect(config.enabled).assertEqual(true);
        }

        // 清理
        const disabledRetrieved = await syncConfigDao.getByEmail('disabled@example.com');
        if (disabledRetrieved) {
          await syncConfigDao.delete(disabledRetrieved.id);
        }

        console.info('[SyncConfigDaoTest] F3.1.6 获取已启用的同步配置成功验证通过');
      });

      it('F3.1.7 检查邮箱是否存在成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.1.7 检查邮箱是否存在成功');

        // 验证邮箱不存在
        let exists = await syncConfigDao.emailExists(testEmail);
        expect(exists).assertEqual(false);

        // 创建配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        // 验证邮箱存在
        exists = await syncConfigDao.emailExists(testEmail);
        expect(exists).assertEqual(true);

        console.info('[SyncConfigDaoTest] F3.1.7 检查邮箱是否存在成功验证通过');
      });
    });

    /**
     * ========================================
     * F3.3 配置验证测试
     * ========================================
     */
    describe('F3.3 配置验证', () => {
      it('F3.3.1 有效配置验证通过', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.3.1 有效配置验证通过');

        // 创建有效配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        // 验证配置
        const isValid = config.validate();

        // 验证通过
        expect(isValid).assertEqual(true);

        console.info('[SyncConfigDaoTest] F3.3.1 有效配置验证通过验证通过');
      });

      it('F3.3.2 空邮箱验证失败', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.3.2 空邮箱验证失败');

        // 创建无效配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          '',
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        // 验证配置
        const isValid = config.validate();

        // 验证失败
        expect(isValid).assertEqual(false);

        console.info('[SyncConfigDaoTest] F3.3.2 空邮箱验证失败验证通过');
      });

      it('F3.3.3 空用户ID验证失败', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.3.3 空用户ID验证失败');

        // 创建无效配置
        const config = new SyncConfig(
          testConfigId,
          '',
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        // 验证配置
        const isValid = config.validate();

        // 验证失败
        expect(isValid).assertEqual(false);

        console.info('[SyncConfigDaoTest] F3.3.3 空用户ID验证失败验证通过');
      });

      it('F3.3.4 无效同步路径验证失败', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.3.4 无效同步路径验证失败');

        // 创建无效配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          'InvalidPath',  // 不以/开头
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        // 验证配置
        const isValid = config.validate();

        // 验证失败
        expect(isValid).assertEqual(false);

        console.info('[SyncConfigDaoTest] F3.3.4 无效同步路径验证失败验证通过');
      });
    });

    /**
     * ========================================
     * F3.4 配置修改测试
     * ========================================
     */
    describe('F3.4 配置修改', () => {
      it('F3.4.1 更新同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.4.1 更新同步配置成功');

        // 创建并插入配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        // 修改配置
        config.autoSync = true;
        config.syncInterval = 7200000;
        config.enabled = true;
        config.updateModifiedTime();

        // 更新配置
        const rowsAffected = await syncConfigDao.update(config);

        // 验证更新成功
        expect(rowsAffected).assertLarger(0);

        // 验证修改已保存
        const updatedConfig = await syncConfigDao.getById(testConfigId);
        expect(updatedConfig?.autoSync).assertEqual(true);
        expect(updatedConfig?.syncInterval).assertEqual(7200000);
        expect(updatedConfig?.enabled).assertEqual(true);

        console.info('[SyncConfigDaoTest] F3.4.1 更新同步配置成功验证通过');
      });

      it('F3.4.2 更新不存在的配置失败', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.4.2 更新不存在的配置失败');

        // 创建配置
        const config = new SyncConfig(
          'non_existent_id',
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        // 尝试更新不存在的配置
        const rowsAffected = await syncConfigDao.update(config);

        // 验证没有更新任何行
        expect(rowsAffected).assertEqual(0);

        console.info('[SyncConfigDaoTest] F3.4.2 更新不存在的配置失败验证通过');
      });
    });

    /**
     * ========================================
     * F3.5 配置删除测试
     * ========================================
     */
    describe('F3.5 配置删除', () => {
      it('F3.5.1 删除同步配置成功', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.5.1 删除同步配置成功');

        // 创建并插入配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        // 验证配置存在
        let retrievedConfig = await syncConfigDao.getById(testConfigId);
        expect(retrievedConfig).not.toBeNull();

        // 删除配置
        const rowsAffected = await syncConfigDao.delete(testConfigId);

        // 验证删除成功
        expect(rowsAffected).assertLarger(0);

        // 验证配置已删除
        retrievedConfig = await syncConfigDao.getById(testConfigId);
        expect(retrievedConfig).assertNull();

        console.info('[SyncConfigDaoTest] F3.5.1 删除同步配置成功验证通过');
      });

      it('F3.5.2 删除不存在的配置失败', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: F3.5.2 删除不存在的配置失败');

        // 尝试删除不存在的配置
        const rowsAffected = await syncConfigDao.delete('non_existent_id');

        // 验证没有删除任何行
        expect(rowsAffected).assertEqual(0);

        console.info('[SyncConfigDaoTest] F3.5.2 删除不存在的配置失败验证通过');
      });
    });

    /**
     * ========================================
     * 边界情况测试
     * ========================================
     */
    describe('边界情况测试', () => {
      it('获取不存在的配置返回null', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 获取不存在的配置返回null');

        // 获取不存在的配置
        const config = await syncConfigDao.getById('non_existent_id');

        // 验证返回null
        expect(config).assertNull();

        console.info('[SyncConfigDaoTest] 获取不存在的配置返回null验证通过');
      });

      it('检查不存在的邮箱返回false', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 检查不存在的邮箱返回false');

        // 检查不存在的邮箱
        const exists = await syncConfigDao.emailExists('non_existent@example.com');

        // 验证返回false
        expect(exists).assertEqual(false);

        console.info('[SyncConfigDaoTest] 检查不存在的邮箱返回false验证通过');
      });

      it('空配置列表', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 空配置列表');

        // 清理所有配置
        const allConfigs = await syncConfigDao.getAll();
        for (const config of allConfigs) {
          await syncConfigDao.delete(config.id);
        }

        // 获取所有配置
        const emptyConfigs = await syncConfigDao.getAll();

        // 验证返回空数组
        expect(emptyConfigs).not.toBeNull();
        expect(Array.isArray(emptyConfigs)).assertEqual(true);
        expect(emptyConfigs.length).assertEqual(0);

        console.info('[SyncConfigDaoTest] 空配置列表验证通过');
      });

      it('特殊字符邮箱处理', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 特殊字符邮箱处理');

        const specialEmail = 'test+special@example.com';

        // 创建配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          specialEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        // 获取配置
        const retrievedConfig = await syncConfigDao.getByEmail(specialEmail);

        // 验证获取成功
        expect(retrievedConfig).not.toBeNull();
        expect(retrievedConfig.email).assertEqual(specialEmail);

        console.info('[SyncConfigDaoTest] 特殊字符邮箱处理验证通过');
      });
    });

    /**
     * ========================================
     * 性能测试
     * ========================================
     */
    describe('性能测试', () => {
      it('插入配置性能', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 插入配置性能');

        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );

        const startTime = Date.now();

        await syncConfigDao.insert(config);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 插入操作应该在100ms内完成
        expect(duration).assertLess(100);

        console.info('[SyncConfigDaoTest] 插入配置性能验证通过: ' + duration + 'ms');
      });

      it('查询配置性能', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 查询配置性能');

        // 创建配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        const startTime = Date.now();

        await syncConfigDao.getById(testConfigId);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 查询操作应该在50ms内完成
        expect(duration).assertLess(50);

        console.info('[SyncConfigDaoTest] 查询配置性能验证通过: ' + duration + 'ms');
      });

      it('更新配置性能', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 更新配置性能');

        // 创建配置
        const config = new SyncConfig(
          testConfigId,
          testUserId,
          testEmail,
          '/NotebookApp',
          'encrypted_access_token',
          'encrypted_refresh_token',
          'client_id',
          'encrypted_client_secret',
          false,
          3600000,
          0,
          false,
          ConflictResolution.LATEST,
          Date.now(),
          Date.now()
        );
        await syncConfigDao.insert(config);

        const startTime = Date.now();

        config.autoSync = true;
        await syncConfigDao.update(config);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 更新操作应该在100ms内完成
        expect(duration).assertLess(100);

        console.info('[SyncConfigDaoTest] 更新配置性能验证通过: ' + duration + 'ms');
      });

      it('批量插入配置性能', 0, async () => {
        console.info('[SyncConfigDaoTest] 测试: 批量插入配置性能');

        const startTime = Date.now();

        // 批量插入10个配置
        const promises = [];
        for (let i = 0; i < 10; i++) {
          const config = new SyncConfig(
            `test_config_${i}`,
            testUserId,
            `test${i}@example.com`,
            '/NotebookApp',
            'encrypted_access_token',
            'encrypted_refresh_token',
            'client_id',
            'encrypted_client_secret',
            false,
            3600000,
            0,
            false,
            ConflictResolution.LATEST,
            Date.now(),
            Date.now()
          );
          promises.push(syncConfigDao.insert(config));
        }

        await Promise.all(promises);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 批量插入10个配置应该在1秒内完成
        expect(duration).assertLess(1000);

        // 清理
        for (let i = 0; i < 10; i++) {
          await syncConfigDao.delete(`test_config_${i}`);
        }

        console.info('[SyncConfigDaoTest] 批量插入配置性能验证通过: ' + duration + 'ms');
      });
    });
  });
}

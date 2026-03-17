/**
 * 同步历史DAO测试套件
 * 测试同步历史记录功能（F2.9）
 *
 * 测试范围：
 * - F2.9 同步历史记录
 *
 * @author 测试工程师
 * @date 2026-03-12
 */
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { SyncHistoryDao } from '../../main/ets/database/SyncHistoryDao';
import { DatabaseHelper } from '../../main/ets/database/DatabaseHelper';
import { SyncHistory, ConflictResolution } from '../../main/ets/models/SyncHistory';
import { SyncType, SyncState } from '../../main/ets/models/SyncStatus';
import common from '@ohos.app.ability.common';

export default function SyncHistoryDaoTest() {
  describe('同步历史DAO功能测试', () => {
    let syncHistoryDao: SyncHistoryDao;
    let testHistoryId: string = 'test_history_001';
    let testConfigId: string = 'test_config_001';
    let testConfigEmail: string = 'history_test@example.com';
    let context: common.Context;

    beforeAll(async () => {
      console.info('[SyncHistoryDaoTest] 测试套件初始化开始');

      try {
        // 初始化数据库
        await DatabaseHelper.getInstance().init(context);

        // 初始化DAO
        syncHistoryDao = SyncHistoryDao.getInstance();

        console.info('[SyncHistoryDaoTest] 测试套件初始化完成');
      } catch (error) {
        console.error('[SyncHistoryDaoTest] 测试套件初始化失败: ' + error);
        throw error;
      }
    });

    beforeEach(async () => {
      console.info('[SyncHistoryDaoTest] 测试用例前置处理开始');

      try {
        // 清理测试数据
        const existingHistory = await syncHistoryDao.getById(testHistoryId);
        if (existingHistory) {
          await syncHistoryDao.delete(testHistoryId);
        }

        console.info('[SyncHistoryDaoTest] 测试用例前置处理完成');
      } catch (error) {
        console.error('[SyncHistoryDaoTest] 测试用例前置处理失败: ' + error);
        throw error;
      }
    });

    afterEach(async () => {
      console.info('[SyncHistoryDaoTest] 测试用例后置处理开始');

      try {
        // 清理测试数据
        const existingHistory = await syncHistoryDao.getById(testHistoryId);
        if (existingHistory) {
          await syncHistoryDao.delete(testHistoryId);
        }

        console.info('[SyncHistoryDaoTest] 测试用例后置处理完成');
      } catch (error) {
        console.error('[SyncHistoryDaoTest] 测试用例后置处理失败: ' + error);
      }
    });

    afterAll(async () => {
      console.info('[SyncHistoryDaoTest] 测试套件清理开始');

      try {
        // 清理所有测试数据
        const existingHistory = await syncHistoryDao.getById(testHistoryId);
        if (existingHistory) {
          await syncHistoryDao.delete(testHistoryId);
        }

        console.info('[SyncHistoryDaoTest] 测试套件清理完成');
      } catch (error) {
        console.error('[SyncHistoryDaoTest] 测试套件清理失败: ' + error);
      }
    });

    /**
     * ========================================
     * F2.9 同步历史记录测试
     * ========================================
     */
    describe('F2.9 同步历史记录', () => {
      it('F2.9.1 插入同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.1 插入同步历史记录成功');

        // 创建同步历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );

        // 插入历史记录
        const rows = await syncHistoryDao.insert(history);

        // 验证插入成功
        expect(rows).assertLarger(0);

        // 验证可以查询到
        const insertedHistory = await syncHistoryDao.getById(testHistoryId);
        expect(insertedHistory).not.toBeNull();
        expect(insertedHistory.configEmail).assertEqual(testConfigEmail);

        console.info('[SyncHistoryDaoTest] F2.9.1 插入同步历史记录成功验证通过');
      });

      it('F2.9.2 根据ID获取同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.2 根据ID获取同步历史记录成功');

        // 创建并插入历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );
        await syncHistoryDao.insert(history);

        // 根据ID获取历史记录
        const retrievedHistory = await syncHistoryDao.getById(testHistoryId);

        // 验证获取成功
        expect(retrievedHistory).not.toBeNull();
        expect(retrievedHistory.id).assertEqual(testHistoryId);
        expect(retrievedHistory.configId).assertEqual(testConfigId);
        expect(retrievedHistory.configEmail).assertEqual(testConfigEmail);

        console.info('[SyncHistoryDaoTest] F2.9.2 根据ID获取同步历史记录成功验证通过');
      });

      it('F2.9.3 获取所有同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.3 获取所有同步历史记录成功');

        // 创建多个历史记录
        const history1 = new SyncHistory(
          'test_history_001',
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );

        const history2 = new SyncHistory(
          'test_history_002',
          SyncType.FULL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          10000,
          20,
          10,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );

        await syncHistoryDao.insert(history1);
        await syncHistoryDao.insert(history2);

        // 获取所有历史记录
        const allHistories = await syncHistoryDao.getAll(10, 0);

        // 验证获取成功
        expect(allHistories).not.toBeNull();
        expect(Array.isArray(allHistories)).assertEqual(true);
        expect(allHistories.length).assertLargerOrEqual(2);

        // 清理
        await syncHistoryDao.delete('test_history_001');
        await syncHistoryDao.delete('test_history_002');

        console.info('[SyncHistoryDaoTest] F2.9.3 获取所有同步历史记录成功验证通过');
      });

      it('F2.9.4 根据配置ID获取同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.4 根据配置ID获取同步历史记录成功');

        // 创建历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );
        await syncHistoryDao.insert(history);

        // 根据配置ID获取历史记录
        const histories = await syncHistoryDao.getByConfigId(testConfigId, 10, 0);

        // 验证获取成功
        expect(histories).not.toBeNull();
        expect(Array.isArray(histories)).assertEqual(true);
        expect(histories.length).assertLargerOrEqual(1);

        // 验证所有历史记录都属于该配置
        for (const h of histories) {
          expect(h.configId).assertEqual(testConfigId);
        }

        console.info('[SyncHistoryDaoTest] F2.9.4 根据配置ID获取同步历史记录成功验证通过');
      });

      it('F2.9.5 获取失败的同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.5 获取失败的同步历史记录成功');

        // 创建失败的历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.FAILED,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          0,
          0,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '同步失败：网络错误',
          false
        );
        await syncHistoryDao.insert(history);

        // 获取失败的历史记录
        const failedHistories = await syncHistoryDao.getFailedHistories(10);

        // 验证获取成功
        expect(failedHistories).not.toBeNull();
        expect(Array.isArray(failedHistories)).assertEqual(true);
        expect(failedHistories.length).assertLargerOrEqual(1);

        // 验证所有历史记录都是失败的
        for (const h of failedHistories) {
          expect(h.state).assertEqual(SyncState.FAILED);
        }

        console.info('[SyncHistoryDaoTest] F2.9.5 获取失败的同步历史记录成功验证通过');
      });

      it('F2.9.6 获取有冲突的同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.6 获取有冲突的同步历史记录成功');

        // 创建有冲突的历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          3,  // conflictCount = 3
          ConflictResolution.LATEST,
          '',
          false
        );
        await syncHistoryDao.insert(history);

        // 获取有冲突的历史记录
        const conflictHistories = await syncHistoryDao.getConflictHistories(10);

        // 验证获取成功
        expect(conflictHistories).not.toBeNull();
        expect(Array.isArray(conflictHistories)).assertEqual(true);
        expect(conflictHistories.length).assertLargerOrEqual(1);

        // 验证所有历史记录都有冲突
        for (const h of conflictHistories) {
          expect(h.conflictCount).assertLarger(0);
        }

        console.info('[SyncHistoryDaoTest] F2.9.6 获取有冲突的同步历史记录成功验证通过');
      });

      it('F2.9.7 获取自动同步的历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.7 获取自动同步的历史记录成功');

        // 创建自动同步的历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          true  // isAutoSync = true
        );
        await syncHistoryDao.insert(history);

        // 获取自动同步的历史记录
        const autoSyncHistories = await syncHistoryDao.getAutoSyncHistories(10);

        // 验证获取成功
        expect(autoSyncHistories).not.toBeNull();
        expect(Array.isArray(autoSyncHistories)).assertEqual(true);
        expect(autoSyncHistories.length).assertLargerOrEqual(1);

        // 验证所有历史记录都是自动同步
        for (const h of autoSyncHistories) {
          expect(h.isAutoSync).assertEqual(true);
        }

        console.info('[SyncHistoryDaoTest] F2.9.7 获取自动同步的历史记录成功验证通过');
      });

      it('F2.9.8 获取统计信息成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.8 获取统计信息成功');

        // 创建多个历史记录
        const history1 = new SyncHistory(
          'test_history_001',
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );

        const history2 = new SyncHistory(
          'test_history_002',
          SyncType.FULL,
          SyncState.FAILED,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          0,
          0,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '同步失败',
          false
        );

        await syncHistoryDao.insert(history1);
        await syncHistoryDao.insert(history2);

        // 获取统计信息
        const statistics = await syncHistoryDao.getStatistics();

        // 验证统计信息
        expect(statistics).not.toBeNull();
        expect(statistics.totalCount).assertLargerOrEqual(2);
        expect(statistics.successCount).assertLargerOrEqual(1);
        expect(statistics.failedCount).assertLargerOrEqual(1);
        expect(statistics.totalUploaded).assertLargerOrEqual(10);
        expect(statistics.totalDownloaded).assertLargerOrEqual(5);

        // 清理
        await syncHistoryDao.delete('test_history_001');
        await syncHistoryDao.delete('test_history_002');

        console.info('[SyncHistoryDaoTest] F2.9.8 获取统计信息成功验证通过');
      });

      it('F2.9.9 更新同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.9 更新同步历史记录成功');

        // 创建并插入历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SYNCING,
          testConfigId,
          testConfigEmail,
          Date.now(),
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );
        await syncHistoryDao.insert(history);

        // 更新历史记录
        history.state = SyncState.SUCCESS;
        history.endTime = Date.now();
        history.duration = 5000;
        history.itemsUploaded = 10;
        history.itemsDownloaded = 5;

        const rowsAffected = await syncHistoryDao.update(history);

        // 验证更新成功
        expect(rowsAffected).assertLarger(0);

        // 验证更新已保存
        const updatedHistory = await syncHistoryDao.getById(testHistoryId);
        expect(updatedHistory?.state).assertEqual(SyncState.SUCCESS);
        expect(updatedHistory?.duration).assertEqual(5000);
        expect(updatedHistory?.itemsUploaded).assertEqual(10);
        expect(updatedHistory?.itemsDownloaded).assertEqual(5);

        console.info('[SyncHistoryDaoTest] F2.9.9 更新同步历史记录成功验证通过');
      });

      it('F2.9.10 删除同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.10 删除同步历史记录成功');

        // 创建并插入历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );
        await syncHistoryDao.insert(history);

        // 验证历史记录存在
        let retrievedHistory = await syncHistoryDao.getById(testHistoryId);
        expect(retrievedHistory).not.toBeNull();

        // 删除历史记录
        const rowsAffected = await syncHistoryDao.delete(testHistoryId);

        // 验证删除成功
        expect(rowsAffected).assertLarger(0);

        // 验证历史记录已删除
        retrievedHistory = await syncHistoryDao.getById(testHistoryId);
        expect(retrievedHistory).assertNull();

        console.info('[SyncHistoryDaoTest] F2.9.10 删除同步历史记录成功验证通过');
      });

      it('F2.9.11 清理旧的同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.11 清理旧的同步历史记录成功');

        // 创建旧的历史记录（31天前）
        const oldTime = Date.now() - (31 * 24 * 60 * 60 * 1000);
        const oldHistory = new SyncHistory(
          'test_history_old',
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          oldTime,
          oldTime,
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );
        await syncHistoryDao.insert(oldHistory);

        // 清理旧的同步历史记录
        const rowsAffected = await syncHistoryDao.cleanOldHistories(30);

        // 验证清理成功
        expect(rowsAffected).assertLarger(0);

        // 验证旧历史记录已删除
        const deletedHistory = await syncHistoryDao.getById('test_history_old');
        expect(deletedHistory).assertNull();

        console.info('[SyncHistoryDaoTest] F2.9.11 清理旧的同步历史记录成功验证通过');
      });

      it('F2.9.12 清空所有同步历史记录成功', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: F2.9.12 清空所有同步历史记录成功');

        // 创建多个历史记录
        const history1 = new SyncHistory(
          'test_history_001',
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );

        const history2 = new SyncHistory(
          'test_history_002',
          SyncType.FULL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          10000,
          20,
          10,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );

        await syncHistoryDao.insert(history1);
        await syncHistoryDao.insert(history2);

        // 清空所有历史记录
        const rowsAffected = await syncHistoryDao.clearAll();

        // 验证清空成功
        expect(rowsAffected).assertLarger(0);

        // 验证所有历史记录已删除
        const allHistories = await syncHistoryDao.getAll(10, 0);
        expect(allHistories.length).assertEqual(0);

        console.info('[SyncHistoryDaoTest] F2.9.12 清空所有同步历史记录成功验证通过');
      });
    });

    /**
     * ========================================
     * 边界情况测试
     * ========================================
     */
    describe('边界情况测试', () => {
      it('获取不存在的同步历史记录返回null', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: 获取不存在的同步历史记录返回null');

        // 获取不存在的同步历史记录
        const history = await syncHistoryDao.getById('non_existent_id');

        // 验证返回null
        expect(history).assertNull();

        console.info('[SyncHistoryDaoTest] 获取不存在的同步历史记录返回null验证通过');
      });

      it('空同步历史记录列表', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: 空同步历史记录列表');

        // 清空所有历史记录
        await syncHistoryDao.clearAll();

        // 获取所有历史记录
        const emptyHistories = await syncHistoryDao.getAll(10, 0);

        // 验证返回空数组
        expect(emptyHistories).not.toBeNull();
        expect(Array.isArray(emptyHistories)).assertEqual(true);
        expect(emptyHistories.length).assertEqual(0);

        console.info('[SyncHistoryDaoTest] 空同步历史记录列表验证通过');
      });

      it('限制和偏移参数正确工作', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: 限制和偏移参数正确工作');

        // 创建多个历史记录
        for (let i = 0; i < 10; i++) {
          const history = new SyncHistory(
            `test_history_${i}`,
            SyncType.INCREMENTAL,
            SyncState.SUCCESS,
            testConfigId,
            testConfigEmail,
            Date.now() - i * 1000,
            Date.now() - i * 1000,
            5000,
            10,
            5,
            0,
            0,
            0,
            0,
            ConflictResolution.LATEST,
            '',
            false
          );
          await syncHistoryDao.insert(history);
        }

        // 获取前5个历史记录
        const first5 = await syncHistoryDao.getAll(5, 0);
        expect(first5.length).assertEqual(5);

        // 获取后5个历史记录
        const last5 = await syncHistoryDao.getAll(5, 5);
        expect(last5.length).assertEqual(5);

        // 清理
        for (let i = 0; i < 10; i++) {
          await syncHistoryDao.delete(`test_history_${i}`);
        }

        console.info('[SyncHistoryDaoTest] 限制和偏移参数正确工作验证通过');
      });
    });

    /**
     * ========================================
     * 性能测试
     * ========================================
     */
    describe('性能测试', () => {
      it('插入历史记录性能', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: 插入历史记录性能');

        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );

        const startTime = Date.now();

        await syncHistoryDao.insert(history);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 插入操作应该在100ms内完成
        expect(duration).assertLess(100);

        console.info('[SyncHistoryDaoTest] 插入历史记录性能验证通过: ' + duration + 'ms');
      });

      it('查询历史记录性能', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: 查询历史记录性能');

        // 创建历史记录
        const history = new SyncHistory(
          testHistoryId,
          SyncType.INCREMENTAL,
          SyncState.SUCCESS,
          testConfigId,
          testConfigEmail,
          Date.now(),
          Date.now(),
          5000,
          10,
          5,
          0,
          0,
          0,
          0,
          ConflictResolution.LATEST,
          '',
          false
        );
        await syncHistoryDao.insert(history);

        const startTime = Date.now();

        await syncHistoryDao.getById(testHistoryId);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 查询操作应该在50ms内完成
        expect(duration).assertLess(50);

        console.info('[SyncHistoryDaoTest] 查询历史记录性能验证通过: ' + duration + 'ms');
      });

      it('批量插入历史记录性能', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: 批量插入历史记录性能');

        const startTime = Date.now();

        // 批量插入10个历史记录
        const promises = [];
        for (let i = 0; i < 10; i++) {
          const history = new SyncHistory(
            `test_history_${i}`,
            SyncType.INCREMENTAL,
            SyncState.SUCCESS,
            testConfigId,
            testConfigEmail,
            Date.now(),
            Date.now(),
            5000,
            10,
            5,
            0,
            0,
            0,
            0,
            ConflictResolution.LATEST,
            '',
            false
          );
          promises.push(syncHistoryDao.insert(history));
        }

        await Promise.all(promises);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 批量插入10个历史记录应该在1秒内完成
        expect(duration).assertLess(1000);

        // 清理
        for (let i = 0; i < 10; i++) {
          await syncHistoryDao.delete(`test_history_${i}`);
        }

        console.info('[SyncHistoryDaoTest] 批量插入历史记录性能验证通过: ' + duration + 'ms');
      });

      it('获取统计信息性能', 0, async () => {
        console.info('[SyncHistoryDaoTest] 测试: 获取统计信息性能');

        // 创建一些历史记录
        for (let i = 0; i < 5; i++) {
          const history = new SyncHistory(
            `test_history_${i}`,
            SyncType.INCREMENTAL,
            SyncState.SUCCESS,
            testConfigId,
            testConfigEmail,
            Date.now(),
            Date.now(),
            5000,
            10,
            5,
            0,
            0,
            0,
            0,
            ConflictResolution.LATEST,
            '',
            false
          );
          await syncHistoryDao.insert(history);
        }

        const startTime = Date.now();

        await syncHistoryDao.getStatistics();

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 获取统计信息应该在500ms内完成
        expect(duration).assertLess(500);

        // 清理
        for (let i = 0; i < 5; i++) {
          await syncHistoryDao.delete(`test_history_${i}`);
        }

        console.info('[SyncHistoryDaoTest] 获取统计信息性能验证通过: ' + duration + 'ms');
      });
    });
  });
}

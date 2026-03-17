import abilityTest from './Ability.test';
import storageServiceTest from './StorageService.test';
import oneDriveServiceTest from './OneDriveService.test';
import syncServiceTest from './SyncService.test';
import syncConfigDaoTest from './SyncConfigDao.test';
import syncHistoryDaoTest from './SyncHistoryDao.test';
import fileUtilsTest from './FileUtils.test';
import cryptoUtilsTest from './CryptoUtils.test';
import syncUtilsTest from './SyncUtils.test';

/**
 * 测试套件入口文件
 * 包含所有测试模块
 *
 * @author 测试工程师
 * @date 2026-03-12
 */
export default function testsuite() {
  // 能力测试
  abilityTest();

  // 存储服务测试（F1.1-F1.7）
  storageServiceTest();

  // OneDrive服务测试（F2.1-F2.10）
  oneDriveServiceTest();

  // 同步服务测试（F2.3-F2.10）
  syncServiceTest();

  // 同步配置DAO测试（F3.1-F3.5）
  syncConfigDaoTest();

  // 同步历史DAO测试（F2.9）
  syncHistoryDaoTest();

  // 文件工具测试
  fileUtilsTest();

  // 加密工具测试（F3.2）
  cryptoUtilsTest();

  // 同步工具测试
  syncUtilsTest();
}

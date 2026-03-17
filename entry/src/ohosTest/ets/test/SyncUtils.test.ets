/**
 * 同步工具类测试套件
 * 测试同步工具功能
 *
 * @author 测试工程师
 * @date 2026-03-12
 */
import { describe, it, expect } from '@ohos/hypium';
import { SyncUtils, FileMetadata, FileChangeType, ConflictInfo, SyncQueueItem } from '../../main/ets/utils/SyncUtils';
import { ConflictResolution } from '../../main/ets/models/SyncHistory';

export default function SyncUtilsTest() {
  describe('同步工具类功能测试', () => {
    /**
     * ========================================
     * 文件变更检测测试（F2.5）
     * ========================================
     */
    describe('F2.5 文件变更检测', () => {
      it('F2.5.1 检测本地新增文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.5.1 检测本地新增文件');

        const localFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 1024,
            modifiedTime: Date.now()
          }
        ];

        const remoteFiles: FileMetadata[] = [];
        const lastSyncTime = Date.now() - 3600000; // 1小时前

        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        // 验证检测到新增文件
        expect(changes.length).assertEqual(1);
        expect(changes[0].type).assertEqual(FileChangeType.ADDED);
        expect(changes[0].path).assertEqual('/notes/page1.json');
        expect(changes[0].localMetadata).not.toBeNull();
        expect(changes[0].remoteMetadata).toBeUndefined();

        console.info('[SyncUtilsTest] F2.5.1 检测本地新增文件验证通过');
      });

      it('F2.5.2 检测远程新增文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.5.2 检测远程新增文件');

        const localFiles: FileMetadata[] = [];
        const remoteFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 1024,
            modifiedTime: Date.now()
          }
        ];

        const lastSyncTime = Date.now() - 3600000; // 1小时前

        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        // 验证检测到新增文件
        expect(changes.length).assertEqual(1);
        expect(changes[0].type).assertEqual(FileChangeType.ADDED);
        expect(changes[0].path).assertEqual('/notes/page1.json');
        expect(changes[0].localMetadata).toBeUndefined();
        expect(changes[0].remoteMetadata).not.toBeNull();

        console.info('[SyncUtilsTest] F2.5.2 检测远程新增文件验证通过');
      });

      it('F2.5.3 检测本地修改文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.5.3 检测本地修改文件');

        const lastSyncTime = Date.now() - 3600000; // 1小时前

        const localFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 2048, // 大小改变
            modifiedTime: lastSyncTime + 1800000 // 30分钟前修改
          }
        ];

        const remoteFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 1024,
            modifiedTime: lastSyncTime + 600000 // 10分钟前修改
          }
        ];

        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        // 验证检测到修改文件
        expect(changes.length).assertEqual(1);
        expect(changes[0].type).assertEqual(FileChangeType.MODIFIED);
        expect(changes[0].path).assertEqual('/notes/page1.json');
        expect(changes[0].localMetadata).not.toBeNull();
        expect(changes[0].remoteMetadata).not.toBeNull();

        console.info('[SyncUtilsTest] F2.5.3 检测本地修改文件验证通过');
      });

      it('F2.5.4 检测远程修改文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.5.4 检测远程修改文件');

        const lastSyncTime = Date.now() - 3600000; // 1小时前

        const localFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 1024,
            modifiedTime: lastSyncTime + 600000 // 10分钟前修改
          }
        ];

        const remoteFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 2048, // 大小改变
            modifiedTime: lastSyncTime + 1800000 // 30分钟前修改
          }
        ];

        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        // 验证检测到修改文件
        expect(changes.length).assertEqual(1);
        expect(changes[0].type).assertEqual(FileChangeType.MODIFIED);
        expect(changes[0].path).assertEqual('/notes/page1.json');
        expect(changes[0].localMetadata).not.toBeNull();
        expect(changes[0].remoteMetadata).not.toBeNull();

        console.info('[SyncUtilsTest] F2.5.4 检测远程修改文件验证通过');
      });

      it('F2.5.5 未变更文件不检测', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.5.5 未变更文件不检测');

        const lastSyncTime = Date.now() - 3600000; // 1小时前

        const localFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 1024,
            modifiedTime: lastSyncTime - 1800000 // 1.5小时前修改
          }
        ];

        const remoteFiles: FileMetadata[] = [
          {
            path: '/notes/page1.json',
            size: 1024,
            modifiedTime: lastSyncTime - 1800000 // 1.5小时前修改
          }
        ];

        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        // 验证未检测到变更
        expect(changes.length).assertEqual(0);

        console.info('[SyncUtilsTest] F2.5.5 未变更文件不检测验证通过');
      });
    });

    /**
     * ========================================
     * F2.7 冲突解决测试
     * ========================================
     */
    describe('F2.7 冲突解决', () => {
      it('F2.7.1 检测文件冲突', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.7.1 检测文件冲突');

        const currentTime = Date.now();

        const changes = [
          {
            path: '/notes/page1.json',
            type: FileChangeType.MODIFIED,
            localMetadata: {
              path: '/notes/page1.json',
              size: 2048,
              modifiedTime: currentTime - 120000 // 2分钟前
            },
            remoteMetadata: {
              path: '/notes/page1.json',
              size: 2048,
              modifiedTime: currentTime - 180000 // 3分钟前
            }
          }
        ];

        const conflicts = SyncUtils.detectConflicts(changes);

        // 验证检测到冲突
        expect(conflicts.length).assertEqual(1);
        expect(conflicts[0].localPath).assertEqual('/notes/page1.json');
        expect(conflicts[0].remotePath).assertEqual('/notes/page1.json');

        console.info('[SyncUtilsTest] F2.7.1 检测文件冲突验证通过');
      });

      it('F2.7.2 最新优先策略', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.7.2 最新优先策略');

        const currentTime = Date.now();

        const conflict: ConflictInfo = {
          localPath: '/notes/page1.json',
          remotePath: '/notes/page1.json',
          localMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 120000 // 2分钟前（较新）
          },
          remoteMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 180000 // 3分钟前（较旧）
          }
        };

        const resolvedPath = SyncUtils.resolveConflict(conflict, ConflictResolution.LATEST);

        // 验证选择本地文件（较新）
        expect(resolvedPath).assertEqual('/notes/page1.json');

        console.info('[SyncUtilsTest] F2.7.2 最新优先策略验证通过');
      });

      it('F2.7.3 本地优先策略', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.7.3 本地优先策略');

        const currentTime = Date.now();

        const conflict: ConflictInfo = {
          localPath: '/notes/page1.json',
          remotePath: '/notes/page1.json',
          localMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 180000 // 3分钟前（较旧）
          },
          remoteMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 120000 // 2分钟前（较新）
          }
        };

        const resolvedPath = SyncUtils.resolveConflict(conflict, ConflictResolution.LOCAL);

        // 验证选择本地文件
        expect(resolvedPath).assertEqual('/notes/page1.json');

        console.info('[SyncUtilsTest] F2.7.3 本地优先策略验证通过');
      });

      it('F2.7.4 云端优先策略', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.7.4 云端优先策略');

        const currentTime = Date.now();

        const conflict: ConflictInfo = {
          localPath: '/notes/page1.json',
          remotePath: '/notes/page1.json',
          localMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 180000 // 3分钟前（较旧）
          },
          remoteMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 120000 // 2分钟前（较新）
          }
        };

        const resolvedPath = SyncUtils.resolveConflict(conflict, ConflictResolution.REMOTE);

        // 验证选择远程文件
        expect(resolvedPath).assertEqual('/notes/page1.json');

        console.info('[SyncUtilsTest] F2.7.4 云端优先策略验证通过');
      });

      it('F2.7.5 双方保留策略', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.7.5 双方保留策略');

        const currentTime = Date.now();

        const conflict: ConflictInfo = {
          localPath: '/notes/page1.json',
          remotePath: '/notes/page1.json',
          localMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 120000
          },
          remoteMetadata: {
            path: '/notes/page1.json',
            size: 2048,
            modifiedTime: currentTime - 180000
          }
        };

        const resolvedPath = SyncUtils.resolveConflict(conflict, ConflictResolution.BOTH);

        // 验证创建备份文件
        expect(resolvedPath).assertContain('.conflict_');
        expect(resolvedPath).assertContain('/notes/page1.json');

        console.info('[SyncUtilsTest] F2.7.5 双方保留策略验证通过');
      });
    });

    /**
     * ========================================
     * F2.10 离线支持测试
     * ========================================
     */
    describe('F2.10 离线支持', () => {
      it('F2.10.1 添加同步队列项', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.10.1 添加同步队列项');

        // 添加队列项
        SyncUtils.addSyncQueueItem('upload', '/notes/page1.json', '/remote/page1.json', 10);

        // 验证队列大小增加
        const queueSize = SyncUtils.getSyncQueueSize();
        expect(queueSize).assertLarger(0);

        // 清空队列
        SyncUtils.clearSyncQueue();

        console.info('[SyncUtilsTest] F2.10.1 添加同步队列项验证通过');
      });

      it('F2.10.2 处理同步队列', 0, async () => {
        console.info('[SyncUtilsTest] 测试: F2.10.2 处理同步队列');

        // 添加队列项
        SyncUtils.addSyncQueueItem('upload', '/notes/page1.json', '/remote/page1.json', 10);
        SyncUtils.addSyncQueueItem('download', '/notes/page2.json', '/remote/page2.json', 5);

        // 处理队列
        let processedCount = 0;
        await SyncUtils.processSyncQueue(async (item: SyncQueueItem) => {
          processedCount++;
        });

        // 验证处理了所有队列项
        expect(processedCount).assertEqual(2);

        // 验证队列已清空
        expect(SyncUtils.getSyncQueueSize()).assertEqual(0);

        console.info('[SyncUtilsTest] F2.10.2 处理同步队列验证通过');
      });

      it('F2.10.3 清空同步队列', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.10.3 清空同步队列');

        // 添加队列项
        SyncUtils.addSyncQueueItem('upload', '/notes/page1.json', '/remote/page1.json', 10);
        SyncUtils.addSyncQueueItem('download', '/notes/page2.json', '/remote/page2.json', 5);

        // 验证队列不为空
        expect(SyncUtils.getSyncQueueSize()).assertLarger(0);

        // 清空队列
        SyncUtils.clearSyncQueue();

        // 验证队列已清空
        expect(SyncUtils.getSyncQueueSize()).assertEqual(0);

        console.info('[SyncUtilsTest] F2.10.3 清空同步队列验证通过');
      });

      it('F2.10.4 获取同步队列大小', 0, () => {
        console.info('[SyncUtilsTest] 测试: F2.10.4 获取同步队列大小');

        // 验证初始队列为空
        expect(SyncUtils.getSyncQueueSize()).assertEqual(0);

        // 添加队列项
        SyncUtils.addSyncQueueItem('upload', '/notes/page1.json', '/remote/page1.json', 10);

        // 验证队列大小为1
        expect(SyncUtils.getSyncQueueSize()).assertEqual(1);

        // 清空队列
        SyncUtils.clearSyncQueue();

        console.info('[SyncUtilsTest] F2.10.4 获取同步队列大小验证通过');
      });
    });

    /**
     * ========================================
     * 文件比较测试
     * ========================================
     */
    describe('文件比较', () => {
      it('比较相同文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: 比较相同文件');

        const file1: FileMetadata = {
          path: '/notes/page1.json',
          size: 1024,
          modifiedTime: Date.now()
        };

        const file2: FileMetadata = {
          path: '/notes/page1.json',
          size: 1024,
          modifiedTime: Date.now()
        };

        const isEqual = SyncUtils.areFilesEqual(file1, file2);

        // 验证文件相同
        expect(isEqual).assertEqual(true);

        console.info('[SyncUtilsTest] 比较相同文件验证通过');
      });

      it('比较不同文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: 比较不同文件');

        const file1: FileMetadata = {
          path: '/notes/page1.json',
          size: 1024,
          modifiedTime: Date.now()
        };

        const file2: FileMetadata = {
          path: '/notes/page1.json',
          size: 2048, // 大小不同
          modifiedTime: Date.now()
        };

        const isEqual = SyncUtils.areFilesEqual(file1, file2);

        // 验证文件不同
        expect(isEqual).assertEqual(false);

        console.info('[SyncUtilsTest] 比较不同文件验证通过');
      });

      it('检查是否需要同步', 0, () => {
        console.info('[SyncUtilsTest] 测试: 检查是否需要同步');

        const lastSyncTime = Date.now() - 3600000; // 1小时前

        const localFile: FileMetadata = {
          path: '/notes/page1.json',
          size: 1024,
          modifiedTime: lastSyncTime + 1800000 // 30分钟前修改（需要同步）
        };

        const remoteFile: FileMetadata = {
          path: '/notes/page1.json',
          size: 1024,
          modifiedTime: lastSyncTime - 1800000 // 1.5小时前修改
        };

        const needsSync = SyncUtils.needsSync(localFile, remoteFile, lastSyncTime);

        // 验证需要同步
        expect(needsSync).assertEqual(true);

        console.info('[SyncUtilsTest] 检查是否需要同步验证通过');
      });
    });

    /**
     * ========================================
     * 文件路径处理测试
     * ========================================
     */
    describe('文件路径处理', () => {
      it('验证文件路径', 0, () => {
        console.info('[SyncUtilsTest] 测试: 验证文件路径');

        // 有效路径
        expect(SyncUtils.isValidFilePath('/notes/page1.json')).assertEqual(true);
        expect(SyncUtils.isValidFilePath('/notes/subfolder/page2.json')).assertEqual(true);

        // 无效路径
        expect(SyncUtils.isValidFilePath('')).assertEqual(false);
        expect(SyncUtils.isValidFilePath('   ')).assertEqual(false);
        expect(SyncUtils.isValidFilePath('/invalid<path>.json')).assertEqual(false);
        expect(SyncUtils.isValidFilePath('/invalid|path.json')).assertEqual(false);

        console.info('[SyncUtilsTest] 验证文件路径验证通过');
      });

      it('标准化文件路径', 0, () => {
        console.info('[SyncUtilsTest] 测试: 标准化文件路径');

        expect(SyncUtils.normalizeFilePath('/notes/page1.json')).assertEqual('notes/page1.json');
        expect(SyncUtils.normalizeFilePath('notes/page1.json')).assertEqual('notes/page1.json');
        expect(SyncUtils.normalizeFilePath('/notes//page1.json')).assertEqual('notes/page1.json');
        expect(SyncUtils.normalizeFilePath('\\notes\\page1.json')).assertEqual('notes/page1.json');
        expect(SyncUtils.normalizeFilePath('/notes/page1.json/')).assertEqual('notes/page1.json');

        console.info('[SyncUtilsTest] 标准化文件路径验证通过');
      });

      it('获取文件扩展名', 0, () => {
        console.info('[SyncUtilsTest] 测试: 获取文件扩展名');

        expect(SyncUtils.getFileExtension('test.txt')).assertEqual('txt');
        expect(SyncUtils.getFileExtension('document.pdf')).assertEqual('pdf');
        expect(SyncUtils.getFileExtension('image.jpg')).assertEqual('jpg');
        expect(SyncUtils.getFileExtension('noextension')).assertEqual('');
        expect(SyncUtils.getFileExtension('archive.tar.gz')).assertEqual('gz');

        console.info('[SyncUtilsTest] 获取文件扩展名验证通过');
      });

      it('检查是否为图片文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: 检查是否为图片文件');

        expect(SyncUtils.isImageFile('test.jpg')).assertEqual(true);
        expect(SyncUtils.isImageFile('test.jpeg')).assertEqual(true);
        expect(SyncUtils.isImageFile('test.png')).assertEqual(true);
        expect(SyncUtils.isImageFile('test.gif')).assertEqual(true);
        expect(SyncUtils.isImageFile('test.bmp')).assertEqual(true);
        expect(SyncUtils.isImageFile('test.webp')).assertEqual(true);
        expect(SyncUtils.isImageFile('test.txt')).assertEqual(false);
        expect(SyncUtils.isImageFile('test.pdf')).assertEqual(false);

        console.info('[SyncUtilsTest] 检查是否为图片文件验证通过');
      });

      it('检查是否为文档文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: 检查是否为文档文件');

        expect(SyncUtils.isDocumentFile('test.pdf')).assertEqual(true);
        expect(SyncUtils.isDocumentFile('test.doc')).assertEqual(true);
        expect(SyncUtils.isDocumentFile('test.docx')).assertEqual(true);
        expect(SyncUtils.isDocumentFile('test.txt')).assertEqual(true);
        expect(SyncUtils.isDocumentFile('test.md')).assertEqual(true);
        expect(SyncUtils.isDocumentFile('test.html')).assertEqual(true);
        expect(SyncUtils.isDocumentFile('test.jpg')).assertEqual(false);
        expect(SyncUtils.isDocumentFile('test.mp3')).assertEqual(false);

        console.info('[SyncUtilsTest] 检查是否为文档文件验证通过');
      });

      it('检查是否为音频文件', 0, () => {
        console.info('[SyncUtilsTest] 测试: 检查是否为音频文件');

        expect(SyncUtils.isAudioFile('test.mp3')).assertEqual(true);
        expect(SyncUtils.isAudioFile('test.wav')).assertEqual(true);
        expect(SyncUtils.isAudioFile('test.ogg')).assertEqual(true);
        expect(SyncUtils.isAudioFile('test.aac')).assertEqual(true);
        expect(SyncUtils.isAudioFile('test.flac')).assertEqual(true);
        expect(SyncUtils.isAudioFile('test.txt')).assertEqual(false);
        expect(SyncUtils.isAudioFile('test.jpg')).assertEqual(false);

        console.info('[SyncUtilsTest] 检查是否为音频文件验证通过');
      });
    });

    /**
     * ========================================
     * 格式化测试
     * ========================================
     */
    describe('格式化', () => {
      it('格式化文件大小', 0, () => {
        console.info('[SyncUtilsTest] 测试: 格式化文件大小');

        expect(SyncUtils.formatFileSize(0)).assertEqual('0 B');
        expect(SyncUtils.formatFileSize(512)).assertEqual('512 B');
        expect(SyncUtils.formatFileSize(1024)).assertEqual('1.00 KB');
        expect(SyncUtils.formatFileSize(1024 * 1024)).assertEqual('1.00 MB');
        expect(SyncUtils.formatFileSize(1024 * 1024 * 1024)).assertEqual('1.00 GB');

        console.info('[SyncUtilsTest] 格式化文件大小验证通过');
      });

      it('格式化时间戳', 0, () => {
        console.info('[SyncUtilsTest] 测试: 格式化时间戳');

        const timestamp = Date.now();
        const formatted = SyncUtils.formatTimestamp(timestamp);

        // 验证格式化结果不为空
        expect(formatted).not.toBeNull();
        expect(formatted.length).assertLarger(0);

        console.info('[SyncUtilsTest] 格式化时间戳验证通过');
      });
    });

    /**
     * ========================================
     * 边界情况测试
     * ========================================
     */
    describe('边界情况测试', () => {
      it('空文件列表', 0, () => {
        console.info('[SyncUtilsTest] 测试: 空文件列表');

        const localFiles: FileMetadata[] = [];
        const remoteFiles: FileMetadata[] = [];
        const lastSyncTime = Date.now() - 3600000;

        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        // 验证没有变更
        expect(changes.length).assertEqual(0);

        console.info('[SyncUtilsTest] 空文件列表验证通过');
      });

      it('大量文件变更', 0, () => {
        console.info('[SyncUtilsTest] 测试: 大量文件变更');

        const localFiles: FileMetadata[] = [];
        const remoteFiles: FileMetadata[] = [];

        // 创建100个本地文件
        for (let i = 0; i < 100; i++) {
          localFiles.push({
            path: `/notes/page${i}.json`,
            size: 1024,
            modifiedTime: Date.now()
          });
        }

        const lastSyncTime = Date.now() - 3600000;
        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        // 验证检测到所有变更
        expect(changes.length).assertEqual(100);

        console.info('[SyncUtilsTest] 大量文件变更验证通过');
      });

      it('队列已满时添加失败', 0, () => {
        console.info('[SyncUtilsTest] 测试: 队列已满时添加失败');

        // 清空队列
        SyncUtils.clearSyncQueue();

        // 添加大量队列项（超过最大限制）
        for (let i = 0; i < 1001; i++) {
          SyncUtils.addSyncQueueItem('upload', `/notes/page${i}.json`, `/remote/page${i}.json`, 10);
        }

        // 验证队列大小不超过最大限制
        const queueSize = SyncUtils.getSyncQueueSize();
        expect(queueSize).assertLessOrEqual(1000);

        // 清空队列
        SyncUtils.clearSyncQueue();

        console.info('[SyncUtilsTest] 队列已满时添加失败验证通过');
      });

      it('同时修改冲突', 0, () => {
        console.info('[SyncUtilsTest] 测试: 同时修改冲突');

        const currentTime = Date.now();

        const changes = [
          {
            path: '/notes/page1.json',
            type: FileChangeType.MODIFIED,
            localMetadata: {
              path: '/notes/page1.json',
              size: 2048,
              modifiedTime: currentTime - 120000 // 2分钟前
            },
            remoteMetadata: {
              path: '/notes/page1.json',
              size: 2048,
              modifiedTime: currentTime - 180000 // 3分钟前
            }
          }
        ];

        const conflicts = SyncUtils.detectConflicts(changes);

        // 验证检测到冲突（时间差小于5分钟）
        expect(conflicts.length).assertEqual(1);

        console.info('[SyncUtilsTest] 同时修改冲突验证通过');
      });

      it('不同时修改不冲突', 0, () => {
        console.info('[SyncUtilsTest] 测试: 不同时修改不冲突');

        const currentTime = Date.now();

        const changes = [
          {
            path: '/notes/page1.json',
            type: FileChangeType.MODIFIED,
            localMetadata: {
              path: '/notes/page1.json',
              size: 2048,
              modifiedTime: currentTime - 120000 // 2分钟前
            },
            remoteMetadata: {
              path: '/notes/page1.json',
              size: 2048,
              modifiedTime: currentTime - 600000 // 10分钟前（时间差大于5分钟）
            }
          }
        ];

        const conflicts = SyncUtils.detectConflicts(changes);

        // 验证没有检测到冲突
        expect(conflicts.length).assertEqual(0);

        console.info('[SyncUtilsTest] 不同时修改不冲突验证通过');
      });
    });

    /**
     * ========================================
     * 性能测试
     * ========================================
     */
    describe('性能测试', () => {
      it('检测大量文件变更性能', 0, () => {
        console.info('[SyncUtilsTest] 测试: 检测大量文件变更性能');

        const localFiles: FileMetadata[] = [];
        const remoteFiles: FileMetadata[] = [];

        // 创建1000个文件
        for (let i = 0; i < 1000; i++) {
          localFiles.push({
            path: `/notes/page${i}.json`,
            size: 1024,
            modifiedTime: Date.now()
          });
        }

        const lastSyncTime = Date.now() - 3600000;

        const startTime = Date.now();

        const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 验证检测到所有变更
        expect(changes.length).assertEqual(1000);

        // 验证性能（应该在100ms内完成）
        expect(duration).assertLess(100);

        console.info('[SyncUtilsTest] 检测大量文件变更性能验证通过: ' + duration + 'ms');
      });

      it('处理大量队列项性能', 0, async () => {
        console.info('[SyncUtilsTest] 测试: 处理大量队列项性能');

        // 清空队列
        SyncUtils.clearSyncQueue();

        // 添加100个队列项
        for (let i = 0; i < 100; i++) {
          SyncUtils.addSyncQueueItem('upload', `/notes/page${i}.json`, `/remote/page${i}.json`, 10);
        }

        const startTime = Date.now();

        let processedCount = 0;
        await SyncUtils.processSyncQueue(async (item: SyncQueueItem) => {
          processedCount++;
        });

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 验证处理了所有队列项
        expect(processedCount).assertEqual(100);

        // 验证性能（应该在200ms内完成）
        expect(duration).assertLess(200);

        console.info('[SyncUtilsTest] 处理大量队列项性能验证通过: ' + duration + 'ms');
      });
    });
  });
}

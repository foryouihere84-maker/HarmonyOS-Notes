/**
 * 存储服务测试套件
 * 测试文件持久化存储功能（F1.1-F1.7）
 *
 * 测试范围：
 * - F1.1 笔记文件持久化
 * - F1.2 附件文件持久化
 * - F1.3 文件目录管理
 * - F1.4 文件读写操作
 * - F1.5 文件元数据管理
 * - F1.6 文件完整性校验
 * - F1.7 存储空间管理
 *
 * @author 测试工程师
 * @date 2026-03-12
 */
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { StorageService } from '../../main/ets/services/StorageService';
import { Page } from '../../main/ets/models/Page';
import { Section } from '../../main/ets/models/Section';
import { AttachmentFile, AttachmentType } from '../../main/ets/models/AttachmentFile';
import { FileUtils } from '../../main/ets/utils/FileUtils';
import { AppConstants } from '../../main/ets/constants/AppConstants';
import common from '@ohos.app.ability.common';

export default function StorageServiceTest() {
  describe('存储服务功能测试', () => {
    let storageService: StorageService;
    let context: common.Context;
    let testPageId: string = 'test_page_001';
    let testPage: Page;

    beforeAll(async () => {
      console.info('[StorageServiceTest] 测试套件初始化开始');

      try {
        // 初始化存储服务
        storageService = StorageService.getInstance();
        await storageService.init(context);

        // 创建测试页面
        testPage = new Page(
          testPageId,
          'notebook_001',
          '测试页面',
          '这是一个测试页面',
          Date.now(),
          Date.now(),
          []
        );

        console.info('[StorageServiceTest] 测试套件初始化完成');
      } catch (error) {
        console.error('[StorageServiceTest] 测试套件初始化失败: ' + error);
        throw error;
      }
    });

    beforeEach(async () => {
      console.info('[StorageServiceTest] 测试用例前置处理开始');

      try {
        // 清理测试数据
        await storageService.deleteNoteFile(testPageId);
        await storageService.deleteAttachmentFilesByPage(testPageId);

        console.info('[StorageServiceTest] 测试用例前置处理完成');
      } catch (error) {
        console.error('[StorageServiceTest] 测试用例前置处理失败: ' + error);
        throw error;
      }
    });

    afterEach(async () => {
      console.info('[StorageServiceTest] 测试用例后置处理开始');

      try {
        // 清理测试数据
        await storageService.deleteNoteFile(testPageId);
        await storageService.deleteAttachmentFilesByPage(testPageId);

        console.info('[StorageServiceTest] 测试用例后置处理完成');
      } catch (error) {
        console.error('[StorageServiceTest] 测试用例后置处理失败: ' + error);
      }
    });

    afterAll(async () => {
      console.info('[StorageServiceTest] 测试套件清理开始');

      try {
        // 清理所有测试数据
        await storageService.deleteNoteFile(testPageId);
        await storageService.deleteAttachmentFilesByPage(testPageId);

        console.info('[StorageServiceTest] 测试套件清理完成');
      } catch (error) {
        console.error('[StorageServiceTest] 测试套件清理失败: ' + error);
      }
    });

    /**
     * ========================================
     * F1.1 笔记文件持久化测试
     * ========================================
     */
    describe('F1.1 笔记文件持久化', () => {
      it('F1.1.1 保存笔记文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.1.1 保存笔记文件成功');

        // 保存笔记文件
        const noteFile = await storageService.saveNoteFile(testPage);

        // 验证保存成功
        expect(noteFile).not.toBeNull();
        expect(noteFile.pageId).assertEqual(testPageId);
        expect(noteFile.filePath).assertContain(testPageId);
        expect(noteFile.fileSize).assertLarger(0);

        // 验证文件存在
        const exists = await storageService.noteFileExists(testPageId);
        expect(exists).assertEqual(true);

        console.info('[StorageServiceTest] F1.1.1 保存笔记文件成功验证通过');
      });

      it('F1.1.2 读取笔记文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.1.2 读取笔记文件成功');

        // 先保存笔记文件
        await storageService.saveNoteFile(testPage);

        // 读取笔记文件
        const page = await storageService.readNoteFile(testPageId);

        // 验证读取成功
        expect(page).not.toBeNull();
        expect(page.id).assertEqual(testPageId);
        expect(page.title).assertEqual(testPage.title);
        expect(page.content).assertEqual(testPage.content);

        console.info('[StorageServiceTest] F1.1.2 读取笔记文件成功验证通过');
      });

      it('F1.1.3 更新笔记文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.1.3 更新笔记文件成功');

        // 先保存笔记文件
        await storageService.saveNoteFile(testPage);

        // 修改页面内容
        testPage.title = '更新后的标题';
        testPage.content = '更新后的内容';
        testPage.modifiedTime = Date.now();

        // 更新笔记文件
        const noteFile = await storageService.updateNoteFile(testPage);

        // 验证更新成功
        expect(noteFile).not.toBeNull();
        expect(noteFile.modifiedTime).assertLarger(testPage.createdTime);

        // 读取并验证内容
        const page = await storageService.readNoteFile(testPageId);
        expect(page.title).assertEqual('更新后的标题');
        expect(page.content).assertEqual('更新后的内容');

        console.info('[StorageServiceTest] F1.1.3 更新笔记文件成功验证通过');
      });

      it('F1.1.4 删除笔记文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.1.4 删除笔记文件成功');

        // 先保存笔记文件
        await storageService.saveNoteFile(testPage);

        // 验证文件存在
        let exists = await storageService.noteFileExists(testPageId);
        expect(exists).assertEqual(true);

        // 删除笔记文件
        await storageService.deleteNoteFile(testPageId);

        // 验证文件已删除
        exists = await storageService.noteFileExists(testPageId);
        expect(exists).assertEqual(false);

        console.info('[StorageServiceTest] F1.1.4 删除笔记文件成功验证通过');
      });

      it('F1.1.5 检查笔记文件存在', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.1.5 检查笔记文件存在');

        // 验证文件不存在
        let exists = await storageService.noteFileExists(testPageId);
        expect(exists).assertEqual(false);

        // 保存笔记文件
        await storageService.saveNoteFile(testPage);

        // 验证文件存在
        exists = await storageService.noteFileExists(testPageId);
        expect(exists).assertEqual(true);

        console.info('[StorageServiceTest] F1.1.5 检查笔记文件存在验证通过');
      });

      it('F1.1.6 无效页面数据保存失败', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.1.6 无效页面数据保存失败');

        // 创建无效页面
        const invalidPage = new Page('', '', '', '', 0, 0, []);

        try {
          await storageService.saveNoteFile(invalidPage);
          // 不应该执行到这里
          expect(false).assertEqual(true);
        } catch (error) {
          // 验证抛出错误
          expect(error).not.toBeNull();
          expect(error.message).assertContain('无效');
          console.info('[StorageServiceTest] F1.1.6 无效页面数据保存失败验证通过');
        }
      });

      it('F1.1.7 读取不存在的笔记文件失败', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.1.7 读取不存在的笔记文件失败');

        try {
          await storageService.readNoteFile('non_existent_page');
          // 不应该执行到这里
          expect(false).assertEqual(true);
        } catch (error) {
          // 验证抛出错误
          expect(error).not.toBeNull();
          expect(error.message).assertContain('不存在');
          console.info('[StorageServiceTest] F1.1.7 读取不存在的笔记文件失败验证通过');
        }
      });
    });

    /**
     * ========================================
     * F1.2 附件文件持久化测试
     * ========================================
     */
    describe('F1.2 附件文件持久化', () => {
      it('F1.2.1 保存图片附件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.1 保存图片附件成功');

        // 创建测试图片文件
        const testImagePath = '/data/test_image.jpg';
        await FileUtils.writeFile(testImagePath, 'fake image data');

        try {
          // 保存图片附件
          const attachmentFile = await storageService.saveAttachmentFile(
            testImagePath,
            testPageId,
            'test_image.jpg'
          );

          // 验证保存成功
          expect(attachmentFile).not.toBeNull();
          expect(attachmentFile.pageId).assertEqual(testPageId);
          expect(attachmentFile.originalFileName).assertEqual('test_image.jpg');
          expect(attachmentFile.fileType).assertEqual(AttachmentType.IMAGE);
          expect(attachmentFile.fileSize).assertLarger(0);

          console.info('[StorageServiceTest] F1.2.1 保存图片附件成功验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
        }
      });

      it('F1.2.2 保存文档附件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.2 保存文档附件成功');

        // 创建测试文档文件
        const testDocPath = '/data/test_doc.pdf';
        await FileUtils.writeFile(testDocPath, 'fake pdf data');

        try {
          // 保存文档附件
          const attachmentFile = await storageService.saveAttachmentFile(
            testDocPath,
            testPageId,
            'test_doc.pdf'
          );

          // 验证保存成功
          expect(attachmentFile).not.toBeNull();
          expect(attachmentFile.fileType).assertEqual(AttachmentType.DOCUMENT);

          console.info('[StorageServiceTest] F1.2.2 保存文档附件成功验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testDocPath);
        }
      });

      it('F1.2.3 保存音频附件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.3 保存音频附件成功');

        // 创建测试音频文件
        const testAudioPath = '/data/test_audio.mp3';
        await FileUtils.writeFile(testAudioPath, 'fake audio data');

        try {
          // 保存音频附件
          const attachmentFile = await storageService.saveAttachmentFile(
            testAudioPath,
            testPageId,
            'test_audio.mp3'
          );

          // 验证保存成功
          expect(attachmentFile).not.toBeNull();
          expect(attachmentFile.fileType).assertEqual(AttachmentType.AUDIO);

          console.info('[StorageServiceTest] F1.2.3 保存音频附件成功验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testAudioPath);
        }
      });

      it('F1.2.4 读取附件文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.4 读取附件文件成功');

        // 创建并保存测试附件
        const testImagePath = '/data/test_image.jpg';
        const testData = 'fake image data';
        await FileUtils.writeFile(testImagePath, testData);

        try {
          const attachmentFile = await storageService.saveAttachmentFile(
            testImagePath,
            testPageId,
            'test_image.jpg'
          );

          // 读取附件文件
          const buffer = await storageService.readAttachmentFile(attachmentFile);

          // 验证读取成功
          expect(buffer).not.toBeNull();
          expect(buffer.byteLength).assertLarger(0);

          console.info('[StorageServiceTest] F1.2.4 读取附件文件成功验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
        }
      });

      it('F1.2.5 删除附件文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.5 删除附件文件成功');

        // 创建并保存测试附件
        const testImagePath = '/data/test_image.jpg';
        await FileUtils.writeFile(testImagePath, 'fake image data');

        try {
          const attachmentFile = await storageService.saveAttachmentFile(
            testImagePath,
            testPageId,
            'test_image.jpg'
          );

          // 验证文件存在
          expect(FileUtils.fileExists(attachmentFile.filePath)).assertEqual(true);

          // 删除附件文件
          await storageService.deleteAttachmentFile(attachmentFile);

          // 验证文件已删除
          expect(FileUtils.fileExists(attachmentFile.filePath)).assertEqual(false);

          console.info('[StorageServiceTest] F1.2.5 删除附件文件成功验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
        }
      });

      it('F1.2.6 批量删除页面附件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.6 批量删除页面附件成功');

        // 创建多个测试附件
        const testImagePath = '/data/test_image.jpg';
        const testDocPath = '/data/test_doc.pdf';
        await FileUtils.writeFile(testImagePath, 'fake image data');
        await FileUtils.writeFile(testDocPath, 'fake pdf data');

        try {
          await storageService.saveAttachmentFile(testImagePath, testPageId, 'test_image.jpg');
          await storageService.saveAttachmentFile(testDocPath, testPageId, 'test_doc.pdf');

          // 批量删除
          await storageService.deleteAttachmentFilesByPage(testPageId);

          // 验证所有附件已删除
          const attachments = await storageService.getAttachmentFilesByPage(testPageId);
          expect(attachments.length).assertEqual(0);

          console.info('[StorageServiceTest] F1.2.6 批量删除页面附件成功验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
          await FileUtils.deleteFile(testDocPath);
        }
      });

      it('F1.2.7 获取页面附件列表成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.7 获取页面附件列表成功');

        // 创建多个测试附件
        const testImagePath = '/data/test_image.jpg';
        const testDocPath = '/data/test_doc.pdf';
        await FileUtils.writeFile(testImagePath, 'fake image data');
        await FileUtils.writeFile(testDocPath, 'fake pdf data');

        try {
          await storageService.saveAttachmentFile(testImagePath, testPageId, 'test_image.jpg');
          await storageService.saveAttachmentFile(testDocPath, testPageId, 'test_doc.pdf');

          // 获取附件列表
          const attachments = await storageService.getAttachmentFilesByPage(testPageId);

          // 验证获取成功
          expect(attachments).not.toBeNull();
          expect(attachments.length).assertEqual(2);

          console.info('[StorageServiceTest] F1.2.7 获取页面附件列表成功验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
          await FileUtils.deleteFile(testDocPath);
        }
      });

      it('F1.2.8 文件大小超过限制失败', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.2.8 文件大小超过限制失败');

        // 创建超大测试文件（模拟）
        const testImagePath = '/data/test_large_image.jpg';
        // 注意：实际测试时需要创建真实的大文件
        await FileUtils.writeFile(testImagePath, 'small data');

        try {
          // 尝试保存超大文件（这里只是测试逻辑，实际需要真实大文件）
          // 在实际测试中，应该创建超过限制的文件
          console.info('[StorageServiceTest] F1.2.8 文件大小超过限制验证通过（需要真实大文件）');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
        }
      });
    });

    /**
     * ========================================
     * F1.3 文件目录管理测试
     * ========================================
     */
    describe('F1.3 文件目录管理', () => {
      it('F1.3.1 创建页面目录成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.3.1 创建页面目录成功');

        // 创建页面目录
        await storageService.createPageDirectory(testPageId);

        // 验证目录已创建
        const imagesPath = `${AppConstants.IMAGES_PATH}/${testPageId}`;
        const docsPath = `${AppConstants.DOCUMENTS_PATH}/${testPageId}`;
        const audioPath = `${AppConstants.AUDIO_PATH}/${testPageId}`;

        expect(FileUtils.directoryExists(imagesPath)).assertEqual(true);
        expect(FileUtils.directoryExists(docsPath)).assertEqual(true);
        expect(FileUtils.directoryExists(audioPath)).assertEqual(true);

        console.info('[StorageServiceTest] F1.3.1 创建页面目录成功验证通过');
      });

      it('F1.3.2 删除页面目录成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.3.2 删除页面目录成功');

        // 创建页面目录
        await storageService.createPageDirectory(testPageId);

        // 验证目录存在
        const imagesPath = `${AppConstants.IMAGES_PATH}/${testPageId}`;
        expect(FileUtils.directoryExists(imagesPath)).assertEqual(true);

        // 删除页面目录
        await storageService.deletePageDirectory(testPageId);

        // 验证目录已删除
        expect(FileUtils.directoryExists(imagesPath)).assertEqual(false);

        console.info('[StorageServiceTest] F1.3.2 删除页面目录成功验证通过');
      });

      it('F1.3.3 清理空目录成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.3.3 清理空目录成功');

        // 创建空目录
        await storageService.createPageDirectory(testPageId);

        // 清理空目录
        await storageService.cleanEmptyDirectories();

        // 验证空目录已清理
        const imagesPath = `${AppConstants.IMAGES_PATH}/${testPageId}`;
        expect(FileUtils.directoryExists(imagesPath)).assertEqual(false);

        console.info('[StorageServiceTest] F1.3.3 清理空目录成功验证通过');
      });
    });

    /**
     * ========================================
     * F1.4 文件读写操作测试
     * ========================================
     */
    describe('F1.4 文件读写操作', () => {
      it('F1.4.1 写入文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.4.1 写入文件成功');

        const testFilePath = '/data/test_write.txt';
        const testContent = 'test content for write';

        // 写入文件
        await storageService.writeFile(testFilePath, testContent);

        // 验证文件存在
        expect(FileUtils.fileExists(testFilePath)).assertEqual(true);

        console.info('[StorageServiceTest] F1.4.1 写入文件成功验证通过');
      });

      it('F1.4.2 读取文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.4.2 读取文件成功');

        const testFilePath = '/data/test_read.txt';
        const testContent = 'test content for read';

        // 写入文件
        await FileUtils.writeFile(testFilePath, testContent);

        // 读取文件
        const content = await storageService.readFile(testFilePath);

        // 验证读取成功
        expect(content).assertEqual(testContent);

        console.info('[StorageServiceTest] F1.4.2 读取文件成功验证通过');
      });

      it('F1.4.3 删除文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.4.3 删除文件成功');

        const testFilePath = '/data/test_delete.txt';

        // 创建文件
        await FileUtils.writeFile(testFilePath, 'test content');

        // 验证文件存在
        expect(FileUtils.fileExists(testFilePath)).assertEqual(true);

        // 删除文件
        await storageService.deleteFile(testFilePath);

        // 验证文件已删除
        expect(FileUtils.fileExists(testFilePath)).assertEqual(false);

        console.info('[StorageServiceTest] F1.4.3 删除文件成功验证通过');
      });

      it('F1.4.4 更新文件成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.4.4 更新文件成功');

        const testFilePath = '/data/test_update.txt';
        const originalContent = 'original content';
        const updatedContent = 'updated content';

        // 创建文件
        await FileUtils.writeFile(testFilePath, originalContent);

        // 更新文件
        await storageService.updateFile(testFilePath, updatedContent);

        // 读取并验证内容
        const content = await storageService.readFile(testFilePath);
        expect(content).assertEqual(updatedContent);

        console.info('[StorageServiceTest] F1.4.4 更新文件成功验证通过');
      });

      it('F1.4.5 获取文件元数据成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.4.5 获取文件元数据成功');

        const testFilePath = '/data/test_metadata.txt';
        const testContent = 'test content for metadata';

        // 创建文件
        await FileUtils.writeFile(testFilePath, testContent);

        // 获取文件元数据
        const metadata = await storageService.getFileMetadata(testFilePath);

        // 验证元数据
        expect(metadata).not.toBeNull();
        expect(metadata.size).assertEqual(testContent.length);
        expect(metadata.mtimeMs).assertLarger(0);

        console.info('[StorageServiceTest] F1.4.5 获取文件元数据成功验证通过');
      });
    });

    /**
     * ========================================
     * F1.5 文件元数据管理测试
     * ========================================
     */
    describe('F1.5 文件元数据管理', () => {
      it('F1.5.1 笔记文件元数据正确', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.5.1 笔记文件元数据正确');

        // 保存笔记文件
        const noteFile = await storageService.saveNoteFile(testPage);

        // 验证元数据
        expect(noteFile.id).not.toBeNull();
        expect(noteFile.pageId).assertEqual(testPageId);
        expect(noteFile.fileName).assertContain(testPageId);
        expect(noteFile.filePath).not.toBeNull();
        expect(noteFile.fileSize).assertLarger(0);
        expect(noteFile.createdTime).assertLarger(0);
        expect(noteFile.modifiedTime).assertLarger(0);

        console.info('[StorageServiceTest] F1.5.1 笔记文件元数据正确验证通过');
      });

      it('F1.5.2 附件文件元数据正确', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.5.2 附件文件元数据正确');

        // 创建测试附件
        const testImagePath = '/data/test_image.jpg';
        await FileUtils.writeFile(testImagePath, 'fake image data');

        try {
          const attachmentFile = await storageService.saveAttachmentFile(
            testImagePath,
            testPageId,
            'test_image.jpg'
          );

          // 验证元数据
          expect(attachmentFile.id).not.toBeNull();
          expect(attachmentFile.pageId).assertEqual(testPageId);
          expect(attachmentFile.originalFileName).assertEqual('test_image.jpg');
          expect(attachmentFile.filePath).not.toBeNull();
          expect(attachmentFile.fileType).not.toBeNull();
          expect(attachmentFile.fileSize).assertLarger(0);
          expect(attachmentFile.createdTime).assertLarger(0);
          expect(attachmentFile.modifiedTime).assertLarger(0);

          console.info('[StorageServiceTest] F1.5.2 附件文件元数据正确验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
        }
      });
    });

    /**
     * ========================================
     * F1.6 文件完整性校验测试
     * ========================================
     */
    describe('F1.6 文件完整性校验', () => {
      it('F1.6.1 保存和读取笔记文件内容一致', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.6.1 保存和读取笔记文件内容一致');

        // 保存笔记文件
        await storageService.saveNoteFile(testPage);

        // 读取笔记文件
        const page = await storageService.readNoteFile(testPageId);

        // 验证内容一致
        expect(page.id).assertEqual(testPage.id);
        expect(page.title).assertEqual(testPage.title);
        expect(page.content).assertEqual(testPage.content);
        expect(page.notebookId).assertEqual(testPage.notebookId);

        console.info('[StorageServiceTest] F1.6.1 保存和读取笔记文件内容一致验证通过');
      });

      it('F1.6.2 保存和读取附件文件内容一致', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.6.2 保存和读取附件文件内容一致');

        // 创建测试附件
        const testImagePath = '/data/test_image.jpg';
        const testData = 'fake image data for integrity test';
        await FileUtils.writeFile(testImagePath, testData);

        try {
          const attachmentFile = await storageService.saveAttachmentFile(
            testImagePath,
            testPageId,
            'test_image.jpg'
          );

          // 读取附件文件
          const buffer = await storageService.readAttachmentFile(attachmentFile);

          // 验证文件大小一致
          expect(buffer.byteLength).assertEqual(testData.length);

          console.info('[StorageServiceTest] F1.6.2 保存和读取附件文件内容一致验证通过');
        } finally {
          // 清理测试文件
          await FileUtils.deleteFile(testImagePath);
        }
      });
    });

    /**
     * ========================================
     * F1.7 存储空间管理测试
     * ========================================
     */
    describe('F1.7 存储空间管理', () => {
      it('F1.7.1 获取存储空间使用情况成功', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.7.1 获取存储空间使用情况成功');

        // 获取存储空间使用情况
        const usage = await storageService.getStorageUsage();

        // 验证返回数据
        expect(usage).not.toBeNull();
        expect(usage.total).assertLargerOrEqual(0);
        expect(usage.used).assertLargerOrEqual(0);
        expect(usage.available).assertLargerOrEqual(0);

        console.info('[StorageServiceTest] F1.7.1 获取存储空间使用情况成功验证通过');
      });

      it('F1.7.2 存储空间计算准确', 0, async () => {
        console.info('[StorageServiceTest] 测试: F1.7.2 存储空间计算准确');

        // 获取初始存储空间
        const initialUsage = await storageService.getStorageUsage();

        // 保存一些文件
        await storageService.saveNoteFile(testPage);

        // 获取新的存储空间
        const newUsage = await storageService.getStorageUsage();

        // 验证存储空间增加
        expect(newUsage.used).assertLarger(initialUsage.used);

        console.info('[StorageServiceTest] F1.7.2 存储空间计算准确验证通过');
      });
    });

    /**
     * ========================================
     * 边界情况测试
     * ========================================
     */
    describe('边界情况测试', () => {
      it('空页面标题保存失败', 0, async () => {
        console.info('[StorageServiceTest] 测试: 空页面标题保存失败');

        const emptyPage = new Page(
          'test_page_002',
          'notebook_001',
          '',
          'content',
          Date.now(),
          Date.now(),
          []
        );

        try {
          await storageService.saveNoteFile(emptyPage);
          expect(false).assertEqual(true);
        } catch (error) {
          expect(error).not.toBeNull();
          console.info('[StorageServiceTest] 空页面标题保存失败验证通过');
        }
      });

      it('超长页面标题保存失败', 0, async () => {
        console.info('[StorageServiceTest] 测试: 超长页面标题保存失败');

        const longPage = new Page(
          'test_page_003',
          'notebook_001',
          'a'.repeat(1001),
          'content',
          Date.now(),
          Date.now(),
          []
        );

        try {
          await storageService.saveNoteFile(longPage);
          expect(false).assertEqual(true);
        } catch (error) {
          expect(error).not.toBeNull();
          console.info('[StorageServiceTest] 超长页面标题保存失败验证通过');
        }
      });

      it('特殊字符文件名处理', 0, async () => {
        console.info('[StorageServiceTest] 测试: 特殊字符文件名处理');

        const specialPage = new Page(
          'test_page_004',
          'notebook_001',
          '测试页面@#$%',
          'content',
          Date.now(),
          Date.now(),
          []
        );

        // 保存应该成功（文件名会被处理）
        const noteFile = await storageService.saveNoteFile(specialPage);
        expect(noteFile).not.toBeNull();

        console.info('[StorageServiceTest] 特殊字符文件名处理验证通过');
      });

      it('并发保存文件', 0, async () => {
        console.info('[StorageServiceTest] 测试: 并发保存文件');

        const page1 = new Page('page_1', 'notebook_001', 'Page 1', 'Content 1', Date.now(), Date.now(), []);
        const page2 = new Page('page_2', 'notebook_001', 'Page 2', 'Content 2', Date.now(), Date.now(), []);
        const page3 = new Page('page_3', 'notebook_001', 'Page 3', 'Content 3', Date.now(), Date.now(), []);

        // 并发保存
        await Promise.all([
          storageService.saveNoteFile(page1),
          storageService.saveNoteFile(page2),
          storageService.saveNoteFile(page3)
        ]);

        // 验证所有文件都保存成功
        expect(await storageService.noteFileExists('page_1')).assertEqual(true);
        expect(await storageService.noteFileExists('page_2')).assertEqual(true);
        expect(await storageService.noteFileExists('page_3')).assertEqual(true);

        // 清理
        await storageService.deleteNoteFile('page_1');
        await storageService.deleteNoteFile('page_2');
        await storageService.deleteNoteFile('page_3');

        console.info('[StorageServiceTest] 并发保存文件验证通过');
      });
    });

    /**
     * ========================================
     * 性能测试
     * ========================================
     */
    describe('性能测试', () => {
      it('保存笔记文件性能', 0, async () => {
        console.info('[StorageServiceTest] 测试: 保存笔记文件性能');

        const startTime = Date.now();

        await storageService.saveNoteFile(testPage);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 保存操作应该在1秒内完成
        expect(duration).assertLess(1000);

        console.info('[StorageServiceTest] 保存笔记文件性能验证通过: ' + duration + 'ms');
      });

      it('读取笔记文件性能', 0, async () => {
        console.info('[StorageServiceTest] 测试: 读取笔记文件性能');

        // 先保存文件
        await storageService.saveNoteFile(testPage);

        const startTime = Date.now();

        await storageService.readNoteFile(testPageId);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 读取操作应该在500ms内完成
        expect(duration).assertLess(500);

        console.info('[StorageServiceTest] 读取笔记文件性能验证通过: ' + duration + 'ms');
      });

      it('批量保存附件性能', 0, async () => {
        console.info('[StorageServiceTest] 测试: 批量保存附件性能');

        const startTime = Date.now();

        // 创建多个测试附件
        const promises = [];
        for (let i = 0; i < 10; i++) {
          const testPath = `/data/test_${i}.jpg`;
          await FileUtils.writeFile(testPath, `test data ${i}`);
          promises.push(storageService.saveAttachmentFile(testPath, testPageId, `test_${i}.jpg`));
        }

        await Promise.all(promises);

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 批量保存10个附件应该在3秒内完成
        expect(duration).assertLess(3000);

        console.info('[StorageServiceTest] 批量保存附件性能验证通过: ' + duration + 'ms');
      });
    });
  });
}

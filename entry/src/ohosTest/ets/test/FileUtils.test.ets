/**
 * 文件工具类测试套件
 * 测试文件工具功能
 *
 * @author 测试工程师
 * @date 2026-03-12
 */
import { describe, it, expect } from '@ohos/hypium';
import { FileUtils } from '../../main/ets/utils/FileUtils';

export default function FileUtilsTest() {
  describe('文件工具类功能测试', () => {
    /**
     * ========================================
     * 文件名处理测试
     * ========================================
     */
    describe('文件名处理', () => {
      it('获取文件扩展名成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 获取文件扩展名成功');

        expect(FileUtils.getFileExtension('test.txt')).assertEqual('txt');
        expect(FileUtils.getFileExtension('document.pdf')).assertEqual('pdf');
        expect(FileUtils.getFileExtension('image.jpg')).assertEqual('jpg');
        expect(FileUtils.getFileExtension('archive.tar.gz')).assertEqual('gz');
        expect(FileUtils.getFileExtension('noextension')).assertEqual('');

        console.info('[FileUtilsTest] 获取文件扩展名成功验证通过');
      });

      it('获取文件名（不含扩展名）成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 获取文件名（不含扩展名）成功');

        expect(FileUtils.getFileNameWithoutExtension('test.txt')).assertEqual('test');
        expect(FileUtils.getFileNameWithoutExtension('document.pdf')).assertEqual('document');
        expect(FileUtils.getFileNameWithoutExtension('image.jpg')).assertEqual('image');
        expect(FileUtils.getFileNameWithoutExtension('noextension')).assertEqual('noextension');

        console.info('[FileUtilsTest] 获取文件名（不含扩展名）成功验证通过');
      });

      it('判断是否是图片文件成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 判断是否是图片文件成功');

        expect(FileUtils.isImageFile('test.jpg')).assertEqual(true);
        expect(FileUtils.isImageFile('test.jpeg')).assertEqual(true);
        expect(FileUtils.isImageFile('test.png')).assertEqual(true);
        expect(FileUtils.isImageFile('test.gif')).assertEqual(true);
        expect(FileUtils.isImageFile('test.bmp')).assertEqual(true);
        expect(FileUtils.isImageFile('test.webp')).assertEqual(true);
        expect(FileUtils.isImageFile('test.txt')).assertEqual(false);
        expect(FileUtils.isImageFile('test.pdf')).assertEqual(false);

        console.info('[FileUtilsTest] 判断是否是图片文件成功验证通过');
      });

      it('判断是否是文档文件成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 判断是否是文档文件成功');

        expect(FileUtils.isDocumentFile('test.pdf')).assertEqual(true);
        expect(FileUtils.isDocumentFile('test.doc')).assertEqual(true);
        expect(FileUtils.isDocumentFile('test.docx')).assertEqual(true);
        expect(FileUtils.isDocumentFile('test.txt')).assertEqual(true);
        expect(FileUtils.isDocumentFile('test.md')).assertEqual(true);
        expect(FileUtils.isDocumentFile('test.jpg')).assertEqual(false);
        expect(FileUtils.isDocumentFile('test.mp3')).assertEqual(false);

        console.info('[FileUtilsTest] 判断是否是文档文件成功验证通过');
      });

      it('判断是否是音频文件成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 判断是否是音频文件成功');

        expect(FileUtils.isAudioFile('test.mp3')).assertEqual(true);
        expect(FileUtils.isAudioFile('test.wav')).assertEqual(true);
        expect(FileUtils.isAudioFile('test.aac')).assertEqual(true);
        expect(FileUtils.isAudioFile('test.ogg')).assertEqual(true);
        expect(FileUtils.isAudioFile('test.flac')).assertEqual(true);
        expect(FileUtils.isAudioFile('test.m4a')).assertEqual(true);
        expect(FileUtils.isAudioFile('test.jpg')).assertEqual(false);
        expect(FileUtils.isAudioFile('test.txt')).assertEqual(false);

        console.info('[FileUtilsTest] 判断是否是音频文件成功验证通过');
      });

      it('判断是否是视频文件成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 判断是否是视频文件成功');

        expect(FileUtils.isVideoFile('test.mp4')).assertEqual(true);
        expect(FileUtils.isVideoFile('test.avi')).assertEqual(true);
        expect(FileUtils.isVideoFile('test.mov')).assertEqual(true);
        expect(FileUtils.isVideoFile('test.wmv')).assertEqual(true);
        expect(FileUtils.isVideoFile('test.flv')).assertEqual(true);
        expect(FileUtils.isVideoFile('test.mkv')).assertEqual(true);
        expect(FileUtils.isVideoFile('test.webm')).assertEqual(true);
        expect(FileUtils.isVideoFile('test.jpg')).assertEqual(false);
        expect(FileUtils.isVideoFile('test.txt')).assertEqual(false);

        console.info('[FileUtilsTest] 判断是否是视频文件成功验证通过');
      });
    });

    /**
     * ========================================
     * 文件大小格式化测试
     * ========================================
     */
    describe('文件大小格式化', () => {
      it('格式化文件大小成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 格式化文件大小成功');

        expect(FileUtils.formatFileSize(0)).assertEqual('0 B');
        expect(FileUtils.formatFileSize(512)).assertEqual('512 B');
        expect(FileUtils.formatFileSize(1024)).assertEqual('1.00 KB');
        expect(FileUtils.formatFileSize(1536)).assertEqual('1.50 KB');
        expect(FileUtils.formatFileSize(1024 * 1024)).assertEqual('1.00 MB');
        expect(FileUtils.formatFileSize(1024 * 1024 * 1.5)).assertEqual('1.50 MB');
        expect(FileUtils.formatFileSize(1024 * 1024 * 1024)).assertEqual('1.00 GB');
        expect(FileUtils.formatFileSize(1024 * 1024 * 1024 * 1.5)).assertEqual('1.50 GB');

        console.info('[FileUtilsTest] 格式化文件大小成功验证通过');
      });
    });

    /**
     * ========================================
     * 文件名生成测试
     * ========================================
     */
    describe('文件名生成', () => {
      it('生成唯一文件名成功', 0, () => {
        console.info('[FileUtilsTest] 测试: 生成唯一文件名成功');

        const filename1 = FileUtils.generateUniqueFilename('test.txt');
        const filename2 = FileUtils.generateUniqueFilename('test.txt');

        // 验证文件名包含原始文件名
        expect(filename1).assertContain('test');
        expect(filename2).assertContain('test');

        // 验证文件名包含扩展名
        expect(filename1).assertContain('.txt');
        expect(filename2).assertContain('.txt');

        // 验证生成的文件名是唯一的
        expect(filename1).not.toEqual(filename2);

        console.info('[FileUtilsTest] 生成唯一文件名成功验证通过');
      });
    });

    /**
     * ========================================
     * 边界情况测试
     * ========================================
     */
    describe('边界情况测试', () => {
      it('空文件名处理', 0, () => {
        console.info('[FileUtilsTest] 测试: 空文件名处理');

        expect(FileUtils.getFileExtension('')).assertEqual('');
        expect(FileUtils.getFileNameWithoutExtension('')).assertEqual('');

        console.info('[FileUtilsTest] 空文件名处理验证通过');
      });

      it('无扩展名文件名处理', 0, () => {
        console.info('[FileUtilsTest] 测试: 无扩展名文件名处理');

        expect(FileUtils.getFileExtension('filename')).assertEqual('');
        expect(FileUtils.getFileNameWithoutExtension('filename')).assertEqual('filename');

        console.info('[FileUtilsTest] 无扩展名文件名处理验证通过');
      });

      it('多个点文件名处理', 0, () => {
        console.info('[FileUtilsTest] 测试: 多个点文件名处理');

        expect(FileUtils.getFileExtension('archive.tar.gz')).assertEqual('gz');
        expect(FileUtils.getFileNameWithoutExtension('archive.tar.gz')).assertEqual('archive.tar');

        console.info('[FileUtilsTest] 多个点文件名处理验证通过');
      });

      it('特殊字符文件名处理', 0, () => {
        console.info('[FileUtilsTest] 测试: 特殊字符文件名处理');

        expect(FileUtils.getFileExtension('测试文件.txt')).assertEqual('txt');
        expect(FileUtils.getFileNameWithoutExtension('测试文件.txt')).assertEqual('测试文件');

        console.info('[FileUtilsTest] 特殊字符文件名处理验证通过');
      });

      it('大文件大小格式化', 0, () => {
        console.info('[FileUtilsTest] 测试: 大文件大小格式化');

        // 测试非常大的文件大小
        const hugeSize = 1024 * 1024 * 1024 * 1024; // 1 TB
        const formatted = FileUtils.formatFileSize(hugeSize);

        // 验证格式化结果
        expect(formatted).not.toBeNull();
        expect(formatted).assertContain('TB');

        console.info('[FileUtilsTest] 大文件大小格式化验证通过');
      });

      it('负数文件大小格式化', 0, () => {
        console.info('[FileUtilsTest] 测试: 负数文件大小格式化');

        // 负数应该返回0 B
        expect(FileUtils.formatFileSize(-1)).assertEqual('0 B');
        expect(FileUtils.formatFileSize(-1024)).assertEqual('0 B');

        console.info('[FileUtilsTest] 负数文件大小格式化验证通过');
      });
    });

    /**
     * ========================================
     * 性能测试
     * ========================================
     */
    describe('性能测试', () => {
      it('获取文件扩展名性能', 0, () => {
        console.info('[FileUtilsTest] 测试: 获取文件扩展名性能');

        const startTime = Date.now();

        // 执行1000次
        for (let i = 0; i < 1000; i++) {
          FileUtils.getFileExtension('test.txt');
        }

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 1000次操作应该在10ms内完成
        expect(duration).assertLess(10);

        console.info('[FileUtilsTest] 获取文件扩展名性能验证通过: ' + duration + 'ms');
      });

      it('格式化文件大小性能', 0, () => {
        console.info('[FileUtilsTest] 测试: 格式化文件大小性能');

        const startTime = Date.now();

        // 执行1000次
        for (let i = 0; i < 1000; i++) {
          FileUtils.formatFileSize(1024 * 1024);
        }

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 1000次操作应该在20ms内完成
        expect(duration).assertLess(20);

        console.info('[FileUtilsTest] 格式化文件大小性能验证通过: ' + duration + 'ms');
      });

      it('生成唯一文件名性能', 0, () => {
        console.info('[FileUtilsTest] 测试: 生成唯一文件名性能');

        const startTime = Date.now();

        // 执行100次
        const filenames = [];
        for (let i = 0; i < 100; i++) {
          filenames.push(FileUtils.generateUniqueFilename('test.txt'));
        }

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 100次操作应该在50ms内完成
        expect(duration).assertLess(50);

        // 验证所有文件名都是唯一的
        const uniqueFilenames = new Set(filenames);
        expect(uniqueFilenames.size).assertEqual(100);

        console.info('[FileUtilsTest] 生成唯一文件名性能验证通过: ' + duration + 'ms');
      });
    });
  });
}

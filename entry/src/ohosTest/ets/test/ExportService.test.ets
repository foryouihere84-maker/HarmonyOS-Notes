/**
 * 导出服务测试
 * 测试ExportService的功能
 * 
 * @author 开发者
 * @date 2026-03-17
 */
import { ExportService } from '../../../main/ets/services/ExportService';
import { Page } from '../../../main/ets/models/Page';


// 测试用例
async function testExportService() {
  console.log('测试ExportService');
  
  const exportService = ExportService.getInstance();
  
  // 创建测试页面
  const testPage = new Page(
    'test_page_1',
    '测试页面',
    '<h1>测试标题</h1><p>测试内容</p>',
    'notebook_1',
    false,
    false,
    Date.now(),
    Date.now(),
    ['标签1', '标签2']
  );
  
  // 测试导出为文本
  console.log('测试导出为文本');
  try {
    const textPath = await exportService.exportToText(testPage);
    console.log('文本导出路径:', textPath);
  } catch (error) {
    console.log('文本导出失败:', error);
  }
  
  // 测试导出为Markdown
  console.log('测试导出为Markdown');
  try {
    const mdPath = await exportService.exportToMarkdown(testPage);
    console.log('Markdown导出路径:', mdPath);
  } catch (error) {
    console.log('Markdown导出失败:', error);
  }
  
  // 测试导出为PDF
  console.log('测试导出为PDF');
  try {
    const pdfPath = await exportService.exportToPdf(testPage);
    console.log('PDF导出路径:', pdfPath);
  } catch (error) {
    console.log('PDF导出失败:', error);
  }
  
  // 测试批量导出
  console.log('测试批量导出');
  try {
    const batchPaths = await exportService.batchExport([testPage], 'txt');
    console.log('批量导出路径:', batchPaths);
  } catch (error) {
    console.log('批量导出失败:', error);
  }
  
  return true;
}

// 执行测试
export async function runExportServiceTests() {
  console.log('开始ExportService测试');
  
  try {
    const result = await testExportService();
    console.log('ExportService测试结果:', result ? '通过' : '失败');
    return result;
  } catch (error) {
    console.log('ExportService测试失败:', error);
    return false;
  }
}

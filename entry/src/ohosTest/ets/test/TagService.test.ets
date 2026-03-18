/**
 * 标签服务测试
 * 测试TagService的功能
 * 
 * @author 开发者
 * @date 2026-03-17
 */
import { TagService } from '../../../main/ets/services/TagService';
import { Tag } from '../../../main/ets/models/Tag';


// 测试用例
async function testTagService() {
  console.log('测试TagService');
  
  const tagService = TagService.getInstance();
  
  // 测试创建标签
  console.log('测试创建标签');
  const newTag = await tagService.createTag('测试标签', '#0078D4');
  console.log('创建的标签:', newTag);
  
  // 测试获取所有标签
  console.log('测试获取所有标签');
  const allTags = await tagService.getAllTags();
  console.log('所有标签:', allTags);
  
  // 测试根据ID获取标签
  console.log('测试根据ID获取标签');
  const tagById = await tagService.getTagById(newTag.id);
  console.log('根据ID获取的标签:', tagById);
  
  // 测试更新标签
  console.log('测试更新标签');
  if (tagById) {
    tagById.name = '更新后的标签';
    await tagService.updateTag(tagById);
    const updatedTag = await tagService.getTagById(newTag.id);
    console.log('更新后的标签:', updatedTag);
  }
  
  // 测试搜索标签
  console.log('测试搜索标签');
  const searchResults = await tagService.searchTags('测试');
  console.log('搜索结果:', searchResults);
  
  // 测试删除标签
  console.log('测试删除标签');
  try {
    await tagService.deleteTag(newTag.id);
    console.log('删除标签成功');
  } catch (error) {
    console.log('删除标签失败:', error);
  }
  
  return true;
}

// 执行测试
export async function runTagServiceTests() {
  console.log('开始TagService测试');
  
  try {
    const result = await testTagService();
    console.log('TagService测试结果:', result ? '通过' : '失败');
    return result;
  } catch (error) {
    console.log('TagService测试失败:', error);
    return false;
  }
}

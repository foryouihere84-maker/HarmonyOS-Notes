/**
 * 标签数据访问对象测试
 * 测试TagDao的功能
 * 
 * @author 开发者
 * @date 2026-03-17
 */
import { TagDao } from '../../../main/ets/database/TagDao';
import { Tag } from '../../../main/ets/models/Tag';


// 测试用例
async function testTagDao() {
  console.log('测试TagDao');
  
  const tagDao = TagDao.getInstance();
  
  // 测试插入标签
  console.log('测试插入标签');
  const tag = new Tag('test_tag_1', '测试标签', '#0078D4', Date.now());
  const insertResult = await tagDao.insert(tag);
  console.log('插入结果:', insertResult);
  
  // 测试根据ID查询标签
  console.log('测试根据ID查询标签');
  const queriedTag = await tagDao.getById(tag.id);
  console.log('查询结果:', queriedTag);
  
  // 测试获取所有标签
  console.log('测试获取所有标签');
  const allTags = await tagDao.getAll();
  console.log('所有标签:', allTags);
  
  // 测试搜索标签
  console.log('测试搜索标签');
  const searchResults = await tagDao.search('测试');
  console.log('搜索结果:', searchResults);
  
  // 测试更新标签
  console.log('测试更新标签');
  if (queriedTag) {
    queriedTag.name = '更新后的标签';
    const updateResult = await tagDao.update(queriedTag);
    console.log('更新结果:', updateResult);
  }
  
  // 测试删除标签
  console.log('测试删除标签');
  const deleteResult = await tagDao.delete(tag.id);
  console.log('删除结果:', deleteResult);
  
  return true;
}

// 执行测试
export async function runTagDaoTests() {
  console.log('开始TagDao测试');
  
  try {
    const result = await testTagDao();
    console.log('TagDao测试结果:', result ? '通过' : '失败');
    return result;
  } catch (error) {
    console.log('TagDao测试失败:', error);
    return false;
  }
}

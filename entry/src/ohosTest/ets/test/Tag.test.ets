/**
 * 标签模型测试
 * 测试Tag模型的功能
 * 
 * @author 开发者
 * @date 2026-03-17
 */
import { Tag } from '../../../main/ets/models/Tag';


// 测试用例
function testTagCreation() {
  console.log('测试Tag模型创建');
  
  // 测试默认构造函数
  const tag1 = new Tag();
  console.log('默认构造函数:', tag1);
  
  // 测试带参数构造函数
  const tag2 = new Tag('tag_1', '测试标签', '#0078D4', Date.now());
  console.log('带参数构造函数:', tag2);
  
  // 测试验证方法
  const valid = tag2.validate();
  console.log('验证结果:', valid);
  
  // 测试toJSON方法
  const json = tag2.toJSON();
  console.log('toJSON结果:', json);
  
  // 测试fromJSON方法
  const tag3 = Tag.fromJSON(json);
  console.log('fromJSON结果:', tag3);
  
  return true;
}

function testTagValidation() {
  console.log('测试Tag模型验证');
  
  // 测试有效标签
  const validTag = new Tag('tag_1', '有效标签', '#0078D4');
  const validResult = validTag.validate();
  console.log('有效标签验证结果:', validResult);
  
  // 测试无效标签（空名称）
  const invalidTag1 = new Tag('tag_2', '', '#0078D4');
  const invalidResult1 = invalidTag1.validate();
  console.log('空名称验证结果:', invalidResult1);
  
  // 测试无效标签（过长名称）
  const longName = 'a'.repeat(51);
  const invalidTag2 = new Tag('tag_3', longName, '#0078D4');
  const invalidResult2 = invalidTag2.validate();
  console.log('过长名称验证结果:', invalidResult2);
  
  return validResult && !invalidResult1 && !invalidResult2;
}

// 执行测试
export function runTagTests() {
  console.log('开始Tag模型测试');
  
  const test1 = testTagCreation();
  const test2 = testTagValidation();
  
  console.log('Tag模型测试结果:');
  console.log('创建测试:', test1 ? '通过' : '失败');
  console.log('验证测试:', test2 ? '通过' : '失败');
  
  return test1 && test2;
}

/**
 * 加密工具类测试套件
 * 测试加密解密功能（F3.2）
 *
 * 测试范围：
 * - F3.2 配置加密
 *
 * @author 测试工程师
 * @date 2026-03-12
 */
import { describe, it, expect } from '@ohos/hypium';
import { CryptoUtils } from '../../main/ets/utils/CryptoUtils';

export default function CryptoUtilsTest() {
  describe('加密工具类功能测试', () => {
    let testKey: string = '';
    let testIV: string = '';

    /**
     * ========================================
     * 密钥生成测试
     * ========================================
     */
    describe('密钥生成', () => {
      it('生成随机密钥成功', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 生成随机密钥成功');

        // 生成密钥
        const key = await CryptoUtils.generateKey();

        // 验证密钥不为空
        expect(key).not.toBeNull();
        expect(key.length).assertLarger(0);

        // 验证密钥是Base64格式
        const base64Pattern = /^[A-Za-z0-9+/]+=*$/;
        expect(base64Pattern.test(key)).assertEqual(true);

        console.info('[CryptoUtilsTest] 生成随机密钥成功验证通过');
      });

      it('生成的密钥是唯一的', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 生成的密钥是唯一的');

        // 生成多个密钥
        const key1 = await CryptoUtils.generateKey();
        const key2 = await CryptoUtils.generateKey();
        const key3 = await CryptoUtils.generateKey();

        // 验证密钥是唯一的
        expect(key1).not.toEqual(key2);
        expect(key2).not.toEqual(key3);
        expect(key1).not.toEqual(key3);

        console.info('[CryptoUtilsTest] 生成的密钥是唯一的验证通过');
      });
    });

    /**
     * ========================================
     * IV生成测试
     * ========================================
     */
    describe('IV生成', () => {
      it('生成随机IV成功', 0, () => {
        console.info('[CryptoUtilsTest] 测试: 生成随机IV成功');

        // 生成IV
        const iv = CryptoUtils.generateIV();

        // 验证IV不为空
        expect(iv).not.toBeNull();
        expect(iv.length).assertLarger(0);

        // 验证IV是Base64格式
        const base64Pattern = /^[A-Za-z0-9+/]+=*$/;
        expect(base64Pattern.test(iv)).assertEqual(true);

        console.info('[CryptoUtilsTest] 生成随机IV成功验证通过');
      });

      it('生成的IV是唯一的', 0, () => {
        console.info('[CryptoUtilsTest] 测试: 生成的IV是唯一的');

        // 生成多个IV
        const iv1 = CryptoUtils.generateIV();
        const iv2 = CryptoUtils.generateIV();
        const iv3 = CryptoUtils.generateIV();

        // 验证IV是唯一的
        expect(iv1).not.toEqual(iv2);
        expect(iv2).not.toEqual(iv3);
        expect(iv1).not.toEqual(iv3);

        console.info('[CryptoUtilsTest] 生成的IV是唯一的验证通过');
      });
    });

    /**
     * ========================================
     * F3.2 配置加密测试
     * ========================================
     */
    describe('F3.2 配置加密', () => {
      it('F3.2.1 加密数据成功', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: F3.2.1 加密数据成功');

        // 生成密钥
        const key = await CryptoUtils.generateKey();

        // 加密数据
        const plaintext = 'test data for encryption';
        const ciphertext = await CryptoUtils.encrypt(plaintext, key);

        // 验证密文不为空
        expect(ciphertext).not.toBeNull();
        expect(ciphertext.length).assertLarger(0);

        // 验证密文格式（IV:密文）
        expect(ciphertext).assertContain(':');

        console.info('[CryptoUtilsTest] F3.2.1 加密数据成功验证通过');
      });

      it('F3.2.2 解密数据成功', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: F3.2.2 解密数据成功');

        // 生成密钥
        const key = await CryptoUtils.generateKey();

        // 加密数据
        const plaintext = 'test data for encryption';
        const ciphertext = await CryptoUtils.encrypt(plaintext, key);

        // 解密数据
        const decrypted = await CryptoUtils.decrypt(ciphertext, key);

        // 验证解密结果与原文一致
        expect(decrypted).assertEqual(plaintext);

        console.info('[CryptoUtilsTest] F3.2.2 解密数据成功验证通过');
      });

      it('F3.2.3 加密解密数据一致性', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: F3.2.3 加密解密数据一致性');

        // 生成密钥
        const key = await CryptoUtils.generateKey();

        // 测试多种数据
        const testCases = [
          'simple text',
          '中文测试数据',
          'Special characters: !@#$%^&*()',
          'Numbers: 1234567890',
          'Long text: ' + 'a'.repeat(1000),
          'JSON: {"key":"value","number":123}'
        ];

        for (const plaintext of testCases) {
          // 加密
          const ciphertext = await CryptoUtils.encrypt(plaintext, key);

          // 解密
          const decrypted = await CryptoUtils.decrypt(ciphertext, key);

          // 验证一致性
          expect(decrypted).assertEqual(plaintext);
        }

        console.info('[CryptoUtilsTest] F3.2.3 加密解密数据一致性验证通过');
      });

      it('F3.2.4 使用自定义IV加密', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: F3.2.4 使用自定义IV加密');

        // 生成密钥和IV
        const key = await CryptoUtils.generateKey();
        const iv = CryptoUtils.generateIV();

        // 使用自定义IV加密
        const plaintext = 'test data for encryption';
        const ciphertext = await CryptoUtils.encrypt(plaintext, key, iv);

        // 验证密文包含自定义IV
        expect(ciphertext).assertContain(iv);

        // 解密
        const decrypted = await CryptoUtils.decrypt(ciphertext, key);

        // 验证解密结果
        expect(decrypted).assertEqual(plaintext);

        console.info('[CryptoUtilsTest] F3.2.4 使用自定义IV加密验证通过');
      });

      it('F3.2.5 加密敏感配置数据', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: F3.2.5 加密敏感配置数据');

        // 生成密钥
        const key = await CryptoUtils.generateKey();

        // 加密各种敏感数据
        const sensitiveData = {
          accessToken: 'access_token_123456789',
          refreshToken: 'refresh_token_987654321',
          clientSecret: 'client_secret_abcdef',
          password: 'user_password_123',
          apiKey: 'api_key_xyz789'
        };

        // 加密所有数据
        for (const [keyName, value] of Object.entries(sensitiveData)) {
          const ciphertext = await CryptoUtils.encrypt(value, key);
          const decrypted = await CryptoUtils.decrypt(ciphertext, key);

          // 验证加密解密成功
          expect(decrypted).assertEqual(value);
        }

        console.info('[CryptoUtilsTest] F3.2.5 加密敏感配置数据验证通过');
      });
    });

    /**
     * ========================================
     * 哈希计算测试
     * ========================================
     */
    describe('哈希计算', () => {
      it('计算SHA-256哈希成功', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 计算SHA-256哈希成功');

        // 计算哈希
        const data = 'test data for hashing';
        const hash = await CryptoUtils.sha256(data);

        // 验证哈希不为空
        expect(hash).not.toBeNull();
        expect(hash.length).assertLarger(0);

        // 验证哈希是Base64格式
        const base64Pattern = /^[A-Za-z0-9+/]+=*$/;
        expect(base64Pattern.test(hash)).assertEqual(true);

        console.info('[CryptoUtilsTest] 计算SHA-256哈希成功验证通过');
      });

      it('相同数据产生相同哈希', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 相同数据产生相同哈希');

        const data = 'test data for hashing';

        // 计算多次哈希
        const hash1 = await CryptoUtils.sha256(data);
        const hash2 = await CryptoUtils.sha256(data);
        const hash3 = await CryptoUtils.sha256(data);

        // 验证哈希相同
        expect(hash1).assertEqual(hash2);
        expect(hash2).assertEqual(hash3);

        console.info('[CryptoUtilsTest] 相同数据产生相同哈希验证通过');
      });

      it('不同数据产生不同哈希', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 不同数据产生不同哈希');

        // 计算不同数据的哈希
        const hash1 = await CryptoUtils.sha256('data1');
        const hash2 = await CryptoUtils.sha256('data2');
        const hash3 = await CryptoUtils.sha256('data3');

        // 验证哈希不同
        expect(hash1).not.toEqual(hash2);
        expect(hash2).not.toEqual(hash3);
        expect(hash1).not.toEqual(hash3);

        console.info('[CryptoUtilsTest] 不同数据产生不同哈希验证通过');
      });
    });

    /**
     * ========================================
     * Base64编解码测试
     * ========================================
     */
    describe('Base64编解码', () => {
      it('Base64编码成功', 0, () => {
        console.info('[CryptoUtilsTest] 测试: Base64编码成功');

        const data = 'test data for base64 encoding';
        const encoded = CryptoUtils.base64Encode(data);

        // 验证编码结果
        expect(encoded).not.toBeNull();
        expect(encoded.length).assertLarger(0);

        // 验证Base64格式
        const base64Pattern = /^[A-Za-z0-9+/]+=*$/;
        expect(base64Pattern.test(encoded)).assertEqual(true);

        console.info('[CryptoUtilsTest] Base64编码成功验证通过');
      });

      it('Base64解码成功', 0, () => {
        console.info('[CryptoUtilsTest] 测试: Base64解码成功');

        const data = 'test data for base64 encoding';
        const encoded = CryptoUtils.base64Encode(data);
        const decoded = CryptoUtils.base64Decode(encoded);

        // 验证解码结果与原文一致
        expect(decoded).assertEqual(data);

        console.info('[CryptoUtilsTest] Base64解码成功验证通过');
      });

      it('Base64编解码一致性', 0, () => {
        console.info('[CryptoUtilsTest] 测试: Base64编解码一致性');

        const testCases = [
          'simple text',
          '中文测试',
          'Special characters: !@#$%',
          'Numbers: 12345',
          'Long text: ' + 'a'.repeat(1000)
        ];

        for (const data of testCases) {
          const encoded = CryptoUtils.base64Encode(data);
          const decoded = CryptoUtils.base64Decode(encoded);

          // 验证一致性
          expect(decoded).assertEqual(data);
        }

        console.info('[CryptoUtilsTest] Base64编解码一致性验证通过');
      });
    });

    /**
     * ========================================
     * 随机字符串生成测试
     * ========================================
     */
    describe('随机字符串生成', () => {
      it('生成随机字符串成功', 0, () => {
        console.info('[CryptoUtilsTest] 测试: 生成随机字符串成功');

        const length = 16;
        const randomString = CryptoUtils.generateRandomString(length);

        // 验证字符串长度
        expect(randomString.length).assertEqual(length);

        // 验证只包含字母和数字
        const pattern = /^[A-Za-z0-9]+$/;
        expect(pattern.test(randomString)).assertEqual(true);

        console.info('[CryptoUtilsTest] 生成随机字符串成功验证通过');
      });

      it('生成的随机字符串是唯一的', 0, () => {
        console.info('[CryptoUtilsTest] 测试: 生成的随机字符串是唯一的');

        const length = 16;
        const str1 = CryptoUtils.generateRandomString(length);
        const str2 = CryptoUtils.generateRandomString(length);
        const str3 = CryptoUtils.generateRandomString(length);

        // 验证字符串是唯一的
        expect(str1).not.toEqual(str2);
        expect(str2).not.toEqual(str3);
        expect(str1).not.toEqual(str3);

        console.info('[CryptoUtilsTest] 生成的随机字符串是唯一的验证通过');
      });

      it('生成不同长度的随机字符串', 0, () => {
        console.info('[CryptoUtilsTest] 测试: 生成不同长度的随机字符串');

        const lengths = [8, 16, 32, 64];

        for (const length of lengths) {
          const randomString = CryptoUtils.generateRandomString(length);

          // 验证字符串长度
          expect(randomString.length).assertEqual(length);
        }

        console.info('[CryptoUtilsTest] 生成不同长度的随机字符串验证通过');
      });
    });

    /**
     * ========================================
     * 边界情况测试
     * ========================================
     */
    describe('边界情况测试', () => {
      it('空字符串加密解密', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 空字符串加密解密');

        const key = await CryptoUtils.generateKey();

        // 加密空字符串
        const ciphertext = await CryptoUtils.encrypt('', key);
        const decrypted = await CryptoUtils.decrypt(ciphertext, key);

        // 验证解密结果
        expect(decrypted).assertEqual('');

        console.info('[CryptoUtilsTest] 空字符串加密解密验证通过');
      });

      it('超长字符串加密解密', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 超长字符串加密解密');

        const key = await CryptoUtils.generateKey();
        const longText = 'a'.repeat(10000);

        // 加密超长字符串
        const ciphertext = await CryptoUtils.encrypt(longText, key);
        const decrypted = await CryptoUtils.decrypt(ciphertext, key);

        // 验证解密结果
        expect(decrypted).assertEqual(longText);

        console.info('[CryptoUtilsTest] 超长字符串加密解密验证通过');
      });

      it('特殊字符加密解密', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 特殊字符加密解密');

        const key = await CryptoUtils.generateKey();
        const specialChars = '!@#$%^&*()_+-=[]{}|;:,.<>?/~`"\'\n\t\r';

        // 加密特殊字符
        const ciphertext = await CryptoUtils.encrypt(specialChars, key);
        const decrypted = await CryptoUtils.decrypt(ciphertext, key);

        // 验证解密结果
        expect(decrypted).assertEqual(specialChars);

        console.info('[CryptoUtilsTest] 特殊字符加密解密验证通过');
      });

      it('无效密文格式解密失败', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 无效密文格式解密失败');

        const key = await CryptoUtils.generateKey();
        const invalidCiphertext = 'invalid_ciphertext';

        try {
          await CryptoUtils.decrypt(invalidCiphertext, key);
          // 不应该执行到这里
          expect(false).assertEqual(true);
        } catch (error) {
          // 验证抛出错误
          expect(error).not.toBeNull();
          expect(error.message).assertContain('格式错误');
          console.info('[CryptoUtilsTest] 无效密文格式解密失败验证通过');
        }
      });

      it('错误密钥解密失败', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 错误密钥解密失败');

        const key1 = await CryptoUtils.generateKey();
        const key2 = await CryptoUtils.generateKey();

        const plaintext = 'test data';
        const ciphertext = await CryptoUtils.encrypt(plaintext, key1);

        try {
          // 使用错误的密钥解密
          await CryptoUtils.decrypt(ciphertext, key2);
          // 不应该执行到这里
          expect(false).assertEqual(true);
        } catch (error) {
          // 验证抛出错误
          expect(error).not.toBeNull();
          console.info('[CryptoUtilsTest] 错误密钥解密失败验证通过');
        }
      });

      it('空字符串哈希', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 空字符串哈希');

        const hash = await CryptoUtils.sha256('');

        // 验证哈希不为空
        expect(hash).not.toBeNull();
        expect(hash.length).assertLarger(0);

        console.info('[CryptoUtilsTest] 空字符串哈希验证通过');
      });

      it('Base64编码空字符串', 0, () => {
        console.info('[CryptoUtilsTest] 测试: Base64编码空字符串');

        const encoded = CryptoUtils.base64Encode('');
        const decoded = CryptoUtils.base64Decode(encoded);

        // 验证解码结果
        expect(decoded).assertEqual('');

        console.info('[CryptoUtilsTest] Base64编码空字符串验证通过');
      });

      it('生成零长度随机字符串', 0, () => {
        console.info('[CryptoUtilsTest] 测试: 生成零长度随机字符串');

        const randomString = CryptoUtils.generateRandomString(0);

        // 验证字符串长度
        expect(randomString.length).assertEqual(0);

        console.info('[CryptoUtilsTest] 生成零长度随机字符串验证通过');
      });
    });

    /**
     * ========================================
     * 性能测试
     * ========================================
     */
    describe('性能测试', () => {
      it('加密性能', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 加密性能');

        const key = await CryptoUtils.generateKey();
        const plaintext = 'test data for performance testing';

        const startTime = Date.now();

        // 执行100次加密
        for (let i = 0; i < 100; i++) {
          await CryptoUtils.encrypt(plaintext, key);
        }

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 100次加密应该在1秒内完成
        expect(duration).assertLess(1000);

        console.info('[CryptoUtilsTest] 加密性能验证通过: ' + duration + 'ms');
      });

      it('解密性能', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 解密性能');

        const key = await CryptoUtils.generateKey();
        const plaintext = 'test data for performance testing';
        const ciphertext = await CryptoUtils.encrypt(plaintext, key);

        const startTime = Date.now();

        // 执行100次解密
        for (let i = 0; i < 100; i++) {
          await CryptoUtils.decrypt(ciphertext, key);
        }

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 100次解密应该在1秒内完成
        expect(duration).assertLess(1000);

        console.info('[CryptoUtilsTest] 解密性能验证通过: ' + duration + 'ms');
      });

      it('哈希计算性能', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 哈希计算性能');

        const data = 'test data for performance testing';

        const startTime = Date.now();

        // 执行1000次哈希计算
        for (let i = 0; i < 1000; i++) {
          await CryptoUtils.sha256(data);
        }

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 1000次哈希计算应该在500ms内完成
        expect(duration).assertLess(500);

        console.info('[CryptoUtilsTest] 哈希计算性能验证通过: ' + duration + 'ms');
      });

      it('密钥生成性能', 0, async () => {
        console.info('[CryptoUtilsTest] 测试: 密钥生成性能');

        const startTime = Date.now();

        // 执行10次密钥生成
        const keys = [];
        for (let i = 0; i < 10; i++) {
          keys.push(await CryptoUtils.generateKey());
        }

        const endTime = Date.now();
        const duration = endTime - startTime;

        // 10次密钥生成应该在1秒内完成
        expect(duration).assertLess(1000);

        // 验证所有密钥都是唯一的
        const uniqueKeys = new Set(keys);
        expect(uniqueKeys.size).assertEqual(10);

        console.info('[CryptoUtilsTest] 密钥生成性能验证通过: ' + duration + 'ms');
      });
    });
  });
}

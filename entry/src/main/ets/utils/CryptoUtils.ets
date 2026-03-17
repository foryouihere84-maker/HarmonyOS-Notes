/**
 * 加密工具类
 * 提供AES-256加密解密功能，用于保护敏感配置信息
 * 
 * @author 开发者
 * @date 2026-03-12
 */
import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';
import { Logger } from './Logger';

export class CryptoUtils {
  private static readonly TAG: string = 'CryptoUtils';
  private static readonly ALGORITHM: string = 'AES256';
  private static readonly MODE: string = 'CBC';
  private static readonly PADDING: string = 'PKCS7';
  private static readonly KEY_SIZE: number = 256; // 256位密钥
  private static readonly IV_SIZE: number = 16; // 16字节IV
  private static readonly ENCODING: string = 'utf-8';

  /**
   * 生成随机密钥
   * @returns Base64编码的密钥
   */
  public static async generateKey(): Promise<string> {
    try {
      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const symKey = await symKeyGenerator.generateSymKey();
      const encodedKey = symKey.getEncoded();
      const base64 = new util.Base64();
      const base64Key = base64.encodeToStringSync(encodedKey.data);
      Logger.i(CryptoUtils.TAG, '生成密钥成功');
      return base64Key;
    } catch (error) {
      Logger.e(CryptoUtils.TAG, `生成密钥失败: ${error}`);
      throw new Error('生成密钥失败');
    }
  }

  /**
   * 生成随机IV
   * @returns Base64编码的IV
   */
  public static generateIV(): string {
    try {
      const iv = new Uint8Array(CryptoUtils.IV_SIZE);
      for (let i = 0; i < CryptoUtils.IV_SIZE; i++) {
        iv[i] = Math.floor(Math.random() * 256);
      }
      const base64 = new util.Base64();
      const base64IV = base64.encodeToStringSync(iv);
      Logger.i(CryptoUtils.TAG, '生成IV成功');
      return base64IV;
    } catch (error) {
      Logger.e(CryptoUtils.TAG, `生成IV失败: ${error}`);
      throw new Error('生成IV失败');
    }
  }

  /**
   * 加密数据
   * @param plaintext 明文
   * @param key Base64编码的密钥
   * @param iv Base64编码的IV（可选，如果不提供则生成随机IV）
   * @returns 加密结果（Base64编码的IV和密文）
   */
  public static async encrypt(plaintext: string, key: string, iv?: string): Promise<string> {
    try {
      Logger.i(CryptoUtils.TAG, `开始加密，字符串长度: ${plaintext.length}`);
      
      // 使用TextEncoder将字符串转换为Uint8Array
      Logger.i(CryptoUtils.TAG, '创建TextEncoder');
      const textEncoder = new util.TextEncoder();
      Logger.i(CryptoUtils.TAG, '开始encodeInto');
      const plaintextBytes = textEncoder.encodeInto(plaintext);
      Logger.i(CryptoUtils.TAG, `encodeInto完成，字节数组长度: ${plaintextBytes.length}`);
      
      // 解码密钥
      Logger.i(CryptoUtils.TAG, '解码密钥');
      const base64 = new util.Base64();
      const keyUint8Array = base64.decodeSync(key);
      const keyBlob: cryptoFramework.DataBlob = { data: keyUint8Array };

      // 创建对称密钥生成器
      Logger.i(CryptoUtils.TAG, '创建对称密钥生成器');
      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const symKey = await symKeyGenerator.convertKey(keyBlob);

      // 生成或使用提供的IV
      let ivData: Uint8Array;
      let ivString: string;
      if (iv) {
        ivString = iv;
        ivData = base64.decodeSync(iv);
      } else {
        iv = CryptoUtils.generateIV();
        ivString = iv;
        ivData = base64.decodeSync(iv);
      }

      const ivBlob: cryptoFramework.DataBlob = { data: ivData };

      // 创建加密器
      Logger.i(CryptoUtils.TAG, '创建加密器');
      const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
      const ivParamsSpec: cryptoFramework.IvParamsSpec = {
        algName: 'IvParamsSpec',
        iv: ivBlob
      };
      Logger.i(CryptoUtils.TAG, '初始化加密器');
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, ivParamsSpec);

      // 加密数据
      Logger.i(CryptoUtils.TAG, '开始加密数据');
      const plaintextBlob: cryptoFramework.DataBlob = {
        data: plaintextBytes
      };
      const encryptedBlob = await cipher.doFinal(plaintextBlob);
      Logger.i(CryptoUtils.TAG, '加密数据完成');

      // 将IV和密文合并
      const base64Cipher = base64.encodeToStringSync(encryptedBlob.data);
      const result = `${iv}:${base64Cipher}`;

      Logger.i(CryptoUtils.TAG, '加密成功');
      return result;
    } catch (error) {
      Logger.e(CryptoUtils.TAG, `加密失败: ${error}`);
      throw new Error('加密失败');
    }
  }

  /**
   * 解密数据
   * @param ciphertext 密文（格式：IV:密文，均为Base64编码）
   * @param key Base64编码的密钥
   * @returns 明文
   */
  public static async decrypt(ciphertext: string, key: string): Promise<string> {
    try {
      Logger.i(CryptoUtils.TAG, `开始解密，密文长度: ${ciphertext.length}`);
      
      // 分离IV和密文
      Logger.i(CryptoUtils.TAG, '分离IV和密文');
      const parts = ciphertext.split(':');
      if (parts.length !== 2) {
        throw new Error('密文格式错误');
      }

      const iv = parts[0];
      const encryptedData = parts[1];
      Logger.i(CryptoUtils.TAG, `IV: ${iv}, 密文: ${encryptedData}`);

      // 解码密钥
      Logger.i(CryptoUtils.TAG, '解码密钥');
      const base64 = new util.Base64();
      const keyUint8Array = base64.decodeSync(key);
      Logger.i(CryptoUtils.TAG, `密钥解码成功，长度: ${keyUint8Array.length}`);
      const keyBlob: cryptoFramework.DataBlob = { data: keyUint8Array };

      // 创建对称密钥生成器
      Logger.i(CryptoUtils.TAG, '创建对称密钥生成器');
      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const symKey = await symKeyGenerator.convertKey(keyBlob);
      Logger.i(CryptoUtils.TAG, '转换密钥成功');

      // 解码IV
      Logger.i(CryptoUtils.TAG, '解码IV');
      const ivData = base64.decodeSync(iv);
      Logger.i(CryptoUtils.TAG, `IV解码成功，长度: ${ivData.length}`);
      const ivBlob: cryptoFramework.DataBlob = { data: ivData };

      // 解码密文
      Logger.i(CryptoUtils.TAG, '解码密文');
      const encryptedDataArray = base64.decodeSync(encryptedData);
      Logger.i(CryptoUtils.TAG, `密文解码成功，长度: ${encryptedDataArray.length}`);
      const encryptedBlob: cryptoFramework.DataBlob = { data: encryptedDataArray };

      // 创建解密器
      Logger.i(CryptoUtils.TAG, '创建解密器');
      const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
      const ivParamsSpec: cryptoFramework.IvParamsSpec = {
        algName: 'IvParamsSpec',
        iv: ivBlob
      };
      Logger.i(CryptoUtils.TAG, '初始化解密器');
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, ivParamsSpec);
      Logger.i(CryptoUtils.TAG, '解密器初始化成功');

      // 解密数据
      Logger.i(CryptoUtils.TAG, '开始解密数据');
      const decryptedBlob = await cipher.doFinal(encryptedBlob);
      Logger.i(CryptoUtils.TAG, '解密数据完成');

      // 转换为字符串
      const decoder = util.TextDecoder.create(CryptoUtils.ENCODING);
      const plaintext = decoder.decodeToString(decryptedBlob.data);
      Logger.i(CryptoUtils.TAG, '解密成功');
      return plaintext;
    } catch (error) {
      Logger.e(CryptoUtils.TAG, `解密失败: ${error}`);
      throw new Error('解密失败');
    }
  }

  /**
   * 计算数据的SHA-256哈希值
   * @param data 数据
   * @returns Base64编码的哈希值
   */
  public static async sha256(data: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('SHA256');
      const dataBlob: cryptoFramework.DataBlob = {
        data: new Uint8Array(util.TextEncoder.create().encodeInto(data))
      };
      await md.update(dataBlob);
      const hashBlob = await md.digest();

      const base64 = new util.Base64();
      const base64Hash = base64.encodeToStringSync(hashBlob.data);

      Logger.i(CryptoUtils.TAG, '计算哈希成功');
      return base64Hash;
    } catch (error) {
      Logger.e(CryptoUtils.TAG, `计算哈希失败: ${error}`);
      throw new Error('计算哈希失败');
    }
  }

  /**
   * 生成随机字符串
   * @param length 长度
   * @returns 随机字符串
   */
  public static generateRandomString(length: number): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * Base64编码
   * @param data 数据
   * @returns Base64编码的字符串
   */
  public static base64Encode(data: string): string {
    try {
      const base64 = new util.Base64();
      const base64String = base64.encodeToStringSync(new Uint8Array(util.TextEncoder.create().encodeInto(data)));
      return base64String;
    } catch (error) {
      Logger.e(CryptoUtils.TAG, `Base64编码失败: ${error}`);
      throw new Error('Base64编码失败');
    }
  }

  /**
   * Base64解码
   * @param base64String Base64编码的字符串
   * @returns 解码后的数据
   */
  public static base64Decode(base64String: string): string {
    try {
      const base64 = new util.Base64();
      const decodedData = base64.decodeSync(base64String);
      const decoder = util.TextDecoder.create(CryptoUtils.ENCODING);
      return decoder.decodeToString(decodedData);
    } catch (error) {
      Logger.e(CryptoUtils.TAG, `Base64解码失败: ${error}`);
      throw new Error('Base64解码失败');
    }
  }
}

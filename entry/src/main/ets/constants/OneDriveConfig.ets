/**
 * OneDrive配置文件
 * 
 * 此文件包含OneDrive集成所需的所有配置常量
 * 包括OAuth 2.0客户端ID、授权端点、权限范围等
 * 
 * 重要说明：
 * 1. 客户端ID需要在Azure Portal中注册应用程序后获得
 * 2. 注册步骤：
 *    - 访问 https://portal.azure.com/
 *    - 导航到"Microsoft Entra ID" > "应用注册"
 *    - 点击"新注册"
 *    - 填写应用名称
 *    - 选择支持的账户类型："任何组织目录中的账户和个人Microsoft账户"
 *    - 注册后复制"应用程序(客户端)ID"
 * 3. 配置重定向URI：
 *    - 在应用注册页面，选择"身份验证"
 *    - 添加平台：移动和桌面应用程序
 *    - 添加重定向URI：harmonynote://oauth/callback
 * 4. 配置API权限：
 *    - 选择"API权限"
 *    - 添加Microsoft Graph权限
 *    - 选择委派权限
 *    - 搜索并添加：Files.ReadWrite 和 offline_access
 * 
 * @author 开发者
 * @date 2026-03-13
 */

/**
 * Microsoft OAuth 2.0客户端ID
 * 
 * 说明：
 * - 这是您在Azure Portal中注册应用程序后获得的唯一标识符
 * - 用于OAuth 2.0授权流程中标识您的应用程序
 * - 请勿泄露此ID，但它是公开信息，不是机密
 * 
 * 获取方式：
 * 1. 登录 https://portal.azure.com/
 * 2. 导航到"Microsoft Entra ID" > "应用注册"
 * 3. 选择您的应用程序
 * 4. 在"概览"页面复制"应用程序(客户端)ID"
 * 
 * 当前使用的客户端ID：
 * e2c2ad83-515d-4a96-bd09-fc0d73ece400
 */
export const MICROSOFT_CLIENT_ID: string = 'e2c2ad83-515d-4a96-bd09-fc0d73ece400';

/**
 * Microsoft授权端点接口
 */
export interface AuthorityEndpoints {
  COMMON: string;
  CONSUMERS: string;
  ORGANIZATIONS: string;
}

/**
 * Microsoft授权端点配置
 * 
 * 说明：
 * - Microsoft Identity Platform提供多个授权端点
 * - 根据您的目标用户类型选择合适的端点
 * 
 * 端点类型：
 * 1. COMMON: 支持所有账户类型（个人、工作、学校）
 *    - 适用于需要支持多种账户类型的应用
 *    - 用户登录时会看到账户类型选择界面
 * 
 * 2. CONSUMERS: 仅支持个人Microsoft账户
 *    - 适用于面向个人用户的应用
 *    - 账户类型：@outlook.com, @hotmail.com, @live.com, @msn.com等
 * 
 * 3. ORGANIZATIONS: 仅支持工作和学校账户
 *    - 适用于企业内部应用
 *    - 账户类型：Azure AD管理的组织账户
 * 
 * 当前配置：CONSUMERS（支持个人账户）
 */
export const AUTHORITY_ENDPOINTS: AuthorityEndpoints = {
  COMMON: 'https://login.microsoft.com/common',
  CONSUMERS: 'https://login.microsoft.com/consumers',
  ORGANIZATIONS: 'https://login.microsoft.com/organizations'
};

/**
 * 当前使用的授权端点
 * 
 * 说明：
 * - 根据应用的目标用户选择合适的端点
 * - 如果需要支持所有账户类型，使用AUTHORITY_ENDPOINTS.COMMON
 * - 如果只支持个人账户，使用AUTHORITY_ENDPOINTS.CONSUMERS
 * - 如果只支持工作/学校账户，使用AUTHORITY_ENDPOINTS.ORGANIZATIONS
 * 
 * 当前配置：CONSUMERS（个人账户）
 */
export const CURRENT_AUTHORITY: string = AUTHORITY_ENDPOINTS.CONSUMERS;

/**
 * OAuth 2.0重定向URI
 * 
 * 说明：
 * - 用户授权成功后，Microsoft会将用户重定向到此URI
 * - 此URI必须在Azure Portal的应用注册中配置
 * - 使用自定义URI方案（custom URI scheme）以便应用接收回调
 * 
 * 配置步骤：
 * 1. 在Azure Portal的应用注册页面，选择"身份验证"
 * 2. 点击"添加平台"
 * 3. 选择"移动和桌面应用程序"
 * 4. 在"重定向URI"中输入：harmonynote://oauth/callback
 * 5. 点击"配置"
 * 
 * 注意事项：
 * - URI必须与代码中完全一致（包括大小写）
 * - 建议使用应用的包名或标识符作为URI方案
 * - 例如：com.yourcompany.yourapp://oauth/callback
 */
export const REDIRECT_URI: string = 'harmonynote://oauth/callback';

/**
 * OAuth 2.0权限范围（Scope）
 * 
 * 说明：
 * - 定义应用程序请求的访问权限
 * - 用户在授权时会看到这些权限说明
 * - 权限分为委派权限和应用程序权限
 * 
 * 当前配置的权限：
 * 1. Files.ReadWrite: 读写用户OneDrive中的所有文件
 *    - 包括创建、读取、更新、删除文件和文件夹
 *    - 用户需要授予此权限才能进行文件同步
 * 
 * 2. User.Read: 读取用户基本信息
 *    - 获取用户的显示名称、邮箱地址等信息
 *    - 用于在应用中显示用户信息和头像
 * 
 * 3. offline_access: 获取刷新令牌
 *    - 允许应用在用户离线时刷新访问令牌
 *    - 访问令牌通常1小时后过期
 *    - 刷新令牌有效期更长（通常90天）
 *    - 必须包含此权限才能实现自动刷新令牌
 * 
 * 权限配置步骤：
 * 1. 在Azure Portal的应用注册页面，选择"API权限"
 * 2. 点击"添加权限"
 * 3. 选择"Microsoft Graph"
 * 4. 选择"委派权限"
 * 5. 搜索并添加：Files.ReadWrite、User.Read 和 offline_access
 * 6. 点击"添加权限"
 * 7. （可选）点击"授予管理员同意"以跳过用户同意
 */
export const OAUTH_SCOPES: string = 'Files.ReadWrite User.Read offline_access';

/**
 * OAuth 2.0授权URL模板
 * 
 * 说明：
 * - 用于生成OAuth 2.0授权请求的URL
 * - 用户访问此URL时会看到Microsoft登录页面
 * 
 * URL参数说明：
 * - client_id: 应用程序的客户端ID
 * - response_type: 固定为"code"（授权码模式）
 * - redirect_uri: 授权成功后的重定向URI
 * - scope: 请求的权限范围
 * - state: 用于防止CSRF攻击的随机字符串
 * - code_challenge: PKCE流程的代码挑战
 * - code_challenge_method: 固定为"S256"（SHA-256）
 */
export const AUTHORIZATION_URL_TEMPLATE: string = `${CURRENT_AUTHORITY}/oauth2/v2.0/authorize`;

/**
 * OAuth 2.0令牌端点URL
 * 
 * 说明：
 * - 用于交换授权码获取访问令牌
 * - 也用于刷新访问令牌
 * 
 * 使用场景：
 * 1. 用户授权成功后，使用授权码交换访问令牌
 * 2. 访问令牌过期后，使用刷新令牌获取新的访问令牌
 */
export const TOKEN_URL: string = `${CURRENT_AUTHORITY}/oauth2/v2.0/token`;

/**
 * Microsoft Graph API基础URL
 * 
 * 说明：
 * - 用于访问Microsoft Graph API
 * - 所有OneDrive API请求都基于此URL
 * 
 * 常用端点：
 * - /me/drive: 获取当前用户的OneDrive
 * - /me/drive/root: 获取OneDrive根目录
 * - /me/drive/root/children: 获取根目录下的文件列表
 * - /me/drive/items/{item-id}: 获取特定文件或文件夹
 * - /me/drive/items/{item-id}/content: 下载文件内容
 */
export const GRAPH_API_BASE_URL: string = 'https://graph.microsoft.com/v1.0';

/**
 * OneDrive API端点接口
 */
export interface OneDriveEndpoints {
  GET_DRIVE: string;
  GET_ROOT: string;
  GET_CHILDREN: string;
  GET_ITEM: (itemId: string) => string;
  GET_ITEM_CONTENT: (itemId: string) => string;
  CREATE_FOLDER: string;
  UPLOAD_FILE: (itemId: string) => string;
  DELETE_ITEM: (itemId: string) => string;
}

/**
 * OneDrive API端点
 * 
 * 说明：
 * - 常用的OneDrive API端点
 * - 用于文件和文件夹操作
 */
export const ONEDRIVE_ENDPOINTS: OneDriveEndpoints = {
  GET_DRIVE: `${GRAPH_API_BASE_URL}/me/drive`,
  GET_ROOT: `${GRAPH_API_BASE_URL}/me/drive/root`,
  GET_CHILDREN: `${GRAPH_API_BASE_URL}/me/drive/root/children`,
  GET_ITEM: (itemId: string) => `${GRAPH_API_BASE_URL}/me/drive/items/${itemId}`,
  GET_ITEM_CONTENT: (itemId: string) => `${GRAPH_API_BASE_URL}/me/drive/items/${itemId}/content`,
  CREATE_FOLDER: `${GRAPH_API_BASE_URL}/me/drive/root/children`,
  UPLOAD_FILE: (itemId: string) => `${GRAPH_API_BASE_URL}/me/drive/items/${itemId}/content`,
  DELETE_ITEM: (itemId: string) => `${GRAPH_API_BASE_URL}/me/drive/items/${itemId}`
};

/**
 * PKCE配置接口
 */
export interface PKCEConfig {
  CODE_VERIFIER_LENGTH: number;
  CODE_CHALLENGE_METHOD: string;
}

/**
 * PKCE配置
 * 
 * 说明：
 * - PKCE（Proof Key for Code Exchange）是OAuth 2.0的安全扩展
 * - 用于公共客户端（无法安全存储client_secret的应用）
 * - 通过代码挑战和验证器防止授权码拦截攻击
 * 
 * PKCE流程：
 * 1. 应用生成随机的code_verifier（43-128字符）
 * 2. 使用SHA-256对code_verifier哈希，生成code_challenge
 * 3. 在授权请求中包含code_challenge
 * 4. 在令牌交换请求中包含code_verifier
 * 5. Microsoft验证code_verifier是否匹配code_challenge
 * 
 * 配置参数：
 * - CODE_VERIFIER_LENGTH: code_verifier的长度（43-128字符）
 * - CODE_CHALLENGE_METHOD: 生成code_challenge的哈希算法（S256 = SHA-256）
 */
export const PKCE_CONFIG: PKCEConfig = {
  CODE_VERIFIER_LENGTH: 128,
  CODE_CHALLENGE_METHOD: 'S256'
};

/**
 * 令牌有效期配置接口
 */
export interface TokenExpiryConfig {
  ACCESS_TOKEN_EXPIRY_SECONDS: number;
  REFRESH_TOKEN_EXPIRY_SECONDS: number;
  REFRESH_THRESHOLD_SECONDS: number;
}

/**
 * 令牌有效期配置
 * 
 * 说明：
 * - 访问令牌通常1小时后过期
 * - 刷新令牌有效期更长（通常90天）
 * - 应用需要在令牌过期前自动刷新
 * 
 * 配置参数：
 * - ACCESS_TOKEN_EXPIRY_SECONDS: 访问令牌有效期（秒）
 * - REFRESH_TOKEN_EXPIRY_SECONDS: 刷新令牌有效期（秒）
 * - REFRESH_THRESHOLD_SECONDS: 提前刷新的阈值（秒）
 */
export const TOKEN_EXPIRY_CONFIG: TokenExpiryConfig = {
  ACCESS_TOKEN_EXPIRY_SECONDS: 3600,
  REFRESH_TOKEN_EXPIRY_SECONDS: 7776000,
  REFRESH_THRESHOLD_SECONDS: 300
};

/**
 * 网络请求配置接口
 */
export interface NetworkConfig {
  REQUEST_TIMEOUT_MS: number;
  MAX_RETRY_COUNT: number;
  RETRY_DELAY_MS: number;
}

/**
 * 网络请求配置
 * 
 * 说明：
 * - HTTP请求的超时时间和重试策略
 * - 用于处理网络不稳定的情况
 */
export const NETWORK_CONFIG: NetworkConfig = {
  REQUEST_TIMEOUT_MS: 30000,
  MAX_RETRY_COUNT: 3,
  RETRY_DELAY_MS: 1000
};

/**
 * 加密配置接口
 */
export interface EncryptionConfig {
  DEFAULT_KEY: string;
  ALGORITHM: string;
}

/**
 * 加密配置
 * 
 * 说明：
 * - 用于加密存储敏感信息（如访问令牌、刷新令牌）
 * - 使用AES加密算法
 * 
 * 安全建议：
 * - 不要将加密密钥硬编码在代码中
 * - 建议从安全存储或用户输入获取
 * - 可以使用设备唯一标识符作为密钥的一部分
 */
export const ENCRYPTION_CONFIG: EncryptionConfig = {
  DEFAULT_KEY: 'default_encryption_key_for_onedrive',
  ALGORITHM: 'AES-256-GCM'
};

/**
 * 同步配置接口
 */
export interface SyncConfiguration {
  DEFAULT_SYNC_PATH: string;
  SYNC_INTERVAL_MS: number;
  MAX_CONCURRENT_UPLOADS: number;
  MAX_FILE_SIZE_MB: number;
}

/**
 * 同步配置
 * 
 * 说明：
 * - 文件同步的相关配置
 * - 包括默认同步路径、同步间隔等
 */
export const SYNC_CONFIG: SyncConfiguration = {
  DEFAULT_SYNC_PATH: '/iherefor_Notebook',
  SYNC_INTERVAL_MS: 60000,
  MAX_CONCURRENT_UPLOADS: 3,
  MAX_FILE_SIZE_MB: 10
};

/**
 * 日志配置接口
 */
export interface LogConfig {
  ENABLE_DEBUG_LOG: boolean;
  ENABLE_ERROR_LOG: boolean;
  LOG_PREFIX: string;
}

/**
 * 日志配置
 * 
 * 说明：
 * - 日志记录的详细程度和输出方式
 * - 用于调试和问题排查
 */
export const LOG_CONFIG: LogConfig = {
  ENABLE_DEBUG_LOG: true,
  ENABLE_ERROR_LOG: true,
  LOG_PREFIX: 'OneDrive'
};

/**
 * 应用常量定义
 * 包含应用级别的常量定义
 * 
 * @author 开发者
 * @date 2026-03-11
 */

export class AppConstants {
  // 应用信息
  public static readonly APP_NAME: string = 'iherefor的笔记';
  public static readonly APP_VERSION: string = '1.0.0';
  
  // 主题模式
  public static readonly THEME_LIGHT: string = 'light';
  public static readonly THEME_DARK: string = 'dark';
  public static readonly THEME_AUTO: string = 'auto';
  
  // 默认设置
  public static readonly DEFAULT_THEME_MODE: string = 'light';
  public static readonly DEFAULT_USERNAME: string = 'iherefor';
  public static readonly DEFAULT_USER_ID: string = 'user_001';
  public static readonly DEFAULT_CACHE_SIZE: string = '0 MB';
  
  // 页面路由名称
  public static readonly ROUTE_MAIN: string = 'pages/MainPage';
  public static readonly ROUTE_NOTEBOOK_LIST: string = 'pages/NotebookList';
  public static readonly ROUTE_PAGE_EDITOR: string = 'pages/PageEditor';
  public static readonly ROUTE_SEARCH: string = 'pages/SearchPage';
  public static readonly ROUTE_SETTINGS: string = 'pages/SettingsPage';
  public static readonly ROUTE_SETTINGS_PAGE: string = 'pages/SettingsPage';
  public static readonly ROUTE_ONEDRIVE_CONFIG: string = 'pages/OneDriveConfigPage';
  public static readonly ROUTE_SYNC_SETTINGS: string = 'pages/SyncSettingsPage';
  public static readonly ROUTE_SYNC_HISTORY: string = 'pages/SyncHistoryPage';
  public static readonly ROUTE_LOGIN: string = 'pages/LoginPage';
  public static readonly ROUTE_REGISTER: string = 'pages/RegisterPage';
  public static readonly ROUTE_AI_CHAT: string = 'pages/AIChatPage';
  public static readonly ROUTE_AI_HISTORY: string = 'pages/AIHistoryPage';
  
  // 数据限制
  public static readonly MAX_NOTEBOOK_TITLE_LENGTH: number = 100;
  public static readonly MAX_PAGE_TITLE_LENGTH: number = 200;
  public static readonly MAX_PAGE_CONTENT_LENGTH: number = 100000;
  public static readonly MAX_TAG_NAME_LENGTH: number = 50;
  
  // 默认值
  public static readonly DEFAULT_NOTEBOOK_COLOR: string = '#0078D4';
  public static readonly DEFAULT_NOTEBOOK_ICON: string = 'notebook';
  public static readonly DEFAULT_FONT_SIZE: number = 16;
  
  // 笔记本颜色选项
  public static readonly NOTEBOOK_COLORS: string[] = [
    '#0078D4',
    '#E81123',
    '#107C10',
    '#FFB900',
    '#FF8C00',
    '#8764B8',
    '#00B7C3',
    '#0078D4'
  ];
  
  // 笔记本图标选项
  public static readonly NOTEBOOK_ICONS: string[] = [
    'notebook',
    'book',
    'folder',
    'star',
    'heart',
    'bookmark'
  ];
  
  // 时间格式
  public static readonly DATE_FORMAT: string = 'yyyy-MM-dd';
  public static readonly TIME_FORMAT: string = 'HH:mm:ss';
  public static readonly DATETIME_FORMAT: string = 'yyyy-MM-dd HH:mm:ss';
  
  // 存储路径
  public static readonly STORAGE_PATH: string = '/data/storage/el2/base/haps/entry/files';
  public static readonly ATTACHMENTS_PATH: string = '/data/storage/el2/base/haps/entry/files/attachments';
  public static readonly EXPORT_PATH: string = '/data/storage/el2/base/haps/entry/files/exports';
  public static readonly NOTES_PATH: string = '/data/storage/el2/base/haps/entry/files/notes';
  public static readonly IMAGES_PATH: string = '/data/storage/el2/base/haps/entry/files/attachments/images';
  public static readonly DOCUMENTS_PATH: string = '/data/storage/el2/base/haps/entry/files/attachments/documents';
  public static readonly AUDIO_PATH: string = '/data/storage/el2/base/haps/entry/files/attachments/audio';
  public static readonly THUMBNAILS_PATH: string = '/data/storage/el2/base/haps/entry/files/thumbnails';
  
  // 文件编码
  public static readonly FILE_ENCODING: string = 'utf-8';
  
  // 文件大小限制
  public static readonly MAX_FILE_SIZE: number = 100 * 1024 * 1024; // 100MB
  public static readonly MAX_IMAGE_SIZE: number = 10 * 1024 * 1024; // 10MB
  public static readonly MAX_DOCUMENT_SIZE: number = 50 * 1024 * 1024; // 50MB
  public static readonly MAX_AUDIO_SIZE: number = 50 * 1024 * 1024; // 50MB
  
  // 文件类型
  public static readonly FILE_TYPE_IMAGE: string = 'image';
  public static readonly FILE_TYPE_DOCUMENT: string = 'document';
  public static readonly FILE_TYPE_AUDIO: string = 'audio';
  public static readonly FILE_TYPE_VIDEO: string = 'video';
  
  // 支持的图片格式
  public static readonly SUPPORTED_IMAGE_FORMATS: string[] = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp'
  ];
  
  // 支持的文档格式
  public static readonly SUPPORTED_DOCUMENT_FORMATS: string[] = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'md'
  ];
  
  // 导出格式
  public static readonly EXPORT_FORMAT_PDF: string = 'pdf';
  public static readonly EXPORT_FORMAT_TEXT: string = 'txt';
  public static readonly EXPORT_FORMAT_MARKDOWN: string = 'md';
  
  // 搜索限制
  public static readonly MAX_SEARCH_RESULTS: number = 100;
  public static readonly MIN_SEARCH_LENGTH: number = 2;
  
  // 同步相关
  public static readonly SYNC_INTERVAL: number = 300000; // 5分钟
  public static readonly SYNC_TIMEOUT: number = 30000; // 30秒
  
  // UI相关
  public static readonly ANIMATION_DURATION: number = 300;
  public static readonly TOAST_DURATION: number = 2000;
  public static readonly DIALOG_WIDTH: number = 500;
  public static readonly DIALOG_HEIGHT: number = 400;
  
  // 分页
  public static readonly PAGE_SIZE: number = 20;
  public static readonly MAX_PAGE_SIZE: number = 100;
  
  // AI 相关配置
  public static readonly AI_MAX_TEXT_LENGTH: number = 50 * 1024; // 50KB 阈值
  public static readonly AI_CHUNK_SIZE: number = 10 * 1024; // 每块 10KB
  public static readonly AI_MAX_CHUNKS: number = 20; // 最多 20 块
  public static readonly AI_REQUEST_TIMEOUT: number = 120000; // 2 分钟

  // 后端服务URL配置
  public static readonly AUTH_BASE_URL: string = 'http://192.168.3.17:8080';
  public static readonly API_BASE_URL: string = 'http://192.168.3.17:8080';
}
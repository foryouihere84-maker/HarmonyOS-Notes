/**
 * 数据库常量定义
 * 包含数据库相关的常量定义
 * 
 * @author 开发者
 * @date 2026-03-11
 */

export class DatabaseConstants {
  // 数据库配置
  public static readonly DATABASE_NAME: string = 'notebook.db';
  public static readonly DATABASE_VERSION: number = 1;
  
  // 表名
  public static readonly TABLE_NOTEBOOKS: string = 'notebooks';
  public static readonly TABLE_PAGES: string = 'pages';
  public static readonly TABLE_SECTIONS: string = 'sections';
  public static readonly TABLE_TAGS: string = 'tags';
  public static readonly TABLE_PAGE_TAGS: string = 'page_tags';
  public static readonly TABLE_USER_SETTINGS: string = 'user_settings';
  public static readonly TABLE_SYNC_CONFIGS: string = 'sync_configs';
  public static readonly TABLE_SYNC_HISTORY: string = 'sync_history';
  public static readonly TABLE_LOGIN_INFO: string = 'login_info';
  
  // 笔记本表字段
  public static readonly FIELD_ID: string = 'id';
  public static readonly FIELD_TITLE: string = 'title';
  public static readonly FIELD_DESCRIPTION: string = 'description';
  public static readonly FIELD_COLOR: string = 'color';
  public static readonly FIELD_ICON: string = 'icon';
  public static readonly FIELD_COVER_IMAGE: string = 'cover_image';
  public static readonly FIELD_CREATED_TIME: string = 'created_time';
  public static readonly FIELD_MODIFIED_TIME: string = 'modified_time';
  public static readonly FIELD_PAGE_COUNT: string = 'page_count';
  
  // 页面表字段
  public static readonly FIELD_NOTEBOOK_ID: string = 'notebook_id';
  public static readonly FIELD_SECTION_ID: string = 'section_id';
  public static readonly FIELD_CONTENT: string = 'content';
  public static readonly FIELD_ORDER: string = 'order_index';
  public static readonly FIELD_IS_PINNED: string = 'is_pinned';
  public static readonly FIELD_IS_DELETED: string = 'is_deleted';
  public static readonly FIELD_BACKGROUND_COLOR: string = 'background_color';
  public static readonly FIELD_FONT_SIZE: string = 'font_size';
  
  // 分区表字段
  public static readonly FIELD_PARENT_ID: string = 'parent_id';
  
  // 标签表字段
  public static readonly FIELD_NAME: string = 'name';
  public static readonly FIELD_PAGE_ID: string = 'page_id';
  public static readonly FIELD_TAG_ID: string = 'tag_id';
  
  // 用户设置表字段
  public static readonly FIELD_USER_ID: string = 'user_id';
  public static readonly FIELD_USERNAME: string = 'username';
  public static readonly FIELD_AVATAR: string = 'avatar';
  public static readonly FIELD_THEME_MODE: string = 'theme_mode';
  public static readonly FIELD_CACHE_SIZE: string = 'cache_size';
  public static readonly FIELD_LAST_CLEAR_CACHE_TIME: string = 'last_clear_cache_time';
  
  // 同步配置表字段
  public static readonly FIELD_EMAIL: string = 'email';
  public static readonly FIELD_SYNC_PATH: string = 'sync_path';
  public static readonly FIELD_ACCESS_TOKEN: string = 'access_token';
  public static readonly FIELD_REFRESH_TOKEN: string = 'refresh_token';
  public static readonly FIELD_CLIENT_ID: string = 'client_id';
  public static readonly FIELD_CLIENT_SECRET: string = 'client_secret';
  public static readonly FIELD_AUTO_SYNC: string = 'auto_sync';
  public static readonly FIELD_SYNC_INTERVAL: string = 'sync_interval';
  public static readonly FIELD_LAST_SYNC_TIME: string = 'last_sync_time';
  public static readonly FIELD_ENABLED: string = 'enabled';
  
  // 同步历史表字段
  public static readonly FIELD_SYNC_TYPE: string = 'sync_type';
  public static readonly FIELD_STATE: string = 'state';
  public static readonly FIELD_CONFIG_ID: string = 'config_id';
  public static readonly FIELD_CONFIG_EMAIL: string = 'config_email';
  public static readonly FIELD_START_TIME: string = 'start_time';
  public static readonly FIELD_END_TIME: string = 'end_time';
  public static readonly FIELD_DURATION: string = 'duration';
  public static readonly FIELD_ITEMS_UPLOADED: string = 'items_uploaded';
  public static readonly FIELD_ITEMS_DOWNLOADED: string = 'items_downloaded';
  public static readonly FIELD_ITEMS_SKIPPED: string = 'items_skipped';
  public static readonly FIELD_ITEMS_FAILED: string = 'items_failed';
  public static readonly FIELD_BYTES_UPLOADED: string = 'bytes_uploaded';
  public static readonly FIELD_BYTES_DOWNLOADED: string = 'bytes_downloaded';
  public static readonly FIELD_CONFLICT_COUNT: string = 'conflict_count';
  public static readonly FIELD_CONFLICT_RESOLUTION: string = 'conflict_resolution';
  public static readonly FIELD_ERROR_MESSAGE: string = 'error_message';
  public static readonly FIELD_IS_AUTO_SYNC: string = 'is_auto_sync';
  public static readonly FIELD_ENCRYPTION_KEY: string = 'encryption_key';
  
  // 登录信息表字段
  public static readonly FIELD_DISPLAY_NAME: string = 'display_name';
  public static readonly FIELD_LOGIN_TIME: string = 'login_time';
  public static readonly FIELD_EXPIRE_TIME: string = 'expire_time';
  public static readonly FIELD_LAST_ACTIVE_TIME: string = 'last_active_time';
  
  // 创建笔记本表的SQL
  public static readonly SQL_CREATE_NOTEBOOKS_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_NOTEBOOKS} (
      ${DatabaseConstants.FIELD_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_TITLE} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_DESCRIPTION} TEXT,
      ${DatabaseConstants.FIELD_COLOR} TEXT,
      ${DatabaseConstants.FIELD_ICON} TEXT,
      ${DatabaseConstants.FIELD_COVER_IMAGE} TEXT,
      ${DatabaseConstants.FIELD_CREATED_TIME} INTEGER,
      ${DatabaseConstants.FIELD_MODIFIED_TIME} INTEGER,
      ${DatabaseConstants.FIELD_PAGE_COUNT} INTEGER DEFAULT 0
    )
  `;
  
  // 创建页面表的SQL
  public static readonly SQL_CREATE_PAGES_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_PAGES} (
      ${DatabaseConstants.FIELD_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_NOTEBOOK_ID} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_SECTION_ID} TEXT,
      ${DatabaseConstants.FIELD_TITLE} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_CONTENT} TEXT,
      ${DatabaseConstants.FIELD_CREATED_TIME} INTEGER,
      ${DatabaseConstants.FIELD_MODIFIED_TIME} INTEGER,
      ${DatabaseConstants.FIELD_ORDER} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_IS_PINNED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_IS_DELETED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_BACKGROUND_COLOR} TEXT DEFAULT '#FFFFFF',
      ${DatabaseConstants.FIELD_FONT_SIZE} INTEGER DEFAULT 36,
      FOREIGN KEY (${DatabaseConstants.FIELD_NOTEBOOK_ID}) REFERENCES ${DatabaseConstants.TABLE_NOTEBOOKS}(${DatabaseConstants.FIELD_ID}) ON DELETE CASCADE,
      FOREIGN KEY (${DatabaseConstants.FIELD_SECTION_ID}) REFERENCES ${DatabaseConstants.TABLE_SECTIONS}(${DatabaseConstants.FIELD_ID}) ON DELETE SET NULL
    )
  `;
  
  // 创建分区表的SQL
  public static readonly SQL_CREATE_SECTIONS_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_SECTIONS} (
      ${DatabaseConstants.FIELD_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_NOTEBOOK_ID} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_PARENT_ID} TEXT,
      ${DatabaseConstants.FIELD_TITLE} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_ORDER} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_CREATED_TIME} INTEGER,
      ${DatabaseConstants.FIELD_MODIFIED_TIME} INTEGER,
      FOREIGN KEY (${DatabaseConstants.FIELD_NOTEBOOK_ID}) REFERENCES ${DatabaseConstants.TABLE_NOTEBOOKS}(${DatabaseConstants.FIELD_ID}) ON DELETE CASCADE,
      FOREIGN KEY (${DatabaseConstants.FIELD_PARENT_ID}) REFERENCES ${DatabaseConstants.TABLE_SECTIONS}(${DatabaseConstants.FIELD_ID}) ON DELETE CASCADE
    )
  `;
  
  // 创建标签表的SQL
  public static readonly SQL_CREATE_TAGS_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_TAGS} (
      ${DatabaseConstants.FIELD_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_NAME} TEXT NOT NULL UNIQUE,
      ${DatabaseConstants.FIELD_CREATED_TIME} INTEGER
    )
  `;
  
  // 创建页面标签关联表的SQL
  public static readonly SQL_CREATE_PAGE_TAGS_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_PAGE_TAGS} (
      ${DatabaseConstants.FIELD_PAGE_ID} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_TAG_ID} TEXT NOT NULL,
      PRIMARY KEY (${DatabaseConstants.FIELD_PAGE_ID}, ${DatabaseConstants.FIELD_TAG_ID}),
      FOREIGN KEY (${DatabaseConstants.FIELD_PAGE_ID}) REFERENCES ${DatabaseConstants.TABLE_PAGES}(${DatabaseConstants.FIELD_ID}) ON DELETE CASCADE,
      FOREIGN KEY (${DatabaseConstants.FIELD_TAG_ID}) REFERENCES ${DatabaseConstants.TABLE_TAGS}(${DatabaseConstants.FIELD_ID}) ON DELETE CASCADE
    )
  `;
  
  // 创建用户设置表的SQL
  public static readonly SQL_CREATE_USER_SETTINGS_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_USER_SETTINGS} (
      ${DatabaseConstants.FIELD_USER_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_USERNAME} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_AVATAR} TEXT,
      ${DatabaseConstants.FIELD_THEME_MODE} TEXT NOT NULL DEFAULT 'light',
      ${DatabaseConstants.FIELD_CACHE_SIZE} TEXT DEFAULT '0 MB',
      ${DatabaseConstants.FIELD_LAST_CLEAR_CACHE_TIME} INTEGER DEFAULT 0
    )
  `;
  
  // 创建同步配置表的SQL
  public static readonly SQL_CREATE_SYNC_CONFIGS_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_SYNC_CONFIGS} (
      ${DatabaseConstants.FIELD_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_USER_ID} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_EMAIL} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_SYNC_PATH} TEXT NOT NULL DEFAULT '/iherefor_Notebook',
      ${DatabaseConstants.FIELD_ACCESS_TOKEN} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_REFRESH_TOKEN} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_CLIENT_ID} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_CLIENT_SECRET} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_AUTO_SYNC} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_SYNC_INTERVAL} INTEGER DEFAULT 3600000,
      ${DatabaseConstants.FIELD_LAST_SYNC_TIME} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_ENABLED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_CONFLICT_RESOLUTION} TEXT DEFAULT 'latest',
      ${DatabaseConstants.FIELD_CREATED_TIME} INTEGER NOT NULL,
      ${DatabaseConstants.FIELD_MODIFIED_TIME} INTEGER NOT NULL,
      ${DatabaseConstants.FIELD_ENCRYPTION_KEY} TEXT NOT NULL
    )
  `;
  
  // 创建同步历史表的SQL
  public static readonly SQL_CREATE_SYNC_HISTORY_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_SYNC_HISTORY} (
      ${DatabaseConstants.FIELD_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_SYNC_TYPE} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_STATE} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_CONFIG_ID} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_CONFIG_EMAIL} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_START_TIME} INTEGER NOT NULL,
      ${DatabaseConstants.FIELD_END_TIME} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_DURATION} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_ITEMS_UPLOADED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_ITEMS_DOWNLOADED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_ITEMS_SKIPPED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_ITEMS_FAILED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_BYTES_UPLOADED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_BYTES_DOWNLOADED} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_CONFLICT_COUNT} INTEGER DEFAULT 0,
      ${DatabaseConstants.FIELD_CONFLICT_RESOLUTION} TEXT DEFAULT 'latest',
      ${DatabaseConstants.FIELD_ERROR_MESSAGE} TEXT DEFAULT '',
      ${DatabaseConstants.FIELD_IS_AUTO_SYNC} INTEGER DEFAULT 0
    )
  `;
  
  // 创建登录信息表的SQL
  public static readonly SQL_CREATE_LOGIN_INFO_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.TABLE_LOGIN_INFO} (
      ${DatabaseConstants.FIELD_ID} TEXT PRIMARY KEY,
      ${DatabaseConstants.FIELD_USER_ID} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_EMAIL} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_DISPLAY_NAME} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_ACCESS_TOKEN} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_REFRESH_TOKEN} TEXT NOT NULL,
      ${DatabaseConstants.FIELD_LOGIN_TIME} INTEGER NOT NULL,
      ${DatabaseConstants.FIELD_EXPIRE_TIME} INTEGER NOT NULL,
      ${DatabaseConstants.FIELD_LAST_ACTIVE_TIME} INTEGER NOT NULL,
      ${DatabaseConstants.FIELD_CREATED_TIME} INTEGER NOT NULL,
      ${DatabaseConstants.FIELD_MODIFIED_TIME} INTEGER NOT NULL
    )
  `;
  
  // 创建索引
  public static readonly SQL_CREATE_INDEXS: string[] = [
    `CREATE INDEX IF NOT EXISTS idx_notebooks_modified_time ON ${DatabaseConstants.TABLE_NOTEBOOKS}(${DatabaseConstants.FIELD_MODIFIED_TIME} DESC)`,
    `CREATE INDEX IF NOT EXISTS idx_pages_notebook_id ON ${DatabaseConstants.TABLE_PAGES}(${DatabaseConstants.FIELD_NOTEBOOK_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_pages_section_id ON ${DatabaseConstants.TABLE_PAGES}(${DatabaseConstants.FIELD_SECTION_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_pages_modified_time ON ${DatabaseConstants.TABLE_PAGES}(${DatabaseConstants.FIELD_MODIFIED_TIME} DESC)`,
    `CREATE INDEX IF NOT EXISTS idx_sections_notebook_id ON ${DatabaseConstants.TABLE_SECTIONS}(${DatabaseConstants.FIELD_NOTEBOOK_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_sections_parent_id ON ${DatabaseConstants.TABLE_SECTIONS}(${DatabaseConstants.FIELD_PARENT_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_tags_name ON ${DatabaseConstants.TABLE_TAGS}(${DatabaseConstants.FIELD_NAME})`,
    `CREATE INDEX IF NOT EXISTS idx_page_tags_page_id ON ${DatabaseConstants.TABLE_PAGE_TAGS}(${DatabaseConstants.FIELD_PAGE_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_page_tags_tag_id ON ${DatabaseConstants.TABLE_PAGE_TAGS}(${DatabaseConstants.FIELD_TAG_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_user_settings_username ON ${DatabaseConstants.TABLE_USER_SETTINGS}(${DatabaseConstants.FIELD_USERNAME})`,
    `CREATE INDEX IF NOT EXISTS idx_sync_configs_user_id ON ${DatabaseConstants.TABLE_SYNC_CONFIGS}(${DatabaseConstants.FIELD_USER_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_sync_configs_email ON ${DatabaseConstants.TABLE_SYNC_CONFIGS}(${DatabaseConstants.FIELD_EMAIL})`,
    `CREATE INDEX IF NOT EXISTS idx_sync_configs_enabled ON ${DatabaseConstants.TABLE_SYNC_CONFIGS}(${DatabaseConstants.FIELD_ENABLED})`,
    `CREATE INDEX IF NOT EXISTS idx_sync_history_config_id ON ${DatabaseConstants.TABLE_SYNC_HISTORY}(${DatabaseConstants.FIELD_CONFIG_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_sync_history_start_time ON ${DatabaseConstants.TABLE_SYNC_HISTORY}(${DatabaseConstants.FIELD_START_TIME} DESC)`,
    `CREATE INDEX IF NOT EXISTS idx_sync_history_state ON ${DatabaseConstants.TABLE_SYNC_HISTORY}(${DatabaseConstants.FIELD_STATE})`,
    `CREATE INDEX IF NOT EXISTS idx_sync_history_is_auto_sync ON ${DatabaseConstants.TABLE_SYNC_HISTORY}(${DatabaseConstants.FIELD_IS_AUTO_SYNC})`,
    `CREATE INDEX IF NOT EXISTS idx_login_info_user_id ON ${DatabaseConstants.TABLE_LOGIN_INFO}(${DatabaseConstants.FIELD_USER_ID})`,
    `CREATE INDEX IF NOT EXISTS idx_login_info_email ON ${DatabaseConstants.TABLE_LOGIN_INFO}(${DatabaseConstants.FIELD_EMAIL})`,
    `CREATE INDEX IF NOT EXISTS idx_login_info_expire_time ON ${DatabaseConstants.TABLE_LOGIN_INFO}(${DatabaseConstants.FIELD_EXPIRE_TIME})`
  ];
}
import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoUri: process.env.MONGO_URI || 'mongodb+srv://puskarpreconet_db_user:2lZjuXKvmR5qJOQU@cluster0.nspnmzz.mongodb.net/agent_chat?appName=Cluster0',
  redisUrl: process.env.REDIS_URL || 'redis://127.0.0.1:6379',
  jwtSecret: process.env.JWT_SECRET || 'super-secret-jwt-key-agent-chat-2026',
  gatewayId: process.env.GATEWAY_ID || `gw-${Math.floor(Math.random() * 1000)}`,
  
  // Wasabi Hot Cloud Storage (S3-compatible) Configuration
  s3: {
    region: process.env.WASABI_REGION || process.env.AWS_REGION || 'us-east-1',
    bucket: process.env.WASABI_BUCKET || process.env.S3_BUCKET || 'chat-recordings', 
    accessKeyId: process.env.WASABI_ACCESS_KEY_ID || process.env.S3_ACCESS_KEY_ID || 'mock-access-key',
    secretAccessKey: process.env.WASABI_SECRET_ACCESS_KEY || process.env.S3_SECRET_ACCESS_KEY || 'mock-secret-key',
    endpoint: process.env.WASABI_ENDPOINT || process.env.S3_ENDPOINT || 'https://s3.us-east-1.wasabisys.com',
    cdnBaseUrl: process.env.WASABI_CDN_BASE_URL || process.env.CDN_BASE_URL || 'https://s3.us-east-1.wasabisys.com/chat-recordings'
  },
  phpApiUrl: process.env.PHP_API_URL || 'http://localhost/api.php',
  fixedApiToken: process.env.FIXED_API_TOKEN || 'chat_fixed_auth_token_2026_prod',
  mysql: {
    host: process.env.DB_HOST || process.env.MYSQL_HOST || 'localhost',
    user: process.env.DB_USER || process.env.MYSQL_USER || 'root',
    password: process.env.DB_PASS !== undefined ? process.env.DB_PASS : (process.env.MYSQL_PASSWORD !== undefined ? process.env.MYSQL_PASSWORD : ''),
    database: process.env.DB_NAME || process.env.MYSQL_DATABASE || 'telewiz_ofcmanage_db',
    port: parseInt(process.env.DB_PORT || process.env.MYSQL_PORT || '3306', 10)
  }
};

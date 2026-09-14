import mongoose from 'mongoose';
import { config } from './env.js';

export async function connectDB() {
  const atlasUri = config.mongoUri;
  
  mongoose.set('strictQuery', true);

  try {
    console.log(`[Database] Connecting to MongoDB Atlas: ${atlasUri.replace(/\/\/[^:]+:[^@]+@/, '//***:***@')}`);
    await mongoose.connect(atlasUri, {
      serverSelectionTimeoutMS: 10000
    });
    console.log(`[Database] MongoDB Atlas connected successfully`);
  } catch (error) {
    console.error(`[Database] CRITICAL: Failed to connect to MongoDB Atlas (${error.message})`);
    throw error;
  }
}

export async function disconnectDB() {
  await mongoose.disconnect();
  console.log('[Database] MongoDB disconnected');
}

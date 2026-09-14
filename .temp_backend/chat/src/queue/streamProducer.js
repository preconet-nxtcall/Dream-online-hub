import { streamClient } from '../config/redis.js';
import { processStreamMessage } from './streamWorker.js';

export const MESSAGES_STREAM_KEY = 'stream:messages';

export async function enqueueMessage(messagePayload) {
  try {
    const payloadJson = JSON.stringify(messagePayload);
    if (typeof streamClient.xadd === 'function' && streamClient.status === 'ready') {
      const entryId = await streamClient.xadd(
        MESSAGES_STREAM_KEY,
        '*',
        'payload', payloadJson
      );
      return entryId;
    }
  } catch (err) {
    if (!err.message.includes('Unsupported command')) {
      console.error('[StreamProducer] Error enqueuing message to Redis stream:', err.message);
    }
  }

  // Fallback: If Redis streams are disabled, mocked, or failed, write directly to MongoDB
  try {
    await processStreamMessage(`direct-${Date.now()}`, messagePayload);
  } catch (dbErr) {
    console.error('[StreamProducer] Direct DB write fallback failed:', dbErr.message);
  }

  return `stream-${Date.now()}`;
}

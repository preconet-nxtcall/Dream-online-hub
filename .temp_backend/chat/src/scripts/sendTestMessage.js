import { connectDB, disconnectDB } from '../config/database.js';
import { Conversation } from '../models/Conversation.js';
import { Message } from '../models/Message.js';

async function main() {
  try {
    console.log('[TestScript] Connecting to MongoDB Atlas...');
    await connectDB();

    const conversationId = 'conv-ADMIN-1-testuser@example.com';
    const messageId = `msg-test-${Date.now()}`;
    const now = new Date();

    // 1. Create/Upsert Test Conversation in MongoDB Atlas
    console.log(`[TestScript] Creating/upserting Conversation "${conversationId}" in MongoDB Atlas...`);
    const conv = await Conversation.findByIdAndUpdate(
      conversationId,
      {
        $setOnInsert: {
          _id: conversationId,
          participant1: 'ADMIN-1',
          participant2: 'testuser@example.com',
          agentId: 'ADMIN-1',
          emailId: 'testuser@example.com'
        },
        $set: {
          lastMessageAt: now,
          lastMessage: 'Hello, this is a test message in MongoDB Atlas!'
        },
        $inc: {
          unread2: 1
        }
      },
      { upsert: true, new: true }
    );
    console.log('[TestScript] Saved Conversation in MongoDB Atlas:', conv);

    // 2. Create Test Message in MongoDB Atlas
    console.log(`[TestScript] Creating Message "${messageId}" in MongoDB Atlas...`);
    const msg = await Message.create({
      _id: messageId,
      conversationId,
      senderId: 'ADMIN-1',
      senderType: 'admin',
      type: 'text',
      text: 'Hello, this is a test message in MongoDB Atlas!',
      status: 'sent',
      createdAt: now
    });
    console.log('[TestScript] Saved Message in MongoDB Atlas:', msg);

    // 3. Verify retrieval from MongoDB Atlas
    console.log('\n[TestScript] Verifying documents directly from MongoDB Atlas...');
    const foundConvs = await Conversation.find({ _id: conversationId });
    const foundMsgs = await Message.find({ conversationId });

    console.log(`[TestScript] Found ${foundConvs.length} Conversation(s) in MongoDB Atlas:`);
    console.dir(foundConvs.map(c => c.toObject()), { depth: null });

    console.log(`[TestScript] Found ${foundMsgs.length} Message(s) in MongoDB Atlas:`);
    console.dir(foundMsgs.map(m => m.toObject()), { depth: null });

    await disconnectDB();
    console.log('[TestScript] Successfully completed verification against MongoDB Atlas!');
  } catch (err) {
    console.error('[TestScript] Error running test script:', err);
    process.exit(1);
  }
}

main();

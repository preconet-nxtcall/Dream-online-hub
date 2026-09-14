import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { v4 as uuidv4 } from 'uuid';
import { pubClient, subClient } from '../config/redis.js';
import { config } from '../config/env.js';
import { socketAuthMiddleware } from './authMiddleware.js';
import { setPresence, renewPresence, removePresence, isOnline } from '../services/presence.service.js';
import { checkRateLimit } from '../services/rateLimiter.service.js';
import { enqueueMessage } from '../queue/streamProducer.js';
import { processStreamMessage } from '../queue/streamWorker.js';
import { Message } from '../models/Message.js';
import { Conversation } from '../models/Conversation.js';
import { User } from '../models/User.js';
import { Agent } from '../models/Agent.js';

export function setupSocketGateway(httpServer) {
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    },
    transports: ['websocket', 'polling']
  });

  // Redis Adapter for horizontal scaling
  io.adapter(createAdapter(pubClient, subClient));

  // Authentication Middleware
  io.use(socketAuthMiddleware);

  io.on('connection', async (socket) => {
    const { emailId, role, agentId, name } = socket.data.user;
    const gatewayId = config.gatewayId;
    const isStaff = role === 'agent' || role === 'admin';
    const myUserIds = new Set([
      emailId,
      isStaff ? agentId : null,
      socket.data.user._id
    ].filter(Boolean));

    myUserIds.forEach(id => {
      socket.join(`user:${id}`);
    });

    const isAdminUser = role === 'admin';
    if (isAdminUser) {
      socket.join('admins');
      console.log(`[Gateway:${gatewayId}] Admin connected and joined admins room: ${emailId}`);
    }

    // Register presence in Redis (TTL 60s)
    for (const keyId of myUserIds) {
      await setPresence(keyId, gatewayId, 60);
    }

    // Auto-deliver all pending messages sent to this user while they were offline
    try {
      const userConvs = await Conversation.find({
        $or: [
          { participant1: { $in: Array.from(myUserIds) } },
          { participant2: { $in: Array.from(myUserIds) } },
          { agentId: { $in: Array.from(myUserIds) } },
          { emailId: { $in: Array.from(myUserIds) } }
        ]
      }, { _id: 1 });

      const convIds = userConvs.map(c => c._id);
      const undeliveredMessages = convIds.length > 0 ? await Message.find({
        conversationId: { $in: convIds },
        senderId: { $nin: Array.from(myUserIds) },
        status: 'sent'
      }) : [];

      if (undeliveredMessages.length > 0) {
        const messageIds = undeliveredMessages.map(m => m._id);
        
        await Message.updateMany(
          { _id: { $in: messageIds } },
          { $set: { status: 'delivered' } }
        );

        // Group by sender to notify them
        const senderGroups = {};
        for (const msg of undeliveredMessages) {
          if (!senderGroups[msg.senderId]) {
            senderGroups[msg.senderId] = [];
          }
          senderGroups[msg.senderId].push(msg._id);
        }

        // Notify each sender that their messages have been delivered
        for (const [senderId, msgIds] of Object.entries(senderGroups)) {
          for (const mId of msgIds) {
            io.to(`user:${senderId}`).emit('message:delivered', {
              messageId: mId,
              deliveredAt: new Date()
            });
          }
        }
      }
    } catch (err) {
      console.error(`[Gateway] Offline message delivery failure for ${emailId}:`, err);
    }

    // Periodic Heartbeat to renew presence TTL
    const heartbeatInterval = setInterval(async () => {
      try {
        for (const keyId of myUserIds) {
          await renewPresence(keyId, gatewayId, 60);
        }
      } catch (err) {
        console.error(`[Gateway] Heartbeat failed for ${emailId}:`, err.message);
      }
    }, 30000);

    // ----------------------------------------------------
    // Event: message:send
    // ----------------------------------------------------
    socket.on('message:send', async (data, ackCallback) => {
      try {
        // Rate limiting check
        const rateCheck = await checkRateLimit(emailId, 'message:send', 60, 60);
        if (!rateCheck.allowed) {
          const errPayload = { error: 'Rate limit exceeded for message:send' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        let { conversationId, recipientId, type = 'text', text, audio, image, recharge, withdraw } = data;

        if (!conversationId || !recipientId) {
          const errPayload = { error: 'conversationId and recipientId are required' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        if (!['text', 'voice', 'image', 'recharge', 'withdraw'].includes(type)) {
          const errPayload = { error: 'Invalid message type' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        if (type === 'text' && (!text || !text.trim())) {
          const errPayload = { error: 'Text message cannot be empty' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        if (type === 'voice' && (!audio || !audio.key)) {
          const errPayload = { error: 'Voice message audio key is required' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        if (type === 'image' && (!image || !image.key)) {
          const errPayload = { error: 'Image message image key is required' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        if (type === 'recharge' && (!recharge || !recharge.userId || !recharge.amount || !recharge.proofImage || (!recharge.transactionId && !recharge.utrNo))) {
          const errPayload = { error: 'Recharge message requires userId, amount, proofImage, and transactionId or utrNo' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        if (type === 'withdraw' && (!withdraw || !withdraw.userId || !withdraw.amount || !withdraw.bankDetails)) {
          const errPayload = { error: 'Withdraw message requires userId, amount, and bankDetails' };
          if (typeof ackCallback === 'function') ackCallback(errPayload);
          return socket.emit('error', errPayload);
        }

        const messageId = data._id || uuidv4();
        const createdAt = new Date();

        // Resolve sender unique participant ID
        let senderParticipantId = emailId;
        if (role === 'admin' || role === 'agent') {
          senderParticipantId = (agentId && !agentId.includes('@')) ? agentId : null;
          if (!senderParticipantId) {
            const agentDoc = await Agent.findOne({ $or: [{ emailId }, { _id: emailId }] });
            if (agentDoc) {
              senderParticipantId = agentDoc._id;
            } else {
              const numId = socket.data.user?.id || '1';
              senderParticipantId = role === 'admin' ? `ADMIN-${numId}` : `AGENCY-${numId}`;
            }
          }
        }

        // Resolve recipient unique participant ID
        let recipientParticipantId = recipientId;
        const recipientAgentDoc = await Agent.findOne({ $or: [{ _id: recipientId }, { emailId: recipientId }] });
        if (recipientAgentDoc) {
          recipientParticipantId = recipientAgentDoc._id;
        }

        const sorted = [senderParticipantId, recipientParticipantId].sort();
        const currentParticipant1 = sorted[0];
        const currentParticipant2 = sorted[1];
        if (!conversationId || conversationId.startsWith('conv-') || conversationId.startsWith('conv_')) {
          conversationId = `conv-${currentParticipant1}-${currentParticipant2}`;
        }

        // Validate Authorization according to the 3 rules:
        // Rule 1: Admin can send msg to all agency and user
        // Rule 2: Agency can send msg to admin and assigned user under him
        // Rule 3: User can send msg to his assigned agent and admin

        let isSenderAdmin = role === 'admin' ||
          String(emailId || '').toUpperCase().includes('ADMIN') ||
          String(agentId || '').toUpperCase().includes('ADMIN') ||
          String(senderParticipantId || '').toUpperCase().includes('ADMIN');

        if (!isSenderAdmin && (role === 'agent' || role === 'admin')) {
          const senderAgentDoc = await Agent.findOne({ $or: [{ _id: senderParticipantId }, { emailId }] });
          if (senderAgentDoc && (senderAgentDoc.type === 'ADMIN' || senderAgentDoc.role === 'admin')) {
            isSenderAdmin = true;
          }
        }

        let isRecipientAdmin = String(recipientId || '').toUpperCase().includes('ADMIN') ||
          String(recipientParticipantId || '').toUpperCase().includes('ADMIN');

        if (!isRecipientAdmin) {
          const targetAgent = await Agent.findOne({
            $or: [{ _id: recipientId }, { emailId: recipientId }, { _id: recipientParticipantId }]
          });
          if (targetAgent && (targetAgent.type === 'ADMIN' || targetAgent.role === 'admin')) {
            isRecipientAdmin = true;
          }
        }

        // Try to fetch existing conversation to lock participants
        const existingConv = await Conversation.findById(conversationId);
        if (existingConv) {
          // Enforce active participant authorization check (Admin can participate in any conversation)
          const isAuthParticipant = 
            isSenderAdmin ||
            emailId === existingConv.participant1 || 
            emailId === existingConv.participant2 || 
            senderParticipantId === existingConv.participant1 || 
            senderParticipantId === existingConv.participant2 ||
            (agentId && (agentId === existingConv.participant1 || agentId === existingConv.participant2));

          if (!isAuthParticipant) {
            const errPayload = { error: 'Unauthorized: You are not a participant in this conversation.' };
            if (typeof ackCallback === 'function') ackCallback(errPayload);
            return socket.emit('error', errPayload);
          }
        }

        // Rule 1: Admin can message anyone (all agencies and users)
        if (isSenderAdmin) {
          // Fully authorized
        } else if (role === 'user') {
          // Rule 3: User can send msg to his assigned agent and admin
          if (!isRecipientAdmin) {
            const userDoc = await User.findOne({ $or: [{ emailId }, { _id: emailId }, { id: socket.data.user?.id }] });
            const userAssignedAgentId = userDoc ? (userDoc.agentId || userDoc.agency_unq_id || userDoc.agency_id) : agentId;

            const cleanAssignedId = userAssignedAgentId ? String(userAssignedAgentId).trim() : '';
            const numAssignedId = cleanAssignedId.includes('-') ? cleanAssignedId.split('-').pop() : cleanAssignedId;

            const allowedAgentIds = new Set([
              agentId,
              cleanAssignedId,
              numAssignedId,
              cleanAssignedId ? `AGENCY-${numAssignedId}` : null,
              cleanAssignedId ? `agency-${numAssignedId}` : null
            ].filter(Boolean).map(id => String(id).toLowerCase()));

            const isAllowedAgent = allowedAgentIds.has(String(recipientId).toLowerCase()) ||
              allowedAgentIds.has(String(recipientParticipantId).toLowerCase());

            if (!isAllowedAgent) {
              const errPayload = { error: 'Unauthorized: Users can only message their assigned agent or admin.' };
              if (typeof ackCallback === 'function') ackCallback(errPayload);
              return socket.emit('error', errPayload);
            }
          }
        } else if (role === 'agent') {
          // Rule 2: Agency can send msg to admin and assigned user under him
          if (!isRecipientAdmin) {
            const recipientUser = await User.findOne({
              $or: [
                { emailId: recipientId },
                { _id: recipientId },
                { mob: recipientId },
                { id: isNaN(recipientId) ? -1 : Number(recipientId) }
              ]
            });

            if (!recipientUser) {
              const errPayload = { error: 'Unauthorized: Agents can only message their assigned users or admin.' };
              if (typeof ackCallback === 'function') ackCallback(errPayload);
              return socket.emit('error', errPayload);
            }

            const myAgentNum = (senderParticipantId && senderParticipantId.includes('-')) 
              ? senderParticipantId.split('-').pop() 
              : (agentId && agentId.includes('-') ? agentId.split('-').pop() : (socket.data.user?.id || ''));

            const myAgencyIds = new Set([
              senderParticipantId,
              agentId,
              emailId,
              String(myAgentNum),
              `AGENCY-${myAgentNum}`,
              `agency-${myAgentNum}`
            ].filter(Boolean).map(id => String(id).toLowerCase()));

            const userAgentIds = [
              recipientUser.agentId,
              recipientUser.agency_unq_id,
              recipientUser.agency_id,
              recipientUser.agency_id ? `AGENCY-${recipientUser.agency_id}` : null,
              recipientUser.agency_id ? `agency-${recipientUser.agency_id}` : null
            ].filter(Boolean).map(id => String(id).toLowerCase());

            const isAssigned = userAgentIds.some(id => myAgencyIds.has(id));

            if (!isAssigned) {
              const errPayload = { error: 'Unauthorized: You can only message users assigned under your agency.' };
              if (typeof ackCallback === 'function') ackCallback(errPayload);
              return socket.emit('error', errPayload);
            }
          }
        }

        // Dynamically determine recipientType based on whether the recipient is an agent
        let recipientType = (role === 'agent' || role === 'admin') ? 'user' : 'agent';
        try {
          const recipientAgent = await Agent.findOne({ $or: [{ emailId: recipientId }, { _id: recipientId }] });
          if (recipientAgent) {
            recipientType = 'agent';
          } else {
            const recipientUser = await User.findOne({ $or: [{ emailId: recipientId }, { _id: recipientId }] });
            if (recipientUser) {
              recipientType = 'user';
            }
          }
        } catch (dbErr) {
          console.error(`[Gateway] Error querying recipient type in MongoDB for ${recipientId}:`, dbErr.message);
        }

        const messagePayload = {
          _id: messageId,
          conversationId,
          senderId: senderParticipantId,
          senderType: role,
          type,
          text: type === 'text' ? text : undefined,
          audio: type === 'voice' ? audio : undefined,
          image: type === 'image' ? image : undefined,
          recharge: type === 'recharge' ? recharge : undefined,
          withdraw: type === 'withdraw' ? withdraw : undefined,
          status: 'sent',
          createdAt,
          participant1: currentParticipant1,
          participant2: currentParticipant2,
          recipientId,
          recipientType
        };

        // 1. Try real-time direct processing first
        try {
          await processStreamMessage(messageId, messagePayload);
        } catch (directErr) {
          console.warn('[Gateway] Direct message processing failed, falling back to Redis queue:', directErr.message);
          // 2. Fallback: ONLY queue into Redis stream if direct processing failed
          await enqueueMessage(messagePayload);
        }

        const responsePayload = {
          status: 'queued',
          messageId,
          conversationId,
          createdAt
        };

        if (typeof ackCallback === 'function') {
          ackCallback(null, responsePayload);
        }
        socket.emit('message:queued', responsePayload);
      } catch (err) {
        console.error(`[Gateway] Error in message:send for ${emailId}:`, err);
        if (typeof ackCallback === 'function') ackCallback({ error: err.message });
      }
    });

    // ----------------------------------------------------
    // Event: message:delivered
    // ----------------------------------------------------
    socket.on('message:delivered', async (data, ackCallback) => {
      try {
        const { messageId, conversationId, senderId } = data;
        if (!messageId || !senderId) return;

        // Update DB status to 'delivered'
        await Message.updateOne(
          { _id: messageId, status: 'sent' },
          { $set: { status: 'delivered' } }
        );

        // Relay receipt back to sender's room
        io.to(`user:${senderId}`).emit('message:delivered', {
          messageId,
          conversationId,
          deliveredAt: new Date()
        });

        if (typeof ackCallback === 'function') ackCallback(null, { success: true });
      } catch (err) {
        console.error(`[Gateway] Error in message:delivered for ${emailId}:`, err);
      }
    });

    // ----------------------------------------------------
    // Event: message:read
    // ----------------------------------------------------
    socket.on('message:read', async (data, ackCallback) => {
      try {
        const { conversationId, senderId, messageIds } = data;
        if (!conversationId) return;

        const readerIds = new Set([
          emailId,
          (role === 'agent' || role === 'admin') ? agentId : null,
          socket.data.user._id,
          socket.data.user.id ? String(socket.data.user.id) : null
        ].filter(Boolean));

        const conv = await Conversation.findById(conversationId);
        if (conv) {
          const isP1Reader = [conv.participant1, conv.agentId?._id || conv.agentId].some(id =>
            id && readerIds.has(String(id))
          );
          const isP2Reader = [conv.participant2, conv.emailId?._id || conv.emailId].some(id =>
            id && readerIds.has(String(id))
          );

          let unreadField = 'unread2';
          if (isP1Reader) {
            unreadField = 'unread1';
          } else if (isP2Reader) {
            unreadField = 'unread2';
          } else {
            unreadField = (role === 'agent' || role === 'admin') ? 'unread1' : 'unread2';
          }

          // 1. Reset unread counter for current reader in Conversation
          await Conversation.updateOne({ _id: conversationId }, { $set: { [unreadField]: 0 } });
        }

        // 2. Update messages in DB to 'read' (all messages not sent by reader)
        const filter = {
          conversationId,
          senderId: { $nin: Array.from(readerIds) },
          status: { $ne: 'read' }
        };

        if (Array.isArray(messageIds) && messageIds.length > 0) {
          filter._id = { $in: messageIds };
        }

        const result = await Message.updateMany(filter, { $set: { status: 'read' } });

        // 3. Relay read receipt back to sender's room
        const targetRoom = senderId ? `user:${senderId}` : (conv ? (role === 'agent' ? `user:${conv.participant2}` : `user:${conv.participant1}`) : null);

        if (targetRoom) {
          io.to(targetRoom).emit('message:read', {
            conversationId,
            readBy: emailId,
            messageIds: messageIds || [],
            modifiedCount: result.modifiedCount,
            readAt: new Date()
          });
        }

        if (typeof ackCallback === 'function') ackCallback(null, { success: true, count: result.modifiedCount });
      } catch (err) {
        console.error(`[Gateway] Error in message:read for ${emailId}:`, err);
      }
    });

    // ----------------------------------------------------
    // Event: presence:check
    // ----------------------------------------------------
    socket.on('presence:check', async (data, ackCallback) => {
      try {
        const targetEmailId = typeof data === 'string' ? data : data?.emailId;
        if (!targetEmailId) return;

        let online = await isOnline(targetEmailId);
        if (!online) {
          try {
            const agentDoc = await Agent.findOne({ $or: [{ _id: targetEmailId }, { emailId: targetEmailId }] });
            if (agentDoc) {
              if (agentDoc.emailId && agentDoc.emailId !== targetEmailId) {
                online = await isOnline(agentDoc.emailId);
              }
              if (!online && agentDoc._id && agentDoc._id !== targetEmailId) {
                online = await isOnline(agentDoc._id);
              }
            }
          } catch (dbErr) {
            console.warn('[Gateway] Presence fallback DB check warning:', dbErr.message);
          }
        }

        const result = { emailId: targetEmailId, isOnline: online };

        if (typeof ackCallback === 'function') ackCallback(null, result);
        socket.emit('presence:res', result);
      } catch (err) {
        console.error(`[Gateway] Error in presence:check for ${emailId}:`, err);
      }
    });

    // ----------------------------------------------------
    // Disconnect cleanup
    // ----------------------------------------------------
    socket.on('disconnect', async (reason) => {
      console.log(`[Gateway:${gatewayId}] Client disconnected: ${emailId} (${reason})`);
      clearInterval(heartbeatInterval);
      try {
        for (const keyId of myUserIds) {
          await removePresence(keyId);
        }
      } catch (err) {
        console.error(`[Gateway] Failed to remove presence for ${emailId}:`, err.message);
      }
    });
  });

  return io;
}

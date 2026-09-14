import { generatePresignedUploadUrl, generatePresignedDownloadUrl } from '../services/image.service.js';
import { Conversation } from '../models/Conversation.js';
import { Agent } from '../models/Agent.js';

async function isUserAuthorizedForConv(reqUser, conversationId) {
  if (!reqUser) return false;
  const currentUserId = reqUser.emailId || reqUser._id || reqUser.id;
  const userAgentId = reqUser.agentId;
  const userIds = new Set([
    currentUserId,
    reqUser.emailId,
    userAgentId,
    reqUser.id ? String(reqUser.id) : null,
    reqUser._id
  ].filter(Boolean));

  try {
    const agentDoc = await Agent.findOne({
      $or: [
        { _id: { $in: Array.from(userIds) } },
        { emailId: { $in: Array.from(userIds) } }
      ]
    });
    if (agentDoc) {
      if (agentDoc.type === 'ADMIN') return true;
      if (agentDoc._id) userIds.add(String(agentDoc._id));
      if (agentDoc.emailId) userIds.add(String(agentDoc.emailId));
      if (agentDoc.id) userIds.add(String(agentDoc.id));
    }
  } catch (e) {}

  if (reqUser.role === 'admin') return true;

  if (conversationId) {
    const conversation = await Conversation.findById(conversationId);
    if (conversation) {
      const isParticipant = [conversation.participant1, conversation.participant2, conversation.agentId, conversation.emailId].some(id =>
        id && userIds.has(String(id))
      );
      if (isParticipant) return true;
    }
    if (conversationId.startsWith('conv-')) {
      const isParticipantInId = Array.from(userIds).some(id =>
        id && (conversationId.includes(id) || conversationId.startsWith(`conv-${id}-`) || conversationId.endsWith(`-${id}`))
      );
      if (isParticipantInId) return true;
    }
  }

  return false;
}

export async function getImageUploadUrl(req, res) {
  try {
    let { conversationId, mimeType = 'image/jpeg' } = req.body;
    if (conversationId) conversationId = String(conversationId).trim();
    if (mimeType) mimeType = String(mimeType).trim();
    const senderId = req.user.emailId || req.user._id;

    if (!conversationId) {
      return res.status(400).json({ error: 'conversationId is required' });
    }

    const isAuth = await isUserAuthorizedForConv(req.user, conversationId);
    if (!isAuth) {
      return res.status(403).json({ error: 'Access denied: You are not a participant in this conversation' });
    }

    const presignedData = await generatePresignedUploadUrl({
      conversationId,
      senderId,
      mimeType
    });

    return res.json(presignedData);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

export async function getImagePlayUrl(req, res) {
  try {
    let { key } = req.query;
    if (!key) {
      return res.status(400).json({ error: 'key query parameter is required' });
    }
    key = String(key).trim();

    const parts = key.split('/');
    const conversationId = parts.length >= 2 ? parts[1] : null;

    const isAuth = await isUserAuthorizedForConv(req.user, conversationId);
    if (!isAuth) {
      return res.status(403).json({ error: 'Access denied: You are not a participant in this conversation' });
    }

    const data = await generatePresignedDownloadUrl({ fileKey: key });
    return res.json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

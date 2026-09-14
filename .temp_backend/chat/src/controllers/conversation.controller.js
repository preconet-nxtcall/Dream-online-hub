import { Conversation } from '../models/Conversation.js';
import { User } from '../models/User.js';
import { Agent } from '../models/Agent.js';
import { config } from '../config/env.js';
import { queryMysql } from '../config/mysql.js';

function formatAvatarUrl(url) {
  if (!url || typeof url !== 'string') return '';
  let clean = url.trim();
  clean = clean.replace(/^https?:\/\/(www\.)?(office-manage|fairbizcrm\.com|telewiz\.in)\/?/i, '/');
  clean = clean.replace(/^\/\/(office-manage|fairbizcrm\.com|telewiz\.in)\/?/i, '/');

  // Detect direct image filename (e.g. 1784376403_Agency.jpg) without folder path
  const stripped = clean.replace(/^\/+/, '');
  if (!stripped.includes('/') && /\.(jpe?g|png|webp|gif|avif|bmp|svg)$/i.test(stripped)) {
    clean = 'uploads/photos/' + stripped;
  } else if (clean.startsWith('photos/')) {
    clean = 'uploads/' + clean;
  }

  if (clean.startsWith('uploads/')) {
    clean = '/' + clean;
  }
  return clean;
}

export async function listConversations(req, res) {
  try {
    const currentUserId = req.user.emailId || req.user._id || req.user.id;
    const role = req.user.role || 'user';
    const isAdmin = role === 'admin';
    const isAgent = role === 'agent';

    // 1. Asynchronously sync users from MySQL database in background (non-blocking)
    (async () => {
      try {
        const isUserAdmin = isAdmin || String(currentUserId).toUpperCase().includes('ADMIN');
        let usersList = [];
        try {
          let sql = 'SELECT id, name, email, mob, img, type, show_status, agency_id, agency_unq_id FROM users';
          let params = [];
          if (!isUserAdmin) {
            const rawAgencyId = req.user.agentId || currentUserId;
            const cleanAgencyId = String(rawAgencyId).replace(/^(AGENCY-|ADMIN-)/i, '');
            sql += ' WHERE (agency_id = ? OR agency_unq_id = ? OR agency_id = ?) AND (type IS NULL OR type = \'\' OR type = \'USER\')';
            params = [cleanAgencyId, String(rawAgencyId), String(rawAgencyId)];
          }
          usersList = await queryMysql(sql, params);
        } catch (sqlErr) {
          console.warn('[Conversations] MySQL direct sync error, falling back to PHP:', sqlErr.message);
        }

        if (!usersList || usersList.length === 0) {
          const reqAction = isUserAdmin ? 'read_users' : 'read_agency_users';
          const reqBody = { action: reqAction, agency_id: req.user.agentId || currentUserId };
          const syncRes = await fetch(config.phpApiUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(reqBody)
          });
          if (syncRes.ok) {
            const syncData = await syncRes.json();
            if (syncData.success && Array.isArray(syncData.data)) {
              usersList = syncData.data;
            }
          }
        }

        if (Array.isArray(usersList) && usersList.length > 0) {
          const bulkOps = usersList
            .filter(u => String(u.type || '').toUpperCase() === 'USER' || !u.type)
            .map(u => ({
              updateOne: {
                filter: { _id: u.email || u.mob || String(u.id) },
                update: {
                  $set: {
                    id: u.id,
                    emailId: u.email || u.mob || String(u.id),
                    name: u.name,
                    mob: u.mob,
                    img: u.img || u.avatar || '',
                    agentId: u.agency_unq_id || (u.agency_id ? (String(u.agency_id).startsWith('AGENCY-') || String(u.agency_id).startsWith('ADMIN-') ? u.agency_id : `AGENCY-${u.agency_id}`) : ''),
                    status: 'active'
                  }
                },
                upsert: true
              }
            }));
          if (bulkOps.length > 0) {
            await User.bulkWrite(bulkOps);
          }
        }
      } catch (syncErr) {
        console.warn('[Conversations] Background sync notice:', syncErr.message);
      }
    })();

    // 2. Build conversation filter so a user only sees conversations where they are a participant
    const isStaffRole = role === 'agent' || role === 'admin';
    const userAgentId = req.user.agentId;
    const myParticipantIds = new Set([
      currentUserId,
      req.user.emailId,
      isStaffRole ? userAgentId : null,
      req.user.id ? String(req.user.id) : null,
      req.user._id
    ].filter(Boolean));

    try {
      const [agentDoc, userDoc] = await Promise.all([
        Agent.findOne({
          $or: [
            { _id: { $in: Array.from(myParticipantIds) } },
            { emailId: { $in: Array.from(myParticipantIds) } }
          ]
        }),
        User.findOne({
          $or: [
            { _id: { $in: Array.from(myParticipantIds) } },
            { emailId: { $in: Array.from(myParticipantIds) } }
          ]
        })
      ]);

      if (agentDoc) {
        if (agentDoc._id) myParticipantIds.add(String(agentDoc._id));
        if (agentDoc.emailId) myParticipantIds.add(String(agentDoc.emailId));
      }
      if (userDoc) {
        if (userDoc._id) myParticipantIds.add(String(userDoc._id));
        if (userDoc.emailId) myParticipantIds.add(String(userDoc.emailId));
      }
    } catch (e) {
      console.warn('[Conversations] Error resolving participant IDs:', e.message);
    }

    const participantIdList = Array.from(myParticipantIds);

    const filterConditions = [
      { participant1: { $in: participantIdList } },
      { participant2: { $in: participantIdList } },
      { emailId: { $in: participantIdList } }
    ];

    if (isStaffRole) {
      filterConditions.push({ agentId: { $in: participantIdList } });
    }

    const filter = { $or: filterConditions };

    const limit = parseInt(req.query.limit || '50', 10);
    const conversations = await Conversation.find(filter)
      .sort({ lastMessageAt: -1 })
      .limit(limit);

    let conversationsJson = conversations.map(c => c.toObject());

    // 3. Populate user and agent details for real conversations

    const allParticipantIds = [...new Set(conversationsJson.flatMap(c => [c.participant1, c.participant2]))].filter(Boolean);

    const userMap = new Map();
    const agentMap = new Map();

    if (allParticipantIds.length > 0) {
      const numericIds = allParticipantIds
        .map(id => id && id.includes('-') ? id.split('-').pop() : id)
        .filter(id => !isNaN(id) && id !== '')
        .map(id => Number(id));

      const [users, agents] = await Promise.all([
        User.find({
          $or: [
            { _id: { $in: allParticipantIds } },
            { emailId: { $in: allParticipantIds } },
            { mob: { $in: allParticipantIds } },
            { id: { $in: numericIds } }
          ]
        }),
        Agent.find({
          $or: [
            { _id: { $in: allParticipantIds } },
            { emailId: { $in: allParticipantIds } },
            { id: { $in: numericIds } }
          ]
        })
      ]);

      for (const u of users) {
        const uKey = u.emailId || u._id || u.email;
        const rawAvatar = u.avatar || u.img || '';
        const uObj = {
          _id: uKey,
          emailId: uKey,
          name: u.name || uKey,
          status: u.status,
          mob: u.mob,
          avatar: formatAvatarUrl(rawAvatar)
        };
        userMap.set(uKey, uObj);
        if (u._id) userMap.set(u._id, uObj);
        if (u.emailId) userMap.set(u.emailId, uObj);
        if (u.id) userMap.set(String(u.id), uObj);
        if (u.mob) userMap.set(String(u.mob), uObj);
      }

      for (const a of agents) {
        const key = a._id || a.emailId;
        const rawAvatar = a.avatar || a.img || '';
        const mappedAgentObj = {
          _id: key,
          emailId: a.emailId,
          name: a.name || key,
          status: a.status,
          avatar: formatAvatarUrl(rawAvatar)
        };
        agentMap.set(key, mappedAgentObj);
        if (a._id) agentMap.set(a._id, mappedAgentObj);
        if (a.emailId) agentMap.set(a.emailId, mappedAgentObj);
        if (a.id) {
          agentMap.set(String(a.id), mappedAgentObj);
          agentMap.set(`AGENCY-${a.id}`, mappedAgentObj);
          agentMap.set(`ADMIN-${a.id}`, mappedAgentObj);
        }
      }
    }

    // Populate user and agent details and construct legacy fields for backward-compatibility
    for (const c of conversationsJson) {
      const p1Details = userMap.get(c.participant1) || agentMap.get(c.participant1) || { emailId: c.participant1, name: 'Unknown Participant' };
      const p2Details = userMap.get(c.participant2) || agentMap.get(c.participant2) || { emailId: c.participant2, name: 'Unknown Participant' };

      c.participant1Details = p1Details;
      c.participant2Details = p2Details;

      if (!c.agentId || typeof c.agentId === 'string') {
        let agentDetails = null;
        let userDetails = null;
        let isP1Agent = false;

        if (agentMap.has(c.participant1)) {
          agentDetails = p1Details;
          userDetails = p2Details;
          isP1Agent = true;
        } else if (agentMap.has(c.participant2)) {
          agentDetails = p2Details;
          userDetails = p1Details;
          isP1Agent = false;
        } else {
          const isCurrentUserAgent = role === 'agent' || role === 'admin';
          if (isCurrentUserAgent) {
            if (c.participant1 === currentUserId) {
              agentDetails = p1Details;
              userDetails = p2Details;
              isP1Agent = true;
            } else {
              agentDetails = p2Details;
              userDetails = p1Details;
              isP1Agent = false;
            }
          } else {
            if (c.participant1 === currentUserId) {
              userDetails = p1Details;
              agentDetails = p2Details;
              isP1Agent = false;
            } else {
              userDetails = p2Details;
              agentDetails = p1Details;
              isP1Agent = true;
            }
          }
        }

        c.agentId = agentDetails;
        c.emailId = userDetails;
        c.unread = {
          agent: isP1Agent ? (c.unread1 || 0) : (c.unread2 || 0),
          user: isP1Agent ? (c.unread2 || 0) : (c.unread1 || 0)
        };
      }
    }

    return res.json({
      role: req.user.role,
      count: conversationsJson.length,
      conversations: conversationsJson
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

export async function createConversation(req, res) {
  try {
    const { recipientId } = req.body;
    if (!recipientId) {
      return res.status(400).json({ error: 'recipientId is required' });
    }

    const currentUserId = req.user.emailId || req.user._id || req.user.id;
    let senderParticipantId = currentUserId;
    if (req.user.role === 'admin' || req.user.role === 'agent') {
      senderParticipantId = (req.user.agentId && !req.user.agentId.includes('@')) ? req.user.agentId : currentUserId;
    }

    let recipientParticipantId = recipientId;
    const recipientAgentDoc = await Agent.findOne({ $or: [{ _id: recipientId }, { emailId: recipientId }] });
    if (recipientAgentDoc) {
      recipientParticipantId = recipientAgentDoc._id;
    }

    const sorted = [senderParticipantId, recipientParticipantId].sort();
    const p1 = sorted[0];
    const p2 = sorted[1];
    const conversationId = `conv-${p1}-${p2}`;

    let convAgentId = recipientParticipantId;
    let convEmailId = senderParticipantId;
    if (req.user.role === 'agent' || req.user.role === 'admin') {
      convAgentId = senderParticipantId;
      convEmailId = recipientParticipantId;
    }

    const conversation = await Conversation.findByIdAndUpdate(
      conversationId,
      {
        $setOnInsert: {
          _id: conversationId,
          participant1: p1,
          participant2: p2,
          agentId: convAgentId,
          emailId: convEmailId,
          lastMessage: 'Start a new conversation'
        },
        $set: {
          lastMessageAt: new Date()
        }
      },
      { upsert: true, new: true }
    );

    return res.json({
      success: true,
      conversation
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

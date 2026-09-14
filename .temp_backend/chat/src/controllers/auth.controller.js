import { v4 as uuidv4 } from 'uuid';
import { generateToken, verifyToken } from '../services/auth.service.js';
import { Agent } from '../models/Agent.js';
import { User } from '../models/User.js';
import { config } from '../config/env.js';
import { queryMysql } from '../config/mysql.js';

export async function login(req, res) {
  try {
    const { emailId, password } = req.body;
    if (!emailId) {
      return res.status(400).json({ error: 'emailId is required' });
    }

    let role = 'user';
    let agentId = null;
    let name = req.body.name;
    let foundId = emailId;

    // 1. Check if this is an admin bypass impersonation flow (no password, but role & name provided)
    if (password === undefined && req.body.role) {
      // Security Check: Verify that the caller is authenticated as an Agent/Admin
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Authorization header with Bearer token required for password bypass' });
      }

      const token = authHeader.split(' ')[1];
      const isFixedBypass = config.fixedApiToken && config.fixedApiToken.trim() !== '' && token === config.fixedApiToken;
      if (!isFixedBypass) {
        try {
          const decoded = verifyToken(token);
          if (decoded.role !== 'agent' && decoded.role !== 'admin') {
            return res.status(403).json({ error: 'Access denied: Only agents/admins can perform impersonation' });
          }
        } catch (err) {
          return res.status(401).json({ error: 'Invalid token: ' + err.message });
        }
      }

      const agent = await Agent.findOne({ $or: [{ _id: emailId }, { emailId }] });
      if (agent) {
        role = agent.type === 'ADMIN' ? 'admin' : 'agent';
        agentId = agent._id;
        foundId = agent._id;
        if (!name) name = agent.name;
      } else {
        const user = await User.findOne({ $or: [{ _id: emailId }, { emailId }] });
        if (user) {
          role = 'user';
          agentId = user.agentId;
          foundId = user._id;
          if (!name) name = user.name;
        } else {
          return res.status(400).json({ error: `Account with Email ID "${emailId}" not found in database.` });
        }
      }
    } else {
      // 2. Normal login flow (requires password)
      if (password === undefined) {
        return res.status(400).json({ error: 'Password is required' });
      }

      let remoteSuccess = false;
      let remoteData = null;
      let remoteStatus = 200;

      try {
        const isMobile = /^\d+$/.test(emailId);
        const reqBody = {
          action: 'login',
          password: password
        };
        if (isMobile) {
          reqBody.mob = emailId;
        } else {
          reqBody.email = emailId;
        }

        const remoteRes = await fetch(config.phpApiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(reqBody)
        });
        remoteStatus = remoteRes.status;
        remoteData = await remoteRes.json();
        if (remoteRes.ok && remoteData && remoteData.success) {
          remoteSuccess = true;
        }
      } catch (err) {
        console.error('[Auth API] External API connection failed:', err.message);
      }

      if (remoteSuccess && remoteData && remoteData.user) {
        const remoteUser = remoteData.user;
        const remoteRole = String(remoteUser.role || '').toUpperCase();
        if (remoteRole === 'ADMIN') {
          role = 'admin';
        } else if (remoteRole === 'AGENCY') {
          role = 'agent';
        } else if (remoteRole === 'USER') {
          role = 'user';
        } else {
          return res.status(403).json({ error: `Access denied: Account type "${remoteRole || 'unknown'}" is not supported.` });
        }

        const email = remoteUser.email || emailId;
        const rawAvatar = remoteUser.avatar || remoteData.avatar || '';
        const avatar = (rawAvatar && rawAvatar !== 'null' && rawAvatar !== 'undefined') ? rawAvatar : '';
        const mob = remoteUser.mob || remoteUser.mobile || remoteUser.phone || '';
        const displayName = remoteUser.name || name || email;

        let existingUser = null;
        if (role === 'user') {
          existingUser = await User.findOne({ $or: [{ _id: email }, { emailId: email }] });
        }

        if (role === 'agent' || role === 'admin') {
          const agencyUnqId = remoteUser.agency_unq_id || (remoteRole === 'ADMIN' && remoteUser.id ? `ADMIN-${remoteUser.id}` : (remoteRole === 'AGENCY' && remoteUser.id ? `AGENCY-${remoteUser.id}` : remoteUser.id || email));
          foundId = agencyUnqId;
          agentId = agencyUnqId;
          name = displayName;

          await Agent.findByIdAndUpdate(
            agencyUnqId,
            {
              id: remoteUser.id,
              emailId: email,
              password: password,
              name: displayName,
              img: avatar,
              mob: mob,
              status: 'active'
            },
            { upsert: true }
          );
        } else {
          // It's a player/user
          foundId = email;
          const userAgencyId = remoteUser.agency_id || (existingUser ? existingUser.agency_id : '') || '';
          let userAgencyUnqId = remoteUser.agency_unq_id || (existingUser ? existingUser.agency_unq_id : '');
          if (!userAgencyUnqId && userAgencyId) {
            const agentDoc = await Agent.findOne({ id: Number(userAgencyId) });
            userAgencyUnqId = agentDoc ? agentDoc._id : (userAgencyId == 1 || userAgencyId == '1' ? 'ADMIN-1' : `AGENCY-${userAgencyId}`);
          }
          agentId = userAgencyUnqId || (userAgencyId ? (userAgencyId == 1 || userAgencyId == '1' ? 'ADMIN-1' : `AGENCY-${userAgencyId}`) : '');
          name = displayName;

          await User.findByIdAndUpdate(
            email,
            {
              id: remoteUser.id,
              emailId: email,
              password: password,
              name: displayName,
              img: avatar,
              mob: mob,
              agency_id: userAgencyId,
              agency_unq_id: userAgencyUnqId,
              agentId: userAgencyUnqId,
              status: 'active'
            },
            { upsert: true }
          );
        }

        // Run Role-Based User/Agent Synchronization
        try {
          if (remoteRole === 'ADMIN') {
            let syncUsers = null;
            try {
              syncUsers = await queryMysql('SELECT id, name, email, mob, img, type, show_status, agency_id, agency_unq_id FROM users');
            } catch (sqlErr) {
              console.warn('[Login Sync] MySQL direct query error, falling back to PHP:', sqlErr.message);
            }

            if (!syncUsers || syncUsers.length === 0) {
              const syncRes = await fetch(config.phpApiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'read_users' })
              });
              if (syncRes.ok) {
                const syncData = await syncRes.json();
                if (syncData.success && Array.isArray(syncData.data)) {
                  syncUsers = syncData.data;
                }
              }
            }

            if (Array.isArray(syncUsers) && syncUsers.length > 0) {
              // Pre-build agency unique ID map
              const agencyMap = {};
              for (const u of syncUsers) {
                const uType = String(u.type || '').toUpperCase();
                if (uType === 'ADMIN' || uType === 'AGENCY') {
                  agencyMap[String(u.id)] = u.agency_unq_id || (uType === 'ADMIN' ? `ADMIN-${u.id}` : `AGENCY-${u.id}`);
                }
              }

              for (const u of syncUsers) {
                const uType = String(u.type || '').toUpperCase();
                const uStatus = String(u.show_status || u.status || 'ACTIVE').toUpperCase();
                const uImg = u.img || u.avatar || '';

                if (uType === 'ADMIN' || uType === 'AGENCY') {
                  const agencyUnqId = u.agency_unq_id || (uType === 'ADMIN' ? `ADMIN-${u.id}` : `AGENCY-${u.id}`);
                  await Agent.findByIdAndUpdate(
                    agencyUnqId,
                    {
                      id: u.id,
                      emailId: u.email,
                      name: u.name,
                      mob: u.mob,
                      img: uImg,
                      type: uType,
                      status: uStatus === 'ACTIVE' ? 'active' : 'inactive'
                    },
                    { upsert: true }
                  );
                } else if (uType === 'USER' || !uType || uType === '') {
                  const existingUser = await User.findOne({ $or: [{ _id: u.email }, { emailId: u.email }] });
                  let userAgencyId = u.agency_id || '';
                  let userAgencyUnqId = u.agency_unq_id || agencyMap[String(userAgencyId)] || '';
                  if (!userAgencyUnqId && userAgencyId) {
                    const agentDoc = await Agent.findOne({ id: Number(userAgencyId) });
                    userAgencyUnqId = agentDoc ? agentDoc._id : '';
                  }

                  if (!u.agency_id && existingUser && (existingUser.agency_id || existingUser.agency_unq_id)) {
                    userAgencyId = existingUser.agency_id || '';
                    userAgencyUnqId = existingUser.agency_unq_id || '';
                  }

                  await User.findByIdAndUpdate(
                    u.email,
                    {
                      id: u.id,
                      emailId: u.email,
                      name: u.name,
                      mob: u.mob,
                      img: uImg,
                      agency_id: userAgencyId,
                      agency_unq_id: userAgencyUnqId,
                      agentId: userAgencyUnqId,
                      type: 'USER',
                      status: uStatus === 'ACTIVE' ? 'active' : 'inactive'
                    },
                    { upsert: true }
                  );
                }
              }
            }
          } else if (remoteRole === 'AGENCY' && remoteUser.id) {
            let syncUsers = null;
            try {
              syncUsers = await queryMysql(
                'SELECT id, name, email, mob, img, type, show_status, agency_id, agency_unq_id FROM users WHERE (agency_id = ? OR agency_unq_id = ? OR id = ?)',
                [String(remoteUser.id), `AGENCY-${remoteUser.id}`, Number(remoteUser.id)]
              );
            } catch (sqlErr) {
              console.warn('[Login Sync] MySQL direct query error, falling back to PHP:', sqlErr.message);
            }

            if (!syncUsers || syncUsers.length === 0) {
              const syncRes = await fetch(config.phpApiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'get_by_agency_id', agency_id: String(remoteUser.id) })
              });
              if (syncRes.ok) {
                const syncData = await syncRes.json();
                if (syncData.success && Array.isArray(syncData.data)) {
                  syncUsers = syncData.data;
                }
              }
            }

            if (Array.isArray(syncUsers) && syncUsers.length > 0) {
              // Pre-build agency unique ID map
              const agencyMap = {};
              for (const u of syncUsers) {
                const uType = String(u.type || '').toUpperCase();
                if (uType === 'ADMIN' || uType === 'AGENCY') {
                  agencyMap[String(u.id)] = u.agency_unq_id || (uType === 'ADMIN' ? `ADMIN-${u.id}` : `AGENCY-${u.id}`);
                }
              }

              for (const u of syncUsers) {
                const uType = String(u.type || '').toUpperCase();
                const uStatus = String(u.show_status || u.status || 'ACTIVE').toUpperCase();
                const uImg = u.img || u.avatar || '';

                if (uType === 'ADMIN' || uType === 'AGENCY') {
                  const agencyUnqId = u.agency_unq_id || (uType === 'ADMIN' ? `ADMIN-${u.id}` : `AGENCY-${u.id}`);
                  await Agent.findByIdAndUpdate(
                    agencyUnqId,
                    {
                      id: u.id,
                      emailId: u.email,
                      name: u.name,
                      mob: u.mob,
                      img: uImg,
                      type: uType,
                      status: uStatus === 'ACTIVE' ? 'active' : 'inactive'
                    },
                    { upsert: true }
                  );
                } else if (uType === 'USER' || !uType || uType === '') {
                  const userAgencyId = u.agency_id || String(remoteUser.id);
                  const userAgencyUnqId = u.agency_unq_id || agencyMap[String(userAgencyId)] || `AGENCY-${userAgencyId}`;
                  await User.findByIdAndUpdate(
                    u.email,
                    {
                      id: u.id,
                      emailId: u.email,
                      name: u.name,
                      mob: u.mob,
                      img: uImg,
                      agency_id: userAgencyId,
                      agency_unq_id: userAgencyUnqId,
                      agentId: userAgencyUnqId,
                      type: 'USER',
                      status: uStatus === 'ACTIVE' ? 'active' : 'inactive'
                    },
                    { upsert: true }
                  );
                }
              }
            }
          } else if (role === 'user' && (remoteUser.agency_id || (existingUser && existingUser.agency_id))) {
            const syncAgencyId = remoteUser.agency_id || (existingUser && existingUser.agency_id);
            const syncRes = await fetch(config.phpApiUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ action: 'get_by_agency_id', agency_id: String(syncAgencyId) })
            });
            if (syncRes.ok) {
              const syncData = await syncRes.json();
              if (syncData.success && Array.isArray(syncData.data)) {
                // Pre-build agency unique ID map
                const agencyMap = {};
                for (const u of syncData.data) {
                  const uType = String(u.type || '').toUpperCase();
                  if (uType === 'ADMIN' || uType === 'AGENCY') {
                    agencyMap[String(u.id)] = u.agency_unq_id || (uType === 'ADMIN' ? `ADMIN-${u.id}` : `AGENCY-${u.id}`);
                  }
                }

                for (const u of syncData.data) {
                  const uType = String(u.type || '').toUpperCase();
                  const uStatus = String(u.show_status || u.status || 'ACTIVE').toUpperCase();
                  if (uType === 'ADMIN' || uType === 'AGENCY') {
                    const agencyUnqId = u.agency_unq_id || (uType === 'ADMIN' ? `ADMIN-${u.id}` : `AGENCY-${u.id}`);
                    await Agent.findByIdAndUpdate(
                      agencyUnqId,
                      {
                        id: u.id,
                        emailId: u.email,
                        name: u.name,
                        mob: u.mob,
                        type: uType,
                        status: uStatus === 'ACTIVE' ? 'active' : 'inactive'
                      },
                      { upsert: true }
                    );
                  } else if (uType === 'USER') {
                    const userAgencyIdVal = u.agency_id || String(remoteUser.agency_id);
                    let userAgencyUnqIdVal = u.agency_unq_id || agencyMap[String(userAgencyIdVal)] || '';
                    if (!userAgencyUnqIdVal && userAgencyIdVal) {
                      const agentDoc = await Agent.findOne({ id: Number(userAgencyIdVal) });
                      userAgencyUnqIdVal = agentDoc ? agentDoc._id : '';
                    }
                    await User.findByIdAndUpdate(
                      u.email,
                      {
                        id: u.id,
                        emailId: u.email,
                        name: u.name,
                        mob: u.mob,
                        agency_id: userAgencyIdVal,
                        agency_unq_id: userAgencyUnqIdVal,
                        agentId: userAgencyUnqIdVal,
                        type: 'USER',
                        status: uStatus === 'ACTIVE' ? 'active' : 'inactive'
                      },
                      { upsert: true }
                    );
                  }
                }
              }
            }
          }

          // Clean up legacy/incorrect entries in User collection (where their email matches an Agent)
          const agentEmails = (await Agent.find({}, 'emailId')).map(a => a.emailId).filter(Boolean);
          if (agentEmails.length > 0) {
            await User.deleteMany({ $or: [{ _id: { $in: agentEmails } }, { emailId: { $in: agentEmails } }] });
          }
        } catch (syncErr) {
          console.error('[Auth Sync] External sync failed:', syncErr.message);
        }
      } else {
        // If account is suspended or inactive on remote API, block login immediately
        if (remoteStatus === 403) {
          return res.status(403).json({ error: (remoteData && remoteData.message) || 'Account is suspended or inactive.' });
        }

        // If API data is incomplete, return 400 immediately
        if (remoteStatus === 400) {
          return res.status(400).json({ error: (remoteData && remoteData.message) || 'Incomplete data. Please provide email/mobile and password.' });
        }

        // If remote validation failed, return the remote API's error response immediately
        const errMsg = (remoteData && remoteData.message) || 'Invalid email/mobile or password.';
        const errStatus = remoteStatus === 404 ? 401 : (remoteStatus || 401);
        return res.status(errStatus).json({ error: errMsg });
      }
    }

    const token = generateToken({
      emailId: foundId,
      role,
      agentId,
      name: name || `${role}_${foundId}`
    });

    // Set token in cookie for server-side page routing
    res.cookie('token', token, {
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
      httpOnly: false, // allow client-side to read if needed
      path: '/'
    });

     let dbUser = null;
    if (role === 'agent' || role === 'admin') {
      dbUser = await Agent.findOne({ $or: [{ _id: foundId }, { emailId: foundId }] });
    } else {
      dbUser = await User.findOne({ $or: [{ _id: foundId }, { emailId: foundId }] });
    }

    const actualEmail = dbUser ? dbUser.emailId : (emailId || foundId);
    const actualMob = dbUser ? (dbUser.mob || dbUser.mobile || '') : '';
    const actualAvatar = dbUser ? (dbUser.avatar || '') : '';
    const actualName = dbUser ? (dbUser.name || name) : (name || `${role}_${foundId}`);

    return res.json({
      token,
      avatar: actualAvatar,
      user: {
        _id: foundId,
        emailId: actualEmail,
        mob: actualMob,
        role,
        agentId,
        name: actualName,
        avatar: actualAvatar
      }
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

/**
 * Sync user/agent data into MongoDB when user logs in on PHP login page.
 */
export async function syncUser(req, res) {
  try {
    const { id, user_id, email, emailId, mob, name, agency_id, agency_unq_id, type, role, show_status, status, img, avatar, password } = req.body;

    const userEmail = email || emailId || mob;
    const userId = id || user_id;

    if (!userEmail && !userId) {
      return res.status(400).json({ success: false, error: 'User identifier (email, mob, or id) is required' });
    }

    let userRole = String(type || role || 'USER').toUpperCase();

    let userData = {
      id: userId,
      emailId: userEmail,
      name: name || userEmail,
      mob: mob || '',
      agency_id: agency_id || '',
      agency_unq_id: agency_unq_id || '',
      status: status || show_status || 'ACTIVE',
      img: img || avatar || ''
    };

    // If details are sparse and PHP API is reachable, query fresh details from PHP API
    if (config.phpApiUrl && (!userData.name || !userData.agency_id || !userData.emailId)) {
      try {
        const fetchRes = await fetch(config.phpApiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ action: 'read_users' })
        });
        if (fetchRes.ok) {
          const fetchJson = await fetchRes.json();
          if (fetchJson.success && Array.isArray(fetchJson.data)) {
            const matched = fetchJson.data.find(u =>
              (userId && String(u.id) === String(userId)) ||
              (userEmail && (u.email === userEmail || u.mob === userEmail))
            );
            if (matched) {
              userData.id = matched.id || userData.id;
              userData.emailId = matched.email || matched.mob || userData.emailId;
              userData.name = matched.name || userData.name;
              userData.mob = matched.mob || userData.mob;
              userData.agency_id = matched.agency_id || userData.agency_id;
              userData.agency_unq_id = matched.agency_unq_id || userData.agency_unq_id;
              userData.status = matched.show_status || matched.status || userData.status;
              userData.img = matched.img || userData.img;
              userRole = String(matched.type || userRole).toUpperCase();
            }
          }
        }
      } catch (fetchErr) {
        console.error('[syncUser] Fetching from PHP API failed:', fetchErr.message);
      }
    }

    if (userRole === 'ADMIN' || userRole === 'AGENCY') {
      const agencyUnqId = userData.agency_unq_id || (userRole === 'ADMIN' ? `ADMIN-${userData.id}` : `AGENCY-${userData.id}`);
      const updatedAgent = await Agent.findByIdAndUpdate(
        agencyUnqId,
        {
          id: userData.id,
          emailId: userData.emailId,
          name: userData.name,
          mob: userData.mob,
          password: password || '',
          img: userData.img,
          type: userRole,
          status: userData.status
        },
        { upsert: true }
      );

      // Clean up legacy entry in User collection if any
      await User.deleteMany({ $or: [{ _id: userData.emailId }, { emailId: userData.emailId }] });

      return res.json({
        success: true,
        message: 'Agent synced successfully to MongoDB',
        user: updatedAgent
      });
    } else if (userRole === 'USER') {
      // User / Player
      let userAgencyId = userData.agency_id || '';
      let userAgencyUnqId = userData.agency_unq_id || '';
      if (!userAgencyUnqId && userAgencyId) {
        const agentDoc = await Agent.findOne({ id: Number(userAgencyId) });
        if (agentDoc) {
          userAgencyUnqId = agentDoc._id;
        } else {
          userAgencyUnqId = `AGENCY-${userAgencyId}`;
        }
      }

      const updatedUser = await User.findByIdAndUpdate(
        userData.emailId,
        {
          id: userData.id,
          emailId: userData.emailId,
          name: userData.name,
          mob: userData.mob,
          password: password || '',
          img: userData.img,
          agency_id: userAgencyId,
          agency_unq_id: userAgencyUnqId,
          agentId: userAgencyUnqId,
          type: 'USER',
          status: userData.status
        },
        { upsert: true }
      );

      return res.json({
        success: true,
        message: 'User synced successfully to MongoDB',
        user: updatedUser
      });
    } else {
      return res.json({
        success: false,
        message: `Ignored sync for non-chat account type: ${userRole}`
      });
    }
  } catch (err) {
    console.error('[syncUser] Error syncing user:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
 * GET /api/v1/auth/me
 * Direct MySQL On-Demand Sync: pulls fresh profile (name, mob, img) directly from MySQL,
 * synchronizes MongoDB in the background, and returns the real-time profile data.
 */
export async function getMe(req, res) {
  try {
    const email = req.user.emailId || req.user._id || req.user.id;
    const role = req.user.role || 'user';
    const agentId = req.user.agentId || null;

    let sqlUser = null;
    try {
      // 1. Fetch directly from MySQL users table for 100% real-time data
      const rows = await queryMysql(
        'SELECT id, name, email, mob, img, type, show_status, agency_id, agency_unq_id FROM users WHERE email = ? OR mob = ? OR id = ? LIMIT 1',
        [String(email), String(email), !isNaN(email) ? Number(email) : -1]
      );
      if (rows && rows.length > 0) {
        sqlUser = rows[0];
      }
    } catch (sqlErr) {
      console.warn('[getMe] MySQL direct query error, falling back to Mongo:', sqlErr.message);
    }

    // 2. If found in MySQL, update Mongo in background and return fresh data
    if (sqlUser) {
      const uType = String(sqlUser.type || '').toUpperCase();
      const isStaff = uType === 'ADMIN' || uType === 'AGENCY' || role === 'agent' || role === 'admin';
      const userMob = sqlUser.mob || '';
      const userImg = sqlUser.img || '';
      const userName = sqlUser.name || req.user.name || email;

      if (isStaff) {
        const agencyUnqId = sqlUser.agency_unq_id || (uType === 'ADMIN' ? (sqlUser.id == 1 ? 'ADMIN-1' : `ADMIN-${sqlUser.id}`) : `AGENCY-${sqlUser.id}`) || req.user.agentId || email;
        Agent.findByIdAndUpdate(
          agencyUnqId,
          {
            id: sqlUser.id,
            emailId: sqlUser.email,
            name: userName,
            mob: userMob,
            img: userImg,
            type: uType,
            status: String(sqlUser.show_status || 'ACTIVE').toUpperCase() === 'ACTIVE' ? 'active' : 'inactive'
          },
          { upsert: true }
        ).catch(err => console.warn('[getMe] Mongo Agent update error:', err.message));
      } else {
        User.findByIdAndUpdate(
          sqlUser.email,
          {
            id: sqlUser.id,
            emailId: sqlUser.email,
            name: userName,
            mob: userMob,
            img: userImg,
            agency_id: sqlUser.agency_id || '',
            agency_unq_id: sqlUser.agency_unq_id || '',
            agentId: sqlUser.agency_unq_id || (sqlUser.agency_id ? `AGENCY-${sqlUser.agency_id}` : ''),
            status: String(sqlUser.show_status || 'ACTIVE').toUpperCase() === 'ACTIVE' ? 'active' : 'inactive'
          },
          { upsert: true }
        ).catch(err => console.warn('[getMe] Mongo User update error:', err.message));
      }

      return res.json({
        success: true,
        user: {
          _id: req.user._id || req.user.emailId || sqlUser.email,
          id: sqlUser.id,
          name: userName,
          email: sqlUser.email,
          emailId: sqlUser.email,
          mob: userMob,
          phone: userMob,
          img: userImg,
          avatar: userImg,
          role,
          agentId: req.user.agentId || sqlUser.agency_unq_id || null
        }
      });
    }

    // 3. Fallback to MongoDB if MySQL is unreachable or row not found
    let dbUser = null;
    if (role === 'agent' || role === 'admin') {
      dbUser = await Agent.findOne({ $or: [{ _id: email }, { emailId: email }] });
    } else {
      dbUser = await User.findOne({ $or: [{ _id: email }, { emailId: email }] });
    }

    return res.json({
      success: true,
      user: {
        _id: req.user._id || email,
        id: dbUser ? dbUser.id : null,
        name: dbUser ? dbUser.name : (req.user.name || 'User'),
        email: dbUser ? dbUser.emailId : email,
        emailId: dbUser ? dbUser.emailId : email,
        mob: dbUser ? (dbUser.mob || '') : '',
        phone: dbUser ? (dbUser.mob || '') : '',
        img: dbUser ? (dbUser.img || '') : '',
        avatar: dbUser ? (dbUser.avatar || dbUser.img || '') : '',
        role,
        agentId
      }
    });
  } catch (err) {
    console.error('[getMe] Error:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}




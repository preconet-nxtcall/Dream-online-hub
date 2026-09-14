import { v4 as uuidv4 } from 'uuid';
import { config } from '../config/env.js';
import { User } from '../models/User.js';
import { Agent } from '../models/Agent.js';
import { Conversation } from '../models/Conversation.js';
import { enqueueMessage } from '../queue/streamProducer.js';

export async function generateQrCode(req, res) {
  try {
    const { userId, bookId = 324, amount } = req.body;

    if (!userId || !amount) {
      return res.status(400).json({ error: 'userId and amount are required' });
    }

    // Lookup user to resolve their numeric agency ID
    const user = await User.findOne({
      $or: [
        { _id: userId },
        { emailId: userId },
        { id: Number(userId) || -1 }
      ]
    });
    let agencyIdNum = 23;
    if (user) {
      const rawAgencyId = user.agency_id || user.agency_unq_id || '';
      if (rawAgencyId) {
        let numericPart = rawAgencyId;
        if (rawAgencyId.includes('-')) {
          const parts = rawAgencyId.split('-');
          numericPart = parts[parts.length - 1];
        }
        const parsed = parseInt(numericPart, 10);
        if (!isNaN(parsed)) {
          agencyIdNum = parsed;
        }
      }
    }

    const payload = {
      action: 'get_qr_code',
      book_id: Number(bookId),
      agency_id: agencyIdNum,
      amount: Number(amount)
    };

    console.log(`[RechargeController] Contacting PHP API at ${config.phpApiUrl} for QR generation:`, payload);

    let qrUrl = null;
    let qrId = null;
    let rangeId = null;
    let empId = null;
    let qrAvailable = false;
    let message = 'QR code generated successfully';

    try {
      const response = await fetch(config.phpApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        const responseText = await response.text();
        let result = null;
        try {
          result = JSON.parse(responseText);
        } catch (e) {
          console.warn('[RechargeController] PHP API non-JSON response in generateQrCode:', responseText);
        }
        if (result && result.success) {
          if (result.qr_available) {
            qrUrl = result.qr_image_url;
            qrId = result.qr_id;
            rangeId = result.range_id;
            empId = result.emp_id;
            qrAvailable = true;
            message = result.message || message;
          } else {
            // Cash transaction only
            return res.json({
              success: true,
              qr_available: false,
              qr_id: null,
              message: result.message || 'Only Cash Transaction Available.'
            });
          }
        }
      }
    } catch (apiErr) {
      console.warn('[RechargeController] PHP API connection failed, falling back to mock QR code:', apiErr.message);
    }

    if (!qrUrl) {
      return res.json({
        success: false,
        qr_available: false,
        message: 'Having trouble generating QR code. Please try again later.'
      });
    }

    return res.json({
      success: true,
      qr_available: qrAvailable,
      qr_url: qrUrl,
      qr_id: qrId,
      range_id: rangeId,
      emp_id: empId,
      message
    });
  } catch (err) {
    console.error('[RechargeController] Error in generateQrCode:', err);
    return res.status(500).json({ error: err.message });
  }
}

export async function submitRecharge(req, res) {
  try {
    console.log("inside submit recharge fn");
    const { userId, qrId, rangeId, amount, empId, bookId, utr, utrNo = utr || req.body.transactionId, image } = req.body;

    if (!userId || !amount || !utrNo || !image) {
      return res.status(400).json({ error: 'userId, amount, utrNo, and image are required' });
    }

    // Lookup user to resolve their numeric user ID (id)
    const user = await User.findOne({
      $or: [
        { _id: userId },
        { emailId: userId },
        { id: Number(userId) || -1 }
      ]
    });
    const resolvedUserId = (user && user.id) ? user.id : userId;

    const payload = {
      action: 'recharge_by_user',
      user_id: resolvedUserId,
      qr_id: qrId ? Number(qrId) : null,
      range_id: rangeId ? Number(rangeId) : null,
      amount: Number(amount),
      emp_id: empId ? Number(empId) : null,
      book_id: bookId ? Number(bookId) : null,
      transaction_id: utrNo, // PHP API expects UTR number in transaction_id field when user submits recharge
      image: image // Base64 string
    };

    console.log(`[RechargeController] Submitting recharge to PHP API at ${config.phpApiUrl}:`, {
      ...payload,
      image: payload.image ? `${payload.image.substring(0, 30)}...` : null
    });

    const response = await fetch(config.phpApiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const responseText = await response.text();
    let result;
    try {
      result = JSON.parse(responseText);
    } catch (parseErr) {
      console.error('[RechargeController] PHP API returned non-JSON response:', responseText);
      const cleanText = responseText.replace(/<[^>]*>/g, '').trim() || responseText;
      return res.status(500).json({
        error: `PHP API error: ${cleanText.substring(0, 200)}`
      });
    }

    if (!response.ok || (result && result.success === false)) {
      return res.status(response.ok ? 400 : response.status).json({
        error: result.message || result.error || `PHP API returned status ${response.status}`
      });
    }

    const phpRechargeId = result.recharge_id || result.id || null;

    return res.json({
      ...result,
      recharge_id: phpRechargeId,
      transactionId: phpRechargeId, // PHP-generated Transaction ID exclusively
      utrNo: utrNo
    });
  } catch (err) {
    console.error('[RechargeController] Error in submitRecharge:', err);
    return res.status(500).json({ error: err.message });
  }
}

export async function getPaymentAccount(req, res) {
  try {
    const userId = req.user?.id || req.user?._id || req.query.userId || req.body.userId;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    // Lookup user to resolve numeric ID if needed
    const user = await User.findOne({
      $or: [
        { _id: userId },
        { emailId: userId },
        { id: Number(userId) || -1 }
      ]
    });
    const resolvedUserId = (user && user.id) ? user.id : (Number(userId) || userId);

    const payload = {
      action: 'get_payment_account',
      user_id: resolvedUserId
    };

    console.log(`[RechargeController] Fetching payment account for user ${resolvedUserId} from PHP API at ${config.phpApiUrl}`);

    const response = await fetch(config.phpApiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const responseText = await response.text();
    let result;
    try {
      result = JSON.parse(responseText);
    } catch (parseErr) {
      console.error('[RechargeController] PHP API returned non-JSON response in getPaymentAccount:', responseText);
      const cleanText = responseText.replace(/<[^>]*>/g, '').trim() || responseText;
      return res.status(500).json({
        error: `PHP API error: ${cleanText.substring(0, 200)}`
      });
    }

    if (result && result.data) {
      if (result.data.image) {
        let clean = String(result.data.image_url || result.data.image).trim();
        clean = clean.replace(/^https?:\/\/(www\.)?(office-manage|fairbizcrm\.com|telewiz\.in)\/?/i, '/');
        clean = clean.replace(/^\/\/(office-manage|fairbizcrm\.com|telewiz\.in)\/?/i, '/');
        const stripped = clean.replace(/^\/+/, '');
        if (!stripped.includes('/') && /\.(jpe?g|png|webp|gif|avif|bmp|svg)$/i.test(stripped)) {
          clean = '/uploads/photos/' + stripped;
        } else if (clean.startsWith('photos/')) {
          clean = '/uploads/' + clean;
        } else if (clean.startsWith('uploads/')) {
          clean = '/' + clean;
        }
        result.data.image_url = clean;
      }
    }

    return res.json(result);
  } catch (err) {
    console.error('[RechargeController] Error in getPaymentAccount:', err);
    return res.status(500).json({ error: err.message });
  }
}

export async function submitWithdraw(req, res) {
  try {
    const { userId = req.user?.id || req.user?._id, bookId, amount, detail = '', image = '' } = req.body;

    if (!userId || !bookId || !amount) {
      return res.status(400).json({ error: 'userId, bookId, and amount are required' });
    }

    // Lookup user to resolve their numeric user ID (id)
    const user = await User.findOne({
      $or: [
        { _id: userId },
        { emailId: userId },
        { id: Number(userId) || -1 }
      ]
    });
    const resolvedUserId = (user && user.id) ? user.id : userId;

    const payload = {
      action: 'user_withdraw',
      user_id: resolvedUserId,
      book_id: Number(bookId),
      amount: Number(amount),
      deatil: detail,
      image: image // Base64 string or image filename
    };

    console.log(`[RechargeController] Submitting withdraw to PHP API at ${config.phpApiUrl}:`, {
      ...payload,
      image: payload.image ? `${payload.image.substring(0, 30)}...` : null
    });

    const response = await fetch(config.phpApiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const responseText = await response.text();
    let result;
    try {
      result = JSON.parse(responseText);
    } catch (parseErr) {
      console.error('[RechargeController] PHP API returned non-JSON response in submitWithdraw:', responseText);
      const cleanText = responseText.replace(/<[^>]*>/g, '').trim() || responseText;
      return res.status(500).json({
        error: `PHP API error: ${cleanText.substring(0, 200)}`
      });
    }

    if (!response.ok || (result && result.success === false)) {
      return res.status(response.ok ? 400 : response.status).json({
        error: result.message || result.error || `PHP API returned status ${response.status}`
      });
    }

    const phpWithdrawId = result.withdraw_id || result.id || result.withdrawal_id || null;
    return res.json({
      ...result,
      withdraw_id: phpWithdrawId,
      transactionId: phpWithdrawId
    });
  } catch (err) {
    console.error('[RechargeController] Error in submitWithdraw:', err);
    return res.status(500).json({ error: err.message });
  }
}

export async function updateTransactionStatus(req, res) {
  try {
    const {
      sender_id,
      senderId = sender_id,
      recipient_id,
      recipientId = recipient_id,
      userId = recipientId,
      type,
      status,
      amount,
      transaction_id,
      recharge_id,
      withdraw_id,
      transactionId = transaction_id || recharge_id || withdraw_id,
      txn_id = transactionId,
      utr,
      utr_no,
      utrNo = utr || utr_no,
      reason,
      remarks,
      book_id,
      bookId = book_id,
      book_name,
      bookName = book_name,
      custom_message,
      invoice_url,
      invoiceUrl = invoice_url || req.body.invoice_link || req.body.invoiceLink || req.body.invoice
    } = req.body;

    const targetUserId = recipientId || userId;
    const targetSenderId = senderId;
    const targetTxnId = transactionId || txn_id;
    const targetStatus = status;
    const targetType = type;
    let targetInvoiceUrl = invoiceUrl || null;
    let targetUtrNo = utrNo || null;

    // Check if utr contains an invoice URL (starts with http/https or contains pdf)
    if (!targetInvoiceUrl && targetUtrNo && typeof targetUtrNo === 'string') {
      const trimmedUtr = targetUtrNo.trim();
      if (trimmedUtr.startsWith('http://') || trimmedUtr.startsWith('https://') || trimmedUtr.toLowerCase().endsWith('.pdf')) {
        targetInvoiceUrl = trimmedUtr;
      }
    }

    // Validate required fields: sender_id, recipient_id, transaction_id, status, type
    const missingFields = [];
    if (!targetSenderId) missingFields.push('sender_id');
    if (!targetUserId) missingFields.push('recipient_id');
    if (!targetTxnId) missingFields.push('transaction_id');
    if (!targetStatus) missingFields.push('status');
    if (!targetType) missingFields.push('type');

    if (missingFields.length > 0) {
      return res.status(400).json({
        error: `Missing required field(s): ${missingFields.join(', ')}`
      });
    }

    // 1. Resolve recipient user (email / user _id)
    let resolvedRecipientId = targetUserId;
    const userDoc = await User.findOne({
      $or: [
        { _id: targetUserId },
        { emailId: targetUserId },
        { id: Number(targetUserId) || -1 }
      ]
    });
    if (userDoc) {
      resolvedRecipientId = userDoc._id || userDoc.emailId;
    }

    // 2. Resolve sender (agent unq_id / _id / email)
    let resolvedSenderId = targetSenderId;
    let senderRole = 'agent';
    const agentDoc = await Agent.findOne({
      $or: [
        { _id: targetSenderId },
        { emailId: targetSenderId },
        { id: Number(targetSenderId) || -1 }
      ]
    });
    if (agentDoc) {
      resolvedSenderId = agentDoc._id || agentDoc.emailId;
      const rawRole = String(agentDoc.role || agentDoc.type || 'agent').toLowerCase();
      senderRole = rawRole === 'admin' ? 'admin' : 'agent';
    }

    // 3. Find or compute conversationId strictly between resolvedSenderId and resolvedRecipientId
    let conversationId = null;
    const existingConv = await Conversation.findOne({
      $or: [
        { participant1: resolvedSenderId, participant2: resolvedRecipientId },
        { participant1: resolvedRecipientId, participant2: resolvedSenderId }
      ]
    }).sort({ lastMessageAt: -1 });

    if (existingConv) {
      conversationId = existingConv._id;
    } else {
      const sorted = [resolvedSenderId, resolvedRecipientId].sort();
      conversationId = `conv-${sorted[0]}-${sorted[1]}`;
    }

    // 4. Construct user-facing text message if custom_message is not provided
    let textMessage = custom_message;
    if (!textMessage) {
      const isApproved = String(status).toLowerCase() === 'approved';
      const isRecharge = String(type).toLowerCase() === 'recharge';
      const statusIcon = isApproved ? '✅' : '❌';
      const typeLabel = isRecharge ? 'Recharge' : 'Withdrawal';
      const statusText = isApproved ? 'APPROVED' : 'REJECTED';

      const details = [];
      if (amount) details.push(`Amount: ₹${amount}`);
      if (targetTxnId) details.push(`Txn ID: ${targetTxnId}`);
      if (targetUtrNo && targetUtrNo !== targetInvoiceUrl) details.push(`UTR: ${targetUtrNo}`);
      if (bookName || bookId) details.push(`Book: ${bookName || bookId}`);
      const finalReason = reason || remarks;
      if (finalReason) details.push(`Reason: ${finalReason}`);

      textMessage = `${statusIcon} Your ${typeLabel} request has been ${statusText}.\n${details.join(' | ')}`;
    }

    // 5. Build message payload & enqueue to stream pipeline
    const messageId = uuidv4();
    const createdAt = new Date();
    const sorted = [resolvedSenderId, resolvedRecipientId].sort();

    const messagePayload = {
      _id: messageId,
      conversationId,
      senderId: resolvedSenderId,
      senderType: senderRole,
      type: 'text',
      text: textMessage,
      invoiceUrl: targetInvoiceUrl,
      status: 'sent',
      createdAt,
      participant1: sorted[0],
      participant2: sorted[1],
      recipientId: resolvedRecipientId,
      recipientType: 'user'
    };

    await enqueueMessage(messagePayload);

    console.log(`[RechargeController] Status update message ${messageId} enqueued for user ${resolvedRecipientId} from sender ${resolvedSenderId}`);

    return res.json({
      success: true,
      message: 'Transaction status update processed successfully',
      messageId,
      conversationId,
      text: textMessage,
      invoiceUrl: targetInvoiceUrl
    });
  } catch (err) {
    console.error('[RechargeController] Error in updateTransactionStatus:', err);
    return res.status(500).json({ error: err.message });
  }
}



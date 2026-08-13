# Mobile Client Chat Integration Guide

This document defines the REST API endpoints and Socket.io events for integrating mobile clients (iOS, Android, React Native, Flutter, etc.) with the Chat Assistant backend.

---

## 1. Authentication Headers & Handshakes

### Option A: Standard JWT Flow
The user logs in to obtain a temporary JWT token.
- **REST Request Header:**
  ```http
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbElkIjoidXNlci1hbGljZTEiLCJyb2xlIjoidXNlciIsImFnZW50SWQiOiJhZ2VudC1ib2IiLCJuYW1lIjoiQWxpY2UifQ.signature
  ```
- **Socket.io Handshake Configuration:**
  ```json
  {
    "auth": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbElkIjoidXNlci1hbGljZTEiLCJyb2xlIjoidXNlciIsImFnZW50SWQiOiJhZ2VudC1ib2IiLCJuYW1lIjoiQWxpY2UifQ.signature"
    }
  }
  ```

### Option B: B2B Fixed API Token Flow
When calls are made via a developer client or backend proxy, authenticate using the fixed token and pass target user context in the headers.
- **REST Request Headers:**
  ```http
  Authorization: Bearer chat_fixed_auth_token_2026_prod
  X-Act-As-Email: user-alice1@domain.com
  X-Act-As-Role: user
  X-Act-As-Name: Alice
  ```
- **Socket.io Handshake Configuration:**
  ```json
  {
    "auth": {
      "token": "chat_fixed_auth_token_2026_prod",
      "actAsEmail": "user-alice1@domain.com",
      "actAsRole": "user",
      "actAsName": "Alice"
    }
  }
  ```

---

## 2. REST API Endpoints

All endpoints are prefixed with `/api/v1`.

### Get Conversations List
Retrieve the list of active chat rooms for the authenticated account.
- **Route:** `GET /api/v1/conversations`
- **Response (200 OK):**
  ```json
  {
    "role": "user",
    "count": 1,
    "conversations": [
      {
        "_id": "conv-agent-bob-user-alice1",
        "agentId": {
          "_id": "agent-bob",
          "emailId": "agent-bob@domain.com",
          "name": "Agent Bob",
          "avatar": "https://telewiz.in/officemanage/uploads/photos/1784376403_Agency.jpg"
        },
        "emailId": {
          "_id": "user-alice1@domain.com",
          "emailId": "user-alice1@domain.com",
          "name": "Alice Player",
          "avatar": ""
        },
        "lastMessageAt": "2026-08-08T12:00:00.000Z",
        "unread": {
          "agent": 0,
          "user": 1
        }
      }
    ]
  }
  ```

### Get Conversation Messages (Paginated)
Retrieve historical messages. Use the `nextCursor` value as the `cursor` query param to page backward.
- **Route:** `GET /api/v1/conversations/:conversationId/messages`
- **Query Parameters:** `?limit=20&cursor=2026-08-08T12:00:00.000Z`
- **Response (200 OK):**
  ```json
  {
    "conversationId": "conv-agent-bob-user-alice1",
    "count": 3,
    "hasMore": false,
    "nextCursor": "2026-08-08T11:45:00.000Z",
    "messages": [
      {
        "_id": "msg-text-001",
        "conversationId": "conv-agent-bob-user-alice1",
        "senderId": "user-alice1@domain.com",
        "senderType": "user",
        "type": "text",
        "text": "Hello, here is my update.",
        "status": "read",
        "createdAt": "2026-08-08T12:00:00.000Z"
      },
      {
        "_id": "msg-voice-002",
        "conversationId": "conv-agent-bob-user-alice1",
        "senderId": "user-alice1@domain.com",
        "senderType": "user",
        "type": "voice",
        "audio": {
          "key": "voice-notes/conv-agent-bob-user-alice1/user-alice1/recording-123.webm",
          "duration": 8,
          "mimeType": "audio/webm"
        },
        "status": "delivered",
        "createdAt": "2026-08-08T11:50:00.000Z"
      },
      {
        "_id": "msg-image-003",
        "conversationId": "conv-agent-bob-user-alice1",
        "senderId": "agent-bob",
        "senderType": "agent",
        "type": "image",
        "image": {
          "key": "images/conv-agent-bob-user-alice1/user-alice1/screenshot-456.png",
          "mimeType": "image/png"
        },
        "status": "sent",
        "createdAt": "2026-08-08T11:45:00.000Z"
      }
    ]
  }
  ```

---

## 3. Media Upload & Playback Flows

### Step 1: Request Pre-signed Upload URL
- **Voice Note Upload URL (`POST /api/v1/voice/presigned-url`):**
  - **Request Body:**
    ```json
    {
      "conversationId": "conv-agent-bob-user-alice1",
      "mimeType": "audio/webm"
    }
    ```
  - **Response (200 OK):**
    ```json
    {
      "provider": "Wasabi",
      "uploadUrl": "https://s3.us-east-1.wasabisys.com/chat-recordings/voice-notes/conv-agent-bob-user-alice1/user-alice1/a96be342-990a.webm?AWSAccessKeyId=4IW26YX9KK1&Expires=1786277000&Signature=abcdefg",
      "fileKey": "voice-notes/conv-agent-bob-user-alice1/user-alice1/a96be342-990a.webm",
      "cdnUrl": "https://s3.us-east-1.wasabisys.com/chat-recordings/voice-notes/conv-agent-bob-user-alice1/user-alice1/a96be342-990a.webm",
      "expiresIn": 3600
    }
    ```

- **Image Upload URL (`POST /api/v1/image/presigned-url`):**
  - **Request Body:**
    ```json
    {
      "conversationId": "conv-agent-bob-user-alice1",
      "mimeType": "image/png"
    }
    ```
  - **Response (200 OK):**
    ```json
    {
      "provider": "Wasabi",
      "uploadUrl": "https://s3.us-east-1.wasabisys.com/chat-recordings/images/conv-agent-bob-user-alice1/user-alice1/c87bf124-770b.png?AWSAccessKeyId=4IW26YX9KK1&Expires=1786277000&Signature=hijklmn",
      "fileKey": "images/conv-agent-bob-user-alice1/user-alice1/c87bf124-770b.png",
      "cdnUrl": "https://s3.us-east-1.wasabisys.com/chat-recordings/images/conv-agent-bob-user-alice1/user-alice1/c87bf124-770b.png",
      "expiresIn": 3600
    }
    ```

### Step 2: Upload Binary Stream (REST API PUT)
Perform a direct HTTP `PUT` upload to the `uploadUrl` returned in Step 1.
- **Method:** `PUT`
- **Headers:** `Content-Type: audio/webm` (or matching mimeType)
- **Body:** Raw binary byte buffer of the media file.

### Step 3: Retrieve Playback/Streaming URL
Attachments must be resolved through a pre-signed playback URL before they are played or viewed in the app.
- **Voice Playback URL (`GET /api/v1/voice/play-url?key=voice-notes/conv-agent-bob-user-alice1/user-alice1/a96be342-990a.webm`):**
  - **Response (200 OK):**
    ```json
    {
      "url": "https://s3.us-east-1.wasabisys.com/chat-recordings/voice-notes/conv-agent-bob-user-alice1/user-alice1/a96be342-990a.webm?AWSAccessKeyId=4IW26YX9KK1&Expires=1786280000&Signature=zxywvuts"
    }
    ```

- **Image Viewing URL (`GET /api/v1/image/play-url?key=images/conv-agent-bob-user-alice1/user-alice1/c87bf124-770b.png`):**
  - **Response (200 OK):**
    ```json
    {
      "url": "https://s3.us-east-1.wasabisys.com/chat-recordings/images/conv-agent-bob-user-alice1/user-alice1/c87bf124-770b.png?AWSAccessKeyId=4IW26YX9KK1&Expires=1786280000&Signature=ponmlkji"
    }
    ```

---

## 4. WebSocket Gateway Events (Socket.io)

### Outgoing Event: `message:send`
Send a message in the active chat.

- **Text Message Payload:**
  ```json
  {
    "conversationId": "conv-agent-bob-user-alice1",
    "recipientId": "agent-bob",
    "type": "text",
    "text": "Hello! How are you?"
  }
  ```

- **Voice Note Payload:**
  ```json
  {
    "conversationId": "conv-agent-bob-user-alice1",
    "recipientId": "agent-bob",
    "type": "voice",
    "audio": {
      "key": "voice-notes/conv-agent-bob-user-alice1/user-alice1/a96be342-990a.webm",
      "duration": 8,
      "mimeType": "audio/webm"
    }
  }
  ```

- **Image Payload:**
  ```json
  {
    "conversationId": "conv-agent-bob-user-alice1",
    "recipientId": "agent-bob",
    "type": "image",
    "image": {
      "key": "images/conv-agent-bob-user-alice1/user-alice1/c87bf124-770b.png",
      "mimeType": "image/png"
    }
  }
  ```

### Incoming Event: `message:new`
Listen for real-time incoming messages.
- **Event Name:** `message:new`
- **Response Payload:**
  ```json
  {
    "_id": "msg-88772",
    "conversationId": "conv-agent-bob-user-alice1",
    "senderId": "agent-bob",
    "senderType": "agent",
    "type": "text",
    "text": "This is a response message from the agent.",
    "status": "sent",
    "createdAt": "2026-08-08T12:05:00.000Z"
  }
  ```

### Outgoing/Incoming: `message:delivered`
- **Acknowledge Delivery (Outgoing):**
  - **Event Name:** `message:delivered`
  - **Payload:**
    ```json
    {
      "messageId": "msg-88772",
      "conversationId": "conv-agent-bob-user-alice1",
      "senderId": "agent-bob"
    }
    ```
- **Listen to Delivery Confirmation (Incoming):**
  - **Event Name:** `message:delivered`
  - **Response Payload:**
    ```json
    {
      "messageId": "msg-88772",
      "deliveredAt": "2026-08-08T12:05:02.000Z"
    }
    ```

### Outgoing/Incoming: `message:read`
- **Acknowledge Read State (Outgoing):**
  - **Event Name:** `message:read`
  - **Payload:**
    ```json
    {
      "conversationId": "conv-agent-bob-user-alice1",
      "senderId": "agent-bob",
      "messageIds": ["msg-88772"]
    }
    ```
- **Listen to Read Confirmation (Incoming):**
  - **Event Name:** `message:read`
  - **Response Payload:**
    ```json
    {
      "conversationId": "conv-agent-bob-user-alice1",
      "readBy": "user-alice1@domain.com",
      "messageIds": ["msg-88772"],
      "modifiedCount": 1,
      "readAt": "2026-08-08T12:06:00.000Z"
    }
    ```

### Outgoing/Incoming: User Presence Check
- **Emit Presence Check (Outgoing):**
  - **Event Name:** `presence:check`
  - **Payload:**
    ```json
    {
      "userId": "agent-bob"
    }
    ```
- **Listen to Status (Incoming):**
  - **Event Name:** `presence:res`
  - **Response Payload:**
    ```json
    {
      "userId": "agent-bob",
      "isOnline": true
    }
    ```

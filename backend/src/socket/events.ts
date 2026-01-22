/**
 * Socket.IO Event Constants
 * 定義所有 WebSocket 事件名稱
 */

export const EVENTS = {
  // Client → Server
  CREATE_ROOM: 'create_room',
  JOIN_ROOM: 'join_room',
  LEAVE_ROOM: 'leave_room',
  PLAYER_READY: 'player_ready',
  START_GAME: 'start_game',
  GAME_ACTION: 'game_action',
  SEND_MESSAGE: 'send_message',
  VOTE: 'vote',

  // Server → Client
  ROOM_CREATED: 'room_created',
  ROOM_JOINED: 'room_joined',
  PLAYER_JOINED: 'player_joined',
  PLAYER_LEFT: 'player_left',
  PLAYER_READY_CHANGED: 'player_ready_changed',
  GAME_STARTED: 'game_started',
  PHASE_CHANGED: 'phase_changed',
  GAME_STATE_UPDATE: 'game_state_update',
  ACTION_RESULT: 'action_result',
  MESSAGE_RECEIVED: 'message_received',
  VOTE_RECEIVED: 'vote_received',
  GAME_ENDED: 'game_ended',
  ERROR: 'error',
} as const;

export type EventType = typeof EVENTS[keyof typeof EVENTS];

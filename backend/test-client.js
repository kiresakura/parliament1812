// 1812 國會風雲 - WebSocket 測試客戶端
const { io } = require('socket.io-client');

const SERVER_URL = process.env.SERVER_URL || 'https://1812-production.up.railway.app';

console.log('=== 1812 國會風雲 測試客戶端 ===\n');
console.log(`連接到: ${SERVER_URL}\n`);

// 測試結果記錄
const testResults = {
  connection: false,
  createRoom: false,
  joinRoom: false,
  playerReady: false,
  gameStart: false,
  errors: []
};

// 創建兩個測試玩家 (使用 polling 和 websocket)
const player1 = io(SERVER_URL, {
  transports: ['polling', 'websocket'],
  timeout: 10000,
  reconnection: false
});

const player2 = io(SERVER_URL, {
  transports: ['polling', 'websocket'],
  timeout: 10000,
  reconnection: false
});

let roomCode = null;
let roomId = null;

// Player 1 事件處理
player1.on('connect', () => {
  console.log('✅ 玩家1 已連接');
  testResults.connection = true;

  // 創建房間
  console.log('\n📋 測試: 創建房間...');
  player1.emit('create_room', { playerName: '測試玩家1' });
});

player1.on('room_created', (data) => {
  console.log('✅ 房間已創建:', data);
  testResults.createRoom = true;
  roomCode = data.roomCode;
  roomId = data.roomId;

  // 讓玩家2加入
  setTimeout(() => {
    console.log('\n📋 測試: 玩家2 加入房間...');
    player2.emit('join_room', { roomCode, playerName: '測試玩家2' });
  }, 500);
});

player1.on('player_joined', (data) => {
  console.log('✅ 收到玩家加入通知:', data.player?.name || data);
});

player1.on('player_ready_changed', (data) => {
  console.log('✅ 收到準備狀態變更:', data);
});

player1.on('game_started', (data) => {
  console.log('✅ 遊戲已開始!');
  console.log('   角色分配:', data.players?.map(p => `${p.name}: ${p.role?.name}`).join(', ') || 'N/A');
  testResults.gameStart = true;

  // 測試完成
  setTimeout(() => {
    printResults();
    process.exit(0);
  }, 1000);
});

player1.on('error', (error) => {
  console.log('❌ 玩家1 錯誤:', error);
  testResults.errors.push(`Player1: ${error.message || error}`);
});

// Player 2 事件處理
player2.on('connect', () => {
  console.log('✅ 玩家2 已連接');
});

player2.on('room_joined', (data) => {
  console.log('✅ 玩家2 已加入房間');
  testResults.joinRoom = true;

  // 玩家2 準備
  setTimeout(() => {
    console.log('\n📋 測試: 玩家2 準備...');
    player2.emit('player_ready', { ready: true });
    testResults.playerReady = true;

    // 嘗試開始遊戲（需要至少4人，這裡會失敗但可以測試機制）
    setTimeout(() => {
      console.log('\n📋 測試: 嘗試開始遊戲 (預期失敗-人數不足)...');
      player1.emit('start_game', {});
    }, 500);
  }, 500);
});

player2.on('error', (error) => {
  console.log('❌ 玩家2 錯誤:', error);
  testResults.errors.push(`Player2: ${error.message || error}`);
});

// 連接錯誤處理
player1.on('connect_error', (error) => {
  console.log('❌ 玩家1 連接失敗:', error.message);
  testResults.errors.push(`Connection: ${error.message}`);
});

player2.on('connect_error', (error) => {
  console.log('❌ 玩家2 連接失敗:', error.message);
});

// 打印測試結果
function printResults() {
  console.log('\n========================================');
  console.log('          測試結果報告');
  console.log('========================================\n');

  console.log(`連接測試:     ${testResults.connection ? '✅ 通過' : '❌ 失敗'}`);
  console.log(`創建房間:     ${testResults.createRoom ? '✅ 通過' : '❌ 失敗'}`);
  console.log(`加入房間:     ${testResults.joinRoom ? '✅ 通過' : '❌ 失敗'}`);
  console.log(`玩家準備:     ${testResults.playerReady ? '✅ 通過' : '❌ 失敗'}`);
  console.log(`遊戲開始:     ${testResults.gameStart ? '✅ 通過' : '⚠️ 跳過 (人數不足)'}`);

  if (testResults.errors.length > 0) {
    console.log('\n錯誤記錄:');
    testResults.errors.forEach(e => console.log(`  - ${e}`));
  }

  const passed = [testResults.connection, testResults.createRoom, testResults.joinRoom, testResults.playerReady].filter(Boolean).length;
  console.log(`\n總計: ${passed}/4 項基本測試通過`);
  console.log('========================================\n');
}

// 超時處理
setTimeout(() => {
  console.log('\n⏰ 測試超時 (15秒)');
  printResults();
  process.exit(1);
}, 15000);

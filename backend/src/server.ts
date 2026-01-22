/**
 * Express + Socket.IO Server
 * 1812 國會風雲 後端伺服器
 */

import express, { Express, Request, Response } from 'express';
import { createServer, Server as HttpServer } from 'http';
import { Server as SocketServer } from 'socket.io';
import cors from 'cors';
import { setupSocketHandlers } from './socket/handlers';
import { RoomManager } from './game/GameRoom';

export interface ServerConfig {
  port: number;
  corsOrigin: string;
}

export function createApp(): Express {
  const app = express();

  // 中間件
  app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST'],
    credentials: true,
  }));
  app.use(express.json());

  // 健康檢查端點
  app.get('/health', (_req: Request, res: Response) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      rooms: RoomManager.getRoomCount(),
    });
  });

  // API 路由
  app.get('/api/rooms/count', (_req: Request, res: Response) => {
    res.json({
      count: RoomManager.getRoomCount(),
    });
  });

  // 404 處理
  app.use((_req: Request, res: Response) => {
    res.status(404).json({ error: 'Not Found' });
  });

  return app;
}

export function createSocketServer(httpServer: HttpServer): SocketServer {
  const io = new SocketServer(httpServer, {
    cors: {
      origin: process.env.CORS_ORIGIN || '*',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['polling', 'websocket'],
    allowEIO3: true,
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // 設置 Socket 事件處理
  setupSocketHandlers(io);

  return io;
}

export function startServer(config: ServerConfig): {
  app: Express;
  httpServer: HttpServer;
  io: SocketServer;
} {
  const app = createApp();
  const httpServer = createServer(app);
  const io = createSocketServer(httpServer);

  httpServer.listen(config.port, () => {
    console.log(`
╔═══════════════════════════════════════════╗
║   1812 國會風雲 - Backend Server          ║
╠═══════════════════════════════════════════╣
║   Port: ${config.port.toString().padEnd(33)}║
║   CORS: ${config.corsOrigin.substring(0, 33).padEnd(33)}║
║   Mode: ${(process.env.NODE_ENV || 'development').padEnd(33)}║
╚═══════════════════════════════════════════╝
    `);
    console.log(`Health check: http://localhost:${config.port}/health`);
  });

  return { app, httpServer, io };
}

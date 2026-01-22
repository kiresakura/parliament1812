# 1812 國會風雲 部署指南

## Railway 後端部署

### 首次部署
1. 前往 https://railway.app 登入
2. New Project → Deploy from GitHub repo
3. 選擇 parliament1812 repo
4. 設定：
   - Root Directory: `/` (使用根目錄的 railway.toml)
   - 或手動設定 Root Directory: `backend`
5. 環境變數設定：
   - `NODE_ENV`: production
   - `CORS_ORIGIN`: * (之後可限制)
   - `PORT`: 由 Railway 自動設定
6. Deploy
7. 取得 URL（例如：parliament1812-production.up.railway.app）

### 更新部署
- git push 到 main branch 會自動觸發部署

### 測試
- 訪問 https://your-app.railway.app/health
- 應該返回 {"status":"ok",...}

## Flutter 打包

### Android APK
```bash
cd platforms/flutter
flutter build apk --release --dart-define=ENV=prod
```
輸出：`build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
cd platforms/flutter
flutter build ios --release --dart-define=ENV=prod
```
然後用 Xcode Archive 上傳 TestFlight

## 驗證連接
1. 更新 api_constants.dart 的 prodBaseUrl
2. 重新打包 Flutter
3. 安裝測試 APK
4. 創建房間測試連接

## 本地測試生產環境配置

### 後端
```bash
cd backend
npm run build
NODE_ENV=production npm start
```

### Flutter（模擬生產環境）
```bash
cd platforms/flutter
flutter run --dart-define=ENV=prod
```

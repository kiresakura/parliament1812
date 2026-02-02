import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/room_service.dart';
import '../../providers/socket_provider.dart';
import '../../providers/room_provider.dart';
import '../widgets/common/common_widgets.dart';

/// 加入房間畫面
class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _roomCodeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _roomService = RoomService();

  List<RoomListItem> _rooms = [];
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await _roomService.getAvailableRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '無法載入房間列表';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinRoom(String roomCode) async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showNicknameDialog(roomCode);
      return;
    }

    await _doJoinRoom(roomCode, nickname);
  }

  Future<void> _doJoinRoom(String roomCode, String nickname) async {
    setState(() => _isJoining = true);

    try {
      final gameService = ref.read(gameServiceProvider);
      final data = await gameService.joinRoom(roomCode, nickname);

      if (data == null) {
        _showError('加入房間失敗，房間可能不存在或已滿');
        return;
      }

      await ref.read(roomProvider.notifier).joinRoom(data);

      if (mounted) {
        final roomId = data['roomId'] ?? roomCode;
        context.goNamed('lobby', pathParameters: {'roomId': roomId});
      }
    } catch (e) {
      _showError('加入房間失敗：$e');
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _joinRandomRoom() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showNicknameDialog(null, isRandom: true);
      return;
    }

    setState(() => _isJoining = true);

    try {
      // 先嘗試從列表中隨機選一個
      final joinableRooms = _rooms.where((r) => r.canJoin).toList();
      if (joinableRooms.isNotEmpty) {
        joinableRooms.shuffle();
        await _doJoinRoom(joinableRooms.first.code, nickname);
        return;
      }

      // 沒有可用房間
      _showError('目前沒有可加入的房間');
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _joinByCode() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showError('請輸入房間代碼');
      return;
    }
    if (code.length != 6) {
      _showError('房間代碼需為 6 位');
      return;
    }

    await _joinRoom(code);
  }

  void _showNicknameDialog(String? roomCode, {bool isRandom = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.accent.withAlpha(128)),
        ),
        title: Text(
          '輸入暱稱',
          style: GoogleFonts.notoSerifHk(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: _nicknameController,
          style: GoogleFonts.lora(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: '你的暱稱',
            hintStyle: GoogleFonts.lora(color: AppTheme.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.accent.withAlpha(128)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.accent),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            if (isRandom) {
              _joinRandomRoom();
            } else if (roomCode != null) {
              _joinRoom(roomCode);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: GoogleFonts.lora(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.primaryDark,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (isRandom) {
                _joinRandomRoom();
              } else if (roomCode != null) {
                _joinRoom(roomCode);
              }
            },
            child: Text('確定', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lora()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryMid],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '加入房間',
              style: GoogleFonts.notoSerifHk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh, color: AppTheme.accent),
            tooltip: '重新整理',
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.accent),
          SizedBox(height: 16),
          Text(
            '載入房間列表...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 暱稱輸入
          _buildNicknameInput(),
          const SizedBox(height: 24),

          // 快速操作按鈕
          _buildQuickActions(),
          const SizedBox(height: 24),

          // 房間列表或手動輸入
          if (_showManualInput)
            _buildManualInput()
          else
            _buildRoomList(),
        ],
      ),
    );
  }

  Widget _buildNicknameInput() {
    return VictorianCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '你的暱稱',
            style: GoogleFonts.lora(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            style: GoogleFonts.lora(color: AppTheme.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: '輸入暱稱加入遊戲',
              hintStyle: GoogleFonts.lora(color: AppTheme.textSecondary.withAlpha(128)),
              prefixIcon: const Icon(Icons.person, color: AppTheme.accent),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.accent.withAlpha(128)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.accent),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppTheme.primaryDark.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final joinableCount = _rooms.where((r) => r.canJoin).length;

    return Row(
      children: [
        Expanded(
          child: VictorianButton(
            text: '隨機加入',
            icon: Icons.shuffle,
            onPressed: _isJoining || joinableCount == 0 ? null : _joinRandomRoom,
            isLoading: _isJoining,
            type: VictorianButtonType.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: VictorianButton(
            text: _showManualInput ? '查看列表' : '輸入代碼',
            icon: _showManualInput ? Icons.list : Icons.keyboard,
            onPressed: () => setState(() => _showManualInput = !_showManualInput),
            type: VictorianButtonType.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomList() {
    if (_error != null) {
      return _buildError();
    }

    final joinableRooms = _rooms.where((r) => r.canJoin).toList();

    if (joinableRooms.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '可加入的房間 (${joinableRooms.length})',
            style: GoogleFonts.lora(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        ...joinableRooms.map((room) => _buildRoomCard(room)),
      ],
    );
  }

  Widget _buildRoomCard(RoomListItem room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VictorianCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 房間資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.accent.withAlpha(128)),
                        ),
                        child: Text(
                          room.code,
                          style: GoogleFonts.firaCode(
                            color: AppTheme.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '房主：${room.hostName}',
                          style: GoogleFonts.lora(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${room.playerCount}/${room.maxPlayers}',
                        style: GoogleFonts.lora(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: room.status == 'waiting' ? AppTheme.success : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        room.status == 'waiting' ? '等待中' : '進行中',
                        style: GoogleFonts.lora(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 加入按鈕
            ElevatedButton(
              onPressed: _isJoining ? null : () => _joinRoom(room.code),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '加入',
                style: GoogleFonts.lora(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return VictorianCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 64,
            color: AppTheme.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            '目前沒有可加入的房間',
            style: GoogleFonts.lora(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '可以創建新房間或輸入房間代碼',
            style: GoogleFonts.lora(
              color: AppTheme.textSecondary.withAlpha(179),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VictorianButton(
                text: '創建房間',
                icon: Icons.add,
                onPressed: () => context.pop(),
                type: VictorianButtonType.primary,
              ),
              const SizedBox(width: 12),
              VictorianButton(
                text: '輸入代碼',
                icon: Icons.keyboard,
                onPressed: () => setState(() => _showManualInput = true),
                type: VictorianButtonType.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput() {
    return VictorianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '輸入房間代碼',
            style: GoogleFonts.lora(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _roomCodeController,
            style: GoogleFonts.firaCode(
              color: AppTheme.textPrimary,
              fontSize: 24,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: GoogleFonts.firaCode(
                color: AppTheme.textSecondary.withAlpha(128),
                fontSize: 24,
                letterSpacing: 8,
              ),
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.accent.withAlpha(128)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppTheme.primaryDark.withAlpha(128),
            ),
            onSubmitted: (_) => _joinByCode(),
          ),
          const SizedBox(height: 16),
          VictorianButton(
            text: '加入房間',
            icon: Icons.login,
            onPressed: _isJoining ? null : _joinByCode,
            isLoading: _isJoining,
            fullWidth: true,
            type: VictorianButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return VictorianCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.danger,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? '發生錯誤',
            style: GoogleFonts.lora(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          VictorianButton(
            text: '重試',
            icon: Icons.refresh,
            onPressed: _loadRooms,
            type: VictorianButtonType.secondary,
          ),
        ],
      ),
    );
  }
}

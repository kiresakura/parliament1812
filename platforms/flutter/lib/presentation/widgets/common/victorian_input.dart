import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// 維多利亞風格輸入框
class VictorianInput extends StatefulWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 提示文字
  final String? hintText;

  /// 標籤文字
  final String? labelText;

  /// 前置圖標
  final IconData? prefixIcon;

  /// 後置圖標
  final IconData? suffixIcon;

  /// 後置圖標點擊
  final VoidCallback? onSuffixIconTap;

  /// 值改變回調
  final ValueChanged<String>? onChanged;

  /// 提交回調
  final ValueChanged<String>? onSubmitted;

  /// 是否密碼輸入
  final bool obscureText;

  /// 是否自動獲取焦點
  final bool autofocus;

  /// 輸入限制
  final List<TextInputFormatter>? inputFormatters;

  /// 鍵盤類型
  final TextInputType? keyboardType;

  /// 最大長度
  final int? maxLength;

  /// 是否顯示計數器
  final bool showCounter;

  /// 錯誤訊息
  final String? errorText;

  /// 是否啟用
  final bool enabled;

  /// 文字對齊
  final TextAlign textAlign;

  const VictorianInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.autofocus = false,
    this.inputFormatters,
    this.keyboardType,
    this.maxLength,
    this.showCounter = false,
    this.errorText,
    this.enabled = true,
    this.textAlign = TextAlign.start,
  });

  @override
  State<VictorianInput> createState() => _VictorianInputState();
}

class _VictorianInputState extends State<VictorianInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isFocused
                  ? AppTheme.accent
                  : AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
        ],

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.primaryMid,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.errorText != null
                  ? AppTheme.danger
                  : _isFocused
                      ? AppTheme.accent
                      : AppTheme.accent.withAlpha(77),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withAlpha(51),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            textAlign: widget.textAlign,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: GoogleFonts.lora(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
            cursorColor: AppTheme.accent,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.lora(
                fontSize: 16,
                color: AppTheme.textSecondary.withAlpha(153),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(),
              counterText: widget.showCounter ? null : '',
            ),
          ),
        ),

        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: GoogleFonts.lora(
              fontSize: 12,
              color: AppTheme.danger,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: _isFocused ? AppTheme.accent : AppTheme.textSecondary,
        ),
        onPressed: widget.onSuffixIconTap,
      );
    }

    return null;
  }
}

/// 房間代碼輸入框（特殊樣式）
class RoomCodeInput extends StatelessWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 提交回調
  final ValueChanged<String>? onSubmitted;

  /// 錯誤訊息
  final String? errorText;

  const RoomCodeInput({
    super.key,
    this.controller,
    this.onSubmitted,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return VictorianInput(
      controller: controller,
      hintText: 'XXXXXX',
      labelText: '房間代碼',
      prefixIcon: Icons.meeting_room_outlined,
      textAlign: TextAlign.center,
      maxLength: 6,
      showCounter: true,
      errorText: errorText,
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
        UpperCaseTextFormatter(),
      ],
      onSubmitted: onSubmitted,
    );
  }
}

/// 暱稱輸入框
class NicknameInput extends StatelessWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 提交回調
  final ValueChanged<String>? onSubmitted;

  /// 錯誤訊息
  final String? errorText;

  const NicknameInput({
    super.key,
    this.controller,
    this.onSubmitted,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return VictorianInput(
      controller: controller,
      hintText: '輸入你的暱稱',
      labelText: '暱稱',
      prefixIcon: Icons.person_outline,
      maxLength: 12,
      showCounter: true,
      errorText: errorText,
      onSubmitted: onSubmitted,
    );
  }
}

/// 大寫轉換器
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

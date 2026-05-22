import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 비밀번호 입력 필드 + 커스텀 키패드 (제어형 위젯)
///
/// 방 등록·입주 준비 서비스 등록에서 공통으로 쓰는 비밀번호 입력 UI.
/// 숫자/특수문자(`* #`) 입력을 지원하며, [showIconKeys] 가 true 면
/// 아이콘(🔑 🔔 🛡) 키도 노출한다.
///
/// 표시 영역을 탭하면 키패드가 펼쳐지고 '완료'를 누르면 접힌다.
/// 값은 [value] 로 받고 변경은 [onChanged] 로 전달하는 제어형 — 부모가
/// formData Map 또는 TextEditingController 등 원하는 방식으로 보관하면 된다.
class PasswordKeypadField extends StatefulWidget {
  /// 현재 입력 값.
  final String value;

  /// 값 변경 콜백.
  final ValueChanged<String> onChanged;

  /// 표시 영역이 비었을 때의 안내 문구.
  final String hint;

  /// 에러 상태 여부 — true 면 표시 영역을 빨간 테두리로 강조.
  final bool hasError;

  /// 아이콘 키(🔑 🔔 🛡) 노출 여부.
  final bool showIconKeys;

  const PasswordKeypadField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = '비밀번호를 입력하세요',
    this.hasError = false,
    this.showIconKeys = true,
  });

  @override
  State<PasswordKeypadField> createState() => _PasswordKeypadFieldState();
}

class _PasswordKeypadFieldState extends State<PasswordKeypadField> {
  bool _showKeypad = false;

  String get _password => widget.value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showKeypad = !_showKeypad),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.hasError ? AppColors.error50 : Colors.white,
              border: Border.all(
                color: widget.hasError
                    ? AppColors.error500
                    : AppColors.gray300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _password.isEmpty ? widget.hint : _password,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _password.isEmpty
                          ? (widget.hasError
                              ? AppColors.error500
                              : Colors.grey[400])
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  _showKeypad
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_showKeypad) ...[
          const SizedBox(height: 16),
          _buildKeypad(),
        ],
      ],
    );
  }

  Widget _buildKeypad() {
    const double buttonHeight = 48.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 아이콘 키 (옵션)
          if (widget.showIconKeys) ...[
            Row(
              children: [
                for (final icon in const ['🔑', '🔔', '🛡']) ...[
                  if (icon != '🔑') const SizedBox(width: 8),
                  Expanded(
                    child: _keypadButton(
                      icon,
                      onTap: () => widget.onChanged('$_password$icon'),
                      fontSize: 32,
                      height: buttonHeight,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          // 숫자/특수문자 키
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            physics: const NeverScrollableScrollPhysics(),
            children:
                ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']
                    .map(
                      (key) => _keypadButton(
                        key,
                        onTap: () => widget.onChanged(_password + key),
                        height: buttonHeight,
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          // 제어 버튼
          SizedBox(
            height: buttonHeight,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onChanged(''),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.error50,
                      side: const BorderSide(color: AppColors.error500),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('전체 삭제'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (_password.isNotEmpty) {
                        widget.onChanged(
                          _password.substring(0, _password.length - 1),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gray300),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('삭제'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showKeypad = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('완료'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypadButton(
    String label, {
    required VoidCallback onTap,
    double fontSize = 16,
    double? height,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

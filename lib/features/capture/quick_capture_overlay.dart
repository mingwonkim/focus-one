// lib/features/capture/quick_capture_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';

/// 전역 단축키(Ctrl+Shift+Space)로 뜨는 브레인덤프 입력.
/// 원칙: 입력 → Enter → 즉시 닫힘. 3초 안에 원래 작업으로 복귀시키는 게 목표.
class QuickCaptureOverlay extends StatefulWidget {
  const QuickCaptureOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<QuickCaptureOverlay> createState() => _QuickCaptureOverlayState();
}

class _QuickCaptureOverlayState extends State<QuickCaptureOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 창이 뜨자마자 바로 타이핑 가능하게
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isNotEmpty) {
      context.read<AppState>().addToInbox(text);
    }
    _controller.clear();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = context.watch<AppState>().scene.style;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Container(
        decoration: BoxDecoration(
          color: style.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: style.cardBorder),
          boxShadow: AppShadow.floating(style.shadowColor),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '떠오른 생각을 던져두고 하던 일로 돌아가세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Enter로 저장 · Esc로 닫기',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

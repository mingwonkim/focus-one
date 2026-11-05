// lib/mobile/widgets/chunky.dart
// 입체 버튼·카드 (docs/v3/app-design-spec.md §4): 윗면 + 어두운 아랫단. 누르면 윗면이 내려간다.
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.style,
    this.label,
    this.icon,
    this.onTap,
    this.primary = true,
    this.expand = false,
    this.semanticLabel,
  });

  final SceneStyle style;
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool expand; // 가로 전체
  final String? semanticLabel; // 아이콘만 있을 때

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final lip = widget.primary
        ? MobileSize.chunkyLip
        : MobileSize.chunkyLipSecondary;
    final drop = widget.primary ? MobileSize.chunkyPress : lip - 1;
    final fg = widget.primary ? s.mobileFg : s.textStrong;
    final iconOnly = widget.label == null;
    final side = widget.primary ? 0.0 : MobileSize.chunkyBorder;
    final bottom = _down ? lip - drop : lip;
    final child = AnimatedContainer(
      duration: reduce
          ? Duration.zero
          : (_down ? AppDuration.press : AppDuration.release),
      curve: _down ? Curves.easeOut : Curves.easeOutCubic,
      margin: EdgeInsets.only(top: _down ? drop : 0),
      padding: EdgeInsets.fromLTRB(side, side, side, bottom + side),
      constraints: BoxConstraints(
          minHeight: (MobileSize.chunkyHeight - (_down ? drop : 0)),
          minWidth: iconOnly ? MobileSize.chunkyHeight : 0),
      decoration: BoxDecoration(
        color: widget.primary ? s.mobileBottom : s.secondaryLip,
        borderRadius: BorderRadius.circular(MobileSize.chunkyRadius),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.primary ? s.mobileFace : s.rowBg,
          borderRadius:
              BorderRadius.circular(MobileSize.chunkyRadius - side),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) Icon(widget.icon, size: 24, color: fg),
            if (!iconOnly && widget.icon != null) const SizedBox(width: 6),
            if (!iconOnly)
              Flexible(
                child: Text(
                  widget.label!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w800,
                      color: fg),
                ),
              ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.expand
              ? double.infinity
              : (iconOnly ? MobileSize.chunkyHeight : null),
          child: child,
        ),
      ),
    );
  }
}

/// 두꺼운 진행 막대. 넘친 값은 가득으로 보여 준다.
class ChunkyProgress extends StatelessWidget {
  const ChunkyProgress({super.key, required this.style, required this.value});

  final SceneStyle style;
  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: MobileSize.progressBar,
          color: style.divider,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: ColoredBox(color: style.mobileFace),
          ),
        ),
      );
}

/// 카드·칩: 두꺼운 테두리 + 아랫단. 불투명 받침이라 차오름 위에서도 글자가 읽힌다.
class ChunkySurface extends StatelessWidget {
  const ChunkySurface({
    super.key,
    required this.style,
    required this.child,
    this.radius = MobileSize.chunkyRadius,
    this.padding = EdgeInsets.zero,
    this.minHeight = 0,
  });

  final SceneStyle style;
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(
            MobileSize.chunkyBorder,
            MobileSize.chunkyBorder,
            MobileSize.chunkyBorder,
            MobileSize.chunkyBorder + MobileSize.chunkyLipSecondary),
        decoration: BoxDecoration(
          color: style.secondaryLip,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          decoration: BoxDecoration(
            color: style.rowBg,
            borderRadius:
                BorderRadius.circular(radius - MobileSize.chunkyBorder),
          ),
          child: child,
        ),
      );
}

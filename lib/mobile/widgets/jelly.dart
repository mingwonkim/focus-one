// lib/mobile/widgets/jelly.dart
// 젤리 UI: 둥근 알약, 위쪽 광택, 부드러운 색 그림자. 누르면 납작해졌다가 탱글하게 돌아온다.
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// 윗면은 밝게, 아랫면은 원래 색으로 — 말랑한 입체감
Gradient jellyGradient(Color base) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(base, AppColors.onPrimary, JellyLook.topLighten)!,
        base,
      ],
    );

List<BoxShadow> jellyShadow(Color color) => [
      BoxShadow(
        color: color.withValues(alpha: JellyLook.shadowAlpha),
        blurRadius: JellyLook.shadowBlur,
        offset: const Offset(0, JellyLook.shadowY),
      ),
    ];

/// 위쪽에 얹는 광택 한 줄
class JellyGloss extends StatelessWidget {
  const JellyGloss({super.key, required this.radius, this.alpha = JellyLook.glossAlpha});
  final double radius;
  final double alpha;

  @override
  Widget build(BuildContext context) => Positioned(
        top: JellyLook.glossInset,
        left: radius * JellyLook.glossSide,
        right: radius * JellyLook.glossSide,
        height: JellyLook.glossHeight,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ),
      );
}

/// 눌림: 납작해졌다가 튕겨 돌아옴. 동작 줄이기면 즉시.
class JellyPress extends StatefulWidget {
  const JellyPress({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<JellyPress> createState() => _JellyPressState();
}

class _JellyPressState extends State<JellyPress> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _down ? 1.0 : 0.0),
        duration: reduce
            ? Duration.zero
            : (_down ? AppDuration.press : AppDuration.jellyRelease),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
        builder: (_, v, child) => Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(
              1 + JellyLook.squashX * v, 1 - JellyLook.squashY * v, 1),
          child: child,
        ),
      ),
    );
  }
}

class JellyButton extends StatelessWidget {
  const JellyButton({
    super.key,
    required this.style,
    this.label,
    this.icon,
    this.onTap,
    this.primary = true,
    this.expand = false,
    this.onCard = false,
    this.semanticLabel,
  });

  final SceneStyle style;
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool expand;
  final bool onCard; // 흰 카드 위: 보조 버튼을 물들여 형체가 보이게
  final String? semanticLabel; // 아이콘만 있을 때

  @override
  Widget build(BuildContext context) {
    final fg = primary ? style.mobileFg : style.textStrong;
    final enabled = onTap != null;
    final iconOnly = label == null;
    final base = primary ? style.mobileFace : style.rowBg;
    final body = Container(
      constraints: BoxConstraints(
          minHeight: MobileSize.jellyHeight,
          minWidth: iconOnly ? MobileSize.jellyHeight : 0),
      padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: primary || onCard
            ? jellyGradient(onCard && !primary ? style.divider : base)
            : null,
        color: primary || onCard ? null : base,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: enabled
            ? jellyShadow(primary ? style.mobileBottom : style.secondaryLip)
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Icon(icon, size: 24, color: enabled ? fg : style.textFaint),
        if (!iconOnly && icon != null) const SizedBox(width: 6),
        if (!iconOnly)
          Flexible(
            child: Text(
              label!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  height: 1.3,
                  color: enabled ? fg : style.textFaint),
            ),
          ),
      ]),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: JellyPress(
        onTap: onTap,
        child: SizedBox(
          width: expand
              ? double.infinity
              : (iconOnly ? MobileSize.jellyHeight : null),
          child: Stack(children: [
            body,
            if (primary || onCard)
              const JellyGloss(radius: MobileSize.jellyHeight / 2),
          ]),
        ),
      ),
    );
  }
}

/// 진행 막대: 젤리 관. 넘친 값은 가득으로 보여 준다.
class JellyProgress extends StatelessWidget {
  const JellyProgress({super.key, required this.style, required this.value});

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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: jellyGradient(style.mobileFace),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ),
      );
}

/// 카드·칩: 말랑한 흰 면 + 부드러운 그림자. 불투명이라 차오름 위에서도 읽힌다.
class JellySurface extends StatelessWidget {
  const JellySurface({
    super.key,
    required this.style,
    required this.child,
    this.radius = MobileSize.jellyRadius,
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
        constraints: BoxConstraints(minHeight: minHeight),
        padding: padding,
        decoration: BoxDecoration(
          color: style.rowBg,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: jellyShadow(style.secondaryLip),
        ),
        child: child,
      );
}

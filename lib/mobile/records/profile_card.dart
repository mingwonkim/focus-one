// lib/mobile/records/profile_card.dart
// 기록 탭 맨 위 프로필: 칭호 테두리 아바타 · 닉네임 · 칭호 · 다음 칭호까지 · 명예의 전당 · 자랑하기.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../share/share_card.dart';
import '../widgets/title_avatar.dart';
import 'ranking_page.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.scene.style;
    final title = s.title;
    final total = s.focusMinutesTotal;
    final next = title.next;
    return Container(
      margin: const EdgeInsets.only(bottom: MobileSize.cardGap),
      padding: const EdgeInsets.all(MobileSize.cardPadding),
      decoration: BoxDecoration(
        color: style.rowBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card(style.rowShadow),
      ),
      child: Column(children: [
        Row(children: [
          TitleAvatar(
            title: title,
            asset: s.selectedCompanion.asset,
            background: style.cardBg,
          ),
          const SizedBox(width: MobileSize.cardPadding - 4),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.rankNickname ?? '나',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: style.textMuted)),
              Text(title.label,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: style.textStrong)),
            ]),
          ),
          IconButton(
            tooltip: '자랑하기',
            icon: Icon(Icons.ios_share_rounded, color: style.accent),
            onPressed: () => showShareSheet(context),
          ),
        ]),
        const SizedBox(height: MobileSize.cardGap + 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: title.progress(total),
            minHeight: 6,
            color: style.ringProgress,
            backgroundColor: style.ringTrack,
          ),
        ),
        const SizedBox(height: MobileSize.labelGap + 2),
        Row(children: [
          Expanded(
            child: Text(
                next == null
                    ? '가장 높은 칭호예요'
                    : '\'${next.label}\'까지 ${hm(title.remaining(total))}',
                style: TextStyle(fontSize: 13, color: style.textMuted)),
          ),
        ]),
        Divider(height: MobileSize.sectionGap, color: style.divider),
        InkWell(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RankingPage())),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: MobileSize.touchMin - 8),
            child: Row(children: [
              Icon(Icons.emoji_events_outlined, color: style.accent),
              const SizedBox(width: MobileSize.iconGap),
              Text('명예의 전당',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: style.textStrong)),
              const Spacer(),
              Text(s.rankNickname == null ? '참여하기' : '이번 주 · 이번 달',
                  style: TextStyle(fontSize: 13, color: style.textMuted)),
              Icon(Icons.chevron_right_rounded, color: style.textMuted),
            ]),
          ),
        ),
      ]),
    );
  }
}

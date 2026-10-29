import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/dhlottery_api.dart';

/// 주소 또는 상호명에서 직관적인 지역 태그 추출 (예: '서울 성북', '경기 성남', '세종', '온라인')
String extractWinningStoreRegion(DHLotteryWinningStore store) {
  if (store.address.contains('dhlottery') || store.name.contains('인터넷')) {
    return '온라인';
  }
  final cleanAddr = store.address.trim();
  final tokens = cleanAddr.split(RegExp(r'\s+'));
  if (tokens.isNotEmpty && tokens[0].isNotEmpty) {
    String s0 = tokens[0];
    if (s0.startsWith('전남광주') || s0 == '광주광역시') {
      s0 = '광주';
    } else if (s0 == '세종특별자치시' || s0.startsWith('세종')) {
      // 세종은 시/군/구가 없으므로 바로 '세종' 또는 읍/면 반환
      if (tokens.length >= 2 && (tokens[1].endsWith('읍') || tokens[1].endsWith('면'))) {
        return '세종 ${tokens[1]}';
      }
      return '세종';
    } else if (s0.endsWith('특별시') || s0.endsWith('광역시')) {
      s0 = s0.substring(0, s0.length - 3);
    } else if (s0 == '충청북도') {
      s0 = '충북';
    } else if (s0 == '충청남도') {
      s0 = '충남';
    } else if (s0 == '전라북도' || s0 == '전북특별자치도') {
      s0 = '전북';
    } else if (s0 == '전라남도') {
      s0 = '전남';
    } else if (s0 == '경상북도') {
      s0 = '경북';
    } else if (s0 == '경상남도') {
      s0 = '경남';
    } else if (s0 == '강원특별자치도' || s0 == '강원도') {
      s0 = '강원';
    } else if (s0 == '제주특별자치도' || s0 == '제주도') {
      s0 = '제주';
    } else if (s0.endsWith('특별자치도')) {
      s0 = s0.substring(0, 2);
    }

    if (tokens.length >= 2) {
      String s1 = tokens[1];
      if (s1.length > 2 && (s1.endsWith('구') || s1.endsWith('군') || s1.endsWith('시'))) {
        s1 = s1.substring(0, s1.length - 1);
      }
      return '$s0 $s1';
    }
    return s0;
  }
  if (store.region.isNotEmpty && store.region != 'null') {
    return store.region;
  }
  return '전국 명당';
}

/// VIP 1등 당첨 판매점 개별 카드 위젯
class WinningStoreCard extends StatelessWidget {
  final DHLotteryWinningStore store;
  final int index;
  final bool isLight;

  const WinningStoreCard({
    super.key,
    required this.store,
    required this.index,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = store.address.contains('dhlottery') || store.name.contains('인터넷');
    final regionLabel = extractWinningStoreRegion(store);

    final isRank2 = store.rank == 2;
    final hasSpecificType = store.winType == '수동' || store.winType == '반자동' || store.winType == '자동';

    final Color typeColor = isRank2
        ? const Color(0xFF1565C0)
        : (store.winType == '수동'
            ? const Color(0xFF2E7D32)
            : (store.winType == '반자동'
                ? const Color(0xFF7B1FA2)
                : (store.winType == '자동' ? const Color(0xFF1E88E5) : AppColors.textSecondary)));

    final typeIcon = isRank2
        ? Icons.military_tech_rounded
        : (store.winType == '수동'
            ? Icons.edit_note_rounded
            : (store.winType == '반자동' ? Icons.auto_awesome_rounded : Icons.bolt_rounded));

    final badgeLabel = isRank2
        ? '2등 배출점'
        : (hasSpecificType ? '${store.winType} 1등' : '1등 배출점');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.cardHover,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFEBE5D8)
              : AppColors.gold.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.035)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1열: [순번] [지역] [배출 방식]
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 순번 뱃지 (VIP 골드 알약)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLight
                        ? [const Color(0xFFF7EEDD), const Color(0xFFEFE2C5)]
                        : [const Color(0xFF332B18), const Color(0xFF241E10)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'NO. ${(index + 1).toString().padLeft(2, '0')}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isLight ? AppColors.goldDeep : AppColors.goldLight,
                  ),
                ),
              ),

              // 지역 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.black.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.language_rounded : Icons.place_rounded,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      regionLabel,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 배출 방식 뱃지 (자동 1등, 수동 1등 등)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isLight ? 0.12 : 0.22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.45),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 11.5, color: typeColor),
                    const SizedBox(width: 3),
                    Text(
                      badgeLabel,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2열: 상호명 (시원하고 또렷한 폰트)
          Text(
            store.name,
            style: GoogleFonts.notoSansKr(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // 3열: 상세 도로명 주소
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  store.address,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 은은한 구분선
          Divider(
            height: 1,
            thickness: 0.6,
            color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
          ),

          const SizedBox(height: 10),

          // 4열: 하단 액션 버튼 행: [주소 복사] & [지도에서 찾기 / 공식 사이트]
          Row(
            children: [
              // [주소 복사] 버튼
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: store.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${store.name} 주소가 복사되었습니다.',
                                style: GoogleFonts.notoSansKr(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7.5),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.black.withValues(alpha: 0.035) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          '주소 복사',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // [지도에서 찾기 / 공식 사이트] 버튼
              Expanded(
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final Uri targetUri;
                    if (isOnline) {
                      targetUri = Uri.parse('https://dhlottery.co.kr');
                    } else {
                      final cleanSearchAddr = store.address
                          .replaceAll(RegExp(r'\s+(\d+층|[가-힣A-Za-z0-9]+호|상가\s*.*)$'), '')
                          .trim();
                      final searchQuery = cleanSearchAddr.isNotEmpty ? cleanSearchAddr : store.name;
                      targetUri = Uri.parse(
                        'https://m.map.naver.com/search2/search.naver?query=${Uri.encodeComponent(searchQuery)}',
                      );
                    }
                    try {
                      if (await canLaunchUrl(targetUri)) {
                        await launchUrl(targetUri, mode: LaunchMode.externalApplication);
                      }
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7.5),
                    decoration: BoxDecoration(
                      color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: isLight ? 0.08 : 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isOnline ? Icons.open_in_browser_rounded : Icons.map_outlined,
                          size: 13,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isOnline ? '공식 사이트' : '지도에서 찾기',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isLight ? AppColors.goldDeep : AppColors.gold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

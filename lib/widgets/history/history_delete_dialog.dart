import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/history_service.dart';
import '../lotto_ball.dart';
import 'history_badges.dart';

/// 보관함 삭제 관련 프리미엄 럭셔리 VIP 모달 다이얼로그 헬퍼
class HistoryDeleteDialog {
  /// 단일 기록 삭제 확인 다이얼로그 표시
  static void showConfirmDeleteEntry({
    required BuildContext context,
    required LottoHistoryEntry entry,
    required VoidCallback onConfirm,
  }) {
    showLuxuryDeleteModal(
      context: context,
      badgeText: 'RECORD DELETION',
      title: '번호 기록을 삭제하시겠습니까?',
      subtitle: '보관함에서 삭제된 번호는 복구할 수 없습니다.',
      icon: Icons.delete_outline_rounded,
      confirmButtonText: '삭제하기',
      preview: _buildSingleEntryPreview(entry),
      onConfirm: onConfirm,
    );
  }

  /// 전체 기록 삭제 확인 다이얼로그 표시
  static void showConfirmClearAll({
    required BuildContext context,
    required int historyCount,
    required VoidCallback onConfirm,
  }) {
    showLuxuryDeleteModal(
      context: context,
      badgeText: 'CLEAR ALL RECORDS',
      title: '보관함을 모두 비우시겠습니까?',
      subtitle: '보관함에 저장된 모든 번호 기록이 영구히 삭제됩니다.',
      icon: Icons.delete_sweep_rounded,
      confirmButtonText: '모두 삭제',
      preview: _buildClearAllPreview(historyCount),
      onConfirm: onConfirm,
    );
  }

  /// 보관함 삭제 확인 전용 럭셔리 VIP 모달 공통 함수
  static void showLuxuryDeleteModal({
    required BuildContext context,
    required String badgeText,
    required String title,
    required String subtitle,
    required IconData icon,
    required String confirmButtonText,
    required Widget preview,
    required VoidCallback onConfirm,
  }) {
    HapticFeedback.lightImpact();
    final isLight = AppColors.isLight;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * anim.value,
            sigmaY: 8 * anim.value,
          ),
          child: Transform.scale(
            scale: 0.9 + (0.1 * curvedValue),
            child: Opacity(
              opacity: anim.value.clamp(0.0, 1.0),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF191820),
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isLight
                          ? [
                              const Color(0xFFFFFFFF),
                              const Color(0xFFFAF7F2),
                            ]
                          : [
                              const Color(0xFF23212C),
                              const Color(0xFF15141B),
                            ],
                    ),
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFFFCDD2).withValues(alpha: 0.8)
                          : const Color(0xFFFF5252).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.16 : 0.6),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF5252).withValues(alpha: isLight ? 0.08 : 0.16),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. 헤더: 럭셔리 이중 글로우 아이콘 뱃지
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF5252).withValues(alpha: isLight ? 0.16 : 0.22),
                              const Color(0xFFFF5252).withValues(alpha: 0.02),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFF5252).withValues(alpha: isLight ? 0.3 : 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isLight
                                    ? [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)]
                                    : [const Color(0xFF3B1518), const Color(0xFF230B0D)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: const Color(0xFFFF5252),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. 카테고리 태그 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: isLight ? 0.08 : 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.rajdhani(
                            color: const Color(0xFFFF6B6B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3. 타이틀
                      Text(
                        title,
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textPrimary,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // 4. 서브타이틀
                      Text(
                        subtitle,
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      // 5. 대상 정보 미리보기 카드 (번호 공 / 복권 정보 등)
                      preview,
                      const SizedBox(height: 22),

                      // 6. 하단 액션 버튼 (취소 / 삭제하기)
                      Row(
                        children: [
                          // 취소 버튼
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(dialogCtx),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13.5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isLight
                                        ? Colors.black.withValues(alpha: 0.04)
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isLight
                                          ? const Color(0xFFDCD2C3)
                                          : Colors.white.withValues(alpha: 0.12),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '취소',
                                      style: GoogleFonts.notoSansKr(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 삭제 버튼 (프리미엄 크림슨 그라데이션)
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(dialogCtx);
                                  onConfirm();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(vertical: 13.5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF5252),
                                        Color(0xFFD32F2F),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          confirmButtonText,
                                          style: GoogleFonts.notoSansKr(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 단일 기록 삭제 미리보기 카드
  static Widget _buildSingleEntryPreview(LottoHistoryEntry entry) {
    final isLight = AppColors.isLight;
    final timeStr =
        '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE2D8C8)
              : Colors.white.withValues(alpha: 0.09),
          width: 0.9,
        ),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              LottoTypeBadge(type: entry.entryType),
              LottoDrawBadge(
                drawNo: entry.drawNo,
                gameCount: entry.isTicket ? entry.gameCount : null,
              ),
              Text(
                timeStr,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (entry.numbers.isNotEmpty && !entry.isTicket) ...[
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: entry.numbers.map((n) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: LottoBall(number: n, size: 28),
                  );
                }).toList(),
              ),
            ),
          ] else if (entry.isTicket) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.goldText),
                const SizedBox(width: 6),
                Text(
                  '실물 복권 총 ${entry.gameCount}게임 수록',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.goldText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 전체 삭제 미리보기 카드
  static Widget _buildClearAllPreview(int totalCount) {
    final isLight = AppColors.isLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5252).withValues(alpha: isLight ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF5252).withValues(alpha: 0.25),
          width: 0.9,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFFF5252)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '총 $totalCount개의 저장된 기록',
                  style: GoogleFonts.notoSansKr(
                    color: const Color(0xFFFF5252),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '생성된 추천 번호 및 QR 스캔 복권이 모두 영구 삭제됩니다.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

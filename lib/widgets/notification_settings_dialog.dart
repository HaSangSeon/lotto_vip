import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  bool _isEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = NotificationService.isEnabled;
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() {
      _isLoading = true;
    });

    await NotificationService.setNotificationEnabled(value);

    if (mounted) {
      setState(() {
        _isEnabled = value;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
              ? '🔔 토요일 로또 추첨 결과 알림이 켜졌습니다.'
              : '🔕 로또 추첨 결과 알림이 꺼졌습니다.',
            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: value ? AppColors.goldDark : Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    await NotificationService.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📨 테스트 알림이 발송되었습니다. 상단 알림 바를 확인해보세요!',
            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AppColors.goldDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.isLight
                ? AppColors.lightGoldBorder
                : AppColors.borderGold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.isLight
                  ? AppColors.goldDark.withValues(alpha: 0.15)
                  : AppColors.gold.withValues(alpha: 0.15),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    _isEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    color: _isEnabled ? AppColors.gold : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '추첨 결과 알림 설정',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '매주 토요일 당첨 결과 리마인더',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 20),

            // 알림 토글 카드
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isEnabled
                      ? AppColors.gold.withValues(alpha: 0.4)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '토요일 추첨 결과 알림',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.isLight
                                    ? const Color(0xFFFFF0C2)
                                    : AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.isLight
                                      ? const Color(0xFFD4AF37)
                                      : Colors.transparent,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '토 20:45',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '추첨 직후 내 번호 맞추기 리마인더 발송',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch.adaptive(
                      value: _isEnabled,
                      activeThumbColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                      activeTrackColor: AppColors.goldDark.withValues(alpha: 0.5),
                      onChanged: _toggleNotification,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 알림 메시지 미리보기 박스
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mark_chat_unread_outlined,
                          size: 14, color: AppColors.goldText),
                      const SizedBox(width: 6),
                      Text(
                        '발송되는 알림 미리보기',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💰 혹시… 이번 주 1등 당첨자이신가요?',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '로또 추첨이 완료되었습니다. 저장해둔 내 번호와 지금 맞춰보세요! 🎰',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 테스트 발송 버튼
            OutlinedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                '지금 테스트 알림 받아보기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldText,
                side: BorderSide(
                  color: AppColors.isLight
                      ? const Color(0xFFD4AF37)
                      : AppColors.gold.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 닫기 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '닫기',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  bool _hasSystemPermission = true;

  @override
  void initState() {
    super.initState();
    _isEnabled = NotificationService.isEnabled;
    _checkSystemPermission();
  }

  Future<void> _checkSystemPermission() async {
    final granted = await NotificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _hasSystemPermission = granted;
      });
    }
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() {
      _isLoading = true;
    });

    await NotificationService.setNotificationEnabled(value);
    final granted = await NotificationService.areNotificationsEnabled();

    if (mounted) {
      setState(() {
        _isEnabled = value;
        _hasSystemPermission = granted;
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



  Future<void> _sendTestDelayedNotification() async {
    final success = await NotificationService.scheduleTestDelayedNotification(seconds: 10);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '⏱️ 10초 뒤 예약 알림이 등록되었습니다!\n지금 바로 스마트폰 화면을 끄고 10초만 기다려보세요! 🔔'
                : '⚠️ 예약 알림 등록에 실패했습니다. 권한을 확인해주세요.',
            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.3),
          ),
          backgroundColor: success ? AppColors.goldDark : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
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

            // 스마트폰 시스템 레벨 알림 차단 시 경고 배너
            if (_isEnabled && !_hasSystemPermission) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  await NotificationService.requestPermission();
                  _checkSystemPermission();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '스마트폰 시스템 알림이 꺼져 있습니다.\n여기를 눌러 알림 권한을 허용해 주세요.',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.amber.shade700, size: 18),
                    ],
                  ),
                ),
              ),
            ],

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

            // 10초 뒤 예약 알림 테스트 버튼 (AlarmManager 및 잠금화면 검증용)
            OutlinedButton.icon(
              onPressed: _sendTestDelayedNotification,
              icon: const Icon(Icons.timer_outlined, size: 16),
              label: Text(
                '⏱️ 10초 뒤 예약 알림 테스트 (화면 끄고 확인)',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldText,
                backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                side: BorderSide(
                  color: AppColors.isLight
                      ? const Color(0xFFD4AF37)
                      : AppColors.gold.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 닫기 버튼 (프리미엄 라운드 버튼)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                  foregroundColor: AppColors.isLight ? Colors.white : Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  '닫기',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AppInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.15),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 36),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: AppColors.isLight
                    ? [AppColors.goldDark, AppColors.gold]
                    : [AppColors.goldLight, AppColors.gold],
              ).createShader(bounds),
              child: Text(
                '로또 신통 v1.1.4',
                style: GoogleFonts.notoSansKr(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '프리미엄 로또 생성기 안내',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.auto_awesome,
              '오늘의 행운 번호',
              '생년월일과 오늘 날짜를 조합하여 매일 나만을 위한 고유 행운 번호를 뽑아드립니다.',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.tune,
              '맞춤 번호 조합',
              '꼭 넣고 싶은 번호와 빼고 싶은 번호를 직접 골라 나만의 로또 번호를 조합합니다.',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.analytics,
              '빅데이터 통계 분석',
              '역대 동행복권 당첨 데이터를 바탕으로 HOT/COLD 번호를 한눈에 분석합니다.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardHover,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '※ 본 앱에서 제공하는 번호는 분석 및 알고리즘 기반 참고 자료이며, 실제 당첨을 보장하지 않습니다.',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('확인', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

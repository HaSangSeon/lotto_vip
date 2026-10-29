import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class CalculationLoadingDialog extends StatefulWidget {
  final String title;
  final String step1;
  final String step2;

  const CalculationLoadingDialog({
    super.key,
    required this.title,
    required this.step1,
    required this.step2,
  });

  @override
  State<CalculationLoadingDialog> createState() => _CalculationLoadingDialogState();
}

class _CalculationLoadingDialogState extends State<CalculationLoadingDialog> {
  late String _currentStep;
  Timer? _stepTimer;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.step1;
    _stepTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _currentStep = widget.step2);
      }
    });
    _closeTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.borderGold,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _currentStep,
                  key: ValueKey(_currentStep),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.isLight ? AppColors.goldDark : AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '알고리즘 연산 진행 중...',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

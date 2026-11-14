import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Logotipo institucional EcoGestão utilizado nas telas de entrada e cabeçalhos.
class EcoBrandLogo extends StatelessWidget {
  final bool showSubtitle;
  final double iconSize;
  final double titleSize;

  const EcoBrandLogo({
    super.key,
    this.showSubtitle = true,
    this.iconSize = 36,
    this.titleSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize + 10,
          height: iconSize + 10,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.eco_rounded,
            color: AppColors.primaryDark,
            size: iconSize * 0.8,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EcoGestão',
              style: GoogleFonts.poppins(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                height: 1.1,
              ),
            ),
            if (showSubtitle)
              Text(
                'CONSULTORIA E GESTÃO AMBIENTAL',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// lib/constants/design_system.dart
// lib/constants/design_system.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Kept to fix your unused import warning

class CipherColors {
  // Primary
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryDark = Color(0xFF3C3489);
  
  // Secondary
  static const Color secondary = Color(0xFF43E97B);
  static const Color secondaryLight = Color(0xFFE8FFF4);
  static const Color secondaryDark = Color(0xFF085041);
  
  // Accent Pink
  static const Color pink = Color(0xFFFF6584);
  static const Color pinkLight = Color(0xFFFFF0F4);
  static const Color pinkDark = Color(0xFF72243E);
  
  // Accent Blue
  static const Color blue = Color(0xFF4C86FF);
  static const Color blueLight = Color(0xFFE6F1FF);
  static const Color blueDark = Color(0xFF0C447C);
  
  // Accent Orange
  static const Color orange = Color(0xFFFFA726);
  static const Color orangeLight = Color(0xFFFFF8E8);
  static const Color orangeDark = Color(0xFF633806);
  
  // Neutrals
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
    
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF43E97B), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
    
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFFF6584), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
    
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFF6584)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
    
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF4C86FF), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================================
  // ALIASES & MAPPINGS TO FIXED SCREEN ERRORS SYSTEM-WIDE
  // ==========================================================================
  
  // Fixes notes_screen, study_screen, quiz_screen color references
  static const Color purplePrimary = primary;
  static const Color pinkPrimary = pink;
  static const Color greenPrimary = secondary;
  static const Color orangePrimary = orange;

  // Background aliases for cards (Notes, Tasks, Quiz, AI panels)
  static const Color notesBg = primaryLight;
  static const Color tasksBg = pinkLight;
  static const Color quizBg = secondaryLight;
  static const Color aiBg = orangeLight;

  // Text colors used across study_screen.dart
  static const Color notesText = textPrimary;
  static const Color tasksText = textPrimary;
  static const Color quizText = textPrimary;
  static const Color aiText = textPrimary;

  // Subtitle colors used across panels
  static const Color notesSub = textSecondary;
  static const Color tasksSub = textSecondary;
  static const Color quizSub = textSecondary;
  static const Color aiSub = textSecondary;

  // Gradient redirects
  static const LinearGradient purpleGradient = primaryGradient;
  static const LinearGradient headerGradient = blueGradient;
}

class CipherTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: CipherColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: CipherColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: CipherColors.textPrimary,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CipherColors.textSecondary,
  );
  
  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CipherColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CipherColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static const TextStyle caption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: CipherColors.textSecondary,
  );
  
  static const TextStyle headingWhite = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  
  static const TextStyle subtitleWhite = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  // ==========================================================================
  // DYNAMIC COMPATIBILITY METHOD FOR POPPINS DYNAMIC LOOKUPS
  // ==========================================================================
  
  /// Generates text configurations directly via Google Fonts dynamically 
  /// resolving all dynamic 'poppins' errors in screen builders.
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? alpha,
  }) {
    Color? finalColor = color;
    if (alpha != null && finalColor != null) {
      finalColor = finalColor.withValues(alpha: alpha);
    }
    
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: finalColor,
    );
  }
}
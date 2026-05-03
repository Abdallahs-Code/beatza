
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  
  static Brightness _brightness = Brightness.dark;

  static void setThemeBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get _isDark => _brightness == Brightness.dark;

  
  
  
  static const Color brilliantOrange = Color(0xFFFF9533);
  static const Color crusta = Color(
    0xFFFF7F34,
  ); 
  static const Color papaya = Color(
    0xFFFE6D35,
  ); 
  static const Color inferno = Color(
    0xFFFF5836,
  ); 
  static const Color anger = Color(
    0xFFFF4137,
  ); 
  static const Color gentlePeach = Color(
    0xFFFFE9E1,
  ); 

  
  static const Color primaryOrange = Color(0xFFFF5500);
  
  
  

  
  static const Color orangeQrCode = Color(
    0xFFF97316,
  ); 
  static const Color primaryOrangeAccent = Color(
    0xFFFF3D00,
  ); 
  static const Color proBadgeOrange = Color(
    0xFFE65100,
  ); 

  
  

  static Color get homeBackground => _isDark
      ? const Color(0xFF0A0A0A) 
      : const Color(0xFFF5F1EC); 

  static Color get chineseBlack => _isDark
      ? const Color(
          0xFF121212,
        ) 
      : const Color(0xFFF0EDE8); 

  static Color get pureBlack => _isDark
      ? const Color(
          0xFF000000,
        ) 
      : const Color(0xFFF5F1EC); 

  
  static Color get backgroundDeepest => _isDark
      ? const Color(
          0xFF090909,
        ) 
      : const Color(0xFFEDE8E2); 

  static Color get backgroundVeryDark => _isDark
      ? const Color(
          0xFF0B0B0B,
        ) 
      : const Color(0xFFEDE8E2); 

  static Color get backgroundDark3 => _isDark
      ? const Color(
          0xFF0F0F0F,
        ) 
      : const Color(0xFFEDE8E2); 

  static Color get backgroundDark => _isDark
      ? const Color(
          0xFF111111,
        ) 
      : const Color(0xFFE8E2DC); 

  static Color get backgroundDark2 => _isDark
      ? const Color(
          0xFF141414,
        ) 
      : const Color(0xFFF5F1EC); 

  
  static Color get surfaceDark => _isDark
      ? const Color(
          0xFF181818,
        ) 
      : const Color(0xFFEEEAE5); 

  static Color get cardDark => _isDark
      ? const Color(
          0xFF202020,
        ) 
      : Colors.white; 

  static Color get cardDark2 => _isDark
      ? const Color(
          0xFF222222,
        ) 
      : const Color(0xFFFAF8F5); 

  static Color get surface => _isDark
      ? const Color(
          0xFF1C1C1C,
        ) 
      : const Color(0xFFFAF8F5); 

  static Color get surfaceMid => _isDark
      ? const Color(
          0xFF1E1E1E,
        ) 
      : Colors.white; 

  static Color get cardDark3 => _isDark
      ? const Color(
          0xFF171717,
        ) 
      : const Color(0xFFE5E1DC); 

  
  static Color get container => _isDark
      ? const Color(
          0xFF1A1A1A,
        ) 
      : const Color(0xFFEFEBE6); 

  static Color get containerMid => _isDark
      ? const Color(
          0xFF2A2A2A,
        ) 
      : const Color(0xFFE2DDD7); 

  static Color get containerDark => _isDark
      ? const Color(0xFF252525) 
      : const Color(0xFFD8D3CD); 

  
  static const Color paymentDialogBg = Color(
    0xFF2C2C2E,
  ); 
  static const Color paymentLightBg = Color(
    0xFFF2F2F7,
  ); 

  
  static Color get borderDark => _isDark
      ? const Color(
          0xFF2D2D2D,
        ) 
      : const Color(0xFFD0CBC5); 

  
  static Color get tileDark =>
      _isDark ? const Color(0xFF323232) : const Color(0xFFE5E0DA);

  static Color get tileDark2 =>
      _isDark ? const Color(0xFF383838) : const Color(0xFFDDD8D2);

  static Color get tileDark3 => _isDark
      ? const Color(0xFF3A3A3A) 
      : const Color(0xFFD5D0CA);

  static Color get tileDark4 => _isDark
      ? const Color(0xFF3B3B3B) 
      : const Color(0xFFCDC8C2);

  static Color get tileDark5 => _isDark
      ? const Color(
          0xFF444444,
        ) 
      : const Color(0xFFC5C0BA);

  
  static Color get inputFill => _isDark
      ? const Color(
          0xFF333333,
        ) 
      : const Color(
          0xFFECE8E3,
        ); 

  static Color get greyInputDark => _isDark
      ? const Color(0xFFD9D9D9) 
      : Colors.black87;

  static Color get greyButton => _isDark
      ? const Color(
          0xFFB3B3B3,
        ) 
      : Colors.grey[600]!;

  
  
  static Color get whiteSmoke => _isDark
      ? const Color(
          0xFFF4F4F4,
        ) 
      : const Color(0xFF1A1A1A);

  
  static Color get white10 => _isDark
      ? Colors
            .white10 
      : Colors.black12;

  static Color get white12 => _isDark
      ? Colors
            .white12 
      : Colors.black12;

  static Color get white24 => _isDark
      ? Colors
            .white24 
      : Colors.black26;

  static Color get white54 => _isDark
      ? Colors
            .white54 
      : Colors.black54;

  static Color get white60 => _isDark
      ? Colors
            .white60 
      : Colors.black54;

  static Color get white70 => _isDark
      ? Colors
            .white70 
      : Colors.black87;

  static Color get black54 => _isDark
      ? Colors
            .white54 
      : Colors.black54;

  
  static Color get silver => _isDark
      ? const Color(
          0xFFA0A0A0,
        ) 
      : Colors.grey[600]!;

  static Color get greyZinc => _isDark
      ? const Color(
          0xFF9A9A9A,
        ) 
      : Colors.grey[600]!;

  static Color get greyMedium => _isDark
      ? const Color(
          0xFF9A9A9A,
        ) 
      : Colors.grey[600]!;

  static Color get greyDark => _isDark
      ? const Color(0xFF808080) 
      : Colors.grey[500]!;

  static Color get greyEnabled => _isDark
      ? const Color(
          0xFFCACACA,
        ) 
      : Colors.grey[800]!;

  static Color get greyLight => _isDark
      ? const Color(0xFFCCCCCC) 
      : Colors.grey[700]!;

  static Color get greyIcon => _isDark
      ? const Color(0xFFAAAAAA) 
      : Colors.grey[600]!;

  
  static Color get greyDark3 => _isDark
      ? const Color(
          0xFF888888,
        ) 
      : Colors.grey[600]!;

  static Color get greyDark4 => _isDark
      ? const Color(0xFF888888) 
      : Colors.grey[500]!;

  static Color get greyMid => _isDark
      ? const Color(
          0xFF777777,
        ) 
      : Colors.grey[600]!;

  static Color get greyMid2 => _isDark
      ? const Color(0xFF888888) 
      : Colors.grey[600]!; 

  static Color get greyMuted => _isDark
      ? const Color(
          0xFF999999,
        ) 
      : Colors
            .grey[600]!; 

  static Color get greyBright => _isDark
      ? const Color(0xFFDDDDDD) 
      : Colors.grey[800]!;

  
  static const Color blueHyperlink = Color(
    0xFF699FFF,
  ); 
  static const Color blueAccent = Color(
    0xFF2F7CF6,
  ); 
  static const Color blueWelcome = Color(
    0xFF5A8DEE,
  ); 
  static Color get blueCard => _isDark
      ? const Color(
          0xFF243B63,
        ) 
      : const Color(0xFFE3F2FD);
  static const Color mixBlue = Color(
    0xFF2D4A7A,
  ); 
  static const Color mixLabelBlue = Color(
    0xFF93B5FF,
  ); 
  static const Color dailyDropsBlue = Color(
    0xFF4E6DFF,
  ); 
  static const Color stationBackground = Color(
    0xFF1E2A38,
  ); 
  static const Color glowBlue = Color(0xFF3B82F6); 
  static const Color linkBlue = Color(
    0xFF2C6BED,
  ); 
  static const Color primaryBlue = Color(
    0xFF1B64D1,
  ); 
  static const Color profileAccentBlue = Color(
    0xFF4F5DFF,
  ); 
  static const Color badgeBlue = Color(
    0xFF1976D2,
  ); 
  static const Color iOSBlue = Color(
    0xFF0A84FF,
  ); 
  static const Color lightBlue = Color(
    0xFF64B5F6,
  ); 

  
  static const Color successGreen = Color(
    0xFF00D632,
  ); 
  static const Color whatsAppGreen = Color(
    0xFF32D74B,
  ); 
  static const Color messagingGreen = Color(
    0xFF25D366,
  ); 

  
  static const Color deepRed = Color(
    0xFFC62828,
  ); 

  
  static const Color likesGradientEnd = Color(0xFF722100);

  
  static const Color glowPurple = Color(
    0xFF8B5CF6,
  ); 
  static const Color proBadgePurple = Color(
    0xFF8E24AA,
  ); 
  static const Color premiumPurple = Color(
    0xFF6B1B9A,
  ); 
  static const Color premiumDarkPink = Color(
    0xFF880E4F,
  ); 
  static const Color premiumDarkPurple = Color(
    0xFF4A148C,
  ); 
  static const Color premiumDarkBlue = Color(
    0xFF311B92,
  ); 
  static const Color flashPurple = Color(
    0xFFD47AFA,
  ); 

  
  static const Color chipPink = Color(
    0xFFFF4F7B,
  ); 
  static const Color instagramPink = Color(
    0xFFE1306C,
  ); 
  static const Color buzzingPink = Color(
    0xFFEC4899,
  ); 

  
  static const Color buzzingYellow = Color(
    0xFFFACC15,
  ); 
  static const Color snapchatYellow = Color(
    0xFFFFFC00,
  ); 

  
  static const Color buzzingCyan = Color(
    0xFF22D3EE,
  ); 

  
  static const Color glowOrange = Color(
    0xFFFF7F34,
  ); 

  
  
  static const Color notifLike = Color(
    0xFFFF4B6E,
  ); 
  static const Color notifComment = Color(
    0xFF4B9EFF,
  ); 
  static const Color notifFollow = Color(
    0xFF2DB44A,
  ); 
  static const Color notifOther = Color(
    0xFFF59E0B,
  ); 
  static const Color notifAlt = Color(
    0xFFA855F7,
  ); 

  
  
  static const Color googleBackGround = Color(
    0xFF484848,
  ); 
  

  
  
  static const Color vibeAltRockStart = Color(0xFFC0392B);
  static const Color vibeAltRockEnd = Color(0xFF922B21);
  static const Color vibeAmbientStart = Color(0xFF0097A7);
  static const Color vibeAmbientEnd = Color(0xFF006064);
  static const Color vibeClassicalStart = Color(0xFF546E7A);
  static const Color vibeClassicalEnd = Color(0xFF37474F);
  static const Color vibeCountryStart = Color(0xFFF57F17);
  static const Color vibeCountryEnd = Color(
    0xFFE65100,
  ); 
  static const Color vibeElectronicStart = Color(0xFFE91E63);
  static const Color vibeElectronicEnd = Color(0xFFAD1457);
  static const Color vibeHipHopStart = Color(0xFF6B2FBA);
  static const Color vibeHipHopEnd = Color(
    0xFF4A148C,
  ); 
  static const Color vibeHouseStart = Color(0xFFFF5722);
  static const Color vibeHouseEnd = Color(0xFFBF360C);
  static const Color vibeIndieStart = Color(0xFF388E3C);
  static const Color vibeIndieEnd = Color(0xFF1B5E20);
  static const Color vibeJazzStart = Color(0xFF795548);
  static const Color vibeJazzEnd = Color(0xFF3E2723);
  static const Color vibeLatinStart = Color(0xFFF44336);
  static const Color vibeLatinEnd = Color(0xFFB71C1C);
  static const Color vibeMetalStart = Color(0xFF455A64);
  static const Color vibeMetalEnd = Color(0xFF263238);
  static const Color vibePopStart = Color(0xFFFFD600);
  static const Color vibePopEnd = Color(0xFFFFC107);
  static const Color vibeRnBStart = Color(0xFF00BCD4);
  static const Color vibeRnBEnd = Color(0xFF006064); 
  static const Color vibeReggaeStart = Color(0xFF2E7D32);
  static const Color vibeReggaeEnd = Color(0xFF1B5E20); 
  static const Color vibeRockStart = Color(0xFFD32F2F);
  static const Color vibeRockEnd = Color(0xFFB71C1C); 
  static const Color vibeSoulStart = Color(0xFF7B1FA2);
  static const Color vibeSoulEnd = Color(
    0xFF4A148C,
  ); 
  static const Color vibeTrapStart = Color(0xFF283593);
  static const Color vibeTrapEnd = Color(0xFF1A237E);
  static const Color vibeWorldMusicStart = Color(0xFF00695C);
  static const Color vibeWorldMusicEnd = Color(0xFF004D40);

  
  static Color get errorContainerDark => _isDark
      ? const Color(0xFF3B1111) 
      : const Color(0xFFFFEBEE);

  static Color get successContainerDark => _isDark
      ? const Color(0xFF0F3B21) 
      : const Color(0xFFE8F5E9);

  static Color get uploadProgressBg => _isDark
      ? const Color(0xFF2A1B38) 
      : const Color(0xFFEDE7F6);

  static Color get proFeatureBadgeBg => _isDark
      ? const Color(0xFF3B2F2F) 
      : const Color(0xFFFFF3E0);

  static Color get blockBannerBg => _isDark
      ? const Color(0xFF161616) 
      : const Color(0xFFF5F5F5);

  static Color get artistStudioGradientStart => _isDark
      ? const Color(0xFF381E4B) 
      : const Color(0xFFEDE7F6);

  static Color get destructiveDisabledBg => _isDark
      ? const Color(0xFF5C1F1F) 
      : const Color(0xFFFFCDD2);

  static Color get datePickerDisabledBg => _isDark
      ? const Color(0xFF3A2A1A) 
      : const Color(0xFFFFF8F0);

  static Color get genericDisabledButtonBg => _isDark
      ? const Color(0xFF424242) 
      : const Color(0xFFE0E0E0);

  static const Color insightsChartFill =
      Color(0xFF2A0055); 

  
  static const Color errorRed =
      Color(0xFFFF6B6B); 
  static const Color errorSoft =
      Color(0xFFE57373); 
  static const Color removeRed =
      Color(0xFFE53935); 

  
  static const Color datepickerGreen =
      Color(0xFF1DB954); 
  static const Color completedGreen =
      Color(0xFF49D17D); 
  static const Color progressOrange =
      Color(0xFFFF6A00); 

  
  static const Color timestampPillBg =
      Color(0xFF1A4BB8); 
  static Color get trueFriendsBg => _isDark
      ? const Color(0xFF212121) 
      : const Color(0xFFEFEBE6);
  static const Color welcomeLoginButton =
      Color(0xFFBBD2FE); 

  
  static const Color studioActionBlue =
      Color(0xFF4A90E2); 

  
  static const Color waveformInactive =
      Color(0xFFBDBDBD); 
  static Color get waveformInactiveDark => _isDark
      ? const Color(0xFFBDBDBD)
      : const Color(0xFF9E9E9E);

  
  static const Color uploadGlowPurple =
      Color(0xFF8A2BE2); 

  
  static const Color transparent = Color(
    0x00000000,
  ); 
}

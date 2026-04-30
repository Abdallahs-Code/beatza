// Dart imports
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── THEME CONTROL ─────────────────────────────────────────────────────────
  static Brightness _brightness = Brightness.dark;
  
  static void setThemeBrightness(Brightness brightness) {
    _brightness = brightness;
  }
  
  static bool get _isDark => _brightness == Brightness.dark;

  // ── BRAND ORANGE GRADIENT ─────────────────────────────────────────────────
  // Gradient spectrum used in: playback mini-player bar, playback now-playing
  // card, library widgets, upload screen buttons, audio upload track management
  static const Color brilliantOrange = Color(0xFFFF9533);
  static const Color crusta = Color(
    0xFFFF7F34,
  ); // glow effects (same value as glowOrange)
  static const Color papaya = Color(
    0xFFFE6D35,
  ); // home_widgets accent border/background
  static const Color inferno = Color(
    0xFFFF5836,
  ); // library_widgets, playback_mini_player_bar, playback_debug_track_tile gradient
  static const Color anger = Color(
    0xFFFF4137,
  ); // error states: email_entry_screen, login_screen, password_screen, verify_code_screen, check_inbox_screen, playback_debug_track_tile
  static const Color gentlePeach = Color(
    0xFFFFE9E1,
  ); // glow / highlight overlay effects

  // Primary orange used as the app's action colour across many features
  static const Color primaryOrange = Color(0xFFFF5500);
  // Used in: messaging (chat_screen, messages_tab, attach_content_sheet),
  //          activity_screen, playback_now_playing_card, user_profile_screen,
  //          common_widgets, quick_reply_sheet

  // Orange variants used in specific contexts
  static const Color orangeQrCode = Color(
    0xFFF97316,
  ); // login_screen QR-code icon, login_widgets primary button
  static const Color primaryOrangeAccent = Color(
    0xFFFF3D00,
  ); // settings_screen star icon, premium_subscription badge
  static const Color proBadgeOrange = Color(
    0xFFE65100,
  ); // promo_subscription_screen badge, vibes_grid Country secondary

  // ── BACKGROUNDS ───────────────────────────────────────────────────────────
  // Layered dark backgrounds ordered from lightest to darkest

  static Color get homeBackground => _isDark
      ? const Color(0xFF0A0A0A)   // home_screen scaffold, playback_debug_screen
      : Colors.white;
  
  static Color get chineseBlack => _isDark
      ? const Color(0xFF121212)   // email_entry_screen, create_password_screen, password_screen, search_screen, genre_tracks_screen, common_widgets
      : Colors.grey[50]!;
  
  static Color get pureBlack => _isDark
      ? const Color(0xFF000000)   // login_widgets, offline_downloads_screen, recently_played_screen, premium screens
      : Colors.white;

  // Fine-grained dark tiers (used when chineseBlack / pureBlack is too light)
  static Color get backgroundDeepest => _isDark
      ? const Color(0xFF090909)   // global_playback_overlay barrier, edit_profile_screen overlay, track_options_sheet
      : Colors.grey[100]!;
  
  static Color get backgroundVeryDark => _isDark
      ? const Color(0xFF0B0B0B)   // user_profile_screen, edit_profile_screen very-dark sections
      : Colors.grey[50]!;
  
  static Color get backgroundDark3 => _isDark
      ? const Color(0xFF0F0F0F)   // artist_pro_screens, pro_restrictions_screen, edit_spotlight_screen, your_uploads_spotlight_screen
      : Colors.grey[100]!;
  
  static Color get backgroundDark => _isDark
      ? const Color(0xFF111111)   // settings_screen, messaging (chat_screen, activity_screen)
      : Colors.grey[200]!;
  
  static Color get backgroundDark2 => _isDark
      ? const Color(0xFF141414)   // user_profile_screen scaffold, profile_header_widget, edit_spotlight_screen
      : Colors.white;

  // ── SURFACES / CARDS ──────────────────────────────────────────────────────
  static Color get surfaceDark => _isDark
      ? const Color(0xFF181818)   // home_widgets, playback_mini_player_bar, feed_card placeholder, library_widgets
      : Colors.grey[100]!;
  
  static Color get cardDark => _isDark
      ? const Color(0xFF202020)   // home_widgets, playback_debug_track_tile, playback_now_playing_card, library screens, playback_debug_screen
      : Colors.white;
  
  static Color get cardDark2 => _isDark
      ? const Color(0xFF222222)   // messaging snackbar, quick_reply_options_menu icon bg, login_widgets card variant
      : Colors.grey[50]!;

  static Color get surface => _isDark
      ? const Color(0xFF1C1C1C)   // global_playback_overlay, messaging (messages_tab, chat_screen), activity_screen
      : Colors.grey[50]!;
  
  static Color get surfaceMid => _isDark
      ? const Color(0xFF1E1E1E)   // home_screen card bg, settings_screen card, account_settings_screen picker, user_profile_screen, edit_spotlight_screen, premium_subscription card
      : Colors.white;

  static Color get cardDark3 => _isDark
      ? const Color(0xFF171717)   // global_playback_overlay dark cards, user_profile_screen cards
      : Colors.grey[200]!;

  // Container shades for modals / bottom-sheets / dialogs
  static Color get container => _isDark
      ? const Color(0xFF1A1A1A)   // comment_tile bg, repost_bottom_sheet, activity_screen dialog, quick_reply_sheet dialog
      : Colors.grey[100]!;
  
  static Color get containerMid => _isDark
      ? const Color(0xFF2A2A2A)   // account_settings_screen divider, global_playback_overlay, messaging (attach_content_sheet button), user_profile_screen controls, activity_screen follow-state bg
      : Colors.grey[200]!;
  
  static Color get containerDark => _isDark
      ? const Color(0xFF252525)   // repost_bottom_sheet input field
      : Colors.grey[300]!;

  // Payment sheet (iOS-style light surface)
  static const Color paymentDialogBg = Color(
    0xFF2C2C2E,
  ); // payment_checkout_sheet dark dialog overlay
  static const Color paymentLightBg = Color(
    0xFFF2F2F7,
  ); // payment_checkout_sheet light background (iOS sheet style)

  // ── BORDERS / TILES / SKELETON ────────────────────────────────────────────
  static Color get borderDark => _isDark
      ? const Color(0xFF2D2D2D)   // home_widgets, playback_mini_player_bar, playback_now_playing_card, library_widgets, playback_debug_screen
      : Colors.grey[300]!;

  // Loading-skeleton tile shades (home_widgets, library_widgets, listening_history_screen, recently_played_screen)
  static Color get tileDark => _isDark
      ? const Color(0xFF323232)
      : Colors.grey[200]!;
  
  static Color get tileDark2 => _isDark
      ? const Color(0xFF383838)
      : Colors.grey[300]!;
  
  static Color get tileDark3 => _isDark
      ? const Color(0xFF3A3A3A)   // also settings_screen border (non-pro item)
      : Colors.grey[300]!;
  
  static Color get tileDark4 => _isDark
      ? const Color(0xFF3B3B3B)   // also playback_debug_track_tile gradient end
      : Colors.grey[400]!;
  
  static Color get tileDark5 => _isDark
      ? const Color(0xFF444444)   // also behind_the_track_screen icon container bg
      : Colors.grey[400]!;

  // ── INPUT FIELDS ──────────────────────────────────────────────────────────
  static Color get inputFill => _isDark
      ? const Color(0xFF333333)   // login_widgets text-field fill, password_input_field fill
      : Colors.grey[200]!;
  
  static Color get greyInputDark => _isDark
      ? const Color(0xFFD9D9D9)   // verify_code_screen OTP input box
      : Colors.black87;
  
  static Color get greyButton => _isDark
      ? const Color(0xFFB3B3B3)   // verify_code_screen resend button, user_info_screen placeholder text
      : Colors.grey[600]!;

  // ── TEXT / ICON WHITES ────────────────────────────────────────────────────
  // Primary text in dark UI
  static Color get whiteSmoke => _isDark
      ? const Color(0xFFF4F4F4)   // home_widgets primary text, library screens, playback_mini_player_bar, playback_debug_screen, account_settings_screen, listening_history_screen, recently_played_screen, common_widgets
      : const Color(0xFF1A1A1A);

  // Semi-transparent white palette (text / icon hierarchy across nearly every screen)
  static Color get white10 => _isDark
      ? Colors.white10   // subtle borders: home_widgets, login_widgets, settings_screen, library_widgets, common_widgets
      : Colors.black12;
  
  static Color get white12 => _isDark
      ? Colors.white12   // borders: home_widgets, library screens, playback, activity_screen dividers
      : Colors.black12;
  
  static Color get white24 => _isDark
      ? Colors.white24   // overlays: home_widgets, home_screen border, common_widgets slider inactive
      : Colors.black26;
  
  static Color get white54 => _isDark
      ? Colors.white54   // secondary text/icons: used across all screens (search bar, feed, library, auth widgets)
      : Colors.black54;
  
  static Color get white60 => _isDark
      ? Colors.white60   // secondary text: library screens, playback, home, account_settings_screen
      : Colors.black54;
  
  static Color get white70 => _isDark
      ? Colors.white70   // secondary text: authentication screens, home, playback, settings
      : Colors.black87;

  static Color get black54 => _isDark
      ? Colors.black54   // home_widgets feed text overlay, feed_card secondary text, payment_checkout_sheet barrier
      : Colors.white54;

  // ── GREY TEXT / ICON PALETTE ──────────────────────────────────────────────
  static Color get silver => _isDark
      ? const Color(0xFFA0A0A0)   // placeholder text: email_entry_screen, create_password_screen, password_screen
      : Colors.grey[600]!;

  static Color get greyZinc => _isDark
      ? const Color(0xFF71717A)   // profile_header_widget icon, animated_stat_widget placeholder
      : Colors.grey[700]!;
  
  static Color get greyMedium => _isDark
      ? const Color(0xFF9A9A9A)   // user_profile_screen text, edit_profile_screen placeholder; also activity_screen waveform-fill reference
      : Colors.grey[600]!;
  
  static Color get greyDark => _isDark
      ? const Color(0xFF6E6E6E)   // edit_profile_screen disabled text
      : Colors.grey[500]!;
  
  static Color get greyEnabled => _isDark
      ? const Color(0xFFCACACA)   // edit_profile_screen enabled text (non-focused)
      : Colors.grey[800]!;
  
  static Color get greyLight => _isDark
      ? const Color(0xFFCCCCCC)   // user_profile_screen light secondary text
      : Colors.grey[700]!;
  
  static Color get greyIcon => _isDark
      ? const Color(0xFFAAAAAA)   // activity_screen notification icon colour
      : Colors.grey[600]!;

  // Specific grey values used in activity / quick-reply UI
  static Color get greyDark3 => _isDark
      ? const Color(0xFF555555)   // quick_reply_options_menu icon, activity_screen icon bg
      : Colors.grey[700]!;
  
  static Color get greyDark4 => _isDark
      ? const Color(0xFF666666)   // quick_reply_sheet divider grey
      : Colors.grey[600]!;
  
  static Color get greyMid => _isDark
      ? const Color(0xFF777777)   // behind_the_track_screen secondary text, quick_reply_sheet text variant
      : Colors.grey[600]!;
  
  static Color get greyMid2 => _isDark
      ? const Color(0xFF888888)   // quick_reply_sheet light text variant
      : Colors.grey[500]!;
  
  static Color get greyMuted => _isDark
      ? const Color(0xFF999999)   // behind_the_track_screen grey text, activity_screen unfilled waveform
      : Colors.grey[400]!;
  
  static Color get greyBright => _isDark
      ? const Color(0xFFDDDDDD)   // quick_reply_sheet lightest text
      : Colors.grey[800]!;

  // ── ACCENT BLUES ──────────────────────────────────────────────────────────
  static const Color blueHyperlink = Color(
    0xFF699FFF,
  ); // auth_link_text widget, check_inbox_screen link, library_widgets link text
  static const Color blueAccent = Color(
    0xFF2F7CF6,
  ); // user_info_screen accent, verify_code_screen link/accent
  static const Color blueWelcome = Color(
    0xFF5A8DEE,
  ); // welcome_screen button, welcome_widgets container bg
  static Color get blueCard => _isDark
      ? const Color(0xFF243B63)   // home_widgets featured card bg, home_screen featured card
      : const Color(0xFFE3F2FD);
  static const Color mixBlue = Color(
    0xFF2D4A7A,
  ); // home_widgets mix-blend colour
  static const Color mixLabelBlue = Color(
    0xFF93B5FF,
  ); // home_widgets mix label text
  static const Color dailyDropsBlue = Color(
    0xFF4E6DFF,
  ); // home_widgets daily-drops accent, home_screen daily-drops badge
  static const Color stationBackground = Color(
    0xFF1E2A38,
  ); // home_widgets station card background
  static const Color glowBlue = Color(0xFF3B82F6); // glow overlay effects
  static const Color linkBlue = Color(
    0xFF2C6BED,
  ); // comment_tile mention/link, global_playback_overlay accent
  static const Color primaryBlue = Color(
    0xFF1B64D1,
  ); // edit_spotlight_screen title, pro_restrictions_screen title
  static const Color profileAccentBlue = Color(
    0xFF4F5DFF,
  ); // user_profile_screen blue section accent
  static const Color badgeBlue = Color(
    0xFF1976D2,
  ); // premium_subscription plan badge
  static const Color iOSBlue = Color(
    0xFF0A84FF,
  ); // premium_subscription CTA button, payment_checkout_sheet Pay button, Apple Pay highlight border
  static const Color lightBlue = Color(
    0xFF64B5F6,
  ); // premium_subscription light-blue feature highlight

  // ── GREENS ────────────────────────────────────────────────────────────────
  static const Color successGreen = Color(
    0xFF00D632,
  ); // settings_screen online indicator, payment_checkout_sheet Link-Pay button bg, Cash-App icon bg
  static const Color whatsAppGreen = Color(
    0xFF32D74B,
  ); // user_profile_screen WhatsApp share button
  static const Color messagingGreen = Color(
    0xFF25D366,
  ); // user_profile_screen messaging/WhatsApp alternate

  // ── REDS / DEEP REDS ──────────────────────────────────────────────────────
  static const Color deepRed = Color(
    0xFFC62828,
  ); // settings_screen destructive/warning action button

  // Gradient end for the Likes section on home_widgets
  static const Color likesGradientEnd = Color(0xFF722100);

  // ── PURPLES ───────────────────────────────────────────────────────────────
  static const Color glowPurple = Color(
    0xFF8B5CF6,
  ); // glow overlay effects, user_profile_screen Discord share icon
  static const Color proBadgePurple = Color(
    0xFF8E24AA,
  ); // settings_screen Pro-badge border, promo_subscription_screen Free / Pro badge
  static const Color premiumPurple = Color(
    0xFF6B1B9A,
  ); // promo_subscription_screen Free-plan gradient start
  static const Color premiumDarkPink = Color(
    0xFF880E4F,
  ); // promo_subscription_screen Artist-plan gradient start
  static const Color premiumDarkPurple = Color(
    0xFF4A148C,
  ); // promo_subscription_screen Pro-plan gradient start; vibes_grid Hip-Hop secondary
  static const Color premiumDarkBlue = Color(
    0xFF311B92,
  ); // promo_subscription_screen Label-plan gradient start
  static const Color flashPurple = Color(
    0xFFD47AFA,
  ); // edit_spotlight_screen flash/spotlight icon

  // ── PINKS ─────────────────────────────────────────────────────────────────
  static const Color chipPink = Color(
    0xFFFF4F7B,
  ); // home_widgets chip selection, library_widgets filter chip
  static const Color instagramPink = Color(
    0xFFE1306C,
  ); // user_profile_screen Instagram share button
  static const Color buzzingPink = Color(
    0xFFEC4899,
  ); // home_widgets "Buzzing" section gradient

  // ── YELLOWS ───────────────────────────────────────────────────────────────
  static const Color buzzingYellow = Color(
    0xFFFACC15,
  ); // home_widgets "Buzzing" section gradient
  static const Color snapchatYellow = Color(
    0xFFFFFC00,
  ); // user_profile_screen Snapchat share button

  // ── CYANS ─────────────────────────────────────────────────────────────────
  static const Color buzzingCyan = Color(
    0xFF22D3EE,
  ); // home_widgets "Buzzing" section gradient

  // ── GLOW EFFECTS ──────────────────────────────────────────────────────────
  static const Color glowOrange = Color(
    0xFFFF7F34,
  ); // same value as crusta — used for orange glow overlays

  // ── NOTIFICATION / ACTIVITY INDICATOR COLOURS ────────────────────────────
  // activity_screen — colour-coded dot beside each notification type
  static const Color notifLike = Color(
    0xFFFF4B6E,
  ); // "like" notification indicator
  static const Color notifComment = Color(
    0xFF4B9EFF,
  ); // "comment" notification indicator
  static const Color notifFollow = Color(
    0xFF2DB44A,
  ); // "follow" notification indicator
  static const Color notifOther = Color(
    0xFFF59E0B,
  ); // generic / repost notification indicator
  static const Color notifAlt = Color(
    0xFFA855F7,
  ); // alternate notification type indicator

  // ── SOCIAL MEDIA BRAND COLOURS ────────────────────────────────────────────
  // user_profile_screen share-sheet buttons
  static const Color googleBackGround = Color(
    0xFF484848,
  ); // login_widgets Google-sign-in button bg
  // whatsAppGreen / messagingGreen / instagramPink / snapchatYellow / glowPurple (Discord) defined above

  // ── GENRE / VIBE TILE GRADIENTS ───────────────────────────────────────────
  // feed_search_discovery/widgets/vibes_grid.dart — each pair is [start, end]
  static const Color vibeAltRockStart = Color(0xFFC0392B);
  static const Color vibeAltRockEnd = Color(0xFF922B21);
  static const Color vibeAmbientStart = Color(0xFF0097A7);
  static const Color vibeAmbientEnd = Color(0xFF006064);
  static const Color vibeClassicalStart = Color(0xFF546E7A);
  static const Color vibeClassicalEnd = Color(0xFF37474F);
  static const Color vibeCountryStart = Color(0xFFF57F17);
  static const Color vibeCountryEnd = Color(
    0xFFE65100,
  ); // same as proBadgeOrange
  static const Color vibeElectronicStart = Color(0xFFE91E63);
  static const Color vibeElectronicEnd = Color(0xFFAD1457);
  static const Color vibeHipHopStart = Color(0xFF6B2FBA);
  static const Color vibeHipHopEnd = Color(
    0xFF4A148C,
  ); // same as premiumDarkPurple
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
  static const Color vibeRnBEnd = Color(0xFF006064); // same as vibeAmbientEnd
  static const Color vibeReggaeStart = Color(0xFF2E7D32);
  static const Color vibeReggaeEnd = Color(0xFF1B5E20); // same as vibeIndieEnd
  static const Color vibeRockStart = Color(0xFFD32F2F);
  static const Color vibeRockEnd = Color(0xFFB71C1C); // same as vibeLatinEnd
  static const Color vibeSoulStart = Color(0xFF7B1FA2);
  static const Color vibeSoulEnd = Color(
    0xFF4A148C,
  ); // same as premiumDarkPurple / vibeHipHopEnd
  static const Color vibeTrapStart = Color(0xFF283593);
  static const Color vibeTrapEnd = Color(0xFF1A237E);
  static const Color vibeWorldMusicStart = Color(0xFF00695C);
  static const Color vibeWorldMusicEnd = Color(0xFF004D40);

  // ── UTILITY ───────────────────────────────────────────────────────────────
  static const Color transparent = Color(
    0x00000000,
  ); // used across all screens as no-op colour
}
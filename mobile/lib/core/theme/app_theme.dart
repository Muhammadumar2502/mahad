// Mahad Test — ThemeData for Kun (light) and Tun (dark).
// Reference implementation: adapt to the existing `core/theme.dart` (AppTheme.light) without
// touching any business logic. Requires `google_fonts` (or bundle Cormorant Garamond + Lora as assets).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mahad_colors.dart';
import '../../widgets/mahad_shapes.dart';
import 'transitions.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData kun = _build(MahadColors.kun, Brightness.light);
  static final ThemeData tun = _build(MahadColors.tun, Brightness.dark);

  /// Old name kept for compatibility.
  static ThemeData get light => kun;

  /// Display font (headings, numbers): Cormorant Garamond with lining figures.
  static TextStyle display(double size, FontWeight weight, double lineHeight, Color color) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        color: color,
        fontFeatures: const [FontFeature.liningFigures()],
      );

  /// Body font: Lora.
  static TextStyle body(double size, FontWeight weight, double lineHeight, Color color) =>
      GoogleFonts.lora(fontSize: size, fontWeight: weight, height: lineHeight / size, color: color);

  static TextTheme _textTheme(MahadColors c) => TextTheme(
        displayLarge: display(36, FontWeight.w600, 40, c.ink), // tab sarlavhasi: Asosiy, Profil
        headlineMedium: display(28, FontWeight.w700, 32, c.ink), // ekran sarlavhasi
        headlineSmall: display(25, FontWeight.w700, 30, c.ink), // dialog sarlavhasi
        titleLarge: display(22, FontWeight.w700, 26, c.ink), // karta sarlavhasi
        titleMedium: body(15.5, FontWeight.w600, 21, c.ink), // ro'yxat qatori nomi
        titleSmall: body(14, FontWeight.w600, 20, c.ink),
        bodyLarge: body(18.5, FontWeight.w500, 29, c.ink), // savol matni
        bodyMedium: body(15, FontWeight.w400, 22, c.ink), // variant, asosiy matn
        bodySmall: body(12.5, FontWeight.w400, 17, c.muted), // ikkinchi darajali matn
        labelLarge: body(15, FontWeight.w600, 20, c.ink), // tugma
        labelMedium: body(12, FontWeight.w600, 16, c.ink), // pill
        labelSmall: body(11.5, FontWeight.w700, 16, c.goldText).copyWith(letterSpacing: 2.3), // SAVOL 3 / 20
      );

  static ThemeData _build(MahadColors c, Brightness brightness) {
    // Fonts are bundled in assets/google_fonts (offline); never fetch at runtime.
    GoogleFonts.config.allowRuntimeFetching = false;
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? c.primaryEnd : c.primaryStart;
    final text = _textTheme(c);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: c.priText,
      secondary: c.gold,
      onSecondary: isDark ? c.priText : c.ink,
      error: c.bad,
      onError: c.badOn,
      surface: c.card,
      onSurface: c.ink,
      surfaceContainerHighest: c.card2,
      surfaceContainerHigh: c.card2,
      surfaceContainer: c.card,
      onSurfaceVariant: c.muted,
      outline: c.frame,
      outlineVariant: c.hair,
      scrim: c.scrim,
      shadow: Colors.black,
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.pageFlat,
      textTheme: text,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: mahadPageTransitions,
      appBarTheme: AppBarTheme(
        // Ekranlar sarlavhasi `BandHeader` (yashil tasma) bilan chiziladi; AppBar shaffof.
        backgroundColor: Colors.transparent,
        foregroundColor: c.bandText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: display(28, FontWeight.w700, 32, c.bandText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: c.priText,
          disabledBackgroundColor: c.disBg,
          disabledForegroundColor: c.disText,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: buttonShape.copyWith(side: BorderSide(color: c.gold.withValues(alpha: 0.55))),
          textStyle: body(15, FontWeight.w600, 20, c.priText),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.secBg,
          foregroundColor: c.secText,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: c.secBd),
          shape: buttonShape,
          textStyle: body(15, FontWeight.w600, 20, c.secText),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? c.goldText : c.emerald,
          textStyle: body(15, FontWeight.w600, 20, c.ink),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: body(16, FontWeight.w400, 22, c.placeholder),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputBd)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputFocus, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.bad)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputBd)),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.frame)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        barrierColor: c.scrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.frame)),
        titleTextStyle: display(25, FontWeight.w700, 30, c.ink),
        contentTextStyle: body(14.5, FontWeight.w400, 22, c.ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.sheetBg,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: c.navBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.navActiveEnd,
        indicatorShape: const MihrabBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? body(11.5, FontWeight.w700, 15, c.navActiveText)
              : body(11.5, FontWeight.w500, 15, c.navText),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.navActiveIcon : c.navText, size: 22),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: primary,
        side: BorderSide(color: c.frame),
        shape: const StadiumBorder(),
        labelStyle: body(13.5, FontWeight.w500, 18, c.ink),
        secondaryLabelStyle: body(13.5, FontWeight.w600, 18, c.priText),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.toastOkBg, // xato toast: c.toastBadBg (Session.toast ichida)
        contentTextStyle: body(14, FontWeight.w600, 20, c.toastOkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.gold.withValues(alpha: 0.45))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.spinner,
        circularTrackColor: c.spinnerTrack,
        linearTrackColor: c.progBg,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.checkOn : c.card),
        checkColor: WidgetStatePropertyAll(c.checkMark),
        side: BorderSide(color: c.checkBd, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? (isDark ? c.card : c.priText) : c.card),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : c.card3),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.gold : c.goldDeep),
      ),
      dividerTheme: DividerThemeData(color: c.hair, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.icon, size: 22),
    );
  }
}

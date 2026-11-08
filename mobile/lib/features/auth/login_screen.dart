import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/device.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../data/repository.dart';
import '../home/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialMessage});

  /// Masalan: "Qurilma bloklangan" — sessiya tugaganda ko'rsatiladi.
  final String? initialMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _mask = MaskTextInputFormatter(mask: '## ### ## ##', filter: {'#': RegExp(r'[0-9]')});
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialMessage;
    final last = Session.user?.phone ?? '';
    if (last.startsWith('+998') && last.length == 13) {
      _phone.text = _mask.maskText(last.substring(4));
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _digits => _mask.unmaskText(_phone.text);
  bool get _valid => _digits.length == 9 && _password.text.length >= 8;

  Future<void> _submit() async {
    if (!_valid || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Repo.login(phone: '+998$_digits', password: _password.text);
      Session.group(force: true).ignore();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Kutilmagan xatolik yuz berdi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final mq = MediaQuery.of(context);
    const band = 170.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: c.pageFlat,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: c.pageGradient),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: mq.size.height),
              child: Stack(
                children: [
                  const BandBackground(height: band),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, band - 54, 24, 24 + mq.padding.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: FadeSlideIn(
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -10)],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.asset('assets/logo/splash_logo_512.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Xush kelibsiz!', textAlign: TextAlign.center, style: AppTheme.display(36, FontWeight.w700, 40, c.ink)),
                        const SizedBox(height: 6),
                        Text(
                          'Telefon raqam va parolingiz bilan kiring',
                          textAlign: TextAlign.center,
                          style: AppTheme.body(14, FontWeight.w400, 20, c.muted),
                        ),
                        const SizedBox(height: 28),
                        Text('Telefon raqam', style: AppTheme.body(13.5, FontWeight.w600, 18, c.ink)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phone,
                          inputFormatters: [_mask],
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          style: AppTheme.body(16.5, FontWeight.w500, 22, c.ink),
                          decoration: InputDecoration(
                            hintText: '90 123 45 67',
                            fillColor: c.inputBg,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('+998', style: AppTheme.body(16.5, FontWeight.w700, 22, c.ink)),
                                  const SizedBox(width: 12),
                                  Container(width: 1, height: 22, color: c.hair),
                                ],
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Parol', style: AppTheme.body(13.5, FontWeight.w600, 18, c.ink)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                          style: AppTheme.body(16.5, FontWeight.w500, 22, c.ink),
                          decoration: InputDecoration(
                            hintText: 'Kamida 8 ta belgi',
                            fillColor: c.inputBg,
                            suffixIcon: IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: MIcon(_obscure ? Iconsax.eye_slash : Iconsax.eye, key: ValueKey(_obscure), color: c.muted, size: 21),
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          child: _error == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: c.badTint,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: c.bad.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        StarMedallion(
                                          size: 24,
                                          tone: MedallionTone.bad,
                                          child: Text('!', style: AppTheme.body(12, FontWeight.w800, 14, c.bad)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(_error!, style: AppTheme.body(13.5, FontWeight.w600, 19, c.badText))),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        MahadButton(
                          onPressed: _valid && !_loading ? _submit : null,
                          loading: _loading,
                          label: 'Kirish',
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Har bir akkaunt faqat bitta qurilmada ishlaydi.\nQurilmani almashtirish uchun admin bilan bog\'laning.',
                          textAlign: TextAlign.center,
                          style: AppTheme.body(12.5, FontWeight.w400, 18, c.muted),
                        ),
                        const SizedBox(height: 8),
                        Text('v${DeviceData.appVersion}', textAlign: TextAlign.center, style: AppTheme.body(12, FontWeight.w400, 16, c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

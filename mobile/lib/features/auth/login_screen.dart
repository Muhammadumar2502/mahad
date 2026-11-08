import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../core/api_client.dart';
import '../../core/device.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(28)),
                    child: Image.asset('assets/images/splash_logo.png'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Xush kelibsiz!', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Telefon raqam va parolingiz bilan kiring',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),
                const Text('Telefon raqam', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  inputFormatters: [_mask],
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '90 123 45 67',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Text('+998', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Parol', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Kamida 8 ta belgi',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Iconsax.danger, color: AppColors.red),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: TextStyle(color: AppColors.red))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _valid && !_loading ? _submit : null,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Kirish'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Har bir akkaunt faqat bitta qurilmada ishlaydi.\nQurilmani almashtirish uchun admin bilan bog\'laning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9), fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Text('v${DeviceData.appVersion}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_divider.dart';
import '../widgets/labeled_field.dart';
import '../widgets/padel_header.dart';
import '../widgets/social_login_button.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // The prototype logs straight through without validating credentials —
    // this mirrors that "fast test" shortcut from the design chat.
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.read(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const PadelHeader(title: '🎾 Padelicious', showBack: false, centerTitle: true),
            const GradientDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    const Text("Log in to join today's session", style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    LabeledField(label: 'Email', controller: _email, hint: 'you@email.com', keyboardType: TextInputType.emailAddress, errorText: _emailError),
                    LabeledField(label: 'Password', controller: _password, hint: '••••••••', obscureText: true, errorText: _passwordError),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _remember = !_remember),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged: (v) => setState(() => _remember = v ?? false),
                                  activeColor: AppColors.green,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text('Remember me', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: const Text('Forgot password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.teal)),
                          ),
                        ],
                      ),
                    ),
                    PrimaryButton(label: 'Log in →', onPressed: _submit),
                    OrDivider('OR CONTINUE WITH'.toUpperCase()),
                    GmailSignInButton(onPressed: () => appState.showToast('Social login — coming soon')),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text('New to Padelicious? ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: const Text('Create account', style: TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

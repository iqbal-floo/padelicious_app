import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_divider.dart';
import '../widgets/labeled_field.dart';
import '../widgets/padel_header.dart';
import '../widgets/social_login_button.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _agreeError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final nameError = _name.text.trim().isEmpty ? 'Name is required' : null;
    final emailError = validateEmail(_email.text);
    String? passwordError;
    if (_password.text.isEmpty) {
      passwordError = 'Password is required';
    } else if (_password.text.length < 6) {
      passwordError = 'At least 6 characters';
    }
    final confirmError = _confirm.text != _password.text ? 'Passwords do not match' : null;
    final agreeError = _agree ? null : 'Please accept the club rules';

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _agreeError = agreeError;
    });

    if ([nameError, emailError, passwordError, confirmError, agreeError].any((e) => e != null)) return;

    AppStateScope.read(context).showToast('Welcome to Padelicious! 🎾');
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
            const PadelHeader(title: 'Create account', subtitle: 'PADELICIOUS · Join the club'),
            const GradientDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Let's get you playing 🎾", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    const Text('Create your player profile in a minute', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    LabeledField(label: 'Full name', controller: _name, hint: 'Iqbal Ramadhan', errorText: _nameError),
                    LabeledField(label: 'Email', controller: _email, hint: 'you@email.com', keyboardType: TextInputType.emailAddress, errorText: _emailError),
                    LabeledField(label: 'Password', controller: _password, hint: 'At least 6 characters', obscureText: true, errorText: _passwordError),
                    LabeledField(label: 'Confirm password', controller: _confirm, hint: 'Re-enter password', obscureText: true, errorText: _confirmError),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: InkWell(
                        onTap: () => setState(() => _agree = !_agree),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agree,
                              onChanged: (v) => setState(() => _agree = v ?? false),
                              activeColor: AppColors.green,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'I agree to the Padelicious Club Rules and Terms',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_agreeError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(_agreeError!, style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 16),
                    PrimaryButton(label: 'Create account →', onPressed: () => _submit(context)),
                    OrDivider('OR SIGN UP WITH'),
                    GmailSignInButton(onPressed: () => appState.showToast('Social login — coming soon')),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text('Log in', style: TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w800)),
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

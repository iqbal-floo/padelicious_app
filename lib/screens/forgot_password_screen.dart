import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/gradient_divider.dart';
import '../widgets/labeled_field.dart';
import '../widgets/padel_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final error = validateEmail(_email.text);
    setState(() => _emailError = error);
    if (error != null) return;
    AppStateScope.read(context).showToast('Reset link sent! Check your inbox 📩');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const PadelHeader(title: 'Reset password', subtitle: 'PADELICIOUS · Account recovery'),
            const GradientDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Forgot your password? 🔑', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    const Text(
                      "No worries — enter the email linked to your account and we'll send a reset link.",
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                    ),
                    LabeledField(label: 'Email', controller: _email, hint: 'you@email.com', keyboardType: TextInputType.emailAddress, errorText: _emailError),
                    const SizedBox(height: 20),
                    PrimaryButton(label: 'Send reset link', onPressed: _submit),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text('Remembered it? ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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

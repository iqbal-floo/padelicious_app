import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/gender_selector.dart';
import '../widgets/gradient_divider.dart';
import '../widgets/labeled_field.dart';
import '../widgets/padel_header.dart';

/// Lets an existing account set the fields registration may have skipped —
/// most importantly gender, which the mixed match formats require.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _fullName;
  late final TextEditingController _displayName;
  String? _gender;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = AppStateScope.read(context).auth;
    final player = auth.user?['player'] as Map?;

    _fullName = TextEditingController(
      text: auth.user?['full_name'] as String? ?? '',
    );
    _displayName = TextEditingController(
      text: player?['display_name'] as String? ?? '',
    );
    final current = player?['gender'] as String?;
    _gender = (current == null || current == 'undisclosed') ? null : current;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = AppStateScope.read(context).auth;

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await auth.updateProfile(
      fullName: _fullName.text.trim().isEmpty ? null : _fullName.text.trim(),
      displayName:
          _displayName.text.trim().isEmpty ? null : _displayName.text.trim(),
      gender: _gender,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.ok) {
      setState(() => _error = result.message);
      return;
    }

    AppStateScope.read(context).showToast('Profile updated');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const PadelHeader(
              title: 'Edit profile',
              subtitle: 'PADELICIOUS · Your details',
            ),
            const GradientDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledField(
                      label: 'Full name',
                      controller: _fullName,
                      hint: 'Iqbal Ramadhan',
                    ),
                    LabeledField(
                      label: 'Display name',
                      controller: _displayName,
                      hint: 'Iqbal',
                    ),
                    const SizedBox(height: 14),
                    GenderSelector(
                      value: _gender,
                      onChanged: (v) => setState(() => _gender = v),
                      helperText:
                          'Mixed formats pair one man with one woman, so this '
                          'is required to join them.',
                      errorText: _error,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _busy ? 'Saving…' : 'Save changes',
                      onPressed: _busy ? null : _save,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textFaint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

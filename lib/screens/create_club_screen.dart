import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';

class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final appState = AppStateScope.read(context);
    if (_name.text.trim().isEmpty) {
      appState.showToast('Give your club a name');
      return;
    }
    await appState.createClub(name: _name.text.trim(), description: _description.text.trim());
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create club',
      subtitle: 'Start your own community',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SectionCard(children: [
            SectionCardRow(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Club name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                    decoration: const InputDecoration(hintText: 'Sunday Smashers', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  ),
                ],
              ),
            ),
            SectionCardRow(
              showDivider: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
                    decoration: const InputDecoration(hintText: "What's your club about?", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Create club', onPressed: _submit),
        ],
      ),
    );
  }
}

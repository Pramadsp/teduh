import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/core/theme/app_colors.dart';
import 'package:teduh/features/auth/data/auth_service.dart';
import 'package:teduh/features/transactions/data/firestore_repositories.dart';

class HouseholdSetupScreen extends ConsumerStatefulWidget {
  final String uid;

  const HouseholdSetupScreen({super.key, required this.uid});

  @override
  ConsumerState<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends ConsumerState<HouseholdSetupScreen> {
  final _authService = AuthService();
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  final _householdNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  bool _isCreating = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _householdNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _submitCreate() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final household = await _authService.createHousehold(
        uid: widget.uid,
        householdName: _householdNameController.text.trim(),
      );

      // Seed kategori default ke Firestore
      final firestoreCategoryRepo = FirestoreCategoryRepository(householdId: household.id);
      await firestoreCategoryRepo.seedDefaultCategories();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitJoin() async {
    if (!_joinFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.joinHouseholdWithCode(
        uid: widget.uid,
        inviteCode: _inviteCodeController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup Keluarga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Buat Grup Baru')),
                ButtonSegment(value: false, label: Text('Gabung Kode')),
              ],
              selected: {_isCreating},
              onSelectionChanged: (val) {
                setState(() {
                  _isCreating = val.first;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.expense, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isCreating) ...[
              Form(
                key: _createFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _householdNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Keluarga / Rumah Tangga',
                        hintText: 'Contoh: Keluarga Pratama',
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Nama grup wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitCreate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Buat Grup Keluarga'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Form(
                key: _joinFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _inviteCodeController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Kode Undangan (6 Karakter)',
                        hintText: 'Contoh: A8K9X2',
                      ),
                      validator: (val) =>
                          val == null || val.trim().length < 6 ? 'Masukkan 6 karakter kode' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitJoin,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Gabung Grup'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

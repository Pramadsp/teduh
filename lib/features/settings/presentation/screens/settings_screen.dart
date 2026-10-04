import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/core/theme/app_colors.dart';
import 'package:teduh/features/categories/presentation/screens/category_list_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.sageDark.withValues(alpha: 0.15),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sageDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.category_outlined, color: AppColors.sageDark, size: 22),
              ),
              title: const Text(
                'Kelola Kategori',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              subtitle: Text(
                'Tambah, ubah, atau hapus kategori transaksi',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.6),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.sageDark),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CategoryListScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.sageDark.withValues(alpha: 0.15),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sageDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.sageDark, size: 22),
              ),
              title: const Text(
                'Versi Aplikasi',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              subtitle: Text(
                'v1.0.7 (Teduh Official Release)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

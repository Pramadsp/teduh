import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/core/theme/app_colors.dart';
import 'package:teduh/features/categories/presentation/screens/category_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.sand,
              child: Icon(Icons.category, color: AppColors.sageDark),
            ),
            title: const Text(
              'Kelola Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Tambah, ubah, atau hapus kategori transaksi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoryListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.sand,
              child: Icon(Icons.info_outline, color: AppColors.sageDark),
            ),
            title: Text('Versi Aplikasi'),
            subtitle: Text('0.4.0 (Teduh Local Beta)'),
          ),
        ],
      ),
    );
  }
}

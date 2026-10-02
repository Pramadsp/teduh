import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/core/theme/app_colors.dart';
import 'package:teduh/features/auth/data/auth_service.dart';
import 'package:teduh/features/auth/domain/user_profile.dart';
import 'package:teduh/features/household/domain/household_model.dart';
import 'package:teduh/features/household/presentation/widgets/transfer_modal.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, String currentUid, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: AppColors.cream,
            title: const Text(
              'Ubah Nama Profil',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: const TextStyle(color: AppColors.sageDark, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppColors.sand,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.sageDark.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.sageDark.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.sageDark, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama wajib diisi';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Batal', style: TextStyle(color: AppColors.sageDark)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                        });

                        try {
                          final newName = nameController.text.trim();
                          final authService = AuthService();
                          await authService.updateDisplayName(uid: currentUid, newDisplayName: newName);

                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.sageDark,
                                content: Text(
                                  'Nama profil berhasil diperbarui',
                                  style: TextStyle(color: AppColors.cream),
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.cream,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(color: AppColors.cream, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Belum masuk akun')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: authService.streamUserProfile(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.sageDark),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(
              child: Text(
                'Profil tidak ditemukan',
                style: TextStyle(color: AppColors.ink),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profil Avatar & Meta
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.sage,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.sageDark,
                          child: Text(
                            profile.displayName.isNotEmpty
                                ? profile.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cream,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile.displayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.sageDark,
                            ),
                            tooltip: 'Ubah Nama',
                            onPressed: () {
                              _showEditNameDialog(context, profile.uid, profile.displayName);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: const TextStyle(
                          color: AppColors.sageDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Kartu Info Grup Keluarga
                if (profile.householdId != null && profile.householdId!.isNotEmpty)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('households')
                        .doc(profile.householdId)
                        .snapshots(),
                    builder: (context, householdSnapshot) {
                      if (householdSnapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.sageDark),
                          ),
                        );
                      }

                      if (!householdSnapshot.hasData || !householdSnapshot.data!.exists) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Informasi grup keluarga tidak ditemukan',
                            style: TextStyle(color: AppColors.ink),
                          ),
                        );
                      }

                      final household = Household.fromMap(householdSnapshot.data!.data()!);
                      return ActiveHouseholdCard(
                        household: household,
                        currentUid: currentUser.uid,
                      );
                    },
                  ),

                const SizedBox(height: 28),

                // Tombol Keluar Akun
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.expense.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppColors.expense, size: 22),
                    ),
                    title: const Text(
                      'Keluar Akun',
                      style: TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'Keluar dari sesi akun aktif ini',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: AppColors.cream,
                          title: const Text(
                            'Keluar Akun',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          content: const Text(
                            'Apakah Anda yakin ingin keluar dari akun ini?',
                            style: TextStyle(color: AppColors.ink),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text(
                                'Batal',
                                style: TextStyle(color: AppColors.sageDark),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.expense,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Keluar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await authService.logout();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ActiveHouseholdCard extends StatelessWidget {
  final Household household;
  final String currentUid;

  const ActiveHouseholdCard({
    super.key,
    required this.household,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final memberCount = household.memberIds.length;
    final isFull = memberCount >= 6;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.sageDark.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: AppColors.sageDark,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.cream,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Grup Saya (Aktif)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cream,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Nama Grup & Status Kuota
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NAMA GRUP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.sageDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            household.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quota Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFull
                            ? AppColors.terracotta.withValues(alpha: 0.12)
                            : AppColors.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFull
                              ? AppColors.terracotta.withValues(alpha: 0.4)
                              : AppColors.income.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFull
                                ? Icons.group_rounded
                                : Icons.person_add_rounded,
                            size: 14,
                            color: isFull ? AppColors.terracotta : AppColors.income,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$memberCount/6 • ${isFull ? 'Penuh' : 'Aktif'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isFull ? AppColors.terracotta : AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Chip Kode Undangan Pasangan
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.sageDark.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KODE UNDANGAN GRUP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.sageDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              household.inviteCode,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3.5,
                                color: AppColors.terracotta,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: AppColors.sageDark,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: household.inviteCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.sageDark,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle, color: AppColors.cream, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Kode undangan berhasil disalin!',
                                      style: TextStyle(color: AppColors.cream),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: AppColors.cream,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Salin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section Title Anggota Keluarga
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 16,
                      color: AppColors.sageDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ANGGOTA KELUARGA (${household.memberIds.length}/6)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.sageDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Daftar Anggota
                Column(
                  children: [
                    for (final memberUid in household.memberIds)
                      MemberProfileTile(
                        uid: memberUid,
                        household: household,
                        currentUid: currentUid,
                      ),
                    if (household.memberIds.length < 6) const WaitingPartnerTile(),
                  ],
                ),

                // Tombol Transfer Saldo (Jika pengguna memiliki izin transfer / owner)
                if (household.canTransfer(currentUid)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: AppColors.cream,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.cream, size: 20),
                      label: const Text(
                        'Transfer Saldo ke Anggota',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () {
                        TransferModal.show(
                          context,
                          household: household,
                          currentUid: currentUid,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MemberProfileTile extends StatelessWidget {
  final String uid;
  final Household household;
  final String currentUid;

  const MemberProfileTile({
    super.key,
    required this.uid,
    required this.household,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentProfile = uid == currentUid;
    final isMemberOwner = household.isOwner(uid);
    final hasTransferPermission = household.canTransfer(uid);
    final isCurrentUserAdmin = household.isOwner(currentUid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.sageDark,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Memuat profil anggota...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          );
        }

        final profile = UserProfile.fromMap(snapshot.data!.data()!);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrentProfile
                  ? AppColors.sageDark.withValues(alpha: 0.3)
                  : AppColors.sageDark.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isMemberOwner ? AppColors.sageDark : AppColors.terracotta,
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cream,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMemberOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sageDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Leader',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      profile.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ink.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Switch Toggle Izin Transfer (Tampil jika Admin/Leader mengelola anggota lain)
              if (isCurrentUserAdmin && !isCurrentProfile && !isMemberOwner)
                Column(
                  children: [
                    const Text(
                      'Izin Transfer',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sageDark,
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: Switch.adaptive(
                        value: hasTransferPermission,
                        activeTrackColor: AppColors.sageDark,
                        onChanged: (val) async {
                          final authService = AuthService();
                          await authService.toggleTransferPrivilege(
                            householdId: household.id,
                            targetUid: uid,
                            grant: val,
                          );
                        },
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrentProfile
                        ? AppColors.sageDark.withValues(alpha: 0.15)
                        : (hasTransferPermission
                            ? AppColors.income.withValues(alpha: 0.15)
                            : AppColors.sand),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentProfile
                          ? AppColors.sageDark.withValues(alpha: 0.3)
                          : (hasTransferPermission
                              ? AppColors.income.withValues(alpha: 0.4)
                              : AppColors.sageDark.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: Text(
                    isCurrentProfile
                        ? 'Saya'
                        : (hasTransferPermission ? 'Izin Transfer' : 'Anggota'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCurrentProfile
                          ? AppColors.sageDark
                          : (hasTransferPermission ? AppColors.income : AppColors.ink),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class WaitingPartnerTile extends StatelessWidget {
  const WaitingPartnerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.terracotta.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.terracotta.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_add_rounded,
              size: 18,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menunggu Pasangan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracotta,
                  ),
                ),
                Text(
                  'Bagikan kode undangan untuk bergabung',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


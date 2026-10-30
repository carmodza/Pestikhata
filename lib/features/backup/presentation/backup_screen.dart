import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../data/backup_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<CloudBackup> backups = [];
  @override
  Widget build(BuildContext context) {
    final service = BackupService(
      ref.watch(repositoryProvider),
      ref.watch(authProvider),
    );
    return PageBody(
      maxWidth: 760,
      children: [
        Text(context.tr('backupHelp'), style: context.fonts.bodyLarge),
        SectionTitle(context.tr('localBackup')),
        ActionButton(
          label: context.tr('downloadBackup'),
          icon: Icons.download_outlined,
          onPressed: service.exportLocal,
        ),
        ActionButton(
          label: context.tr('restoreBackup'),
          icon: Icons.restore,
          onPressed: () async {
            if (await confirmAction(context, context.tr('restoreHelp'))) {
              await service.restoreLocal();
            }
          },
        ),
        SectionTitle(context.tr('cloudBackup')),
        Text(context.tr('cloudBackupHelp')),
        ActionButton(
          label: context.tr('uploadBackup'),
          icon: Icons.cloud_upload_outlined,
          onPressed: () async {
            await service.upload();
            if (context.mounted) context.toast(context.tr('backupUploaded'));
          },
        ),
        ActionButton(
          label: context.tr('loadCloudBackups'),
          icon: Icons.cloud_download_outlined,
          onPressed: () async {
            final files = await service.list();
            if (mounted) setState(() => backups = files);
          },
        ),
        for (final backup in backups)
          GlassCard(
            child: ListTile(
              title: Text(backup.name.split('/').last),
              subtitle: Text(backup.updated),
              trailing: IconButton(
                tooltip: context.tr('restoreBackup'),
                icon: const Icon(Icons.restore),
                onPressed: () async {
                  if (!await confirmAction(
                    context,
                    context.tr('restoreHelp'),
                  )) {
                    return;
                  }
                  try {
                    await service.restoreCloud(backup);
                    if (context.mounted) {
                      context.toast(context.tr('backupRestored'));
                    }
                  } catch (e) {
                    if (context.mounted) context.toast(context.failure(e));
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

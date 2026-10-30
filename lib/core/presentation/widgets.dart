import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/strings.dart';
import '../data/shop_repository.dart';
import '../domain/models.dart';
import '../providers.dart';

extension UiContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get fonts => Theme.of(this).textTheme;
  String money(int amount) =>
      'Rs ${NumberFormat('#,##0.00', 'en_PK').format(amount / 100)}';
  String day(DateTime value) => DateFormat('dd MMM yyyy', 'en').format(value);
  void toast(String message) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  String failure(Object error) {
    if (error is DomainFailure) return tr(error.code);
    final code = error.toString().toLowerCase();
    if (code.contains('invalidcode') ||
        code.contains('invalid-verification-code')) {
      return tr('invalidCode');
    }
    if (code.contains('ratelimit') || code.contains('too-many-requests')) {
      return tr('rateLimited');
    }
    if (code.contains('expired')) return tr('codeExpired');
    if (code.contains('permission') || code.contains('403')) {
      return tr('ownerOnly');
    }
    return tr('operationFailed');
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tint,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? tint;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: (tint ?? context.colors.surface).withValues(alpha: .82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colors.outlineVariant.withValues(alpha: .4),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1120});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: children
            .expand((w) => [w, const SizedBox(height: 18)])
            .toList(),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: context.fonts.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      ?action,
    ],
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
  final String label, value;
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color ?? context.colors.primary),
        const SizedBox(height: 16),
        Text(
          value,
          style: context.fonts.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: context.fonts.bodyMedium),
      ],
    ),
  );
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final columns = bounds.maxWidth >= 900
          ? 4
          : bounds.maxWidth >= 550
          ? 3
          : 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children
            .map(
              (w) => SizedBox(
                width: (bounds.maxWidth - (columns - 1) * 12) / columns,
                child: w,
              ),
            )
            .toList(),
      );
    },
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.eco_outlined,
    this.action,
  });
  final String message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.colors.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.fonts.bodyLarge,
          ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 16), child: action!),
        ],
      ),
    ),
  );
}

class ShopData extends ConsumerWidget {
  const ShopData({super.key, required this.builder});
  final Widget Function(ShopSnapshot data) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(snapshotProvider)
      .when(
        data: builder,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(context.failure(error))),
      );
}

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.check,
  });
  final String label;
  final Future<void> Function() onPressed;
  final IconData icon;
  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            try {
              await widget.onPressed();
            } catch (error) {
              if (context.mounted) context.toast(context.failure(error));
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
    icon: busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(widget.icon),
    label: Text(widget.label),
  );
}

String endpointLabel(
  BuildContext context,
  ShopSnapshot data,
  Endpoint endpoint,
) => endpoint.person
    ? data.personName(endpoint.id)
    : endpoint.kind == PartyKind.godam
    ? data.godamName(endpoint.id)
    : context.tr(endpoint.kind.name);

class EntryDirectionIcon extends StatelessWidget {
  const EntryDirectionIcon({super.key, required this.entry});
  final JournalEntry entry;
  @override
  Widget build(BuildContext context) {
    final shade = Theme.of(context).brightness == Brightness.dark ? 300 : 700;
    final color = switch (entry.direction) {
      EntryDirection.incoming => Colors.green[shade]!,
      EntryDirection.outgoing => Colors.red[shade]!,
      EntryDirection.direct || EntryDirection.transfer => Colors.blue[shade]!,
    };
    return Semantics(
      label: context.tr(switch (entry.direction) {
        EntryDirection.incoming => 'incomingEntry',
        EntryDirection.outgoing => 'outgoingEntry',
        EntryDirection.direct => 'directEntry',
        EntryDirection.transfer => 'stockTransfer',
      }),
      child: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(
          [
            Icons.payments_outlined,
            Icons.science_outlined,
            Icons.grass,
            Icons.local_gas_station_outlined,
            Icons.receipt_long_outlined,
          ][entry.kind.index],
          color: color,
        ),
      ),
    );
  }
}

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.data,
    this.onTap,
  });
  final JournalEntry entry;
  final ShopSnapshot data;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: EntryDirectionIcon(entry: entry),
      title: Text(
        entry.title.isEmpty ? context.tr(entry.kind.name) : entry.title,
        style: TextStyle(
          decoration: entry.voided ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${endpointLabel(context, data, entry.source)} → ${endpointLabel(context, data, entry.destination)}\n${context.day(entry.date)}',
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            entry.ratePending
                ? context.tr('ratePending')
                : context.money(entry.totalPaise),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: entry.ratePending ? Colors.orange.shade800 : null,
            ),
          ),
          if (entry.creditPaise != 0)
            Text(
              '${context.tr('udhar')} ${context.money(entry.creditPaise)}',
              style: context.fonts.bodySmall,
            ),
        ],
      ),
    );
  }
}

Future<bool> confirmAction(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('confirm')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('confirm')),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  bool numeric = false,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.tr('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(ctx.tr('save')),
        ),
      ],
    ),
  );
  // Dialog transition can still reference its controller until the route is gone.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  return result;
}

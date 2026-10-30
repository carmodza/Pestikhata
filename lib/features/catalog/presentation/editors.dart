import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/data/shop_repository.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../../ledger/domain/ledger_engine.dart';
import '../application/unit_service.dart';

Future<Person?> editPerson(
  BuildContext context,
  WidgetRef ref,
  PartyKind kind, {
  Person? existing,
}) => showDialog<Person>(
  context: context,
  builder: (_) => PersonEditor(kind: kind, existing: existing),
);
Future<Product?> editProduct(
  BuildContext context,
  WidgetRef ref,
  EntryKind kind, {
  Product? existing,
}) => showDialog<Product>(
  context: context,
  builder: (_) => ProductEditor(kind: kind, existing: existing),
);

class PersonEditor extends ConsumerStatefulWidget {
  const PersonEditor({super.key, required this.kind, this.existing});
  final PartyKind kind;
  final Person? existing;
  @override
  ConsumerState<PersonEditor> createState() => _PersonEditorState();
}

class _PersonEditorState extends ConsumerState<PersonEditor> {
  late final name = TextEditingController(text: widget.existing?.name);
  late final phone = TextEditingController(text: widget.existing?.phone);
  late final village = TextEditingController(text: widget.existing?.village);
  late final acres = TextEditingController(
    text: widget.existing?.acres.toString() ?? '0',
  );
  late final crops = TextEditingController(text: widget.existing?.crops);
  @override
  void dispose() {
    for (final c in [name, phone, village, acres, crops]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(widget.kind.name)),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final pair in [
              (name, 'name'),
              (phone, 'phone'),
              (village, 'village'),
              if (widget.kind == PartyKind.farmer) ...[
                (acres, 'acres'),
                (crops, 'crops'),
              ],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: pair.$1,
                  keyboardType: pair.$2 == 'acres'
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : pair.$2 == 'phone'
                      ? TextInputType.phone
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: context.tr(pair.$2)),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('cancel')),
      ),
      ActionButton(
        label: context.tr('save'),
        onPressed: () async {
          final acreage = double.tryParse(acres.text);
          if (acreage == null) throw const DomainFailure('invalidPerson');
          final person = Person(
            id: widget.existing?.id ?? ShopRepository.uuid.v4(),
            name: name.text.trim(),
            phone: phone.text.trim(),
            village: village.text.trim(),
            acres: acreage,
            crops: crops.text.trim(),
            kind: widget.kind,
          );
          await ref.read(repositoryProvider).savePerson(person);
          if (context.mounted) Navigator.pop(context, person);
        },
      ),
    ],
  );
}

class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({super.key, required this.kind, this.existing});
  final EntryKind kind;
  final Product? existing;
  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  late final name = TextEditingController(text: widget.existing?.name);
  late final company = TextEditingController(text: widget.existing?.company);
  late final crop = TextEditingController(text: widget.existing?.crop);
  late final pest = TextEditingController(text: widget.existing?.pest);
  late final low = TextEditingController(
    text: widget.existing?.lowStock.toString() ?? '5',
  );
  late final purchase = TextEditingController(
    text: moneyInput(widget.existing?.purchasePaise ?? 0),
  );
  late final sale = TextEditingController(
    text: moneyInput(widget.existing?.salePaise ?? 0),
  );
  late final bori = TextEditingController(
    text: widget.existing?.units['bori']?.toString() ?? '50',
  );
  late final conversions = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.units.entries
              .where((u) => u.key != widget.existing!.baseUnit)
              .map((u) => '${u.key}=${u.value}')
              .join(', '),
  );
  late String baseUnit =
      widget.existing?.baseUnit ??
      (widget.kind == EntryKind.crop ? 'kg' : 'piece');
  @override
  void dispose() {
    for (final c in [
      name,
      company,
      crop,
      pest,
      low,
      purchase,
      sale,
      bori,
      conversions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      context.tr(widget.kind == EntryKind.crop ? 'addCrop' : 'addProduct'),
    ),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final pair in [
              (name, 'name'),
              (company, 'company'),
              (crop, 'crop'),
              (pest, 'pest'),
              (low, 'lowStockThreshold'),
              (purchase, 'purchasePrice'),
              (sale, 'salePrice'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: pair.$1,
                  keyboardType:
                      [
                        'lowStockThreshold',
                        'purchasePrice',
                        'salePrice',
                      ].contains(pair.$2)
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: context.tr(pair.$2)),
                ),
              ),
            if (widget.kind != EntryKind.crop) ...[
              DropdownButtonFormField<String>(
                initialValue: baseUnit,
                decoration: InputDecoration(labelText: context.tr('baseUnit')),
                items: ['piece', 'bag', 'kg', 'liter', 'packet', 'bottle']
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(context.tr(u)),
                      ),
                    )
                    .toList(),
                onChanged: widget.existing == null
                    ? (u) => setState(() => baseUnit = u!)
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conversions,
                decoration: InputDecoration(
                  labelText: context.tr('unitConversions'),
                  helperText: context.tr('unitConversionsHelp'),
                ),
              ),
            ] else
              TextField(
                controller: bori,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.tr('boriWeight'),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('cancel')),
      ),
      ActionButton(
        label: context.tr('save'),
        onPressed: () async {
          final units = UnitService.parse(
            kind: widget.kind,
            baseUnit: baseUnit,
            boriWeight: bori.text,
            conversions: conversions.text,
          );
          final threshold = double.tryParse(low.text);
          if (threshold == null) throw const DomainFailure('invalidProduct');
          final product = Product(
            id: widget.existing?.id ?? ShopRepository.uuid.v4(),
            name: name.text.trim(),
            company: company.text.trim(),
            crop: crop.text.trim(),
            pest: pest.text.trim(),
            kind: widget.kind,
            baseUnit: baseUnit,
            units: units,
            lowStock: threshold,
            purchasePaise: parseMoney(purchase.text),
            salePaise: parseMoney(sale.text),
          );
          await ref.read(repositoryProvider).saveProduct(product);
          if (context.mounted) Navigator.pop(context, product);
        },
      ),
    ],
  );
}

Future<T?> searchPick<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  Future<T?> Function()? onAdd,
}) => showDialog<T>(
  context: context,
  builder: (_) =>
      _SearchPicker<T>(title: title, items: items, label: label, onAdd: onAdd),
);

class _SearchPicker<T> extends StatefulWidget {
  const _SearchPicker({
    required this.title,
    required this.items,
    required this.label,
    this.onAdd,
  });
  final String title;
  final List<T> items;
  final String Function(T) label;
  final Future<T?> Function()? onAdd;
  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where(
          (i) => widget.label(i).toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: context.tr('search'),
              ),
              onChanged: (q) => setState(() => query = q),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(context.tr('noResults')))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(widget.label(filtered[i])),
                        onTap: () => Navigator.pop(context, filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onAdd != null)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(context.tr('addNew')),
            onPressed: () async {
              final value = await widget.onAdd!();
              if (value != null && context.mounted) {
                Navigator.pop(context, value);
              }
            },
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
      ],
    );
  }
}

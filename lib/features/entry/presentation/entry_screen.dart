import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../../catalog/presentation/editors.dart';
import '../../khata/application/payment_summary.dart';
import '../../khata/presentation/pending_payments_card.dart';
import '../application/entry_service.dart';

class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({
    super.key,
    required this.kind,
    this.personId,
    this.receiving = true,
    this.fromLocation,
  });
  final EntryKind kind;
  final String? personId;
  final bool receiving;
  final String? fromLocation;
  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  final input = EntryInput();
  final fields = <String, TextEditingController>{};
  bool dirty = false, saved = false, paymentPersonInitialized = false;
  @override
  void initState() {
    super.initState();
    input.kind = widget.kind;
    if (widget.kind == EntryKind.cash) input.amount = '';
    if (widget.kind == EntryKind.cash || widget.kind == EntryKind.crop) {
      input.source = const Endpoint(PartyKind.farmer);
      input.destination = const Endpoint(PartyKind.inventory);
    } else if (widget.kind == EntryKind.other ||
        widget.kind == EntryKind.diesel) {
      input.source = const Endpoint(PartyKind.inventory);
      input.destination = const Endpoint(PartyKind.walkIn);
    }
    if (widget.fromLocation != null) {
      input.source = widget.fromLocation == 'inventory'
          ? const Endpoint(PartyKind.inventory)
          : Endpoint(PartyKind.godam, widget.fromLocation);
      input.destination = widget.fromLocation == 'inventory'
          ? const Endpoint(PartyKind.godam)
          : const Endpoint(PartyKind.inventory);
    }
    final data = ref.read(snapshotProvider).value;
    if (widget.personId != null && data != null) {
      final person = data.people
          .where((p) => p.id == widget.personId)
          .firstOrNull;
      if (person != null) {
        EntryService.selectPaymentPerson(input, person, widget.receiving);
        paymentPersonInitialized = true;
      }
    }
    for (final pair in [
      ('quantity', '1'),
      ('rate', '0'),
      ('purchase', '0'),
      ('sale', '0'),
      ('cash', '0'),
      ('amount', input.amount),
      ('title', ''),
      ('note', ''),
    ]) {
      fields[pair.$1] = TextEditingController(text: pair.$2);
      fields[pair.$1]!.addListener(_changed);
    }
  }

  void _changed() {
    if (!mounted) return;
    input.quantity = fields['quantity']!.text;
    input.rate = fields['rate']!.text;
    input.purchase = fields['purchase']!.text;
    input.sale = fields['sale']!.text;
    input.cash = fields['cash']!.text;
    input.amount = fields['amount']!.text;
    input.title = fields['title']!.text;
    input.note = fields['note']!.text;
    setState(() => dirty = true);
  }

  void _applyPrices() {
    // Updating one controller must not copy the other controllers' old values
    // back into the draft before their new prices have been applied.
    final prices = {
      'purchase': input.purchase,
      'sale': input.sale,
      'rate': input.rate,
    };
    for (final price in prices.entries) {
      final controller = fields[price.key]!;
      controller.removeListener(_changed);
      controller.text = price.value;
      controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(String name, String label, {bool numeric = true}) => TextField(
    controller: fields[name],
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: context.tr(label),
      helperText:
          widget.kind == EntryKind.crop &&
              (name == 'purchase' || name == 'sale')
          ? '${context.tr('rateUnit')} ${context.tr(input.unit)}'
          : null,
    ),
    minLines: name == 'note' ? 2 : 1,
    maxLines: name == 'note' ? 3 : 1,
    onChanged: name == 'purchase' || name == 'sale'
        ? (value) {
            EntryService.editPrice(input, name, value);
            final rate = fields['rate']!;
            rate.removeListener(_changed);
            rate.text = input.rate;
            rate.addListener(_changed);
            setState(() => dirty = true);
          }
        : null,
  );

  Widget endpoint(ShopSnapshot data, bool source) {
    final selected = source ? input.source : input.destination;
    void change(Endpoint endpoint) => setState(() {
      dirty = true;
      EntryService.changeEndpoint(input, source, endpoint);
      _applyPrices();
      fields['cash']!.text = input.cash;
    });
    Future<void> choose(PartyKind kind) async {
      if (kind == PartyKind.farmer || kind == PartyKind.supplier) {
        final person = await searchPick<Person>(
          context,
          title: context.tr('selectPerson'),
          items: data.people.where((p) => p.kind == kind).toList(),
          label: (p) => '${p.name} · ${p.village} · ${p.phone}',
          onAdd: () => editPerson(context, ref, kind),
        );
        if (person != null && mounted) change(Endpoint(person.kind, person.id));
      } else if (kind == PartyKind.godam) {
        final godam = await searchPick<Godam>(
          context,
          title: context.tr('selectGodam'),
          items: data.godams,
          label: (g) => g.name,
        );
        if (godam != null && mounted) change(Endpoint(kind, godam.id));
      } else {
        change(Endpoint(kind));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            widget.kind == EntryKind.crop
                ? (source ? 'cropSource' : 'cropDestination')
                : (source ? 'source' : 'destination'),
          ),
          style: context.fonts.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: PartyKind.values
              .map(
                (kind) => ChoiceChip(
                  label: Text(context.tr(kind.name)),
                  selected: selected.kind == kind,
                  onSelected: (_) => choose(kind),
                ),
              )
              .toList(),
        ),
        if (selected.person || selected.kind == PartyKind.godam)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(
                      selected.id == null
                          ? context.tr(
                              selected.kind == PartyKind.godam
                                  ? 'selectGodam'
                                  : 'selectPerson',
                            )
                          : endpointLabel(context, data, selected),
                    ),
                    onPressed: () => choose(selected.kind),
                  ),
                ),
                if (selected.person)
                  IconButton(
                    tooltip: context.tr('addNew'),
                    icon: const Icon(Icons.person_add_alt),
                    onPressed: () async {
                      final person = await editPerson(
                        context,
                        ref,
                        selected.kind,
                      );
                      if (person != null) {
                        change(Endpoint(person.kind, person.id));
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty || saved,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      if (await confirmAction(context, context.tr('discardEntry')) &&
          context.mounted) {
        setState(() => dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.pop();
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          '${context.tr('newEntry')} · ${context.tr(widget.kind.name)}',
        ),
      ),
      body: ShopData(
        builder: (data) {
          if (widget.personId != null && !paymentPersonInitialized) {
            final person = data.people
                .where((p) => p.id == widget.personId)
                .firstOrNull;
            if (person != null) {
              EntryService.selectPaymentPerson(input, person, widget.receiving);
              paymentPersonInitialized = true;
            }
          }
          final paymentPersonId = widget.kind != EntryKind.cash
              ? null
              : input.source.person && input.destination.internal
              ? input.source.id
              : input.destination.person && input.source.internal
              ? input.destination.id
              : null;
          final paymentSummary = paymentPersonId == null
              ? null
              : PaymentSummary(
                  data,
                  paymentPersonId,
                  receiving: input.destination.internal,
                );
          JournalEntry? preview;
          try {
            preview = EntryService.preview(input);
          } catch (_) {
            /* Editing an incomplete decimal is valid UI state. */
          }
          final stockEntry =
              widget.kind == EntryKind.product || widget.kind == EntryKind.crop;
          return PageBody(
            maxWidth: 780,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    endpoint(data, true),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    endpoint(data, false),
                  ],
                ),
              ),
              if (paymentSummary != null)
                PendingPaymentsCard(summary: paymentSummary, data: data),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(context.day(input.date)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    locale: const Locale('en'),
                    cancelText: context.tr('cancel'),
                    confirmText: context.tr('done'),
                    helpText: context.tr('date'),
                    initialDate: input.date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (date != null) {
                    setState(() {
                      input.date = date;
                      dirty = true;
                    });
                  }
                },
              ),
              if (stockEntry)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.search),
                              label: Text(
                                input.product?.name ??
                                    context.tr('selectProduct'),
                              ),
                              onPressed: () async {
                                final product = await searchPick<Product>(
                                  context,
                                  title: context.tr('selectProduct'),
                                  items: data.products
                                      .where((p) => p.kind == widget.kind)
                                      .toList(),
                                  label: (p) => '${p.name} · ${p.company}',
                                );
                                if (product != null) {
                                  setState(() {
                                    EntryService.selectProduct(input, product);
                                    _applyPrices();
                                    dirty = true;
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: context.tr('addNew'),
                            icon: const Icon(Icons.add_box_outlined),
                            onPressed: () async {
                              final product = await editProduct(
                                context,
                                ref,
                                widget.kind,
                              );
                              if (product != null) {
                                setState(() {
                                  EntryService.selectProduct(input, product);
                                  _applyPrices();
                                  dirty = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (input.receivingProduct) ...[
                        const SizedBox(height: 12),
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.tr('automaticBatch'),
                            helperText: context.tr('automaticBatchHelp'),
                          ),
                          child: SelectableText(input.batch),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(
                            input.expiry == null
                                ? context.tr('addExpiryOptional')
                                : '${context.tr('expiryDate')}: ${context.day(input.expiry!)}',
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              locale: const Locale('en'),
                              cancelText: context.tr('cancel'),
                              confirmText: context.tr('done'),
                              helpText: context.tr('expiryDate'),
                              initialDate:
                                  input.expiry ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                input.expiry = date;
                                dirty = true;
                              });
                            }
                          },
                        ),
                        if (input.expiry != null)
                          TextButton.icon(
                            onPressed: () => setState(() {
                              input.expiry = null;
                              dirty = true;
                            }),
                            icon: const Icon(Icons.clear),
                            label: Text(context.tr('clearExpiry')),
                          ),
                      ],
                      if (input.source.internal)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            context.tr('automaticStockHelp'),
                            style: context.fonts.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: field('quantity', 'quantity')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(
                                '${input.product?.id}-${input.unit}',
                              ),
                              initialValue: input.unit,
                              decoration: InputDecoration(
                                labelText: context.tr('unit'),
                              ),
                              items: (input.product?.units.keys ?? ['piece'])
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(context.tr(u)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() {
                                EntryService.changeUnit(input, value!);
                                _applyPrices();
                                dirty = true;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (widget.kind == EntryKind.cash ||
                  widget.kind == EntryKind.other)
                field('amount', 'amount'),
              if (input.isDirect && widget.kind != EntryKind.crop)
                GlassCard(child: Text(context.tr('directEntryHelp'))),
              if (widget.kind == EntryKind.crop && !input.isTransfer)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr(
                          input.isDirect
                              ? 'cropDirectHelp'
                              : input.cropPurchase
                              ? 'cropPurchaseHelp'
                              : 'cropSaleHelp',
                        ),
                      ),
                      if (input.cropPurchase) ...[
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.tr(
                              input.isDirect
                                  ? 'purchaseRateLater'
                                  : 'rateLater',
                            ),
                          ),
                          value: input.cropPurchasePending,
                          onChanged: (value) => setState(() {
                            if (input.isDirect) {
                              input.purchaseRatePending = value;
                            } else {
                              input.ratePending = value;
                            }
                            dirty = true;
                          }),
                        ),
                        if (!input.cropPurchasePending)
                          field('purchase', 'purchasePrice'),
                      ],
                      if (input.cropSale) ...[
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.tr(
                              input.isDirect ? 'saleRateLater' : 'rateLater',
                            ),
                          ),
                          value: input.ratePending,
                          onChanged: (value) => setState(() {
                            input.ratePending = value;
                            dirty = true;
                          }),
                        ),
                        if (!input.ratePending) field('sale', 'salePrice'),
                      ],
                      const SizedBox(height: 12),
                      field(
                        'cash',
                        input.isDirect
                            ? 'cashThroughShop'
                            : input.cropPurchase
                            ? 'paidNow'
                            : 'receivedNow',
                      ),
                      if (input.isDirect)
                        Text(
                          context.tr('cropCashHelp'),
                          style: context.fonts.bodySmall,
                        ),
                    ],
                  ),
                ),
              if (widget.kind == EntryKind.other) ...[
                field('title', 'title', numeric: false),
                DropdownButtonFormField<String>(
                  initialValue: input.expenseCategory,
                  decoration: InputDecoration(
                    labelText: context.tr('expenseCategory'),
                  ),
                  items: ['rent', 'salary', 'bill', 'other']
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(context.tr(c)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    input.expenseCategory = value!;
                    dirty = true;
                  }),
                ),
              ],
              if (widget.kind == EntryKind.diesel) field('quantity', 'liters'),
              if (input.isRateBearing &&
                  widget.kind != EntryKind.crop &&
                  !(input.source.internal && input.destination.internal))
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('rateLater')),
                  subtitle: Text(context.tr('rateLaterHelp')),
                  value: input.ratePending,
                  onChanged: (value) => setState(() {
                    input.ratePending = value;
                    dirty = true;
                  }),
                ),
              if (widget.kind != EntryKind.crop &&
                  widget.kind != EntryKind.cash &&
                  widget.kind != EntryKind.other &&
                  !(input.source.internal && input.destination.internal)) ...[
                if (!input.ratePending) field('rate', 'rate'),
                if (stockEntry && !input.isDirect) ...[
                  Row(
                    children: [
                      Expanded(child: field('purchase', 'purchasePrice')),
                      const SizedBox(width: 12),
                      Expanded(child: field('sale', 'salePrice')),
                    ],
                  ),
                ],
                field('cash', 'cashAmount'),
              ],
              field(
                'note',
                widget.kind == EntryKind.diesel ? 'vehicleNote' : 'note',
                numeric: false,
              ),
              if (widget.kind == EntryKind.crop)
                GlassCard(
                  tint: context.colors.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (input.isTransfer) Text(context.tr('stockTransfer')),
                      if (input.cropPurchase) ...[
                        _summaryRow(
                          'purchaseTotal',
                          input.cropPurchasePending
                              ? context.tr('ratePending')
                              : context.money(preview?.purchaseTotalPaise ?? 0),
                        ),
                        if (input.source.person)
                          _summaryRow(
                            input.cropPurchasePending
                                ? 'balanceSoFar'
                                : (preview?.purchaseCreditPaise ?? 0) < 0
                                ? 'receivable'
                                : 'payable',
                            '${endpointLabel(context, data, input.source)}: ${context.money((preview?.purchaseCreditPaise ?? 0).abs())}',
                          ),
                      ],
                      if (input.isDirect) const Divider(height: 24),
                      if (input.cropSale) ...[
                        _summaryRow(
                          'saleTotal',
                          input.ratePending
                              ? context.tr('ratePending')
                              : context.money(preview?.totalPaise ?? 0),
                        ),
                        if (input.destination.person)
                          _summaryRow(
                            input.ratePending
                                ? 'balanceSoFar'
                                : (preview?.creditPaise ?? 0) < 0
                                ? 'payable'
                                : 'receivable',
                            '${endpointLabel(context, data, input.destination)}: ${context.money((preview?.creditPaise ?? 0).abs())}',
                          ),
                      ],
                      if (input.ratePending || input.purchaseRatePending)
                        Text(
                          context.tr('pendingPaymentRatesHelp'),
                          style: context.fonts.bodySmall,
                        ),
                    ],
                  ),
                )
              else
                GlassCard(
                  tint: context.colors.primaryContainer,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr('total')),
                          Text(
                            input.ratePending
                                ? context.tr('ratePending')
                                : context.money(preview?.totalPaise ?? 0),
                            style: context.fonts.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr('udhar')),
                          Text(
                            context.money(preview?.creditPaise ?? 0),
                            style: context.fonts.titleMedium,
                          ),
                        ],
                      ),
                      if (input.source.internal && input.destination.internal)
                        Text(context.tr('stockTransfer')),
                    ],
                  ),
                ),
              ActionButton(
                label: context.tr('saveEntry'),
                icon: Icons.save_outlined,
                onPressed: () async {
                  await EntryService(ref.read(repositoryProvider)).save(input);
                  if (context.mounted) {
                    setState(() {
                      saved = true;
                      dirty = false;
                    });
                    context.toast(context.tr('entrySaved'));
                    context.go('/');
                  }
                },
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(context.tr(label))),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: context.fonts.titleMedium,
          ),
        ),
      ],
    ),
  );
}

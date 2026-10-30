import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/core/presentation/widgets.dart';
import 'package:pestikhata/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'in/out/direct icons stay green/red/blue in light and dark themes',
    (tester) async {
      final date = DateTime(2026, 10, 30);
      const shop = Endpoint(PartyKind.inventory),
          farmer = Endpoint(PartyKind.farmer, 'f'),
          supplier = Endpoint(PartyKind.supplier, 's');
      final entries = [
        JournalEntry(
          id: 'in',
          kind: EntryKind.cash,
          source: farmer,
          destination: shop,
          date: date,
        ),
        JournalEntry(
          id: 'out',
          kind: EntryKind.product,
          source: shop,
          destination: farmer,
          date: date,
        ),
        JournalEntry(
          id: 'direct',
          kind: EntryKind.product,
          source: supplier,
          destination: farmer,
          date: date,
        ),
      ];
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Row(
                children: entries
                    .map((entry) => EntryDirectionIcon(entry: entry))
                    .toList(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final shade = brightness == Brightness.dark ? 300 : 700;
        final icons = tester.widgetList<Icon>(
          find.descendant(
            of: find.byType(EntryDirectionIcon),
            matching: find.byType(Icon),
          ),
        );
        expect(icons.map((i) => i.color), [
          Colors.green[shade],
          Colors.red[shade],
          Colors.blue[shade],
        ]);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

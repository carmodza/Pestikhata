# Architecture and accounting

## Source of truth

`lib/core/database/app_database.dart` defines Drift's `documents` and `outbox` tables. The composite key is `(shopId, entity, id)`. Tenant identity comes from the authenticated server profile, never a field entered on an entry form. Local demo has a separate shop ID. Documents contain typed domain payloads for people, products, godams, rates and journal entries; entity-specific repositories validate all application writes.

Every local mutation updates its document and outbox in one SQLite transaction. Streams update the UI from SQLite. The UI never reads business data directly from Firestore. Repository transactions serialize local stock validation and writes. Database schema version 1 is included; future releases must supply Drift migrations instead of deleting databases.

Feature folders separate domain models/calculations, application services, data access and presentation. `LedgerEngine`, `EntryService` and `ReportSummary` contain accounting rules and calculations. Widgets collect input and display projections. Riverpod owns sessions, repositories, streams, theme/language and sync lifecycle. Owner-only paths are checked both in go_router and the relevant repository/backend operations.

## Money and units

Money is stored as integer **paisa**, not floating-point rupees. Text parsing accepts at most two decimal places. Quantity × price uses decimal multiplication with half-up rounding; quantity and conversion factors are snapshotted on an entry. An item has one base unit and named multipliers. Crop defaults: kg = 1, maan = 40, quintal = 100, ton = 1,000 and configurable bori weight. Stocked items cannot change unit conversions retroactively.

Rates are recorded per entry unit. The rate screen stores current rates per base unit; choosing another unit converts those defaults. Users can override purchase, sale and billed rate on a new entry. Current daily rates never rewrite historical bills.

Business dates and expiry dates are stored as `YYYY-MM-DD` calendar values so they do not shift when opened in a different device timezone. Entries also retain an immutable UTC creation timestamp to order transactions within a day; sync versions are separate from these accounting dates.

## Journal projections

Positive person balance means **shop receivable**; negative means **shop payable**.

| Movement | Person effect | Cash effect | Stock effect |
|---|---|---|---|
| Supplier/Farmer → Shop/Godam | Source balance decreases by total minus cash | Cash out | Stock in |
| Shop/Godam → Farmer/Walk-in | Destination balance increases by total minus cash | Cash in | Stock out |
| Shop/Godam → Supplier | Supplier payable reduces by total minus cash | Cash in | Stock out (supplier return) |
| Farmer/Supplier → Shop, Cash | Source balance decreases by amount | Cash in | None |
| Shop → Farmer/Supplier, Cash | Destination balance increases by amount | Cash out | None |
| Shop/Godam → Shop/Godam, stock | None | None | Equal base-unit transfer |
| Shop → Supplier, Diesel | Supplier balance decreases by unpaid amount | Cash out | No diesel inventory |
| Shop → Walk-in, Other | None | Full amount out | None |

Walk-in transactions require full cash settlement and cannot have pending rates. A pending-rate stock transaction has no priced total until resolved; any received/paid cash is an advance in the person's ledger. Completing or explicitly editing a rate replaces that entry's projection without adding another movement. Owner rate corrections are allowed; daily price changes never rewrite bills automatically. Owner voids remain in the journal but are excluded from balances.

Pending rates are supported for products, crops and diesel in all entry flows. Diesel cash advances affect cash and supplier khata immediately; expense totals are priced when its rate is completed. Cash and ordinary expenses remain fixed-amount entries. Crop purchase and sale prices are both captured, and changing the active purchase/sale price updates the billed rate before saving.

Payment summaries derive pending bills from the person's signed journal movements. Opposite movements settle the oldest open amounts first, including advances recorded before a bill. Voided entries are excluded; unpriced entries are shown separately with a warning that the final balance may change. Payment forms show the selected direction's outstanding balance and pending bills, but leave the amount blank. These are general khata settlements, without changing historical bill records.

The Shop location retains its existing `inventory` storage key so saved records remain compatible. Stock is tracked by item, location, batch and optional expiry. Receiving product stock automatically generates a receipt batch; the form shows batch and expiry controls only for incoming product stock. Expiry is never invented when unknown.

Sales and internal transfers allocate available lots automatically by earliest expiry, with unknown expiries last. Automatic sales skip lots expired on the entry date; transfers and supplier returns can still move expired stock. The immutable `allocations` payload stores base-unit quantities, batches and expiry dates. One financial entry can span several lots without splitting its cash or khata amount. Transfers preserve lot identities, and voids restore all allocated lots. Legacy entries without allocations retain their original batch behavior. Local writes reject shortages. Multiple disconnected devices can each sell the same stock; after synchronization both journal records remain and negative stock is flagged for reconciliation. LWW is **not** a global offline stock reservation system.

Direct entries between two recorded people, including Supplier → Farmer and Supplier → Supplier, do not move Shop/Godam stock. Source khata decreases and destination khata increases by the unpaid bill amount (or the payment amount for Cash). Cash passes through Shop: the same amount appears in cash-in and cash-out with zero net change. Pending rates apply cash advances first and recalculate both khatas when priced. Direct pass-through trades do not create shop profit or shop expenses; sales to farmers are included in sales totals. Entry icons are green for incoming movements, red for outgoing movements, and blue for direct people-to-people entries and internal stock transfers.

Gross profit uses the purchase price snapshotted on each sale; net profit subtracts expenses. This is entry-cost accounting, not FIFO, weighted-average costing, tax accounting or an accrual cash-flow statement. Stock valuation uses current item purchase prices. Reports label their date/current-balance basis and exclude unpriced pending-rate totals. Sales returns that need financial corrections should be made by void/re-entry in this version; no automatic FIFO cost reversals are inferred.

## Sync and conflicts

`SyncService` reacts to outbox and network changes, retries every 20 seconds while running and pulls remote records automatically. It refreshes membership before syncing. Writes survive app termination in SQLite and resume on the next run. Mobile operating systems may suspend an application; this version does not promise synchronization while the app is terminated.

Each remote commit includes a server-set `committedAt` timestamp. Paginated incremental queries use a per-shop durable cursor on that server field, rather than rescanning every record or trusting another device's clock. Cursor timestamps are inclusive to safely replay equal-time commits. The cursor advances only after all received records have been applied locally.

All platforms use the documented Firebase Auth ID-token/Firestore REST interfaces for record synchronization. Native Android/iOS and browser login use FlutterFire Auth; Windows uses Auth REST, secure refresh-token storage and browser approval for Google/phone. The Windows path does not initialize FlutterFire's development-only Windows Firebase runtime.

For each record the ordering is `(updatedAt UTC microseconds, deviceId lexicographic)`. A local edit is newer than its previous observed version even if the device clock moved backwards. The REST client reads the remote record, compares versions and commits using Firestore's `updateTime`/`exists` precondition. A concurrent remote edit makes that commit retry the comparison. Both devices choose the same equal-time winner. The winning remote payload is applied locally in a transaction.

An outbox acknowledgment includes the sent version and device ID. It cannot clear a newer local edit made while a request was in flight. Duplicate reads/retries cannot double-apply cash or stock because projections derive from canonical journal IDs. Losing edits are replaced according to LWW; the app does not claim to merge two independently edited fields. Devices need approximately correct clocks; security rules reject versions more than five minutes in the future.

Deletion uses tombstones, and financial correction uses retained void records. Membership and role documents are Admin SDK only. Firestore enforces membership on each request, so a cached owner role cannot authorize a forbidden remote write. Offline revocation cannot erase data from a disconnected device; reconnecting revocations remove access to the local shop screens until re-invited. The SQLite file is not encrypted by this version; use device encryption and controlled device access for shop data.

## Web persistence

SQLite WASM and the Drift worker are served locally. Hosting uses popup-compatible COOP so Google login works; Drift uses its persistent fallback where shared-memory OPFS is unavailable. Browsers with private/transient storage or unsupported multi-tab behavior cannot guarantee durable accounting data. Use a normal browser profile, one active shop tab on mobile web, and regular backups; native apps are preferred for primary shop terminals.

`tool/build_service_worker.mjs` hashes the built application and generates `sw.js`, caching the full local shell (including CanvasKit, worker and WASM). It does not cache authenticated API responses. A first online load is necessary before offline reload works. An update waits for existing tabs to close rather than replacing code underneath an open ledger. Clearing browser site data deletes unsynced local records.

## Backups and access

JSON backups include the shop ID, versioned typed records and complete journal. Restore validates format/tenant before a transaction and merges newer backup records while keeping newer local records. Restored writes join the outbox, with catalog dependencies uploaded before journal entries. Cloud objects are immutable and owner-only under `shops/{shopId}/backups/`. Archive listings follow all pages and sort newest first. Storage's v0 REST requests use Firebase's ID-token authorization scheme. Exported files are sensitive shop records; the operating system controls their later sharing.

Staff can operate entries, people, stock, rates and expenses. They cannot void/delete, open Reports/Backup/Settings/Users, create invitations or change roles. Staff who can read the operational journal can technically derive financial summaries from that data; hiding the Reports route does not claim cryptographic secrecy of aggregates.



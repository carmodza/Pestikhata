// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get automaticBatch => 'Batch (automatic)';

  @override
  String get automaticBatchHelp => 'Generated for this stock receipt.';

  @override
  String get addExpiryOptional => 'Add expiry date (optional)';

  @override
  String get clearExpiry => 'Remove expiry date';

  @override
  String get automaticStockHelp =>
      'Stock is selected automatically, earliest expiry first. Expired stock is not selected for sales.';

  @override
  String get directEntryHelp =>
      'Cash is received by Shop and paid onward. Both khatas update; Shop and Godam stock stays unchanged.';

  @override
  String get personOrShopRequired =>
      'Choose two people, or include Shop or Godam.';

  @override
  String get invalidAllocation =>
      'The stock selection is invalid. Review available stock and try again.';

  @override
  String get incomingEntry => 'In';

  @override
  String get outgoingEntry => 'Out';

  @override
  String get directEntry => 'Direct';

  @override
  String get cashReceived => 'Cash in';

  @override
  String get cashPaid => 'Cash out';

  @override
  String get noStockAtLocation =>
      'No stock in this location yet. Receive or transfer stock here.';

  @override
  String get items => 'Items';

  @override
  String get products => 'Products';

  @override
  String get godamsTransfers => 'Godams & transfers';

  @override
  String get stockLocation => 'Stock location';

  @override
  String get allLocations => 'All locations';

  @override
  String get shopStock => 'Shop';

  @override
  String get appName => 'PestiKhata';

  @override
  String get tagline => 'Your shop. Every rupee, every harvest.';

  @override
  String get home => 'Home';

  @override
  String get roznamcha => 'Roznamcha';

  @override
  String get entry => 'Entry';

  @override
  String get khata => 'Khata';

  @override
  String get more => 'More';

  @override
  String get cash => 'Cash';

  @override
  String get product => 'Pesticide / Fertilizer / Seed';

  @override
  String get crop => 'Crop';

  @override
  String get crops => 'Crops';

  @override
  String get diesel => 'Diesel';

  @override
  String get other => 'Other';

  @override
  String get farmer => 'Farmer';

  @override
  String get supplier => 'Supplier';

  @override
  String get godam => 'Godam';

  @override
  String get inventory => 'Shop';

  @override
  String get walkIn => 'Walk-in';

  @override
  String get owner => 'Owner';

  @override
  String get staff => 'Staff';

  @override
  String get source => 'Source — from';

  @override
  String get destination => 'Destination — to';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone (+92)';

  @override
  String get email => 'Email';

  @override
  String get village => 'Village / City';

  @override
  String get acres => 'Acres';

  @override
  String get date => 'Date';

  @override
  String get title => 'Title';

  @override
  String get note => 'Note';

  @override
  String get amount => 'Amount (Rs)';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get rate => 'Rate (Rs / unit)';

  @override
  String get purchasePrice => 'Purchase price (Rs / unit)';

  @override
  String get salePrice => 'Sale price (Rs / unit)';

  @override
  String get total => 'Total';

  @override
  String get udhar => 'Udhar';

  @override
  String get cashAmount => 'Cash amount (Rs)';

  @override
  String get batch => 'Batch number';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get rateLater => 'Rate later';

  @override
  String get rateLaterHelp =>
      'Stock moves now. Final khata updates when the rate is set.';

  @override
  String get ratePending => 'Rate pending';

  @override
  String get pendingRates => 'Pending rates';

  @override
  String get noPendingRates => 'All rates are up to date.';

  @override
  String get setRate => 'Set rate (Rs / entry unit)';

  @override
  String get rateUpdated => 'Rate updated. Balances recalculated.';

  @override
  String get newEntry => 'New entry';

  @override
  String get saveEntry => 'Save entry';

  @override
  String get entrySaved => 'Entry saved on this device.';

  @override
  String get discardEntry => 'Discard this unsaved entry?';

  @override
  String get addNew => 'Add new';

  @override
  String get addProduct => 'Add product';

  @override
  String get addCrop => 'Add crop';

  @override
  String get selectProduct => 'Search / select an item';

  @override
  String get selectPerson => 'Search / select a person';

  @override
  String get selectGodam => 'Select a godam';

  @override
  String get chooseStockBatch => 'Choose available stock batch';

  @override
  String get stockTransfer => 'Stock transfer — no cash or udhar';

  @override
  String get company => 'Company';

  @override
  String get pest => 'Pest';

  @override
  String get productName => 'Product / crop';

  @override
  String get baseUnit => 'Base unit';

  @override
  String get lowStockThreshold => 'Low stock threshold';

  @override
  String get unitConversions => 'Extra unit conversions';

  @override
  String get unitConversionsHelp =>
      'Example: carton=12, dozen=12 (in base units)';

  @override
  String get boriWeight => '1 bori weight (kg)';

  @override
  String get piece => 'piece';

  @override
  String get bag => 'bag';

  @override
  String get kg => 'kg';

  @override
  String get liter => 'liter';

  @override
  String get packet => 'packet';

  @override
  String get bottle => 'bottle';

  @override
  String get maan => 'maan (40 kg)';

  @override
  String get quintal => 'quintal (100 kg)';

  @override
  String get bori => 'bori';

  @override
  String get ton => 'ton (1,000 kg)';

  @override
  String get liters => 'Liters';

  @override
  String get vehicleNote => 'Vehicle / note';

  @override
  String get expenseCategory => 'Expense category';

  @override
  String get rent => 'Rent';

  @override
  String get salary => 'Salary';

  @override
  String get bill => 'Bill';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied.';

  @override
  String get search => 'Search';

  @override
  String get noResults => 'No results found.';

  @override
  String get viewAll => 'View all';

  @override
  String get all => 'All';

  @override
  String get todayOverview => 'Today\'s overview';

  @override
  String get homeWelcome => 'A clear view of your daily business.';

  @override
  String get cashIn => 'Cash in today';

  @override
  String get cashOut => 'Cash out today';

  @override
  String get sales => 'Sales';

  @override
  String get cashBalance => 'Cash balance';

  @override
  String get udharGiven => 'Udhar given today';

  @override
  String get udharReceived => 'Udhar received today';

  @override
  String get stockAlerts => 'Stock alerts';

  @override
  String get noStockAlerts => 'Stock and expiry look good.';

  @override
  String get lowStock => 'Low stock';

  @override
  String get expired => 'Expired';

  @override
  String get expiringSoon => 'Expiring within 90 days';

  @override
  String get negativeStockWarning =>
      'Stock needs reconciliation: offline sales from multiple devices exceeded a batch balance. Review entries before further sales.';

  @override
  String get recentEntries => 'Recent entries';

  @override
  String get noEntries => 'No entries yet. Tap Entry to get started.';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get closingBalance => 'Closing balance';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterPerson => 'Filter by person';

  @override
  String get filterItem => 'Filter by item';

  @override
  String get type => 'Type';

  @override
  String get dailyBalanceHelp =>
      'Opening and closing balances cover the whole day. Filters apply only to the entry list.';

  @override
  String get farmerKhata => 'Farmer khata';

  @override
  String get supplierKhata => 'Supplier khata';

  @override
  String get noPeople => 'No people added yet.';

  @override
  String get balance => 'Balance';

  @override
  String get receivable => 'To receive';

  @override
  String get payable => 'To pay';

  @override
  String get settled => 'Settled';

  @override
  String get balanceSignHelp =>
      'Positive balance: the shop will receive. Negative balance: the shop will pay.';

  @override
  String get receivePayment => 'Receive payment';

  @override
  String get givePayment => 'Give payment';

  @override
  String get shareStatement => 'Share statement PDF';

  @override
  String get statement => 'Khata statement';

  @override
  String get ledger => 'Ledger';

  @override
  String get whatsappShareHelp =>
      'Choose WhatsApp from your device share menu to send this PDF.';

  @override
  String get voidEntry => 'Void entry';

  @override
  String get voidEntryHelp =>
      'Void this entry and reverse its cash, stock and khata effects? The audit record is kept.';

  @override
  String get voided => 'Voided';

  @override
  String get entryVoided => 'Entry voided.';

  @override
  String get immutableEntryHelp =>
      'Daily prices never change this bill automatically. The owner can edit its rate, or void and re-enter for other corrections.';

  @override
  String get inventorySearch => 'Search name, company, crop or pest';

  @override
  String get noProducts => 'Add a product or crop to manage stock.';

  @override
  String get noStock => 'No stock in this item.';

  @override
  String get batchesAndLocations => 'Batches & locations';

  @override
  String get addGodam => 'Add godam';

  @override
  String get godamName => 'Godam name';

  @override
  String get address => 'Address';

  @override
  String get transferProducts => 'Transfer products';

  @override
  String get transferCrops => 'Transfer crops';

  @override
  String get transferHelp =>
      'Choose internal source and destination, then select the item, exact batch and quantity. Transfers keep total shop stock unchanged.';

  @override
  String get rates => 'Rates';

  @override
  String get updateRate => 'Update rate';

  @override
  String get ratesHelp =>
      'Daily prices apply to new entries. Saved bills keep the price recorded at entry time.';

  @override
  String get priceHistory => 'Price history · sale rate';

  @override
  String get reports => 'Reports';

  @override
  String get expenses => 'Expenses';

  @override
  String get profit => 'Profit';

  @override
  String get stock => 'Stock';

  @override
  String get grossProfit => 'Gross profit';

  @override
  String get netProfit => 'Net profit';

  @override
  String get cropProfit => 'Crop profit';

  @override
  String get stockValue => 'Stock value (current cost)';

  @override
  String get addExpense => 'Add expense';

  @override
  String get pendingRatesExcluded =>
      'pending-rate entries excluded from priced totals.';

  @override
  String get reportBasisHelp =>
      'Profit uses the purchase cost saved on each sale, not FIFO. Stock, receivables and payables are current balances; sales and expenses use the selected dates. Pending rates are excluded from priced totals.';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get backup => 'Backup / export';

  @override
  String get backupHelp =>
      'Keep an extra copy of your shop records. Backups belong to this shop and include the full journal.';

  @override
  String get localBackup => 'Local backup';

  @override
  String get downloadBackup => 'Download backup';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get restoreHelp =>
      'Merge this backup into the same shop? Newer local records will be kept.';

  @override
  String get cloudBackup => 'Cloud backup';

  @override
  String get cloudBackupHelp =>
      'Requires internet, a configured Firebase Storage bucket and owner access.';

  @override
  String get uploadBackup => 'Upload backup';

  @override
  String get loadCloudBackups => 'Load cloud backups';

  @override
  String get backupUploaded => 'Backup uploaded.';

  @override
  String get backupRestored => 'Backup restored.';

  @override
  String get cloudUnavailable =>
      'Cloud backup is unavailable in local demo mode or before Firebase setup.';

  @override
  String get settings => 'Settings';

  @override
  String get users => 'Users';

  @override
  String get appearance => 'Appearance';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get romanUrdu => 'Roman Urdu';

  @override
  String get yourShop => 'Your shop';

  @override
  String get shopId => 'Shop ID';

  @override
  String get role => 'Role';

  @override
  String get shopName => 'Shop name';

  @override
  String get seedDemoData => 'Seed demo data';

  @override
  String get demoDataHelp =>
      'Sample farmers, products and transactions in the separate local demo shop.';

  @override
  String get clearDemoData => 'Clear all records in the local demo shop?';

  @override
  String get openDemo => 'Open local demo shop';

  @override
  String get aboutApp =>
      'PestiKhata 1.0 · Made for agricultural shops in Pakistan.';

  @override
  String get usersHelp =>
      'Invite staff with a single-use code. User access changes require internet; cached member details remain available offline.';

  @override
  String get inviteStaff => 'Invite staff';

  @override
  String get inviteCode => 'Invitation code';

  @override
  String get inviteHelp =>
      'Share this single-use code with your staff member. It expires in 48 hours.';

  @override
  String get revokeAccess => 'Revoke access';

  @override
  String get revokeHelp =>
      'Remove this staff member from the shop? Offline access on their device ends when it reconnects.';

  @override
  String get sendCode => 'Send code';

  @override
  String get resendCode => 'Resend code';

  @override
  String get otpCode => '6-digit code';

  @override
  String get verifyAndSignIn => 'Verify & sign in';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get tryDemo => 'Try local demo';

  @override
  String get demo => 'Demo';

  @override
  String get offlineLoginHelp =>
      'Sign in needs internet the first time. Saved shop records stay available offline.';

  @override
  String get phoneConsent =>
      'By continuing, you agree to receive an SMS code. Your number is sent to Google to provide phone authentication.';

  @override
  String get onboardingHelp =>
      'Create your shop as owner, or join using your owner’s invitation code. One login belongs to one shop.';

  @override
  String get createShop => 'Create shop';

  @override
  String get joinShop => 'Join shop';

  @override
  String get signOut => 'Sign out';

  @override
  String get desktopComplete => 'Signed in. You can return to the Windows app.';

  @override
  String get desktopCode => 'Match this code in your browser';

  @override
  String get desktopSignIn => 'Windows sign-in';

  @override
  String get desktopApprovalHelp =>
      'Approve only if this code matches the PestiKhata Windows app you just opened. This gives that app access to your account.';

  @override
  String get approveDesktop => 'Approve Windows sign-in';

  @override
  String get editRate => 'Edit this entry’s rate';

  @override
  String get entryDetails => 'Entry details';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get alreadyHasShop => 'This login already belongs to a shop.';

  @override
  String get sessionExpired =>
      'Please sign in again to reconnect. Your local records are kept.';

  @override
  String get serverError =>
      'The service is temporarily unavailable. Please try again.';

  @override
  String get invalidId => 'This record identifier is invalid.';

  @override
  String get invalidRequest => 'Please check the entered details.';

  @override
  String get shopRequired => 'Create or join a shop first.';

  @override
  String get syncFailed => 'Could not sync. Your changes remain saved locally.';

  @override
  String get syncConflict =>
      'A conflicting update is being retried. Local records are kept.';

  @override
  String get textTooLong => 'This name or note is too long. Please shorten it.';

  @override
  String get invalidDate => 'Choose a valid date.';

  @override
  String get synced => 'Synced';

  @override
  String get pending => 'Sync pending';

  @override
  String get offline => 'Offline';

  @override
  String get local => 'Local only';

  @override
  String get blocked => 'Sync needs sign-in / access review';

  @override
  String get pendingWrites => 'pending changes';

  @override
  String get firebaseNotConfigured =>
      'Live sign-in is not configured yet. Try the local demo, or follow docs/FIREBASE_SETUP.md.';

  @override
  String get sameEndpoints => 'Source and destination must be different.';

  @override
  String get shopEndpointRequired =>
      'Choose two people, or include Shop or Godam.';

  @override
  String get invalidTransfer =>
      'Transfers require stock items, two internal locations and no cash or pending rate.';

  @override
  String get invalidQuantity => 'Enter a quantity greater than zero.';

  @override
  String get invalidAmount =>
      'Enter a valid positive amount, with at most two decimal places.';

  @override
  String get invalidRatePending =>
      'Only product and crop entries can have pending rates.';

  @override
  String get invalidExpense =>
      'Choose an internal source and enter an expense title and valid payment.';

  @override
  String get cashExceedsTotal => 'Cash cannot exceed the total.';

  @override
  String get creditRequiresPerson =>
      'Udhar and pending rates require a farmer or supplier.';

  @override
  String get invalidUnit => 'Enter valid unit conversions.';

  @override
  String get batchRequired => 'Incoming product stock needs a batch number.';

  @override
  String get insufficientStock =>
      'Not enough usable stock in this location or batch. Check quantity and expiry dates.';

  @override
  String get invalidBackup =>
      'This backup is invalid or belongs to another shop.';

  @override
  String get invalidPerson => 'Enter a name and valid acreage.';

  @override
  String get invalidProduct => 'Enter a valid item name, units and prices.';

  @override
  String get unitLocked =>
      'Unit conversions cannot change after stock entries exist. Add a new item instead.';

  @override
  String get entryImmutable => 'This entry cannot be changed.';

  @override
  String get ownerOnly => 'Only the shop owner can perform this action.';

  @override
  String get requiredField => 'Please complete the required field.';

  @override
  String get demoOnly =>
      'Demo data is available only in the separate local demo shop.';

  @override
  String get requestCodeFirst => 'Request a code first.';

  @override
  String get browserFailed => 'Could not open the browser.';

  @override
  String get codeExpired =>
      'This code or sign-in session has expired. Please try again.';

  @override
  String get invalidCode => 'The code is incorrect. Please try again.';

  @override
  String get rateLimited =>
      'Too many requests. Please wait before trying again.';

  @override
  String get operationFailed =>
      'Could not complete this action. Check your connection and try again.';
}

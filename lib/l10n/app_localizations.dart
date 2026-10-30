import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @cropRates.
  ///
  /// In en, this message translates to:
  /// **'Crop purchase & sale rates'**
  String get cropRates;

  /// No description provided for @pendingToReceive.
  ///
  /// In en, this message translates to:
  /// **'Pending receipts'**
  String get pendingToReceive;

  /// No description provided for @pendingToPay.
  ///
  /// In en, this message translates to:
  /// **'Pending payments'**
  String get pendingToPay;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get outstanding;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @noPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'No priced payments pending in this direction.'**
  String get noPendingPayments;

  /// No description provided for @paymentAllocationHelp.
  ///
  /// In en, this message translates to:
  /// **'Payments settle the oldest outstanding amounts first.'**
  String get paymentAllocationHelp;

  /// No description provided for @pendingPaymentRatesHelp.
  ///
  /// In en, this message translates to:
  /// **'Some entry rates are still pending. Advances are included in the balance; final dues may change.'**
  String get pendingPaymentRatesHelp;

  /// No description provided for @automaticBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch (automatic)'**
  String get automaticBatch;

  /// No description provided for @automaticBatchHelp.
  ///
  /// In en, this message translates to:
  /// **'Generated for this stock receipt.'**
  String get automaticBatchHelp;

  /// No description provided for @addExpiryOptional.
  ///
  /// In en, this message translates to:
  /// **'Add expiry date (optional)'**
  String get addExpiryOptional;

  /// No description provided for @clearExpiry.
  ///
  /// In en, this message translates to:
  /// **'Remove expiry date'**
  String get clearExpiry;

  /// No description provided for @automaticStockHelp.
  ///
  /// In en, this message translates to:
  /// **'Stock is selected automatically, earliest expiry first. Expired stock is not selected for sales.'**
  String get automaticStockHelp;

  /// No description provided for @directEntryHelp.
  ///
  /// In en, this message translates to:
  /// **'Cash is received by Shop and paid onward. Both khatas update; Shop and Godam stock stays unchanged.'**
  String get directEntryHelp;

  /// No description provided for @personOrShopRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose two people, or include Shop or Godam.'**
  String get personOrShopRequired;

  /// No description provided for @invalidAllocation.
  ///
  /// In en, this message translates to:
  /// **'The stock selection is invalid. Review available stock and try again.'**
  String get invalidAllocation;

  /// No description provided for @incomingEntry.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get incomingEntry;

  /// No description provided for @outgoingEntry.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outgoingEntry;

  /// No description provided for @directEntry.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get directEntry;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get cashReceived;

  /// No description provided for @cashPaid.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get cashPaid;

  /// No description provided for @noStockAtLocation.
  ///
  /// In en, this message translates to:
  /// **'No stock in this location yet. Receive or transfer stock here.'**
  String get noStockAtLocation;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @godamsTransfers.
  ///
  /// In en, this message translates to:
  /// **'Godams & transfers'**
  String get godamsTransfers;

  /// No description provided for @stockLocation.
  ///
  /// In en, this message translates to:
  /// **'Stock location'**
  String get stockLocation;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All locations'**
  String get allLocations;

  /// No description provided for @shopStock.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopStock;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PestiKhata'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your shop. Every rupee, every harvest.'**
  String get tagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @roznamcha.
  ///
  /// In en, this message translates to:
  /// **'Roznamcha'**
  String get roznamcha;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entry;

  /// No description provided for @khata.
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get khata;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Pesticide / Fertilizer / Seed'**
  String get product;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @crops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get crops;

  /// No description provided for @diesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get diesel;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @godam.
  ///
  /// In en, this message translates to:
  /// **'Godam'**
  String get godam;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get inventory;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkIn;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source — from'**
  String get source;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination — to'**
  String get destination;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (+92)'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village / City'**
  String get village;

  /// No description provided for @acres.
  ///
  /// In en, this message translates to:
  /// **'Acres'**
  String get acres;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rs)'**
  String get amount;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate (Rs / unit)'**
  String get rate;

  /// No description provided for @purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price (Rs / unit)'**
  String get purchasePrice;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale price (Rs / unit)'**
  String get salePrice;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @udhar.
  ///
  /// In en, this message translates to:
  /// **'Udhar'**
  String get udhar;

  /// No description provided for @cashAmount.
  ///
  /// In en, this message translates to:
  /// **'Cash amount (Rs)'**
  String get cashAmount;

  /// No description provided for @batch.
  ///
  /// In en, this message translates to:
  /// **'Batch number'**
  String get batch;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @rateLater.
  ///
  /// In en, this message translates to:
  /// **'Rate later'**
  String get rateLater;

  /// No description provided for @rateLaterHelp.
  ///
  /// In en, this message translates to:
  /// **'Save now. Set the entry rate later to update totals and khata.'**
  String get rateLaterHelp;

  /// No description provided for @ratePending.
  ///
  /// In en, this message translates to:
  /// **'Rate pending'**
  String get ratePending;

  /// No description provided for @pendingRates.
  ///
  /// In en, this message translates to:
  /// **'Pending rates'**
  String get pendingRates;

  /// No description provided for @noPendingRates.
  ///
  /// In en, this message translates to:
  /// **'All rates are up to date.'**
  String get noPendingRates;

  /// No description provided for @setRate.
  ///
  /// In en, this message translates to:
  /// **'Set rate (Rs / entry unit)'**
  String get setRate;

  /// No description provided for @rateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rate updated. Balances recalculated.'**
  String get rateUpdated;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get saveEntry;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved on this device.'**
  String get entrySaved;

  /// No description provided for @discardEntry.
  ///
  /// In en, this message translates to:
  /// **'Discard this unsaved entry?'**
  String get discardEntry;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addNew;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @addCrop.
  ///
  /// In en, this message translates to:
  /// **'Add crop'**
  String get addCrop;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Search / select an item'**
  String get selectProduct;

  /// No description provided for @selectPerson.
  ///
  /// In en, this message translates to:
  /// **'Search / select a person'**
  String get selectPerson;

  /// No description provided for @selectGodam.
  ///
  /// In en, this message translates to:
  /// **'Select a godam'**
  String get selectGodam;

  /// No description provided for @chooseStockBatch.
  ///
  /// In en, this message translates to:
  /// **'Choose available stock batch'**
  String get chooseStockBatch;

  /// No description provided for @stockTransfer.
  ///
  /// In en, this message translates to:
  /// **'Stock transfer — no cash or udhar'**
  String get stockTransfer;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @pest.
  ///
  /// In en, this message translates to:
  /// **'Pest'**
  String get pest;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product / crop'**
  String get productName;

  /// No description provided for @baseUnit.
  ///
  /// In en, this message translates to:
  /// **'Base unit'**
  String get baseUnit;

  /// No description provided for @lowStockThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low stock threshold'**
  String get lowStockThreshold;

  /// No description provided for @unitConversions.
  ///
  /// In en, this message translates to:
  /// **'Extra unit conversions'**
  String get unitConversions;

  /// No description provided for @unitConversionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Example: carton=12, dozen=12 (in base units)'**
  String get unitConversionsHelp;

  /// No description provided for @boriWeight.
  ///
  /// In en, this message translates to:
  /// **'1 bori weight (kg)'**
  String get boriWeight;

  /// No description provided for @piece.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get piece;

  /// No description provided for @bag.
  ///
  /// In en, this message translates to:
  /// **'bag'**
  String get bag;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @liter.
  ///
  /// In en, this message translates to:
  /// **'liter'**
  String get liter;

  /// No description provided for @packet.
  ///
  /// In en, this message translates to:
  /// **'packet'**
  String get packet;

  /// No description provided for @bottle.
  ///
  /// In en, this message translates to:
  /// **'bottle'**
  String get bottle;

  /// No description provided for @maan.
  ///
  /// In en, this message translates to:
  /// **'maan (40 kg)'**
  String get maan;

  /// No description provided for @quintal.
  ///
  /// In en, this message translates to:
  /// **'quintal (100 kg)'**
  String get quintal;

  /// No description provided for @bori.
  ///
  /// In en, this message translates to:
  /// **'bori'**
  String get bori;

  /// No description provided for @ton.
  ///
  /// In en, this message translates to:
  /// **'ton (1,000 kg)'**
  String get ton;

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get liters;

  /// No description provided for @vehicleNote.
  ///
  /// In en, this message translates to:
  /// **'Vehicle / note'**
  String get vehicleNote;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense category'**
  String get expenseCategory;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bill;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get copied;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @todayOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s overview'**
  String get todayOverview;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'A clear view of your daily business.'**
  String get homeWelcome;

  /// No description provided for @cashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash in today'**
  String get cashIn;

  /// No description provided for @cashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash out today'**
  String get cashOut;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @cashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash balance'**
  String get cashBalance;

  /// No description provided for @udharGiven.
  ///
  /// In en, this message translates to:
  /// **'Udhar given today'**
  String get udharGiven;

  /// No description provided for @udharReceived.
  ///
  /// In en, this message translates to:
  /// **'Udhar received today'**
  String get udharReceived;

  /// No description provided for @stockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Stock alerts'**
  String get stockAlerts;

  /// No description provided for @noStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Stock and expiry look good.'**
  String get noStockAlerts;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring within 90 days'**
  String get expiringSoon;

  /// No description provided for @negativeStockWarning.
  ///
  /// In en, this message translates to:
  /// **'Stock needs reconciliation: offline sales from multiple devices exceeded a batch balance. Review entries before further sales.'**
  String get negativeStockWarning;

  /// No description provided for @recentEntries.
  ///
  /// In en, this message translates to:
  /// **'Recent entries'**
  String get recentEntries;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Tap Entry to get started.'**
  String get noEntries;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get closingBalance;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filterPerson.
  ///
  /// In en, this message translates to:
  /// **'Filter by person'**
  String get filterPerson;

  /// No description provided for @filterItem.
  ///
  /// In en, this message translates to:
  /// **'Filter by item'**
  String get filterItem;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @dailyBalanceHelp.
  ///
  /// In en, this message translates to:
  /// **'Opening and closing balances cover the whole day. Filters apply only to the entry list.'**
  String get dailyBalanceHelp;

  /// No description provided for @farmerKhata.
  ///
  /// In en, this message translates to:
  /// **'Farmer khata'**
  String get farmerKhata;

  /// No description provided for @supplierKhata.
  ///
  /// In en, this message translates to:
  /// **'Supplier khata'**
  String get supplierKhata;

  /// No description provided for @noPeople.
  ///
  /// In en, this message translates to:
  /// **'No people added yet.'**
  String get noPeople;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @receivable.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get receivable;

  /// No description provided for @payable.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get payable;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @balanceSignHelp.
  ///
  /// In en, this message translates to:
  /// **'Positive balance: the shop will receive. Negative balance: the shop will pay.'**
  String get balanceSignHelp;

  /// No description provided for @receivePayment.
  ///
  /// In en, this message translates to:
  /// **'Receive payment'**
  String get receivePayment;

  /// No description provided for @givePayment.
  ///
  /// In en, this message translates to:
  /// **'Give payment'**
  String get givePayment;

  /// No description provided for @shareStatement.
  ///
  /// In en, this message translates to:
  /// **'Share statement PDF'**
  String get shareStatement;

  /// No description provided for @statement.
  ///
  /// In en, this message translates to:
  /// **'Khata statement'**
  String get statement;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @whatsappShareHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose WhatsApp from your device share menu to send this PDF.'**
  String get whatsappShareHelp;

  /// No description provided for @voidEntry.
  ///
  /// In en, this message translates to:
  /// **'Void entry'**
  String get voidEntry;

  /// No description provided for @voidEntryHelp.
  ///
  /// In en, this message translates to:
  /// **'Void this entry and reverse its cash, stock and khata effects? The audit record is kept.'**
  String get voidEntryHelp;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voided;

  /// No description provided for @entryVoided.
  ///
  /// In en, this message translates to:
  /// **'Entry voided.'**
  String get entryVoided;

  /// No description provided for @immutableEntryHelp.
  ///
  /// In en, this message translates to:
  /// **'Daily prices never change this bill automatically. The owner can edit its rate, or void and re-enter for other corrections.'**
  String get immutableEntryHelp;

  /// No description provided for @inventorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search name, company, crop or pest'**
  String get inventorySearch;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'Add a product or crop to manage stock.'**
  String get noProducts;

  /// No description provided for @noStock.
  ///
  /// In en, this message translates to:
  /// **'No stock in this item.'**
  String get noStock;

  /// No description provided for @batchesAndLocations.
  ///
  /// In en, this message translates to:
  /// **'Batches & locations'**
  String get batchesAndLocations;

  /// No description provided for @addGodam.
  ///
  /// In en, this message translates to:
  /// **'Add godam'**
  String get addGodam;

  /// No description provided for @godamName.
  ///
  /// In en, this message translates to:
  /// **'Godam name'**
  String get godamName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @transferProducts.
  ///
  /// In en, this message translates to:
  /// **'Transfer products'**
  String get transferProducts;

  /// No description provided for @transferCrops.
  ///
  /// In en, this message translates to:
  /// **'Transfer crops'**
  String get transferCrops;

  /// No description provided for @transferHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose internal source and destination, then select the item, exact batch and quantity. Transfers keep total shop stock unchanged.'**
  String get transferHelp;

  /// No description provided for @rates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get rates;

  /// No description provided for @updateRate.
  ///
  /// In en, this message translates to:
  /// **'Update rate'**
  String get updateRate;

  /// No description provided for @ratesHelp.
  ///
  /// In en, this message translates to:
  /// **'Daily prices apply to new entries. Saved bills keep the price recorded at entry time.'**
  String get ratesHelp;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history · sale rate'**
  String get priceHistory;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get grossProfit;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfit;

  /// No description provided for @cropProfit.
  ///
  /// In en, this message translates to:
  /// **'Crop profit'**
  String get cropProfit;

  /// No description provided for @stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value (current cost)'**
  String get stockValue;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @pendingRatesExcluded.
  ///
  /// In en, this message translates to:
  /// **'pending-rate entries excluded from priced totals.'**
  String get pendingRatesExcluded;

  /// No description provided for @reportBasisHelp.
  ///
  /// In en, this message translates to:
  /// **'Profit uses the purchase cost saved on each sale, not FIFO. Stock, receivables and payables are current balances; sales and expenses use the selected dates. Pending rates are excluded from priced totals.'**
  String get reportBasisHelp;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup / export'**
  String get backup;

  /// No description provided for @backupHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep an extra copy of your shop records. Backups belong to this shop and include the full journal.'**
  String get backupHelp;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local backup'**
  String get localBackup;

  /// No description provided for @downloadBackup.
  ///
  /// In en, this message translates to:
  /// **'Download backup'**
  String get downloadBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @restoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Merge this backup into the same shop? Newer local records will be kept.'**
  String get restoreHelp;

  /// No description provided for @cloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get cloudBackup;

  /// No description provided for @cloudBackupHelp.
  ///
  /// In en, this message translates to:
  /// **'Requires internet, a configured Firebase Storage bucket and owner access.'**
  String get cloudBackupHelp;

  /// No description provided for @uploadBackup.
  ///
  /// In en, this message translates to:
  /// **'Upload backup'**
  String get uploadBackup;

  /// No description provided for @loadCloudBackups.
  ///
  /// In en, this message translates to:
  /// **'Load cloud backups'**
  String get loadCloudBackups;

  /// No description provided for @backupUploaded.
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded.'**
  String get backupUploaded;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored.'**
  String get backupRestored;

  /// No description provided for @cloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is unavailable in local demo mode or before Firebase setup.'**
  String get cloudUnavailable;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @romanUrdu.
  ///
  /// In en, this message translates to:
  /// **'Roman Urdu'**
  String get romanUrdu;

  /// No description provided for @yourShop.
  ///
  /// In en, this message translates to:
  /// **'Your shop'**
  String get yourShop;

  /// No description provided for @shopId.
  ///
  /// In en, this message translates to:
  /// **'Shop ID'**
  String get shopId;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @seedDemoData.
  ///
  /// In en, this message translates to:
  /// **'Seed demo data'**
  String get seedDemoData;

  /// No description provided for @demoDataHelp.
  ///
  /// In en, this message translates to:
  /// **'Sample farmers, products and transactions in the separate local demo shop.'**
  String get demoDataHelp;

  /// No description provided for @clearDemoData.
  ///
  /// In en, this message translates to:
  /// **'Clear all records in the local demo shop?'**
  String get clearDemoData;

  /// No description provided for @openDemo.
  ///
  /// In en, this message translates to:
  /// **'Open local demo shop'**
  String get openDemo;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'PestiKhata 1.0 · Made for agricultural shops in Pakistan.'**
  String get aboutApp;

  /// No description provided for @usersHelp.
  ///
  /// In en, this message translates to:
  /// **'Invite staff with a single-use code. User access changes require internet; cached member details remain available offline.'**
  String get usersHelp;

  /// No description provided for @inviteStaff.
  ///
  /// In en, this message translates to:
  /// **'Invite staff'**
  String get inviteStaff;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get inviteCode;

  /// No description provided for @inviteHelp.
  ///
  /// In en, this message translates to:
  /// **'Share this single-use code with your staff member. It expires in 48 hours.'**
  String get inviteHelp;

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get revokeAccess;

  /// No description provided for @revokeHelp.
  ///
  /// In en, this message translates to:
  /// **'Remove this staff member from the shop? Offline access on their device ends when it reconnects.'**
  String get revokeHelp;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpCode;

  /// No description provided for @verifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & sign in'**
  String get verifyAndSignIn;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try local demo'**
  String get tryDemo;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @offlineLoginHelp.
  ///
  /// In en, this message translates to:
  /// **'Sign in needs internet the first time. Saved shop records stay available offline.'**
  String get offlineLoginHelp;

  /// No description provided for @phoneConsent.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to receive an SMS code. Your number is sent to Google to provide phone authentication.'**
  String get phoneConsent;

  /// No description provided for @onboardingHelp.
  ///
  /// In en, this message translates to:
  /// **'Create your shop as owner, or join using your owner’s invitation code. One login belongs to one shop.'**
  String get onboardingHelp;

  /// No description provided for @createShop.
  ///
  /// In en, this message translates to:
  /// **'Create shop'**
  String get createShop;

  /// No description provided for @joinShop.
  ///
  /// In en, this message translates to:
  /// **'Join shop'**
  String get joinShop;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @desktopComplete.
  ///
  /// In en, this message translates to:
  /// **'Signed in. You can return to the Windows app.'**
  String get desktopComplete;

  /// No description provided for @desktopCode.
  ///
  /// In en, this message translates to:
  /// **'Match this code in your browser'**
  String get desktopCode;

  /// No description provided for @desktopSignIn.
  ///
  /// In en, this message translates to:
  /// **'Windows sign-in'**
  String get desktopSignIn;

  /// No description provided for @desktopApprovalHelp.
  ///
  /// In en, this message translates to:
  /// **'Approve only if this code matches the PestiKhata Windows app you just opened. This gives that app access to your account.'**
  String get desktopApprovalHelp;

  /// No description provided for @approveDesktop.
  ///
  /// In en, this message translates to:
  /// **'Approve Windows sign-in'**
  String get approveDesktop;

  /// No description provided for @editRate.
  ///
  /// In en, this message translates to:
  /// **'Edit this entry’s rate'**
  String get editRate;

  /// No description provided for @entryDetails.
  ///
  /// In en, this message translates to:
  /// **'Entry details'**
  String get entryDetails;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @alreadyHasShop.
  ///
  /// In en, this message translates to:
  /// **'This login already belongs to a shop.'**
  String get alreadyHasShop;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to reconnect. Your local records are kept.'**
  String get sessionExpired;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again.'**
  String get serverError;

  /// No description provided for @invalidId.
  ///
  /// In en, this message translates to:
  /// **'This record identifier is invalid.'**
  String get invalidId;

  /// No description provided for @invalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Please check the entered details.'**
  String get invalidRequest;

  /// No description provided for @shopRequired.
  ///
  /// In en, this message translates to:
  /// **'Create or join a shop first.'**
  String get shopRequired;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync. Your changes remain saved locally.'**
  String get syncFailed;

  /// No description provided for @syncConflict.
  ///
  /// In en, this message translates to:
  /// **'A conflicting update is being retried. Local records are kept.'**
  String get syncConflict;

  /// No description provided for @textTooLong.
  ///
  /// In en, this message translates to:
  /// **'This name or note is too long. Please shorten it.'**
  String get textTooLong;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid date.'**
  String get invalidDate;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Sync pending'**
  String get pending;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get local;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Sync needs sign-in / access review'**
  String get blocked;

  /// No description provided for @pendingWrites.
  ///
  /// In en, this message translates to:
  /// **'pending changes'**
  String get pendingWrites;

  /// No description provided for @firebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Live sign-in is not configured yet. Try the local demo, or follow docs/FIREBASE_SETUP.md.'**
  String get firebaseNotConfigured;

  /// No description provided for @sameEndpoints.
  ///
  /// In en, this message translates to:
  /// **'Source and destination must be different.'**
  String get sameEndpoints;

  /// No description provided for @shopEndpointRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose two people, or include Shop or Godam.'**
  String get shopEndpointRequired;

  /// No description provided for @invalidTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfers require stock items, two internal locations and no cash or pending rate.'**
  String get invalidTransfer;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity greater than zero.'**
  String get invalidQuantity;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive amount, with at most two decimal places.'**
  String get invalidAmount;

  /// No description provided for @invalidRatePending.
  ///
  /// In en, this message translates to:
  /// **'Only product, crop and diesel entries can have pending rates.'**
  String get invalidRatePending;

  /// No description provided for @invalidExpense.
  ///
  /// In en, this message translates to:
  /// **'Choose an internal source and enter an expense title and valid payment.'**
  String get invalidExpense;

  /// No description provided for @cashExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Cash cannot exceed the total.'**
  String get cashExceedsTotal;

  /// No description provided for @creditRequiresPerson.
  ///
  /// In en, this message translates to:
  /// **'Udhar and pending rates require a farmer or supplier.'**
  String get creditRequiresPerson;

  /// No description provided for @invalidUnit.
  ///
  /// In en, this message translates to:
  /// **'Enter valid unit conversions.'**
  String get invalidUnit;

  /// No description provided for @batchRequired.
  ///
  /// In en, this message translates to:
  /// **'Incoming product stock needs a batch number.'**
  String get batchRequired;

  /// No description provided for @insufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough usable stock in this location or batch. Check quantity and expiry dates.'**
  String get insufficientStock;

  /// No description provided for @invalidBackup.
  ///
  /// In en, this message translates to:
  /// **'This backup is invalid or belongs to another shop.'**
  String get invalidBackup;

  /// No description provided for @invalidPerson.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and valid acreage.'**
  String get invalidPerson;

  /// No description provided for @invalidProduct.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid item name, units and prices.'**
  String get invalidProduct;

  /// No description provided for @unitLocked.
  ///
  /// In en, this message translates to:
  /// **'Unit conversions cannot change after stock entries exist. Add a new item instead.'**
  String get unitLocked;

  /// No description provided for @entryImmutable.
  ///
  /// In en, this message translates to:
  /// **'This entry cannot be changed.'**
  String get entryImmutable;

  /// No description provided for @ownerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the shop owner can perform this action.'**
  String get ownerOnly;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Please complete the required field.'**
  String get requiredField;

  /// No description provided for @demoOnly.
  ///
  /// In en, this message translates to:
  /// **'Demo data is available only in the separate local demo shop.'**
  String get demoOnly;

  /// No description provided for @requestCodeFirst.
  ///
  /// In en, this message translates to:
  /// **'Request a code first.'**
  String get requestCodeFirst;

  /// No description provided for @browserFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the browser.'**
  String get browserFailed;

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code or sign-in session has expired. Please try again.'**
  String get codeExpired;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is incorrect. Please try again.'**
  String get invalidCode;

  /// No description provided for @rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait before trying again.'**
  String get rateLimited;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this action. Check your connection and try again.'**
  String get operationFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get cropSource => 'Kis se lena / khareedna hai';

  @override
  String get cropDestination => 'Kahan rakhna / kis ko bechna hai';

  @override
  String get cropPurchaseHelp =>
      'Dukaan ya Godam mein khareed: sirf khareed rate likhein. Baqi raqam bechnay walay ke khatay mein jayegi.';

  @override
  String get cropSaleHelp =>
      'Rakhee hui fasal ki farokht: farokht rate likhein. Baqi raqam khareednay walay ke khatay mein jayegi.';

  @override
  String get cropDirectHelp =>
      'Seedhi khareed aur farokht: khareed rate bechnay walay ka khata, farokht rate khareednay walay ka khata update karta hai. Dukaan ya Godam ka stock nahin badalta.';

  @override
  String get purchaseRateLater => 'Khareed rate baad mein';

  @override
  String get saleRateLater => 'Farokht rate baad mein';

  @override
  String get purchaseTotal => 'Khareed ki kul raqam';

  @override
  String get saleTotal => 'Farokht ki kul raqam';

  @override
  String get sellerKhata => 'Bechnay walay ko dena / advance (−)';

  @override
  String get buyerKhata => 'Khareednay walay se lena / advance (−)';

  @override
  String get paidNow => 'Abhi di hui raqam (Rs)';

  @override
  String get receivedNow => 'Abhi wasool raqam (Rs)';

  @override
  String get cashThroughShop => 'Dukaan ke zariye naqad (Rs)';

  @override
  String get cropCashHelp =>
      'Yeh naqad khareednay walay se Dukaan mein aa kar bechnay walay ko di jayegi. Raqmein alag hon to Khata mein alag adaigi likhein.';

  @override
  String get balanceSoFar => 'Ab tak ka balance';

  @override
  String get keepRatePending => 'Baqi rate khali chhor kar baad mein lagayein.';

  @override
  String get purchaseLabel => 'Khareed';

  @override
  String get saleLabel => 'Farokht';

  @override
  String get rateUnit => 'Rate baraye 1';

  @override
  String get cropRates => 'Fasal ke khareed aur farokht rates';

  @override
  String get pendingToReceive => 'Baqi wasooli';

  @override
  String get pendingToPay => 'Baqi adaigi';

  @override
  String get outstanding => 'Baqi balance';

  @override
  String get remaining => 'Baqi';

  @override
  String get noPendingPayments =>
      'Is taraf koi qeemat wala bhugtan baqi nahin.';

  @override
  String get paymentAllocationHelp =>
      'Raqam pehlay purani baqi adaigion mein lagti hai.';

  @override
  String get pendingPaymentRatesHelp =>
      'Kuch entries ke rates baqi hain. Advance balance mein shamil hai; aakhri baqaya badal sakta hai.';

  @override
  String get automaticBatch => 'Batch (khud banay ga)';

  @override
  String get automaticBatchHelp => 'Is stock ki aamad ke liye khud bana hai.';

  @override
  String get addExpiryOptional => 'Expiry tareekh lagayein (ikhtiyari)';

  @override
  String get clearExpiry => 'Expiry tareekh hataein';

  @override
  String get automaticStockHelp =>
      'Stock khud chuna jayega, pehlay qareebi expiry wala. Expire stock farokht ke liye nahin chuna jayega.';

  @override
  String get directEntryHelp =>
      'Naqad Dukaan mein aa kar aagay di jayegi. Dono khatay update honge; Dukaan aur Godam ka stock nahin badlay ga.';

  @override
  String get personOrShopRequired =>
      'Do afraad chunein, ya Dukaan ya Godam shamil karein.';

  @override
  String get invalidAllocation =>
      'Stock ka intikhab durust nahin. Maujood stock dekh kar dobara koshish karein.';

  @override
  String get incomingEntry => 'Aamad';

  @override
  String get outgoingEntry => 'Raft';

  @override
  String get directEntry => 'Seedhi entry';

  @override
  String get cashReceived => 'Naqad aaya';

  @override
  String get cashPaid => 'Naqad gaya';

  @override
  String get noStockAtLocation =>
      'Is maqam par abhi stock nahin. Maal wasool ya transfer karein.';

  @override
  String get items => 'Maal';

  @override
  String get products => 'Zarai maal';

  @override
  String get godamsTransfers => 'Godam aur tabdeeli';

  @override
  String get stockLocation => 'Stock ka maqam';

  @override
  String get allLocations => 'Tamam maqamaat';

  @override
  String get shopStock => 'Dukaan';

  @override
  String get appName => 'PestiKhata';

  @override
  String get tagline => 'Aap ki dukaan. Har rupay, har fasal ka hisaab.';

  @override
  String get home => 'Home';

  @override
  String get roznamcha => 'Roznamcha';

  @override
  String get entry => 'Entry';

  @override
  String get khata => 'Khata';

  @override
  String get more => 'Mazeed';

  @override
  String get cash => 'Naqad';

  @override
  String get product => 'Zarai dawa / Khaad / Beej';

  @override
  String get crop => 'Fasal';

  @override
  String get crops => 'Faslein';

  @override
  String get diesel => 'Diesel';

  @override
  String get other => 'Doosra';

  @override
  String get farmer => 'Kisaan';

  @override
  String get supplier => 'Supplier';

  @override
  String get godam => 'Godam';

  @override
  String get inventory => 'Dukaan';

  @override
  String get walkIn => 'Aam grahak';

  @override
  String get owner => 'Maalik';

  @override
  String get staff => 'Mulazim';

  @override
  String get source => 'Kahan se';

  @override
  String get destination => 'Kahan ko';

  @override
  String get name => 'Naam';

  @override
  String get phone => 'Phone (+92)';

  @override
  String get email => 'Email';

  @override
  String get village => 'Gaon / Shehar';

  @override
  String get acres => 'Aikarr';

  @override
  String get date => 'Tareekh';

  @override
  String get title => 'Unwaan';

  @override
  String get note => 'Tafseel';

  @override
  String get amount => 'Raqam (Rs)';

  @override
  String get quantity => 'Miqdaar';

  @override
  String get unit => 'Ikaai';

  @override
  String get rate => 'Rate (Rs / ikaai)';

  @override
  String get purchasePrice => 'Khareed rate (Rs / ikaai)';

  @override
  String get salePrice => 'Farokht rate (Rs / ikaai)';

  @override
  String get total => 'Kul raqam';

  @override
  String get udhar => 'Udhar';

  @override
  String get cashAmount => 'Naqad raqam (Rs)';

  @override
  String get batch => 'Batch number';

  @override
  String get expiryDate => 'Expiry tareekh';

  @override
  String get rateLater => 'Rate baad mein';

  @override
  String get rateLaterHelp =>
      'Ab save karein. Baad mein rate laganay par kul raqam aur khata update hoga.';

  @override
  String get ratePending => 'Rate baqi hai';

  @override
  String get pendingRates => 'Baqi rates';

  @override
  String get noPendingRates => 'Koi rate baqi nahin.';

  @override
  String get setRate => 'Rate lagayein (Rs / entry ikaai)';

  @override
  String get rateUpdated => 'Rate aur khata update ho gaye.';

  @override
  String get newEntry => 'Nayi entry';

  @override
  String get saveEntry => 'Entry save karein';

  @override
  String get entrySaved => 'Entry is device par save ho gayi.';

  @override
  String get discardEntry => 'Yeh baghair save ki hui entry band karein?';

  @override
  String get addNew => 'Naya shamil karein';

  @override
  String get addProduct => 'Naya maal';

  @override
  String get addCrop => 'Nayi fasal';

  @override
  String get selectProduct => 'Maal talash karein';

  @override
  String get selectPerson => 'Shakhs chunein';

  @override
  String get selectGodam => 'Godam chunein';

  @override
  String get chooseStockBatch => 'Maujood stock ka batch chunein';

  @override
  String get stockTransfer => 'Stock tabdeeli — naqad ya udhar nahin';

  @override
  String get company => 'Company';

  @override
  String get pest => 'Keera';

  @override
  String get productName => 'Maal / fasal';

  @override
  String get baseUnit => 'Bunyadi ikaai';

  @override
  String get lowStockThreshold => 'Kam stock ki had';

  @override
  String get unitConversions => 'Mazeed ikaaiyon ki tabdeeli';

  @override
  String get unitConversionsHelp =>
      'Misal: carton=12, dozen=12 (bunyadi ikaai mein)';

  @override
  String get boriWeight => '1 bori ka wazan (kg)';

  @override
  String get piece => 'adad';

  @override
  String get bag => 'bori';

  @override
  String get kg => 'kg';

  @override
  String get liter => 'liter';

  @override
  String get packet => 'packet';

  @override
  String get bottle => 'botal';

  @override
  String get maan => 'mann (40 kg)';

  @override
  String get quintal => 'quintal (100 kg)';

  @override
  String get bori => 'bori';

  @override
  String get ton => 'ton (1,000 kg)';

  @override
  String get liters => 'Liter';

  @override
  String get vehicleNote => 'Gaari / tafseel';

  @override
  String get expenseCategory => 'Kharch ki qisam';

  @override
  String get rent => 'Kiraya';

  @override
  String get salary => 'Tankhwa';

  @override
  String get bill => 'Bill';

  @override
  String get save => 'Save karein';

  @override
  String get cancel => 'Wapas';

  @override
  String get confirm => 'Tasdeeq';

  @override
  String get done => 'Ho gaya';

  @override
  String get edit => 'Tabdeel karein';

  @override
  String get copy => 'Copy karein';

  @override
  String get copied => 'Copy ho gaya.';

  @override
  String get search => 'Talash karein';

  @override
  String get noResults => 'Kuch nahin mila.';

  @override
  String get viewAll => 'Sab dekhein';

  @override
  String get all => 'Sab';

  @override
  String get todayOverview => 'Aaj ka hisaab';

  @override
  String get homeWelcome => 'Roz ke karobaar ka saaf hisaab.';

  @override
  String get cashIn => 'Aaj naqad aaya';

  @override
  String get cashOut => 'Aaj naqad gaya';

  @override
  String get sales => 'Farokht';

  @override
  String get cashBalance => 'Naqad baqaya';

  @override
  String get udharGiven => 'Aaj diya udhar';

  @override
  String get udharReceived => 'Aaj udhar wasooli';

  @override
  String get stockAlerts => 'Stock ke alerts';

  @override
  String get noStockAlerts => 'Stock aur expiry theek hain.';

  @override
  String get lowStock => 'Stock kam hai';

  @override
  String get expired => 'Expiry ho chuki';

  @override
  String get expiringSoon => '90 din mein expiry';

  @override
  String get negativeStockWarning =>
      'Stock ka milaan karein: mukhtalif devices ki offline entries se batch stock manfi ho gaya. Mazeed farokht se pehlay entries dekhein.';

  @override
  String get recentEntries => 'Haal ki entries';

  @override
  String get noEntries => 'Abhi koi entry nahin. Entry dabayein.';

  @override
  String get openingBalance => 'Ibtidai balance';

  @override
  String get closingBalance => 'Aakhri balance';

  @override
  String get clearFilters => 'Filters hataein';

  @override
  String get filterPerson => 'Shakhs ke mutabiq';

  @override
  String get filterItem => 'Maal ke mutabiq';

  @override
  String get type => 'Qisam';

  @override
  String get dailyBalanceHelp =>
      'Ibtidai aur aakhri balance poore din ke hain. Filters sirf entries par lagte hain.';

  @override
  String get farmerKhata => 'Kisaan khata';

  @override
  String get supplierKhata => 'Supplier khata';

  @override
  String get noPeople => 'Abhi koi shakhs shamil nahin.';

  @override
  String get balance => 'Baqaya';

  @override
  String get receivable => 'Lena hai';

  @override
  String get payable => 'Dena hai';

  @override
  String get settled => 'Hisaab barabar';

  @override
  String get balanceSignHelp =>
      'Musbat balance: dukaan ne lena hai. Manfi balance: dukaan ne dena hai.';

  @override
  String get receivePayment => 'Raqam wasool karein';

  @override
  String get givePayment => 'Raqam dein';

  @override
  String get shareStatement => 'Khata PDF share karein';

  @override
  String get statement => 'Khata statement';

  @override
  String get ledger => 'Tafseeli khata';

  @override
  String get whatsappShareHelp =>
      'PDF bhejnay ke liye device ke share menu se WhatsApp chunein.';

  @override
  String get voidEntry => 'Entry mansookh karein';

  @override
  String get voidEntryHelp =>
      'Entry mansookh karke naqad, stock aur khata wapas karein? Record mehfooz rahega.';

  @override
  String get voided => 'Mansookh';

  @override
  String get entryVoided => 'Entry mansookh ho gayi.';

  @override
  String get immutableEntryHelp =>
      'Rozana rates is bill ko khud nahin badalte. Maalik is ka rate badal sakta hai, ya doosri ghalti par mansookh karke dobara daal sakta hai.';

  @override
  String get inventorySearch => 'Naam, company, fasal ya keera talash karein';

  @override
  String get noProducts => 'Stock ke liye maal ya fasal shamil karein.';

  @override
  String get noStock => 'Is maal ka stock nahin.';

  @override
  String get batchesAndLocations => 'Batch aur maqamaat';

  @override
  String get addGodam => 'Naya godam';

  @override
  String get godamName => 'Godam ka naam';

  @override
  String get address => 'Pata';

  @override
  String get transferProducts => 'Maal transfer karein';

  @override
  String get transferCrops => 'Fasal transfer karein';

  @override
  String get transferHelp =>
      'Androoni source aur destination chunein, phir maal, batch aur miqdaar. Kul stock nahin badlay ga.';

  @override
  String get rates => 'Rates';

  @override
  String get updateRate => 'Rate tabdeel karein';

  @override
  String get ratesHelp =>
      'Rozana rate nayi entry par lagega. Purani entry ka rate mehfooz rahega.';

  @override
  String get priceHistory => 'Rate ki tareekh · farokht';

  @override
  String get reports => 'Reports';

  @override
  String get expenses => 'Kharchay';

  @override
  String get profit => 'Munafa';

  @override
  String get stock => 'Stock';

  @override
  String get grossProfit => 'Kul munafa';

  @override
  String get netProfit => 'Saaf munafa';

  @override
  String get cropProfit => 'Fasal ka munafa';

  @override
  String get stockValue => 'Stock ki qeemat (maujooda khareed)';

  @override
  String get addExpense => 'Kharch shamil karein';

  @override
  String get pendingRatesExcluded =>
      'baqi rate wali entries qeemat ke hisaab mein shamil nahin.';

  @override
  String get reportBasisHelp =>
      'Munafa har farokht par save khareed rate se hai, FIFO se nahin. Stock aur udhar maujooda hain; farokht aur kharch muntakhib tareekhon ke hain. Baqi rates qeemat ke hisaab mein shamil nahin.';

  @override
  String get exportPdf => 'PDF nikalein';

  @override
  String get exportExcel => 'Excel nikalein';

  @override
  String get backup => 'Backup / export';

  @override
  String get backupHelp =>
      'Apni dukaan ke records ki izafi copy rakhein. Backup mein poora roznamcha shamil hai.';

  @override
  String get localBackup => 'Device backup';

  @override
  String get downloadBackup => 'Backup download karein';

  @override
  String get restoreBackup => 'Backup wapas layein';

  @override
  String get restoreHelp =>
      'Isi dukaan mein backup milayein? Naye local records mehfooz rahenge.';

  @override
  String get cloudBackup => 'Cloud backup';

  @override
  String get cloudBackupHelp =>
      'Internet, Firebase Storage aur maalik ki ijazat zaroori hai.';

  @override
  String get uploadBackup => 'Backup upload karein';

  @override
  String get loadCloudBackups => 'Cloud backups dekhein';

  @override
  String get backupUploaded => 'Backup upload ho gaya.';

  @override
  String get backupRestored => 'Backup wapas aa gaya.';

  @override
  String get cloudUnavailable =>
      'Demo mode mein ya Firebase setup se pehlay cloud backup dastiyab nahin.';

  @override
  String get settings => 'Settings';

  @override
  String get users => 'Users';

  @override
  String get appearance => 'Rang aur andaaz';

  @override
  String get system => 'System ke mutabiq';

  @override
  String get light => 'Roshan';

  @override
  String get dark => 'Gehra';

  @override
  String get language => 'Zabaan';

  @override
  String get english => 'English';

  @override
  String get romanUrdu => 'Roman Urdu';

  @override
  String get yourShop => 'Aap ki dukaan';

  @override
  String get shopId => 'Dukaan ID';

  @override
  String get role => 'Kirdaar';

  @override
  String get shopName => 'Dukaan ka naam';

  @override
  String get seedDemoData => 'Demo data daalein';

  @override
  String get demoDataHelp =>
      'Alag demo dukaan mein misaali kisaan, stock aur entries.';

  @override
  String get clearDemoData => 'Demo dukaan ke tamam records saaf karein?';

  @override
  String get openDemo => 'Local demo dukaan kholein';

  @override
  String get aboutApp => 'PestiKhata 1.0 · Pakistan ki zarai dukaanon ke liye.';

  @override
  String get usersHelp =>
      'Aik martaba ke code se staff bulayein. Ijazat ki tabdeeli ke liye internet chahiye; mehfooz users offline dikhte hain.';

  @override
  String get inviteStaff => 'Staff bulayein';

  @override
  String get inviteCode => 'Dawat ka code';

  @override
  String get inviteHelp =>
      'Yeh aik martaba ka code staff ko dein. 48 ghantay baad khatam ho jayega.';

  @override
  String get revokeAccess => 'Ijazat khatam karein';

  @override
  String get revokeHelp =>
      'Is staff ki dukaan tak rasai khatam karein? Unke device par offline rasai dobara internet par band hogi.';

  @override
  String get sendCode => 'Code bhejein';

  @override
  String get resendCode => 'Code dobara bhejein';

  @override
  String get otpCode => '6 adadi code';

  @override
  String get verifyAndSignIn => 'Tasdeeq aur sign in';

  @override
  String get continueGoogle => 'Google se sign in';

  @override
  String get tryDemo => 'Local demo dekhein';

  @override
  String get demo => 'Demo';

  @override
  String get offlineLoginHelp =>
      'Pehli dafa sign in ke liye internet chahiye. Save records offline dastiyab rahenge.';

  @override
  String get phoneConsent =>
      'Jari rakhnay par SMS code ki ijazat dete hain. Phone ki tasdeeq ke liye number Google ko bheja jayega.';

  @override
  String get onboardingHelp =>
      'Maalik ban kar dukaan banayein ya maalik ke code se shamil hon. Aik login aik dukaan ke liye hai.';

  @override
  String get createShop => 'Dukaan banayein';

  @override
  String get joinShop => 'Dukaan mein shamil hon';

  @override
  String get signOut => 'Sign out';

  @override
  String get desktopComplete =>
      'Sign in ho gaya. Windows app mein wapas jayein.';

  @override
  String get desktopCode => 'Browser mein yeh code milayein';

  @override
  String get desktopSignIn => 'Windows sign in';

  @override
  String get desktopApprovalHelp =>
      'Sirf tab ijazat dein jab yeh code aap ki kholi hui PestiKhata Windows app se milta ho. Us app ko account tak rasai milegi.';

  @override
  String get approveDesktop => 'Windows sign in ki ijazat dein';

  @override
  String get editRate => 'Is entry ka rate badlein';

  @override
  String get entryDetails => 'Entry ki tafseel';

  @override
  String get invalidEmail => 'Durust email likhein.';

  @override
  String get alreadyHasShop => 'Yeh login pehlay se aik dukaan ka hai.';

  @override
  String get sessionExpired =>
      'Dobara online honay ke liye sign in karein. Local records mehfooz hain.';

  @override
  String get serverError =>
      'Service filhal dastiyab nahin. Dobara koshish karein.';

  @override
  String get invalidId => 'Record ka number durust nahin.';

  @override
  String get invalidRequest => 'Darj ki hui tafseel dekhein.';

  @override
  String get shopRequired => 'Pehlay dukaan banayein ya shamil hon.';

  @override
  String get syncFailed => 'Sync nahin hua. Tabdeeliyan local save hain.';

  @override
  String get syncConflict =>
      'Mukhtalif update dobara sync hogi. Local records mehfooz hain.';

  @override
  String get textTooLong =>
      'Naam ya tafseel bohat lambi hai. Mukhtasar karein.';

  @override
  String get invalidDate => 'Durust tareekh chunein.';

  @override
  String get synced => 'Sync mukammal';

  @override
  String get pending => 'Sync baqi';

  @override
  String get offline => 'Offline';

  @override
  String get local => 'Sirf local';

  @override
  String get blocked => 'Sync ke liye sign in / ijazat dekhein';

  @override
  String get pendingWrites => 'tabdeeliyan baqi';

  @override
  String get firebaseNotConfigured =>
      'Live sign in ka setup abhi nahin hua. Local demo kholein ya docs/FIREBASE_SETUP.md dekhein.';

  @override
  String get sameEndpoints => 'Source aur destination mukhtalif hon.';

  @override
  String get shopEndpointRequired =>
      'Do afraad chunein, ya Dukaan ya Godam shamil karein.';

  @override
  String get invalidTransfer =>
      'Transfer ke liye maal, do androoni maqam aur baghair naqad / baqi rate chahiye.';

  @override
  String get invalidQuantity => 'Sifar se zyada miqdaar likhein.';

  @override
  String get invalidAmount =>
      'Durust raqam likhein, zyada se zyada do ashaari adad.';

  @override
  String get invalidRatePending =>
      'Sirf maal, fasal aur diesel ka rate baqi reh sakta hai.';

  @override
  String get invalidExpense =>
      'Androoni source chunein aur kharch ka naam aur raqam likhein.';

  @override
  String get cashExceedsTotal => 'Naqad kul raqam se zyada nahin ho sakta.';

  @override
  String get creditRequiresPerson =>
      'Udhar aur baqi rate ke liye kisaan ya supplier chunein.';

  @override
  String get invalidUnit => 'Ikaaiyon ki durust tabdeeli likhein.';

  @override
  String get batchRequired => 'Maal ki aamad ke liye batch number zaroori hai.';

  @override
  String get insufficientStock =>
      'Is maqam ya batch mein qabil-e-farokht stock kaafi nahin. Miqdaar aur expiry dekhein.';

  @override
  String get invalidBackup => 'Backup durust nahin ya doosri dukaan ka hai.';

  @override
  String get invalidPerson => 'Naam aur durust raqba likhein.';

  @override
  String get invalidProduct => 'Maal ka naam, ikaai aur rate durust likhein.';

  @override
  String get unitLocked =>
      'Stock entry ke baad ikaai nahin badal sakti. Naya maal shamil karein.';

  @override
  String get entryImmutable => 'Yeh entry tabdeel nahin ho sakti.';

  @override
  String get ownerOnly => 'Sirf maalik yeh kaam kar sakta hai.';

  @override
  String get requiredField => 'Zaroori khana mukammal karein.';

  @override
  String get demoOnly => 'Demo data sirf alag local demo dukaan mein hai.';

  @override
  String get requestCodeFirst => 'Pehlay code mangwayein.';

  @override
  String get browserFailed => 'Browser nahin khul saka.';

  @override
  String get codeExpired =>
      'Code ya sign in ki muddat khatam ho gayi. Dobara koshish karein.';

  @override
  String get invalidCode => 'Code ghalat hai. Dobara koshish karein.';

  @override
  String get rateLimited =>
      'Bohat zyada darkhwastain. Kuch der baad koshish karein.';

  @override
  String get operationFailed =>
      'Kaam mukammal nahin hua. Internet dekh kar dobara koshish karein.';
}

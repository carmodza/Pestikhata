const {test,before,after}=require('node:test');
const fs=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,deleteDoc,serverTimestamp}=require('firebase/firestore');
let env;
const enabled=!!process.env.FIRESTORE_EMULATOR_HOST;
before(async()=>{
  if(!enabled)return;
  env=await initializeTestEnvironment({projectId:'demo-pestikhata',firestore:{rules:fs.readFileSync('../firestore.rules','utf8')}});
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx=>{
    const db=ctx.firestore();
    await Promise.all([
      setDoc(doc(db,'shops/a/members/owner'),{role:'owner'}),
      setDoc(doc(db,'shops/a/members/staff'),{role:'staff'}),
      setDoc(doc(db,'shops/b/members/outsider'),{role:'owner'}),
    ]);
  });
});
after(async()=>{if(env)await env.cleanup();});
function person(id='f',version=Date.now()*1000){return{id,entity:'people',shopId:'a',updatedAt:version,deviceId:'device',deleted:false,committedAt:serverTimestamp(),
  payload:{id,name:'Ali',kind:'farmer',phone:'',village:'',acres:1,crops:''}};}
test('rules: staff can create a person in their own shop',{skip:!enabled},async()=>{
  await assertSucceeds(setDoc(doc(env.authenticatedContext('staff').firestore(),'shops/a/records/people_f'),person()));
});
test('rules: cross-shop reads and writes are denied',{skip:!enabled},async()=>{
  const db=env.authenticatedContext('outsider').firestore();
  await assertFails(getDoc(doc(db,'shops/a/records/people_f')));
  await assertFails(setDoc(doc(db,'shops/a/records/people_bad'),person('bad')));
});
test('rules: self-assigned owner role and profile affiliation are denied',{skip:!enabled},async()=>{
  const db=env.authenticatedContext('staff').firestore();
  await assertFails(setDoc(doc(db,'shops/a/members/staff'),{role:'owner'}));
  await assertFails(setDoc(doc(db,'users/staff'),{shopId:'b'}));
});
test('rules: staff cannot tombstone or hard-delete records',{skip:!enabled},async()=>{
  const db=env.authenticatedContext('staff').firestore(),id='deletion-test';
  await assertSucceeds(setDoc(doc(db,`shops/a/records/people_${id}`),person(id)));
  await assertFails(setDoc(doc(db,`shops/a/records/people_${id}`),{...person(id,Date.now()*1000+100),deleted:true}));
  await assertFails(deleteDoc(doc(db,`shops/a/records/people_${id}`)));
});
test('rules: future-dated versions and mismatched record IDs are denied',{skip:!enabled},async()=>{
  const db=env.authenticatedContext('owner').firestore();
  await assertFails(setDoc(doc(db,'shops/a/records/people_future'),person('future',Date.now()*1000+9999999999)));
  await assertFails(setDoc(doc(db,'shops/a/records/people_wrong'),person('different')));
});
test('rules: OTP and desktop login secrets are private',{skip:!enabled},async()=>{
  const db=env.authenticatedContext('owner').firestore();
  await assertFails(getDoc(doc(db,'emailChallenges/a')));
  await assertFails(getDoc(doc(db,'desktopSessions/a')));
});

function cropEntry(id, ratePending = false) {
  return {id,entity:'entries',shopId:'a',updatedAt:Date.now()*1000,deviceId:'device',deleted:false,committedAt:serverTimestamp(),
    payload:{id,kind:'crop',source:{kind:'inventory',id:null},destination:{kind:'farmer',id:'rate-farmer'},
      date:'2026-10-30',itemId:'rate-crop',title:'Wheat',note:'',batch:'',expiry:null,quantity:1,unit:'kg',unitFactor:1,
      ratePaise:ratePending?0:10000,purchasePaise:7000,salePaise:10000,cashPaise:0,amountPaise:0,ratePending,
      expenseCategory:'other',createdBy:'staff',createdAt:Date.now()*1000,voided:false}};
}
async function prepareRateEntry(id, pending = false) {
  const value=cropEntry(id,pending);
  await env.withSecurityRulesDisabled(async ctx=>{
    const db=ctx.firestore();
    await setDoc(doc(db,'shops/a/records/people_rate-farmer'),person('rate-farmer'));
    await setDoc(doc(db,'shops/a/records/products_rate-crop'),{payload:{id:'rate-crop',kind:'crop'}});
    await setDoc(doc(db,`shops/a/records/entries_${id}`),value);
  });
  return value;
}
test('rules: staff cannot change a finalized rate; owner can',{skip:!enabled},async()=>{
  const value=await prepareRateEntry('finalized-rate');
  const changed={...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,ratePaise:12000}};
  await assertFails(setDoc(doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_finalized-rate'),changed));
  await assertSucceeds(setDoc(doc(env.authenticatedContext('owner').firestore(),'shops/a/records/entries_finalized-rate'),changed));
});
test('rules: staff can complete a pending rate but cannot void the entry',{skip:!enabled},async()=>{
  const value=await prepareRateEntry('pending-rate',true);
  const changed={...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,ratePaise:12000,ratePending:false}};
  const ref=doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_pending-rate');
  await assertSucceeds(setDoc(ref,changed));
  await assertFails(setDoc(ref,{...changed,updatedAt:changed.updatedAt+1000,payload:{...changed.payload,voided:true}}));
});
test('rules: entry quantity and endpoints stay immutable for owners too',{skip:!enabled},async()=>{
  const value=await prepareRateEntry('immutable-rate');
  await assertFails(setDoc(doc(env.authenticatedContext('owner').firestore(),'shops/a/records/entries_immutable-rate'),
    {...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,quantity:99}}));
});
test('rules: every entry category and a godam transfer can be saved by staff',{skip:!enabled},async()=>{
  await prepareRateEntry('category-fixture');
  await env.withSecurityRulesDisabled(async ctx=>{
    const db=ctx.firestore();
    await setDoc(doc(db,'shops/a/records/products_rate-product'),{payload:{id:'rate-product',kind:'product'}});
    await setDoc(doc(db,'shops/a/records/people_rate-supplier'),{payload:{id:'rate-supplier',kind:'supplier'}});
    await setDoc(doc(db,'shops/a/records/godams_main'),{payload:{id:'main',name:'Main godam'}});
  });
  const inventory={kind:'inventory',id:null},farmer={kind:'farmer',id:'rate-farmer'},supplier={kind:'supplier',id:'rate-supplier'};
  const cases=[
    {kind:'cash',itemId:null,source:farmer,destination:inventory,ratePaise:0,amountPaise:10000},
    {kind:'product',itemId:'rate-product',batch:'A',expiry:'2027-12-01'},
    {kind:'crop'},
    {kind:'diesel',itemId:null,destination:supplier,quantity:10,ratePaise:25000,cashPaise:50000,unit:'liter'},
    {kind:'other',itemId:null,destination:{kind:'walkIn',id:null},title:'Rent',ratePaise:0,amountPaise:10000,cashPaise:10000},
    {kind:'product',itemId:'rate-product',batch:'A',expiry:'2027-12-01',source:{kind:'godam',id:'main'},destination:inventory,ratePaise:0},
    {kind:'product',itemId:'rate-product',batch:'A',expiry:'2027-12-01',source:supplier,destination:inventory},
    {kind:'crop',source:farmer,destination:inventory,ratePending:true,ratePaise:0,cashPaise:5000},
  ];
  const db=env.authenticatedContext('staff').firestore();
  for(const [i,fields] of cases.entries()){
    const value=cropEntry(`category-${i}`);
    value.payload={...value.payload,...fields};
    await assertSucceeds(setDoc(doc(db,`shops/a/records/entries_${value.id}`),value));
  }
});
test('rules: direct supplier/farmer and supplier/supplier entries do not need a shop endpoint',{skip:!enabled},async()=>{
  await prepareRateEntry('direct-fixture');
  await env.withSecurityRulesDisabled(async ctx=>{
    const db=ctx.firestore();
    await setDoc(doc(db,'shops/a/records/people_direct-supplier'),{payload:{id:'direct-supplier',kind:'supplier'}});
    await setDoc(doc(db,'shops/a/records/people_direct-supplier2'),{payload:{id:'direct-supplier2',kind:'supplier'}});
    await setDoc(doc(db,'shops/a/records/products_direct-product'),{payload:{id:'direct-product',kind:'product'}});
  });
  const db=env.authenticatedContext('staff').firestore();
  const source={kind:'supplier',id:'direct-supplier'};
  for(const [i,destination] of [{kind:'farmer',id:'rate-farmer'},{kind:'supplier',id:'direct-supplier2'}].entries()){
    const value=cropEntry(`direct-${i}`);
    value.payload={...value.payload,kind:'product',itemId:'direct-product',source,destination,cashPaise:1000};
    await assertSucceeds(setDoc(doc(db,`shops/a/records/entries_${value.id}`),value));
  }
});
test('rules: receipt expiry is optional and allocated stock is immutable',{skip:!enabled},async()=>{
  await prepareRateEntry('allocation-fixture');
  await env.withSecurityRulesDisabled(async ctx=>{
    await setDoc(doc(ctx.firestore(),'shops/a/records/products_allocation-product'),{payload:{id:'allocation-product',kind:'product'}});
  });
  const db=env.authenticatedContext('staff').firestore();
  const receipt=cropEntry('optional-expiry');
  receipt.payload={...receipt.payload,kind:'product',itemId:'allocation-product',source:{kind:'farmer',id:'rate-farmer'},destination:{kind:'inventory',id:null},batch:'AUTO-BATCH',expiry:null};
  await assertSucceeds(setDoc(doc(db,'shops/a/records/entries_optional-expiry'),receipt));
  const sale=cropEntry('allocated-sale');
  sale.payload={...sale.payload,kind:'product',itemId:'allocation-product',allocations:[{batch:'AUTO-BATCH',expiry:null,quantity:1}]};
  const ref=doc(db,'shops/a/records/entries_allocated-sale');
  await assertSucceeds(setDoc(ref,sale));
  await assertFails(setDoc(ref,{...sale,updatedAt:sale.updatedAt+1000,payload:{...sale.payload,allocations:[{batch:'CHANGED',expiry:null,quantity:1}]}}));
});
test('rules: diesel can have a pending rate and staff can complete it',{skip:!enabled},async()=>{
  await prepareRateEntry('diesel-fixture');
  await env.withSecurityRulesDisabled(async ctx=>{
    await setDoc(doc(ctx.firestore(),'shops/a/records/people_diesel-supplier'),{payload:{id:'diesel-supplier',kind:'supplier'}});
  });
  const value=cropEntry('diesel-rate',true);
  value.payload={...value.payload,kind:'diesel',itemId:null,quantity:10,unit:'liter',destination:{kind:'supplier',id:'diesel-supplier'},cashPaise:50000};
  const ref=doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_diesel-rate');
  await assertSucceeds(setDoc(ref,value));
  await assertSucceeds(setDoc(ref,{...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,ratePending:false,ratePaise:25000}}));
});

async function prepareCropTrade(id, changes = {}) {
  await prepareRateEntry(`${id}-fixture`);
  await env.withSecurityRulesDisabled(async ctx=>{
    await setDoc(doc(ctx.firestore(),'shops/a/records/people_crop-buyer'),person('crop-buyer'));
  });
  const value=cropEntry(id);
  value.payload={...value.payload,cropPricing:true,purchaseRatePending:false,
    source:{kind:'farmer',id:'rate-farmer'},destination:{kind:'inventory',id:null},
    quantity:10,unit:'maan',unitFactor:40,ratePaise:280000,purchasePaise:280000,salePaise:0,...changes};
  return value;
}

test('rules: crop storage receipt has a purchase price and no sale price',{skip:!enabled},async()=>{
  const value=await prepareCropTrade('crop-storage');
  const db=env.authenticatedContext('staff').firestore();
  await assertSucceeds(setDoc(doc(db,'shops/a/records/entries_crop-storage'),value));
  for(const [i,changes] of [{salePaise:320000},{ratePaise:320000},{cashPaise:2800001+1},{purchaseRatePending:true}].entries()){
    const id=`crop-storage-invalid-${i}`;
    await assertFails(setDoc(doc(db,`shops/a/records/entries_${id}`),{...value,id,payload:{...value.payload,id,...changes}}));
  }
});

test('rules: pending crop purchase can be priced by staff without inventing a sale',{skip:!enabled},async()=>{
  const value=await prepareCropTrade('crop-storage-pending',{ratePending:true,ratePaise:0,purchasePaise:0,cashPaise:100000});
  const ref=doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_crop-storage-pending');
  await assertSucceeds(setDoc(ref,value));
  const changed={...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,ratePending:false,ratePaise:280000,purchasePaise:280000}};
  await assertSucceeds(setDoc(ref,changed));
  await assertFails(setDoc(ref,{...changed,updatedAt:changed.updatedAt+1000,payload:{...changed.payload,ratePaise:290000,purchasePaise:290000}}));
});

test('rules: direct crop rates are independent and staff cannot alter the known purchase',{skip:!enabled},async()=>{
  const value=await prepareCropTrade('crop-direct-pending-sale',{
    destination:{kind:'farmer',id:'crop-buyer'},ratePending:true,ratePaise:0,salePaise:0,cashPaise:100000});
  const ref=doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_crop-direct-pending-sale');
  await assertSucceeds(setDoc(ref,value));
  const changed={...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,ratePending:false,ratePaise:320000,salePaise:320000}};
  await assertFails(setDoc(ref,{...changed,payload:{...changed.payload,purchasePaise:100}}));
  await assertSucceeds(setDoc(ref,changed));
  await assertFails(setDoc(ref,{...changed,updatedAt:changed.updatedAt+1000,payload:{...changed.payload,voided:true}}));
  await assertSucceeds(setDoc(doc(env.authenticatedContext('owner').firestore(),'shops/a/records/entries_crop-direct-pending-sale'),
    {...changed,updatedAt:changed.updatedAt+1000,payload:{...changed.payload,voided:true}}));
});

test('rules: purchase may be pending while crop sale is priced; staff can complete only purchase',{skip:!enabled},async()=>{
  const value=await prepareCropTrade('crop-direct-pending-buy',{
    destination:{kind:'farmer',id:'crop-buyer'},purchaseRatePending:true,purchasePaise:0,ratePaise:320000,salePaise:320000});
  const ref=doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_crop-direct-pending-buy');
  await assertSucceeds(setDoc(ref,value));
  const changed={...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,purchaseRatePending:false,purchasePaise:280000}};
  await assertFails(setDoc(ref,{...changed,payload:{...changed.payload,ratePaise:330000,salePaise:330000}}));
  await assertSucceeds(setDoc(ref,changed));
});

test('rules: crop cash must fit both priced sides and stock/parties remain immutable',{skip:!enabled},async()=>{
  const value=await prepareCropTrade('crop-direct-priced',{
    destination:{kind:'farmer',id:'crop-buyer'},ratePaise:320000,salePaise:320000,cashPaise:100000});
  const db=env.authenticatedContext('owner').firestore(),ref=doc(db,'shops/a/records/entries_crop-direct-priced');
  await assertSucceeds(setDoc(ref,value));
  for(const changes of [{quantity:11},{cropPricing:false},{ratePending:true,ratePaise:0},{source:{kind:'inventory',id:null}}]){
    await assertFails(setDoc(ref,{...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,...changes}}));
  }
  const id='crop-direct-excess-cash';
  await assertFails(setDoc(doc(db,`shops/a/records/entries_${id}`),{...value,id,payload:{...value.payload,id,cashPaise:3000000}}));
  await assertSucceeds(setDoc(ref,{...value,updatedAt:value.updatedAt+1000,
    payload:{...value.payload,purchasePaise:270000,ratePaise:330000,salePaise:330000}}));
});

test('rules: staff can price both pending crop sides in one write',{skip:!enabled},async()=>{
  const value=await prepareCropTrade('crop-both-pending',{
    destination:{kind:'farmer',id:'crop-buyer'},ratePending:true,purchaseRatePending:true,
    ratePaise:0,purchasePaise:0,salePaise:0,cashPaise:100000});
  const ref=doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_crop-both-pending');
  await assertSucceeds(setDoc(ref,value));
  await assertSucceeds(setDoc(ref,{...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,
    ratePending:false,purchaseRatePending:false,ratePaise:320000,salePaise:320000,purchasePaise:280000}}));
});

test('rules: resolving a stored crop sale cannot change its saved purchase cost',{skip:!enabled},async()=>{
  const value=await prepareCropTrade('crop-stored-sale-pending',{
    source:{kind:'inventory',id:null},destination:{kind:'farmer',id:'crop-buyer'},
    ratePending:true,ratePaise:0,salePaise:0});
  const ref=doc(env.authenticatedContext('staff').firestore(),'shops/a/records/entries_crop-stored-sale-pending');
  await assertSucceeds(setDoc(ref,value));
  const changed={...value,updatedAt:value.updatedAt+1000,payload:{...value.payload,ratePending:false,ratePaise:320000,salePaise:320000}};
  await assertFails(setDoc(ref,{...changed,payload:{...changed.payload,purchasePaise:1}}));
  await assertSucceeds(setDoc(ref,changed));
});

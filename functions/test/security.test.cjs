const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {digest,matchesDigest,normalizeEmail,validId}=require(fs.existsSync(path.join(__dirname,'../lib/security.js'))?'../lib/security':'../src/security.ts');
test('codes are bound to a normalized email and server secret',()=>{
  const expected=digest('a-secret','ali@example.com:123456');
  assert.equal(matchesDigest(expected,digest('a-secret','ali@example.com:123456')),true);
  assert.equal(matchesDigest(expected,digest('a-secret','other@example.com:123456')),false);
  assert.equal(matchesDigest(expected,digest('different-secret','ali@example.com:123456')),false);
  assert.equal(matchesDigest(expected,'malformed'),false);
});
test('email normalization validates before sending',()=>{
  assert.equal(normalizeEmail('  Ali@Example.com '),'ali@example.com');
  for(const value of ['',null,'no-at-sign','x@y','x y@example.com'])assert.throws(()=>normalizeEmail(value));
});
test('path identifiers cannot escape their collection',()=>{
  assert.equal(validId('shop-a_123'),'shop-a_123');
  for(const value of ['../shop','a/b','','a?b'])assert.throws(()=>validId(value));
});

import { randomInt, randomBytes } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getAuth, DecodedIdToken } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onRequest, Request } from 'firebase-functions/v2/https';
import { defineInt, defineSecret, defineString } from 'firebase-functions/params';
import { createTransport } from 'nodemailer';
import { digest, matchesDigest, normalizeEmail, text, validId } from './security';

initializeApp();
const db = getFirestore();
const pepper = defineSecret('OTP_PEPPER');
const smtpUser = defineSecret('SMTP_USER');
const smtpPassword = defineSecret('SMTP_PASSWORD');
const smtpHost = defineString('SMTP_HOST');
const smtpPort = defineInt('SMTP_PORT', { default: 587 });
const emailFrom = defineString('EMAIL_FROM');
type Body = Record<string, unknown>;
class Failure extends Error {
  constructor(public readonly status: number, code: string) { super(code); }
}
async function identity(req: Request): Promise<DecodedIdToken> {
  const header = req.get('Authorization') ?? '';
  if (!header.startsWith('Bearer ')) throw new Failure(401, 'sessionExpired');
  try { return await getAuth().verifyIdToken(header.slice(7), true); }
  catch { throw new Failure(401, 'sessionExpired'); }
}
function endpoint(authenticated: boolean,
  handler: (body: Body, req: Request, user?: DecodedIdToken) => Promise<unknown>,
  mail = false) {
  return onRequest({ region: 'asia-south1', cors: true, maxInstances: 10, timeoutSeconds: 60,
    memory: '256MiB', secrets: mail ? [pepper, smtpUser, smtpPassword] : [pepper] }, async (req, res) => {
    res.set('Cache-Control', 'no-store');
    if (req.method !== 'POST') { res.status(405).json({ error: 'methodNotAllowed' }); return; }
    if (Number(req.get('content-length') ?? 0) > 16384) { res.status(413).json({ error: 'invalidRequest' }); return; }
    try {
      const user = authenticated ? await identity(req) : undefined;
      const result = await handler((req.body ?? {}) as Body, req, user);
      res.status(200).json(result ?? { ok: true });
    } catch (error) {
      const known = ['invalidEmail', 'requiredField', 'invalidId'];
      const status = error instanceof Failure ? error.status : error instanceof Error && known.includes(error.message) ? 400 : 500;
      // Do not return tokens, OTPs, SMTP errors or internal stack traces.
      const code = error instanceof Failure || error instanceof Error && known.includes(error.message) ? error.message : 'serverError';
      res.status(status).json({ error: code });
    }
  });
}
function ipKey(req: Request): string { return digest(pepper.value(), `ip:${req.ip ?? req.socket.remoteAddress ?? 'unknown'}`); }
async function limit(key: string, maximum: number, windowMs: number): Promise<void> {
  const ref = db.doc(`rateLimits/${key}`), now = Date.now();
  const allowed = await db.runTransaction(async tx => {
    const doc = await tx.get(ref), data = doc.data();
    if (data && data.until > now && data.count >= maximum) return false;
    const active = data && data.until > now;
    tx.set(ref, { count: active ? data.count + 1 : 1, until: active ? data.until : now + windowMs,
      expiresAt: Timestamp.fromMillis(now + windowMs * 2) });
    return true;
  });
  if (!allowed) throw new Failure(429, 'rateLimited');
}
async function member(user: DecodedIdToken, owner = false) {
  const profile = (await db.doc(`users/${user.uid}`).get()).data();
  if (!profile?.shopId) throw new Failure(403, 'shopRequired');
  const membership = (await db.doc(`shops/${profile.shopId}/members/${user.uid}`).get()).data();
  if (!membership || (owner && membership.role !== 'owner')) throw new Failure(403, 'ownerOnly');
  return { shopId: profile.shopId as string, role: membership.role as string };
}

export const requestEmailCode = endpoint(false, async (body, req) => {
  const email = normalizeEmail(body.email);
  await limit(`email-ip-${ipKey(req)}`, 20, 3600000);
  const key = digest(pepper.value(), `email:${email}`), ref = db.doc(`emailChallenges/${key}`);
  const code = randomInt(100000, 1000000).toString(), now = Date.now();
  const allowed = await db.runTransaction(async tx => {
    const previous = (await tx.get(ref)).data();
    if (previous && now - previous.sentAt < 60000) return false;
    tx.set(ref, { digest: digest(pepper.value(), `${email}:${code}`), sentAt: now,
      expiresAt: Timestamp.fromMillis(now + 300000), attempts: 0, consumed: false });
    return true;
  });
  if (!allowed) throw new Failure(429, 'rateLimited');
  await limit(`email-account-${key}`, 8, 3600000);
  await createTransport({ host: smtpHost.value(), port: smtpPort.value(), secure: smtpPort.value() === 465,
    requireTLS: smtpPort.value() !== 465, auth: { user: smtpUser.value(), pass: smtpPassword.value() } }).sendMail({
    from: emailFrom.value(), to: email, subject: 'Your PestiKhata sign-in code',
    text: `Your PestiKhata code is ${code}. It expires in 5 minutes. Do not share this code.\n\nAap ka PestiKhata code ${code} hai. Yeh 5 minute mein khatam ho jayega. Code kisi ko na dein.`,
  });
  return { ok: true };
}, true);

export const verifyEmailCode = endpoint(false, async (body, req) => {
  await limit(`verify-${ipKey(req)}`, 50, 600000);
  const email = normalizeEmail(body.email), code = text(body.code, 6);
  if (!/^\d{6}$/.test(code)) throw new Failure(400, 'invalidCode');
  const ref = db.doc(`emailChallenges/${digest(pepper.value(), `email:${email}`)}`);
  const result = await db.runTransaction(async tx => {
    const challenge = (await tx.get(ref)).data();
    if (!challenge || challenge.consumed || challenge.expiresAt.toMillis() < Date.now()) return 'codeExpired';
    if (challenge.attempts >= 5) return 'rateLimited';
    const good = matchesDigest(challenge.digest, digest(pepper.value(), `${email}:${code}`));
    tx.update(ref, { attempts: challenge.attempts + 1, consumed: good });
    return good ? 'ok' : 'invalidCode';
  });
  if (result !== 'ok') throw new Failure(400, result);
  let user;
  try { user = await getAuth().getUserByEmail(email); }
  catch (error) {
    if ((error as { code?: string }).code !== 'auth/user-not-found') throw error;
    user = await getAuth().createUser({ email, emailVerified: true });
  }
  if (user.disabled) throw new Failure(403, 'sessionExpired');
  if (!user.emailVerified) await getAuth().updateUser(user.uid, { emailVerified: true });
  return { token: await getAuth().createCustomToken(user.uid) };
});

export const getProfile = endpoint(true, async (_body, _req, user) => {
  const profile = (await db.doc(`users/${user!.uid}`).get()).data();
  if (!profile?.shopId) return { userId: user!.uid, shopId: '', shopName: '', role: 'staff' };
  const membership = (await db.doc(`shops/${profile.shopId}/members/${user!.uid}`).get()).data();
  if (!membership) return { userId: user!.uid, shopId: '', shopName: '', role: 'staff', revoked: true };
  const access = { shopId: profile.shopId as string, role: membership.role as string };
  const shop = (await db.doc(`shops/${access.shopId}`).get()).data();
  return { userId: user!.uid, shopId: access.shopId, shopName: shop?.name ?? '', role: access.role };
});

export const createShop = endpoint(true, async (body, _req, user) => {
  const name = text(body.name), shop = db.collection('shops').doc(), profile = db.doc(`users/${user!.uid}`);
  await db.runTransaction(async tx => {
    const existing = await tx.get(profile);
    if (existing.data()?.shopId) throw new Failure(409, 'alreadyHasShop');
    tx.create(shop, { name, ownerId: user!.uid, createdAt: Timestamp.now() });
    tx.create(shop.collection('members').doc(user!.uid), { role: 'owner', label: user!.email ?? user!.phone_number ?? user!.uid, joinedAt: Timestamp.now() });
    tx.set(profile, { shopId: shop.id });
  });
  return { shopId: shop.id };
});

export const createInvite = endpoint(true, async (_body, _req, user) => {
  const access = await member(user!, true);
  await limit(`invite-${access.shopId}`, 20, 86400000);
  const code = randomBytes(6).toString('hex').toUpperCase();
  await db.doc(`invites/${digest(pepper.value(), `invite:${code}`)}`).create({ shopId: access.shopId,
    role: 'staff', used: false, createdBy: user!.uid, expiresAt: Timestamp.fromMillis(Date.now() + 48 * 3600000) });
  return { code };
});

export const joinShop = endpoint(true, async (body, _req, user) => {
  await limit(`join-${user!.uid}`, 10, 3600000);
  const code = text(body.code, 12).toUpperCase();
  const invite = db.doc(`invites/${digest(pepper.value(), `invite:${code}`)}`), profile = db.doc(`users/${user!.uid}`);
  await db.runTransaction(async tx => {
    const [current, invitation] = await Promise.all([tx.get(profile), tx.get(invite)]);
    const data = invitation.data();
    if (current.data()?.shopId && current.data()?.shopId !== data?.shopId) throw new Failure(409, 'alreadyHasShop');
    if (!data || data.used || data.expiresAt.toMillis() < Date.now()) throw new Failure(400, 'invalidCode');
    // An invitation is invalid as soon as its issuing owner loses ownership.
    const issuer = await tx.get(db.doc(`shops/${data.shopId}/members/${data.createdBy}`));
    if (issuer.data()?.role !== 'owner') throw new Failure(400, 'invalidCode');
    tx.create(db.doc(`shops/${data.shopId}/members/${user!.uid}`), { role: 'staff',
      label: user!.email ?? user!.phone_number ?? user!.uid, joinedAt: Timestamp.now() });
    tx.set(profile, { shopId: data.shopId });
    tx.update(invite, { used: true, usedBy: user!.uid });
  });
  return { ok: true };
});

export const listMembers = endpoint(true, async (_body, _req, user) => {
  const access = await member(user!, true);
  const docs = await db.collection(`shops/${access.shopId}/members`).get();
  return { members: docs.docs.map(d => ({ userId: d.id, role: d.data().role, label: d.data().label })) };
});

export const revokeMember = endpoint(true, async (body, _req, user) => {
  const access = await member(user!, true), uid = validId(body.userId);
  const ref = db.doc(`shops/${access.shopId}/members/${uid}`);
  await db.runTransaction(async tx => {
    const data = (await tx.get(ref)).data();
    if (!data || data.role === 'owner' || uid === user!.uid) throw new Failure(403, 'ownerOnly');
    tx.delete(ref);
    // Retain the one-shop affiliation; revocation must not permit silently
    // taking an old user's cached database into a different shop.
  });
  await getAuth().revokeRefreshTokens(uid);
  return { ok: true };
});

export const startDesktopSignIn = endpoint(false, async (body, req) => {
  await limit(`desktop-start-${ipKey(req)}`, 20, 3600000);
  const secret = text(body.secret, 64);
  if (!/^[a-zA-Z0-9_-]{43}$/.test(secret)) throw new Failure(400, 'invalidRequest');
  const ref = db.collection('desktopSessions').doc();
  await ref.create({ secret: digest(pepper.value(), `desktop:${secret}`), userId: null, consumed: false,
    expiresAt: Timestamp.fromMillis(Date.now() + 5 * 60000) });
  return { sessionId: ref.id };
});

export const completeDesktopSignIn = endpoint(true, async (body, _req, user) => {
  const ref = db.doc(`desktopSessions/${validId(body.sessionId)}`);
  await db.runTransaction(async tx => {
    const data = (await tx.get(ref)).data();
    if (!data || data.consumed || data.userId || data.expiresAt.toMillis() < Date.now()) throw new Failure(400, 'codeExpired');
    tx.update(ref, { userId: user!.uid });
  });
  return { ok: true };
});

export const pollDesktopSignIn = endpoint(false, async (body, req) => {
  await limit(`desktop-poll-${ipKey(req)}`, 240, 600000);
  const ref = db.doc(`desktopSessions/${validId(body.sessionId)}`), secret = text(body.secret, 64);
  const uid = await db.runTransaction(async tx => {
    const data = (await tx.get(ref)).data();
    if (!data || !matchesDigest(data.secret, digest(pepper.value(), `desktop:${secret}`)) ||
      data.consumed || data.expiresAt.toMillis() < Date.now()) throw new Failure(400, 'codeExpired');
    if (!data.userId) return null;
    tx.update(ref, { consumed: true });
    return data.userId as string;
  });
  return uid ? { token: await getAuth().createCustomToken(uid) } : { pending: true };
});

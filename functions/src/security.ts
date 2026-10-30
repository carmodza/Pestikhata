import { createHmac, timingSafeEqual } from 'node:crypto';

export function digest(pepper: string, value: string): string {
  return createHmac('sha256', pepper).update(value).digest('hex');
}
export function matchesDigest(expected: string, actual: string): boolean {
  if (!/^[a-f0-9]{64}$/.test(expected) || !/^[a-f0-9]{64}$/.test(actual)) return false;
  return timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(actual, 'hex'));
}
export function normalizeEmail(value: unknown): string {
  const email = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error('invalidEmail');
  return email;
}
export function text(value: unknown, max = 120): string {
  if (typeof value !== 'string' || !value.trim() || value.length > max) throw new Error('requiredField');
  return value.trim();
}
export function validId(value: unknown): string {
  const id = text(value, 128);
  if (!/^[a-zA-Z0-9_-]+$/.test(id)) throw new Error('invalidId');
  return id;
}

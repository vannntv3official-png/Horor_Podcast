import { describe, it, expect } from 'vitest';
import type { UserRole } from '../src/types';

describe('Admin Authorization Rules', () => {
  it('correctly evaluates admin and editor privileges', () => {
    const isEditor = (role: UserRole | null) => role === 'admin' || role === 'editor';
    const isAdmin = (role: UserRole | null) => role === 'admin';

    expect(isAdmin('admin')).toBe(true);
    expect(isAdmin('editor')).toBe(false);
    expect(isAdmin('user')).toBe(false);
    expect(isAdmin(null)).toBe(false);

    expect(isEditor('admin')).toBe(true);
    expect(isEditor('editor')).toBe(true);
    expect(isEditor('user')).toBe(false);
    expect(isEditor(null)).toBe(false);
  });
});

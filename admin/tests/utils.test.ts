import { describe, it, expect } from 'vitest';
import { formatDuration, formatBytes, formatDate, cn } from '../src/lib/utils';

describe('Admin Utility Functions', () => {
  it('formats audio seconds into mm:ss and hh:mm:ss', () => {
    expect(formatDuration(0)).toBe('00:00');
    expect(formatDuration(45)).toBe('00:45');
    expect(formatDuration(125)).toBe('02:05');
    expect(formatDuration(3665)).toBe('1:01:05');
    expect(formatDuration(null)).toBe('00:00');
  });

  it('formats byte sizes correctly', () => {
    expect(formatBytes(0)).toBe('0 B');
    expect(formatBytes(1024)).toBe('1 KB');
    expect(formatBytes(10485760)).toBe('10 MB');
    expect(formatBytes(null)).toBe('0 B');
  });

  it('formats ISO dates nicely', () => {
    const formatted = formatDate('2026-10-22T00:00:00Z');
    expect(formatted).toBeTruthy();
    expect(formatDate(null)).toBe('-');
  });

  it('merges tailwind class names properly', () => {
    const res = cn('px-4 py-2', 'bg-red-500', { 'text-white': true, 'hidden': false });
    expect(res).toContain('px-4');
    expect(res).toContain('bg-red-500');
    expect(res).toContain('text-white');
  });
});

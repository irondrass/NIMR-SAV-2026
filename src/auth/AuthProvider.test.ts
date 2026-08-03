import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { isE2ETestSession } from './AuthProvider';

describe('contrat AuthProvider phase 3A', () => {
  it('n’active pas le mode E2E sans le paramètre explicite', () => {
    expect(isE2ETestSession()).toBe(false);
  });

  it('utilise la session Supabase et ne contient aucune clé serveur', () => {
    const source = readFileSync(resolve(process.cwd(), 'src/auth/AuthProvider.tsx'), 'utf8');
    expect(source).toContain('onAuthStateChange');
    expect(source).toContain("from('profiles')");
    expect(source).toContain("from('profile_roles')");
    expect(source).toContain("from('profile_site_access')");
    expect(source).not.toMatch(/service[_-]role/i);
  });
});

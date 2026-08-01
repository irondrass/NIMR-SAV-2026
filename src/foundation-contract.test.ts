import { describe, expect, it } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { NAV_ITEMS } from './layouts/AppLayout';
import { ROLES, ROLE_PERMISSIONS } from './types/auth';

const root = resolve(process.cwd(), 'src');
const read = (file: string) => readFileSync(resolve(root, file), 'utf8');

describe('contrats réels de fondation', () => {
  it('contient exactement les huit rôles contractuels', () => expect(ROLES).toEqual(['ADMIN_TECHNIQUE','DIRECTEUR_SAV','CHEF_ATELIER','IMPORT_DEVIS','TECHNICIEN','CONTROLE_QUALITE','RESPONSABLE_GARANTIE','LECTURE_SEULE']));
  it('ne contient aucun rôle ou permission retiré', () => { const auth = read('types/auth.ts'); expect(auth).not.toContain('reception.manage'); expect(auth).not.toContain('parts.manage'); expect(Object.keys(ROLE_PERMISSIONS)).not.toContain('RECEPTION'); expect(Object.keys(ROLE_PERMISSIONS)).not.toContain('MAGASIN_PDR'); });
  it('ne contient aucun répertoire fonctionnel interdit', () => { for (const folder of ['clients','vehicles','parts','parts-blocking','pdr','reception','reception-appointments']) expect(existsSync(resolve(root, 'features', folder))).toBe(false); });
  it('ne contient aucune route ou navigation interdite et expose l’import', () => { const routes = read('routes/AppRoutes.tsx'); const layout = read('layouts/AppLayout.tsx'); for (const route of ['/reception','/clients','/vehicles','/parts','/pdr','/parts-blocking']) expect(routes).not.toContain(route); expect(routes).toContain('/quote-import'); expect(NAV_ITEMS.map((item) => item.path)).toContain('/quote-import'); expect(layout).not.toContain('Nouvelle réception'); });
  it('ne persiste aucune donnée métier dans le stockage navigateur', () => { for (const file of ['main.tsx','routes/AppRoutes.tsx','layouts/AppLayout.tsx','auth/AuthProvider.tsx','lib/supabase.ts']) { const source = read(file); expect(source).not.toContain('localStorage'); expect(source).not.toContain('indexedDB'); } });
  it('ne configure Playwright qu’une seule fois', () => { const config = readFileSync(resolve(process.cwd(), 'playwright.config.ts'), 'utf8'); expect((config.match(/export default defineConfig/g) ?? []).length).toBe(1); expect(config).toContain("name: 'desktop'"); expect(config).toContain("name: 'tablet'"); expect(config).toContain("name: 'mobile'"); });
});

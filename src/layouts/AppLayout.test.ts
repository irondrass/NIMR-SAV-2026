import { describe, expect, it } from 'vitest';
import { NAV_ITEMS } from './AppLayout';
describe('navigation corrigée', () => { it('ne contient aucun module hors périmètre', () => { const text = NAV_ITEMS.map((item) => `${item.label} ${item.path}`).join(' ').toLowerCase(); for (const forbidden of ['réception','clients','véhicules','pièces','pdr']) expect(text).not.toContain(forbidden); }); it('expose l’import et son historique', () => { expect(NAV_ITEMS.map((item) => item.path)).toEqual(expect.arrayContaining(['/quote-import','/imports'])); }); });

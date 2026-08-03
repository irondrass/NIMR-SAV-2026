import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import type { User } from '../types/auth';
import { isSupabaseConfigured, supabase } from '../lib/supabase';
import { ROLES, type Role, type Site } from '../types/auth';

type AuthStatus = 'loading' | 'authenticated' | 'unauthenticated' | 'configuration_error';
type AuthContextValue = { user: User | null; sites: Site[]; loading: boolean; isConfigured: boolean; status: AuthStatus; error: string | null };
const AuthContext = createContext<AuthContextValue>({ user: null, sites: [], loading: false, isConfigured: false, status: 'configuration_error', error: null });
export function isE2ETestSession(): boolean { return import.meta.env.DEV && import.meta.env.VITE_ENABLE_E2E_AUTH === 'true' && new URLSearchParams(window.location.search).get('e2eAuth') === '1'; }

export function AuthProvider({ children }: { children: ReactNode }) {
  const testSession = isE2ETestSession();
  const [user, setUser] = useState<User | null>(testSession ? { id: 'e2e-test-session', email: 'e2e@test.invalid', displayName: 'Utilisateur E2E', roles: ['IMPORT_DEVIS'] } : null);
  const [sites, setSites] = useState<Site[]>([]);
  const [status, setStatus] = useState<AuthStatus>(testSession ? 'authenticated' : isSupabaseConfigured ? 'loading' : 'configuration_error');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const client = supabase;
    if (testSession || !client) return;
    let mounted = true;
    const loadUser = async (sessionUser: { id: string; email?: string | null } | null) => {
      if (!sessionUser) { if (mounted) { setUser(null); setSites([]); setStatus('unauthenticated'); } return; }
      const [profileResult, rolesResult, sitesResult] = await Promise.all([
        client.from('profiles').select('id,email,display_name,active').eq('id', sessionUser.id).maybeSingle(),
        client.from('profile_roles').select('roles(code)').eq('profile_id', sessionUser.id),
        client.from('profile_site_access').select('sites(id,organization_id,name,city,active)').eq('profile_id', sessionUser.id),
      ]);
      if (!mounted) return;
      if (profileResult.error || rolesResult.error || sitesResult.error) { setUser(null); setSites([]); setError('Impossible de charger le profil et son périmètre.'); setStatus('configuration_error'); return; }
      const profile = profileResult.data;
      if (!profile || !profile.active) { setUser(null); setSites([]); setError('Profil absent ou inactif.'); setStatus('unauthenticated'); return; }
      const roleRows = (rolesResult.data ?? []) as unknown as Array<{ roles?: { code?: string } | Array<{ code?: string }> }>;
      const siteRows = (sitesResult.data ?? []) as unknown as Array<{ sites?: { id: string; organization_id: string; name: string; city: string | null; active: boolean } | Array<{ id: string; organization_id: string; name: string; city: string | null; active: boolean }> }>;
      const roles = roleRows.map((row) => Array.isArray(row.roles) ? row.roles[0]?.code : row.roles?.code).filter((role): role is Role => typeof role === 'string' && (ROLES as readonly string[]).includes(role));
      const authorizedSites = siteRows.map((row) => Array.isArray(row.sites) ? row.sites[0] : row.sites).filter((site): site is { id: string; organization_id: string; name: string; city: string | null; active: boolean } => Boolean(site?.id && site.active)).map((site) => ({ id: site.id, organizationId: site.organization_id, name: site.name, city: site.city ?? '', active: site.active }));
      setUser({ id: profile.id, email: profile.email ?? sessionUser.email ?? '', displayName: profile.display_name ?? '', roles });
      setSites(authorizedSites); setError(null); setStatus('authenticated');
    };
    void client.auth.getSession().then(({ data }) => loadUser(data.session?.user ?? null));
    const { data: listener } = client.auth.onAuthStateChange((_event, session) => { void loadUser(session?.user ?? null); });
    return () => { mounted = false; listener.subscription.unsubscribe(); };
  }, [testSession]);

  return <AuthContext.Provider value={{ user, sites, loading: status === 'loading', isConfigured: isSupabaseConfigured || testSession, status, error }}>{children}</AuthContext.Provider>;
}
export function useAuth() { return useContext(AuthContext); }

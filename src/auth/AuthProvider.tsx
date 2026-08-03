import { createContext, useContext, type ReactNode } from 'react';
import type { User } from '../types/auth';
import { isSupabaseConfigured } from '../lib/supabase';
type AuthContextValue = { user: User | null; loading: boolean; isConfigured: boolean };
const AuthContext = createContext<AuthContextValue>({ user: null, loading: false, isConfigured: false });
export function isE2ETestSession(): boolean { return import.meta.env.DEV && import.meta.env.VITE_ENABLE_E2E_AUTH === 'true' && new URLSearchParams(window.location.search).get('e2eAuth') === '1'; }
export function AuthProvider({ children }: { children: ReactNode }) { const testSession = isE2ETestSession(); const user: User | null = testSession ? { id: 'e2e-test-session', email: 'e2e@test.invalid', displayName: 'Utilisateur E2E', roles: ['IMPORT_DEVIS'] } : null; return <AuthContext.Provider value={{ user, loading: false, isConfigured: isSupabaseConfigured || testSession }}>{children}</AuthContext.Provider>; }
export function useAuth() { return useContext(AuthContext); }

import { createContext, useContext, type ReactNode } from 'react';
import type { User } from '../types/auth';
import { isSupabaseConfigured } from '../lib/supabase';
type AuthContextValue = { user: User | null; loading: boolean; isConfigured: boolean };
const AuthContext = createContext<AuthContextValue>({ user: null, loading: false, isConfigured: false });
export function AuthProvider({ children }: { children: ReactNode }) { return <AuthContext.Provider value={{ user: null, loading: false, isConfigured: isSupabaseConfigured }}>{children}</AuthContext.Provider>; }
export function useAuth() { return useContext(AuthContext); }

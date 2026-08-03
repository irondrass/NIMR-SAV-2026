import { createClient, type SupabaseClient } from '@supabase/supabase-js';

// Deliberately untyped until `supabase gen types typescript --local` is adopted.
// Only the browser-safe anon/publishable key is accepted here.
const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
export const isSupabaseConfigured = Boolean(url && anonKey);
export const supabase: SupabaseClient | null = isSupabaseConfigured ? createClient(url!, anonKey!) : null;

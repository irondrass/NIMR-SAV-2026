import type { ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from './AuthProvider';
import { ConfigurationPage } from '../features/settings/ConfigurationPage';
export function ProtectedRoute({ children }: { children: ReactNode }) { const { user, loading, isConfigured, status } = useAuth(); if (loading) return <div className="p-8">Chargement de la session…</div>; if (!isConfigured || status === 'configuration_error') return <ConfigurationPage/>; if (!user) return <Navigate to="/configuration" replace/>; return <>{children}</>; }

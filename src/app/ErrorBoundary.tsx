import { Component, type ErrorInfo, type ReactNode } from 'react';
export class ErrorBoundary extends Component<{ children: ReactNode }, { hasError: boolean }> {
  state = { hasError: false };
  static getDerivedStateFromError() { return { hasError: true }; }
  componentDidCatch(error: Error, info: ErrorInfo) { console.error('Application error', error, info); }
  render() { return this.state.hasError ? <main className="min-h-screen grid place-items-center bg-mist p-6"><section className="card max-w-lg text-center"><p className="eyebrow">Incident applicatif</p><h1 className="mt-2 text-2xl font-semibold text-ink">Une erreur inattendue est survenue</h1><p className="mt-3 text-slate-600">Rechargez la page. Si le problème persiste, contactez l’administrateur technique.</p><button className="btn-primary mt-6" onClick={() => window.location.reload()}>Recharger</button></section></main> : this.props.children; }
}

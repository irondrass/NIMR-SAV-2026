import { useReducer, useState, type ChangeEvent } from 'react';
import { CheckCircle2, FileText, UploadCloud } from 'lucide-react';
import { EmptyState, PageHeader } from '../../../components/ui';
import { parseCsv, sourceFileToText, validateCsvSourceFile } from '../parsers/csv';
import { suggestColumnMappings, validateMappings } from '../mapping/mapping';
import { approveQuoteImportLocally, buildNormalizedQuote } from '../domain/drafts';
import { validateNormalizedQuote } from '../validation/validate';
import { computeFileSha256, maskFileHash } from '../domain/hash';
import { initialQuoteImportState, quoteImportReducer } from '../state/reducer';
import type { QuoteSourceFile } from '../domain/types';

const steps = ['Sélection du fichier', 'Contrôle du fichier', 'Mapping', 'Prévisualisation', 'Erreurs et avertissements', 'Résumé', 'Approbation locale'];
const statusStep: Record<string, number> = { FILE_SELECTED: 1, HASHING: 2, PARSING: 2, MAPPING_REQUIRED: 3, READY_FOR_REVIEW: 4, VALIDATION_ERROR: 5, APPROVED_LOCALLY: 7, SERVER_CONFIRMATION_REQUIRED: 7, REJECTED: 1 };
const labels: Record<string, string> = { line_label: 'Désignation du travail', quote_reference: 'Référence du devis', quantity: 'Quantité de travaux', labor_hours: 'Durée prévue (heures)', quote_date: 'Date du devis', LABOR: 'Main-d’œuvre', BODYWORK: 'Tôlerie', PAINT: 'Peinture', MECHANICAL: 'Mécanique', ELECTRICAL: 'Électricité', DIAGNOSTIC: 'Diagnostic', OTHER: 'Autre', DISASSEMBLY: 'Dépose', BODY_REPAIR: 'Réparation carrosserie', PREPARATION: 'Préparation', QUALITY_CONTROL: 'Contrôle qualité', UNSPECIFIED: 'Non spécifiée', FILE_SELECTED: 'Fichier sélectionné', HASHING: 'Empreinte en cours', PARSING: 'Lecture en cours', MAPPING_REQUIRED: 'Mapping requis', READY_FOR_REVIEW: 'Prêt pour revue', VALIDATION_ERROR: 'Erreur de validation', SERVER_CONFIRMATION_REQUIRED: 'Confirmation serveur requise', REJECTED: 'Rejeté' };

export function QuoteImportPage() {
  const [state, dispatch] = useReducer(quoteImportReducer, initialQuoteImportState);
  const [dragActive, setDragActive] = useState(false);
  const step = statusStep[state.status] ?? 1;
  const processFile = async (file: File) => {
    const source: QuoteSourceFile = { name: file.name, size: file.size, type: file.type, lastModified: file.lastModified, bytes: new Uint8Array(await file.arrayBuffer()) };
    dispatch({ type: 'SELECT_FILE', file: source });
    const fileCheck = validateCsvSourceFile(source);
    if (!fileCheck.valid) { dispatch({ type: 'PARSING_FAILURE', issues: fileCheck.issues }); return; }
    dispatch({ type: 'START_HASHING' });
    const hash = await computeFileSha256(source.bytes);
    dispatch({ type: 'HASH_SUCCESS', hash: { algorithm: 'SHA-256', value: hash } });
    const parsed = parseCsv(sourceFileToText(source));
    if (!parsed.sheet || parsed.issues.some((issue) => issue.severity === 'BLOCKING')) { dispatch({ type: 'PARSING_FAILURE', issues: parsed.issues }); return; }
    dispatch({ type: 'PARSING_SUCCESS', sheet: parsed.sheet, mappings: suggestColumnMappings(parsed.sheet) });
  };
  const onFileChange = (event: ChangeEvent<HTMLInputElement>) => { const file = event.target.files?.[0]; if (file) void processFile(file); };
  const updateMapping = (target: string, sourceColumn: string) => dispatch({ type: 'UPDATE_MAPPING', mappings: state.mappings.map((mapping) => mapping.target === target ? { ...mapping, sourceColumn: sourceColumn || undefined, confidence: sourceColumn ? 1 : 0, ambiguous: false, reason: 'Correction manuelle' } : mapping) });
  const approveMapping = () => {
    if (!state.sheet) return;
    const checked = validateMappings(state.mappings, state.sheet);
    if (!checked.valid) { dispatch({ type: 'VALIDATION_FAILURE', issues: checked.errors.map((message) => ({ code: 'REQUIRED_FIELD_MISSING', severity: 'BLOCKING', message })) }); return; }
    dispatch({ type: 'APPROVE_MAPPING' });
    const quote = buildNormalizedQuote(state.sheet, state.mappings);
    const validation = validateNormalizedQuote(quote);
    dispatch({ type: 'RUN_VALIDATION', quote, summary: validation.summary, issues: validation.issues });
  };
  const approveLocally = () => {
    if (!state.quote || !state.file || !state.hash) return;
    const approval = approveQuoteImportLocally(state.quote, state.file.name, state.hash.value, crypto.randomUUID(), state.issues);
    if (approval.status === 'SERVER_CONFIRMATION_REQUIRED') dispatch({ type: 'APPROVE_LOCALLY', approval }); else dispatch({ type: 'VALIDATION_FAILURE', issues: approval.issues });
  };
  return <>
    <PageHeader eyebrow="Import contrôlé" title="Importer un devis" description="CSV UTF-8 uniquement. Le devis est utilisé uniquement pour identifier les travaux à planifier." />
    <div className="mb-6 grid grid-cols-2 gap-2 md:grid-cols-7">{steps.map((label, index) => <div key={label} className={`rounded-lg border p-3 text-center text-xs ${index + 1 === step ? 'border-teal bg-teal/10 text-ink' : 'border-line bg-white text-slate-500'}`}><span className="font-bold">{index + 1}</span><span className="mt-1 hidden md:block">{label}</span></div>)}</div>
    <section className="card">
      <div className="flex items-start justify-between gap-4"><div><h2 className="section-title">{steps[step - 1]}</h2><p className="mt-1 text-sm text-slate-500">Les informations commerciales ne sont pas conservées dans le périmètre opérationnel.</p></div><span className="rounded-full bg-mist px-3 py-1 text-xs font-semibold text-teal">{labels[state.status] ?? state.status}</span></div>
      {!state.file && <label onDragOver={(event) => { event.preventDefault(); setDragActive(true); }} onDragLeave={() => setDragActive(false)} onDrop={(event) => { event.preventDefault(); setDragActive(false); const file = event.dataTransfer.files[0]; if (file) void processFile(file); }} className={`mt-6 block cursor-pointer rounded-xl border-2 border-dashed p-10 text-center ${dragActive ? 'border-teal bg-teal/5' : 'border-line bg-mist'}`}><UploadCloud className="mx-auto text-teal" size={34} /><span className="mt-3 block font-medium text-ink">Déposer un devis CSV UTF-8</span><span className="mt-2 block text-sm text-slate-500">ou sélectionner un fichier dans l’explorateur</span><input aria-label="Sélectionner un fichier CSV" className="sr-only" type="file" accept=".csv,text/csv" onChange={onFileChange} /></label>}
      {state.file && <div className="mt-6 grid gap-4 md:grid-cols-3"><div className="rounded-lg border border-line p-4"><FileText className="text-teal" size={20} /><p className="mt-2 font-medium text-ink">{state.file.name}</p><p className="text-xs text-slate-500">{state.file.size.toLocaleString('fr-FR')} octets</p></div><div className="rounded-lg border border-line p-4"><p className="text-xs uppercase tracking-wide text-slate-500">Empreinte SHA-256</p><p className="mt-2 font-mono text-sm text-ink">{state.hash ? maskFileHash(state.hash.value) : 'Calcul en cours…'}</p></div><div className="rounded-lg border border-line p-4"><p className="text-xs uppercase tracking-wide text-slate-500">Séparateur</p><p className="mt-2 font-medium text-ink">{state.sheet?.delimiter ?? 'Détection en cours…'}</p></div></div>}
      {state.sheet && <div className="mt-6"><h3 className="font-semibold text-ink">Mapping des colonnes utiles aux travaux</h3><div className="mt-3 grid gap-3 md:grid-cols-2">{state.mappings.filter((mapping) => ['line_label', 'quote_reference', 'quantity', 'labor_hours', 'quote_date'].includes(mapping.target)).map((mapping) => <label className="text-sm" key={mapping.target}><span className="mb-1 block text-slate-600">{labels[mapping.target] ?? mapping.target}</span><select className="min-h-11 w-full rounded-lg border border-line bg-white px-3" value={mapping.sourceColumn ?? ''} onChange={(event) => updateMapping(mapping.target, event.target.value)}><option value="">Ignorer</option>{state.sheet?.headers.map((header) => <option key={header} value={header}>{header}</option>)}</select></label>)}</div><button className="btn-primary mt-5" onClick={approveMapping}>Prévisualiser et valider le mapping</button></div>}
      {state.quote && <div className="mt-6 overflow-x-auto"><h3 className="font-semibold text-ink">Prévisualisation des travaux</h3><table className="mt-3 w-full min-w-[680px] text-left text-sm"><thead><tr className="border-b border-line text-xs uppercase text-slate-500"><th className="p-2">Ligne</th><th className="p-2">Travail identifié</th><th className="p-2">Catégorie</th><th className="p-2">Étape</th><th className="p-2">Durée prévue</th></tr></thead><tbody>{state.quote.lines.map((line) => <tr className="border-b border-line" key={line.sourceRowNumber}><td className="p-2">{line.sourceRowNumber}</td><td className="p-2">{line.normalizedLabel || '—'}</td><td className="p-2">{labels[line.operationCategory] ?? line.operationCategory}</td><td className="p-2">{labels[line.stage] ?? line.stage}</td><td className="p-2">{line.planningDurationMinutes} min</td></tr>)}</tbody></table></div>}
      {state.summary && <div className="mt-6 grid gap-3 sm:grid-cols-3"><div className="rounded-lg bg-mist p-4"><p className="text-xs text-slate-500">Travaux valides</p><p className="mt-1 text-2xl font-semibold text-ink">{state.summary.validRows}</p></div><div className="rounded-lg bg-mist p-4"><p className="text-xs text-slate-500">Travaux rejetés</p><p className="mt-1 text-2xl font-semibold text-ink">{state.summary.rejectedRows}</p></div><div className="rounded-lg bg-mist p-4"><p className="text-xs text-slate-500">Durée prévue totale</p><p className="mt-1 text-2xl font-semibold text-ink">{state.quote?.lines.reduce((sum, line) => sum + line.planningDurationMinutes, 0) ?? 0} min</p></div></div>}
      {state.issues.length > 0 && <div className="mt-6 rounded-lg border border-amber-200 bg-amber-50 p-4"><h3 className="font-semibold text-amber-900">Erreurs et avertissements</h3><ul className="mt-2 space-y-1 text-sm text-amber-900">{state.issues.map((issue, index) => <li key={`${issue.code}-${index}`}>{issue.severity} — {issue.message}</li>)}</ul></div>}
      {state.approval && <div className="mt-6 flex items-start gap-3 rounded-lg border border-teal/30 bg-teal/10 p-4 text-ink"><CheckCircle2 className="shrink-0 text-teal" /><div><p className="font-semibold">Travaux validés localement — confirmation serveur requise</p><p className="mt-1 text-sm text-slate-600">Aucun dossier n’a encore été enregistré en base.</p></div></div>}
      {state.quote && !state.approval && <div className="mt-6 flex flex-wrap gap-3"><button className="btn-secondary" onClick={() => dispatch({ type: 'RESET_IMPORT' })}>Annuler</button><button className="btn-primary" onClick={approveLocally} disabled={state.status === 'VALIDATION_ERROR' || !state.summary || state.summary.blockingIssues > 0}>Valider les travaux</button></div>}
      {!state.file && <div className="mt-6"><EmptyState title="Aucun fichier sélectionné" message="Le brouillon sera perdu lors d’un rafraîchissement pendant cette phase." /></div>}
    </section>
  </>;
}

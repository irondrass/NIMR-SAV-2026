import type { SupabaseClient } from '@supabase/supabase-js';

export type ValidatedQuoteRowPayload = {
  quote_import_row_id: string;
  validation_version: number;
  payload_hash: string;
  normalized_label: string;
  operation_category: 'LABOR' | 'BODYWORK' | 'PAINT' | 'MECHANICAL' | 'ELECTRICAL' | 'DIAGNOSTIC' | 'OTHER';
  quantity: number;
  unit: 'unit' | 'hour' | 'day' | 'job';
  planned_duration_minutes: number;
  source_row_number: number;
  source_reference?: string | null;
  customer_display_name?: string | null;
  customer_external_reference?: string | null;
  vin?: string | null;
  registration_number?: string | null;
  make?: string | null;
  model?: string | null;
  variant?: string | null;
  mileage_km?: number | null;
  powertrain?: 'ICE' | 'HYBRID' | 'ELECTRIC' | 'OTHER' | null;
};

export type RepairOrderLineProjection = {
  line_order: number;
  source_import_row_id: string;
  source_row_number: number;
  description: string;
  operation_category: ValidatedQuoteRowPayload['operation_category'];
  quantity: number;
  unit: ValidatedQuoteRowPayload['unit'];
  planned_duration_minutes: number;
  source_reference: string | null;
  provenance: { payload_hash: string; validation_version: number };
};

export function projectValidatedQuoteRow(payload: ValidatedQuoteRowPayload): RepairOrderLineProjection {
  if (!payload.quote_import_row_id || !payload.payload_hash || !payload.normalized_label.trim()) throw new Error('Payload validé invalide.');
  if (!Number.isInteger(payload.source_row_number) || payload.source_row_number <= 0) throw new Error('Numéro de ligne source invalide.');
  if (!(payload.planned_duration_minutes > 0)) throw new Error('Durée prévue invalide.');
  return {
    line_order: payload.source_row_number,
    source_import_row_id: payload.quote_import_row_id,
    source_row_number: payload.source_row_number,
    description: payload.normalized_label.trim(),
    operation_category: payload.operation_category,
    quantity: payload.quantity,
    unit: payload.unit,
    planned_duration_minutes: payload.planned_duration_minutes,
    source_reference: payload.source_reference?.trim() || null,
    provenance: { payload_hash: payload.payload_hash, validation_version: payload.validation_version },
  };
}

export async function createDossierFromValidatedQuote(client: SupabaseClient, quoteImportRowId: string, acceptWarnings = false): Promise<string> {
  const { data, error } = await client.rpc('create_dossier_from_validated_quote', {
    p_quote_import_row_id: quoteImportRowId,
    p_accept_warnings: acceptWarnings,
  });
  if (error) throw error;
  return data as string;
}

import { describe, expect, it } from 'vitest';
import { projectValidatedQuoteRow } from './contracts';

const payload = {
  quote_import_row_id: '00000000-0000-4000-8000-000000000001', validation_version: 2, payload_hash: 'a'.repeat(64),
  normalized_label: 'Remplacement plaquettes de frein avant', operation_category: 'MECHANICAL' as const,
  quantity: 1, unit: 'job' as const, planned_duration_minutes: 60, source_row_number: 4, source_reference: 'OP-4',
};

describe('projection opérationnelle du devis', () => {
  it('projette uniquement les champs planifiables et conserve un ordre stable', () => {
    expect(projectValidatedQuoteRow(payload)).toEqual({
      line_order: 4, source_import_row_id: payload.quote_import_row_id, source_row_number: 4,
      description: 'Remplacement plaquettes de frein avant', operation_category: 'MECHANICAL', quantity: 1,
      unit: 'job', planned_duration_minutes: 60, source_reference: 'OP-4',
      provenance: { payload_hash: 'a'.repeat(64), validation_version: 2 },
    });
  });

  it('refuse une ligne sans description ou durée', () => {
    expect(() => projectValidatedQuoteRow({ ...payload, normalized_label: ' ' })).toThrow();
    expect(() => projectValidatedQuoteRow({ ...payload, planned_duration_minutes: 0 })).toThrow();
  });
});

import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';

const root = process.cwd();
const migrationsDir = join(root, 'supabase', 'migrations');
const expected = [
  '0001_extensions_and_helpers.sql', '0002_organizations_and_sites.sql',
  '0003_profiles_and_roles.sql', '0004_profile_site_access.sql',
  '0005_quote_import_foundation.sql', '0006_storage_and_attachments.sql',
  '0007_audit_foundation.sql', '0008_rls_policies.sql',
  '0009_quote_import_server_contract.sql', '0010_dossier_persistence.sql',
];
const forbidden = /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?(clients|vehicles|reception|appointments|parts|pdr|workshop_tasks|bookings|quality_controls|deliveries|invoices|payments|billing)\b/i;
const migrationText = (await Promise.all(expected.map((file) => readFile(join(migrationsDir, file), 'utf8')))).join('\n');
const foundationText = await readFile(join(root, 'supabase', 'tests', 'foundation.sql'), 'utf8');
const behaviorText = await readFile(join(root, 'supabase', 'tests', 'rls_behavior.sql'), 'utf8');
const dossierText = await readFile(join(root, 'supabase', 'tests', 'dossier_persistence.sql'), 'utf8');
const foundationPgtapSearchPath = 'set local search_path = extensions, public, storage, pg_catalog;';
const behaviorPgtapSearchPath = 'set local search_path = extensions, public, auth, storage, pg_catalog;';
const rlsBlock = migrationText.match(/foreach\s+t\s+in\s+array[\s\S]*?enable\s+row\s+level\s+security[\s\S]*?end\s+\$\$/i)?.[0] ?? '';
const checks = [];
const check = (name, condition) => checks.push({ name, condition });

check('migrations are complete and ordered', (await readdir(migrationsDir)).filter((file) => /^\d{4}_.*\.sql$/.test(file)).join('|') === expected.join('|'));
check('forbidden tables absent', !forbidden.test(migrationText));
check('RLS is declared for every application table', rlsBlock.includes('enable row level security') && ['organizations','sites','profiles','roles','profile_roles','profile_site_access','quote_import_operations','quote_import_rows','quote_mapping_templates','attachments','audit_events','quote_import_issue_catalog','quote_import_row_validated_payloads','quote_import_row_issues','dossiers','repair_orders','repair_order_lines','dossier_number_counters'].every((name) => migrationText.includes(`alter table public.${name} enable row level security`) || rlsBlock.includes(`'${name}'`)));
check('no authenticated DELETE grants', !/grant\s+[^;\n]*\bdelete\b[^;\n]*to\s+authenticated/i.test(migrationText));
check('no Storage DELETE policy', !/create\s+policy\s+[^;\n]*\bon\s+storage\.objects\s+for\s+delete/i.test(migrationText));
check('audit has no direct authenticated INSERT grant', !/grant\s+insert\s+on\s+public\.audit_events\s+to\s+authenticated/i.test(migrationText));
check('immutability protections exist', ['guard_quote_import_operation_update', 'guard_quote_import_row_update', 'guard_attachment_update', 'prevent_audit_mutation'].every((name) => migrationText.includes(name)));
check('behavioral pgTAP contract exists', foundationText.includes('select plan(69)') && foundationText.includes('can_create_quote_import'));
check('dossier pgTAP contract exists', dossierText.includes('select plan(22)') && dossierText.includes('create_dossier_from_validated_quote'));
check('foundation pgTAP search_path is explicit', foundationText.includes(foundationPgtapSearchPath));
check('behavioral pgTAP search_path is explicit', behaviorText.includes(behaviorPgtapSearchPath));
check('foundation pgTAP search_path appears once', (foundationText.match(/set local search_path\s*=\s*extensions, public, storage, pg_catalog;/gi) ?? []).length === 1);
check('behavioral pgTAP search_path appears once', (behaviorText.match(/set local search_path\s*=\s*extensions, public, auth, storage, pg_catalog;/gi) ?? []).length === 1);
check('behavioral pgTAP file exists', behaviorText.includes('select plan(') && behaviorText.includes('select * from finish()'));
check('behavioral pgTAP has one plan', (behaviorText.match(/select\s+plan\(/gi) ?? []).length === 1);
check('behavioral tests perform writes', /\b(insert|update|delete)\s+into?\b|\bupdate\b|\bdelete\b/i.test(behaviorText));
check('behavioral tests simulate authenticated role', behaviorText.includes('set local role authenticated'));
check('behavioral tests simulate anonymous role', behaviorText.includes('set local role anon'));
check('behavioral tests simulate auth uid', behaviorText.includes('request.jwt.claim.sub') && behaviorText.includes('auth.uid()'));
check('behavioral tests cover cross-site isolation', /site B|another site|cross-site|site_id = '00000000-0000-4000-8000-000000000201'/i.test(behaviorText));
check('behavioral tests cover cross-organization isolation', /organization B|another organization|organization_id = '00000000-0000-4000-8000-000000000002'/i.test(behaviorText));
check('behavioral tests cover audit', behaviorText.includes('append_audit_event') && behaviorText.includes('audit_events'));
check('behavioral tests cover Storage', behaviorText.includes('storage.objects') && behaviorText.includes('storage_path_has_expected_shape'));
const privilegedKeyPattern = new RegExp(['service', 'role'].join('[_-]'), 'i');
check('no server privilege key or secret patterns', !privilegedKeyPattern.test(migrationText));
check('no remote migration commands', !/supabase\s+(link|db\s+push|migration\s+up\s+--linked|functions\s+deploy)/i.test(migrationText));

const failed = checks.filter(({ condition }) => !condition);
for (const result of checks) console.log(`${result.condition ? 'PASS' : 'FAIL'} ${result.name}`);
if (failed.length) process.exit(1);
console.log(`Supabase foundation static check passed (${checks.length} checks).`);

import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';

const root = process.cwd();
const migrationsDir = join(root, 'supabase', 'migrations');
const expected = [
  '0001_extensions_and_helpers.sql', '0002_organizations_and_sites.sql',
  '0003_profiles_and_roles.sql', '0004_profile_site_access.sql',
  '0005_quote_import_foundation.sql', '0006_storage_and_attachments.sql',
  '0007_audit_foundation.sql', '0008_rls_policies.sql',
];
const forbidden = /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?(clients|vehicles|reception|appointments|parts|pdr|dossiers|repair_orders|repair_order_lines|workshop_tasks|bookings|quality_controls|deliveries)\b/i;
const migrationText = (await Promise.all(expected.map((file) => readFile(join(migrationsDir, file), 'utf8')))).join('\n');
const rlsBlock = migrationText.match(/foreach\s+t\s+in\s+array[\s\S]*?enable\s+row\s+level\s+security[\s\S]*?end\s+\$\$/i)?.[0] ?? '';
const checks = [];
const check = (name, condition) => checks.push({ name, condition });

check('migrations are complete and ordered', (await readdir(migrationsDir)).filter((file) => /^\d{4}_.*\.sql$/.test(file)).slice(0, expected.length).join('|') === expected.join('|'));
check('forbidden tables absent', !forbidden.test(migrationText));
check('RLS is declared for every application table', rlsBlock.includes('enable row level security') && ['organizations','sites','profiles','roles','profile_roles','profile_site_access','quote_import_operations','quote_import_rows','quote_mapping_templates','attachments','audit_events'].every((name) => rlsBlock.includes(`'${name}'`)));
check('no authenticated DELETE grants', !/grant\s+[^;\n]*\bdelete\b[^;\n]*to\s+authenticated/i.test(migrationText));
check('no Storage DELETE policy', !/create\s+policy\s+[^;\n]*\bon\s+storage\.objects\s+for\s+delete/i.test(migrationText));
check('audit has no direct authenticated INSERT grant', !/grant\s+insert\s+on\s+public\.audit_events\s+to\s+authenticated/i.test(migrationText));
check('immutability protections exist', ['guard_quote_import_operation_update', 'guard_quote_import_row_update', 'guard_attachment_update', 'prevent_audit_mutation'].every((name) => migrationText.includes(name)));
check('behavioral pgTAP contract exists', (await readFile(join(root, 'supabase', 'tests', 'foundation.sql'), 'utf8')).includes('select plan(67)') && (await readFile(join(root, 'supabase', 'tests', 'foundation.sql'), 'utf8')).includes('can_create_quote_import'));
const privilegedKeyPattern = new RegExp(['service', 'role'].join('[_-]'), 'i');
check('no server privilege key or secret patterns', !privilegedKeyPattern.test(migrationText));
check('no remote migration commands', !/supabase\s+(link|db\s+push|migration\s+up\s+--linked|functions\s+deploy)/i.test(migrationText));

const failed = checks.filter(({ condition }) => !condition);
for (const result of checks) console.log(`${result.condition ? 'PASS' : 'FAIL'} ${result.name}`);
if (failed.length) process.exit(1);
console.log(`Supabase foundation static check passed (${checks.length} checks).`);

import { spawn } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';
import { chromium } from '@playwright/test';
import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

const root = process.cwd();
const run = (command, args) => new Promise((resolve, reject) => { const child = spawn(command, args, { cwd: root, stdio: 'inherit', shell: true }); child.on('error', reject); child.on('exit', (code) => code === 0 ? resolve() : reject(new Error(`${command} exited with ${code}`))); });
async function waitFor(url) { for (let attempt = 0; attempt < 40; attempt += 1) { try { const response = await fetch(url); if (response.ok) return; } catch { /* server starting */ } await delay(250); } throw new Error(`Preview unavailable: ${url}`); }
async function files(dir) { const entries = await readdir(dir, { withFileTypes: true }); return (await Promise.all(entries.map((entry) => { const file = join(dir, entry.name); return entry.isDirectory() ? files(file) : [file]; }))).flat(); }
await run('npm.cmd', ['run', 'build']);
const distFiles = await files(join(root, 'dist')); const bundleText = (await Promise.all(distFiles.map((file) => readFile(file, 'utf8')))).join('\n');
for (const forbidden of ['VITE_ENABLE_E2E_AUTH', 'test-user', 'mock session']) if (bundleText.toLowerCase().includes(forbidden.toLowerCase())) throw new Error(`Production bundle contains forbidden E2E marker: ${forbidden}`);
const preview = spawn('npx.cmd', ['vite', 'preview', '--host', '127.0.0.1', '--port', '4173'], { cwd: root, stdio: 'ignore', shell: true });
try { await waitFor('http://127.0.0.1:4173'); const browser = await chromium.launch(); const page = await browser.newPage(); await page.goto('http://127.0.0.1:4173/quote-import?e2eAuth=1'); if (!(await page.getByRole('heading', { name: 'Supabase n’est pas configuré' }).isVisible())) throw new Error('Production preview exposed a non-authenticated page.'); if (await page.getByRole('heading', { name: 'Importer un devis' }).isVisible()) throw new Error('Production preview exposed the quote-import assistant.'); await browser.close(); console.log('Production auth bypass check passed.'); } finally { preview.kill(); }

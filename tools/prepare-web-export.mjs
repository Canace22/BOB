// Explicit production resources; local demos and legacy frames stay editable.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
execFileSync(process.execPath, ['game/tools/audit_resources.mjs', '--release'], {cwd:root, stdio:'pipe'});
const inventory = JSON.parse(fs.readFileSync(path.join(root, 'game/build/qa/package-audit/release-resources.json'), 'utf8'));
if (inventory.missing.length) throw new Error('Production dependencies are missing');
const resources = inventory.reachable.filter(file => /\.(tscn|tres|gd|gdshader|png|svg|wav|ogg|ttf)$/.test(file));
const data = inventory.reachable.filter(file => /\.(json|txt)$/.test(file));
const preset = path.join(root, 'game/export_presets.cfg');
let text = fs.readFileSync(preset, 'utf8');
text = text.replace(/^export_filter=.*$/m, 'export_filter="resources"');
text = text.replace(/^export_files=.*\r?\n/m, '');
text = text.replace(/^export_filter=.*$/m, match => match + '\nexport_files=PackedStringArray(' + resources.map(file => JSON.stringify('res://' + file)).join(', ') + ')');
text = text.replace(/^include_filter=.*$/m, 'include_filter=' + JSON.stringify(data.join(',')));
fs.writeFileSync(preset, text);
console.log(`Web production selection: ${resources.length} resources and ${data.length} data files`);

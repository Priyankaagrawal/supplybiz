import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

// Upstream Markdown templates leave trailing spaces on optional parameter rows.
// Normalize generated docs here so regeneration is reproducible and whitespace-clean.
const directory = fileURLToPath(new URL('../packages/api_client/doc/', import.meta.url));
for (const name of readdirSync(directory).filter(name => name.endsWith('.md'))) {
  const path = `${directory}${name}`;
  writeFileSync(path, readFileSync(path, 'utf8').replace(/[\t ]+$/gm, ''));
}

const readme = fileURLToPath(new URL('../packages/api_client/README.md', import.meta.url));
writeFileSync(readme, readFileSync(readme, 'utf8').replace(/[\t ]+$/gm, ''));

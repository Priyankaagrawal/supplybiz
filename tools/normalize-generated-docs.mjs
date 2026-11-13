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

// dart-dio imports typed error responses but only deserializes success responses.
// Remove unused model imports deterministically at generation time, retaining the
// exported error models for callers to decode DioException.response.data.
const apiDirectory = fileURLToPath(new URL('../packages/api_client/lib/src/api/', import.meta.url));
for (const name of readdirSync(apiDirectory).filter(name => name.endsWith('_api.dart'))) {
  const path = `${apiDirectory}${name}`, source = readFileSync(path, 'utf8');
  const bodyStart = source.indexOf('class ');
  if (bodyStart < 0) continue;
  const body = source.slice(bodyStart);
  const normalized = source.replace(/^import 'package:supplybiz_api_client\/src\/model\/([a-z0-9_]+)\.dart';\r?\n/gm, (line, fileName) => {
    const type = fileName.replace(/(?:^|_)([a-z])/g, (_, letter) => letter.toUpperCase());
    return new RegExp(`\\b${type}\\b`).test(body) ? line : '';
  });
  writeFileSync(path, normalized);
}

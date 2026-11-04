import js from '@eslint/js';
import tseslint from 'typescript-eslint';
export default tseslint.config(
 { ignores: ['.next/**', 'node_modules/**', 'next-env.d.ts'] },
 js.configs.recommended, ...tseslint.configs.recommended,
 { files: ['**/*.ts', '**/*.tsx'], languageOptions: { parserOptions: { project: './tsconfig.json', tsconfigRootDir: import.meta.dirname } },
 rules: { '@typescript-eslint/no-floating-promises': 'error', '@typescript-eslint/no-misused-promises': 'error' } },
);

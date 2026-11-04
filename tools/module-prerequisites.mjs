const range = (from, to) => Array.from({ length: to - from + 1 }, (_, i) => `T-${String(from + i).padStart(3, '0')}`);
export const required = {
  G0: [...range(1, 16), ...range(180, 184)],
  G1: [...range(20, 29), 'T-084', ...range(150, 153), 'T-103', 'T-156'],
  G2: ['T-032', 'T-033', ...range(40, 53), 'T-070', 'T-071'],
  G3: range(72, 83),
  G4: ['T-019', 'T-030', 'T-031', ...range(100, 103), ...range(105, 107), 'T-126',
    ...range(154, 156), 'T-158', 'T-161', 'T-162'],
  G5: ['T-017', 'T-018', 'T-122'],
  G6: [...range(170, 173), ...range(175, 178)],
};

export function missingPrerequisites(gate, register) {
  const missing = required[gate].filter(id => {
    const row = register.split('\n').find(line => line.startsWith(`| ${id} |`));
    return row?.split('|').at(-2)?.trim() !== 'DONE';
  });
  const previous = Number(gate.slice(1)) - 1;
  if (previous >= 0 && !new RegExp(`^\\| G${previous}[^|]*\\| PASS \\|`, 'm').test(register)) {
    missing.push(`G${previous} PASS`);
  }
  return missing;
}

#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const [, , reportPathArg] = process.argv;

if (!reportPathArg) {
  console.error('Usage: node Scripts/print_ingest_report.mjs <report-path>');
  process.exit(1);
}

const reportPath = path.resolve(reportPathArg);

if (!fs.existsSync(reportPath)) {
  console.error(`Report not found at ${reportPath}`);
  process.exit(1);
}

let data;
try {
  data = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
} catch (error) {
  console.error(`Failed to parse report: ${error.message}`);
  process.exit(1);
}

const rows = data.report?.moved ?? [];

if (!rows.length) {
  console.log('No files were moved during ingest.');
  process.exit(0);
}

const headers = ['SRC', 'ARCHIVE', 'TARGET'];
const table = [
  headers,
  ...rows.map((row) => [
    row.src ?? '',
    row.archive ?? '',
    row.target ?? ''
  ])
];

const widths = headers.map((_, columnIndex) =>
  Math.max(
    ...table.map((row) => String(row[columnIndex] ?? '').length)
  )
);

const separator = widths.map((width) => '-'.repeat(width)).join('  ');

const formatted = table.map((row, rowIndex) =>
  row
    .map((cell, columnIndex) => {
      const text = String(cell ?? '');
      return text.padEnd(widths[columnIndex], ' ');
    })
    .join('  ')
);

console.log(formatted[0]);
console.log(separator);
for (const line of formatted.slice(1)) {
  console.log(line);
}



const fs = require('fs');
const code = fs.readFileSync('preload.rb', 'utf-8');
const lines = code.split('\n');

console.log('Total lines in preload.rb:', lines.length);

// Let's test eval line-by-line or chunk-by-chunk to find the unclosed block
// In Ruby syntax:
// Keywords that increment indent: class, module, def, if, unless, case, while, until, for, begin, do
// Keywords that decrement indent: end

const stack = [];
for (let i = 0; i < lines.length; i++) {
  let line = lines[i].replace(/#.*$/, '').trim();
  if (!line) continue;

  // Split by semicolons
  const parts = line.split(';').map(p => p.trim()).filter(Boolean);
  for (const p of parts) {
    // Check for single line: def ...; ...; end
    if (/^def\s+.*?\bend(\s+(?:if|unless|rescue)\b.*)?$/.test(p)) continue;
    if (/^(class|module)\s+.*?\bend$/.test(p)) continue;

    const words = p.split(/\s+/);
    const kw = words[0];

    if (['class', 'module', 'case', 'begin'].includes(kw)) {
      stack.push({ line: i + 1, kw, text: p });
    } else if (kw === 'def') {
      stack.push({ line: i + 1, kw, text: p });
    } else if (['if', 'unless', 'while', 'until', 'for'].includes(kw)) {
      // Check if it's a modifier: e.g. return if true
      // Here kw is the FIRST word, so it's a statement opening a block unless it has 'then ... end'
      if (!/\bend\b/.test(p)) {
        stack.push({ line: i + 1, kw, text: p });
      }
    } else if (/\bdo\b(\s*\|[^|]*\|)?\s*$/.test(p)) {
      stack.push({ line: i + 1, kw: 'do', text: p });
    }

    if (words.includes('end')) {
      // For each 'end' word that is a standalone token
      const countEnd = words.filter(w => w === 'end').length;
      for (let c = 0; c < countEnd; c++) {
        if (stack.length > 0) {
          stack.pop();
        } else {
          console.log('Extra end at line', i + 1, p);
        }
      }
    }
  }
}

console.log('Unclosed stack count:', stack.length);
stack.forEach(s => console.log('Line ' + s.line + ' (' + s.kw + '): ' + s.text));

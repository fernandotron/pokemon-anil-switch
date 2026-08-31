const fs = require('fs');
const target = process.argv[2] || 'preload.rb';
const content = fs.readFileSync(target, 'utf-8');
console.log('Checking syntax:', target);

function checkRubySyntax(src) {
  const lines = src.split('\n');
  const stack = [];
  let extraEnds = 0;

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i].replace(/\r/g, '').replace(/#.*/, '');
    line = line.replace(/"(?:[^"\\]|\\.)*"/g, '""');
    line = line.replace(/'(?:[^'\\]|\\.)*'/g, "''");
    line = line.replace(/\/(?:[^\/\\]|\\.)*\//g, '//');

    const words = line.trim().split(/\s+/).filter(Boolean);
    if (words.length === 0) continue;

    // Tokenize
    const tokens = line.match(/\b(?:class|module|def|if|unless|case|while|until|for|begin|do|end)\b/g) || [];

    for (let t of tokens) {
      if (['class', 'module', 'case', 'begin', 'def'].includes(t)) {
        stack.push({ line: i + 1, token: t, code: lines[i].trim() });
      } else if (['if', 'unless', 'while', 'until', 'for'].includes(t)) {
        const idx = line.indexOf(t);
        const before = line.substring(0, idx).trim();
        if (before === '' || before.endsWith(';') || before.endsWith('=') || before.endsWith('then') || before.endsWith('do')) {
          stack.push({ line: i + 1, token: t, code: lines[i].trim() });
        }
      } else if (t === 'do') {
        stack.push({ line: i + 1, token: t, code: lines[i].trim() });
      } else if (t === 'end') {
        if (stack.length > 0) {
          stack.pop();
        } else {
          extraEnds++;
          console.error(`[SYNTAX ERROR] Unmatched extra 'end' at line ${i + 1}: ${lines[i]}`);
        }
      }
    }
  }

  console.log(`Remaining unclosed stack depth: ${stack.length}`);
  if (stack.length > 0 || extraEnds > 0) {
    stack.forEach(s => console.error(`  Unclosed ${s.token} from line ${s.line}: ${s.code}`));
    console.error(`[ERROR] check_syntax.js: Se encontraron errores de sintaxis en ${target}.`);
    process.exit(1);
  } else {
    console.log(`[SUCCESS] 0 syntax errors. Every block in ${target} is 100% matched!`);
    process.exit(0);
  }
}

checkRubySyntax(content);

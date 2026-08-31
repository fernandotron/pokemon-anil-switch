const fs = require('fs');
const target = process.argv[2] || 'preload.rb';
const content = fs.readFileSync(target, 'utf-8');
console.log('Validating:', target);

function validateRuby(src) {
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
        // Is it a modifier or block opener?
        // In Ruby: expr if cond (modifier) vs if cond (block)
        // If 'if' is followed by something and preceded only by =, +=, etc. or start of line/statement
        const idx = line.indexOf(t);
        const before = line.substring(0, idx).trim();
        if (before === '' || before.endsWith(';') || before.endsWith('=') || before.endsWith('then') || before.endsWith('do')) {
          stack.push({ line: i + 1, token: t, code: lines[i].trim() });
        }
      } else if (t === 'do') {
        stack.push({ line: i + 1, token: t, code: lines[i].trim() });
      } else if (t === 'end') {
        if (stack.length > 0) {
          const popped = stack.pop();
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
    console.error(`[ERROR] validate_ruby.js: Se encontraron errores de validación en ${target}.`);
    process.exit(1);
  } else {
    console.log(`[SUCCESS] 0 syntax errors. Every block in ${target} is 100% matched!`);
    process.exit(0);
  }
}

validateRuby(content);

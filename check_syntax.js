const fs = require('fs');
const content = fs.readFileSync('preload.rb', 'utf-8');

// Accurate Ruby lexer / block parser
function checkRubySyntax(code) {
  const lines = code.split('\n');
  const stack = [];

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    // Remove comments
    line = line.replace(/#.*$/, '');
    // Strip strings
    line = line.replace(/\"(?:[^\"\\]|\\.)*\"/g, '""');
    line = line.replace(/\'(?:[^\'\\]|\\.)*\'/g, "''");
    line = line.replace(/:(?:\w+|[^\s]+)/g, ''); // strip symbols
    
    // Normalize semicolons as linebreaks
    const sublines = line.split(';');
    for (let part of sublines) {
      part = part.trim();
      if (!part) continue;

      // Handle single-line definitions
      if (/^def\s+.*?\bend(\s+(?:if|unless|rescue)\b.*)?$/.test(part)) continue;
      if (/^(?:class|module)\s+.*?\bend$/.test(part)) continue;

      const words = part.split(/\s+/);
      const first = words[0];

      if (['class', 'module', 'case', 'begin'].includes(first)) {
        stack.push({ line: i + 1, type: first, text: part });
      } else if (first === 'def') {
        stack.push({ line: i + 1, type: 'def', text: part });
      } else if (['if', 'unless', 'while', 'until', 'for'].includes(first)) {
        stack.push({ line: i + 1, type: first, text: part });
      } else if (/\bdo\b(\s*\|[^|]*\|)?\s*$/.test(part)) {
        stack.push({ line: i + 1, type: 'do', text: part });
      }

      if (first === 'end' || words[words.length - 1] === 'end') {
        if (stack.length > 0) {
          const popped = stack.pop();
        } else {
          console.error('EXTRA end at line ' + (i + 1) + ': ' + part);
        }
      }
    }
  }

  console.log('Final stack count:', stack.length);
  stack.forEach(s => console.log('Unclosed ' + s.type + ' at line ' + s.line + ': ' + s.text));
}

checkRubySyntax(content);

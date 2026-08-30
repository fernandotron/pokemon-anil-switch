const fs = require('fs');
const zlib = require('zlib');
const buf = fs.readFileSync('Data/Scripts.rxdata.bak');
let pos = 2;

function readByte() { return buf[pos++]; }
function readFixnum() {
  const b = buf[pos++];
  if (b === 0) return 0;
  if (b > 0 && b <= 4) {
    let val = 0;
    for (let i = 0; i < b; i++) val |= buf[pos++] << (i * 8);
    return val;
  }
  if (b >= 5 && b <= 127) return b - 5;
  if (b >= 252) {
    const count = 256 - b;
    let val = 0;
    for (let i = 0; i < count; i++) val |= buf[pos++] << (i * 8);
    return -(~val + 1);
  }
  if (b >= 128) return b - 251;
  return b;
}

function readString() {
  const t = readByte();
  if (t === 0x49) {
    const rawStr = readString();
    const ivarCount = readFixnum();
    for (let i = 0; i < ivarCount; i++) {
      readObject();
      readObject();
    }
    return rawStr;
  } else if (t === 0x22) {
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len);
    pos += len;
    return s;
  } else if (t === 0x3a) {
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len).toString('utf-8');
    pos += len;
    return s;
  } else if (t === 0x3b) {
    return 'sym_' + readFixnum();
  }
}

function readObject() {
  const t = readByte();
  if (t === 0x69) return readFixnum();
  if (t === 0x54) return true;
  if (t === 0x46) return false;
  if (t === 0x30) return null;
  if (t === 0x3a) {
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len).toString('utf-8');
    pos += len;
    return s;
  } else if (t === 0x3b) return 'sym_link_' + readFixnum();
  if (t === 0x22) {
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len);
    pos += len;
    return s;
  } else if (t === 0x49) {
    pos--;
    return readString();
  } else if (t === 0x5b) {
    const len = readFixnum();
    const arr = [];
    for (let i = 0; i < len; i++) arr.push(readObject());
    return arr;
  }
}

const rootType = readByte();
const numScripts = readFixnum();
for (let s = 0; s < numScripts; s++) {
  const arrType = readByte();
  const arrLen = readFixnum();
  const idObj = readObject();
  const nameObj = readObject();
  const name = Buffer.isBuffer(nameObj) ? nameObj.toString('utf-8') : String(nameObj);
  const codeObj = readObject();
  const codeBuf = Buffer.isBuffer(codeObj) ? codeObj : Buffer.from(codeObj);
  let code = '';
  try { code = zlib.inflateSync(codeBuf).toString('utf-8'); } catch(e) {
    try { code = zlib.inflateSync(codeBuf).toString('latin1'); } catch(e2){}
  }
  if (name.includes('MKXP') || s === 6 || s === 5) {
    console.log(`=== Script #${s}: ${name} ===`);
    console.log(code);
  }
}

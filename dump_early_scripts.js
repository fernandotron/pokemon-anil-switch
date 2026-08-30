const fs = require('fs');
const zlib = require('zlib');
const buf = fs.readFileSync('Data/Scripts.rxdata.bak');
let pos = 2;
function readByte() { return buf[pos++]; }
function readFixnum() {
  const b = buf[pos++];
  if (b === 0) return 0;
  if (b > 0 && b < 128) {
    let res = 0;
    for (let i = 0; i < b; i++) res |= (buf[pos++] << (i * 8));
    return res;
  }
  if (b > 127) {
    const len = 256 - b;
    let res = 0;
    for (let i = 0; i < len; i++) res |= (buf[pos++] << (i * 8));
    return res;
  }
}
function readString() {
  const t = readByte();
  if (t === 0x22) {
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len);
    pos += len;
    return s;
  } else if (t === 0x49) {
    const s = readString();
    const numIv = readFixnum();
    for (let i = 0; i < numIv; i++) {
      readObject();
      readObject();
    }
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

readByte();
const numScripts = readFixnum();
for (let s = 0; s < numScripts; s++) {
  readByte();
  readFixnum();
  const id = readObject();
  const nameObj = readObject();
  const name = Buffer.isBuffer(nameObj) ? nameObj.toString('utf-8') : String(nameObj);
  const codeObj = readObject();
  const codeBuf = Buffer.isBuffer(codeObj) ? codeObj : Buffer.from(codeObj);
  let decompressed = '';
  try { decompressed = zlib.inflateSync(codeBuf).toString('utf-8'); } catch (e) {
    try { decompressed = zlib.inflateSync(codeBuf).toString('latin1'); } catch (e2) {}
  }
  if (s < 10 || name.includes('MKXP')) {
    console.log(`=== Script #${s}: ${name} ===`);
    console.log(decompressed);
    console.log('==============================\n');
  }
}

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const sourceFile = fs.existsSync('Data/Scripts.rxdata.bak') ? 'Data/Scripts.rxdata.bak' : 'Data/Scripts.rxdata';
const buf = fs.readFileSync(sourceFile);
console.log('Reading ' + sourceFile + ' (' + buf.length + ' bytes)');

let pos = 0;

function readByte() {
  return buf[pos++];
}

function readFixnum() {
  const b = buf[pos++];
  if (b === 0) return 0;
  if (b > 0 && b <= 4) {
    let val = 0;
    for (let i = 0; i < b; i++) {
      val |= buf[pos++] << (i * 8);
    }
    return val;
  }
  if (b >= 5 && b <= 127) {
    return b - 5;
  }
  if (b >= 252) {
    const count = 256 - b;
    let val = 0;
    for (let i = 0; i < count; i++) {
      val |= buf[pos++] << (i * 8);
    }
    return -(~val + 1);
  }
  if (b >= 128) {
    return b - 251;
  }
  return b;
}

function writeFixnum(n) {
  if (n === 0) return Buffer.from([0]);
  if (n > 0 && n < 123) return Buffer.from([n + 5]);
  if (n >= 123 && n <= 0xff) return Buffer.from([1, n & 0xff]);
  if (n > 0xff && n <= 0xffff) return Buffer.from([2, n & 0xff, (n >> 8) & 0xff]);
  if (n > 0xffff && n <= 0xffffff) return Buffer.from([3, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff]);
  return Buffer.from([4, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff]);
}

function readString() {
  const t = readByte();
  if (t === 0x49) { // 'I' wrapped object (e.g. String with encoding)
    const rawStr = readString();
    const ivarCount = readFixnum();
    for (let i = 0; i < ivarCount; i++) {
      readObject(); // ivar symbol
      readObject(); // ivar value
    }
    return rawStr;
  } else if (t === 0x22) { // '"' String
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len);
    pos += len;
    return s;
  } else if (t === 0x3a) { // ':' Symbol
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len).toString('utf-8');
    pos += len;
    return s;
  } else if (t === 0x3b) { // ';' Symbol link
    const index = readFixnum();
    return 'sym_' + index;
  } else {
    throw new Error('Unsupported string type 0x' + t.toString(16) + ' at offset ' + (pos - 1));
  }
}

function readObject() {
  const t = readByte();
  if (t === 0x69) { // Fixnum
    return readFixnum();
  } else if (t === 0x54) { // true
    return true;
  } else if (t === 0x46) { // false
    return false;
  } else if (t === 0x30) { // nil
    return null;
  } else if (t === 0x3a) { // Symbol
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len).toString('utf-8');
    pos += len;
    return s;
  } else if (t === 0x3b) { // Symbol link
    return 'sym_link_' + readFixnum();
  } else if (t === 0x22) { // String
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len);
    pos += len;
    return s;
  } else if (t === 0x49) { // 'I'
    pos--;
    return readString();
  } else if (t === 0x5b) { // Array
    const len = readFixnum();
    const arr = [];
    for (let i = 0; i < len; i++) {
      arr.push(readObject());
    }
    return arr;
  } else {
    throw new Error('Unknown object type 0x' + t.toString(16) + ' at offset ' + (pos - 1));
  }
}

if (buf[0] !== 0x04 || buf[1] !== 0x08) {
  throw new Error('Not a valid Ruby Marshal file');
}
pos = 2;

const rootType = readByte();
if (rootType !== 0x5b) throw new Error('Expected Array');
const numScripts = readFixnum();
console.log('Number of scripts:', numScripts);

const scripts = [];

for (let s = 0; s < numScripts; s++) {
  const arrType = readByte(); // '['
  if (arrType !== 0x5b) throw new Error('Expected inner array at script ' + s + ' at pos ' + (pos - 1) + ' got 0x' + arrType.toString(16));
  const arrLen = readFixnum();
  
  // ID
  const idObj = readObject();
  
  // Name
  const nameObj = readObject();
  const nameStr = Buffer.isBuffer(nameObj) ? nameObj.toString('utf-8') : String(nameObj);
  
  // Code (Zlib compressed string)
  const codeObj = readObject();
  const codeBuf = Buffer.isBuffer(codeObj) ? codeObj : Buffer.from(codeObj);
  
  let decompressed = '';
  try {
    decompressed = zlib.inflateSync(codeBuf).toString('utf-8');
  } catch (e) {
    decompressed = '';
  }
  
  scripts.push({ id: idObj, name: nameStr, code: decompressed });
}

console.log('Successfully decoded all', scripts.length, 'scripts!');

// Sync modified and missing scripts from Data/Scripts directory on disk
function syncFromDisk(dir) {
  if (!fs.existsSync(dir)) return;
  let maxId = scripts.reduce((max, s) => Math.max(max, s.id || 0), 0);
  
  // 1. If 000_UI_base.rb exists, assign it to [[ UI ]] (or insert before UI_PauseMenu)
  const uiBaseFile = 'Data/Scripts/048_UI/000_UI_base.rb';
  if (fs.existsSync(uiBaseFile)) {
    const uiCode = fs.readFileSync(uiBaseFile, 'utf-8');
    const uiHeaderIdx = scripts.findIndex(s => s.name === '[[ UI ]]');
    if (uiHeaderIdx >= 0) {
      console.log('  -> Assigning 000_UI_base.rb to [[ UI ]]');
      scripts[uiHeaderIdx].name = 'UI_base';
      scripts[uiHeaderIdx].code = uiCode;
    } else {
      const pauseIdx = scripts.findIndex(s => s.name === 'UI_PauseMenu');
      if (pauseIdx >= 0) {
        console.log('  -> Inserting UI_base before UI_PauseMenu');
        scripts.splice(pauseIdx, 0, { id: ++maxId, name: 'UI_base', code: uiCode });
      }
    }
  }

  // 2. Scan all scripts and update matching or insert unmatched
  function scan(currentDir) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        scan(fullPath);
      } else if (entry.isFile() && entry.name.endsWith('.rb')) {
        if (entry.name === '000_UI_base.rb') continue; // Handled above
        const baseName = entry.name.replace(/^\d+_/, '').replace(/\.rb$/, '');
        const rawCode = fs.readFileSync(fullPath, 'utf-8');
        const targetScript = scripts.find(s => s.name === baseName || s.name === entry.name.replace(/\.rb$/, '') || s.name === entry.name);
        if (targetScript) {
          console.log(`  -> Updating script from disk: ${fullPath} => ${targetScript.name}`);
          targetScript.code = rawCode;
        } else {
          // Insert unmatched scripts into appropriate locations
          if (fullPath.includes('001_Settings')) {
            const extraIdx = scripts.findIndex(s => s.name === 'Settings_Extra_Base');
            const insertIdx = extraIdx >= 0 ? extraIdx + 1 : 1;
            console.log(`  -> Inserting Settings script: ${entry.name} at index ${insertIdx}`);
            scripts.splice(insertIdx, 0, { id: ++maxId, name: baseName, code: rawCode });
          } else if (fullPath.includes('067_Scripts de la base')) {
            const incIdx = scripts.findIndex(s => s.name === 'Incubadora');
            const insertIdx = incIdx >= 0 ? incIdx + 1 : scripts.length - 1;
            console.log(`  -> Inserting Base script: ${entry.name} at index ${insertIdx}`);
            scripts.splice(insertIdx, 0, { id: ++maxId, name: baseName, code: rawCode });
          }
        }
      }
    }
  }
  scan(dir);
}
syncFromDisk('Data/Scripts');

// Universal sanitizer for ANY reopened class with < Superclass
const definedClasses = new Set([
  'Rect', 'Color', 'Tone', 'File', 'Dir', 'FileTest',
  'Bitmap', 'Sprite', 'Viewport', 'Plane', 'Window',
  'Tilemap', 'Table', 'Font', 'Audio', 'Input', 'Graphics',
  'Numeric', 'Fixnum', 'Integer', 'Float', 'String', 'Array', 'Hash',
  'GameStats', 'Game_Temp', 'PokemonSystem', 'PokemonBoxArrow'
]);

for (let s of scripts) {
  s.code = s.code.replace(/\r\n/g, '\n');
  s.code = s.code.replace(/class\s+([A-Za-z0-9_:]+)\s*<\s*([A-Za-z0-9_:]+)/g, (match, cls, superCls) => {
    const simpleName = cls.split('::').pop();
    if (definedClasses.has(cls) || definedClasses.has(simpleName)) {
      console.log(`Sanitizing reopened class in ${s.name}: ${match} -> class ${cls}`);
      return 'class ' + cls;
    }
    definedClasses.add(cls);
    definedClasses.add(simpleName);
    return match;
  });
}

let patchedCount = 0;
for (let s of scripts) {
  let changed = false;
  
  if (s.code.includes('def pbSetResizeFactor')) {
    console.log('Patching pbSetResizeFactor in:', s.name);
    s.code = s.code.replace(/def pbSetResizeFactor[\s\S]*?\bend\b/m, `def pbSetResizeFactor(factor = 0)
  Graphics.fixed_aspect_ratio = (factor == 1) rescue nil
  Graphics.integer_scaling = false rescue nil
  Graphics.smooth_scaling = 3 rescue nil
  Graphics.fullscreen = true rescue nil
  Graphics.center rescue nil
end`);
    changed = true;
  }
  
  if (s.code.includes('update_KGC_ScreenCapture')) {
    console.log('Patching update_KGC_ScreenCapture in:', s.name);
    s.code = s.code.replace(/class\s*<<\s*Input[\s\S]*?alias\s*update_KGC_ScreenCapture\s*update[\s\S]*?end/g, 'class << Input; alias update_KGC_ScreenCapture update unless method_defined?(:update_KGC_ScreenCapture); end');
    changed = true;
  }
  
  if (s.name.includes('MKXP_Compatibility') || s.code.includes('mkxp_draw_text')) {
    console.log('Patching MKXP_Compatibility in:', s.name);
    s.code = `# MKXP Compatibility for Nintendo Switch
$VERBOSE = nil
Encoding.default_internal = Encoding::UTF_8 rescue nil
Encoding.default_external = Encoding::UTF_8 rescue nil

module Kernel
  def max_party_size
    return Settings::MAX_PARTY_SIZE rescue 6 if !defined?(ChallengeModes) || !defined?(ChallengeModes.on?) || !ChallengeModes.on?(:PERMALOCKE)
    if defined?($PokemonGlobal) && $PokemonGlobal
      $PokemonGlobal.max_party_size ||= (Settings::MAX_PARTY_SIZE rescue 6)
      return $PokemonGlobal.max_party_size
    end
    return (Settings::MAX_PARTY_SIZE rescue 6)
  end
  module_function :max_party_size
end

class Module
  def max_party_size
    Kernel.max_party_size
  end
end

class Object
  def max_party_size
    Kernel.max_party_size
  end
end

def pbSetWindowText(string = "")
end

class ::Color
  def self.white; Color.new(255, 255, 255); end
  def self.black; Color.new(0, 0, 0); end
end

module ::System
  @start_time ||= (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f)

  def self.uptime
    if defined?(Process::CLOCK_MONOTONIC)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
    else
      Time.now.to_f - @start_time
    end
  rescue
    0.0
  end

  def self.real_uptime
    uptime
  end

  def self.unscaled_uptime
    uptime
  end

  def self.delta
    uptime
  end

  def self.data_directory
    "."
  end

  def self.user_directory
    "."
  end

  def self.set_window_title(title = "")
  end

  def self.window_title
    "Pokemon Anil"
  end

  def self.window_title=(title)
  end

  def self.platform
    "Switch"
  end

  def self.is_mac?; false; end
  def self.is_rosetta?; false; end
  def self.is_linux?; false; end
  def self.is_windows?; false; end
  def self.is_wine?; false; end
  def self.is_switch?; true; end

  def self.user_language
    "es"
  end

  def self.user_name
    "Trainer"
  end

  def self.game_title
    "Pokemon Anil"
  end

  def self.power_state
    {}
  end
end

module ::FileTest
  def self.exist?(filename)
    File.exist?(filename.to_s)
  end
  def self.exists?(filename)
    File.exist?(filename.to_s)
  end
  def self.file?(filename)
    File.file?(filename.to_s)
  end
  def self.directory?(filename)
    File.directory?(filename.to_s)
  end
  def self.readable?(filename)
    File.readable?(filename.to_s)
  end
  def self.size(filename)
    File.size(filename.to_s) rescue 0
  end
  def self.zero?(filename)
    File.zero?(filename.to_s) rescue true
  end
end

module Kernel
  System = ::System unless const_defined?(:System) rescue nil
  FileTest = ::FileTest unless const_defined?(:FileTest) rescue nil
  RPG = ::RPG unless const_defined?(:RPG) rescue nil
end

unless defined?(::SWITCH_CORE_RGSS_PATCHED)
::SWITCH_CORE_RGSS_PATCHED = true

class ::Tone
  unless method_defined?(:__switch_native_tone_init)
    alias __switch_native_tone_init initialize rescue nil
    def initialize(*args)
      if args.length == 3
        __switch_native_tone_init(args[0].to_f, args[1].to_f, args[2].to_f, 0.0)
      elsif args.length == 0
        __switch_native_tone_init(0.0, 0.0, 0.0, 0.0)
      elsif args.length == 1 && args[0].is_a?(Tone)
        __switch_native_tone_init(args[0].red, args[0].green, args[0].blue, args[0].gray)
      elsif args.length >= 4
        __switch_native_tone_init(args[0].to_f, args[1].to_f, args[2].to_f, args[3].to_f)
      else
        __switch_native_tone_init(0.0, 0.0, 0.0, 0.0)
      end
    end
  end
  unless method_defined?(:__switch_native_tone_set)
    alias __switch_native_tone_set set rescue nil
    def set(*args)
      if args.length == 3
        __switch_native_tone_set(args[0].to_f, args[1].to_f, args[2].to_f, 0.0)
      elsif args.length == 0
        __switch_native_tone_set(0.0, 0.0, 0.0, 0.0)
      elsif args.length == 1 && args[0].is_a?(Tone)
        __switch_native_tone_set(args[0].red, args[0].green, args[0].blue, args[0].gray)
      elsif args.length >= 4
        __switch_native_tone_set(args[0].to_f, args[1].to_f, args[2].to_f, args[3].to_f)
      else
        __switch_native_tone_set(0.0, 0.0, 0.0, 0.0)
      end
    end
  end
end

class << ::Tone
  unless method_defined?(:__switch_native_tone_new)
    alias __switch_native_tone_new new
    def new(*args)
      if self == ::Tone
        if args.length == 3
          __switch_native_tone_new(args[0].to_f, args[1].to_f, args[2].to_f, 0.0)
        elsif args.length == 0
          __switch_native_tone_new(0.0, 0.0, 0.0, 0.0)
        elsif args.length == 1 && args[0].is_a?(Tone)
          __switch_native_tone_new(args[0].red, args[0].green, args[0].blue, args[0].gray)
        elsif args.length >= 4
          __switch_native_tone_new(args[0].to_f, args[1].to_f, args[2].to_f, args[3].to_f)
        else
          __switch_native_tone_new(0.0, 0.0, 0.0, 0.0)
        end
      else
        super(*args)
      end
    end
  end
end

class ::Color
  unless method_defined?(:__switch_native_color_init)
    alias __switch_native_color_init initialize rescue nil
    def initialize(*args)
      if args.length == 3
        __switch_native_color_init(args[0].to_f, args[1].to_f, args[2].to_f, 255.0)
      elsif args.length == 0
        __switch_native_color_init(0.0, 0.0, 0.0, 255.0)
      elsif args.length == 1 && args[0].is_a?(Color)
        __switch_native_color_init(args[0].red, args[0].green, args[0].blue, args[0].alpha)
      elsif args.length >= 4
        __switch_native_color_init(args[0].to_f, args[1].to_f, args[2].to_f, args[3].to_f)
      else
        __switch_native_color_init(0.0, 0.0, 0.0, 255.0)
      end
    end
  end
  unless method_defined?(:__switch_native_color_set)
    alias __switch_native_color_set set rescue nil
    def set(*args)
      if args.length == 3
        __switch_native_color_set(args[0].to_f, args[1].to_f, args[2].to_f, 255.0)
      elsif args.length == 0
        __switch_native_color_set(0.0, 0.0, 0.0, 255.0)
      elsif args.length == 1 && args[0].is_a?(Color)
        __switch_native_color_set(args[0].red, args[0].green, args[0].blue, args[0].alpha)
      elsif args.length >= 4
        __switch_native_color_set(args[0].to_f, args[1].to_f, args[2].to_f, args[3].to_f)
      else
        __switch_native_color_set(0.0, 0.0, 0.0, 255.0)
      end
    end
  end
end

class << ::Color
  unless method_defined?(:__switch_native_color_new)
    alias __switch_native_color_new new
    def new(*args)
      if self == ::Color
        if args.length == 3
          __switch_native_color_new(args[0].to_f, args[1].to_f, args[2].to_f, 255.0)
        elsif args.length == 0
          __switch_native_color_new(0.0, 0.0, 0.0, 255.0)
        elsif args.length == 1
          val = args.first
          if val.is_a?(Color)
            __switch_native_color_new(val.red, val.green, val.blue, val.alpha)
          elsif val.is_a?(String)
            hex = val.delete("#")
            __switch_native_color_new(hex[0...2].to_i(16), hex[2...4].to_i(16), hex[4...6].to_i(16), 255.0)
          elsif val.is_a?(Integer)
            hex = val.to_s(16).rjust(6, '0')
            __switch_native_color_new(hex[0...2].to_i(16), hex[2...4].to_i(16), hex[4...6].to_i(16), 255.0)
          else
            __switch_native_color_new(0.0, 0.0, 0.0, 255.0)
          end
        elsif args.length >= 4
          __switch_native_color_new(args[0].to_f, args[1].to_f, args[2].to_f, args[3].to_f)
        else
          __switch_native_color_new(0.0, 0.0, 0.0, 255.0)
        end
      else
        super(*args)
      end
    end
  end
end

class << ::Sprite
  unless method_defined?(:__switch_native_sprite_new)
    alias __switch_native_sprite_new new
    def new(*args)
      if self == ::Sprite
        if args.empty?
          __switch_native_sprite_new(nil)
        else
          __switch_native_sprite_new(args[0])
        end
      else
        super(*args)
      end
    end
  end
end

class << ::Plane
  unless method_defined?(:__switch_native_plane_new)
    alias __switch_native_plane_new new rescue nil
    def new(*args)
      if self == ::Plane
        if args.empty?
          __switch_native_plane_new(nil)
        else
          __switch_native_plane_new(args[0])
        end
      else
        super(*args)
      end
    end
  end
end

class << ::Viewport
  unless method_defined?(:__switch_native_viewport_new)
    alias __switch_native_viewport_new new rescue nil
    def new(*args)
      if self == ::Viewport
        if args.empty?
          __switch_native_viewport_new(0, 0, (Graphics.width rescue 512), (Graphics.height rescue 384))
        elsif args.length == 1 && args[0].is_a?(Rect)
          __switch_native_viewport_new(args[0])
        elsif args.length == 1 && args[0].nil?
          __switch_native_viewport_new(0, 0, (Graphics.width rescue 512), (Graphics.height rescue 384))
        elsif args.length == 4
          __switch_native_viewport_new(args[0].to_i, args[1].to_i, args[2].to_i, args[3].to_i)
        else
          __switch_native_viewport_new(0, 0, (Graphics.width rescue 512), (Graphics.height rescue 384))
        end
      else
        super(*args)
      end
    end
  end
end

class << ::Rect
  unless method_defined?(:__switch_native_rect_new)
    alias __switch_native_rect_new new rescue nil
    def new(*args)
      if self == ::Rect
        if args.empty?
          __switch_native_rect_new(0, 0, 0, 0)
        elsif args.length == 4
          __switch_native_rect_new(args[0].to_i, args[1].to_i, args[2].to_i, args[3].to_i)
        elsif args.length == 1 && args[0].is_a?(Rect)
          __switch_native_rect_new(args[0].x, args[0].y, args[0].width, args[0].height)
        else
          __switch_native_rect_new(0, 0, 0, 0)
        end
      else
        super(*args)
      end
    end
  end
end

class << ::Tilemap
  unless method_defined?(:__switch_native_tilemap_new)
    alias __switch_native_tilemap_new new rescue nil
    def new(*args)
      if self == ::Tilemap
        if args.empty?
          __switch_native_tilemap_new(nil)
        else
          __switch_native_tilemap_new(args[0])
        end
      else
        super(*args)
      end
    end
  end
end

module ::Graphics
  class << self
    unless method_defined?(:__switch_native_transition)
      alias __switch_native_transition transition rescue nil
      def transition(duration = 8, filename = "", vague = 40)
        duration = 8 if duration.nil?
        filename = "" if filename.nil?
        vague = 40 if vague.nil?
        if respond_to?(:__switch_native_transition)
          __switch_native_transition(duration.to_i, filename.to_s, vague.to_i)
        end
      end
    end
  end
end

class ::Bitmap
  attr_accessor :text_offset_y

  unless method_defined?(:__switch_native_blt)
    alias __switch_native_blt blt rescue nil
    def blt(x, y, src_bitmap, src_rect, opacity = 255)
      opacity = 255 if opacity.nil?
      if respond_to?(:__switch_native_blt)
        __switch_native_blt(x.to_i, y.to_i, src_bitmap, src_rect, opacity.to_i)
      end
    end
  end

  unless method_defined?(:__switch_native_stretch_blt)
    alias __switch_native_stretch_blt stretch_blt rescue nil
    def stretch_blt(dest_rect, src_bitmap, src_rect, opacity = 255)
      opacity = 255 if opacity.nil?
      if respond_to?(:__switch_native_stretch_blt)
        __switch_native_stretch_blt(dest_rect, src_bitmap, src_rect, opacity.to_i)
      end
    end
  end
end

class AnimFrame
  X          = 0
  Y          = 1
  ZOOMX      = 2
  ANGLE      = 3
  MIRROR     = 4
  BLENDTYPE  = 5
  VISIBLE    = 6
  PATTERN    = 7
  OPACITY    = 8
  ZOOMY      = 11
  COLORRED   = 12
  COLORGREEN = 13
  COLORBLUE  = 14
  COLORALPHA = 15
  TONERED    = 16
  TONEGREEN  = 17
  TONEBLUE   = 18
  TONEGRAY   = 19
  LOCKED     = 20
  FLASHRED   = 21
  FLASHGREEN = 22
  FLASHBLUE  = 23
  FLASHALPHA = 24
  PRIORITY   = 25
  FOCUS      = 26
end unless defined?(AnimFrame)

class PBAnimTiming
  attr_accessor :frame, :timingType, :name, :volume, :pitch
  attr_accessor :bgX, :bgY, :opacity, :colorRed, :colorGreen, :colorBlue, :colorAlpha
  attr_accessor :duration, :flashScope, :flashColor, :flashDuration

  def initialize(type = 0)
    @frame = 0; @timingType = type; @name = ""; @volume = 80; @pitch = 100
    @bgX = nil; @bgY = nil; @opacity = nil; @colorRed = nil; @colorGreen = nil; @colorBlue = nil; @colorAlpha = nil
    @duration = 5; @flashScope = 0; @flashColor = Color.new(255, 255, 255); @flashDuration = 5
  end

  def timingType; @timingType || 0; end
  def duration; @duration || 5; end
end unless defined?(PBAnimTiming)

class PBAnimation < Array
  attr_accessor :id, :name, :graphic, :hue, :position, :speed, :array, :timing, :scope

  def speed; @speed || 20; end
  def initialize(size = 1)
    @id = -1; @name = ""; @graphic = ""; @hue = 0; @position = 4; @array = []; @timing = []; @scope = 0
  end
  def length; @array.length; end
  def [](i); @array[i]; end
  def []=(i, v); @array[i] = v; end
end unless defined?(PBAnimation)

class PBAnimations < Array
  attr_accessor :array, :selected
  def initialize(size = 1)
    @array = []; @selected = 0
  end
  def length; @array.length; end
  def [](i); @array[i]; end
  def []=(i, v); @array[i] = v; end
  def get_from_name(name)
    @array.each { |i| return i if i&.name == name }
    return nil
  end
end unless defined?(PBAnimations)

module Graphics
  class << self
    def scale=(val)
      # No-op on Switch to prevent window shrinking to 512x384
    end
    def resize_screen(w, h)
      # No-op on Switch
    end
    def resize_window(w, h)
      # No-op on Switch
    end
  end
end

def pbSetResizeFactor(factor = 0)
  Graphics.fixed_aspect_ratio = (factor == 1) rescue nil
  Graphics.integer_scaling = false rescue nil
  Graphics.smooth_scaling = 3 rescue nil
  Graphics.fullscreen = true rescue nil
end
end # SWITCH_CORE_RGSS_PATCHED
`;
    changed = true;
  }

  if (s.name.includes('AnimatedBitmap') || s.code.includes('class AnimatedBitmap')) {
    console.log('Patching AnimatedBitmap in:', s.name);
    s.code = s.code.replace(/def dispose\s*\n\s*return if @disposed\s*\n\s*@bitmap\.dispose\s*\n\s*@disposed = true\s*\n\s*end/m, `def dispose
    return if @disposed
    @bitmap.dispose if @bitmap && !@bitmap.disposed? rescue nil
    @disposed = true
  end`);
    s.code = s.code.replace(/def dispose\s*\n\s*@bitmap\.dispose\s*\n\s*end/m, `def dispose
    @bitmap.dispose if @bitmap && !@bitmap.disposed? rescue nil
  end`);
    changed = true;
  }

  if (s.name.includes('SpriteWindow') || s.code.includes('class SpriteWindow')) {
    console.log('Patching SpriteWindow in:', s.name);
    s.code = s.code.replace(/@sprites\[i\]\s*=\s*Sprite\.new\(@viewport\)/g, '@sprites[i] = (@viewport ? Sprite.new(@viewport) : Sprite.new) rescue Sprite.new');
    s.code = s.code.replace(/@tone\s*=\s*Tone\.new\(0,\s*0,\s*0\)/g, '@tone = (Tone.new(0, 0, 0, 0) rescue Tone.new)');
    s.code = s.code.replace(/@color\s*=\s*Color\.new\(0,\s*0,\s*0,\s*0\)/g, '@color = (Color.new(0, 0, 0, 0) rescue Color.new)');
    s.code = s.code.replace(/@blankcontents\s*=\s*Bitmap\.new\(1,\s*1\)/g, '@blankcontents = (Bitmap.new(1, 1) rescue Bitmap.new(32, 32) rescue Bitmap.new rescue nil)');
    changed = true;
  }
  
  if (s.code.includes('class File')) {
    console.log('Patching class File in:', s.name);
    s.code = s.code.replace(/class\s+File\s*<\s*IO/g, 'class ::File');
    s.code = s.code.replace(/class\s+File\b/g, 'class ::File');
    changed = true;
  }

  if (s.code.includes('module Graphics')) {
    console.log('Patching module Graphics in:', s.name);
    s.code = s.code.replace(/module\s+Graphics\b/g, 'module ::Graphics');
    changed = true;
  }

  if (s.code.includes('module Input')) {
    console.log('Patching module Input in:', s.name);
    s.code = s.code.replace(/module\s+Input\b/g, 'module ::Input');
    changed = true;
  }

  if (s.name === 'PluginManager' || s.code.includes('def self.runPlugins')) {
    console.log('Patching PluginManager in:', s.name);
    s.code = fs.readFileSync('Data/Scripts/003_Technical/006_PluginManager.rb', 'utf-8');
    s.code = s.code.replace(/module\s+PluginManager\b/g, 'module ::PluginManager');
    changed = true;
  }

  if (s.name.includes('EventScene') || s.code.includes('class EventScene')) {
    console.log('Patching EventScene in:', s.name);
    s.code = fs.readFileSync('Data/Scripts/022_Scenes/003_EventScene.rb', 'utf-8');
    changed = true;
  }

  if (s.name.includes('UI_SplashesAndTitleScreen') || s.code.includes('class IntroEventScene')) {
    console.log('Patching UI_SplashesAndTitleScreen in:', s.name);
    s.code = fs.readFileSync('Data/Scripts/049_Non-interactive UI/002_UI_SplashesAndTitleScreen.rb', 'utf-8');
    changed = true;
  }

  if (s.name === 'FileTests' || s.code.includes('def pbGetFileChar')) {
    console.log('Patching FileTests in:', s.name);
    s.code = fs.readFileSync('Data/Scripts/005_Files/002_FileTests.rb', 'utf-8');
    s.code = s.code.replace(/file\.last\s*==\s*["']\/["']/g, 'file.to_s[-1] == "/"');
    changed = true;
  }

  if (s.name === 'PictureEx' || s.code.includes('class PictureEx')) {
    console.log('Patching PictureEx in:', s.name);
    s.code = s.code.replace(/@tone\s*=\s*Tone\.new\([^)]*\)/g, '@tone = (Tone.new(0, 0, 0, 0) rescue Tone.new)');
    s.code = s.code.replace(/@color\s*=\s*Color\.new\([^)]*\)/g, '@color = (Color.new(0, 0, 0, 0) rescue Color.new)');
    s.code = s.code.replace(/@src_rect\s*=\s*Rect\.new\([^)]*\)/g, '@src_rect = (Rect.new(0, 0, -1, -1) rescue Rect.new)');
    s.code = s.code.replace(/Tone\.new\(0,\s*0,\s*0,\s*0\)/g, '(Tone.new(0, 0, 0, 0) rescue Tone.new)');
    s.code = s.code.replace(/Color\.new\(0,\s*0,\s*0,\s*0\)/g, '(Color.new(0, 0, 0, 0) rescue Color.new)');
    s.code = s.code.replace(/time_now\s*=\s*System\.uptime/g, 'time_now = (defined?(System) && System.respond_to?(:uptime) ? System.uptime : (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f))');
    changed = true;
  }

  if (s.name === 'AnimatedBitmap' || s.name.includes('MEP') || s.code.includes('class AnimatedBitmap')) {
    console.log('Patching AnimatedBitmap in:', s.name);
    s.code = s.code.replace(/file\.last\s*!=\s*["']\/["']/g, 'file.to_s[-1] != "/"');
    s.code = s.code.replace(/Gif::Bitmap/g, 'GifBitmap');
    s.code = s.code.replace(/PngAnimated::Bitmap/g, 'PngAnimatedBitmap');
    s.code = s.code.replace(/\bBitmap\.new\(32,\s*32\)/g, '(::Bitmap.new(32, 32) rescue ::Bitmap.new rescue nil)');
    s.code = s.code.replace(/(?<![A-Za-z0-9_:])Bitmap\.new\(/g, '::Bitmap.new(');
    changed = true;
  }

  if (s.name.includes('RPG_Cache') || s.code.includes('class BitmapWrapper')) {
    console.log('Patching BitmapWrapper in:', s.name);
    s.code = s.code.replace(/class BitmapWrapper < Bitmap[\s\S]*?def initialize\(\*arg\)[\s\S]*?end/m, `class BitmapWrapper < ::Bitmap
  attr_reader   :refcount
  attr_accessor :never_dispose

  def dispose
    return if self.disposed?
    @refcount -= 1
    super if @refcount <= 0 && !never_dispose
  end

  def initialize(*arg)
    begin
      super(*arg)
    rescue ArgumentError
      if arg.length == 2
        super(arg[0].to_i, arg[1].to_i) rescue nil
      elsif arg.length == 1
        super(arg[0].to_s) rescue nil
      end
    rescue Exception
    end
    @refcount = 1
  end`);
    changed = true;
  }

  if (s.name === 'UI_Load' || s.code.includes('class PokemonLoadScreen')) {
    console.log('Patching UI_Load in:', s.name);
    s.code = s.code.replace(/class PokemonLoadScreen\s*\n\s*def initialize\(([^)]*)\)/m, `class PokemonLoadScreen
  def initialize(scene = nil)
    @scene = scene`);
    s.code = s.code.replace(/class PokemonLoad_Scene\s*\n/m, `class PokemonLoad_Scene
  def initialize(*args); end\n`);
    changed = true;
  }

  if (s.code.includes('module Audio')) {
    console.log('Patching module Audio in:', s.name);
    s.code = s.code.replace(/module\s+Audio\b/g, 'module ::Audio');
    changed = true;
  }

  if (s.code.includes('Graphics.frame_rate')) {
    console.log('Patching Graphics.frame_rate in:', s.name);
    s.code = s.code.replace(/Graphics\.frame_rate\b/g, '(Graphics.respond_to?(:frame_rate) ? Graphics.frame_rate : 40)');
    changed = true;
  }
  
  if (s.name.includes('SaveData')) {
    console.log('Patching SaveData in:', s.name);
    s.code = s.code.replace(/FILE_PATH\s*=\s*if[\s\S]*?end/m, 'FILE_PATH = "./Game.rxdata"');
    s.code = s.code.replace(/def self\.get_data_from_file[\s\S]*?\bend\s*\n\s*#\s*Obtiene los datos/m, `def self.get_data_from_file(file_path)
    validate file_path => String rescue nil
    save_data = nil
    File.open(file_path, "rb") do |file|
      begin
        data = Marshal.load(file)
      rescue Exception => e
        log_compat("[SaveData Warning] Incompatible save file: #{e.message}") rescue nil
        return {}
      end
      if data.is_a?(Hash)
        save_data = data
        next
      end
      save_data = [data]
      begin
        save_data << Marshal.load(file) until file.eof?
      rescue Exception
      end
    end
    return save_data || {}
  end

  # Obtiene los datos`);
    changed = true;
  }

  if (s.name === 'Validation' || s.code.includes('def validate(value_pairs)')) {
    console.log('Patching Validation in:', s.name);
    s.code = s.code.replace(/private\s*\n\s*#/, 'public\n  #');
    changed = true;
  }

  if (s.name === 'RubyUtilities' || s.code.includes('alias init_original initialize')) {
    console.log('Patching Color initialize in:', s.name);
    s.code = s.code.replace(/class\s+Color\s*\n\s*#\s*alias\s+del\s+antiguo\s+constructor[\s\S]*?end\n\s*def\s+self\.new_from_rgb/m, 
`class Color
  def self.new(*args)
    if args.length == 1
      val = args.first
      if val.is_a?(String)
        if val.include?(",")
          parts = val.split(",").map(&:to_i)
          return super(*parts)
        else
          hex = val.delete("#")
          return super(hex[0...2].to_i(16), hex[2...4].to_i(16), hex[4...6].to_i(16), 255)
        end
      elsif val.is_a?(Integer)
        hex = val.to_s(16).rjust(6, '0')
        return super(hex[0...2].to_i(16), hex[2...4].to_i(16), hex[4...6].to_i(16), 255)
      end
    elsif args.length == 3
      return super(args[0], args[1], args[2], 255)
    end
    super(*args)
  end

  def self.new_from_rgb`);
    changed = true;
  }

  if (s.name.includes('Event_Handlers')) {
    console.log('Patching Event_Handlers handler check in:', s.name);
    s.code = s.code.replace(/if\s+![^\n]*\s*raise\s+ArgumentError[^\n]*\n\s*end/g, '');
    changed = true;
  }


  if (s.name === 'SaveData' || s.name === 'SaveData_Value' || s.name === 'SaveData_Conversion' || s.name.startsWith('SaveData')) {
    console.log('Patching SaveData namespace in:', s.name);
    s.code = s.code.replace(/module\s+SaveData\b/g, 'module ::SaveData');
    changed = true;
  }

  if (s.name.includes('Utilities') && (s.code.includes('def pbGetUserName') || s.code.includes('def pbGetLanguage'))) {
    console.log('Patching Utilities in:', s.name);
    s.code = s.code.replace(/def\s+pbGetUserName[\s\S]*?end\n/m, 'def pbGetUserName; "Ash"; end\n');
    s.code = s.code.replace(/def\s+pbGetLanguage[\s\S]*?return\s+2[^\n]*\nend\s*\n/m, 'def pbGetLanguage\n  return 7\nend\n\n');
    changed = true;
  }

  if (s.name.includes('Turbo') || s.code.includes('unscaled_uptime')) {
    console.log('Patching Turbo System.uptime in:', s.name);
    s.code = s.code.replace(/module\s+System[\s\S]*?def\s+self\.uptime[\s\S]*?end\r?\nend/m,
`module System
  class << self
    def unscaled_uptime
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f)
    end
    def uptime
      mult = (defined?(SPEEDUP_STAGES) && defined?($GameSpeed) && SPEEDUP_STAGES[$GameSpeed]) ? SPEEDUP_STAGES[$GameSpeed] : 1
      mult * unscaled_uptime
    end
  end
end`);
    changed = true;
  }

  if (s.code.includes('module System')) {
    s.code = s.code.replace(/module\s+System\b/g, 'module ::System');
    changed = true;
  }

  if (s.code.includes('System.data_directory')) {
    console.log('Patching System.data_directory in:', s.name);
    s.code = s.code.replace(/System\.data_directory/g, '"."');
    changed = true;
  }

  if (s.name.includes('DebugConsole') || s.code.includes('def echoln(string)')) {
    console.log('Patching DebugConsole echoln in:', s.name);
    s.code = s.code.replace(/module\s+Kernel[\s\S]*?def\s+echoln\(string\)[\s\S]*?end\s*end/m,
`module Kernel
  def echo(string)
    puts string if $DEBUG
  end
  def echoln(string)
    puts string if $DEBUG
  end
  module_function :echo, :echoln
end

module Console
  def self.echo(string); Kernel.echo(string); end
  def self.echoln(string); Kernel.echoln(string); end
end`);
    changed = true;
  }

  if (s.name === 'Errors' || s.code.includes('def pbPrintException')) {
    console.log('Patching pbPrintException in:', s.name);
    s.code = s.code.replace(/print\(["'].*?portapapeles\.["']\)/m, 'puts message');
    changed = true;
  }

  if (s.name === 'StartGame' || s.code.includes('def self.set_up_system')) {
    console.log('Patching StartGame set_up_system in:', s.name);
    s.code = s.code.replace(/def\s+self\.set_up_system[\s\S]*?end\r?\n\r?\n\s*#\s*Called/m,
`def self.set_up_system
    log_compat("[set_up_system] a. comprobando save_data...") rescue nil
    save_data = (SaveData.exists?) ? (SaveData.read_from_file(SaveData::FILE_PATH) rescue {}) : {}
    log_compat("[set_up_system] b. save_data obtenido: #{save_data.class}") rescue nil
    if save_data.empty?
      log_compat("[set_up_system] c. inicializando bootup values...") rescue nil
      SaveData.initialize_bootup_values rescue nil
    else
      log_compat("[set_up_system] c. cargando bootup values...") rescue nil
      SaveData.load_bootup_values(save_data) rescue nil
    end
    log_compat("[set_up_system] d. comprobando PokemonSystem...") rescue nil
    $PokemonSystem ||= PokemonSystem.new rescue nil
    SaveData.load_options rescue nil
    log_compat("[set_up_system] e. configurando pantalla...") rescue nil
    pbSetResizeFactor([$PokemonSystem.screensize, 4].min) rescue nil
    log_compat("[set_up_system] f. completado con exito!") rescue nil
  end

  # Called`);
    changed = true;
  }

  if (s.code.includes('Event_Handlers.remove(:on_frame_update, :wait_for_other_active_events)')) {
    console.log('Patching Event_Handlers handler check in:', s.name);
    s.code = s.code.replace(/if\s+!EventHandlers\.has_key\?\(event,\s*key\)[\s\S]*?end/g, '');
    changed = true;
  }





  if (s.name.includes('Barras entrenadores') || s.code.includes('module TrainerSensor')) {
    console.log('Patching Barras entrenadores in:', s.name);
    s.code = s.code.replace(/module\s+TrainerSensor[\s\S]*?@created\s*=\s*false/m,
`module TrainerSensor
  @top = nil
  @bottom = nil
  @triggered = false
  @created = false`);
    s.code = s.code.replace(/def\s+self\.create\(distance\)\s*\n\s*(?:@top\s*=\s*Sprite\.new[\s\S]*?)?if\s+!@created/m,
`def self.create(distance)
    @top = Sprite.new if !@top || @top.disposed?
    @top.z = 1 if @top.respond_to?(:z=)
    @bottom = Sprite.new if !@bottom || @bottom.disposed?
    @bottom.z = 1 if @bottom.respond_to?(:z=)
    if !@created`);
    changed = true;
  }

  if (s.code.includes('Bitmap.max_size')) {
    console.log('Patching Bitmap.max_size in:', s.name);
    s.code = s.code.replace(/Bitmap\.max_size/g, '4096');
    changed = true;
  }

  if (s.name === 'GameData' || s.code.includes('raise "Unknown ID #{other}."')) {
    console.log('Patching GameData in:', s.name);
    s.code = s.code.replace(/raise\s+"Unknown ID #\{other\}\."\s*unless\s*self::DATA\.has_key\?\(other\)/g, 'return nil unless self::DATA.has_key?(other)');
    changed = true;
  }

  if (s.name.includes('SplashesAndTitleScreen') || s.code.includes('def fade_out_title_screen')) {
    console.log('Patching fade_out_title_screen in:', s.name);
    s.code = s.code.replace(
      /def fade_out_title_screen\(scene\)[\s\S]*?end\n\n\s*def close_title_screen/m,
`def fade_out_title_screen(scene)
    onUpdate.clear
    onCTrigger.clear
    begin
      species_keys = GameData::Species.keys rescue []
      if species_keys && !species_keys.empty?
        sample_key = species_keys.sample
        if sample_key
          species_data = GameData::Species.try_get(sample_key) rescue nil
          Pokemon.play_cry(species_data.species, species_data.form) if species_data rescue nil
        end
      end
    rescue Exception
    end
    @pic.moveXY(0, 20, 0, 0)
    pictureWait
    @pic.moveOpacity(0, FADE_TICKS, 0)
    @pic2.clearProcesses
    @pic2.moveOpacity(0, FADE_TICKS, 0)
    pbBGMStop(1.0)
    pictureWait
    scene.dispose
  end

  def close_title_screen`
    );
    changed = true;
  }

  if (s.name === 'AnimatedBitmap' || s.code.includes('class AnimatedBitmap')) {
    console.log('Patching AnimatedBitmap in:', s.name);
    s.code = s.code.replace(
      /def\s+initialize\(file,\s*hue\s*=\s*0\)[\s\S]*?@bitmap\s*=\s*GifBitmap\.new\(path,\s*filename,\s*hue\)\s*\n\s*end\s*\n\s*end/m,
`def initialize(file, hue = 0)
    file = "" if file.nil?
    path     = file.to_s
    filename = ""
    if path.length > 0 && path[-1] != "/"
      split_file = path.split(/[\\\\\\/]/)
      filename = split_file.pop || ""
      path = split_file.empty? ? "" : (split_file.join("/") + "/")
    end
    filename ||= ""
    if filename.length > 0 && filename[/^\\[\\d+(?:,\\d+)?\\]/]
      @bitmap = PngAnimatedBitmap.new(path, filename, hue)
    else
      @bitmap = GifBitmap.new(path, filename, hue)
    end
  end`
    );
    changed = true;
  }

  if (s.name === 'Trainer_Class' || s.code.includes('@trainer_type = GameData::TrainerType.get(trainer_type).id')) {
    console.log('Patching Trainer_Class initialize in:', s.name);
    s.code = s.code.replace(
      /@trainer_type\s*=\s*GameData::TrainerType\.get\(trainer_type\)\.id/g,
      '@trainer_type = (GameData::TrainerType.try_get(trainer_type)&.id rescue nil) || GameData::TrainerType.keys.find { |k| k.is_a?(Symbol) } || :POKEMONTRAINER_Red'
    );
    changed = true;
  }

  if (s.name === 'Player' || s.code.includes('@money                 = GameData::Metadata.get.start_money')) {
    console.log('Patching Player initialize in:', s.name);
    s.code = s.code.replace(
      /@money\s*=\s*GameData::Metadata\.get\.start_money/g,
      '@money = (GameData::Metadata.get.start_money rescue 3000) || 3000'
    );
    changed = true;
  }

  if (s.name === 'Game_SaveValues' || s.code.includes('Player.new("Unnamed", GameData::TrainerType.keys.first)')) {
    console.log('Patching Game_SaveValues in:', s.name);
    s.code = s.code.replace(
      /Player\.new\("Unnamed",\s*GameData::TrainerType\.keys\.first\)/g,
      'Player.new("Unnamed", GameData::TrainerType.keys.find { |k| k.is_a?(Symbol) } || GameData::TrainerType.keys.first || :POKEMONTRAINER_Red)'
    );
    changed = true;
  }

  if (s.name === 'RubyUtilities' || s.code.includes('alias oldRand rand')) {
    console.log('Patching rand recursion in:', s.name);
    s.code = s.code.replace(/def rand\(\*args\)[\s\S]*?class << Kernel[\s\S]*?end\s*\nend/m, '# Native Ruby 3 rand');
    changed = true;
  }

  if (s.name === 'DrawText' || s.code.includes('defaultfontname = "Arial"')) {
    console.log('Patching font fallbacks and sharp shadow in:', s.name);
    s.code = s.code.replace(/"Arial"/g, '"Power Green"');
    s.code = s.code.replace(
      /bitmap\.draw_text\(x \+ 2, y, width, height, string, align\)[\s\S]*?bitmap\.draw_text\(x \+ 2, y \+ 2, width, height, string, align\)/m,
      'bitmap.draw_text(x + 1, y + 1, width, height, string, align)'
    );
    changed = true;
  }

  if (s.name === 'TilemapRenderer' || s.code.includes('class TileSprite < Sprite')) {
    console.log('Patching TileSprite and update in:', s.name);
    s.code = s.code.replace(
      /class\s+TileSprite\s*<\s*Sprite/g,
`class TileSprite < Sprite
    def initialize(viewport = nil)
      super(viewport) rescue super()
    end`
    );
    s.code = s.code.replace(
      /  def update\n    # Update tone[\s\S]*?@autotiles\.changed = false\n  end\nend/m,
`  def update
    return if !@tiles || @tiles.empty? || !$map_factory
    begin
      # Update tone
      if @old_tone != @tone
        if @tiles
          for col in @tiles
            if col
              for coord in col
                if coord
                  for layer in 0..2
                    tile = (coord[layer] rescue nil)
                    tile.tone = @tone if tile
                  end
                end
              end
            end
          end
        end
        @old_tone = @tone.clone rescue @tone
      end
      # Update color
      if @old_color != @color
        if @tiles
          for col in @tiles
            if col
              for coord in col
                if coord
                  for layer in 0..2
                    tile = (coord[layer] rescue nil)
                    tile.color = @color if tile
                  end
                end
              end
            end
          end
        end
        @old_color = @color.clone rescue @color
      end
      # Recalculate autotile frames
      @tilesets.update rescue nil
      @autotiles.update rescue nil
      do_full_refresh = @need_refresh
      if @viewport && (@viewport.ox != @old_viewport_ox || @viewport.oy != @old_viewport_oy)
        @old_viewport_ox = @viewport.ox
        @old_viewport_oy = @viewport.oy
        do_full_refresh = true
      end
      # Check whether the screen has moved since the last update
      @screen_moved = false
      @screen_moved_vertically = false
      if $PokemonGlobal && $PokemonGlobal.bridge != @bridge
        @bridge = $PokemonGlobal.bridge
        @screen_moved_vertically = true
      end
      do_full_refresh = true if (check_if_screen_moved rescue false)
      # Update all tile sprites
      visited = []
      @tiles_horizontal_count.times do |i|
        visited[i] = []
        @tiles_vertical_count.times { |j| visited[i][j] = false }
      end
      $map_factory.maps.each do |map|
        next unless map
        map_display_x = (map.display_x.to_f / Game_Map::X_SUBPIXELS).round rescue 0
        map_display_x = ((map_display_x + (Graphics.width / 2)) * ZOOM_X) - (Graphics.width / 2) if ZOOM_X != 1
        map_display_y = (map.display_y.to_f / Game_Map::Y_SUBPIXELS).round rescue 0
        map_display_y = ((map_display_y + (Graphics.height / 2)) * ZOOM_Y) - (Graphics.height / 2) if ZOOM_Y != 1
        map_display_x_tile = map_display_x / DISPLAY_TILE_WIDTH
        map_display_y_tile = map_display_y / DISPLAY_TILE_HEIGHT
        start_x = [-map_display_x_tile, 0].max
        start_y = [-map_display_y_tile, 0].max
        end_x = [@tiles_horizontal_count - 1, (map.width rescue 50) - map_display_x_tile - 1].min
        end_y = [@tiles_vertical_count - 1, (map.height rescue 50) - map_display_y_tile - 1].min
        next if start_x > end_x || start_y > end_y || end_x < 0 || end_y < 0
        for i in start_x..end_x
          next if i < 0 || i >= @tiles_horizontal_count || !@tiles[i]
          tile_x = i + map_display_x_tile
          for j in start_y..end_y
            next if j < 0 || j >= @tiles_vertical_count || !@tiles[i][j]
            tile_y = j + map_display_y_tile
            for layer in 0..2
              tile = (@tiles[i][j][layer] rescue nil)
              if tile
                tile_id = (map.data[tile_x, tile_y, layer] rescue 0) || 0
                if do_full_refresh || tile.need_refresh || tile.tile_id != tile_id
                  refresh_tile(tile, i, j, map, layer, tile_id) rescue nil
                else
                  refresh_tile_frame(tile, tile_id) if tile.animated && @autotiles.changed rescue nil
                  refresh_tile_coordinates(tile, i, j) if @screen_moved rescue nil
                  refresh_tile_z(tile, map, j, layer, tile_id) if @screen_moved_vertically rescue nil
                end
              end
            end
            visited[i][j] = true rescue nil
          end
        end
      end
      if @tiles
        _i = 0
        for col in @tiles
          if col
            _j = 0
            for coord in col
              if coord && (!visited[_i] || !visited[_i][_j])
                for layer in 0..2
                  tile = (coord[layer] rescue nil)
                  if tile
                    tile.set_bitmap("", 0, false, false, 0, nil) rescue nil
                    tile.shows_reflection = false
                    tile.bridge           = false
                  end
                end
              end
              _j += 1
            end
          end
          _i += 1
        end
      end
      @need_refresh = false
      @autotiles.changed = false
    rescue Exception => e
      log_compat("[TilemapRenderer update handled] #{e.message}") rescue nil
    end
  end
end`
    );
    changed = true;
  }

  if (s.name === 'MessageConfig' || s.code.includes('def self.pbTryFonts')) {
    console.log('Patching pbTryFonts in:', s.name);
    s.code = s.code.replace(
      /def self\.pbTryFonts\(\*args\)[\s\S]*?\n  end/m,
`def self.pbTryFonts(*args)
    args.each do |a|
      next if !a || a.empty?
      case a
      when String
        return a
      when Array
        a.each do |aa|
          ret = MessageConfig.pbTryFonts(aa)
          return ret if ret && ret != ""
        end
      end
    end
    return "Power Clear"
  end`
    );
    s.code = s.code.replace(/FONT_NAME\s*=\s*["'][^"']+["']/, 'FONT_NAME = "Power Clear"');
    s.code = s.code.replace(/FONT_SIZE\s*=\s*\d+/, 'FONT_SIZE = 28');
    s.code = s.code.replace(/FONT_Y_OFFSET\s*=\s*\d+/, 'FONT_Y_OFFSET = 0');
    s.code = s.code.replace(/SMALL_FONT_NAME\s*=\s*["'][^"']+["']/, 'SMALL_FONT_NAME = "Power Clear"');
    s.code = s.code.replace(/SMALL_FONT_SIZE\s*=\s*\d+/, 'SMALL_FONT_SIZE = 22');
    s.code = s.code.replace(/SMALL_FONT_Y_OFFSET\s*=\s*\d+/, 'SMALL_FONT_Y_OFFSET = 0');
    s.code = s.code.replace(/NARROW_FONT_NAME\s*=\s*["'][^"']+["']/, 'NARROW_FONT_NAME = "Power Clear"');
    s.code = s.code.replace(/NARROW_FONT_SIZE\s*=\s*\d+/, 'NARROW_FONT_SIZE = 28');
    s.code = s.code.replace(
      /def self\.pbDefaultSystemFrame[\s\S]*?def self\.pbDefaultWindowskin/m,
`def self.pbDefaultSystemFrame
    idx = ($PokemonSystem ? ($PokemonSystem.frame || 0) : 0).to_i
    skin_name = (Settings::MENU_WINDOWSKINS[idx] rescue nil) || (Settings::MENU_WINDOWSKINS[0] rescue nil) || "001-Blue01"
    path = File.join("Graphics", "Windowskins", skin_name)
    return pbResolveBitmap(path) || ""
  end

  def self.pbDefaultSpeechFrame
    idx = ($PokemonSystem ? ($PokemonSystem.textskin || 0) : 0).to_i
    skin_name = (Settings::SPEECH_WINDOWSKINS[idx] rescue nil) || (Settings::SPEECH_WINDOWSKINS[0] rescue nil) || "speech hgss 1"
    path = File.join("Graphics", "Windowskins", skin_name)
    return pbResolveBitmap(path) || ""
  end

  def self.pbDefaultWindowskin`
    );
    s.code = s.code.replace(/duration\s*=\s*0\.4\s*#\s*In seconds/g, 'duration = 0.1   # In seconds');
    changed = true;
  }




  if (s.name.includes('Metadata') && s.code.includes('class Metadata')) {
    s.code = s.code.replace(
      /def self\.get[\s\S]*?return DATA\[0\]\s*\n\s*end/m,
      `def self.get\n      return DATA[0] || (DATA.is_a?(Hash) ? DATA.values.first : nil) || self.new({})\n    end`
    );
    changed = true;
  }

  if (s.name.includes('Overworld') && s.code.includes('def pbAutoplayOnSave')) {
    s.code = s.code.replace(
      /def pbAutoplayOnTransition[\s\S]*?def pbAutoplayOnSave[\s\S]*?\$game_map\.autoplay\s*\n\s*end\s*\n\s*end/m,
`def pbAutoplayOnTransition
  surfbgm = GameData::Metadata.get&.surf_BGM rescue nil
  if $PokemonGlobal&.surfing && surfbgm
    pbBGMPlay(surfbgm)
  else
    $game_map&.autoplayAsCue rescue nil
  end
end

def pbAutoplayOnSave
  surfbgm = GameData::Metadata.get&.surf_BGM rescue nil
  if $PokemonGlobal&.surfing && surfbgm
    pbBGMPlay(surfbgm) rescue nil
  else
    $game_map&.autoplay rescue nil
  end
  $player.last_update_time(System.real_uptime) if $player rescue nil
end

module Game
  def self.pbAutoplayOnSave
    surfbgm = GameData::Metadata.get&.surf_BGM rescue nil
    if $PokemonGlobal&.surfing && surfbgm
      pbBGMPlay(surfbgm) rescue nil
    else
      $game_map&.autoplay rescue nil
    end
    $player.last_update_time(System.real_uptime) if $player rescue nil
  end
end`
    );
    changed = true;
  }



  if (s.name.includes('BattleStarting') || s.code.includes('def setBattleRule')) {
    console.log('Patching BattleStarting in:', s.name);
    s.code = s.code.replace(
      /def add_battle_rule\(rule, var = nil\)[\s\S]*?\n  end\nend/m,
`def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "single", "1v1", "1v2", "2v1", "1v3", "3v1",
         "double", "2v2", "2v3", "3v2", "triple", "3v3"
      rules["size"] = rule.to_s.downcase
    when "canlose"                then rules["canLose"]             = true
    when "cannotlose"             then rules["canLose"]             = false
    when "canrun"                 then rules["canRun"]              = true
    when "cannotrun"              then rules["canRun"]              = false
    when "roamerflees"            then rules["roamerFlees"]         = true
    when "canswitch"              then rules["canSwitch"]           = true
    when "cannotswitch"           then rules["canSwitch"]           = false
    when "noexp"                  then rules["expGain"]             = false
    when "nomoney"                then rules["moneyGain"]           = false
    when "disablepokeballs"       then rules["disablePokeBalls"]    = true
    when "forcecatchintoparty"    then rules["forceCatchIntoParty"] = true
    when "switchstyle"            then rules["switchStyle"]         = true
    when "setstyle"               then rules["switchStyle"]         = false
    when "anims"                  then rules["battleAnims"]         = true
    when "noanims"                then rules["battleAnims"]         = false
    when "terrain"
      rules["defaultTerrain"] = GameData::BattleTerrain.try_get(var)&.id rescue nil
    when "weather"
      rules["defaultWeather"] = GameData::BattleWeather.try_get(var)&.id rescue nil
    when "environment", "environ"
      rules["environment"] = GameData::Environment.try_get(var)&.id rescue nil
    when "backdrop", "battleback" then rules["backdrop"]            = var
    when "base"                   then rules["base"]                = var
    when "outcome", "outcomevar"  then rules["outcomeVar"]          = var
    when "nopartner"              then rules["noPartner"]           = true
    when "adjustlevels"           then rules["adjustLevels"]        = true
    when "adjustlevelsresetmoves" then rules["adjustLevelsResetMoves"] = true
    when "midbattlescript", "midbattle" then rules["midbattleScript"] = var
    else
      rules[rule.to_s] = var.nil? ? true : var
    end
  end
end`
    );
    s.code = s.code.replace(
      /when "terrain", "weather", "environment", "environ", "backdrop",\s*\n\s*"battleback", "base", "outcome", "outcomevar"/g,
      'when "terrain", "weather", "environment", "environ", "backdrop", "battleback", "base", "outcome", "outcomevar", "midbattlescript", "midbattle"'
    );
    s.code = s.code.replace(
      /raise _INTL\("Argumento \{1\} esperaba una variable después pero no la tiene\.", r\) if r/g,
      '$game_temp.add_battle_rule(r) if r'
    );
    changed = true;
  }
  
  if (s.name.includes('Mostrar nombres') || s.code.includes('module NameBox')) {
    s.code = s.code.replace(
      /@namebox\.setSkin\("Graphics\/Windowskins\/#\{skin\}"\)/g,
      'skin = "Graphics/Windowskins/#{skin}" unless skin.to_s.start_with?("Graphics/"); @namebox.setSkin(skin)'
    );
    changed = true;
  }

  if (s.name.includes('SpriteWindow') && s.code.includes('def setSkin(skin)')) {
    s.code = s.code.replace(
      /def setSkin\(skin\)[\s\S]*?resolvedName = pbResolveBitmap\(skin\)/m,
`def setSkin(skin)
    @customskin&.dispose
    @customskin = nil
    skin = skin.to_s.gsub("Graphics/Windowskins/Graphics/Windowskins/", "Graphics/Windowskins/")
    resolvedName = pbResolveBitmap(skin)`
    );
    changed = true;
  }
  
  if (s.name.includes('Messages') && s.code.includes('def pbMessageDisplay')) {
    console.log('Patching Messages button prompts in:', s.name);
    s.code = s.code.replace(
      /colortag\s*=\s*getSkinColor[\s\S]*?text\s*=\s*colortag\s*\+\s*text/m,
`colortag = getSkinColor(msgwindow.windowskin, 0, isDarkSkin)
  end
  # Adaptacion dinamica de controles de PC a Nintendo Switch
  text.gsub!(/\\b(?:tecla|Tecla)\\s+C\\b/i, "botón B (Aceptar)")
  text.gsub!(/\\b(?:tecla|Tecla)\\s+X\\b/i, "botón A (Cancelar)")
  text.gsub!(/\\b(?:tecla|Tecla)\\s+Z\\b/i, "botón X (Menú)")
  text.gsub!(/\\b(?:tecla|Tecla)\\s+D\\b/i, "botón R (Turbo)")
  text.gsub!(/\\b(?:tecla|Tecla)\\s+S\\b/i, "botón Y")
  text.gsub!(/\\b(?:teclas|Teclas)\\s+A\\s+y\\s+S\\b/i, "botones L y R")
  text.gsub!(/\\bEnter\\b/i, "botón B")
  
  text = colortag + text`
    );
    s.code = s.code.replace(/appear_duration\s*=\s*0\.5\s*#\s*In seconds/, 'appear_duration = 0.08   # In seconds');
    changed = true;
  }
  
  if (s.code.includes('pbShowCommands') || s.code.includes('Kernel.pb')) {
    s.code = s.code.replace(/next\s+(?:Kernel\.)?pbShowCommands\(/g, 'next send(:pbShowCommands, ');
    s.code = s.code.replace(/next\s+(?:Kernel\.)?pbShowCommandsWithHelp\(/g, 'next send(:pbShowCommandsWithHelp, ');
    s.code = s.code.replace(/Kernel\.pb([A-Za-z0-9_]+)/g, 'pb$1');
    changed = true;
  }
  
  if (s.name.includes('UI_TextEntry') || s.code.includes('def pbEntry1')) {
    console.log('Patching UI_TextEntry in:', s.name);
    s.code = s.code.replace(
      /if Input\.triggerex\?\(:ESCAPE\)[\s\S]*?ret = @sprites\["entry"\]\.text\s*\n\s*break\s*\n\s*end/m,
      `if (Input.triggerex?(:ESCAPE) || Input.trigger?(Input::BACK) || Input.trigger?(Input::B)) && @minlength == 0
        ret = ""
        break
      elsif (Input.triggerex?(:RETURN) || Input.trigger?(Input::USE) || Input.trigger?(Input::C) || Input.trigger?(Input::ACTION) || Input.trigger?(Input::A) || (Input.respond_to?(:triggerex?) && Input.triggerex?(0x0D))) && @sprites["entry"].text.length >= @minlength
        ret = @sprites["entry"].text
        break
      end`
    );
    s.code = s.code.replace(
      /def pbChangeTab\(newtab = @mode \+ 1\)[\s\S]*?pbDoUpdateOverlay2\s*\n\s*end/m,
`def pbChangeTab(newtab = @mode + 1)
    pbSEPlay("GUI naming tab swap start")
    @mode = newtab % @@Characters.length
    @sprites["bottomtab"].bitmap = @bitmaps[@mode + @@Characters.length]
    @sprites["bottomtab"].x = 22
    @sprites["bottomtab"].y = 162
    @sprites["toptab"].bitmap = @bitmaps[((@mode + 1) % @@Characters.length) + @@Characters.length]
    @sprites["toptab"].x = 22 - 504
    @sprites["toptab"].y = 162
    @sprites["cursor"].visible = true
    pbSEPlay("GUI naming tab swap end")
    pbDoUpdateOverlay2
  end`
    );
    changed = true;
  }
  
  if (s.name.includes('Game_Player') || s.code.includes('def bump_into_object')) {
    console.log('Patching Game_Player in:', s.name);
    s.code = s.code.replace(
      /def initialize\(\*arg\)[\s\S]*?@lastdirframe = 0\s*\n\s*end/m,
`def initialize(*arg)
    super(*arg)
    @lastdir = 0
    @lastdirframe = 0
  end

  def character_name
    if @character_name.nil? || @character_name == ""
      refresh_charset
    end
    if @character_name.nil? || @character_name == ""
      meta = GameData::PlayerMetadata.get($player ? ($player.character_ID || 1) : 1) rescue nil
      @character_name = meta ? meta.walk_charset : "POKEMONTRAINER_RojoNeutro"
    end
    return @character_name || "POKEMONTRAINER_RojoNeutro"
  end

  def transparent
    return false if !@move_route_forcing && !pbMapInterpreterRunning?
    return @transparent
  end`
    );
    s.code = s.code.replace(
      /def bump_into_object[\s\S]*?@bumping = true\s*\n\s*end/m,
`def bump_into_object
    return if @bumping
    @bumping = true
    $stats.bump_count += 1 if $stats
    @move_initial_x = @x
    @move_initial_y = @y
    @move_timer = 0.0
    pbSEPlay("Player bump") if !@move_route_forcing && !Settings::DISABLE_BUMP_SOUND rescue nil
  end`
    );
    s.code = s.code.replace(
      /def refresh_charset[\s\S]*?@character_name = new_charset if new_charset\s*\n\s*end/m,
`def refresh_charset
    meta = GameData::PlayerMetadata.get($player&.character_ID || 1)
    return if !meta
    new_charset = nil
    if $PokemonGlobal&.diving
      new_charset = pbGetPlayerCharset(meta.dive_charset, nil, true)
    elsif $PokemonGlobal&.surfing
      new_charset = pbGetPlayerCharset(meta.surf_charset, nil, true)
    elsif $PokemonGlobal&.bicycle
      new_charset = pbGetPlayerCharset(meta.cycle_charset, nil, true)
    else
      new_charset = pbGetPlayerCharset(meta.walk_charset, nil, true)
    end
    @character_name = new_charset if new_charset && new_charset != ""
  end`
    );
    s.code = s.code.replace(
      /def pbGetPlayerCharset\(charset, trainer = nil, force = false\)[\s\S]*?return ret\s*\n\s*end/m,
`def pbGetPlayerCharset(charset, trainer = nil, force = false)
  return "" if charset.nil? || charset == ""
  trainer = $player if !trainer
  outfit = (trainer) ? trainer.outfit.to_i : 0
  char_id = trainer ? trainer.character_ID.to_i : 1
  force = true if $game_player && ($game_player.character_name.nil? || $game_player.character_name == "")
  return nil if !force && $game_player&.charsetData &&
                $game_player.charsetData[0] == char_id &&
                $game_player.charsetData[1] == charset &&
                $game_player.charsetData[2] == outfit
  $game_player.charsetData = [char_id, charset, outfit] if $game_player
  ret = charset.to_s
  if pbResolveBitmap("Graphics/Characters/" + ret + "_" + outfit.to_s)
    ret = ret + "_" + outfit.to_s
  end
  return ret
end`
    );
    changed = true;
  }
  
  if (s.name === 'Player' || s.code.includes('class Player < Trainer')) {
    console.log('Patching Player in:', s.name);
    s.code = s.code.replace(
      /attr_accessor :has_exp_all/,
      `attr_accessor :has_exp_all\n  attr_accessor :expall\n  def expall=(v); @expall = v; @has_exp_all = v; end\n  def expall; @expall || @has_exp_all; end`
    );
    changed = true;
  }
  
  if (s.name === 'Interpreter' || s.code.includes('def execute_script')) {
    console.log('Patching Interpreter execute_script in:', s.name);
    s.code = s.code.replace(
      /def execute_script\(script\)[\s\S]*?rescue Exception\s*\n\s*e = \$!/m,
      `def execute_script(script)
    begin
      result = eval(script)
      return result
    rescue Exception => e
      log_compat("[EVENT SCRIPT CRASH] #{e.class}: #{e.message}\\n  Script: #{script.inspect}\\n  Backtrace:\\n#{e.backtrace&.join("\\n")}") rescue nil
      if script.include?("setBattleRule") || e.message.include?("regla de combate") || e.message.include?("midbattle")
        return nil
      end`
    );
    changed = true;
  }
  
  if (s.name.includes('Pokemon') && s.code.includes('def initialize(species, level')) {
    console.log('Patching Pokemon initialize in:', s.name);
    s.code = s.code.replace(
      /def species_data\s*\n\s*return GameData::Species\.get_species_form\(@species, form_simple\)\s*\n\s*end/m,
`def species_data
    ret = GameData::Species.get_species_form(@species, form_simple) rescue nil
    ret ||= GameData::Species.try_get(@species) rescue nil
    ret ||= GameData::Species.try_get(:BULBASAUR) rescue nil
    ret ||= (GameData::Species::DATA.is_a?(Hash) ? GameData::Species::DATA.values.first : nil)
    return ret
  end`
    );
    s.code = s.code.replace(
      /def leaders_crest_evolution\(item, qty = 1\)[\s\S]*?@evo_crest_count\[item\] \+= qty\s*\n\s*break\s*\n\s*end\s*\n\s*end\s*\n\s*end/m,
`def leaders_crest_evolution(item, qty = 1)
    sp_data = species_data
    return if !sp_data || !sp_data.respond_to?(:get_evolutions)
    sp_data.get_evolutions.each do |evo|
      if evo[1] == :LevelDefeatItsKindWithItem && evo[2] == item
        init_evo_crest_count(item)
        @evo_crest_count[item] += qty
        break
      end
    end
  end`
    );
    s.code = s.code.replace(
      /def recoil_evolution\(qty = 1\)[\s\S]*?@evo_recoil_count \+= qty\s*\n\s*break\s*\n\s*end\s*\n\s*end\s*\n\s*end/m,
`def recoil_evolution(qty = 1)
    sp_data = species_data
    return if !sp_data || !sp_data.respond_to?(:get_evolutions)
    sp_data.get_evolutions.each do |evo|
      if evo[1] == :LevelRecoilDamage || evo[1] == :LevelRecoilDamageForm0
        @evo_recoil_count = 0 if !@evo_recoil_count
        @evo_recoil_count += qty
        break
      end
    end
  end`
    );
    s.code = s.code.replace(
      /def walking_evolution\(qty = 1\)[\s\S]*?@evo_step_count \+= qty\s*\n\s*break\s*\n\s*end\s*\n\s*end\s*\n\s*end/m,
`def walking_evolution(qty = 1)
    sp_data = species_data
    return if !sp_data || !sp_data.respond_to?(:get_evolutions)
    sp_data.get_evolutions.each do |evo|
      if evo[1] == :LevelWalk
        @evo_step_count = 0 if !@evo_step_count
        @evo_step_count += qty
        break
      end
    end
  end`
    );
    s.code = s.code.replace(
      /def initialize\(species, level, owner = \$player, withMoves = true, recheck_form = true\)[\s\S]*?@form\s*=\s*species_data\.base_form/m,
`def initialize(species, level, owner = $player, withMoves = true, recheck_form = true)
    species = :BULBASAUR if species.nil? || !GameData::Species.exists?(species)
    species_data = GameData::Species.try_get(species)
    species_data ||= GameData::Species.try_get(:BULBASAUR)
    species_data ||= (GameData::Species::DATA.is_a?(Hash) ? GameData::Species::DATA.values.first : nil)
    raise "No hay datos de especies Pokémon cargados." if !species_data
    @species          = species_data.species
    @form             = species_data.base_form`
    );
    changed = true;
  }
  
  if (s.name.includes('Options') || s.code.includes('class PokemonSystem')) {
    console.log('Patching PokemonSystem in:', s.name);
    s.code = s.code.replace(
      /class PokemonSystem[\s\S]*?def initialize/m,
      `class PokemonSystem
  attr_accessor :textspeed, :battlescene, :battlestyle, :show_pokemon_on_change
  attr_accessor :sendtoboxes, :givenicknames, :frame, :textskin, :screensize
  attr_accessor :language, :runstyle, :bgmvolume, :sevolume, :textinput, :vsync
  attr_accessor :autotile_animations, :salvajes_visibles_en_ow

  def salvajes_visibles_en_ow
    @salvajes_visibles_en_ow || 0
  end

  def salvajes_visibles_en_ow=(val)
    @salvajes_visibles_en_ow = val
  end

  def salvajes_visibles_en_ow?
    (@salvajes_visibles_en_ow || 0) == 0
  end

  def method_missing(name, *args, &block)
    if name.to_s.end_with?("=")
      var = "@#{name.to_s.chop}".to_sym
      instance_variable_set(var, args[0])
    elsif name.to_s.end_with?("?")
      var = "@#{name.to_s.chop}".to_sym
      val = instance_variable_get(var)
      val == true || val == 1 || val == 0
    else
      var = "@#{name}".to_sym
      instance_variable_get(var)
    end
  end

  def respond_to_missing?(name, include_private = false)
    true
  end

  def initialize`
    );
    changed = true;
  }
  
  if (s.name.includes('Game_System') || s.code.includes('def bgm_play_internal2')) {
    console.log('Patching Game_System in:', s.name);
    s.code = s.code.replace(
      /def bgm_play_internal2\(name, volume, pitch, position, track = nil\)[\s\S]*?vol = vol\.to_i/m,
      `def bgm_play_internal2(name, volume, pitch, position, track = nil)
    vol = volume || 100
    bgm_vol = ($PokemonSystem ? ($PokemonSystem.bgmvolume || 100) : 100)
    vol = (vol * (bgm_vol / 100.0)).to_i`
    );
    s.code = s.code.replace(
      /def se_play\(se\)[\s\S]*?def se_stop/m,
      `def se_play(se)
    se = RPG::AudioFile.new(se) if se.is_a?(String)
    if se && se.name && !se.name.to_s.empty?
      vol = (se.volume || 100)
      se_vol = ($PokemonSystem ? ($PokemonSystem.sevolume || 100) : 100)
      vol = (vol * (se_vol / 100.0)).to_i
      file = se.name.to_s
      file = "Audio/SE/" + file unless file.start_with?("Audio/SE/") || file.start_with?("Audio/")
      Audio.se_play(file, vol, se.pitch || 100)
    end
  end

  def se_stop`
    );
    s.code = s.code.replace(
      /def me_play\(me\)[\s\S]*?Graphics\.frame_reset\s*\n\s*end/m,
      `def me_play(me)
    me = RPG::AudioFile.new(me) if me.is_a?(String)
    if me && me.name && !me.name.to_s.empty?
      vol = (me.volume || 100)
      bgm_vol = ($PokemonSystem ? ($PokemonSystem.bgmvolume || 100) : 100)
      vol = (vol * (bgm_vol / 100.0)).to_i
      file = me.name.to_s
      file = "Audio/ME/" + file unless file.start_with?("Audio/ME/") || file.start_with?("Audio/")
      Audio.me_play(file, vol, me.pitch || 100)
    else
      Audio.me_stop
    end
    Graphics.frame_reset
  end`
    );
    s.code = s.code.replace(
      /def bgs_play\(bgs\)[\s\S]*?Graphics\.frame_reset\s*\n\s*end/m,
      `def bgs_play(bgs)
    @playing_bgs = (bgs.nil?) ? nil : bgs.clone
    if bgs && bgs.name && !bgs.name.to_s.empty?
      vol = (bgs.volume || 100)
      se_vol = ($PokemonSystem ? ($PokemonSystem.sevolume || 100) : 100)
      vol = (vol * (se_vol / 100.0)).to_i
      file = bgs.name.to_s
      file = "Audio/BGS/" + file unless file.start_with?("Audio/BGS/") || file.start_with?("Audio/")
      Audio.bgs_play(file, vol, bgs.pitch || 100)
    else
      @bgs_position = 0
      @playing_bgs  = nil
      Audio.bgs_stop
    end
    Graphics.frame_reset
  end`
    );
    changed = true;
  }
  
  if (s.name.includes('Game_Event') || (s.code.includes('class Game_Event') && s.code.includes('def switchIsOn?'))) {
    console.log('Patching Game_Event in:', s.name);
    s.code = s.code.replace(
      /def switchIsOn\?\(id\)[\s\S]*?end\s*\n\s*def variable/m,
`def switchIsOn?(id)
    switchname = $data_system.switches[id]
    return false if !switchname
    if switchname[/^s\\:/]
      code = $~.post_match
      begin
        return eval(code, binding)
      rescue Exception => e
        begin
          return eval(code)
        rescue Exception
          return false
        end
      end
    else
      return $game_switches[id]
    end
  end

  def variable`
    );
    changed = true;
  }

  if (s.name.includes('Audio_Play') || s.code.includes('def pbResolveAudioFile')) {
    console.log('Patching Audio_Play in:', s.name);
    s.code = s.code.replace(
      /def pbResolveAudioFile\(str[\s\S]*?\nend\s*\n/m,
`def pbResolveAudioFile(str, volume = nil, pitch = nil)
  if str.is_a?(String)
    return ::RPG::AudioFile.new(str, volume || 100, pitch || 100)
  elsif str.respond_to?(:name)
    return ::RPG::AudioFile.new(str.name, volume || (str.volume rescue 100) || 100, pitch || (str.pitch rescue 100) || 100)
  end
  return ::RPG::AudioFile.new(str.to_s, volume || 100, pitch || 100)
end
`
    );
    s.code = s.code.replace(
      /def pbSEPlay\(param[\s\S]*?\nend\s*\n/m,
`def pbSEPlay(param, volume = nil, pitch = nil)
  return if !param
  name = param.is_a?(String) ? param : (param.name rescue param.to_s)
  vol  = volume || (param.volume rescue 100) || 100
  pit  = pitch || (param.pitch rescue 100) || 100
  if name && !name.to_s.empty?
    if $game_system
      $game_system.se_play(::RPG::AudioFile.new(name, vol, pit))
      return
    end
    file = name.to_s
    file = "Audio/SE/" + file unless file.start_with?("Audio/SE/") || file.start_with?("Audio/")
    Audio.se_play(file, vol, pit)
  end
end
`
    );
    changed = true;
  }
  
  if (s.name.includes('DrawText') || s.code.includes('def pbDrawShadowText')) {
    console.log('Patching DrawText in:', s.name);
    s.code = s.code.replace(
      /def pbDrawPlainText\(bitmap, x, y, width, height, string, baseColor, align = 0\)[\s\S]*?end\s*\n\s*def pbDrawShadowText/m,
`def pbDrawPlainText(bitmap, x, y, width, height, string, baseColor, align = 0)
  return if !bitmap || !string
  ts = bitmap.text_size(string)
  w = (width < 0) ? ts.width + 2 : width
  h = (height < 0) ? ts.height + 12 : [height, ts.height + 12].max
  draw_y = y - 4
  if baseColor && baseColor.alpha > 0
    bitmap.font.color = baseColor
    bitmap.draw_text(x, draw_y, w, h, string, align)
  end
end

def pbDrawShadowText`
    );
    s.code = s.code.replace(
      /def pbDrawShadowText\(bitmap, x, y, width, height, string, baseColor, shadowColor = nil, align = 0\)[\s\S]*?end\s*\n\s*def pbDrawOutlineText/m,
`def pbDrawShadowText(bitmap, x, y, width, height, string, baseColor, shadowColor = nil, align = 0)
  return if !bitmap || !string
  ts = bitmap.text_size(string)
  w = (width < 0) ? ts.width + 2 : width
  h = (height < 0) ? ts.height + 12 : [height, ts.height + 12].max
  draw_y = y - 4
  if shadowColor && shadowColor.alpha > 0
    bitmap.font.color = shadowColor
    bitmap.draw_text(x + 2, draw_y + 2, w, h, string, align)
  end
  if baseColor && baseColor.alpha > 0
    bitmap.font.color = baseColor
    bitmap.draw_text(x, draw_y, w, h, string, align)
  end
end

def pbDrawOutlineText`
    );
    s.code = s.code.replace(
      /def pbDrawOutlineText\(bitmap, x, y, width, height, string, baseColor, shadowColor = nil, align = 0\)[\s\S]*?end\s*\n\s*# Draws text/m,
`def pbDrawOutlineText(bitmap, x, y, width, height, string, baseColor, shadowColor = nil, align = 0)
  return if !bitmap || !string
  ts = bitmap.text_size(string)
  w = (width < 0) ? ts.width + 4 : width
  h = (height < 0) ? ts.height + 12 : [height, ts.height + 12].max
  draw_y = y - 4
  if shadowColor && shadowColor.alpha > 0
    bitmap.font.color = shadowColor
    bitmap.draw_text(x - 2, draw_y - 2, w, h, string, align)
    bitmap.draw_text(x, draw_y - 2, w, h, string, align)
    bitmap.draw_text(x + 2, draw_y - 2, w, h, string, align)
    bitmap.draw_text(x - 2, draw_y, w, h, string, align)
    bitmap.draw_text(x + 2, draw_y, w, h, string, align)
    bitmap.draw_text(x - 2, draw_y + 2, w, h, string, align)
    bitmap.draw_text(x, draw_y + 2, w, h, string, align)
    bitmap.draw_text(x + 2, draw_y + 2, w, h, string, align)
  end
  if baseColor && baseColor.alpha > 0
    bitmap.font.color = baseColor
    bitmap.draw_text(x, draw_y, w, h, string, align)
  end
end

# Draws text`
    );
    changed = true;
  }



  if (s.name === 'Main' || s.code.includes('def mainFunctionDebug')) {
    console.log('Restoring standard Main in:', s.name);
    s.code = `module LBDSKY
  LA_BASE_DE_SKY_VERSION = "1.0.6" # No modificar esto
end

class Scene_DebugIntro
  def main
    Graphics.transition(0)
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
    Graphics.freeze
  end
end

def pbCallTitle
  return Scene_DebugIntro.new if $DEBUG && !Settings::SHOW_TITLE_SCREEN_ON_DEBUG
  return Scene_Intro.new
end

def mainFunction
  if $DEBUG
    pbCriticalCode { mainFunctionDebug }
  else
    mainFunctionDebug
  end
  return 1
end

def mainFunctionDebug
  begin
    # Iniciar música inmediatamente al arrancar
    Audio.bgm_play("Audio/BGM/Title.ogg", 100, 100) rescue nil

    # 0. Pantalla de carga visual inmediata (para que nunca haya pantalla negra en la Switch)
    $loading_viewport = nil
    $loading_sprite = nil
    begin
      $loading_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height) rescue nil
      if $loading_viewport
        $loading_viewport.z = 999999
        $loading_sprite = Sprite.new($loading_viewport) rescue nil
        if $loading_sprite
          splash_file = pbResolveBitmap("Graphics/Titles/splash") || pbResolveBitmap("Graphics/Titles/splash1") || pbResolveBitmap("Graphics/Titles/title")
          if splash_file
            $loading_sprite.bitmap = Bitmap.new(splash_file) rescue nil
          else
            $loading_sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height) rescue nil
            $loading_sprite.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(20, 24, 35)) rescue nil
          end
          Graphics.update rescue nil
          Graphics.transition(0) rescue nil
        end
      end
    rescue Exception => e_splash
      log_compat("[Warning Splash] #{e_splash.message}") rescue nil
    end

    log_compat("[Main] 1. Cargando mensajes...") rescue puts("[Main] 1. Cargando mensajes...")
    MessageTypes.load_default_messages if FileTest.exist?("Data/messages_core.dat") rescue nil
    log_compat("[Main] 2. Ejecutando Plugins...") rescue puts("[Main] 2. Ejecutando Plugins...")
    PluginManager.runPlugins rescue nil
    log_compat("[Main] 3. Inicializando Game...") rescue puts("[Main] 3. Inicializando Game...")
    begin
      $data_system ||= load_data("Data/System.rxdata") rescue nil
      Game.initialize
    rescue Exception => eg
      log_compat("[Error Game.initialize] #{eg.class}: #{eg.message}") rescue nil
      if eg.backtrace
        eg.backtrace.each { |line| log_compat("  #{line}") rescue nil }
      end
    end
    log_compat("[Main] 4. Configurando sistema...") rescue puts("[Main] 4. Configurando sistema...")
    begin
      SaveData.initialize_bootup_values rescue nil
      Game.set_up_system
    rescue Exception => e
      log_compat("[Error set_up_system] #{e.class}: #{e.message}") rescue nil
      if e.backtrace
        e.backtrace.each { |line| log_compat("  #{line}") rescue nil }
      end
    end
    log_compat("[Main] 5. Variables globales...") rescue nil
    $data_system ||= load_data("Data/System.rxdata") rescue nil
    $PokemonSystem ||= PokemonSystem.new rescue nil
    $game_system ||= Game_System.new rescue nil
    $game_temp ||= Game_Temp.new rescue nil

    # Descartar pantalla de carga visual antes del título
    begin
      if $loading_sprite
        $loading_sprite.dispose rescue nil
        $loading_viewport.dispose rescue nil
        $loading_sprite = nil
        $loading_viewport = nil
      end
    rescue
    end

    log_compat("[Main] 6. Renderizando primer cuadro...") rescue puts("[Main] 6. Renderizando primer cuadro...")
    Graphics.update rescue nil
    Graphics.transition(10) rescue nil
    log_compat("[Main] 7. Iniciando pantalla de título...") rescue puts("[Main] 7. Iniciando pantalla de título...")
    $scene = pbCallTitle
    log_compat("[Main] 8. Escena inicial creada: #{$scene ? $scene.class : 'nil'}") rescue nil
    while $scene
      current_scene = $scene
      log_compat("[Main Loop] Iniciando escena: #{current_scene.class}") rescue nil
      begin
        current_scene.main
      rescue Exception => e
        log_compat("[SCENE CRASH] #{current_scene.class}: #{e.class} - #{e.message}\n#{e.backtrace&.join("\n")}") rescue nil
        if current_scene.is_a?(Scene_Intro)
          log_compat("[Fallback directo a PokemonLoadScreen]") rescue nil
          $scene = nil
          begin
            sscene = PokemonLoad_Scene.new
            sscreen = PokemonLoadScreen.new(sscene)
            sscreen.pbStartLoadScreen
          rescue Exception => e2
            log_compat("[Load Screen Fallback Error] #{e2.class}: #{e2.message}") rescue nil
          end
        elsif current_scene.is_a?(Scene_Map)
          log_compat("[Scene_Map crash recovery: returning to title]") rescue nil
          $scene = pbCallTitle rescue nil
        else
          $scene = nil
        end
      end
      log_compat("[Main Loop] Escena #{current_scene.class} terminada. Siguiente: #{$scene ? $scene.class : 'nil'}") rescue nil
      if $scene.nil?
        if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:game_quitting) && $game_temp.game_quitting
          break
        end
        break
      end
    end
    log_compat("[Main] 9. Fin del bucle de juego.") rescue nil
    Graphics.transition rescue nil
    pbEmergencySave rescue nil
  rescue Exception => e
    log_compat("[CRASH EN MAIN] #{e.class}: #{e.message}\n  #{e.backtrace&.join("\n  ")}") rescue nil
  end
end

loop do
  retval = mainFunction
  case retval
  when 0
    loop do
      Graphics.update
    end
  when 1
    if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:game_quitting) && $game_temp.game_quitting
      break
    end
    $scene = pbCallTitle if !$scene
  end
end
`;
    changed = true;
  }
  
  if (changed) patchedCount++;
}

console.log('Total scripts patched:', patchedCount);

// Re-encode to Marshal
const chunks = [];
chunks.push(Buffer.from([0x04, 0x08, 0x5b]));
chunks.push(writeFixnum(scripts.length));

for (let s of scripts) {
  chunks.push(Buffer.from([0x5b])); // '['
  chunks.push(writeFixnum(3));
  
  // ID
  chunks.push(Buffer.from([0x69])); // 'i'
  chunks.push(writeFixnum(s.id));
  
  // Name ('I' wrapped UTF-8 string)
  const nameBuf = Buffer.from(s.name, 'utf-8');
  chunks.push(Buffer.from([0x49, 0x22])); // 'I"'
  chunks.push(writeFixnum(nameBuf.length));
  chunks.push(nameBuf);
  chunks.push(Buffer.from([0x06, 0x3a, 0x06, 0x45, 0x54])); // 1 ivar: symbol :E => true
  
  // Code ('"' raw zlib string)
  const codeBuf = Buffer.from(s.code, 'utf-8');
  const deflated = zlib.deflateSync(codeBuf, { level: 6 });
  chunks.push(Buffer.from([0x22])); // '"'
  chunks.push(writeFixnum(deflated.length));
  chunks.push(deflated);
}

const outBuf = Buffer.concat(chunks);
console.log('Original size:', buf.length, 'New size:', outBuf.length);

if (!fs.existsSync('Data/Scripts.rxdata.bak')) {
  fs.writeFileSync('Data/Scripts.rxdata.bak', buf);
}
fs.writeFileSync('Data/Scripts.rxdata', outBuf);

if (fs.existsSync('switch_release/switch/pokemon_anil/Data')) {
  fs.writeFileSync('switch_release/switch/pokemon_anil/Data/Scripts.rxdata', outBuf);
}
if (fs.existsSync('release_ready/switch/pokemon_anil/Data')) {
  fs.writeFileSync('release_ready/switch/pokemon_anil/Data/Scripts.rxdata', outBuf);
}
if (fs.existsSync('ARCHIVOS_PARA_SWITCH/Data')) {
  fs.writeFileSync('ARCHIVOS_PARA_SWITCH/Data/Scripts.rxdata', outBuf);
}
console.log('Saved patched Scripts.rxdata successfully to Data, switch_release, release_ready, and ARCHIVOS_PARA_SWITCH!');

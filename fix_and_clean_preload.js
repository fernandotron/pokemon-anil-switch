const fs = require('fs');

let preload = fs.readFileSync('preload.rb', 'utf-8');

// If it has the duplicated header, find the second banner
const bannerMarker = '*** PRELOAD VERIFICACION BUILD 2026-ANIMATION-SMOOTH-60FPS ***';
if (preload.includes(bannerMarker)) {
  const parts = preload.split(bannerMarker);
  // Keep from the second banner downwards
  const secondPart = parts[1];
  
  // Find where the banner starts before marker
  const bannerLine = 'log_compat("=================================================================")';
  let cleaned = bannerMarker + secondPart;
  
  // Reconstruct top
  const header = `# ==============================================================================
# Nintendo Switch (Horizon OS) & Modern Ruby Compatibility Shims for mkxp-z
# ==============================================================================

# 1.0 Inicialización del Logging Eficiente
$mkxp_log_file ||= (File.open("mkxp_ruby.log", "a") rescue nil)
def log_compat(msg)
  puts msg rescue nil
  if $mkxp_log_file
    $mkxp_log_file.puts(msg) rescue nil
    $mkxp_log_file.flush rescue nil
  end
rescue
  nil
end

log_compat("=================================================================")
log_compat("[Switch Compatibility] *** PRELOAD BUILD 2026-PERFECT-60FPS-STABLE ***")
log_compat("[Switch Compatibility] Iniciando preload.rb en Nintendo Switch...")
log_compat("=================================================================")
`;

  // Remove the old banner lines from cleaned
  cleaned = cleaned.replace(bannerMarker + '\nlog_compat("[Switch Compatibility] Iniciando preload.rb en Nintendo Switch...")\nlog_compat("=================================================================")\n', '');

  preload = header + '\n' + cleaned;
}

// Now let's fix Bitmap definition in preload
const badBitmapBlock = `class ::Bitmap
  alias __switch_native_bitmap_init initialize unless method_defined?(:__switch_native_bitmap_init) rescue nil
  def initialize(*args)
    if args.length == 1 && args[0].is_a?(String) && !args[0].empty?
      resolved = nil
      if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE
        k = args[0].to_s.gsub("\\\\", "/").downcase
        k_noext = k.sub(/\\.(bmp|png|gif|jpg|jpeg)$/, "")
        resolved = $GRAPHICS_LOOKUP_TABLE[k] ||
                   $GRAPHICS_LOOKUP_TABLE[k_noext] ||
                   $GRAPHICS_LOOKUP_TABLE[k_noext + ".png"] ||
                   $GRAPHICS_LOOKUP_TABLE[k_noext + ".gif"] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/" + k] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/" + k_noext] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/" + k_noext + ".png"] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k_noext] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k_noext + ".png"] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k_noext] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k_noext + ".png"] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k_noext] ||
                   $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k_noext + ".png"]
      end
      return __switch_native_bitmap_init(resolved || args[0])
    end
    __switch_native_bitmap_init(*args)
  end

  class << self
    alias __switch_native_bitmap_new new unless method_defined?(:__switch_native_bitmap_new) rescue nil
    def new(*args)
      if args.length == 1 && args[0].is_a?(String) && !args[0].empty?
        resolved = nil
        if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE
          k = args[0].to_s.gsub("\\\\", "/").downcase
          k_noext = k.sub(/\\.(bmp|png|gif|jpg|jpeg)$/, "")
          resolved = $GRAPHICS_LOOKUP_TABLE[k] ||
                     $GRAPHICS_LOOKUP_TABLE[k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE[k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE[k_noext + ".gif"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/" + k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k_noext + ".png"]
        end
        return __switch_native_bitmap_new(resolved || args[0])
      end
      __switch_native_bitmap_new(*args)
    end
  end
end`;

const safeBitmapBlock = `unless defined?($SWITCH_BITMAP_INIT_HOOKED)
  $SWITCH_BITMAP_INIT_HOOKED = true
  class ::Bitmap
    alias __switch_native_bitmap_init initialize
    def initialize(*args)
      if args.length == 1 && args[0].is_a?(String) && !args[0].empty?
        resolved = nil
        if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE
          k = args[0].to_s.gsub("\\\\", "/").downcase
          k_noext = k.sub(/\\.(bmp|png|gif|jpg|jpeg)$/, "")
          resolved = $GRAPHICS_LOOKUP_TABLE[k] ||
                     $GRAPHICS_LOOKUP_TABLE[k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE[k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE[k_noext + ".gif"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/" + k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + k_noext + ".png"] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k_noext] ||
                     $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + k_noext + ".png"]
        end
        return __switch_native_bitmap_init(resolved || args[0])
      end
      __switch_native_bitmap_init(*args)
    end
  end
end`;

if (preload.includes(badBitmapBlock)) {
  preload = preload.replace(badBitmapBlock, safeBitmapBlock);
  console.log('Replaced badBitmapBlock with safeBitmapBlock');
} else {
  console.log('Warning: badBitmapBlock exact match not found, inspecting...');
}

// Make sure Audio hook is safe
preload = preload.replace(
  /module ::Audio\s+class << self\s+alias __switch_native_bgm_play bgm_play unless method_defined\?\(:\__switch_native_bgm_play\) rescue nil/,
  `module ::Audio
  class << self
    unless method_defined?(:__switch_native_bgm_play)
      alias __switch_native_bgm_play bgm_play rescue nil
      alias __switch_native_bgs_play bgs_play rescue nil
      alias __switch_native_me_play me_play rescue nil
      alias __switch_native_se_play se_play rescue nil
    end`
);
preload = preload.replace(
  /alias __switch_native_bgs_play bgs_play unless method_defined\?\(:\__switch_native_bgs_play\) rescue nil\n\s*alias __switch_native_me_play me_play unless method_defined\?\(:\__switch_native_me_play\) rescue nil\n\s*alias __switch_native_se_play se_play unless method_defined\?\(:\__switch_native_se_play\) rescue nil\n/,
  ''
);

fs.writeFileSync('preload.rb', preload, 'utf-8');
console.log('preload.rb successfully cleaned and updated!');

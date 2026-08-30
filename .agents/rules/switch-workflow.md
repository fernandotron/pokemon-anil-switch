---
description: Rule to always execute switch-port-verifier after making code changes
globs: "**/*.rb, **/*.js, **/*.json, **/*.txt"
always_on: true
---

# Nintendo Switch Port Workflow Rule

Whenever any modification or fix is made to scripts, plugins, audio, graphics, or configuration files in this repository:

1. **Ruby & Syntax Check**: Execute `node check_syntax.js` and `node validate_ruby.js` to ensure 100% syntax validity.
2. **Package Rxdata**: Execute `node patch_scripts.js` and `node patch_plugins_complete.js` to serialize all changes into `Data/Scripts.rxdata` and `Data/PluginScripts.rxdata`.
3. **Deploy to Switch Distribution**: Execute `node build_and_deploy_all.js` to update `switch_release/switch/pokemon_anil/` and `ARCHIVOS_PARA_SWITCH/`.
4. **RAM Preload & Non-blocking Audio**: Always ensure audio and graphics are indexed and resolved via RAM lookup tables (`$AUDIO_LOOKUP_TABLE`, `$GRAPHICS_LOOKUP_TABLE`, `$OW_SPRITE_CACHE`) without synchronous blocking disk I/O.
5. **Touch Compatibility**: Ensure all newly added or modified UI components support both controller inputs and `SwitchTouch` screen interactions.

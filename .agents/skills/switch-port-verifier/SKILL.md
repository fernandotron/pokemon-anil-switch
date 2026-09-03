---
name: switch-port-verifier
description: >-
  Verifies, validates, and packages Pokémon Añil scripts, plugins, audio, graphics,
  and configurations for flawless execution on Nintendo Switch via mkxp-z.
  Use this skill whenever code is modified or before testing/deploying a release.
---

# Switch Port Verifier (Nintendo Switch / mkxp-z)

This skill automates and documents the complete verification, validation, and packaging workflow for Pokémon Añil running on Nintendo Switch via `mkxp-z`.

---

## Workflow Steps

### 1. Ruby 3 & Syntax Validation
Run the syntax checker to ensure no unescaped strings, syntax errors, or mismatched `end` statements exist in `preload.rb`, base scripts, or plugins:

```powershell
node check_syntax.js
node validate_ruby.js
```

**Checklist:**
- [ ] No `SyntaxError` in `preload.rb`.
- [ ] No missing or extra `end` keywords.
- [ ] Safe navigation operator (`&.`) and keyword arguments compatibility verified for Ruby 3.x.

---

### 2. Audio & RAM Preload Verification
Verify that all sound effects, interface audios, cries, and BGMs are resolved via fast RAM lookup tables without synchronous blocking disk I/O on FAT32 MicroSD:

**Checklist:**
- [ ] `$AUDIO_LOOKUP_TABLE` indexes lowercase and normalized audio paths in `preload.rb`.
- [ ] Common UI SEs (`GUI menu open`, `GUI sel decision`, `Player jump`, `Door enter`, `Battle ball drop`, etc.) are pre-warmed via `warmup_audio_buffers!`.
- [ ] Overworld cries (`pbPlayCryOnOverworld`) and follower graphics are cached in RAM (`$OW_SPRITE_CACHE`) to prevent frame drops during wild encounter spawning.

---

### 3. Following Pokémon EX Integrity
Verify that the follower Pokémon system behaves correctly:

**Checklist:**
- [ ] `FollowerSprites#refresh` contains no circular calls to `FollowingPkmn.refresh(false)`.
- [ ] `FollowingPkmn.refresh(true)` plays Pokéball animations (`ANIMATION_COME_OUT = 30` when summoned, `ANIMATION_COME_IN = 29` when recalled).
- [ ] `FollowingPkmn.change_sprite` does not invoke `$game_temp.followers.update_events` unless the sprite or follower data actually changed.
- [ ] `Game_FollowingPkmn#follow_leader` smoothly tracks the player's position on all terrain tags.

---

### 4. Serialization & Rxdata Packaging
Compile and inject all fresh scripts and plugins into `Data/Scripts.rxdata` and `Data/PluginScripts.rxdata`:

```powershell
node patch_scripts.js
node patch_plugins_complete.js
```

---

### 5. Final Distribution Deployment
Synchronize and deploy all updated files into the Switch distribution directories:

```powershell
node build_and_deploy_all.js
```

**Verification:**
- Confirm `switch_release/switch/pokemon_anil/` contains updated `.rxdata`, `preload.rb` and `Game.ini`.
- The `.nro` is NOT built by the Node pipeline. `build_and_deploy_all.js` only copies the base
  binary versioned in the repo, and writes it under both names (`port.nro` and `pokemon_anil.nro`)
  so whichever one the homebrew launcher opens is the same file. Any change under `mkxp-z/` or in
  `patches/mkxp-z-switch.patch` requires the CI artifact `PokemonAnil-Switch-NRO`, copied over the
  deployed files **after** running the deploy — otherwise the deploy overwrites it and the change
  silently never reaches the console.
- Confirm `ARCHIVOS_PARA_SWITCH/` contains the synchronized files for user SD card transfer.

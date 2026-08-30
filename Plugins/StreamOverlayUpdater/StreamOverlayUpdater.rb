class PokemonGlobalMetadata
	attr_accessor :overlay, :overlay_gifs
	alias initialize_overlay initialize
	def initialize
		initialize_overlay
		@overlay = Array.new(Overlay::Config::MAX_PARTY_SIZE)
		@overlay_gifs = Array.new(Overlay::Config::MAX_PARTY_SIZE, Overlay.get_empty_value)
	end
end

class PokemonSystem
	attr_accessor :streamer_mode
	attr_accessor :streamer_mode_icon_type

	alias initialize_overlay initialize
	def initialize	
		initialize_overlay
		@streamer_mode = 1
		@streamer_mode_icon_type = 0
	end
end

MenuHandlers.add(:options_menu, :overlay_updater, {
  "name"        => _INTL("Modo Streamer"),
  "order"       => 250,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Exporta tu equipo en tiempo real en la carpeta pokes_layout."),
  "get_proc"    => proc { next $PokemonSystem.streamer_mode },
  "set_proc"    => proc { |value, _scene| 
			$PokemonSystem.streamer_mode = value
			Overlay.check_removed if $PokemonSystem.streamer_mode == 0
	 }
})

MenuHandlers.add(:options_menu, :overlay_updater_type, {
  "name"        => _INTL("Graficos streamer"),
  "order"       => 251,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sprites"), _INTL("Iconos")], #_INTL("Arte"), #_INTL("GIFs")],
  "description" => _INTL("Elige el tipo de iconos a usar al activar el modo streamer."),
  "get_proc"    => proc { next $PokemonSystem.streamer_mode_icon_type },
  "set_proc"    => proc { |value, _scene| 
		$PokemonSystem.streamer_mode_icon_type = value
		Overlay.check_removed
 }
})

module Overlay

	module Config
		ONLY_UPDATE_ON_SAVE = false
		USE_POKEAPI_FOR_SPRITES = false
		# Si esto está en false se usaran los sprites del juego, si usas sprites animados se usará el primer frame de la animación
		USE_GIF = false
		GIF_FOLDER = "gifs"
		LAYOUT_FOLDER = "pokes_layout"
		STANDARD_WIDTH = 128
		STANDARD_HEIGHT = 128
		MAX_PARTY_SIZE = 6
		EMPTY_SPRITE_NAME = "empty"
		DEBUG_MODE = false
	end

	# Logging module for better debugging and error reporting
	module Logger
		def self.info(message)
			puts "[StreamOverlay] INFO: #{message}" if Config::DEBUG_MODE
		end
		
		def self.error(message)
			puts "[StreamOverlay] ERROR: #{message}"
		end
		
		def self.debug(message)
			puts "[StreamOverlay] DEBUG: #{message}" if Config::DEBUG_MODE
		end
	end

	# Error handling helpers
	def self.safe_file_operation
		yield
		true
	rescue StandardError => e
		Logger.error("File operation failed: #{e.message}")
		false
	end

	def self.safe_bitmap_operation(bitmap)
		yield bitmap
	rescue StandardError => e
		Logger.error("Bitmap operation failed: #{e.message}")
		nil
	ensure
		bitmap&.dispose
	end

	def self.with_temporary_sprite(sprite_class, *args)
		sprite = sprite_class.new(*args)
		sprite.visible = false
		yield sprite
	rescue StandardError => e
		Logger.error("Sprite operation failed: #{e.message}")
		nil
	ensure
		sprite&.dispose if sprite.respond_to?(:dispose)
	end

	# Caching for performance improvements
	@sprite_cache = {}
	@extension_cache = nil

	def self.clear_cache
		@sprite_cache.clear
		@extension_cache = nil
	end

	def self.cached_sprite_filename(pokemon)
		return nil unless pokemon
		cache_key = "#{pokemon.species}_#{pokemon.form}_#{pokemon.gender}_#{pokemon.shiny?}_#{pokemon.egg?}"
		@sprite_cache[cache_key] ||= calculate_sprite_filename(pokemon)
	end

	def self.calculate_sprite_filename(pokemon)
		if pokemon&.egg?
			GameData::Species.egg_sprite_filename(pokemon.species, pokemon.form)
		else
			GameData::Species.front_sprite_filename(pokemon.species, pokemon.form, pokemon.gender, pokemon.shiny?)
		end
	end

	# Validation helpers
	def self.valid_overlay_conditions?
		!$joiplay && $PokemonSystem.streamer_mode == 0 && $player
	end

	def self.validate_option(option)
		raise ArgumentError, "Invalid option format" unless option.is_a?(Array) && option.length == 2
		raise ArgumentError, "Invalid index" unless option[0].between?(0, Config::MAX_PARTY_SIZE - 1)
	end

	def self.ensure_overlay_directory
		safe_file_operation do
			Dir.mkdir(Config::LAYOUT_FOLDER) unless Dir.exist?(Config::LAYOUT_FOLDER)
		end
	end

	def self.initialize_overlay_arrays
		$PokemonGlobal.overlay ||= Array.new(Config::MAX_PARTY_SIZE)
		$PokemonGlobal.overlay_gifs ||= Array.new(Config::MAX_PARTY_SIZE, get_empty_value)
	end

	module_function
	def switch_places(option1, option2=nil)
		return unless valid_overlay_conditions?
		
		begin
			validate_option(option1)
			validate_option(option2) if option2
		rescue ArgumentError => e
			Logger.error("Invalid parameters in switch_places: #{e.message}")
			return
		end
		
		ensure_overlay_directory
		initialize_overlay_arrays
		
		# Update first pokemon
		update_sprite_at_index(option1[1], option1[0])
		
		# Update second pokemon if provided
		if option2
			update_sprite_at_index(option2[1], option2[0])
		end
	end

	def get_extension
		@extension_cache ||= $PokemonSystem.streamer_mode_icon_type == 3 ? '.gif' : '.png'
	end

	def get_empty_value
		File.join(Config::LAYOUT_FOLDER, Config::EMPTY_SPRITE_NAME + get_extension)
	end

	# Shared method for updating sprites at specific indices
	def update_sprite_at_index(pokemon, index)
		return unless index.between?(0, Config::MAX_PARTY_SIZE - 1)
		
		extension = get_extension
		filename = File.join(Config::LAYOUT_FOLDER, "poke#{index + 1}")
		gif_path = update_image(pokemon, filename, extension)
		
		$PokemonGlobal.overlay[index] = pokemon
		$PokemonGlobal.overlay_gifs[index] = gif_path
		
		Logger.debug("Updated sprite at index #{index} for #{pokemon&.species || 'empty slot'}")
	end

	def clear_slot(index)
		return unless index.between?(0, Config::MAX_PARTY_SIZE - 1)
		
		extension = get_extension
		target_file = File.join(Config::LAYOUT_FOLDER, "poke#{index + 1}#{extension}")
		
		safe_file_operation do
			File.copy(get_empty_value, target_file) if File.exist?(get_empty_value)
		end
		
		$PokemonGlobal.overlay[index] = nil
		$PokemonGlobal.overlay_gifs[index] = nil
		
		Logger.debug("Cleared slot #{index}")
	end

	def should_update_sprite?(pokemon, index)
		return false unless index < $PokemonGlobal.overlay.length && index < $PokemonGlobal.overlay_gifs.length
		
		current_poke = $PokemonGlobal.overlay[index]
		current_gif = $PokemonGlobal.overlay_gifs[index]
		
		# Check if pokemon changed or gif is missing
		!(current_poke.is_a?(Pokemon) && 
		  current_poke.species == pokemon.species && 
		  current_poke.form == pokemon.form && 
		  current_poke.egg? == pokemon.egg? && 
		  current_gif)
	end

	def update_party_sprites
		$player.party.each_with_index do |pokemon, index|
			if should_update_sprite?(pokemon, index)
				update_sprite_at_index(pokemon, index)
			end
		end
	end

	def clear_empty_slots
		($player.party.length...Config::MAX_PARTY_SIZE).each do |index|
			clear_slot(index)
		end
	end

	def check_removed
		return unless valid_overlay_conditions?
		
		Logger.debug("Checking for removed/changed pokemon")
		
		# Initialize defaults for system settings
		$PokemonSystem.streamer_mode ||= 1
		$PokemonSystem.streamer_mode_icon_type ||= 1
		
		ensure_overlay_directory
		initialize_overlay_arrays
		
		update_party_sprites
		clear_empty_slots
	end

	def update_image(pokemon, target_file, extension)
		return nil if $joiplay
		
		if !pokemon
			safe_file_operation do
				File.copy(get_empty_value, target_file + extension) if File.exist?(get_empty_value)
			end
			return nil
		end
		
		Logger.debug("Updating image for #{pokemon.species}")
		
		# Skip PokeAPI for now to avoid threading issues
		# if Overlay::USE_POKEAPI_FOR_SPRITES && !pokemon.egg?
		#	begin			
		#		temp_sprite_path = PokeAPI.get_image(pokemon)
		#		
		#		if temp_sprite_path && File.exist?(temp_sprite_path)
		#			File.copy(temp_sprite_path, target_file + extension)
		#			Logger.info("Using PokeAPI sprite for #{pokemon.species}")
		#			File.delete(temp_sprite_path) if File.exist?(temp_sprite_path)
		#			return target_file
		#		else
		#			Logger.info("PokeAPI sprite not available for #{pokemon.species}, using local sprites")
		#		end
		#	rescue => e
		#		Logger.error("Error getting PokeAPI sprite for #{pokemon.species}: #{e.message}")
		#		Logger.info("Falling back to local sprites")
		#	end
		# end

		return get_png_from_spritesheet(pokemon, target_file + extension) if PluginManager.installed?("[DBK] Animated Pokémon System")
		
		# For regular sprites, resize them to standard size too
		filename = cached_sprite_filename(pokemon)
		
		if filename && FileTest.exist?(filename)
			# Load and resize to standard size
			if resize_sprite_to_standard(filename, target_file + extension)
				Logger.debug("Successfully updated sprite for #{pokemon.species}")
				return filename
			else
				Logger.error("Failed to resize sprite for #{pokemon.species}")
			end
		else
			Logger.error("Sprite file not found for #{pokemon.species}")
		end
		
		# Fallback to empty sprite
		safe_file_operation do
			File.copy(get_empty_value, target_file + extension) if File.exist?(get_empty_value)
		end
		nil
	end

	# Helper method to resize any sprite to standard size
	def resize_sprite_to_standard(source_file, target_file)
		return false unless FileTest.exist?(source_file)
		
		safe_file_operation do
			source_bitmap = nil
			final_bitmap = nil
			
			begin
				source_bitmap = Bitmap.new(source_file)
				final_bitmap = Bitmap.new(Config::STANDARD_WIDTH, Config::STANDARD_HEIGHT)
				final_bitmap.stretch_blt(
					Rect.new(0, 0, Config::STANDARD_WIDTH, Config::STANDARD_HEIGHT), 
					source_bitmap, 
					Rect.new(0, 0, source_bitmap.width, source_bitmap.height)
				)
				final_bitmap.save_to_png(target_file)
				true
			rescue StandardError => e
				Logger.error("Failed to resize sprite: #{e.message}")
				false
			ensure
				source_bitmap&.dispose
				final_bitmap&.dispose
			end
		end
	end

	def get_png_from_spritesheet(pokemon, target_file)
		Logger.debug("Getting PNG from spritesheet for #{pokemon.species}")
		
		if $PokemonSystem.streamer_mode_icon_type == 1
			return with_temporary_sprite(PokemonIconSprite, pokemon) do |sprite|
				safe_bitmap_operation(sprite.bitmap.copy) do |bitmap_aux|
					frame_size = bitmap_aux.height
					
					safe_bitmap_operation(Bitmap.new(frame_size, frame_size)) do |cropped_bitmap|
						cropped_bitmap.blt(0, 0, bitmap_aux, Rect.new(0, 0, frame_size, frame_size))
						
						safe_bitmap_operation(Bitmap.new(Config::STANDARD_WIDTH, Config::STANDARD_HEIGHT)) do |final_bitmap|
							final_bitmap.stretch_blt(
								Rect.new(0, 0, Config::STANDARD_WIDTH, Config::STANDARD_HEIGHT), 
								cropped_bitmap, 
								Rect.new(0, 0, frame_size, frame_size)
							)
							final_bitmap.save_to_png(target_file)
							target_file
						end
					end
				end
			end
		else
			return with_temporary_sprite(PokemonSprite) do |sprite|
				sprite.setPokemonBitmap(pokemon)
				bitmap = sprite.iconBitmap
				bitmap.to_frame(0)
				
				safe_bitmap_operation(bitmap.copy) do |bitmap_aux|
					safe_bitmap_operation(Bitmap.new(Config::STANDARD_WIDTH, Config::STANDARD_HEIGHT)) do |final_bitmap|
						final_bitmap.stretch_blt(
							Rect.new(0, 0, Config::STANDARD_WIDTH, Config::STANDARD_HEIGHT), 
							bitmap_aux, 
							Rect.new(0, 0, bitmap_aux.width, bitmap_aux.height)
						)
						final_bitmap.save_to_png(target_file)
						target_file
					end
				end
			end
		end
	end
end

unless Overlay::Config::ONLY_UPDATE_ON_SAVE
	class PokemonPartyScreen
		alias pbSwitch_overlay pbSwitch
		def pbSwitch(oldid, newid)
			pbSwitch_overlay(oldid, newid)
			Overlay.switch_places([newid, @party[newid]], [oldid, @party[oldid]]) if oldid != newid
		end
	end

	# class PokemonStorage
	# 	alias pbCopy_overlay pbCopy
	# 	def pbCopy(boxDst, indexDst, boxSrc, indexSrc)
	# 		pbCopy_overlay(boxDst, indexDst, boxSrc, indexSrc)
	# 		Overlay.check_removed if boxDst==-1
	# 	end
	# end

	class PokemonStorage
		alias pbMove_overlay pbMove
		def pbMove(boxDst, indexDst, boxSrc, indexSrc)
			if pbMove_overlay(boxDst, indexDst, boxSrc, indexSrc)
				Overlay.check_removed 
			end
		end

		alias pbMoveCaughtToBox_overlay pbMoveCaughtToBox
		def pbMoveCaughtToBox(pkmn, box)
			prev_length = $player.party.length
			if pbMoveCaughtToBox_overlay(pkmn, box)
				if $player.party.length > prev_length && prev_length < 6
					index = $player.party.length - 1
					Overlay.switch_places([index, pokemon])
				elsif prev_length == 6
					Overlay.check_removed
				end
			end
		end
	end

	class PokemonStorageScene
		alias pbSwap_overlay pbSwap
		def pbSwap(selected, _heldpoke)
			pbSwap_overlay(selected, _heldpoke)
			Overlay.switch_places([selected[1], _heldpoke]) if selected[0] == -1
		end

		alias pbPlace_overlay pbPlace
		def pbPlace(selected, _heldpoke)
			pbPlace_overlay(selected, _heldpoke)
			selected[0] == -1 ? Overlay.switch_places([selected[1], _heldpoke]) : Overlay.check_removed
		end
	end

	class PokemonStorageScreen
		alias pbPlace_overlay pbPlace
		def pbPlace(selected)
			pbPlace_overlay(selected)
			box=selected[0]
			Overlay.check_removed if box == -1
		end

		alias pbWithdraw_overlay pbWithdraw
		def pbWithdraw(selected, heldpoke)
			Overlay.check_removed if pbWithdraw_overlay(selected, heldpoke)
		end
	end

	class PokemonEvolutionScene
		alias pbEvolution_overlay pbEvolution
		def pbEvolution(cancancel = true)
			pbEvolution_overlay(cancancel)
			Overlay.check_removed
		end
	end

	alias pbStorePokemon_overlay pbStorePokemon
	def pbStorePokemon(pokemon)
		prev_length = $player.party.length
		pbStorePokemon_overlay(pokemon)
		if $player.party.length > prev_length && prev_length < 6
			index = $player.party.length - 1
			Overlay.switch_places([index, pokemon])
		elsif prev_length == 6
			Overlay.check_removed
		end
	end

	module Battle::CatchAndStoreMixin
		alias pbStorePokemon_overlay pbStorePokemon
		def pbStorePokemon(pokemon)
			prev_length = $player.party.length
			pbStorePokemon_overlay(pokemon)
			if $player.party.length > prev_length && prev_length < 6
			index = $player.party.length - 1
			Overlay.switch_places([index, pokemon])
			elsif prev_length == 6
				Overlay.check_removed
			end
		end
	end

	alias pbHatch_overlay pbHatch
	def pbHatch(pokemon)
		pbHatch_overlay(pokemon)
		Overlay.check_removed
	end

	class PokemonEggHatch_Scene
		alias pbMain_overlay pbMain
		def pbMain
			pbMain_overlay
			Overlay.check_removed
		end 
	end

	class PokemonLoadScreen
		alias pbStartLoadScreen_overlay pbStartLoadScreen
		def pbStartLoadScreen
			pbStartLoadScreen_overlay
			Overlay.check_removed
		end
	end
end

class PokemonSaveScreen
	alias doSave_overlay doSave if method_defined?(:doSave)
	def doSave(slot)
		ret = doSave_overlay(slot)
		Overlay.check_removed
		return ret
	end
end

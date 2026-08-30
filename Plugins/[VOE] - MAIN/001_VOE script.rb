 #=====================================================================#
  #                                                                    #
  #   Visible Overworld Wild Encounters V20.0.0.4 for PEv20 and PEv21  #
  #                         - by derFischae (Credits if used please)   #
  #                                                                    #
  #====================================================================#

# This script is for Pokémon Essentials v20, v20.1, v21 and v21.1 (for short PEv20 and PEv21). UPDATED TO VERSION 20.0.0.4.

# As in Pokemon Let's go Pikachu/Eevee or Pokemon Shield and Sword wild encounters
# pop up on the overworld, they move around and you can start the battle with
# them simply by moving to the pokemon. Clearly, you also can omit the battle
# by circling around them.


#===============================================================================
#            FEATURES
#===============================================================================

#  [*] Easy Install as Plugin
#  [*] see the pokemon on the overworld before going into battle
#  [*] no forced battling against overworld encounters
#  [*] Supports individual sprites for shiny, female and alternative forms
#  [*] plays the pokemon cry while spawning
#  [*] Overworld pokemon will despawn after some steps
#  [*] you can have instant wild battle and overworld spawning at the same time and set the propability of that in percentage
#  [*] In caves, pokemon don't spawn on impassable Rock-Tiles, which have the Tile-ID 4 
#  [*] In water, pokemon won't spawn above other tiles, which made them stuck or walk on ground
#  [*] See "advanced features" and "additional features by add-ons" below for more (e.g. additional animations...)

# ADVANCED FEATURES [/b]
#  [*] Set the size of the area around the player where pokemon can spawn
#  [*] Choose whether encounters occure on all terrains or only on the terrain of the player
#  [*] Allow or forbid water pokemon to spawn on border
#  [*] Set movement of overworld pokemon depending on its properties
#  [*] Choose whether you can battle water pokemon while not surfing or not
#  [*] set steps a pokemon remains on map before despawning depending on pokemon properties 
#  [*] You can check during the events :on_wild_species_chosen, :on_wild_pokemon_created, :on_calling_wild_battle ... if you are battling a spawned pokemon with the global variable $PokemonGlobal.battlingSpawnedPokemon
#  [*] You can check during the events :on_wild_species_chosen and :on_wild_pokemon_created if the pokemon is created for spawning on the map or created for a different reason with the Global variable $PokemonGlobal.creatingSpawningPokemon
#  [*] If you want to add a procedure that modifies a pokemon only for spawning but not before battling then you can use the Event :on_wild_pokemon_created_for_spawning

# ADDITIONAL FEATURES BY ADD-ONS (for PEv19, might be outdated, but feel free to test):
#  [*] Aggressive Encounters Add-On
#    [*] introduces aggressive encounters, which are pokemon that chase the player after spawning
#    [*] aggressive encounters may only start to chase if the player comes them to close
#    [*] set the move speed, move frequency and move type of aggressive pokemon
#    [*] aggressive ecounters are restricted to player movements
#    [*] add animations to aggressive encounters. See Additional Animations -Add On and TrankerGolD's animations for aggressive encounters
#        at https://www.pokecommunity.com/showpost.php?p=10395100&postcount=383 to include spawning animations in your game
#  [*] Additional Animations Add-On
#    [*] manage different appear animations of overworld spawning encounters depending on encounter type and pokemon properties
#    [*] Play animations while PokeEvent is visible on screen, such as a shiny animation
#    [*] See also the animations by TrankerGolD for aggressive encounters, water encounters, and shiny encounters https://www.pokecommunity.com/showpost.php?p=10395100&postcount=383
#  [*] Different Spawn And Normal Encounters (like in Pokemon Sword/Shield) Add-On
#    [*] Introduces Overworld Encounter Types you can set in your encounters.txt PBS-file.
#    [*] This allows you to define different encounters for overworld spawning and instant battling on the same map.
#  [*] Restrict Movement Add-On
#    [*] Overworld spawned Grass/Water/Sand/etc encounters move only on Grass/Water/Sand tiles and not leave there terrain
#    [*] You can activate and deactivate the restriction by setting the parameter RESTRICT_MOVEMENT in the settings section of this add-on
#  [*] Max Spawn Add-On
#    [*] Define a maximal limit of spawned pokemon on the overworld at the same time.
#    [*] After reaching that limit MAX_SPAWN no pokemon will spawn until another pokemon despawned.
#  [*] Additional Despawn Methods Add-On
#    [*] Choose to remove PokeEvent distanced on screen from the player with REMOVE_DISTANCED
#    [*] The distance (steps) is edited in DISTANCE_VANISH and DISTANCE_VANISH_SHINY
#    [*] Remove by time chronometer with REMOVE_PROLONGED
#    [*] Use your own overworld spawn chance in VISIBLE_ENCOUNTER_PROBABILITY
# [*] Own Minimum Spawn Chance
#    [*] The Spawn probability of the first encounter and later ones are similar.
#    [*] Spawning does not interact with the encounter chance for normal encounters.
#    [*] Increase the average spawning time of pokemon by setting MAX_ENCOUNTER_REDUCED larger than zero in the settings section of this script
#  [*] Fixed Spawn Probability Add-On
#    [*] Define your own overworld spawn chance in Percentage
#    [*] Spawn chance becomes independent from the default PEv19.1 encounter chance calculator
#  [*] Variable Spawn/Normal Encounter Proportion During Game  
#    [*] You can change the percentage between overworld spawning and normal encounters in story driven events during playthrough
#    [*] in Percentage, from only normal encounters to only spawning encounters
#  [*] Automatic Spawning Add-On
#    [*] Choose whether pokemon spawn automatically or only while moving the player
#    [*] Set the speed of automatic spawning
#  [*] Randomized Spawning Add-On
#    [*] It will randomize overworld encounters
#  [*] Ditto Transform Add-On
#    [*] Like in Pokemon Go, transformable Pokemon such as Ditto get the overworld appearence of different species
#    [*] Choose in settings if completely random, set by a list of candidates or set by the map encounters
#  [*] Remove Poke Events on load/save/transfer Add-On
#    [*] Remove overworld encounters on load/save and on map transfer
#  [*] Overworld Lavender Town Ghosts Add-On
#    [*] Shows ghost sprite for overworld encounters
#    [*] full functionality when using additionally the original Lavender Town Ghosts Plugin https://www.pokecommunity.com/threads/lavender-town-ghosts-v18-1.441236/
#    [*] You need to put a graphic, named "ghost.png", in your "/Graphisc/Characters/" folder of your project. This graphic is not provided here, but maybe you can easily find some resource, for example search for "shiny missingNo [Ghost Form]".


#===============================================================================
#            INSTALLATION
#===============================================================================

# Installation as simple as it can be.
# [1] Add Graphics: Either get the resources from Gen 8 Project https://reliccastle.com/resources/670/
#  and install the "Graphics/Characters" folder in your game file system.
#  Or you place your own sprites for your pokemon/fakemon with the right names in your "\Graphics\Characters\Follower" folder and your shiny sprites in your "\Graphics\Characters\Follower shiny" folder. 
#  The right name of sprites is:
#    usual form     - SPECIES.png   where SPECIES is the species name in capslock (e.g. PIDGEY.png)
#    alternate form - SPECIES_n.png where n is the number of the form (e.g. PIKACHU_3.png)
#    female form    - SPECIES_female.png or SPECIES_n_female (e.g. PIDGEY_female.png or PIKACHU_3_female.png)
# [2] Add Script: Follow this link https://github.com/VisibleOverworldWildEncounters/V20 and copy the folder "Visible Overworld Wild Encounters - Script" to your "/plugins/" folder.
# [3] [optional] Change Settings: Open the script file in the folder and change the parameters in the settings section therein as you like. Details descriptions about the parameters can be found there as well. 
# [4] [optional] Install Add-Ons (the folders under "/optional/" in the github repository): There are a lot of Add-Ons and parameter settings for your personal optimal solution. So, Copy Add-Ons in your "/plugins/" folder and edit parameters in settings of that Add-Ons to your liking. Some Add-Ons are incompatible to each other and some Add-On and parameter combinations can produce lag, e.g. a high spawning rate without a spawning cap, or e.g. "NO_OF_CHOSEN_TILES=0" (or too high) when having other scripts like Pokemon Following. So, do not simply include all folders.
# [5] Enjoy!

#===============================================================================
#             HELP AND MORE
#===============================================================================

# If you need help, found a bug or search for more modifications then go to
# https://www.pokecommunity.com/showthread.php?t=429019


#===============================================================================
#             CHANGELOG
#===============================================================================

# NEW FEATURES FROM VERSION 20.0.0.4 FOR PEv20:
# - new add on to restrict movement of spawned pokemon to there starting terrain. I.e. grass encounters stay on grass.
# NEW FEATURES FROM VERSION 20.0.0.3 FOR PEv20:
#  - removed bug concerning battling water encounters from shore in PEv20
# NEW FEATURES FROM VERSION 20.0.0.2 FOR PEv20:
#  - removed bug concerning renaming $MapFactory in PEv20
# NEW FEATURES FROM VERSION 20.0.0.1 FOR PEv20:
#  - updated version 19.1.0.4 to make it compatible with PEv20
# NEW FEATURES FROM VERSION 19.1.0.4 FOR PEv19:
#  - rearranged aggressive encounters as an Add On
# NEW FEATURES FROM VERSION 19.1.0.1 FOR PEv19:
#  - bug fix concerning roaming pokemon
#  - included an easy way to set the steps a pokemon remains on map before despawning depending on pokemon properties 
#  - rearranged features of previous version as add-ons, including
#     - trigger different appear animations depending on encounter type, shinyness
#     - shiny animation while PokeEvent is visible on screen
#     - stop more pokemon from spawning with the MAX_SPAWN parameter
#     - choose wether remove distanced spawned pokemon or not with REMOVE_DISTANCED parameter
#     - choose wether remove by time chronometer or not with REMOVE_PROLONGED
#     - added to add your own overworld encounter chance with VISIBLE_ENCOUNTER_PROBABILITY
# NEW FEATURES FROM VERSION 19.0.10 FOR PEv19:
#  - fixed water pokemon spawning in platform above water tile
#  - water pokemon won't appear in the border
#  - choose wether battling water pokemon from ground or not with BATTLE_WATER_ONGROUND parameter
#  - stop more pokemon from spawning with the MAX_SPAWN parameter
#  - choose wether remove distanced spawned pokemon or not with REMOVE_DISTANCED parameter
#  - shiny animation while PokeEvent is visible on screen
#  - choose wether remove by time chronometer or not with REMOVE_PROLONGED
#  - added to add your own chance with VISIBLE_ENCOUNTER_PROBABILITY
#  - aggressive encounters restricted to player movements
# NEW FEATURES FROM VERSION 19.0.9 FOR PEv19:
#  - updated script to work with PEv19.1
#  - used $game_temp.encounter_type to trigger diferent appear animations
#  - added alternative stepcount before vanishining for shiny pokemon
# NEW FEATURES FROM VERSION 18.0.8 FOR PEv18:
#  - tiny bug fix for $game_temp.encounter_type
# NEW FEATURES FROM VERSION 18.0.7 FOR PEv18:
#  - removed a bug concerning changing the standard form when goining into battle
# NEW FEATURES FROM VERSION 18.0.6 FOR PEv18:
#   - (hopefully) removed a rare crash concerning character_sprites
# NEW FEATURES FROM VERSION 2.0.5 FOR PEv18:
#   - removed bug that makes all water encounter vanish
# NEW FEATURES FROM VERSION 2.0.4 FOR PEv18:
#   - encounters dont spawn on impassable tiles in caves
# NEW FEATURES FROM VERSION 2.0.3 FOR PEv18:
#   - poke radar works as usual
# NEW FEATURES FROM VERSION 2.0.2 FOR PEv18:
#   - added new global variable $PokemonGlobal.creatingSpawningPokemon to check during the event @@OnWildPokemonCreate if the pokemon is created for spawning on the map or created for a different reason
# UPSCALED FEATURES FROM VERSION 2.0.1 FOR PEv17.2:
#   - less lag
#   - supports sprites for alternative forms of pokemon
#   - supports sprites for female/male/genderless pokemon
#   - bug fixes for roaming encounter and double battles
#   - more options in settings
#   - roaming encounters working correctly
#   - more lag reduction 
#   - included automatic spawning of pokemon, i.e. spawning without having to move the player
#   - included vendilys rescue chain, i. e. if pokemon of the same species family spawn in a row and will be battled in a row, then you increase the chance of spawning
#     an evolved pokemon of that species family. Link: https://www.pokecommunity.com/showthread.php?t=415524
#   - removed bug occuring after fainting against wild overworld encounter
#   - for script-developers, shortened the spawnPokeEvent method for better readablitiy
#   - removed bugs from version 1.9
#   - added shapes of overworld encounter for rescue chain users
#   - supports spawning of alternate forms while chaining
#   - if overworld sprites for alternative, female or shiny forms are missing,
#     then the standard sprite will be displayed instead of an invisible event
#   - bug fix for shiny encounters
#   - respecting shiny state for normal encounters when using overworld and normal encounters at the same time
#   - easier chaining concerning Vendilys Rescue chain, i.e. no more resetting of the chain when spawning of a pokemon of different family but when fighting with a pokemon of different family
#   - Added new Event @@OnPokemonCreateForSpawning which only triggers on spawning
#   - Added new global variable $PokemonGlobal.battlingSpawnedShiny to check if an active battle is against a spawned pokemon.
#   - removed bug to make the new features in version 1.11 work
#   - reorganised and thin out the code to organise code as add-ons
#   - removed Vendilys Rescue Chain, Let's Go Shiny Hunting and automatic spawning as hard coded feature and provide it as Add-Ons instead
#   - Now, using overworld and normal encounters at the same time is a standard feature
#   - autospawning will not trigger instant battles anymore
#   - removed a bug that came from reorganising the code in original code and add-ons concerning Let's go shiny hunting add-on

#===============================================================================
#                             Settings            
#===============================================================================

module VisibleEncounterSettings
  #------------- SPAWN RATE AND SPAWN PROPABILITY ------------ 
  INSTANT_WILD_BATTLE_PROPABILITY = 0 # default 0.
  # This parameter holds the default propability of normal to overworld encountering.
  # The propability is stored in percentage with possible values 0,1,2,...,100.
  # <= 0           - means only overworld encounters, no instant battles
  # > 0 and < 100  - means overworld encounters and normal encounters at the same time.
  # >= 100         - means only normal encounters and instant battles as usual, no overworld spawning
  
  #--------------- SPAWN POSITION ------------------
  SPAWN_RANGE = 6 # default 4, Rango de que un Pokémon aparezca.

  RESTRICT_ENCOUNTERS_TO_PLAYER_MOVEMENT = true # true es que solo salen si haces surf.
  
  NO_SPAWN_ON_BORDER = true # Que no aparezcan en el borde del agua.

  #---------------- GRAPHICS OF SPAWNED POKEMON -------------------
  SPRITES = [true, true, true] # default [true, true, true]
  # This parameter must be an array [alt_form, female, shiny] of three bools.
  # alt_form/ female/ shiny = false means: you don't use alternative/ female/ shiny sprites for your overworld encounter.
  #                         = true  means: alternative forms/ female forms/ shiny pokemon have there own special overworld sprite.
  # If true, make sure that you have the overworld sprites with the right name in your "\Graphics\Characters\Follower" folder
  # and that you have the shiny overworld sprites with the same name in your "\Graphics\Characters\Follower shiny" folder.
  # The right name of sprites:
  #  usual form     - SPECIES.png   where SPECIES is the species name in capslock (e.g. PIDGEY.png)
  #  alternate form - SPECIES_n.png where n is the number of the form (e.g. PIKACHU_3.png)
  #  female form    - SPECIES_female.png or SPECIES_n_female (e.g. PIDGEY_female.png or PIKACHU_3_female.png)
  
  USE_STEP_ANIMATION = true # Que tengan stop animation.
  
  #------------------- MOVEMENT OF SPAWNED POKEMON -----------------------
  DEFAULT_MOVEMENT = [3, 3, 1] # default [3, 3, 1]
  # This parameter stores an array [move_speed, move_frequency, move_type] of three integers where
  # move_speed/ move_frequency/ move_type is the default movement speed/ frequency/ type of spawned PokeEvents.
  # See RPGMakerXP for more details (compare to autonomous movement of events).
  # speed/ frequency = 1   - means lowest movement speed/ frequency
  # speed/ frequency = 6   - means highest movement speed/ frequency
  # type = 0/ 1/ 3         - means no movement/ random movement/ run to player
  # ...

  Enc_Movements = [                  # default
    [:shiny?, true, 3, 4, nil],    # [:shiny?, true, 3, 4, 3] means that shiny encounters will be faster
    [:species, :SLOWPOKE, 1, 1, nil], # [:species, :SLOWPOKE, 1, 1, nil] means that slowpoke is very slow. It might still want to run random or to the player.
    [:nature, :NAUGHTY, nil, 4, 3] # [:nature, :NAUGHTY, nil, 4, 3] means pokemon with a naughty nature will run to the player and be faster
  ]
  # This parameter is used to change movement of spawned PokeEvents depending on the spawned pokemon.
  # The data is stored as an array of arrays. You can add your own arrays.s
  # The data is stored as an array of entries [variable, value, move_speed, move_frequency, move_type], where variable
  # is a variable or method which does not require parameters of the class Pokemon,
  # value is a possible outcome value of variable and move_speed, move_frequency and move_type are the movement speed,
  # frequency and type all PokeEvents should get if value == pokemon.variable.
  # nil  - means that the movement-parameter will not be changed.

  #--------------- BATTLING SPAWNED POKEMON ------------------
  BATTLE_WATER_FROM_SHORE = false #default true
  # this is used if you want to battle water pokemon without surfing
  # (default is true but I think is better in false)
  #false - means the battle wont start if not surfing 
  #true - means you can battle from the ground a pokemon from the water

  #--------------- VANISHING OF SPAWNED POKEMON AFTER STEPS -------------------
  DEFAULT_STEPS_BEFORE_VANISH = 10 # default 10
  # This is the number of steps a wild encounter goes by default before vanishing on the map.

  Add_Steps_Before_Vanish = [ # default
    [:shiny?, true, 999],       # [:shiny, true, 8]       - means that spawned shiny pokemon will more 8 steps longer on the map than default.
    #[:species, :PIDGEY, -2]   # [:species, :PIDGEY, -2] - means that pidgeys will be gone faster (2 steps earlier).
  ]
  # This is an array of arrays. You can add your own conditions as an additional array. It must be of the form [variable, value, number] where
  # variable is a variable or an method that does not need any parameters of the class Pokemon,
  # value is a possible value of variable and number is the number of steps an pokemon goes more (or less) than default before vanishing on the map 
  # if it satisfies pokemon.variable == value
  
end

CHAINLENGTH      = 10 # default 10
#       number describes how many pokemon of the same species
#       you have to kill in a row to increase shiny propability

SHINYPROBABILITY = 1000 # default 100 --> 10%
#       increasing this value decreases the probability of spawning a shiny


#===============================================================================
#                              THE SCRIPT
#===============================================================================

          #########################################################
          #                                                       #
          #      0. PART: BUG FIX FOR ONCHANGEDIRECTION           #
          #                                                       #
          #########################################################

#===============================================================================
# (Bug Fix for Events.onChangeDirection)
#   - ChangeDirection will be considered as taking a step
#===============================================================================

EventHandlers.remove(:on_player_change_direction, :trigger_encounter)

EventHandlers.add(:on_player_change_direction, :trigger_encounter,
  proc {
    next if $game_temp.in_menu
    repel_active = ($PokemonGlobal.repel > 0) || $PokemonGlobal&.infRepel == true
    if pbBattleOrSpawnOnStepTaken(repel_active) 
      pbBattleOnStepTaken(repel_active) # STANDARD WILD BATTLE
    else
      pbSpawnOnStepTaken(repel_active)  # OVERWORLD ENCOUNTERS
    end
  }
)


          #########################################################
          #                                                       #
          #      1. PART: SPAWNING THE OVERWORLD ENCOUNTER        #
          #                                                       #
          #########################################################


#===============================================================================
# We override the original method "pbOnStepTaken" in Script Overworld.
# It was  originally used for wild encounter battles
#===============================================================================
def pbOnStepTaken(eventTriggered)
  if $game_player.move_route_forcing || pbMapInterpreterRunning?
    EventHandlers.trigger(:on_step_taken, $game_player)
    return
  end
  $PokemonGlobal.stepcount = 0 if !$PokemonGlobal.stepcount
  $PokemonGlobal.stepcount += 1
  $PokemonGlobal.stepcount &= 0x7FFFFFFF
  repel_active = ($PokemonGlobal.repel > 0) || $PokemonGlobal&.infRepel == true
  EventHandlers.trigger(:on_player_step_taken)
  handled = [nil]
  EventHandlers.trigger(:on_player_step_taken_can_transfer, handled)
  return if handled[0]
  if !eventTriggered && !$game_temp.in_menu
    if $PokemonSystem.salvajes_visibles_en_ow == 1 #pbBattleOrSpawnOnStepTaken(repel_active)
      pbBattleOnStepTaken(repel_active) # STANDARD WILD BATTLE
    else
      pbSpawnOnStepTaken(repel_active)  # OVERWORLD ENCOUNTERS
    end
  end
  $game_temp.encounter_triggered = false   # This info isn't needed here
end

#===============================================================================
# new Method pbBattleOrSpawnOnStepTaken which gives true with the probability of
# an instant encounter and false with the probability of an overworld encounter
#===============================================================================
def pbBattleOrSpawnOnStepTaken(repel_active)
  if (rand(100) < VisibleEncounterSettings::INSTANT_WILD_BATTLE_PROPABILITY) || pbPokeRadarOnShakingGrass
    return true
  else
    return false
  end
end

def voe_enabled?
  return true if $PokemonSystem.salvajes_visibles_en_ow == 0
  return true if $game_switches[OW_ENCOUNTER_SWITCH] == true
  return false
end


#===============================================================================
# Eliminar todos los Pokémon salvajes del mapa
#===============================================================================
def delete_all_wild_pkmn_spawned()
  all_pkmn_far_on_map = $game_map&.events&.values&.find_all { |event|
    event.is_a?(Game_PokeEvent)}
  return if !all_pkmn_far_on_map || all_pkmn_far_on_map.empty?
  for eventi in all_pkmn_far_on_map
    $map_factory.getMap($game_map.map_id).removeThisEventfromMap(eventi.id)
  end
end


#===============================================================================
# new method pbSpawnOnStepTaken working almost like pbBattleOnStepTaken
#===============================================================================
def pbSpawnOnStepTaken(repel_active)
  return if $PokemonSystem.salvajes_visibles_en_ow == 1 # Solo spawnean cuando está a Sí (0)
  return if $game_switches[OW_ENCOUNTER_SWITCH] == true

  if false
    #  Hacer que los eventos lejanos desaparezcan.
    horizontal_size_desp = 16
    vertical_size_desp = 16
    gp = $game_player
    all_pkmn_far_on_map = $game_map.events.values.find_all { |event|
      (((event.x - gp.x).abs >= horizontal_size_desp) || ((event.y - gp.y).abs >= vertical_size_desp)) &&
      event.is_a?(Game_PokeEvent)}
    for eventi in all_pkmn_far_on_map
      #$game_map.events[eventi.id]&.erase
      valor_d = $game_self_switches[[$game_map.map_id, eventi.id, "D"]]
      $map_factory.getMap($game_map.map_id).removeThisEventfromMap(eventi.id) if !valor_d
    end
  end

  #return if $player.able_pokemon_count == 0 #check if trainer has pokemon
  #First we choose a tile near the player
  pos = pbChooseTileOnStepTaken
  return if !pos
  encounter_type = $PokemonEncounters.encounter_type_on_tile(pos[0],pos[1])
  return if !encounter_type
  return if !$PokemonEncounters.encounter_triggered_on_tile?(encounter_type, repel_active, true)
  $game_temp.encounter_type = encounter_type
  encounter = $PokemonEncounters.choose_wild_pokemon(encounter_type)
  $PokemonGlobal.creatingSpawningPokemon = true
  EventHandlers.trigger(:on_wild_species_chosen, encounter)
  if $PokemonEncounters.allow_encounter?(encounter, repel_active)
    pokemon = pbGenerateWildPokemon(encounter[0],encounter[1])
    # trigger event on spawning of pokemon
    EventHandlers.trigger(:on_wild_pokemon_created_for_spawning, pokemon)
    pbPlaceEncounter(pos[0],pos[1],pokemon)
    # $PokemonEncounters.reset_step_count # added such that your encounter rate resets after spawning of an overworld pokemon 
    $game_temp.encounter_type = nil
    $game_temp.encounter_triggered = true


    #================================================================
    # ANIMACION DE QUE APARECE EL POKÉMON
    # echoln "TIPO DE ENCUENTRO: #{encounter_type}. CHECK" #  y #{$game_map.terrain_tag(pos[0],pos[1])}
    
    encounter_class = $PokemonEncounters.encounter_class_on_tile(pos[0],pos[1]) rescue nil
    # Terreno de hierba
    if encounter_class == "Water"
      $scene.spriteset.addUserAnimation(23,pos[0],pos[1]) rescue nil
    # Encuentro hierba
    elsif encounter_class == "Land" || encounter_class == "LandClassic"
      if $game_map && $game_map.map_id==174
        $scene.spriteset.addUserAnimation(24,pos[0],pos[1]) rescue nil
      else
        $scene.spriteset.addUserAnimation(Settings::RUSTLE_NORMAL_ANIMATION_ID,pos[0],pos[1]) rescue nil
      end
    else
      $scene.spriteset.addUserAnimation(2,pos[0],pos[1]) rescue nil
    end
  end
  $game_temp.force_single_battle = false
  EventHandlers.trigger(:on_wild_pokemon_created_for_spawning_end)
  $PokemonGlobal.creatingSpawningPokemon = false
  #EncounterModifier.triggerEncounterEndSpawn
  #EncounterModifier.triggerEncounterEnd # not use anymore in PEv20 ?
end

#===============================================================================
# new method pbChooseTileOnStepTaken to choose the tile on which the pkmn spawns 
#===============================================================================
def pbChooseTileOnStepTaken
  x = $game_player.x
  y = $game_player.y
  range = VisibleEncounterSettings::SPAWN_RANGE
  i = rand(range)
  r = rand((i+1)*8)
  if r<=(i+1)*2
    new_x = x-i-1+r
    new_y = y-i-1
  elsif r<=(i+1)*6-2
    new_x = [x+i+1,x-i-1][r%2]
    new_y = y-i+((r-1-(i+1)*2)/2).floor
  else
    new_x = x-i+r-(i+1)*6
    new_y = y+i+1
  end
  return [new_x,new_y] if pbTileIsPossible(new_x,new_y)
  return
end

#===============================================================================
# new method pbTileIsPossible to check if tile is good to spawn
#===============================================================================
def pbTileIsPossible(x,y)
  if !$game_map.valid?(x,y) #check if the tile is on the map
    return false
  else
    tile_terrain_tag = $game_map.terrain_tag(x,y)
  end
  for event in $game_map.events.values
    if event.x==x && event.y==y
      return false
    end
  end

  # Evitar que salga un Pokémon pegado a otro
  for wildpokes in $game_map.events.values
    if wildpokes.is_a?(Game_PokeEvent)
      if ((wildpokes.x - x).abs <= 1) && ((wildpokes.y - y).abs <= 1)
        return false
      end
    end
  end

  return false if !tile_terrain_tag
  #check if it's a valid grass, water or cave etc. tile
  return false if tile_terrain_tag.ice
  return false if tile_terrain_tag.ledge
  return false if tile_terrain_tag.waterfall
  return false if tile_terrain_tag.waterfall_crest
  return false if tile_terrain_tag.id == :Rock
  if tile_terrain_tag.can_surf && !($PokemonGlobal && $PokemonGlobal.surfing)
    return false
  end
  if tile_terrain_tag.can_surf
    for i in [2, 1, 0]
      tile_id = $game_map.data[x, y, i]
      return false if !tile_id || tile_id < 0
      next if tile_id == 0
      terrain = GameData::TerrainTag.try_get($game_map.terrain_tags[tile_id])
      passage = $game_map.passages[tile_id]
      priority = $game_map.priorities[tile_id]
      break if terrain.can_surf
      # Ignore if tile above water
      return false if passage!=0
      return false if priority==0 && !terrain.ignore_passability
    end
  else
    return false if !$game_map.passableStrict?(x, y, 0)
  end
  return false if !$PokemonEncounters.encounter_possible_here_on_tile?(x,y)
  return true
end

#===============================================================================
# defining new method pbPlaceEncounter to add/place and visualise the pokemon
# "encounter" on the overworld-tile (x,y)
#===============================================================================
def pbPlaceEncounter(x,y,pokemon)
  # place event with random movement with overworld sprite
  # We define the event, which has the sprite of the pokemon and activates the wildBattle on touch
  if !$map_factory
    $game_map.spawnPokeEvent(x,y,pokemon)
  else
    mapId = $game_map.map_id
    spawnMap = $map_factory.getMap(mapId)
    spawnMap.spawnPokeEvent(x,y,pokemon)
  end
  pbPlayCryOnOverworld(pokemon.species, pokemon.form) # Play the pokemon cry of encounter
end


#===============================================================================
# adding new Method encounter_type_on_tile in Class PokemonEncounters
#===============================================================================
class PokemonEncounters  
  def encounter_type_on_tile(x,y)
    time = pbGetTimeNow
    ret = nil
    if $game_map.terrain_tag(x,y).can_surf_freely
      water_encounter = $game_switches[MODO_CLASICO] ? :WaterClassic : :Water
      ret = find_valid_encounter_type_for_time(water_encounter, time)
    else   # Land/Cave (can have both in the same map)
      if has_land_encounters? && $game_map.terrain_tag(x, y).land_wild_encounters
        if $game_switches[MODO_CLASICO]
          bug_encounter  = :BugContestClassic
          land_encounter = :LandClassic
        else
          bug_encounter  = :BugContest
          land_encounter = :Land
        end
        ret = bug_encounter if pbInBugContest? && has_encounter_type?(bug_encounter)
        ret = find_valid_encounter_type_for_time(land_encounter, time) if !ret
      end
      if !ret && has_cave_encounters?
        cave_encounter = $game_switches[MODO_CLASICO] ? :CaveClassic : :Cave
        ret = find_valid_encounter_type_for_time(cave_encounter, time)
      end
    end
    return ret
  end


  def encounter_class_on_tile(x,y)
    time = pbGetTimeNow
    ret = nil
    if $game_map.terrain_tag(x,y).can_surf_freely
      ret = $game_switches[MODO_CLASICO] ? "WaterClassic" : "Water"
    else   # Land/Cave (can have both in the same map)
      if has_land_encounters? && $game_map.terrain_tag(x, y).land_wild_encounters
        ret = $game_switches[MODO_CLASICO] ? "LandClassic" : "Land"
      end
      if !ret && has_cave_encounters?
        ret = $game_switches[MODO_CLASICO] ? "CaveClassic" : "Cave"
      end
    end
    return ret
  end

  
  #===============================================================================
  # adding new method encounter_possible_here_on_tile? in class PokemonEncounters
  # in file 003_Overworld_WildEncounters.rb to check at arbitrary coordinates x
  # and y and not only at players position such as encounter_possible_here? does
  #===============================================================================
  def encounter_possible_here_on_tile?(x,y)
    tile_terrain_tag = $game_map.terrain_tag(x,y)
    if tile_terrain_tag.can_surf_freely
      if VisibleEncounterSettings::NO_SPAWN_ON_BORDER
        return false if !$game_map.terrain_tag(x+1,y).can_surf_freely
        return false if !$game_map.terrain_tag(x-1,y).can_surf_freely
        return false if !$game_map.terrain_tag(x,y+1).can_surf_freely
        return false if !$game_map.terrain_tag(x,y-1).can_surf_freely
      end
      return true
    end
    return true if tile_terrain_tag.can_surf_freely
    return false if tile_terrain_tag.ice
    return true if has_cave_encounters?   # i.e. this map is a cave
    return true if has_land_encounters? && tile_terrain_tag.land_wild_encounters
    return false
  end

  #===============================================================================
  # adding new Method encounter_triggered_on_tile? to Class PokemonEncounters
  # to returns whether a overworld wild encounter should happen, based on its encounter
  # chance. Called when taking a step. Add-ons may overwrite this method.
  #===============================================================================
  def encounter_triggered_on_tile?(enc_type, repel_active = false, triggered_by_step = true)
    return $PokemonEncounters.encounter_triggered?(enc_type, repel_active, true)
  end

  #===============================================================================
  # adding new method have_double_wild_battle_on_tile? in class PokemonEncounters
  # Returns whether a wild encounter should be turned into a double wild encounter
  # similar to have_double_wild_battle but depends on tile.
  #===============================================================================
  def have_double_wild_battle_on_tile?(x, y, map_id)
    return false if $game_temp.force_single_battle
    return false if pbInSafari?
    return true if $PokemonGlobal.partner
    return false if $player.able_pokemon_count <= 1
    if $map_factory
      terrainTag = $map_factory.getTerrainTag(map_id,x,y)
    else
      terrainTag = $game_map.terrain_tag(x,y)
    end
    return true if terrainTag.double_wild_encounters && rand(100) < 30  
    return false
  end
end

#===============================================================================
# adding new Class Game_PokeEvent and a new method attr_accessor to this Class
# to store the corresponding Pokemon in the Game_Event
#===============================================================================
class Game_PokeEvent < Game_Event
  #attr_accessor :event
  attr_accessor :pokemon # contains the original pokemon of class Pokemon

  def initialize(map_id, event, map=nil)
    super(map_id, event, map)
  end
end

#===============================================================================
# new Method spawnPokeEvent in Class Game_Map in Script Game_Map
#===============================================================================
class Game_Map
  def spawnPokeEvent(x,y,pokemon)
    #--- generating a new event ---------------------------------------
    event = RPG::Event.new(x,y)
    #--- nessassary properties ----------------------------------------
    key_id = (@events.keys.max || -1) + 1
    event.id = key_id
    event.x = x
    event.y = y

    #--- Graphic of the event -----------------------------------------
    encounter = [pokemon.species,pokemon.level]
    form = pokemon.form
    gender = pokemon.gender
    #event.pages[0].graphic.tile_id = 0
    graphic_form   = (VisibleEncounterSettings::SPRITES[0] && form!=nil) ? form : 0
    graphic_gender = (VisibleEncounterSettings::SPRITES[1] && gender!=nil) ? gender : 0
    
    pokemon.shiny       = false
    pokemon.super_shiny = false

    # FORZAR SHINY
    if $game_switches[Settings::SUPER_SHINY_WILD_POKEMON_SWITCH]    #FORZANDO SUPER SHINY
      pokemon.shiny = true
      pokemon.super_shiny = true
    elsif $game_switches[Settings::SHINY_WILD_POKEMON_SWITCH] || $game_switches[SHINYZADOR_SWTICH]==true  #FORZANDO SHINY
      pokemon.shiny=true
      pokemon.super_shiny = false
      $game_switches[SHINYZADOR_SWTICH] = false
    else
      $PokemonGlobal.catchcombo = [0, 0] if $PokemonGlobal.catchcombo.nil?

      # Calcular la probabilidad base según la cadena
      combo_count = $PokemonGlobal.catchcombo[0]
      is_same_species = $PokemonGlobal.catchcombo[1] == encounter[0]

      shiny_chance = if is_same_species
                      # Chain shiny probabilities for same species
                      case combo_count
                      when (CHAINLENGTH * 4)..Float::INFINITY      # 40+ chain
                        SHINYPROBABILITY / 5                       # 1/200
                      when (CHAINLENGTH * 3)...(CHAINLENGTH * 4)   # 30-39 chain
                        SHINYPROBABILITY * 2 / 5                   # 1/400
                      when (CHAINLENGTH * 2)...(CHAINLENGTH * 3)   # 20-29 chain
                        SHINYPROBABILITY * 3 / 5                   # 1/600
                      when CHAINLENGTH...(CHAINLENGTH * 2)         # 10-19 chain
                        SHINYPROBABILITY * 4 / 5                   # 1/800
                      else
                        SHINYPROBABILITY                           # 1/1000 (base rate)
                      end
                    else
                      SHINYPROBABILITY                             # 1/1000 (base rate)
                    end

      # Aplicar modificador del Shiny Charm (duplica la probabilidad)
      shiny_chance /= 2 if $bag.has?(:SHINYCHARM)

      # Determinar si es shiny
      if rand(shiny_chance) == 0
        pokemon.shiny = true
        pokemon.super_shiny = true if rand(10) == 0  # 10% de super shiny
      end
    end

    shiny = pokemon.shiny?

    graphic_shiny = (VisibleEncounterSettings::SPRITES[2] && shiny!=nil && !pokemon.super_shiny?) ? shiny : false

    fname = ow_sprite_filename(pokemon.species, graphic_form, graphic_gender, graphic_shiny)
    fname = fname.to_s.sub(/^Graphics\/Characters\//i, "").sub(/\.(png|gif|bmp)$/i, "")
    event.pages[0].graphic.character_name = fname

    event.pages[0].graphic.character_hue = pokemon.super_shiny_hue if pokemon.super_shiny?

    #--- movement of the event --------------------------------
    event.pages[0].move_speed = VisibleEncounterSettings::DEFAULT_MOVEMENT[0]
    event.pages[0].move_frequency = VisibleEncounterSettings::DEFAULT_MOVEMENT[1]
    event.pages[0].move_type = VisibleEncounterSettings::DEFAULT_MOVEMENT[2]
    event.pages[0].step_anime = true if VisibleEncounterSettings::USE_STEP_ANIMATION
    event.pages[0].trigger = 2
    event.pages[0].move_route = RPG::MoveRoute.new
    event.pages[0].move_route.list = [RPG::MoveCommand.new(10), RPG::MoveCommand.new]
    for move in VisibleEncounterSettings::Enc_Movements do
      if pokemon.method(move[0]).call == move[1]
        event.pages[0].move_speed = move[2] if move[2]
        event.pages[0].move_frequency = move[3] if move[3]
        event.pages[0].move_type = move[4] if move[4]
      end
    end



    #============================================================================#
    # CAMBIOS EN EL MOVIMIENTO EN BASE A LA ESPECIE:
    #============================================================================#

    # VELOCIDAD 1
    especies_vel1 = [
      :WAILORD, :REGIGIGAS
    ]
    if especies_vel1.include?(pokemon.species)  
      event.pages[0].move_type = 1
      event.pages[0].move_speed = 1
      event.pages[0].move_frequency = 3
    end


    # VELOCIDAD 2
    especies_vel2 = [
      :VENUSAUR, :CHARIZARD, :BLASTOISE, :ONIX, :PARASECT, :SNORLAX, :TYRANITAR, :SLAKOTH, :SLAKING, 
      :SHEDINJA, :AGGRON, :WAILMER, :TORKOAL, :WALREIN, :TORKOAL, :WALREIN, :REGIROCK, :REGICE,
      :REGISTEEL, :GROTLE, :TORTERRA, :EMPOLEON, :RAMPARDOS, :BASTIODON, :DRIFLOON, :DRIFBLIM,
      :BRONZOR, :BRONZONG, :GARCHOMP, :HIPPOWDOWN, :ABOMASNOW, :RHYPERIOR, :MAMOSWINE, :PROBOPASS,
      :DIALGA, :PALKIA, :GIRATINA, :ROGGENROLA, :BOLDORE, :GIGALITH, :CONKELDURR, :CRISTLE, 
      :ESCAVALIER, :JELLICENT, :FERROTHORN, :HAXORUS, :BEARTIC, :GOLETT, :GOLURK, :CHESNAUGHT,
      :PANGORO, :DOUBLADE, :AEGISLASH, :BINACLE, :AURORUS, :CARBINK, :GOOMY, :SLIGGOO, :GOODRA,
      :BERGMITE, :AVALUGG, :CRABOMINABLE, :PYUKUMUKU, :MELMETAL, :RILLABOOM, :COALOSSAL, 
      :APPLETUNE, :DURALUDON, :STONJOURNER, :CUFANT, :COPPERAJAH, :ARCTOZOLT, :DRACOZOLT, 
      :ETERNATUS, :REGIDRAGO, :GLASTRIER, :KLEAVOR, :URSALUNA, :OVERQWILL, :SKELEDIRGE, :ARBOLIVA,
      :NACLI, :NACLSTACK, :GARGANACL, :TOEDSCRUEL, :KLAWF, :CETITAN, :DONDOZO, :KINGAMBIT,
      :IRONTHORNS, :BAXCALIBUR, :WOCHIEN, :TINGLU, :KORAIDON, :ARCHALUDON, :GOUGINGFIRE,
      :RAGINGBOLT, :IRONBOULDER, :RABSCA, :HOUNDSTONE, :CLODSIRE, :HYDRAPPLE, :EXEGGUTOR,
      :PINCURCHIN, :DREDNAW
    ]
    if especies_vel2.include?(pokemon.species)  
      event.pages[0].move_type = 1
      event.pages[0].move_speed = 2
      event.pages[0].move_frequency = 3
    end


    # VELOCIDAD 4
    especies_vel4 = [
      :BEEDRILL, :PIDGEOTTO, :ZUBAT, :GOLBAT, :VENOMOTH, :LEDYBA, :LEDIAN, :CROBAT,
      :TOGETIC, :BEAUTIFLY, :DUSTOX, :SWELLOW, :MASQUERAIN, :VIGOROTH, :MOTHIM, :COMBEE,
      :VESPIQUEN, :WOOBAT, :SWOOBAT, :ACCELGOR, :FLETCHINDER, 
      :NOIBAT, :ROWLET, :PIKIPEK, :TRUMBEAK, :VIKAVOLT, :CUTIEFLY, :WIMPOD, :CORVISQUIRE,
      :FLAPPLE, :VELUZA, :FLUTTERMANE, :IRONBOUNDLE, 
    ]
    if especies_vel4.include?(pokemon.species)  
      event.pages[0].move_type = 1
      event.pages[0].move_speed = 4
      event.pages[0].move_frequency = 3
    end


    # VELOCIDAD 5
    especies_vel5 = [
      :YANMA, :NINJASK, :YANMEGA, :ROTOM
    ]
    if especies_vel5.include?(pokemon.species)  
      event.pages[0].move_type = 1
      event.pages[0].move_speed = 5
      event.pages[0].move_frequency = 3
    end


    # QUE NO SE MUEVAN EN EL SITIO
    especies_stop = [
      :NOSEPASS
    ]
    if especies_stop.include?(pokemon.species)  
      event.pages[0].move_route.list = []
      event.pages[0].move_route.list.push(RPG::MoveCommand.new(PBMoveRoute::TURN_UP)) # Mirar arriba
      event.pages[0].move_route.list.push( RPG::MoveCommand.new)

      event.pages[0].step_anime = false
      event.pages[0].trigger = 2
    end


    # SPOINK:
    especies_jump = [
      :SPOINK
    ]
    if especies_jump.include?(pokemon.species)  
      event.pages[0].move_route.repeat = true # the pokemon repeats the route
      event.pages[0].move_route.skippable = true # the pokemon skips if not possible
      event.pages[0].move_type = 3 # Custom
      event.pages[0].move_route.list = []
      saltoArriba = 0
      saltoAbajo  = 0
      saltoIzda   = 0
      saltoDcha   = 0
      veces = rand(4)
      veces+=4 # Así hacemos todo entre 4 y 8 veces
      for i in 0...veces # Generamos movimientos al azar.
        for i in 0...6 # '...' no incluye el último número.
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,0])) # saltar en el sitio
        end
        direccionSalto = rand(4) # A number between 0 and 3
        if direccionSalto == 0
          saltoDcha = 1
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[1,0])) # salto derecha
        elsif direccionSalto == 1
          saltoIzda = 1
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[-1,0])) # salto izquierda
        elsif direccionSalto == 2
          saltoAbajo = 1
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,1])) # salto abajo
        elsif direccionSalto == 3
          saltoArriba = 1
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,-1])) # salto arriba
        end
      end
      #Si no ha dado saltos en una dirección pero sí en la opuesta, creamos la otra para que nunca se quede quieto para siempre.
      if saltoArriba==1 && saltoAbajo==0
        for i in 0...6
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,0])) # saltar en el sitio
        end
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,1])) # salto abajo
      elsif saltoArriba==0 && saltoAbajo==1
        for i in 0...6
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,0])) # saltar en el sitio
        end
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,-1])) # salto arriba
      end
      if saltoIzda==0 && saltoDcha==1
        for i in 0...6
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,0])) # saltar en el sitio
        end
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[-1,0])) # salto arriba
      elsif saltoIzda==1 && saltoDcha==0
        for i in 0...6
          event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[0,0])) # saltar en el sitio
        end
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(14,[1,0])) # salto arriba
      end
      event.pages[0].move_route.list.push( RPG::MoveCommand.new )
      event.pages[0].move_speed = 3
      event.pages[0].move_frequency = 6
    end


    # TELEPORTS:
    especies_tps = [
      :ABRA, :RALTS, :KIRLIA, :UNOWN, :WYNAUT, :MUNNA, :ELGYEM, :BEHEEYEM, :ESPURR,
      :HATENNA, :HATTREM
    ]
    if especies_tps.include?(pokemon.species)
      event.pages[0].move_route.repeat = true # the pokemon repeats the route
      event.pages[0].move_route.skippable = true # the pokemon skips if not possible
      event.pages[0].move_type = 3 # Custom
      event.pages[0].move_route.list = []
      saltoArriba = 0
      saltoAbajo  = 0
      saltoIzda   = 0
      saltoDcha   = 0
      veces = rand(4)
      veces+=4 # Así hacemos todo entre 4 y 8 veces
      for i in 0...veces # Generamos movimientos al azar.
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(15,[50])) # WAIT
        # Cambiamos gráfico para volverlo invisible
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(41,["Teleport",0,0,0])) # GRAPHIC
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(15,[1])) # WAIT
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(41,["Teleport2",0,0,0])) # GRAPHIC
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(15,[1])) # WAIT
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(41,["",0,0,0])) # GRAPHIC
        # MOVIMINETO (TO DO: quitar sombra y que no mueva hierba al moverse)
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(29,[6])) # CHANGESPEED 6
        #event.pages[0].move_route.list.push(RPG::MoveCommand.new(37)) # THROUGH ON
        # 1 o 3 pasos se mueven (2 no para que no se quede en el sitio).
        opcionPasos = rand(2)
        if false # opcionPasos==0 # Que siempre sean 3
          numMovsTP = 1
        else
          numMovsTP = 3
        end
        for i in 0...numMovsTP
          # Elegir la dirección
          dirRandTP = rand(4)
          if dirRandTP == 0
            event.pages[0].move_route.list.push(RPG::MoveCommand.new(1)) # DOWN
          elsif dirRandTP == 1
            event.pages[0].move_route.list.push(RPG::MoveCommand.new(2)) # LEFT
          elsif dirRandTP == 2
            event.pages[0].move_route.list.push(RPG::MoveCommand.new(3)) # RIGHT
          else
            event.pages[0].move_route.list.push(RPG::MoveCommand.new(4)) # UP
          end
        end
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(29,[3])) # CHANGESPEED 3
        #event.pages[0].move_route.list.push(RPG::MoveCommand.new(38)) # THROUGH OFF
        # Recuperar el gráfico del pokémon.
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(41,["Teleport2",0,0,0])) # GRAPHIC
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(15,[1])) # WAIT
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(41,["Teleport",0,0,0])) # GRAPHIC
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(15,[1])) # WAIT
        event.pages[0].move_route.list.push(RPG::MoveCommand.new(41,[fname,0,0,0])) # GRAPHIC
      end
      event.name = "pokemonTP"
      event.pages[0].move_route.list.push( RPG::MoveCommand.new )
      event.pages[0].move_speed = 3
      event.pages[0].move_frequency = 6  
    end

    #--- event commands of the event -------------------------------------
    #  - add a method that stores temp data when PokeEvent is triggered, must include
    #    $PokemonGlobal.roamEncounter, $game_temp.roamer_index_for_encounter, $PokemonGlobal.nextBattleBGM, $game_temp.force_single_battle, $game_temp.encounter_type
    Compiler::push_script(event.pages[0].list,sprintf(" pbStoreTempForBattle()"))
    #  - set data for roamer and encounterType, that is
    #    $PokemonGlobal.roamEncounter, $game_temp.roamer_index_for_encounter, $PokemonGlobal.nextBattleBGM, $game_temp.force_single_battle, $game_temp.encounter_type
    if $PokemonGlobal.roamEncounter!=nil # i.e. $PokemonGlobal.roamEncounter = [i,species,poke[1],poke[4]]
      parameter1 = $PokemonGlobal.roamEncounter[0].to_s
      parameter2 = $PokemonGlobal.roamEncounter[1].to_s
      parameter3 = $PokemonGlobal.roamEncounter[2].to_s
      $PokemonGlobal.roamEncounter[3] != nil ? (parameter4 = '"'+$PokemonGlobal.roamEncounter[3].to_s+'"') : (parameter4 = "nil")
      parameter = " $PokemonGlobal.roamEncounter = ["+parameter1+",:"+parameter2+","+parameter3+","+parameter4+"] "
    else
      parameter = " $PokemonGlobal.roamEncounter = nil "
    end
    Compiler::push_script(event.pages[0].list,sprintf(parameter))
    parameter = ($game_temp.roamer_index_for_encounter!=nil) ? " $game_temp.roamer_index_for_encounter = "+$game_temp.roamer_index_for_encounter.to_s : " $game_temp.roamer_index_for_encounter = nil "
    Compiler::push_script(event.pages[0].list,sprintf(parameter))
    parameter = ($PokemonGlobal.nextBattleBGM!=nil) ? " $PokemonGlobal.nextBattleBGM = '"+$PokemonGlobal.nextBattleBGM.to_s+"'" : " $PokemonGlobal.nextBattleBGM = nil "
    Compiler::push_script(event.pages[0].list,sprintf(parameter))
    parameter = ($game_temp.force_single_battle!=nil) ? " $game_temp.force_single_battle = "+$game_temp.force_single_battle.to_s : " $game_temp.force_single_battle = nil "
    Compiler::push_script(event.pages[0].list,sprintf(parameter))
    parameter = ($game_temp.encounter_type!=nil) ? " $game_temp.encounter_type = :"+$game_temp.encounter_type.to_s : " $game_temp.encounter_type = nil "
    Compiler::push_script(event.pages[0].list,sprintf(parameter))
    #  - add a branch to check if player can battle water pokemon from ground
    Compiler::push_branch(event.pages[0].list,sprintf(" pbCheckBattleAllowed()"))
    #  - set $PokemonGlobal.battlingSpawnedPokemon = true
    Compiler::push_script(event.pages[0].list,sprintf(" $PokemonGlobal.battlingSpawnedPokemon = true"),1)    
    #  - add method pbSingleOrDoubleWildBattle for the battle
    if !$map_factory
      parameter = " pbSingleOrDoubleWildBattle( $game_map.events[#{key_id}].map.map_id, $game_map.events[#{key_id}].x, $game_map.events[#{key_id}].y, $game_map.events[#{key_id}].pokemon )"
    else
      mapId = $game_map.map_id
      parameter = " pbSingleOrDoubleWildBattle( $map_factory.getMap("+mapId.to_s+").events[#{key_id}].map.map_id, $map_factory.getMap("+mapId.to_s+").events[#{key_id}].x, $map_factory.getMap("+mapId.to_s+").events[#{key_id}].y, $map_factory.getMap("+mapId.to_s+").events[#{key_id}].pokemon )"
    end
    Compiler::push_script(event.pages[0].list,sprintf(parameter),1)
    #   - set $PokemonGlobal.battlingSpawnedPokemon = false
    Compiler::push_script(event.pages[0].list,sprintf(" $PokemonGlobal.battlingSpawnedPokemon = false"),1) 
    #  - add a method to reset temporary data to previous state, must include
    #    $PokemonGlobal.roamEncounter, $game_temp.roamer_index_for_encounter, $PokemonGlobal.nextBattleBGM, $game_temp.force_single_battle, $game_temp.encounter_type
    Compiler::push_script(event.pages[0].list,sprintf(" pbResetTempAfterBattle()"),1)
    #  - add method to remove this PokeEvent from map
    if !$map_factory
      parameter = "$game_map.removeThisEventfromMap(#{key_id})"
    else
      mapId = $game_map.map_id
      parameter = "$map_factory.getMap("+mapId.to_s+").removeThisEventfromMap(#{key_id})"
    end
    Compiler::push_script(event.pages[0].list,sprintf(parameter),1)
    #  - add the end of branch
    Compiler::push_branch_end(event.pages[0].list,1)
    #  - add a method to reset temporary data to previous state (if tried to battle waterpokemon from shore but not allowed), must include
    #    $PokemonGlobal.roamEncounter, $game_temp.roamer_index_for_encounter, $PokemonGlobal.nextBattleBGM, $game_temp.force_single_battle, $game_temp.encounter_type
    Compiler::push_script(event.pages[0].list,sprintf(" pbResetTempAfterBattle()"))
    #  - finally push end command
    Compiler::push_end(event.pages[0].list)
    #--- creating and adding the Game_PokeEvent ------------------------------------
    gameEvent = Game_PokeEvent.new(@map_id, event, self)
    gameEvent.id = key_id
    gameEvent.moveto(x,y)
    gameEvent.pokemon = pokemon
    for step in VisibleEncounterSettings::Add_Steps_Before_Vanish
      step_method = step[0]
      step_value = step[1]
      step_count = step[2]
      if pokemon.method(step_method).call == step_value
        gameEvent.remaining_steps += step_count
      end
    end

    #================================================================
    # Animación cuando es Shiny
    #================================================================
    if pokemon.super_shiny?
      $scene.spriteset.addUserAnimation(53,x,y)
      pbMapInterpreter.pbSetSelfSwitch(event.id, "D", true, @map_id)
        echoln "Aumentado el contador de shinys desde fuera del combate." if shiny
    elsif pokemon.shiny?
      $scene.spriteset.addUserAnimation(52,x,y)
      pbMapInterpreter.pbSetSelfSwitch(event.id, "D", true, @map_id)
        echoln "Aumentado el contador de shinys desde fuera del combate." if shiny
    end 
    
    begin
     @events[key_id] = gameEvent
    rescue
      return
      # pbMessage(_INTL("Error al crear el evento."))
    end
    #--- updating the sprites --------------------------------------------------------
    sprite = Sprite_Character.new(Spriteset_Map.viewport,@events[key_id])
    $scene.spritesets[self.map_id]=Spriteset_Map.new(self) if $scene.spritesets[self.map_id]==nil
    $scene.spritesets[self.map_id].character_sprites.push(sprite)
    # alternatively: updating the sprites (old and slow but working):
    #$scene.disposeSpritesets
    #$scene.createSpritesets
  end
end

#-------------------------------------------------------------------------------
# New method for easily get the appropriate Pokemon Graphic (Optimized with RAM Cache)
#-------------------------------------------------------------------------------
$OW_SPRITE_CACHE ||= {}

def ow_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
  cache_key = "#{species}_#{form}_#{gender}_#{shiny}_#{shadow}"
  cached = $OW_SPRITE_CACHE[cache_key]
  return cached if cached

  fname = GameData::Species.check_graphic_file("Graphics/Characters/", species, form, gender, shiny, shadow, "Followers") rescue nil
  if nil_or_empty?(fname) || fname.to_s.include?("/000")
    prefix = shiny ? "Followers shiny" : "Followers"
    cand1 = "Graphics/Characters/#{prefix}/#{species}_#{form}"
    cand2 = "Graphics/Characters/#{prefix}/#{species}"
    cand3 = "Graphics/Characters/Followers/#{species}_#{form}"
    cand4 = "Graphics/Characters/Followers/#{species}"
    if pbResolveBitmap(cand1)
      fname = cand1
    elsif pbResolveBitmap(cand2)
      fname = cand2
    elsif pbResolveBitmap(cand3)
      fname = cand3
    elsif pbResolveBitmap(cand4)
      fname = cand4
    end
  end
  fname = "Graphics/Characters/Followers/000.png" if nil_or_empty?(fname)
  $OW_SPRITE_CACHE[cache_key] = fname
  return fname
end

class Game_Temp
  attr_accessor :VOWERoamEncounter
  attr_accessor :VOWERoamerIndex
  attr_accessor :VOWENextBattleBGM
  attr_accessor :VOWEForceSingleBattle
  attr_accessor :VOWEEncounterType
end

class PokemonGlobalMetadata
  attr_accessor :catchcombo
end

#===============================================================================
# adding new Method pbStoreTempForBattle to store temporary data before battling
# overworld pokemon
#===============================================================================
def pbStoreTempForBattle()
  $game_temp.VOWERoamEncounter = $PokemonGlobal.roamEncounter
  $game_temp.VOWERoamerIndex = $game_temp.roamer_index_for_encounter
  $game_temp.VOWENextBattleBGM = $PokemonGlobal.nextBattleBGM 
  $game_temp.VOWEForceSingleBattle = $game_temp.force_single_battle
  $game_temp.VOWEEncounterType = $game_temp.encounter_type
end

#===============================================================================
# adding new Method to reset temporary data after battling overworld back to before
#===============================================================================
def pbResetTempAfterBattle()
  $PokemonGlobal.roamEncounter = $game_temp.VOWERoamEncounter
  $game_temp.roamer_index_for_encounter = $game_temp.VOWERoamerIndex
  $PokemonGlobal.nextBattleBGM = $game_temp.VOWENextBattleBGM 
  $game_temp.force_single_battle = $game_temp.VOWEForceSingleBattle
  $game_temp.encounter_type = $game_temp.VOWEEncounterType
end

#===============================================================================
# adding new Method pbCheckBattleAllowed to check if battling water pokemon from ground are allowed
#===============================================================================
def pbCheckBattleAllowed()
  encType = GameData::EncounterType.try_get($game_temp.encounter_type)
  #the pokemon encounter battle won't happen if it is in the water and the player is not surfing
  return false if !$PokemonGlobal.surfing && encType.type == :water && VisibleEncounterSettings::BATTLE_WATER_FROM_SHORE == false
  return true
end

#===============================================================================
# adding new Method pbSingleOrDoubleWildBattle to reduce the code in spawnPokeEvent
#===============================================================================
def pbSingleOrDoubleWildBattle(map_id,x,y,pokemon)
  if $PokemonEncounters.have_double_wild_battle_on_tile?(x,y,map_id)
      encounter2 = $PokemonEncounters.choose_wild_pokemon($game_temp.encounter_type)
      EventHandlers.trigger(:on_wild_species_chosen, encounter2)
      setBattleRule("double")
      WildBattle.start(pokemon, encounter2, can_override: true)
  else
    WildBattle.start(pokemon, can_override: true)
  end
  $game_temp.encounter_type = nil
  $game_temp.encounter_triggered = true
end

#===============================================================================
# adding new method pbPlayCryOnOverworld to load/play Pokémon cry files 
# SPECIAL THANKS TO "Ambient Pokémon Cries" - by Vendily
#===============================================================================
def pbPlayCryOnOverworld(pokemon,form=0,volume=30,pitch=100)
  # Desactivado en Switch para que la aparición de Pokémon en hierba alta sea 100% fluida a 60 FPS
  return
end

#===============================================================================
# adding a new method attr_reader to the Class Spriteset_Map in Script
# Spriteset_Map to get access to the variable @character_sprites of a
# Spriteset_Map
#===============================================================================
class Spriteset_Map
  attr_reader :character_sprites
end

#===============================================================================
# adding a new method attr_reader to the Class Scene_Map in Script
# Scene_Map to get access to the Spriteset_Maps listed in the variable 
# @spritesets of a Scene_Map
#===============================================================================
class Scene_Map
  attr_reader :spritesets
end


          #########################################################
          #                                                       #
          #   2. PART: VANISH OVERWORLD ENCOUNTER AFTER BATTLE    #
          #                                                       #
          #########################################################

#-------------------------------------------------------------------
# adding new Method removeThisEventfromMap in Class Game_Map 
# to let an overworld pokemon disappear after battling
#-------------------------------------------------------------------
class Game_Map
  def removeThisEventfromMap(id)
    if @events.has_key?(id)
      if defined?($scene.spritesets)
        for sprite in $scene.spritesets[@map_id].character_sprites
          if sprite.character == @events[id]
            $scene.spritesets[@map_id].character_sprites.delete(sprite)
            sprite.dispose
            break
          end
        end
      end
      @events.delete(id)
    end
  end
end


def animacion_al_desaparecer_poke(pos_x, pos_y)
  # ANIMACION DE QUE APARECE EL POKÉMON
  #echoln "ARREGLAR QUE SEGÚN EL TERRENO CAMBIE, Y AÑADIR QUE AL IRSE HAYA ANIMACIÓN"
  encounter_class = $PokemonEncounters.encounter_class_on_tile(pos_x,pos_y)
  #echoln "TERRENO DE DESAPARECIDA: #{encounter_class}."
  # Terreno de hierba
  if encounter_class == "Water"
    #echoln "Animación de encuentro en agua"
    $scene.spriteset.addUserAnimation(23,pos_x,pos_y) if defined?($scene.spriteset)
  # Encuentro hierba
  elsif encounter_class == "Land"
    #echoln "Animación de encuentro en hierba"
    if $game_map && $game_map.map_id==174 # Animación de hierba amarillenta
      $scene.spriteset.addUserAnimation(24,pos_x,pos_y) if defined?($scene.spriteset)
    else
      $scene.spriteset.addUserAnimation(Settings::RUSTLE_NORMAL_ANIMATION_ID,pos_x,pos_y) if defined?($scene.spriteset)
    end
  else # Cuevas y demás
    #echoln "Animación de encuentro en cueva"
    $scene.spriteset.addUserAnimation(2,pos_x,pos_y) if defined?($scene.spriteset)
  end
end


#===============================================================================
# adding a new variable remaining_steps and replacing the method increase_steps
# in class Game_PokeEvent to count the remaining steps of the PokeEvent of the 
# overworld encounter before vanishing from map and to make them disappear after
# remaining_steps became <= 0 
#===============================================================================
class Game_PokeEvent < Game_Event
  attr_accessor :remaining_steps #counts the remaining steps of an overworld encounter before vanishing 
  attr_accessor :seguro_pasos_poke

  alias o_initialize initialize unless method_defined?(:o_initialize)
  def initialize(map_id, event, map=nil)
    o_initialize(map_id, event, map)
    @remaining_steps   = VisibleEncounterSettings::DEFAULT_STEPS_BEFORE_VANISH
    @seguro_pasos_poke = false
  end
  
  alias voe_increase_steps increase_steps unless method_defined?(:voe_increase_steps)
  def increase_steps
    if @remaining_steps <= 0
      removeThisEventfromMap
    else
      @remaining_steps-=1 if @seguro_pasos_poke
      voe_increase_steps
    end
  end


  def move_generic(dir, turn_enabled = true)
    turn_generic(dir) if turn_enabled
    if can_move_in_direction?(dir)
      turn_generic(dir)
      @move_initial_x = @x
      @move_initial_y = @y
      @x += (dir == 4) ? -1 : (dir == 6) ? 1 : 0
      @y += (dir == 8) ? -1 : (dir == 2) ? 1 : 0
      @move_timer = 0.0
      @seguro_pasos_poke = true
      increase_steps
    else
      check_event_trigger_touch(dir)
    end
  end


  
  # self.map_id bzw. @map_id

  def removeThisEventfromMap
    if $game_map.events.has_key?(@id) and $game_map.events[@id]==self
      if defined?($scene.spritesets)
        for sprite in $scene.spritesets[$game_map.map_id].character_sprites
          if sprite.character==self

            if $game_map.events[id].direction==8 #mirando arriba
              animacion_al_desaparecer_poke($game_map.events[id].x, $game_map.events[id].y+1)
            elsif  $game_map.events[id].direction==2 #mirando abajo
              animacion_al_desaparecer_poke($game_map.events[id].x, $game_map.events[id].y-1)
            elsif  $game_map.events[id].direction==4 #mirando izda
              animacion_al_desaparecer_poke($game_map.events[id].x+1, $game_map.events[id].y)
            elsif  $game_map.events[id].direction==6 # mirando dcha
              animacion_al_desaparecer_poke($game_map.events[id].x-1, $game_map.events[id].y)
            end

            $scene.spritesets[$game_map.map_id].character_sprites.delete(sprite)
            sprite.dispose
            break
          end
        end
      end
      $game_map.events.delete(@id)
    else
      if $map_factory
        for map in $map_factory.maps
          if map.events.has_key?(@id) and map.events[@id]==self
            if defined?($scene.spritesets) && $scene.spritesets[self.map_id] && $scene.spritesets[self.map_id].character_sprites
              for sprite in $scene.spritesets[self.map_id].character_sprites
                if sprite.character==self

                  if map.events[id].direction==8 #mirando arriba
                    animacion_al_desaparecer_poke(map.events[id].x,map.events[id].y+1)
                  elsif  map.events[id].direction==2 #mirando abajo
                    animacion_al_desaparecer_poke(map.events[id].x,map.events[id].y-1)
                  elsif  map.events[id].direction==4 #mirando izda
                    animacion_al_desaparecer_poke(map.events[id].x+1,map.events[id].y)
                  elsif  map.events[id].direction==6 # mirando dcha
                    animacion_al_desaparecer_poke(map.events[id].x-1,map.events[id].y)
                  end

                  $scene.spritesets[map.map_id].character_sprites.delete(sprite)
                  sprite.dispose
                  break
                end
              end
            end
            map.events.delete(@id)
            break
          end
        end
      else
        raise ArgumentError.new(_INTL("Actually, this should not be possible"))
      end
    end
  end
end


          #########################################################
          #                                                       #
          #             3. PART: ADDITIONAL FEATURES              #
          #                                                       #
          #########################################################

#===============================================================================
# introduces EventHandlers
# :on_wild_pokemon_created_for_spawning_end (used for roamer)
# :on_wild_pokemon_created_for_spawning (nessessary?)
# This Event is triggered  when a new pokemon spawns. Use this Event instead of OnWildPokemonCreate
# if you want to add a new procedure that modifies a pokemon on spawning 
# but not on creation while going into battle with an already spawned pokemon.
#Note that OnPokemonCreate is also triggered when a pokemon is created for spawning,
#But OnPokemonCreateForSpawning is not triggered when a pokemon is created in other situations than for spawning
#===============================================================================

#-------------------------------------------------------------------------------
# adding a process to the EncounterModifier TriggerEncounterEnd For roaming
# encounters. We have to set roamed_already to true after one roamer spawned.
#-------------------------------------------------------------------------------

#===============================================================================
# adds new parameter battlingSpawnedPokemon to the class PokemonGlobalMetadata.
# Also overrides initialize include that parameter there.
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :creatingSpawningPokemon
  attr_accessor :battlingSpawnedPokemon

  alias original_initialize initialize unless method_defined?(:original_initialize)
  def initialize
    creatingSpawningPokemon = false
    battlingSpawnedPokemon = false
    original_initialize
  end
end


          #########################################################
          #                                                       #
          #            4. PART: ROAMING POKEMON                   #
          #                                                       #
          #########################################################
#===============================================================================
# This part is about roaming pokemon
#
# By default roaming pokemon can encounter as overworld and as normal encounters
#===============================================================================

#-------------------------------------------------------------------------------
# Overwriting pbRoamingMethodAllowed such that the encounter_type is not computed
# by the position of the player but of the chosen tile near the player
# Returns whether the given category of encounter contains the actual encounter
# method that will not occur in the player's current position.
#-------------------------------------------------------------------------------
def pbRoamingMethodAllowed(roamer_method)
  enc_type = $game_temp.encounter_type # $game_temp.encounter_type stores the encounter type of the chosen tile
  type = GameData::EncounterType.get(enc_type).type
  case roamer_method
  when 0   # Any step-triggered method (except Bug Contest)
    return [:land, :cave, :water].include?(type)
  when 1   # Walking (except Bug Contest)
    return [:land, :cave].include?(type)
  when 2   # Surfing
    return type == :water
  when 3   # Fishing
    return type == :fishing
  when 4   # Water-based
    return [:water, :fishing].include?(type)
  end
  return false
end

#-------------------------------------------------------------------------------
# adding a process to the EncounterModifier TriggerEncounterEnd For roaming
# encounters. We have to set roamed_already to true after one roamer spawned.
#-------------------------------------------------------------------------------  
EventHandlers.add(:on_wild_pokemon_created_for_spawning_end, :roamer_spawned, proc{
  if $game_temp.roamer_index_for_encounter != nil &&  $PokemonGlobal.roamEncounter != nil
    $PokemonGlobal.roamEncounter = nil
    $PokemonGlobal.roamedAlready = true
    $game_temp.roamer_index_for_encounter = nil
  end
})










          #########################################################
          #                                                       #
          #          ADD-ON:  MAX SPAWN by TrankerGolD            #
          #                                                       #
          #########################################################

# CONTROLAR CUÁNTOS POKÉMON SALEN A LA VEZ EN PANTALLA



# You can use this add-on to set a maximal number of wild Encounters Events
# that can be spawned on the map at the same time.
# Use the parameter MAX_SPAWN (see below) to set the limit of overworld pokeEvents at the same time.

# FEATURES:
# * Stop more PokeEvent from spawning with the MAX_SPAWN parameter

#===============================================================================
# overwriting method pbSpawnOnStepTaken in script visible overworld wild encounters
# to include maximal number of spawned pokemon
#===============================================================================
alias o_pbSpawnOnStepTaken pbSpawnOnStepTaken
def pbSpawnOnStepTaken(repel_active)
  # return false if VisibleEncounterSettings::MAX_SPAWN>0 && pbCountPokeEvent >= VisibleEncounterSettings::MAX_SPAWN
  
  # Choose 1 random tile from 1 random ring around the player
  i = rand(4)
  r = rand((i+1)*8)
  x = $game_player.x
  y = $game_player.y
  if r<=(i+1)*2
    x = $game_player.x-i-1+r
    y = $game_player.y-i-1
  elsif r<=(i+1)*6-2
    x = [$game_player.x+i+1,$game_player.x-i-1][r%2]
    y = $game_player.y-i+((r-1-(i+1)*2)/2).floor
  else
    x = $game_player.x-i+r-(i+1)*6
    y = $game_player.y+i+1
  end
=begin
  horizontal_size = 4
  vertical_size = 4
  gp = $game_player
  event_count = $game_map.events.values.find_all { |event|
  ((event.x - gp.x).abs <= horizontal_size) && ((event.y - gp.y).abs <= vertical_size) &&
  event.is_a?(Game_PokeEvent)}.size
  return if event_count>=8
  
  #Evitar que spawnee un pokémon al lado de otro
  for wildpokes in $game_map.events.values
    if (((wildpokes.x - x).abs <= 1) || ((wildpokes.y - y).abs <= 1)) && (wildpokes.is_a?(Game_PokeEvent))
      return
    end
  end
=end
  o_pbSpawnOnStepTaken(repel_active)
end 



#===============================================================================
# adding a new event handler on Battle end to update the catchchain (where the
# pokemon-kill-chain is saved)
#===============================================================================
#=begin
EventHandlers.add(:on_wild_battle_end, :shiny_chain_aumenta,
  proc { |species, level, decision|
    # Only process on defeat (1) or capture (4)
    next unless [1, 4].include?(decision)
    
    # Initialize catch combo if needed
    $PokemonGlobal.catchcombo = [0, 0] if $PokemonGlobal.catchcombo.nil?
    
    # Cache combo array for better performance
    combo = $PokemonGlobal.catchcombo
    
    # Reset combo if species changed, otherwise increment
    if combo[1] != species
      combo[0], combo[1] = 0, species
    end
    
    combo[0] += 1

    $PokemonGlobal.catchcombo = combo
    
    # Show chain messages if enabled and chain > 1
    next unless combo[0] > 1 && $PokemonSystem.mensaje_shinys == 0
    
    species_name = GameData::Species.get(species).name
    combo_count = combo[0]
    
    # Main chain message
    pbMessage(_INTL("¡Cadena de {1} {2} seguidos!", combo_count, species_name))
    
    # Milestone messages with lookup table
    milestone_messages = {
      10 => "¡Aumenta ligeramente la probabilidad de encontrar uno variocolor!",
      20 => "¡Aumenta un poco la probabilidad de encontrar uno variocolor!",
      30 => "¡Aumenta mucho la probabilidad de encontrar uno variocolor!",
      40 => ["¡Aumenta bastante la probabilidad de encontrar uno variocolor!",
             "Ya no aumentará más aunque sigas derrotando a más Pokémon."]
    }
    
    if milestone_messages.key?(combo_count)
      messages = milestone_messages[combo_count]
      if messages.is_a?(Array)
        messages.each { |msg| pbMessage(_INTL(msg)) }
      else
        pbMessage(_INTL(messages))
      end
    end
  }
)
#=end







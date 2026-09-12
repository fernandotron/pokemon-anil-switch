#===============================================================================#
# Whether the options menu shows the speed up settings (true by default)
#===============================================================================#
module Settings
  SPEED_OPTIONS = true
end

#===============================================================================#
# Speed-up config
#===============================================================================#
SPEEDUP_STAGES = [1, 2, 2.5]
$GameSpeed = 0
$CanToggle = true
$RefreshEventsForTurbo = false
$SpeedDiference = 0

#===============================================================================#
# Set $CanToggle depending on the saved setting
#===============================================================================#
module Game
  class << self
    alias_method :original_load, :load unless method_defined?(:original_load)
  end

  def self.load(save_data)
    original_load(save_data)
    SaveData.load_options rescue nil
    SaveData.load_controls rescue nil
    # echoln "UNSCALED #{System.unscaled_uptime} * #{SPEEDUP_STAGES[$GameSpeed]} - #{$GameSpeed}"
    $CanToggle = ($PokemonSystem.nil? || ($PokemonSystem.only_speedup_battles || 0) == 0)
  end
end

#===============================================================================#
# Handle incrementing speed stages if $CanToggle allows it
#===============================================================================#
module Input
  def self.update
    update_KGC_ScreenCapture
    pbScreenCapture if trigger?(Input::F8)
    turbo_triggered = (Input.respond_to?(:trigger_turbo?) ? Input.trigger_turbo? : (trigger?(Input::ALT) || trigger?(Input::AUX1)))
    if $CanToggle && (turbo_triggered && !Input.text_input)
      $GameSpeed += 1
      if $GameSpeed >= SPEEDUP_STAGES.size
        $GameSpeed = 0 
        $SpeedDiference += (System.real_uptime * SPEEDUP_STAGES[-1])
      end
      # $PokemonSystem.battle_speed = $GameSpeed if $PokemonSystem && $PokemonSystem.only_speedup_battles == 1
      $buttonframes = 0
      $RefreshEventsForTurbo  = true
    end
  end
end

#===============================================================================#
# Return System.Uptime with smooth delta accumulation (no skips or jumps)
#===============================================================================#
module System
  @last_real_time = nil
  @accumulated_time = 0.0

  def self.unscaled_uptime
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue (Time.now.to_f rescue 0.0))
  end

  def self.real_uptime
    unscaled_uptime
  end

  def self.uptime
    current_real = unscaled_uptime
    @last_real_time ||= current_real
    @accumulated_time ||= 0.0
    delta = current_real - @last_real_time
    delta = 0.0 if delta < 0
    delta = 0.05 if delta > 0.05 # Cap at 50ms per frame to prevent skipping animations
    @last_real_time = current_real

    speed = (defined?(SPEEDUP_STAGES) && defined?($GameSpeed) && $GameSpeed && SPEEDUP_STAGES[$GameSpeed]) ? SPEEDUP_STAGES[$GameSpeed] : 1
    @accumulated_time += delta * speed
    @accumulated_time
  end
end

#===============================================================================#
# Event handlers for in-battle speed-up restrictions
#===============================================================================#
EventHandlers.add(:on_start_battle, :start_speedup, proc {
  $CanToggle = true if $PokemonSystem.only_speedup_battles == 1
  $GameSpeed = $PokemonSystem.battle_speed if $PokemonSystem.only_speedup_battles == 1
})
EventHandlers.add(:on_end_battle, :stop_speedup, proc {
  $GameSpeed = 0 if $PokemonSystem.only_speedup_battles == 1
  $CanToggle = false if $PokemonSystem.only_speedup_battles == 1
})


#===============================================================================#
# Can only change speed in battle during command phase (prevents weird animation glitches)
#===============================================================================#
# class Battle
#   alias_method :original_pbCommandPhase, :pbCommandPhase unless method_defined?(:original_pbCommandPhase)
#   def pbCommandPhase
#     $CanToggle = true
#     original_pbCommandPhase
#     $CanToggle = false
#   end
# end

#===============================================================================#
# Fix for consecutive battle soft-lock glitch
#===============================================================================#
alias :original_pbBattleOnStepTaken :pbBattleOnStepTaken
def pbBattleOnStepTaken(repel_active)
  return if $game_temp.in_battle
  original_pbBattleOnStepTaken(repel_active)
end

class Game_Event < Game_Character
  def pbGetInterpreter
    return @interpreter
  end

  def pbResetInterpreterWaitCount
    @interpreter.pbRefreshWaitCount if @interpreter
  end

  def IsParallel
    return @trigger == 4
  end  
end  

class Interpreter
  def pbRefreshWaitCount
    @wait_count = 0
    @wait_start = System.uptime
  end  
end  

class Window_AdvancedTextPokemon < SpriteWindow_Base
  def pbResetWaitCounter
    @wait_timer_start = nil
    @waitcount = 0
    @display_last_updated = nil
  end  
end  

$CurrentMsgWindow = nil;
def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  ret = 0
  msgwindow = pbCreateMessageWindow(nil, skin)
  $CurrentMsgWindow = msgwindow

  if commands
    ret = pbMessageDisplay(msgwindow, message, true,
                           proc { |msgwndw|
                             next Kernel.pbShowCommands(msgwndw, commands, cmdIfCancel, defaultCmd, &block)
                           }, &block)
  else
    pbMessageDisplay(msgwindow, message, &block)
  end
  pbDisposeMessageWindow(msgwindow)
  $CurrentMsgWindow = nil
  Input.update
  return ret
end

#===============================================================================#
# Fix for scrolling fog speed
#===============================================================================#
class Game_Map
  alias_method :original_update, :update unless method_defined?(:original_update)

  def update
    if $RefreshEventsForTurbo
      if $game_map&.events
        $game_map.events.each_value { |event| event.pbResetInterpreterWaitCount }
      end
      @scroll_timer_start = System.uptime/SPEEDUP_STAGES[SPEEDUP_STAGES.size-1] if (@scroll_distance_x || 0) != 0 || (@scroll_distance_y || 0) != 0
      $CurrentMsgWindow.pbResetWaitCounter if $game_temp.message_window_showing && $CurrentMsgWindow 
      $RefreshEventsForTurbo = false
    end

    temp_timer = @fog_scroll_last_update_timer
    @fog_scroll_last_update_timer = System.uptime # Don't scroll in the original update method
    original_update
    @fog_scroll_last_update_timer = temp_timer
    update_fog
  end

  def update_fog
    uptime_now = System.unscaled_uptime
    @fog_scroll_last_update_timer = uptime_now unless @fog_scroll_last_update_timer
    speedup_mult = $PokemonSystem.only_speedup_battles == 1 ? 1 : SPEEDUP_STAGES[$GameSpeed]
    scroll_mult = (uptime_now - @fog_scroll_last_update_timer) * 5 * speedup_mult
    @fog_ox -= @fog_sx * scroll_mult
    @fog_oy -= @fog_sy * scroll_mult
    @fog_scroll_last_update_timer = uptime_now
  end
end

# SpriteAnimation is handled cleanly in 007_RPG_Sprite.rb

#===============================================================================#
# PokemonSystem Accessors
#===============================================================================#
class PokemonSystem
  alias_method :original_initialize, :initialize unless method_defined?(:original_initialize)
  attr_accessor :only_speedup_battles
  attr_accessor :battle_speed
  attr_accessor :turbo_button
  attr_accessor :plus_action
  attr_accessor :button_layout

  def initialize
    original_initialize
    @only_speedup_battles = 0 # Speed up setting (0=always, 1=battle_only)
    @battle_speed = 0 # Depends on the SPEEDUP_STAGES array size
    @turbo_button = 0
    @plus_action  = 0
    @button_layout = 0
  end
end

MenuHandlers.add(:options_menu, :turbo, {
  "name"        => _INTL("Modo turbo"),
  "order"       => 45,
  "type"        => EnumOption,
  "condition"   => proc { next expshare_enabled? },
  "parameters"  => [_INTL("Siempre"), _INTL("Combates")],
  "description" => _INTL("Define el modo del turbo, si se puede activar siempre o solo en combates."),
  "get_proc"    => proc { next $PokemonSystem.only_speedup_battles || 0 },
  "set_proc"    => proc { |value, _scene| 
    $PokemonSystem.only_speedup_battles = value 
    $CanToggle = ($PokemonSystem.only_speedup_battles || 0) == 0
    $GameSpeed = 0 if $PokemonSystem.only_speedup_battles == 1
  }
})



module Graphics
  class << self
    alias _old_update_turbo update
    def update
      _old_update_turbo
      $buttonframes = 150 if !$buttonframes
      if $buttonframes < 150 # Frames en pantalla
        if !@boton_turbo || @boton_turbo.disposed?
          @boton_turbo = Sprite.new
          if $GameSpeed == 0
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo0")
          elsif $GameSpeed == 1
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo1")
          else
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo2")
          end
          @boton_turbo.z = 999999
        elsif @boton_turbo
          if $GameSpeed == 0
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo0")
          elsif $GameSpeed == 1
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo1")
          else
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo2")
          end
        end
        $buttonframes += 1
        if $buttonframes == 150
          @boton_turbo.dispose
        end
      end
    end
  end
end

# Asegura que al cambiar de mapa, el jugador vuelva a tener colisiones.
EventHandlers.add(:on_enter_map, :fix_turbo_collision, proc { |_map_id|
  # Solo forzamos la colisión si NO estamos presionando CTRL en modo Debug.
  unless $DEBUG && Input.press?(Input::CTRL)
    if $game_player
      # Verificar si el jugador tiene through activado
      if $game_player.through
        player_x = $game_player.x
        player_y = $game_player.y
        
        # Desactivar through temporalmente para verificar colisiones correctamente
        $game_player.through = false
        
        # Verificar si la posición actual es transitable
        unless $game_map.passable?(player_x, player_y, 0, $game_player)
          # Buscar la posición transitable más cercana
          passable_x, passable_y = $game_player.find_nearest_passable_spot(player_x, player_y)
          if passable_x && passable_y
            $game_player.moveto(passable_x, passable_y)
          end
        end
      end
      $game_player.always_on_top = false
    end
  end
})
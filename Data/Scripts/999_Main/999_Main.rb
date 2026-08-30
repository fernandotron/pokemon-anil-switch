module LBDSKY
  VERSION = "1.2.0" # No modificar esto
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
  if true #$DEBUG
    pbCriticalCode { mainFunctionDebug }
  else
    mainFunctionDebug
  end
  return 1
end

def mainFunctionDebug
  begin
    MessageTypes.load_default_messages if FileTest.exist?("Data/messages_core.dat")
    PluginManager.runPlugins
    if Dir.exist?("Plugins/misc_scripts")
      Dir.glob("Plugins/misc_scripts/*.rb").sort.each do |f|
        begin
          load f
        rescue Exception => e
          log_compat("[MISC_SCRIPTS LOAD ERROR] #{f}: #{e.class} - #{e.message}") rescue nil
        end
      end
    end
    Compiler.main
    Game.initialize
    Game.set_up_system
    Graphics.update
    Graphics.freeze
    $scene = pbCallTitle
    $scene.main until $scene.nil?
    Graphics.transition
  rescue Hangup
    pbPrintException($!) if !$DEBUG
    pbEmergencySave
    raise
  end
end

loop do
  retval = mainFunction
  case retval
  when 0   # failed
    loop do
      Graphics.update
    end
  when 1   # ended successfully
    break
  end
end


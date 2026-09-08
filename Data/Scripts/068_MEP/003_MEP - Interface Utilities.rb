#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
class Swdfm_Exp_Screen
  def set_comparative_z(first_tile, second_tile, amount = 1)
    return unless @sprites[second_tile] && @sprites[first_tile]
    set_to = @sprites[second_tile].z
    set_to += amount
    @sprites[first_tile].z = set_to
  end
  
  def main
    auto_close_frames = 0
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      if @elapsed < @total_frames
        update_bars
      else
        auto_close_frames += 1
        # Cierre automatico tras 1.2 segundos sin pulsar teclas
        @do_break = true if auto_close_frames >= 48
      end
      if Input.trigger?(Input::USE)
        do_action_USE
      elsif Input.trigger?(Input::BACK)
        @do_break = true
        do_action_BACK
      end
      break if @do_break
    end
  end
  
  def run
    begin
      pbDeactivateWindows(@sprites)
      pbFadeInAndShow(@sprites)
      main
      pbFadeOutAndHide(@sprites)
    ensure
      pbDisposeSpriteHash(@sprites) rescue nil
      if @viewport && !@viewport.disposed?
        @viewport.dispose rescue nil
      end
      @viewport = nil
      $active_exp_panel_viewport = nil
    end
  end
  
  def dispose_if_there(name)
    @sprites[name].dispose if @sprites[name] && !@sprites[name].disposed? rescue nil
    @sprites[name] = nil
  end
end

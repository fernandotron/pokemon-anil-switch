#===============================================================================
# * Punch Bag Game - by FL (Credits will be apreciated)
# * Modificado para entrenamiento proporcional de EVs - Versión 21 únicamente
#===============================================================================
#
# Este script es para Pokémon Essentials v21. El jugador selecciona un pokémon 
# para un minijuego simple donde gana puntos mientras más cerca del centro esté 
# el cursor cuando se presiona el botón. Los EVs e IVs pueden ser recompensas.
#
#== INSTALACIÓN ================================================================
#
# Ponlo encima de main O conviértelo en plugin. Crea la carpeta "Punch Bag" en
# Graphics/UI y pon las imágenes (puede funcionar con otros tamaños):
# -  32x32  arrow (flecha)
# - 262x20  bar (barra)
# - 512x288 bg (fondo)
# - 104x256 punchbag (saco de boxeo)
# -  48x40  star (estrella)
#
#== CÓMO USAR ==================================================================
#
# NUEVO: Para entrenamiento proporcional de EVs, usa:
# PunchBag.play_proportional_ev_training  (con selector de estadística)
#
# O directamente una estadística específica:
# PunchBag.play_proportional_ev(20, :HP)  (20 rondas, PS)
#
#== EJEMPLOS ===================================================================
#
# - Entrenamiento proporcional con selector de stat:
#  PunchBag.play_proportional_ev_training
#
# - Entrenamiento específico de PS con 10 rondas:
#  PunchBag.play_proportional_ev(10, :HP)
#
# - Método original (15 rondas sin recompensa):
#  PunchBag.play(15)
#
#===============================================================================

if defined?(PluginManager) && !PluginManager.installed?("Punch Bag Game")
  PluginManager.register({                                                 
    :name    => "Punch Bag Game",                                        
    :version => "1.3.0 - v21",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=346235",
    :credits => "FL - Modificado para EVs proporcionales"
  })
end

module PunchBag
  class Parameters
    attr_accessor :rounds        # Número de rondas
    attr_accessor :canCancel     # Puede cancelar el minijuego
    attr_accessor :acceptFainted # Acepta pokémon debilitados
    attr_accessor :blockMax      # Bloquea pokémon con stats al máximo
    attr_accessor :minLevel      # Nivel mínimo requerido
    attr_accessor :minScore      # Puntuación mínima para recompensa
    attr_accessor :stats         # Debe ser un símbolo o array de símbolos
    attr_accessor :evGain        # EVs a ganar (fijo)
    attr_accessor :ivGain        # IVs a ganar (fijo)
    attr_accessor :maximizeIV    # Maximizar IVs

    def initialize(rounds)
      @rounds = rounds
      @canCancel = true
      @acceptFainted = false
      @blockMax = false
      @minLevel = 0
      @minScore = 0
      @stats = [
        :HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE
      ]
      @evGain = 0
      @ivGain = 0
      @maximizeIV = false
    end
    
    def setCanCancel(canCancel)
      @canCancel = canCancel
      return self
    end
    
    def setAcceptFainted(acceptFainted)
      @acceptFainted = acceptFainted
      return self
    end
    
    def setBlockMax(blockMax)
      @blockMax = blockMax
      return self
    end
    
    def setMinLevel(minLevel)
      @minLevel = minLevel
      return self
    end
    
    def setMinScore(minScore)
      @minScore = minScore
      return self
    end
    
    def setStats(stats)
      @stats = stats
      return self
    end
    
    def setEvGain(evGain)
      @evGain = evGain
      return self
    end
    
    def setIvGain(ivGain)
      @ivGain = ivGain
      return self
    end
    
    def setMaximizeIV(maximizeIV)
      @maximizeIV = maximizeIV
      return self
    end

    def statArray
      return @stats.is_a?(Array) ? @stats : [@stats]
    end
  end

  class Scene
    # El tiempo está en segundos. La velocidad en píxeles por segundo
    # Tamaño de los puntos válidos de la barra entre la izquierda y el centro
    BAR_LEFT_SIZE = 128 
    ARROW_SPEED = 640
    ARROW_SCORE_DISTANCE = 16 # -1 por cada esta distancia del centro
    MAX_SCORE = 5
    MIN_SCORE = 1
      
    BAG_SPEED_ARRAY = [80,120,160]
    BAG_ANGLES_ARRAY = [0,16,32,64]
    POKEMON_SPEED = 640
    POKEMON_DISTANCE = 64
    WAIT_ANIMATION_TIME = 0.2
    
    def pbStartScene(pkmn,rounds)
      @sprites={} 
      @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z=99999
      @sprites["field"]=IconSprite.new(0,0,@viewport)
      @sprites["field"].setBitmap("Graphics/UI/Punch Bag/bg")
      @sprites["field"].y=-48
      # Un fondo extra. Usado porque el primero no tiene el tamaño de pantalla,
      # así que una pequeña parte puede verse debajo de la ventana.
      @sprites["fieldBack"]=IconSprite.new(0,0,@viewport)
      @sprites["fieldBack"].setBitmap("Graphics/UI/Punch Bag/bg")
      @sprites["fieldBack"].y=@sprites["field"].bitmap.height
      @sprites["fieldBack"].z=@sprites["field"].z-1 # Debajo del campo
      @sprites["scorebox"]=Window_AdvancedTextPokemon.new
      @sprites["scorebox"].viewport=@viewport
      pbBottomLeftLines(@sprites["scorebox"],2)
      @sprites["scorebox"].width=160
      @sprites["scorebox"].z=2
      @sprites["barbox"]=Window_AdvancedTextPokemon.new
      @sprites["barbox"].viewport=@viewport
      pbBottomLeftLines(@sprites["barbox"],2)
      @sprites["barbox"].x=@sprites["scorebox"].width
      @sprites["barbox"].width=Graphics.width-@sprites["scorebox"].width
      @sprites["barbox"].y = @sprites["scorebox"].y + 20
      @sprites["barbox"].z=2
      @sprites["starbox"]=Window_AdvancedTextPokemon.new
      @sprites["starbox"].viewport=@viewport
      pbBottomLeftLines(@sprites["starbox"],1)
      @sprites["starbox"].y=@sprites["scorebox"].y-@sprites["starbox"].height
      @sprites["starbox"].z=2
      @sprites["punchbag"]=IconSprite.new(0,0,@viewport)  
      @sprites["punchbag"].setBitmap("Graphics/UI/Punch Bag/punch_bag")
      @sprites["punchbag"].x=Graphics.width/2
      # El centro del saco es la cuerda
      @sprites["punchbag"].ox=@sprites["punchbag"].bitmap.width/2 
      @sprites["punchbag"].y=-38
      @sprites["pokemonback"]=PokemonSprite.new(@viewport)
      @sprites["pokemonback"].setPokemonBitmap(pkmn,true) 
      @sprites["pokemonback"].setOffset(PictureOrigin::BOTTOM)
      @sprites["pokemonback"].x += @sprites["punchbag"].x-56-POKEMON_DISTANCE
      @sprites["pokemonback"].y += 228
      @sprites["pokemonback"].z=1
      @sprites["bar"]=IconSprite.new(0,0,@viewport)
      @sprites["bar"].setBitmap("Graphics/UI/Punch Bag/bar")
      @sprites["bar"].x=@sprites["barbox"].x+(
        @sprites["barbox"].width-@sprites["bar"].bitmap.width
      )/2
      @sprites["bar"].y=@sprites["barbox"].y+44
      @sprites["bar"].z=3
      @sprites["arrow"]=IconSprite.new(0,0,@viewport)
      @sprites["arrow"].setBitmap("Graphics/UI/Punch Bag/arrow")
      @arrowXMiddle = (
        @sprites["bar"].x - @sprites["arrow"].bitmap.width/2 + 4 + BAR_LEFT_SIZE
      )
      @sprites["arrow"].x = @arrowXMiddle-BAR_LEFT_SIZE
      @sprites["arrow"].y = @sprites["bar"].y-24
      @sprites["arrow"].z=3
      for i in 0...5
        @sprites["star#{i}"]=IconSprite.new(0,0,@viewport)
        @sprites["star#{i}"].setBitmap("Graphics/UI/Punch Bag/star")
        @sprites["star#{i}"].x=32+(@sprites["star#{i}"].bitmap.width+52)*i
        @sprites["star#{i}"].y=@sprites["starbox"].y+12
        @sprites["star#{i}"].z=3
      end
      @rounds = rounds
      pbMakeAllStarsInvisible
      @sprites["overlay"]=BitmapSprite.new(
        Graphics.width, Graphics.height, @viewport
      )
      @moving=true
      @right=false
      @score = 0
      @lastScore = 0
      @shoots = 0
      @endGame=false
      @nextAngle=0
      @lastAngle=0
      @angleDirection=1
      @bagAnimating=false
      @bagWaitTime=0
      @pokemonAnimating=false
      @pokemonWaitTime=0
      @animating=false
      @arrowX = @sprites["arrow"].x
      @pokemonX = @sprites["pokemonback"].x
      pbSetSystemFont(@sprites["overlay"].bitmap)
      pbDrawText
      pbFadeInAndShow(@sprites) { update }
    end

    def pbDrawText
      @sprites["scorebox"].text = _INTL(
        "Puntos: {1} \nGolpe: {2}/{3}",@score,@shoots,@rounds
      )
    end
    
    def pbDrawStars(stars)
      pbMakeAllStarsInvisible
      for i in 0...stars
        @sprites["star#{i}"].visible=true
      end
    end
    
    def pbMakeAllStarsInvisible
      for i in 0...5
        @sprites["star#{i}"].visible=false
      end
    end  

    def pbMain(canCancel)
      @timeCount=0
      loop do
        Graphics.update
        Input.update
        self.update
        if @endGame
          return @score if !@animating
        else  
          if (
            Input.trigger?(Input::B) && canCancel && 
            pbConfirmMessage(_INTL("¿Salir?")){ update }
          )
            pbPlayCursorSE
            break
          end
          if Input.trigger?(Input::C) && @lastScore==0
            distance = BAR_LEFT_SIZE 
            if @arrowX>@arrowXMiddle
              distance -= @arrowX-@arrowXMiddle
            else 
              distance -= @arrowXMiddle-@arrowX
            end
            @lastScore=[(
              (distance - BAR_LEFT_SIZE)/ARROW_SCORE_DISTANCE.to_f + MAX_SCORE
            ).round, MIN_SCORE].max
            @sprites["arrow"].visible = false
          end
          if @moving
            @right = true  if @arrowX<=@arrowXMiddle-BAR_LEFT_SIZE
            @right = false if @arrowX>=@arrowXMiddle+BAR_LEFT_SIZE            
            @arrowX += (
              (@right ? ARROW_SPEED : -ARROW_SPEED) * Graphics.delta
            )
            @sprites["arrow"].x = @arrowX.round
          end
        end
        @timeCount += Graphics.delta
      end
      return nil
    end
    
    def update
      updateAnimation
      pbUpdateSpriteHash(@sprites)
    end
    
    def computeScore
      # Calcula la puntuación en cierto punto de la animación.
      # Cuando el saco se detiene en el aire por primera vez en ese golpe
      @shoots+=1
      @endGame = true if @shoots==@rounds
      @score+=@lastScore
      pbSEPlay("Pkmn move learnt") if @lastScore==MAX_SCORE
      pbDrawText
      pbDrawStars(@lastScore)
      @lastScore = 0
      @scoreComputed = true
      @sprites["arrow"].visible = true
    end  
    
    def setAnimation
      lastScoreFromMax = @lastScore-MAX_SCORE
      @nextAngle = case lastScoreFromMax
      when 0;  BAG_ANGLES_ARRAY[3] # Golpe perfecto
      when -1; BAG_ANGLES_ARRAY[2]
      when -2; BAG_ANGLES_ARRAY[1]
      else;    BAG_ANGLES_ARRAY[0]
      end
      @angleDirection = 1
      lastScoreFromMax==0 ? 64 : 32
      @bagSpeedIndex = lastScoreFromMax==0 ? 2 : 0
      @pokemonAnimating=true
      @pokemonSpeed=POKEMON_SPEED
      @pokemonX=@pokemonX.floor
      @pokemonDestiny=@pokemonX+POKEMON_DISTANCE
      @scoreComputed=false
    end  
    
    def updateAnimation
      @animating = @pokemonAnimating || @bagAnimating
      if !@animating && @lastScore!=0
        setAnimation
      end  
      updateAnimationBag if @bagAnimating
      updateAnimationPokemon if @pokemonAnimating
    end  
    
    def updateAnimationBag
      return if @bagWaitTime>@timeCount
      angle = @sprites["punchbag"].angle
      angle = @nextAngle if reached(angle, @nextAngle, @angleDirection)
      if angle == @nextAngle
        if @nextAngle==0
          if @bagSpeedIndex>0 # Puntuación máxima
            @nextAngle=-BAG_ANGLES_ARRAY[-2]
          else
            @bagAnimating=false
          end  
        else  
          if @nextAngle<0 # Revertir dirección
            @nextAngle=BAG_ANGLES_ARRAY[-3]
          else
            @nextAngle=0
          end
          @bagWaitTime=@timeCount+WAIT_ANIMATION_TIME-0.001
          computeScore if !@scoreComputed 
        end
        @angleDirection = @nextAngle>angle ? 1 : -1
      else
        # Cortar la velocidad a la mitad cada vez que el saco cruza el medio
        if (@lastAngle < 0) != (angle < 0) && @bagSpeedIndex!=0 
          @bagSpeedIndex-=1 
        end
        @lastAngle = angle
        angle+=BAG_SPEED_ARRAY[@bagSpeedIndex] * @angleDirection * Graphics.delta
      end
      @sprites["punchbag"].angle = angle
    end  
    
    def updateAnimationPokemon
      return if @pokemonWaitTime>@timeCount
      @pokemonX+=@pokemonSpeed * Graphics.delta
      if reached(@pokemonX, @pokemonDestiny, @pokemonSpeed)
        @pokemonX = @pokemonDestiny
        if @pokemonSpeed>0 # Configurar para moverse hacia atrás
          # SE para golpear el saco
          pbSEPlay(getHitSEName(@lastScore-MAX_SCORE))
          if @nextAngle==0 # Si no hay animación del saco, calcular ahora
            computeScore
          else
            @bagAnimating=true
          end
          @pokemonSpeed/=-2
          @pokemonDestiny=@pokemonX-POKEMON_DISTANCE
          @pokemonWaitTime=@timeCount+WAIT_ANIMATION_TIME-0.001
        else
          @pokemonAnimating=false
        end
      end  
      @sprites["pokemonback"].x = @pokemonX.floor
    end

    # Un >= que funciona con pasos/velocidad negativos
    def reached(value, destiny, sign)
      return sign < 0 ? value <= destiny : value >= destiny
    end

    def getHitSEName(lastScoreFromMax)
      return case lastScoreFromMax
        when -1,0;  "Battle damage super"
        when -2;    "Battle damage normal"
        else;       "Battle damage weak"
      end
    end
    
    def pbEndScene
      pbFadeOutAndHide(@sprites) { update }
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end
  end

  class Screen
    def initialize(scene)
      @scene=scene
    end

    def pbStartScreen(pokemon,rounds,canCancel)
      @scene.pbStartScene(pokemon,rounds)
      ret=@scene.pbMain(canCancel)
      @scene.pbEndScene
      return ret
    end
  end

  # Método original para compatibilidad
  def self.play(param)
    score = nil
    pkmn = nil
    param = Parameters.new(param) if param.is_a?(Numeric)
    pbFadeOutIn(99999){
      loop do
        pkmn = promptChoosePokemon(param)
        break if pkmn || param.canCancel
      end
      if pkmn
        scene=Scene.new
        screen=Screen.new(scene)
        score=screen.pbStartScreen(pkmn,param.rounds,param.canCancel)
      end
    }
    giveReward(pkmn, param) if score && param.minScore <= score
    return score
  end

  # NUEVO: Método para entrenamiento proporcional de EVs con selector de stat
  def self.play_proportional_ev_training
    # Permitir al jugador elegir qué stat entrenar
    stat_names = [
      "PS (HP)",
      "Ataque", 
      "Defensa",
      "Velocidad",
      "Ataque Especial",
      "Defensa Especial"
    ]
    
    stat_symbols = [
      :HP,
      :ATTACK,
      :DEFENSE, 
      :SPEED,
      :SPECIAL_ATTACK,
      :SPECIAL_DEFENSE
    ]
    
    # Mostrar menú de selección
    choice = pbShowCommands(nil, stat_names, -1, "¿Qué estadística quieres entrenar?")
    
    return nil if choice < 0 # Cancelado
    
    selected_stat = stat_symbols[choice]
    selected_name = stat_names[choice]
    
    pbMessage("Has elegido entrenar: #{selected_name}")
    pbMessage("Puntuación perfecta (50 puntos) = 126 EVs")
    pbMessage("Tu puntuación determinará el % de EVs ganados.")
    
    return play_proportional_ev(10, selected_stat)
  end

  # NUEVO: Método para entrenamiento proporcional de EVs (stat específico)
  def self.play_proportional_ev(rounds, stat_symbol)
    score = nil
    pkmn = nil
    
    # Crear parámetros básicos - no dar EVs automáticamente
    param = Parameters.new(rounds)
    param.stats = stat_symbol
    param.minScore = 1      # Cualquier puntuación da algo
    param.evGain = 1        # Marcar que vamos a dar EVs (para el filtro)
    param.canCancel = true
    param.acceptFainted = false
    param.blockMax = true   # Bloquear pokémon que ya están al máximo
    
    pbFadeOutIn(99999){
      loop do
        pkmn = promptChoosePokemon(param)
        break if pkmn || param.canCancel
      end
      if pkmn
        scene = Scene.new
        screen = Screen.new(scene)
        score = screen.pbStartScreen(pkmn, param.rounds, param.canCancel)
      end
    }
    
    # Calcular y dar EVs proporcionales si hubo puntuación
    if score && pkmn
      max_possible = rounds * 5  # Puntuación máxima posible (5 estrellas por ronda)
      min_possible = rounds * 1  # Puntuación mínima posible (1 estrella por ronda)
      
      # Calcular porcentaje de rendimiento (0-100%)
      score_range = max_possible - min_possible  # 80 para 20 rondas (100-20)
      score_above_min = score - min_possible     # Puntos por encima del mínimo
      percentage = (score_above_min.to_f / score_range * 100).round
      
      # Asegurar que el porcentaje esté entre 0-100%
      percentage = [[percentage, 0].max, 100].min
      
      # Calcular EVs a dar (máximo 126)
      max_evs_possible = 126
      evs_to_give = (max_evs_possible * percentage / 100).round
      
      # Verificar si se pueden dar los EVs
      if canIncreaseEV?(pkmn, stat_symbol)
        # Calcular cuántos EVs se pueden dar realmente
        current_ev = pkmn.ev[stat_symbol]
        ev_stat_limit = Pokemon::EV_STAT_LIMIT
        max_ev_increase = ev_stat_limit - current_ev
        
        # Verificar límite total de EVs (510)
        current_total_evs = 0
        [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE].each do |s|
          current_total_evs += pkmn.ev[s]
        end
        max_total_increase = Pokemon::EV_LIMIT - current_total_evs
        
        # Tomar el menor de los límites
        actual_evs_to_give = [evs_to_give, max_ev_increase, max_total_increase].min
        actual_evs_to_give = [actual_evs_to_give, 0].max
        
        # Dar los EVs
        evs_given = raiseEV(pkmn, stat_symbol, actual_evs_to_give)
        
        # Mostrar resultados
        pbMessage("¡Puntuación final: #{score}/#{max_possible}!")
        pbMessage("Rendimiento: #{percentage}%.")
        
        if evs_given > 0
          stat_name = GameData::Stat.get(stat_symbol).name
          pbMessage("¡#{pkmn.name} ganó #{evs_given} EVs de #{stat_name}!")
          
          # Mostrar EVs actuales
          new_ev_total = pkmn.ev[stat_symbol]
          pbMessage("EVs totales de #{stat_name}: #{new_ev_total} EVs.")
        else
          if actual_evs_to_give == 0
            pbMessage("No se pudieron dar más EVs debido a los límites.")
          end
        end
        
        # Advertir si se alcanzó algún límite
        if evs_given < evs_to_give
          if max_ev_increase == 0
            stat_name = GameData::Stat.get(stat_symbol).name
            pbMessage("#{pkmn.name} ya tiene #{stat_name} al máximo.")
          elsif max_total_increase == 0
            pbMessage("#{pkmn.name} ya tiene el límite total de EVs (510).")
          end
        end
        
      else
        stat_name = GameData::Stat.get(stat_symbol).name
        pbMessage("¡#{pkmn.name} ya tiene los EVs de #{stat_name} al máximo!")
      end
    end
    
    return score
  end

  def self.promptChoosePokemon(param)
    pbChoosePokemon(1,3,proc{ |pkmn| 
      next (
        !pkmn.egg? &&
        (!param.blockMax || !hasMaxedValue?(pkmn, param)) && 
        (param.acceptFainted || pkmn.hp>0) &&
        (param.minLevel <= pkmn.level)
      )
    })
    return pbGet(1)==-1 ? nil : $player.party[pbGet(1)]
  end

  def self.hasMaxedValue?(pkmn, param)
    # Verificar límite total de EVs (510)
    current_total_evs = 0
    [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE].each do |s|
      current_total_evs += pkmn.ev[s]
    end
    
    # Si ya tiene el máximo total de EVs, no se puede entrenar más
    return true if current_total_evs >= Pokemon::EV_LIMIT
    
    # Verificar si la stat específica que queremos entrenar ya está al máximo
    for stat in param.statArray
      if param.evGain > 0  # Solo si vamos a dar EVs
        # Si esta stat específica ya está al máximo (252), no se puede entrenar
        return true if pkmn.ev[stat] >= Pokemon::EV_STAT_LIMIT
      end
      
      # Verificaciones para IVs (por compatibilidad con el código original)
      if param.ivGain > 0
        return true if pkmn.iv[stat] >= Pokemon::IV_STAT_LIMIT
      end
      
      if param.maximizeIV
        return true if pkmn.ivMaxed[stat]
      end
    end
    
    return false  # Se puede entrenar
  end

  def self.giveReward(pkmn, param)
    for stat in param.statArray
      stat_name = GameData::Stat.get(stat).name
      pbMessage(_INTL(
        "¡{1} ha aumentado el {2} de {3}!", stat_name, pkmn.name
      )) if raiseEV(pkmn, stat, param.evGain) > 0
      pbMessage(_INTL(
        "¡{1} ha aumentado el {2} de {3}!", stat_name, pkmn.name
      )) if raiseIV(pkmn, stat, param.ivGain) > 0
      pbMessage(_INTL(
        "¡{1} tiene el {2} al máximo!", pkmn.name, stat_name
      )) if param.maximizeIV && maximizeIV(pkmn, stat)
    end
  end

  def self.raiseEV(pkmn, stat, value)
    return pbJustRaiseEffortValues(pkmn, stat, value)
  end
  
  def self.raiseIV(pkmn, stat, value)
    valueToAdd = [
      Pokemon::IV_STAT_LIMIT - pkmn.iv[stat], value
    ].min
    pkmn.iv[stat] += valueToAdd
    return valueToAdd
  end
  
  def self.maximizeIV(pkmn, stat)
    return false if pkmn.ivMaxed[stat]
    pkmn.ivMaxed[stat] = true
    return true
  end
  
  def self.canIncreaseEV?(pkmn, stat)
    return false if pkmn.ev[stat] >= Pokemon::EV_STAT_LIMIT
    evTotal = 0
    [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE].each { |s| 
      evTotal += pkmn.ev[s] 
    }
    return evTotal < Pokemon::EV_LIMIT
  end
  
  def self.canIncreaseIV?(pkmn, stat)
    return pkmn.iv[stat] < Pokemon::IV_STAT_LIMIT
  end
  
  def self.hasMaxedIV?(pkmn, stat)
    return pkmn.ivMaxed[stat]
  end
end

#===============================================================================
# INSTRUCCIONES DE USO
#===============================================================================
#
# MÉTODO PRINCIPAL (con selector de estadística):
# PunchBag.play_proportional_ev_training
#
# MÉTODOS ESPECÍFICOS POR ESTADÍSTICA:
# PunchBag.play_proportional_ev(10, :HP)              # PS
# PunchBag.play_proportional_ev(10, :ATTACK)          # Ataque
# PunchBag.play_proportional_ev(10, :DEFENSE)         # Defensa
# PunchBag.play_proportional_ev(10, :SPEED)           # Velocidad
# PunchBag.play_proportional_ev(10, :SPECIAL_ATTACK)  # Ataque Especial
# PunchBag.play_proportional_ev(10, :SPECIAL_DEFENSE) # Defensa Especial
#
# SISTEMA DE PUNTUACIÓN:
# - 10 rondas mínimas (10 puntos) = 0% de 126 EVs = 0 EVs
# - 10 rondas perfectas (50 puntos) = 100% de 126 EVs = 126 EVs
# - Puntuación intermedia = Porcentaje proporcional de EVs
#
# EJEMPLO: 30 puntos en 10 rondas = 50% = 63 EVs
#
#===============================================================================
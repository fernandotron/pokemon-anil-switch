################################################################################
#                        Menú de Customización de Partida                      #
################################################################################

class CustomizationMenu
  
  def self.start
    menu = new
    menu.show_main_menu
  end
  
  def initialize
    # Inicializar cualquier variable necesaria
    @random_rules_shown = false
  end
  
  def show_main_menu
    loop do
      # Verificar qué opciones están elegidas
      opciones_elegidas = get_selected_options
      
      # Crear las opciones del menú con indicadores visuales
      opciones_menu = [
        _INTL("{1} Modo Nuzlocke", opciones_elegidas[:nuzlocke] ? "[X]" : "[  ]"),
        _INTL("{1} Modo Random", opciones_elegidas[:random] ? "[X]" : "[  ]"),
        _INTL("{1} Modo Monotype", opciones_elegidas[:monotype] ? "[X]" : "[  ]"),
        _INTL("{1} Modo VGC (dobles)", opciones_elegidas[:vgc] ? "[X]" : "[  ]"),
        _INTL("{1} Modo Inverso", opciones_elegidas[:inverso] ? "[X]" : "[  ]"),
        _INTL("{1} Modo Sin Grindeo", opciones_elegidas[:sin_grindeo] ? "[X]" : "[  ]"),
        _INTL("Confirmar los elegidos")
      ]
      
      choice = pbMessage(
        _INTL("Elige si quieres algún tipo de customización para tu partida. Puedes elegir más de uno de estos modos a la vez."),
        opciones_menu, -1
      )
      
      case choice
      when 0  # Modo Nuzlocke
        handle_nuzlocke_mode
      when 1  # Modo Random
        handle_random_mode
      when 2  # Modo Monotype
        handle_monotype_mode
      when 3  # Modo VGC
        handle_vgc_mode
      when 4  # Modo Inverso
        handle_inverse_mode
      when 5  # Modo Sin Grindeo
        handle_no_grinding_mode
      when 6  # Confirmar los elegidos
        if confirm_selection
          break
        end
      when -1 # Cancelar
        cmd = pbMessage(_INTL("¿Qué quieres hacer?"),
                        [_INTL("Salir sin hacer cambios"), _INTL("Salir sin elegir ningún modo"), _INTL("Cancelar")], -1)
        case cmd
        when 0  # Salir sin hacer cambios
          break
        when 1  # Salir sin elegir ningún modo
          clear_choices
          break
        when -1, 2  # Cancelar
          next
        end
      end
    end
  end
  
  private

  def clear_choices
    $game_switches[MODO_VGC] = false if $game_switches
    $game_switches[MODO_INVERSO] = false if $game_switches
    $game_switches[MODO_SIN_GRINDEO] = false if $game_switches
    ChallengeModes.reset if (ChallengeModes.queued? rescue false)
    RandomizedChallenge.disable if (RandomizedChallenge.enabled? rescue false)
    MonotypeChallenge.disable if (MonotypeChallenge.enabled? rescue false)
    pbMessage(_INTL("Se han desactivado todos los modos de juego personalizados."))
  end
  
  def get_selected_options
    {
      nuzlocke: (ChallengeModes.queued? || ChallengeModes.on? rescue false),
      random: (RandomizedChallenge.enabled? rescue false),
      monotype: (MonotypeChallenge.enabled? rescue false),
      vgc: (($game_switches && $game_switches[MODO_VGC]) rescue false),
      inverso: (($game_switches && $game_switches[MODO_INVERSO]) rescue false),
      sin_grindeo: (($game_switches && $game_switches[MODO_SIN_GRINDEO]) rescue false)
    }
  end
  
  def handle_nuzlocke_mode
    if !ChallengeModes.on? && !ChallengeModes.queued?
      choice = pbMessage(
        _INTL("¿Quieres abrir el menú de personalización del <b>MODO NUZLOCKE</b>? Esto incluye <b>numerosas reglas</b> para personalizar tu partida. Tendrás la posibilidad de editar muchas cosas, como cantidad de vidas, limitaciones de tus capturas y más. Si es tu primera partida a este juego, te recomendamos <b>NO ELEGIR</b> este modo, ya que está destinado a personas que quieran rejugar el juego."),
        [_INTL("Sí"), _INTL("No")], -1
      )
    else
      choice = pbMessage(_INTL("El Modo Nuzlocke ya está activado. ¿Qué quieres hacer?"), 
                        [_INTL("Ver las reglas"), _INTL("Configurar reglas"), _INTL("Desactivar Modo Nuzlocke"), _INTL("Salir sin cambios")])
    end
    
    if !ChallengeModes.on? && !ChallengeModes.queued?
      if choice == 0
        ChallengeModes.start
      end
    else
      if choice == 0
        ChallengeModes.display_rules
      elsif choice == 1
        ChallengeModes.open_rules_menu
      elsif choice == 2
        ChallengeModes.reset
        pbMessage(_INTL("El Modo Nuzlocke ha sido desactivado."))
      end
    end
  end
  
  def handle_random_mode
    if RandomizedChallenge.enabled?
      choice = pbMessage(_INTL("El Modo Random ya está activado. ¿Qué quieres hacer?"), 
                        [_INTL("Configurar reglas"), _INTL("Desactivar Modo Random")])
      @random_rules_shown = false
    else
      choice = pbMessage(
        _INTL("¿Quieres activar el <b>MODO RANDOM</b>? Esto randomizará los Pokémon salvajes, Pokémon de Entrenadores, movimientos, habilidades y objetos. No podrás desactivarlo en ningún momento de tu aventura. Si es tu 1ª partida en POKÉMON AÑIL, <b>te recomendamos seriamente que no actives el MODO RANDOM para no estropearte la experiencia de juego</b>. ¿Quieres activar aún así el <b>MODO RANDOM</b>?"),
        [_INTL("Sí"), _INTL("No")], -1
      )
    end
  
    if choice == 0 && !RandomizedChallenge.enabled?
      show_random_type_selection
    elsif choice == 0 && RandomizedChallenge.enabled?
      show_random_options_menu
    elsif choice == 1 && RandomizedChallenge.enabled?
      RandomizedChallenge.disable
      pbMessage(_INTL("El Modo Random ha sido desactivado."))
    end
  end
  
  def show_random_type_selection
    tipo_random = pbMessage(
      _INTL("Elige qué modo de randomizado quieres. Estos modos vienen con algunas opciones predefinidas, pero tras elegir uno de ellos luego podrás entrar al menú de reglas para definir las que te interesen."),
      [_INTL("Random Completo"), _INTL("Semi Random"), _INTL("Cancelar")], -1
    )
    
    case tipo_random
    when 0  # Random Completo
      setup_random_mode(:completo)
      show_random_options_menu
    when 1  # Semi Random
      setup_random_mode(:semi)
      show_random_options_menu
    when 2  # Cancelar
      # Volver al menú principal
    end
  end
  
  def setup_random_mode(type)
    if $game_switches && $game_switches[109]
      RandomizerConfigurator.gens = [1,2]
    end
    RandomizedChallenge.enable
    
    if type == :semi
      RandomizerConfigurator.toggle_semi_random_mode
    end
  end
  

  def show_random_intro
    # pbMessage(_INTL("Este modo de juego tiene las reglas predefinidas:"))
    # RandomizerConfigurator.display_current_rules
  end

  def show_random_options_menu(with_intro = true)
    if RandomizedChallenge.enabled?
      show_random_intro if with_intro
      
      opcion = pbMessage(
        _INTL("¿Qué te gustaría hacer?"),
        [_INTL("Ver las reglas"), _INTL("Jugar con estas reglas"), _INTL("Configurar mis reglas"), _INTL("Salir sin modo random")], -1
      )
      case opcion
      when 0  # Ver las reglas
        RandomizerConfigurator.display_current_rules
        @random_rules_shown = true
        show_random_options_menu(false)
      when 1  # Jugar con estas reglas
        if !@random_rules_shown
          show_rules = pbConfirmMessage(_INTL("Estás aceptando las reglas predefinidas para el Modo Random. ¿Deseas verlas primero?"))
          if show_rules
            RandomizerConfigurator.display_current_rules
            @random_rules_shown = true
          end
        end
        pbMessage(_INTL("Se han elegido las reglas predefinidas para el Modo Random."))
      when 2  # Configurar mis reglas
        ret = RandomizerConfigurator.open_configurator
        if ret
          pbMessage(_INTL("Se han elegido estas reglas para el Modo Random."))
        else
          pbMessage(_INTL("El Modo Random ha sido desactivado."))
        end
      when 3  # Salir sin modo random
        RandomizedChallenge.disable
        pbMessage(_INTL("Has cancelado el Modo Random."))
      end
    end
  end
  
  def handle_monotype_mode
    MonotypeMenu.display
  end
  
  def handle_vgc_mode
    choice = pbMessage(
      _INTL("¿Quieres activar el <b>MODO VGC</b>? Esto hará que <b>TODOS LOS COMBATES</b> sean en formato <b>DOBLE</b>."),
      [_INTL("Sí"), _INTL("No")], -1
    )
    
    $game_switches[MODO_VGC] = (choice == 0)
  end
  
  def handle_inverse_mode
    choice = pbMessage(
      _INTL("¿Quieres activar el <b>MODO INVERSO</b>? Esto hará que <b>TODAS LAS EFICACIAS SE INVIERTAN</b>. Por ejemplo, si normalmente un movimiento de  tipo Agua es eficaz contra un Pokémon de Fuego, en este modo el movimiento de tipo Fuego será eficaz contra el Pokémon de Agua y el movimiento de Agua será poco eficaz contra el Pokémon de Fuego. En el caso de las inmunidades, los ataques pasarán a ser Muy Eficaz."),
      [_INTL("Sí"), _INTL("No")], -1
    )
    
    $game_switches[MODO_INVERSO] = (choice == 0)
  end
  
  def handle_no_grinding_mode
    choice = pbMessage(
      _INTL("¿Quieres activar el <b>MODO SIN GRINDEO</b>? Esto hará que los IVs y EVs de los Pokémon no sean considerados en combate, todos los calculos de estadístícas y daño serán como si el Pokémon tuviera 0 EVs y 0 IVs. (Los IVs y EVs seguirán existiendo para otras razones como el tipo del poder oculto, pero no tendrán injerencia en los combates.)"),
      [_INTL("Sí"), _INTL("No")], -1
    )
    
    $game_switches[MODO_SIN_GRINDEO] = (choice == 0)
  end
  
  def confirm_selection
    # Recopilar los modos elegidos
    modos_elegidos = []
    opciones = get_selected_options
    
    modos_elegidos.push(_INTL("Modo Nuzlocke")) if opciones[:nuzlocke]
    modos_elegidos.push(_INTL("Modo Random")) if opciones[:random]
    modos_elegidos.push(_INTL("Modo Monotype")) if opciones[:monotype]
    modos_elegidos.push(_INTL("Modo VGC")) if opciones[:vgc]
    modos_elegidos.push(_INTL("Modo Inverso")) if opciones[:inverso]
    modos_elegidos.push(_INTL("Modo Sin Grindeo")) if opciones[:sin_grindeo]
    
    # Crear el mensaje con los modos elegidos
    if modos_elegidos.empty?
      mensaje = _INTL("No has elegido ningún modo.")
    else
      lista_modos = modos_elegidos.join(", ")
      mensaje = _INTL("Has elegido los modos: {1}.", lista_modos)
    end
    
    choice = pbMessage(
      mensaje + "\n" + _INTL("¿Te parece bien esta elección?"),
      [_INTL("Sí"), _INTL("No")], -1
    )
    
    return choice == 0
  end
end

# Función de conveniencia para llamar desde fuera
def pbMostrarMenuCustomizacion
  CustomizationMenu.start
end
#-------------------------------------------------------------------------------
# These are used to define what the Follower will say when spoken to under
# specific conditions like Status or Weather or Map names
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Amie Compatibility
#-------------------------------------------------------------------------------
if defined?(PkmnAR)
  EventHandlers.add(:following_pkmn_talk, :amie, proc { |_pkmn, _random_val|
    cmd = pbMessage(_INTL("¿Qué te gustaría hacer?"), [
      _INTL("Jugar"),
      _INTL("Hablar"),
      _INTL("Cancelar")
    ])
    PkmnAR.show if cmd == 0
    next true if [0, 2].include?(cmd)
  })
end
#-------------------------------------------------------------------------------
# Special Dialogue when statused
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :status, proc { |pkmn, _random_val|
  case pkmn.status
  when :POISON
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_POISON)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} está tiritando a causa del veneno.", pkmn.name))
  when :BURN
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("Parece que a {1} le duele mucho su quemadura.", pkmn.name))
  when :FROZEN
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("Da la impresión de que {1} está pasando mucho frío.", pkmn.name))
  when :SLEEP
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} parece agotado.", pkmn.name))
  when :PARALYSIS
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} está temblando y tiene sacudidas.", pkmn.name))
  end
  next true if pkmn.status != :NONE
})
#-------------------------------------------------------------------------------
# Specific message if the map has the Pokemon Lab metadata flag
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :pokemon_lab, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("PokemonLab")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} está tocando algún tipo de interruptor."),
      _INTL("¡{1} tiene un cable en la boca!"),
      _INTL("{1} parece que quiere tocar la maquinaria.")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map name has the players name in it like the
# Player's House
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :player_house, proc { |pkmn, _random_val|
  if $game_map.name.include?($player.name)
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} está olfateando la habitaciónis sniffing around the room."),
      _INTL("{1} a notado que la mama de {2} está cerca."),
      _INTL("{1} parece querer quedarse en casa.")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has Pokecenter metadata flag
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :pokemon_center, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("PokeCenter")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} parece feliz de ver a la enfermera."),
      _INTL("{1} se ve un poco mejor simplemente estando en el Centro Pokémon.."),
      _INTL("{1} parece fascinado por la maquina de curación."),
      _INTL("{1} parece que quiere echarse una siesta."),
      _INTL("{1} saludó a la enfermera."),
      _INTL("{1} está mirando a {2} juguetonamente."),
      _INTL("{1} parece completamente tranquilo."),
      _INTL("{1} se está poniendo cómodo."),
      _INTL("Hay una expresión feliz en el rostro de {1}.")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has the Gym metadata flag
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :gym, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("GymMap")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("¡{1} parece ansioso por luchar!"),
      _INTL("{1} está mirando a {2} con un brillo decidido en sus ojos."),
      _INTL("{1} está tratando de intimidar a los otros Entrenadores."),
      _INTL("{1} confía en {2} para idear una estrategia ganadora."),
      _INTL("{1} está vigilando al líder del gimnasio."),
      _INTL("{1} está listo para pelear con alguien."),
      _INTL("¡Parece que {1} podría estar preparándose para un gran enfrentamiento!"),
      _INTL("¡{1} quiere mostrar lo fuerte que es!"),
      _INTL("¿{1} está...haciendo ejercicios de calentamiento?"),
      _INTL("{1} está gruñendo silenciosamente en la contemplación...")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Storm. Pokemon of different types
# have different reactions to the weather.
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :storm_weather, proc { |pkmn, _random_val|
  if :Storm == $game_screen.weather_type
    if pkmn.hasType?(:ELECTRIC)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está mirando al cielo."),
        _INTL("La tormenta parece estar entusiasmando a {1}."),
        _INTL("¡{1} miró al cielo y gritó fuerte!"),
        _INTL("¡La tormenta sólo parece dar energía a {1}!"),
        _INTL("¡{1} está felizmente correteando y saltando en círculos!"),
        _INTL("Los rayos no molesta en absoluto a {1}.")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está mirando al cielo."),
        _INTL("La tormenta parece estar poniendo {1} un poco nervioso."),
        _INTL("¡El rayo sobresaltó a {1}!"),
        _INTL("La lluvia no parece molestar mucho a {1}."),
        _INTL("El clima parece estar poniendo nervioso a {1}."),
        _INTL("¡{1} se sobresaltó por el rayo y se acurrucó junto a {2}!")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Snowy. Pokemon of different types
# have different reactions to the weather.
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :snow_weather, proc { |pkmn, _random_val|
  if :Snow == $game_screen.weather_type
    if pkmn.hasType?(:ICE)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está viendo caer la nieve."),
        _INTL("¡{1} está encantado con la nieve!"),
        _INTL("{1} está mirando al cielo con una sonrisa."),
        _INTL("La nieve parece haber puesto de buen humor a {1}."),
        _INTL("¡{1} está alegre por el frío!")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está viendo caer la nieve."),
        _INTL("{1} está mordisqueando los copos de nieve que caen."),
        _INTL("{1} quiere atrapar un copo de nieve con la boca."),
        _INTL("{1} está fascinado por la nieve."),
        _INTL("¡Los dientes de {1} castañetean!"),
        _INTL("{1} se encogió debido al frío...")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Blizzard. Pokemon of different types
# have different reactions to the weather.
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :blizzard_weather, proc { |pkmn, _random_val|
  if :Blizzard == $game_screen.weather_type
    if pkmn.hasType?(:ICE)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está viendo caer el granizo."),
        _INTL("A {1} no le molesta en absoluto el granizo."),
        _INTL("{1} está mirando al cielo con una sonrisa."),
        _INTL("El granizo parece haber puesto de buen humor a {1}."),
        _INTL("{1} está royendo un trozo de granizo.")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("¡{1} está siendo golpeado por el granizo!"),
        _INTL("{1} quiere evitar el granizo."),
        _INTL("El granizo está golpeando dolorosamente a {1}."),
        _INTL("{1} parece infeliz."),
        _INTL("¡{1} tiembla como una hoja!")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Sandstorm. Pokemon of different types
# have different reactions to the weather.
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :sandstorm_weather, proc { |pkmn, _random_val|
  if :Sandstorm == $game_screen.weather_type
    if [:ROCK, :GROUND].any? { |type| pkmn.hasType?(type) }
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está cubierto de arena."),
        _INTL("¡El clima no parece molestar a {1} en absoluto!"),
        _INTL("¡La arena no puede frenar a {1}!"),
        _INTL("{1} está disfrutando del clima.")
      ]
    elsif pkmn.hasType?(:STEEL)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está cubierto de arena, pero no parece importarle."),
        _INTL("{1} parece no preocuparse por la tormenta de arena."),
        _INTL("La arena no frena a {1}."),
        _INTL("A {1} no parece importarle el clima.")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está cubierto de arena..."),
        _INTL("¡{1} escupió un bocado de arena!"),
        _INTL("{1} entrecierra los ojos a través de la tormenta de arena."),
        _INTL("La arena parece estar molestando a {1}.")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has the Forest metadata flag
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :forest_map, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("Forest")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_MUSIC)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    if [:BUG, :GRASS].any? { |type| pkmn.hasType?(type) }
      messages = [
        _INTL("{1} parece muy interesado en los árboles."),
        _INTL("{1} parece disfrutar el zumbido del Pokémon insecto."),
        _INTL("{1} salta inquieto en el bosque.")
      ]
    else
      messages = [
        _INTL("{1} parece muy interesado en los árboles."),
        _INTL("{1} parece disfrutar el zumbido del Pokémon insecto."),
        _INTL("{1} salta inquieto en el bosque."),
        _INTL("{1} está deambulando y escuchando los diferentes sonidos."),
        _INTL("{1} está masticando la hierba."),
        _INTL("{1} está deambulando y disfrutando del paisaje del bosque."),
        _INTL("{1} está jugando, arrancando trozos de hierba."),
        _INTL("{1} está mirando la luz que entra entre los árboles."),
        _INTL("¡{1} está jugando con una hoja!"),
        _INTL("{1} parece estar escuchando el sonido de las hojas susurrando.."),
        _INTL("{1} está perfectamente quieto y podría estar imitando un árbol..."),
        _INTL("¡{1} se enredó en las ramas y casi se cae.!"),
        _INTL("¡{1} se sorprendió cuando fue golpeado por una rama!")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Rainy. Pokemon of different types
# have different reactions to the weather.
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :rainy_weather, proc { |pkmn, _random_val|
  if [:Rain, :HeavyRain].include?($game_screen.weather_type)
    if pkmn.hasType?(:FIRE) || pkmn.hasType?(:GROUND) || pkmn.hasType?(:ROCK)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} parece muy molesto por el clima."),
        _INTL("{1} esta temblando..."),
        _INTL("A {1} no parece gustarle estar todo mojado ..."),
        _INTL("{1} se intenta secar agitándose..."),
        _INTL("{1} se acercó a {2} en busca de consuelo."),
        _INTL("{1} mira al cielo y frunce el ceño."),
        _INTL("{1} parece tener dificultades para mover su cuerpo.")
      ]
    elsif pkmn.hasType?(:WATER) || pkmn.hasType?(:GRASS)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} parece estar disfrutando del clima."),
        _INTL("¡{1} parece estar feliz por la lluvia!"),
        _INTL("¡{1} parece estar muy sorprendido de que esté lloviendo!"),
        _INTL("¡{1} sonrió felizmente a {2}!"),
        _INTL("{1} está mirando las nubes de lluvia."),
        _INTL("Las gotas de lluvia siguen cayendo sobre {1}."),
        _INTL("{1} mira hacia arriba con la boca abierta.")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está mirando al cielo."),
        _INTL("{1} parece un poco sorprendido de ver la lluvia."),
        _INTL("{1} se intenta secar agitándose."),
        _INTL("La lluvia no parece molestar mucho a {1}."),
        _INTL("¡{1} está jugando en un charco!"),
        _INTL("¡{1} se resbala en el agua y casi se cae!")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has Beach metadata flag
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :beach_map, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("Beach")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} parece estar disfrutando del paisaje."),
      _INTL("{1} parece disfrutar del sonido de las olas moviendo la arena."),
      _INTL("¡Parece que {1} quiere nadar!"),
      _INTL("{1} apenas puede apartar la vista del océano."),
      _INTL("{1} mira con deseo el agua."),
      _INTL("{1} sigue intentando empujar a {2} hacia el agua."),
      _INTL("¡{1} está emocionado de poder contemplar el mar!"),
      _INTL("¡{1} está feliz mirando las olas!"),
      _INTL("¡{1} está jugando en la arena!"),
      _INTL("{1} está mirando las huellas de {2} en la arena."),
      _INTL("{1} está rodando en la arena.")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Sunny. Pokemon of different types
# have different reactions to the weather.
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :sunny_weather, proc { |pkmn, _random_val|
  if :Sun == $game_screen.weather_type
    if pkmn.hasType?(:GRASS)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} parece encantado de estar bajo el sol."),
        _INTL("{1} está tomando el sol."),
        _INTL("La brillante luz del sol no parece molestar a {1} en absoluto."),
        _INTL("¡{1} envió una nube de esporas en forma de anillo al aire!"),
        _INTL("{1} se ha estirado y se está relajando bajo el sol."),
        _INTL("{1} desprende un aroma floral.")
      ]
    elsif pkmn.hasType?(:FIRE)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("¡{1} parece estar feliz por el buen tiempo!"),
        _INTL("La brillante luz del sol no parece molestar a {1} en absoluto."),
        _INTL("¡{1} se ve encantado por el sol!"),
        _INTL("{1} echó una bola de fuego."),
        _INTL("¡{1} está exhalando fuego!"),
        _INTL("¡{1} está caliente y féliz!")
      ]
    elsif pkmn.hasType?(:DARK)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} está fulminando con la mirada al cielo."),
        _INTL("{1} parece ofendido personalmente por el sol."),
        _INTL("La brillante luz del sol parece molestar a {1}."),
        _INTL("{1} parece molesto por alguna razón."),
        _INTL("{1} está intentando mantenerse en la sombra de {2}."),
        _INTL("{1} sigue buscando refugio de la luz del sol.")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} entrecierra los ojos bajo el sol brillante."),
        _INTL("{1} está empezando a sudar."),
        _INTL("{1} parece un poco incómodo en este clima."),
        _INTL("{1} parece un poco asfixiado por el calor."),
        _INTL("{1} parece muy acalorado..."),
        _INTL("¡{1} está protegiendo sus ojos de la luz brillante!")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
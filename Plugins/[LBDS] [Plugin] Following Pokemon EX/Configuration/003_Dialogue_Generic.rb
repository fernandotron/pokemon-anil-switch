#-------------------------------------------------------------------------------
# These are used to define what the Follower will say when spoken to in general
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# All dialogues with the Music Note animation
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :music_generic, proc { |pkmn, random_val|
  if random_val == 0
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_MUSIC)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} parece querer jugar con {2}."),
      _INTL("{1} está cantando y tarareando."),
      _INTL("{1} está mirando a {2} con una expresión de felicidad."),
      _INTL("{1} se balanceaba y bailaba a su antojo."),
      _INTL("¡{1} está saltando sin preocupaciones!"),
      _INTL("¡{1} presume de su su agilidad!"),
      _INTL("¡{1} se mueve felizmente!"),
      _INTL("¡Eh! ¡{1} se ha puesto a bailar de alegría!"),
      _INTL("¡{1} sigue constantemente el ritmo de {2}!"),
      _INTL("{1} es feliz saltando."),
      _INTL("{1} está mordisqueando el suelo alegremente."),
      _INTL("¡{1} está mordisqueando juguetonamente los pies de {2}!"),
      _INTL("¡{1} sigue a {2} muy de cerca!"),
      _INTL("{1} se da vuelta y mira a {2}."),
      _INTL("¡{1} está trabajando duro para mostrar su gran poder!"),
      _INTL("¡Parece que {1} quiere correr!"),
      _INTL("{1} está deambulando disfrutando del paisaje."),
      _INTL("¡{1} parece estar disfrutando un poco!"),
      _INTL("¡{1} está saludando!"),
      _INTL("¿{1} parece estar cantando algo?"),
      _INTL("¡{1} se ha puesto a bailar de alegría!"),
      _INTL("¡{1} se divierte bailando!"),
      _INTL("¡{1} está tan feliz que empezó a cantar!"),
      _INTL("{1} ha pegado un grito mientras miraba al cielo."),
      _INTL("{1} parece sentirse optimista."),
      _INTL("¡Parece que {1} tiene ganas de bailar!"),
      _INTL("¡{1} de repente empezó a cantar! Parece que se siente genial."),
      _INTL("¡Parece que {1} quiere bailar con {2}!")
    ]
    value = rand(messages.length)
    case value
    # Special move route to go along with some of the dialogue
    when 3, 9
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 80])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 4, 5
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 40])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 6, 17
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 40])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP
      ])
    when 7, 28
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 60])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 21, 22
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 50])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Angry animation
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :angry_generic, proc { |pkmn, random_val|
  if random_val == 1
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("¡{1} dejó escapar un rugido!"),
      _INTL("¡{1} está poniendo cara de enfado!"),
      _INTL("{1} parece estar molesto por alguna razón."),
      _INTL("{1} mordió los pies de {2}."),
      _INTL("{1} se giró hacia el otro lado, mostrando una expresión desafiante."),
      _INTL("¡{1} está tratando de intimidar a los enemigos de {2}!"),
      _INTL("¡{1} está buscando pelea!"),
      _INTL("¡{1} está listo para luchar!"),
      _INTL("¡Parece que {1} pelearía contra cualquiera ahora mismo!"),
      _INTL("{1} está gruñendo de una manera que parece que te esté hablando...")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 6, 7, 8
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 25])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Neutral Animation
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :ellipses_generic, proc { |pkmn, random_val|
  if random_val == 2
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} mira hacia abajo fijamente."),
      _INTL("{1} está olfateando el aire."),
      _INTL("{1} se está concentrando muy fuerte."),
      _INTL("{1} miró a {2} y asintió."),
      _INTL("{1} está mirando directamente a los ojos de {2}."),
      _INTL("{1} está inspeccionando el área."),
      _INTL("¡{1} se concentra con una mirada aguda!"),
      _INTL("{1} mira a su alrededor distraídamente."),
      _INTL("¡{1} bostezó muy fuerte!"),
      _INTL("{1} se está relajando cómodamente."),
      _INTL("{1} está centrando su atención en {2}."),
      _INTL("{1} está mirando fijamente a la nada."),
      _INTL("{1} se está concentrando."),
      _INTL("{1} miró a {2} y asintió."),
      _INTL("{1} está mirando las huellas de {2}."),
      _INTL("{1} parece querer jugar y está mirando a {2} expectante."),
      _INTL("{1} parece estar pensando profundamente en algo."),
      _INTL("{1} no está prestando atención a {2}... Parece que está pensando en otra cosa."),
      _INTL("{1} tiene la cara un poco seria."),
      _INTL("{1} parece no tener mucho interés."),
      _INTL("La mente de {1} parece estar en otra parte."),
      _INTL("{1} parece estar observando los alrededores en lugar de mirar a {2}."),
      _INTL("{1} parece que se aburre un poco."),
      _INTL("{1} tiene una mirada intensa en su rostro."),
      _INTL("{1} está mirando a lo lejos."),
      _INTL("{1} parece estar examinando cuidadosamente la cara de {2}."),
      _INTL("{1} parece estar intentando comunicarse con la mirada."),
      _INTL("... ¡Parece que {1} ha estornudado!"),
      _INTL("... {1} notó que los zapatos de {2} están un poco sucios."),
      _INTL("Parece que {1} comió algo extraño, está poniendo una cara rara..."),
      _INTL("{1} parece estar oliendo algo bueno."),
      _INTL("{1} notó que la bolsa de {2} tiene un poco de suciedad..."),
      _INTL("... ... ... ... ... ... ... ... ... ... ... ¡{1} asintió en silencio!")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 1, 5, 7, 20, 21
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 35])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_DOWN
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Happy animation
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :happy_generic, proc { |pkmn, random_val|
  if random_val == 3
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} comenzó a dar toquecitos a {2}."),
      _INTL("{1} está muy emocionado."),
      _INTL("{1} abraza felizmente a {2}."),
      _INTL("{1} está tan feliz que no puede quedarse quieto."),
      _INTL("¡Parece que {1} quiere ir por delante!"),
      _INTL("{1} avanza felizmente."),
      _INTL("¡{1} parece sentirse muy bien caminando con {2}!"),
      _INTL("{1} parece muy saludable."),
      _INTL("{1} se ve muy feliz."),
      _INTL("¡{1} hace un esfuerzo adicional solo por {2}!"),
      _INTL("{1} está oliendo los aromas de los alrededores."),
      _INTL("¡{1} salta de alegría!"),
      _INTL("¡{1} se siente genial!"),
      _INTL("{1} estira su cuerpo y se relaja."),
      _INTL("{1} está haciendo todo lo posible para mantenerse al día con {2}."),
      _INTL("¡{1} está abrazando felizmente a {2}!"),
      _INTL("¡{1} está lleno de energía!"),
      _INTL("¡{1} está tan feliz que no puede quedarse quieto!"),
      _INTL("{1} deambula y escucha los diferentes sonidos."),
      _INTL("{1} le da a {2} una mirada feliz y una sonrisa."),
      _INTL("¡{1} comenzó a respirar agitadamente por la nariz de emoción!"),
      _INTL("¡{1} tiembla incontroladamente!"),
      _INTL("{1} está tan feliz que empezó a rodar."),
      _INTL("{1} parece encantado de llamar la atención de {2}."),
      _INTL("¡{1} parece muy feliz de que {2} se dé cuenta!"),
      _INTL("¡{1} comenzó a mover todo su cuerpo de emoción!"),
      _INTL("¡Parece que {1} no puede evitar abrazar a {2}!"),
      _INTL("{1} se mantiene cerca de los pies de {2}.")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 3
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 45])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 11, 16, 17, 24
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 40])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Heart animation
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :heart_generic, proc { |pkmn, random_val|
  if random_val == 4
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HEART)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} ha comenzado a caminar más cerca de {2}."),
      _INTL("¡Aaah! {1} de repente abrazó a {2}."),
      _INTL("{1} se está frotando contra {2}."),
      _INTL("{1} se mantiene cerca de {2}."),
      _INTL("{1} se sonrojó."),
      _INTL("¡A {1} le encanta pasar tiempo con {2}!"),
      _INTL("¡{1} se ha puesto juguetón de repente!"),
      _INTL("¡{1} se está frotando contra las piernas de {2}!"),
      _INTL("¡{1} mira a {2} con cariño!"),
      _INTL("{1} parece querer algo de afecto de {2}."),
      _INTL("{1} parece querer algo de atención de {2}."),
      _INTL("{1} parece estar muy feliz de viajar con {2}."),
      _INTL("{1} parece sentir afecto por {2}."),
      _INTL("{1} está mirando a {2} con ojos amorosos."),
      _INTL("Parece que {1} quiere un regalo de {2}."),
      _INTL("¡Parece que {1} quiere que {2} lo acaricie!"),
      _INTL("{1} se está frotando contra {2} cariñosamente."),
      _INTL("{1} frota suavemente su cabeza contra la mano de {2}."),
      _INTL("{1} se ha dado la vuelta mirando a {2} expectante."),
      _INTL("{1} está mirando a {2} con confianza."),
      _INTL("¡{1} parece estar rogando a {2} algo de afecto!"),
      _INTL("¡{1} imitó a {2}!")
    ]
    value = rand(messages.length)
    case value
    when 1, 6,
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 10])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with no animation
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :generic,  proc { |pkmn, random_val|
  if random_val == 5
    messages = [
      _INTL("¡{1} da vueltas en círculos!"),
      _INTL("{1} dejó escapar un grito de guerra."),
      _INTL("¡{1} está alerta!"),
      _INTL("{1} está de pie pacientemente."),
      _INTL("{1} está mirando con inquietud a su alrededor."),
      _INTL("{1} está deambulando."),
      _INTL("¡{1} bostezó ruidosamente!"),
      _INTL("{1} está hurgando en el suelo alrededor de los pies de {2}."),
      _INTL("{1} está mirando a {2} mientras sonríe."),
      _INTL("{1} mira fijamente a lo lejos."),
      _INTL("{1} está siguiendo el ritmo de {2}."),
      _INTL("{1} parece rebosar de satisfacción."),
      _INTL("¡{1} está exultante!"),
      _INTL("{1} se ha sincronizado con {2}."),
      _INTL("{1} comenzó a girar en círculos."),
      _INTL("{1} mira a {2} con admiración."),
      _INTL("{1} parece que se ha avergonzado."),
      _INTL("{1} está esperando ver qué hará {2}."),
      _INTL("{1} está mirando tranquilamente a {2}."),
      _INTL("{1} está buscando en {2} algún tipo de señal."),
      _INTL("{1} está expectante a que {2} haga un movimiento."),
      _INTL("{1} se sentó a los pies de {2} obedientemente."),
      _INTL("¡{1} se sorprendió!"),
      _INTL("¡{1} da brincos!")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 0
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 15])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN
      ])
    when 2, 4
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 35])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_DOWN
      ])
    when 14
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 50])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN
      ])
    when 22, 23
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 10])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------

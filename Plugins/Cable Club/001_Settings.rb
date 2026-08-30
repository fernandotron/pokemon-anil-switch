module CableClub
  HOST = "188.245.253.191"
  PORT = 25565
  FOLDER_FOR_BATTLE_PRESETS = "OnlinePresets"
  GROUP_ID_LENGTH = 8
  
  ONLINE_TRAINER_TYPE_LIST = [
    [:POKEMONTRAINER_Red,:POKEMONTRAINER_Leaf],
    [:PSYCHIC_M,:PSYCHIC_F],
    [:BLACKBELT,:CRUSHGIRL],
    [:COOLTRAINER_M,:COOLTRAINER_F]
  ]
  
  ONLINE_WIN_SPEECHES_LIST = [
    _INTL("¡Gané!"),
    _INTL("Es todo gracias a mi equipo."),
    _INTL("¡Conseguimos hacernos con la victoria!"),
    _INTL("¡Qué batalla, fue divertida!")
  ]
  ONLINE_LOSE_SPEECHES_LIST = [
    _INTL("¡Perdí...!"),
    _INTL("¡Estaba seguro de mi equipo también!"),
    _INTL("¡Eso era la única cosa que quería evitar!"),
    _INTL("¡Qué batalla, fue divertida!")
  ]
  
  ENABLE_RECORD_MIXER = false
  
  # If true, Sketch fails when used.
  # If false, Sketch is undone after battle
  DISABLE_SKETCH_ONLINE = true
end
#===============================================================================
#  The Trade Expert
#    by Luka S.J.
#
#  Provides an emulated experience of Wonder Trade, but uses the base stat total
#  of a Pokemon species to determine which Pokemon you'll obtain from the trade.
#  Includes dialogues to make the event more interesting when trading your Pokemon.
#  To use, simply call it in an event via the script command:
#      tradeExpert(margin)
#  where margin is a percentage value (from 0.0 to 1.0) that determines the
#  increase in upper and lower base stat total values for the traded Pokemon.
#  By default, it is set to 0.1; meaning that the Pokemon you recieve will be
#  in the base stat total range of within 90% - 110% of the base stat total of
#  the Pokemon you're giving up for trade. The 'margin' parameter can be
#  omitted.
#  Look at the 'def tradePokemon' if you want to customize the Pokemon you're
#  getting from the trade even further.
#
#  Enjoy the script, and make sure to give credit!
#===============================================================================
#  Trade Expert (settings)
#===============================================================================
module TradeExpert

  # A list of Pokemon you cannot obtain from the Trade Expert
  TRADING_BLACKLIST = [
    :MEWTWO,
    :MEW,
    :CELEBI,
    :JIRACHI,
    :DEOXYS,
    :ARCEUS,
    :GENESECT
  ]

  # A list of Pokemon you cannot give to the Trade Expert
  GIVING_BLACKLIST = [
    :ARCEUS
  ]

  # hash containing the spoken text
  # add multiple entries as array to speak in sequence, or assign single message
  # to each defined key
  TEXT = {
    # text when starting the event
    "intro" => [
      "¡Hola! ¡Soy el Don Prodigio!",
      "Me especializo en encontrar Pokémon raros e intercambiarlos con entrenadores por otros Pokémon del mismo valor."
    ],
    # confirmation message from the expert
    "asktrade" => "¿Hay algún Pokémon que te gustaría que le evalue? Puedo ofrecerte un Pokémon de valor similar.",
    # rejection message if no mon for trade
    "invalid" => "Parece que no tienes un Pokémon para darme.",
    # rejection if no offer found
    "notrade" => "¡Ese {1} es un Pokémon sobrecogedor! No tengo nada que pueda ofrecerte. Lo siento!",
    # thinking intermission
    "thinking" => "Hmm... Hmm...",
    # trade options
    "trade0" => "¡Ese {1} es un Pokémon muy débil!",
    "trade1" => "¡Ese {1} no es un Pokémon intimidante!",
    "trade2" => "¡Ese {1} no es un mal Pokémon!",
    "trade3" => "¡Ese {1} un Pokémon ciertamente interesante!",
    "trade4" => "¡Ese {1} es lo que yo llamo un Pokémon fiero!",
    "trade5" => "Ese {1}... ¡Es un Pokémon realmente fascinante!",
    # trade proposal
    "propose" => "En base a esto... ¿Te gustaría intercambiar tu {2} por mi {1}?",
    # trade acceptance (player action)
    "accepttrade" => "¡Ha sido un placer hacer negocios contigo! ¡Déjame saber si quieres hacer más intercambios!",
    # trade rejection (player action)
    "rejecttrade" => [
      "A mi me parecía un intercambio justo.",
      "Bueno... si algún día cambias de opinión, déjame saber."
    ],
    # trade cancelled (player action)
    "canceltrade" => "Bueno... si algún día cambias de opinión, déjame saber."
  }

  SHINY_CHANCE_MAX_GIVING_SHINY = 20
  SHINY_CHANCE_MAX = 300

end

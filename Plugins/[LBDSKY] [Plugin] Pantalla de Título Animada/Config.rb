#===============================================================================
#  Modular Title Screen para Pokemon Essentials
#    por Luka S.J.
#
#  Adatado para LA BASE DE SKY
# ----------------
#  Constantes de configuración para el script. Todas las constantes diversas están
#  comentadas para etiquetar lo que hace cada una. Asegúrate de leer qué hacen
#  y cómo usarlas. La mayor parte de este script está en texto verde.
#
#  Se invirtió mucho tiempo y esfuerzo en hacer de esto un recurso extenso y completo.
#  Así que por favor, sé amable y da crédito al usarlo.
#
#  Consulta la página de documentación oficial para aprender cómo configurar
#  tus pantallas de título animadas: https://luka-sj.com/res/modts/docs
#===============================================================================
module ModularTitle
  # Constante de configuración utilizada para dar estilo a la pantalla de título
  # Agrega múltiples modificadores para añadir efectos visuales a la pantalla de título
  # Los modificadores no aditivos no se acumulan, es decir, solo puedes usar uno de cada tipo
  MODIFIERS = [
  #-------------------------------------------------------------------------------
  #                                PREESTABLECIDOS
  #-------------------------------------------------------------------------------
    # Pesadilla Eléctrica
    #"background1", "logo:bounce", "effect9", "logo:shine", "intro:4"

    # Aventura del Entrenador
    #"background6", "misc1", "overlay5", "effect8", "logo:glow", "bgm:title_hgss", "intro:2"

    # Entrada de Ultraumbral
    #"background2", "effect1", "effect5", "overlay:static003", "logo:glow", "intro:7"

    # Arcoíris Feo
    #"background5", "logo:sparkle", "overlay:static004", "effect1", "intro:5"

    # Brisa Oceánica
    #"background11", "intro:1", "logoY:172", "logo:sparkle", "logo:shine", "overlay:blue_z25", "misc5:blastoise_x294_y118", "effect5_y106", "effect4_y106", "bgm:title_frlg"

    # Evolución
    #"background8", "effect7_y272", "effect6_y272", "effect4_y272", "effect5_y272", "logoY:172", "misc4_y312", "overlay5", "bgm:title_rse", "intro:3"

    # Rojo Ardiente (gen 1)
    #"background:frlg", "intro:1", "effect10_y308", "overlay:frlg", "logoX:204", "logoY:164", "logo:sparkle", "misc5:charizard_x284_y142", "bgm:title_frlg"

    # Corazón de Oro (gen 2)
    #"background:dawn", "intro:2", "logoY:172", "logo:glow", "misc2", "effect11_x368_y112", "effect6_x368_y112", "effect4_x368_y112", "overlay3", "bgm:title_hgss"

    # Abismo Zafiro (gen 3)
    #"background:rse", "intro:3", "misc3_x260_y236", "overlay4", "logoY:172", "logo:sparkle", "logo:shine", "effect3_y236", "bgm:title_rse"

    # Sombra Platino (gen 4)
    #"background10", "intro:4", "overlay7", "bgm:title_dppt", "logoY:172"

    # Pantalla Oscura (gen 5)
    #"background:bw", "overlay2", "logoY:172", "logo:shine", "misc4_s2_x284_y339", "effect6_y312", "bgm:title_bw"

    # Cielo Forestal (gen 6)
    #"background4", "intro:6", "effect4", "effect5", "effect7", "overlay:static002", "bgm:title_xy"

    # Vibraciones Cósmicas (gen 7)
    #"background3", "intro:7", "effect5", "effect6", "overlay6", "logo:shine", "bgm:title_sm"
  #-------------------------------------------------------------------------------
  #                  V V     añade tus modificadores aquí     V V
  #-------------------------------------------------------------------------------
  "intro:2", "logoY:280", "logo:shine", "effect8", "logo:glow", "bgm:Titulo"

  ] # fin de la constante de configuración
  #-------------------------------------------------------------------------------
  # Otra configuración
  #-------------------------------------------------------------------------------
  # Configuración utilizada para determinar el grito de la especie de Pokémon a reproducir,
  # junto con la visualización de cierto sprite de Pokémon si corresponde. Pon false en MOSTRAR_GRITO
  # para no reproducir el grito de una especie.

  MOSTRAR_GRITO = false


  SPECIES = :PIKACHU
  # Aplica una forma a la especie de Pokémon
  SPECIES_FORM = 0
  # Aplica la forma femenina
  SPECIES_FEMALE = false
  # Aplica la variante brillante
  SPECIES_SHINY = false
  # Aplica el sprite trasero
  SPECIES_BACK = false

  # Configuración para reposicionar el texto "Presiona Enter" en la pantalla
  # mantén los valores en nil para mantener la posición predeterminada
  # el formato es [x,y]
  START_POS = [nil, nil]
end

#===============================================================================
# Transiciones para Pokémon Legendarios - Versión v21
# Para Pokémon Essentials v21 (LA BASE DE SKY)
#
# Incluye:
# 1. Animación de ojos para Pokémon Regi
# 2. Pantalla temblorosa para legendarios menores
#===============================================================================

# Configuración de especies
REGI_SPECIES = [:REGIROCK, :REGISTEEL, :REGICE, :REGIGIGAS, :REGIELEKI, :REGIDRAGO]

MINOR_LEGENDARIES = [
  # Kanto
  :MOLTRES, :ARTICUNO, :ZAPDOS, :MOLTRES_1, :ARTICUNO_1, :ZAPDOS_1, :MEWTWO, :MEW,
  # Johto
  :RAIKOU, :ENTEI, :SUICUNE, :LUGIA, :HOOH, :CELEBI,
  # Hoenn
  :REGICE, :REGIROCK, :REGISTEEL, :KYOGRE, :GROUDON, :RAYQUAZA,
  :DEOXYS, :JIRACHI, :LATIOS, :LATIAS,
  # Sinnoh
  :MESPRIT, :AZELF, :UXIE, :REGIGIGAS, :HEATRAN, :DARKRAI, 
  :CRESSELIA, :PALKIA, :DIALGA, :GIRATINA, :SHAYMIN, :ARCEUS, 
  :PHIONE, :MANAPHY,
  # Teselia
  :VIRIZION, :TERRAKION, :COBALION, :KELDEO, :TORNADUS,
  :THUNDURUS, :LANDORUS, :MELOETTA, :VICTINI, :RESHIRAM,
  :ZEKROM, :KYUREM, :GENESECT,
  # Kalos
  :XERNEAS, :YVELTAL, :ZYGARDE, :HOOPA, :VOLCANION, :DIANCIE,
  # Alola
  :TAPULELE, :TAPUKOKO, :TAPUBULU, :TAPUFINI, :COSMOG, 
  :COSMOEM, :SOLGALEO, :LUNALA, :NECROZMA, :MAGEARNA, 
  :MARSHADOW, :ZERAORA, :NIHILEGO, :BUZZWOLE, :PHEROMOSA, :XURKITREE, 
  :CELESTEELA, :KARTANA, :GUZZLORD, :STAKATAKA, :BLACEPHALON, :POIPOLE, :NAGANADEL,
  # Galar
  :MELTAN, :MELMETAL, :KUBFU, :URSHIFU, :GLASTRIER,
  :SPECTRIER, :CALYREX, :ZAMAZENTA, :ZACIAN, :ETERNATUS,
  :ZARUDE, :REGIELEKI, :REGIDRAGO, :ENAMORUS,
  # Paldea
  :KORAIDON, :MIRAIDON, :TINGLU, :CHIENPAO, :WOCHIEN, :CHIYU,
  :OGERPON, :OKIDOGI, :MUNKIDORI, :FEZANDIPITI,
  :TERAPAGOS, :PECHARUNT
]


#===============================================================================
# Funciones auxiliares
#===============================================================================

def pbBitmap(filename)
  begin
    return AnimatedBitmap.new(filename).bitmap
  rescue
    return nil
  end
end

def pbDisposeSpriteHash(hash)
  return if !hash
  hash.each_value { |sprite| sprite&.dispose }
end

class Sprite
  def blur_sprite
    self.color = Color.new(0, 0, 0, 64) unless self.disposed?
  end
end

#===============================================================================
# Funciones de verificación
#===============================================================================

def queuedIsRegi?(species)
  return false unless species
  base = GameData::Species.get(species).species
  REGI_SPECIES.include?(base)
end

def queuedIsMinorLegendary?(species)
  return false unless species
  # Los Regis tienen animación propia
  return false if queuedIsRegi?(species)
  MINOR_LEGENDARIES.include?(species)
end


#===============================================================================
# Funciones de animación para Regis (basadas en el código original)
#===============================================================================

def ebWildAnimationRegi(viewport, species)
  fp = {}
  
  # Todos los Regis en un solo array con sus posiciones
  regi_species = [:REGIROCK, :REGISTEEL, :REGICE, :REGIGIGAS, :REGIELEKI, :REGIDRAGO]
  index = nil
  regi_species.each_with_index do |regi, i|
    species_data = GameData::Species.try_get(regi)
    if species_data && species_data.species == species
      index = i
      break
    end
  end
  
  return unless index
  
  width = viewport.rect.width
  height = viewport.rect.height
  viewport.color = Color.new(0, 0, 0, 0)
  
  # Crear sprite de fondo
  fp["back"] = Sprite.new(viewport)
  fp["back"].bitmap = Graphics.snap_to_bitmap
  fp["back"].blur_sprite
  c = index < 3 ? 0 : 255
  fp["back"].color = Color.new(c, c, c, 128 * (index < 3 ? 1 : 2))
  fp["back"].z = 99999
  fp["back"].opacity = 0
  
  # Posiciones de ojos para cada Regi (6 Regis ahora)
  x = [
    # Regirock
    [width*0.5, width*0.25, width*0.75, width*0.25, width*0.75, width*0.25, width*0.75],
    # Registeel
    [width*0.5, width*0.3, width*0.7, width*0.15, width*0.85, width*0.3, width*0.7],
    # Regice
    [width*0.5, width*0.325, width*0.675, width*0.5, width*0.5, width*0.15, width*0.85],
    # Regigigas
    [width*0.5, width*0.5, width*0.5, width*0.5, width*0.35, width*0.65, width*0.5],
    # Regieleki
    [width*0.16, width*0.16, width*0.32, width*0.48, width*0.64, width*0.8, width*0.8],
    # Regidrago
    [width*0.3, width*0.7, width*0.5, width*0.4, width*0.6, width*0.5, width*0.5]
  ]
  y = [
    # Regirock
    [height*0.5, height*0.5, height*0.5, height*0.25, height*0.75, height*0.75, height*0.25],
    # Registeel
    [height*0.5, height*0.25, height*0.75, height*0.5, height*0.5, height*0.75, height*0.25],
    # Regice
    [height*0.5, height*0.5, height*0.5, height*0.25, height*0.75, height*0.5, height*0.5],
    # Regigigas
    [height*0.9, height*0.74, height*0.58, height*0.4, height*0.25, height*0.25, height*0.1],
    # Regieleki
    [height*0.30, height*0.70, height*0.5, height*0.5, height*0.5, height*0.30, height*0.70],
    # Regidrago
    [height*0.15, height*0.15, height*0.26, height*0.45, height*0.45, height*0.65, height*0.90]
  ]
  
  # Determinar qué gráfico usar (regi o regi2)
  graphic_file = (index < 4) ? "Graphics/Transitions/regi" : "Graphics/Transitions/regi2"
  graphic_index = (index < 4) ? index : index - 4  # 0-3 para regi, 0-1 para regi2
  
  # Crear sprites de ojos (14 sprites: 7 ojos base + 7 brillos)
  for j in 0...14
    fp["#{j}"] = Sprite.new(viewport)
    fp["#{j}"].bitmap = pbBitmap(graphic_file)
    if fp["#{j}"].bitmap
      fp["#{j}"].src_rect.set(96*(j/7), 100*graphic_index, 96, 100)
      fp["#{j}"].ox = fp["#{j}"].src_rect.width/2
      fp["#{j}"].oy = fp["#{j}"].src_rect.height/2
      fp["#{j}"].x = x[index][j%7]
      fp["#{j}"].y = y[index][j%7]
      fp["#{j}"].opacity = 0
      fp["#{j}"].z = 99999
    end
  end
  
  # Determinar velocidad de animación según el Regi
  is_fast = (index < 4)  # Los primeros 4 son más rápidos
  fade_times = is_fast ? 5 : 8
  fade_increment = is_fast ? 51 : 32
  wait_time = is_fast ? 0.03 : 0.05
  total_frames = is_fast ? 50 : 72
  
  # Animación: Fade in del fondo
  fade_times.times do
    fp["back"].opacity += fade_increment
    pbWait(wait_time)
  end
  
  # Animación principal: ojos apareciendo gradualmente
  k = -2
  for i in 0...total_frames
    if is_fast
      k += 2 if index < 3 && i%6==0
      k += (k==3 ? 2 : 1) if index >= 3 && i%3==0
    else
      k += 2 if i%8==0
      k += (k==3 ? 2 : 1) if i%4==0
    end
    k = 6 if k > 6
    
    for j in 0..k
      next unless fp["#{j}"] && fp["#{j}"].bitmap
      
      if is_fast
        fp["#{j}"].opacity += 45
        if fp["#{j}"].opacity >= 255 && fp["#{j+7}"] && fp["#{j+7}"].bitmap
          fp["#{j+7}"].opacity += 35
          fp["#{j}"].visible = fp["#{j+7}"].opacity < 255
        end
      else
        fp["#{j}"].opacity += 32
        if fp["#{j}"].opacity >= 255 && fp["#{j+7}"] && fp["#{j+7}"].bitmap
          fp["#{j+7}"].opacity += 26
          fp["#{j}"].visible = fp["#{j+7}"].opacity < 255
        end
      end
    end
    
    fp["back"].color.alpha += (is_fast ? 3 : 2) if fp["back"].color.alpha < 255
    pbWait(wait_time)
  end
  
  # Fade final a negro
  fade_times.times do
    viewport.color.alpha += fade_increment
    pbWait(wait_time)
  end
  
  # Limpiar sprites
  pbDisposeSpriteHash(fp)
end

def ebWildAnimationMinor(viewport, special = false)
  bmp = Graphics.snap_to_bitmap
  max = 30  # Reducido de 50 a 30 para ser más rápido
  amax = 4
  frames = {}
  zoom = 1
  angle = nil
  
  # Sin cambios de color - solo efecto de temblor y zoom
  viewport.color = Color.new(0, 0, 0, 0)
  
  # Fade in inicial más rápido y más sutil
  10.times do  # Reducido de 20 a 10
    viewport.color.alpha += 2  # Aumentado de 1 a 2 para compensar menos iteraciones
    pbWait(0.03)  # Más rápido: de 0.05 a 0.03
  end
  
  # Animación principal de temblor y zoom (más rápida)
  for i in 0...(max+15)  # Reducido de max+20 a max+15
    if !(i%2==0)
      # Controlar el zoom progresivo (más agresivo)
      if i > max*0.7  # Cambio de 0.75 a 0.7 para zoom más temprano
        zoom += 0.4  # Aumentado de 0.3 a 0.4 para zoom más agresivo
      else
        zoom -= 0.015  # Aumentado de 0.01 a 0.015 para zoom out más notable
      end
      
      # Calcular ángulo de rotación (temblor más frecuente)
      angle = 0 if angle.nil?
      angle = (i%2==0) ? angle : rand(amax*2) - amax  # Invertida la lógica para que funcione correctamente
      
      # Crear sprite de frame individual para el efecto de temblor
      frames["#{i}"] = Sprite.new(viewport)
      frames["#{i}"].bitmap = bmp
      frames["#{i}"].src_rect.set(0, 0, viewport.rect.width, viewport.rect.height)
      frames["#{i}"].ox = viewport.rect.width/2
      frames["#{i}"].oy = viewport.rect.height/2
      frames["#{i}"].x = viewport.rect.width/2
      frames["#{i}"].y = viewport.rect.height/2
      frames["#{i}"].angle = angle
      frames["#{i}"].zoom_x = zoom
      frames["#{i}"].zoom_y = zoom
      frames["#{i}"].tone = Tone.new(i/3, i/3, i/3)  # Cambio de i/4 a i/3 para brillo más rápido
      frames["#{i}"].opacity = 35  # Aumentado de 30 a 35 para mayor visibilidad
    end
    
    # Durante la segunda mitad de la animación - fade más agresivo
    if i >= max
      viewport.color.alpha += 8  # Aumentado de 6 a 8 para fade más rápido
    end
    
    pbWait(0.03)  # Más rápido: de 0.05 a 0.03
  end
  
  # Flash final blanco (más breve)
  if frames["#{max+14}"]  # Ajustado el índice por el cambio de max+19 a max+14
    frames["#{max+14}"].tone = Tone.new(255, 255, 255)
  end
  pbWait(0.3)  # Reducido de 0.5 a 0.3 (6 frames en lugar de 10)
  
  # Fade final a negro completo (más rápido)
  8.times do  # Reducido de 10 a 8
    viewport.color.alpha += 15  # Aumentado de 12 a 15 para compensar menos iteraciones
    pbWait(0.03)  # Más rápido: de 0.05 a 0.03
  end
  
  # Limpiar sprites
  pbDisposeSpriteHash(frames)
end


#===============================================================================
# Registro de las transiciones
#===============================================================================

SpecialBattleIntroAnimations.register("regi_legendary_animation", 90,
  proc { |battle_type, foe, location|
    next false if battle_type.odd?
    next false if !foe || !foe.is_a?(Array) || !foe[0].is_a?(Pokemon)
    next queuedIsRegi?(foe[0].species)
  },
  proc { |viewport, battle_type, foe, location|
    species = GameData::Species.get(foe[0].species).species
    ebWildAnimationRegi(viewport, species)
  }
)

SpecialBattleIntroAnimations.register("minor_legendary_animation", 80,
  proc { |battle_type, foe, location|
    next false if battle_type.odd?
    next false if !foe || !foe.is_a?(Array) || !foe[0].is_a?(Pokemon)
    next queuedIsMinorLegendary?(foe[0].species)
  },
  proc { |viewport, battle_type, foe, location|
    ebWildAnimationMinor(viewport)
  }
)
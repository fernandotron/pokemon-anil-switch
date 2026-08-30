#===============================================================================
#
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#                     Script : Letreros en Mapas 2.0
#                             por JessWishes
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#                 Creado para RPG Maker XP con base Essentials
#                        Compatible : versi�n 15+
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#   Muestra letreros al acceder a un mapa, que muestren el nombre del mapa.
#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
# DevianArt :
# https://www.deviantart.com/jesswshs
#
# Twitter :
# https://twitter.com/JessWishes
#
# Pagina de Recursos
# https://jessdev.weebly.com
#
# Discord : PixelWooper
# https://discord.gg/eTHrHD9e9a
#
#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#  Esto ha tomado tiempo y esfuerzo en ser diseñado, aunque es de uso libre,
#   se agradece que se den cr�ditos y que no se publique en otros sitios
#   externos como foros, pastebin o sitios de almacenamiento.
#
#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#                             Modo de uso
#
#   
#  1.-Agregar la carpeta Jess_Letreros con los graficos dentro de la carpeta :
#     Graphics/Windowskins
#
#  2.-Colocar el nombre correcto del estilo del letrero que se desea usar en la
#   constante JESS_LETREROS_ESTILO
#   ejemplo :  JESS_LETREROS_ESTILO = "LetsGO"
#
#  3.-Para los estilos DPP, HGSS, BW, BW2, SM y LetsGo puedes seleccionar un cuadro de texto
#   diferente para cada mapa de los que est�n disponibles e incluso agregar
#   nuevos, siempre y cuando exista ese cuadro en la imagen correspondiente.
#
#  4.-Puedes usar la constante JESS_LETREROS_BW2_EST para mostrar/ocultar la barra
#   inferior(estacion del a�o) en el estilo BW2.
#
#  5.-Para evitar errores visuales, al usar el estilo BW o XY, se recomiendo no
#   crear mapas con nombres demasiado largos.
#
#  6.-En casos especiales, como por ejemplo durante un evento o scena, en la cual
#   no se desee que se muestre el letrero del mapa, se usa el siguiente
#   comando : pb_jla(false)
#   Y al finalizar el evento o escena, se usa así : pb_jla(true) para que se
#   muestren de nuevo.
#
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
# Constantes
#-------------------------------------------------------------------------------

JESS_PATH = "Graphics/Windowskins/Jess_Letreros/"

# Estilos de Letreros : "DPP", "HGSS", "BW", "BW2", "XY", "ORAS", "SM", "LetsGO"
JESS_LETREROS_ESTILO = "LetsGO"

## Diseño del letrero según el nombre del mapa, el �ltimo elemento de la lista
#  tiene mayor prioridad.

# Elemento de la lista que será el letrero por defecto
JESS_LETREROS_DPP_PREDE = 0 # 0=(#Ciudad)

# Para Estilo DPP, por defecto tendrá el primero de la lista.
JESS_LETREROS_DPP=[["ciudad"],            #Ciudad
                   ["pueblo"],            #Pueblo
                   ["ruta"],              #Ruta
                   ["cueva"],             #Cueva
                   ["bosque"],            #Bosque
                   ["ruta 65"],           #Pradera
                   ["ruta 66","ruta 67"], #Mar
                   [],                    #Lago
                   [],                    #Interior
                   []                     #Otro
                  ]


# Elemento de la lista que será el letrero por defecto
JESS_LETREROS_HGSS_PREDE = 7 # 7=(#Otros)

# Para Estilo HGSS, por defecto tendrá el primero de la lista.
JESS_LETREROS_HGSS=[[],         #Mar
                    ["ciudad"], #Ciudad
                    ["pueblo"], #Pueblo
                    ["ruta"],   #Ruta
                    [],         #Cueva
                    [],         #Bosque
                    [],         #Lago
                    []          #Otros
                   ]

                   
# Elemento de la lista que será el letrero por defecto
JESS_LETREROS_BW_PREDE = 0 # 0=(#Original)

# Para Estilo BW, por defecto tendrá el primero de la lista.
JESS_LETREROS_BW=[ ["ciudad","pueblo"], #Original
                   [],                  #v2
                   [],                  #v3
                   [],                  #v4
                   ["ruta"],            #v5
                   []                   #v6
                   ]

                   
# Elemento de la lista que ser� el letrero por defecto
JESS_LETREROS_BW2_PREDE = 1 # 1=(#Ciudad)

# Para Estilo BW2, por defecto tendrá el primero de la lista.
JESS_LETREROS_BW2=[ [],         #SinIcono
                    ["ciudad"], #Ciudad
                    ["pueblo"], #Pueblo
                    ["ruta"],   #Ruta 1
                    ["ruta 2"]  #Ruta 2
                   ]

                   
# Elemento de la lista que será el letrero por defecto
JESS_LETREROS_SM_PREDE = 0 # 0=(#Original)

# Para Estilo SM, por defecto tendrá el primero de la lista.
JESS_LETREROS_SM=[ ["ciudad","pueblo"], #Original
                   ["ruta"],            #v2
                   ["ultraumbral"]      #v3
                   ]

                   
# Elemento de la lista que será el letrero por defecto
JESS_LETREROS_LETSGO_PREDE = 0 # 0=(#Original)

# Para Estilo LetsGo, por defecto tendrá el primero de la lista.
JESS_LETREROS_LETSGO=[ ["ciudad","pueblo"], #Original
                       ["ruta"],            #v2
                       ["montaña"],         #v3
                       ["meseta"]           #v4
                   ]


JESS_LETREROS = { "DPP" => [JESS_LETREROS_DPP_PREDE, JESS_LETREROS_DPP], "HGSS" => [JESS_LETREROS_HGSS_PREDE, JESS_LETREROS_HGSS], 
                  "BW" => [JESS_LETREROS_BW_PREDE, JESS_LETREROS_BW], "BW2" => [JESS_LETREROS_BW2_PREDE, JESS_LETREROS_BW2], 
                  "ORAS" => [], 
                  "SM" => [JESS_LETREROS_SM_PREDE, JESS_LETREROS_SM], "LetsGO" => [JESS_LETREROS_LETSGO_PREDE, JESS_LETREROS_LETSGO] }
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

# Mostrar/Ocultar la barra de Estaciones para BW2
JESS_LETREROS_BW2_EST = true
                       
# Nombre de las estaciones, Exclusivo para BW2
JESS_LETREROS_SEASON = [_INTL("Primavera"),  # Nov,Dic,Ene
                        _INTL("Verano"),     # Feb,Mar,Abr
                        _INTL("Otoño"),      # May,Jun,Jul
                        _INTL("Invierno")  ] # Ago,Sep,Oct
                        
# Posición X/Y del letrero en la pantalla
# No editar a menos que sepas lo que haces
JESS_LETREROS_ALTURA_OLD = [["DPP"   ,0,20],
                        ["HGSS"  ,0,5],
                        ["BW"    ,0,20],
                        ["BW2"   ,0,-18],
                        ["XY"    ,5,16],
                        ["ORAS"  ,0,0],
                        ["SM"    ,0,128],
                        ["LetsGO",0,144]
                       ]

JESS_LETREROS_ALTURA = { "DPP"    => [0,20],
                       "HGSS"   => [0,5],
                       "BW"     => [0,20],
                       "BW2"    => [0,-18],
                       "XY"     => [5,16],
                       "ORAS"   => [0,0],
                       "SM"     => [20,128],
                       "LetsGO" => [0,144]
                      }

# Tamaño del bitmap   [Estilo  , X,  Y]
# No editar a menos que sepas lo que haces
JESS_LETREROS_SIZE_OLD = [["DPP"   ,146,48],
                      ["HGSS"  ,144,32],
                      ["BW"    ,256,16],
                      ["BW2"   ,256,26],
                      ["XY"    ,240,64],
                      ["ORAS"  ,256,26],
                      ["SM"    ,256,256],
                      ["LetsGO",256,48]
                     ]

JESS_LETREROS_SIZE = { "DPP"    => [146,48],
                       "HGSS"   => [144,32],
                       "BW"     => [256,16],
                       "BW2"    => [256,26],
                       "XY"     => [240,64],
                       "ORAS"   => [256,26],
                       "SM"     => [256,256],
                       "LetsGO" => [256,48]
                      }

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------

class Game_Temp
  attr_accessor :jess_letreros_activo
end

def pb_jla(val)
   $game_temp.jess_letreros_activo = !val
end

def pbbwtxt(v="",ne=0)
  txt2=v.split(//)
  txt=""
  for i in 0...txt2.size
    txt+=txt2[i]
    ne.times {txt+=" "}
  end
  return txt
end
          

class LocationWindow
  
# Lista de condiciones que eliminan el letrero de la pantalla,
#  por ejemplo al Abrir el menú o hablar con un npc.
  def jess_letreros_isDispose?
    return ( $game_temp.message_window_showing ||            # Si se muestra un mensaje
            @currentmap!=$game_map.map_id     ||             # Si se cambia de mapa
           (Input.press?(Input::B) && !$game_player.moving?) # Abrir el Menú
       )
  end
  
  def pbLGsrc
    val=5
    for i in 0...JESS_LETREROS_LETSGO.size
      for j in 0...JESS_LETREROS_LETSGO[i].size
        val+=(48*i) if JESS_LETREROS_LETSGO[i][j]==$game_map.map_id
      end
    end
    return val
  end
  
  def pbbw(name)
    @window.x=Graphics.width
    @window.y=0
    @pic.x=0
    @pic.y=14
    @pic.opacity=0
    @bw_c=pbbwtxt(@name,0)
  end
  
  def pbxy
    return JESS_LETREROS_ALTURA[JESS_LETREROS_ESTILO] if JESS_LETREROS_ALTURA.key?(JESS_LETREROS_ESTILO)
  end
  
  def pbcrop
    JESS_LETREROS_SIZE.key?(JESS_LETREROS_ESTILO)
    @tamano=JESS_LETREROS_SIZE[JESS_LETREROS_ESTILO]
    return @tamano if @tamano.size>0
  end
  
  def pbmps
    mapy=0
    mapa=$game_map.name.downcase
    return mapy if !JESS_LETREROS.key?(JESS_LETREROS_ESTILO) || !JESS_LETREROS[JESS_LETREROS_ESTILO][0]
    mapy = JESS_LETREROS[JESS_LETREROS_ESTILO][0] * @tamano[1]
    for i in 0...JESS_LETREROS[JESS_LETREROS_ESTILO][1].size
      next if JESS_LETREROS[JESS_LETREROS_ESTILO][1][i].size==0
      for j in 0...JESS_LETREROS[JESS_LETREROS_ESTILO][1][i].size
        mapy=i*@tamano[1] if mapa.include?(JESS_LETREROS[JESS_LETREROS_ESTILO][1][i][j])
      end
    end
    return mapy
  end
  
  def pbtemporadas
    timenow = pbGetTimeNow
    thismon = timenow.mon
    tm=0 if thismon==3  || thismon==4  || thismon==5
    tm=1 if thismon==6  || thismon==7  || thismon==8
    tm=2 if thismon==9  || thismon==10 || thismon==11
    tm=3 if thismon==12 || thismon==1  || thismon==2
    temp=JESS_LETREROS_SEASON[tm]
    return temp
  end
  
  def initialize(name)
    return if $game_temp.jess_letreros_activo==true
    vista=Viewport.new(0,0,Graphics.width,Graphics.height)
    @pic=Sprite.new(vista)
    @pic.z=99999
    @pic.bitmap=RPG::Cache.load_bitmap(JESS_PATH, JESS_LETREROS_ESTILO)
    @pic.y=-48
    r=pbcrop 
    my=pbmps
    @pic.src_rect.set(0,my,r[0],r[1])
    @pic.zoom_x=2; @pic.zoom_y=2
    @window = Window_AdvancedTextPokemon.new("")
    @window.baseColor= Color.new(240,240,240)
    @window.shadowColor= Color.new(92,92,99)
    @window.text=(JESS_LETREROS_ESTILO=="BW") ? pbbwtxt(name,3) : name
    @window.resizeToFit(@window.text,Graphics.width)
    @window.x = 10
    @window.y = (JESS_LETREROS_ESTILO=="HGSS") ? -48 : -28
    @window.y = -64 if JESS_LETREROS_ESTILO=="BW2"
    @window.y = -30 if JESS_LETREROS_ESTILO=="XY"
    @window.x += 30 if JESS_LETREROS_ESTILO=="BW2"
    @window.z = 99999
    @window.windowskin=nil
    if JESS_LETREROS_ESTILO=="XY"
      @pic.zoom_y=0.4
      @pic.y=0
      @pic.tone=Tone.new(-210,-210,-210)
      @window.y-=4
      @window.x= (@window.text.length<2) ? 126 : 126-(@window.text.length*6)+4
    end
    if JESS_LETREROS_ESTILO=="BW2"
        @pic.opacity=200
        @pic.y=-48
        if JESS_LETREROS_BW2_EST==true
          @pic2=Sprite.new
          @pic2.z=99999
          @pic2.bitmap=RPG::Cache.load_bitmap(JESS_PATH,"#{JESS_LETREROS_ESTILO}_2")
          @pic.y=-48
          @pic2.y=Graphics.height
          @pic2.zoom_x=2; @pic2.zoom_y=2
          @w2=Window_AdvancedTextPokemon.new("")
          @w2.y=Graphics.height
          @w2.baseColor= Color.new(240,240,240)
          @w2.shadowColor= Color.new(92,92,99)
          @w2.text=pbtemporadas
          @w2.resizeToFit(@window.text+"  ",Graphics.width)
          @w2.x = Graphics.width-190
          @w2.z = 99999
          @w2.windowskin=nil
        end
    elsif JESS_LETREROS_ESTILO=="ORAS"
      @pic.y=Graphics.height-@pic.bitmap.height
      @pic.x=0
      @pic.opacity=125
      @window.y=Graphics.height-56
      @window.x=Graphics.width
      @pic2=Sprite.new
      @pic2.z=99998
      @pic.z=99998
      @pic2.bitmap=RPG::Cache.load_bitmap(JESS_PATH,"#{JESS_LETREROS_ESTILO}_2")
      @pic2.src_rect.set(0,2,256,22)
      @pic2.x=0
      @pic2.y=Graphics.height-44
      @pic2.opacity=0
      @pic2.zoom_x=2
      @pic2.zoom_y=2
    elsif JESS_LETREROS_ESTILO=="SM"
      @pic.src_rect.set(my,0,256,64)
      @pic.x=0
      @pic.opacity=0
      @pic.y=Graphics.width
      @window.y=Graphics.width
      @window.x=Graphics.width-(@window.text.length*15)
    elsif JESS_LETREROS_ESTILO=="LetsGO"
      @pic.src_rect.set(0,3+my,209,0)
      @pic.x=(Graphics.width/2)-193
      @pic.opacity=200
      @pic.y=Graphics.height-60
      @window.x = -500
      @window.y = Graphics.height-90
      @pic2=Sprite.new
      @pic2.z=99998
      @pic2.bitmap=RPG::Cache.load_bitmap(JESS_PATH, JESS_LETREROS_ESTILO)
      @pic2.src_rect.set(0,0,256,3)
      @pic2.x=-Graphics.width
      @pic2.y=Graphics.height-66
      @pic2.opacity=180
      @pic2.zoom_x=2; @pic2.zoom_y=2
      @pic3=Sprite.new
      @pic3.z=99998
      @pic3.bitmap=RPG::Cache.load_bitmap(JESS_PATH, JESS_LETREROS_ESTILO)
      @pic3.src_rect.set(0,0,256,3)
      @pic3.x=Graphics.width
      @pic3.y=Graphics.height-12-48
      @pic3.zoom_x=2; @pic3.zoom_y=2
      @pic3.opacity=180
    end
    @currentmap = $game_map.map_id
    @name=name
    @frames = 0
    @orasframes=0
    pbbw(name) if JESS_LETREROS_ESTILO=="BW"
    @pic.src_rect.set(0,my,r[0],r[1]) if JESS_LETREROS_ESTILO=="BW"
  end

  def disposed?
    @window.disposed? if @window
    @pic.disposed?  if @pic
    @pic3.disposed? if @pic3
    @pic2.disposed? if @pic2
    @w2.disposed?   if @w2
  end

  def dispose
    @window.dispose if @window
    @pic.dispose  if @pic
    @pic3.dispose if @pic3
    @pic2.dispose if @pic2
    @w2.dispose   if @w2
  end

  def update
    return if !@window || @window.disposed?
    @window.update
    @pic.update
    @pic3.update if JESS_LETREROS_ESTILO=="LetsGO"
    @pic2.update if (JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true) || JESS_LETREROS_ESTILO=="ORAS" || JESS_LETREROS_ESTILO=="LetsGO" 
    @w2.update if JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
    if jess_letreros_isDispose?
      @window.dispose
      @pic.dispose
      @pic3.dispose if JESS_LETREROS_ESTILO=="LetsGO"
      @pic2.dispose if (JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true) || JESS_LETREROS_ESTILO=="ORAS" || JESS_LETREROS_ESTILO=="LetsGO"
      @w2.dispose if JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
      return
    end
    if JESS_LETREROS_ESTILO=="BW"
      @pic.opacity+=10 if @frames<20
      @window.x-=21 if @frames>20 && @frames<45
      @window.text=@bw_c if @frames==36
      @window.x=-20 if @window.x<-20
      @window.dispose if @frames>80
      @pic.dispose if @frames>80
      @frames+=1
    elsif JESS_LETREROS_ESTILO=="ORAS"
      @pic2.opacity+=10 if @pic2.opacity<220 && @orasframes<100 && @frames>15
      @window.x-=5 if @window.x>(Graphics.width-(@window.text.length*15)) && @orasframes<100
      @orasframes+=1 if @frames>30
      @pic2.src_rect.set(0,30,256,22)   if @orasframes==10
      @pic2.src_rect.set(0,(26*2)+4,256,22) if @orasframes==20
      @pic2.src_rect.set(0,(26*3)+4,256,22) if @orasframes==30
      @pic2.src_rect.set(0,(26*4)+4,256,22) if @orasframes==40
      @pic2.src_rect.set(0,(26*5)+4,256,22) if @orasframes==50
      @pic2.src_rect.set(0,(26*2)+4,256,22) if @orasframes==60
      @pic2.src_rect.set(0,(26*1)+4,256,22) if @orasframes==70
      @pic2.src_rect.set(0,4,256,22)    if @orasframes==80
      @window.x+=5 if @orasframes>100
      @pic2.opacity-=20 if @window.x>Graphics.width && @orasframes>100
      @pic.dispose    if @pic2.opacity<10 && @orasframes>100
      @window.dispose if @pic2.opacity<10 && @orasframes>100
      @pic2.dispose   if @pic2.opacity<10 && @orasframes>100
      @frames+=1 if @frames<35
    elsif JESS_LETREROS_ESTILO=="SM"
      if @frames<45
        @pic.opacity+=5
        @pic.y-=10 if @pic.y>(Graphics.height-((@pic.bitmap.height/3)*2))+8
        @window.y-=10 if @window.y>(Graphics.height-((@pic.bitmap.height/3)*2)+55 ) && @frames>12
      elsif @frames>100
        @pic.y+=8
        @window.y+=8
      end
      @pic.src_rect.set(pbmps,0,256,64) if @frames>100
      @pic.src_rect.set(pbmps,64,256,64) if @orasframes==0 && @frames>30
      @pic.src_rect.set(pbmps,64*2,256,64) if @orasframes==16 && @frames>30
      @frames+=1
      @orasframes+=1 if @frames>20 && @frames<100
      @orasframes=0  if @orasframes==32
      @pic.dispose if @frames>112
      @window.dispose if @frames>112
    elsif JESS_LETREROS_ESTILO=="LetsGO"
      if @frames<25
        @pic2.x+=20 if @pic2.x<0; @pic3.x-=20 if @pic3.x>0
        @pic2.x=0 if @frames==24
        @pic3.x=0 if @frames==24
      elsif @frames>27 && @frames<38
        @orasframes+=1
        @pic.src_rect.set(0,5+pbmps,209,4*@orasframes) if (@orasframes*4)<52
        @pic.y-=4 if (@orasframes*4)<52
        @pic2.y-=4
        @pic3.y+=4 if @frames<37
        @window.x=(Graphics.width/2)-(@window.text.length*8)+13 if @frames==34
        @orasframes=0 if @frames==37
      elsif @frames>70 && @frames<83
        @window.text="" if @frames==71
        @orasframes+=1
        @pic.src_rect.set(0,5+pbmps,209,40-(4*@orasframes))
        @pic.y+=4 
        @pic2.y+=4
        @pic3.y-=4 if @frames<83
      elsif @frames>82
         @pic2.x-=20; @pic3.x+=20
      elsif @frames>83 && @pic2.x<(-Graphics.width)
         @pic.dispose
         @pic2.dispose
         @pic3.dispose
         @window.dispose
      end
      @frames+=1
    else  
      if @frames>80
        if JESS_LETREROS_ESTILO=="XY"
           @pic.opacity-=10
           @window.text="" if @frames==81
           @window.dispose if @frames>100
           @pic.dispose    if @frames>100
           @frames+=1
        else
          @pic.y -= 4
          @pic2.y += 4 if JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
          @w2.y += 4 if JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
          @window.y -= 4
          @pic.dispose if @window.y+@window.height<0
          @pic2.dispose if @window.y+@window.height<0 && JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
          @w2.dispose if @window.y+@window.height<0 && JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
          @window.dispose if @window.y+@window.height<0
        end
      else
        @pic.zoom_y+=0.08 if @pic.zoom_y<2
        pn=(JESS_LETREROS_ESTILO=="XY") ? 0 : 4
        wn=(JESS_LETREROS_ESTILO=="XY") ? 2 : 4
        @pic.tone=Tone.new(-100+(@frames*3),-100+(@frames*3),-100+(@frames*3)) if JESS_LETREROS_ESTILO=="XY" && (-100+(@frames*3))<0
        @pic.y += pn if @window.y<pbxy[1]
        @pic2.y -= 4 if @window.y<pbxy[1] && JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
        @w2.y -= 4 if @window.y<pbxy[1] && JESS_LETREROS_ESTILO=="BW2" && JESS_LETREROS_BW2_EST==true
        @window.y += wn if @window.y<pbxy[1]
        @frames += 1
      end
    end
  end
  
end
#
#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#
#===============================================================================

################################################################################
#                        SCRIPT HECHO POR SKYFLYER                             #
################################################################################

PosFotoIZDAX  = 52
PosFotoDCHAX  = 280
PosFotoARRIBY = 42
PosFotoABAJOY = 196

CURSORIZDAX = PosFotoIZDAX  - 8
CURSORDCHAX = PosFotoDCHAX  - 8
CURSORARRIY = PosFotoARRIBY - 10
CURSORABAJY = PosFotoABAJOY - 10

$actualizarCacheAlbum = false

# Usar siempre la carpeta del juego para el álbum
ALBUM_DIR = "Fotos"

class AlbumFotos_Scene

	def pbStartScene
		#Si la carpeta de capturas no existe, la creamos.
		if !FileTest.exist?(ALBUM_DIR)
            Dir.mkdir(ALBUM_DIR) if !$joiplay
        end
        
        # Copiar fotos desde AppData antes de cargar el álbum
        copiar_fotos_de_carpeta_sistema_a_juego

        # Posible implementación: renombrar las imágenes para que no haya huecos
        @page     = 0     # Página del álbum
        @numpages = 0 # Número total de páginas
        p = Dir.glob(File.join(ALBUM_DIR, "capture*.png"))

		@numcapturas = p.size # Número total de fotos en la carpeta.
		
		@numpages=(p.size)/4
		if ((p.size)%4 != 0) || @numpages==0
			@numpages+=1
		end
		
		@photo=0    #Número de las 4 fotos por página
		@viendofoto=false
		@viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
		@viewport.z=99999
		@sprites={}
		
		@sprites["fondo"] = IconSprite.new(0,0,@viewport)
		@sprites["fondo"].setBitmap("Graphics/UI/Album/Fondo")

		@sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow",8,40,28,2,@viewport)
		@sprites["leftarrow"].x       = 10-4
		@sprites["leftarrow"].y       = Graphics.height/2 - 20
		@sprites["leftarrow"].visible = false if @numpages==1
		@sprites["leftarrow"].play
		@sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,2,@viewport)
		@sprites["rightarrow"].x       = Graphics.width - (512-460) + 4
		@sprites["rightarrow"].y       = Graphics.height/2 - 20
		@sprites["rightarrow"].visible = false if @numpages==1
		@sprites["rightarrow"].play

		@overlay = BitmapSprite.new(Graphics.width,Graphics.height)
		@overlay.z = 99999
		pbSetSystemFont(@overlay.bitmap)
		
		for i in 0...4
			#512 anchura pantalla
			#384 altura pantalla
			x=PosFotoIZDAX  if (i == 0 || i == 2)
			x=PosFotoDCHAX  if (i == 1 || i == 3)
			y=PosFotoARRIBY if (i == 0 || i == 1)
			y=PosFotoABAJOY if (i == 2 || i == 3)
			@sprites["basecaptura#{i+1}"] = IconSprite.new(x,y,@viewport)
			@sprites["basecaptura#{i+1}"].setBitmap("Graphics/UI/Album/BaseCaptura")
		end

        if $actualizarCacheAlbum == true
            System.reload_cache if defined?(System.reload_cache)
            $actualizarCacheAlbum = false
        end
		
		for i in 0...4
			x=@sprites["basecaptura#{i+1}"].x
			y=@sprites["basecaptura#{i+1}"].y
			@sprites["captura#{i+1}"] = IconSprite.new(x,y,@viewport)
			
			numcaptura = sprintf("capture%03d",((@page*4)+i))
            file_pattern = File.join(ALBUM_DIR, "#{numcaptura}*.png")
            # Buscamos el archivo que se llame así.
            matching_files = Dir.glob(file_pattern)
            if !matching_files.empty?
                first_matching_file = matching_files.first
                @sprites["captura#{i+1}"].setBitmap(first_matching_file)
                @sprites["captura#{i+1}"].zoom_x = @sprites["captura#{i+1}"].zoom_x*0.354
                @sprites["captura#{i+1}"].zoom_y = @sprites["captura#{i+1}"].zoom_y*0.354
            else
                echoln "No se encontró ningún archivo que coincida con el patrón #{file_pattern}"
            end
		end
		
		#Marcamos seleccionada la primera captura
		@sprites["seleccion"] = IconSprite.new(CURSORIZDAX,CURSORARRIY,@viewport)
		@sprites["seleccion"].setBitmap("Graphics/UI/Album/Seleccion")
		
		#Ponemos número de página y texto de salir
		@overlay.bitmap.clear
        textpos = []
        textpos.push(
            ["FOTOS",Graphics.width/2,10,2,Color.new(255,255,255),Color.new(20,20,20,120),1],
            ["C: Abrir foto",20,Graphics.height-30,0,Color.new(255,255,255),Color.new(20,20,20,120),1],
            ["X: Salir",Graphics.width/2,Graphics.height-30,2,Color.new(255,255,255),Color.new(20,20,20,120),1],
            ["Página: #{@page+1}/#{@numpages}",Graphics.width-20,Graphics.height-30,1,Color.new(255,255,255),Color.new(20,20,20,120),1]
        )
        pbSetSystemFont(@overlay.bitmap)
        pbDrawTextPositions(@overlay.bitmap,textpos)

		#Gráfico de la foto que es ampliada
		@sprites["capturaAmpliada"] = IconSprite.new(0,0,@viewport)
		@sprites["capturaAmpliada"].visible = false

        @sprites["borde_datos"] = IconSprite.new(0,0,@viewport)
        @sprites["borde_datos"].z = @sprites["capturaAmpliada"].z + 10
		@sprites["borde_datos"].visible = false
		
		pbUpdateAlbum
	end
	
	def pbUpdateAlbum
		loop do
			Graphics.update
			Input.update
            @sprites["leftarrow"].update
		    @sprites["rightarrow"].update
			if Input.trigger?(Input::RIGHT)
                pbPlayCursorSE
                if @viendofoto==false
                # Si estás en la foto de la izquierda, pasas a la de la derecha
                    if (@photo==0 || @photo==2)
                        @sprites["seleccion"].x=CURSORDCHAX
                        @photo+=1
                    #Si estás en la foto de la derecha, pasas a la siguiente página (si la hay)  
                    else
                        avanzarPagina
                    end
                else #viendo la foto
                    if (((@page*4)+@photo)!= (@numcapturas-1))
                        if @photo==0
                            @sprites["seleccion"].x=CURSORDCHAX
                            @photo+=1
                        elsif @photo==1
                            @sprites["seleccion"].x=CURSORIZDAX
                            @sprites["seleccion"].y=CURSORABAJY
                            @photo+=1
                        elsif @photo==2
                            @sprites["seleccion"].x=CURSORDCHAX
                            @photo+=1
                        else
                            @sprites["seleccion"].y=CURSORARRIY
                            avanzarPagina
                            @photo=0
                        end
                         
                        @overlay.bitmap.clear
                        textpos = []
                        nombre_foto = sprintf("capture%03d",(@page*4)+@photo)
                        file_pattern = File.join(ALBUM_DIR, "#{nombre_foto}*.png")
                        # Buscamos el archivo que se llame así.
                        matching_files = Dir.glob(file_pattern)
                        
                        if !matching_files.empty?
                            first_matching_file = matching_files.first
                            nombre_sin_png = first_matching_file.chomp(".png")
                            parts = nombre_sin_png.split('_')

                            numcaptura_ui = ((@page*4)+@photo)+1 
                            dia = parts[-3].to_i
                            mes = parts[-2].to_i
                            anyo = parts[-1].to_i
                            textpos.push(
                                ["C/X: Salir",20,Graphics.height-30,0,Color.new(255,255,255),Color.new(20,20,20,120),1],
                                ["#{dia}/#{mes}/#{anyo}",Graphics.width/2,Graphics.height-30,2,Color.new(255,255,255),Color.new(20,20,20,120),1],
                                ["Captura: #{numcaptura_ui}",Graphics.width-20,Graphics.height-30,1,Color.new(255,255,255),Color.new(20,20,20,120),1]
                            )
                            pbSetSystemFont(@overlay.bitmap)
                            pbDrawTextPositions(@overlay.bitmap,textpos)

                            @sprites["capturaAmpliada"].setBitmap(first_matching_file)
                            @sprites["capturaAmpliada"].visible = true
                            @sprites["borde_datos"].setBitmap("Graphics/UI/Album/Borde")
                            @sprites["borde_datos"].visible = true
                            @viendofoto=true
                        end
                    end
                end
        
            elsif Input.trigger?(Input::LEFT)
                pbPlayCursorSE
                if @viendofoto==false
                # Si estás en la foto de la derecha, pasas a la de la izquierda
                    if (@photo==1 || @photo==3)
                        @sprites["seleccion"].x=CURSORIZDAX
                        @photo-=1
                    #Si estás en la foto de la izquierda, pasas a la anterior página (si la hay)  
                    else
                        retrocederPagina
                    end
                else #viendo la foto
                    if (((@page*4)+@photo) != 0)
                        if @photo==0
                            @sprites["seleccion"].y=CURSORABAJY
                            retrocederPagina
                            @photo=3
                        elsif @photo==1
                            @sprites["seleccion"].x=CURSORIZDAX
                            @photo-=1
                        elsif @photo==2
                            @sprites["seleccion"].x=CURSORDCHAX
                            @sprites["seleccion"].y=CURSORARRIY
                            @photo-=1
                        else
                            @sprites["seleccion"].x=CURSORIZDAX
                            @photo-=1
                        end
                        
                        @overlay.bitmap.clear
                        textpos = []
                        nombre_foto = sprintf("capture%03d",(@page*4)+@photo)
                        file_pattern = File.join(ALBUM_DIR, "#{nombre_foto}*.png")
                        # Buscamos el archivo que se llame así.
                        matching_files = Dir.glob(file_pattern)
                        
                        if !matching_files.empty?
                            first_matching_file = matching_files.first
                            nombre_sin_png = first_matching_file.chomp(".png")
                            parts = nombre_sin_png.split('_')

                            numcaptura_ui = ((@page*4)+@photo)+1 
                            dia = parts[-3].to_i
                            mes = parts[-2].to_i
                            anyo = parts[-1].to_i
                            textpos.push(
                                ["C/X: Salir",20,Graphics.height-30,0,Color.new(255,255,255),Color.new(20,20,20,120),1],
                                ["#{dia}/#{mes}/#{anyo}",Graphics.width/2,Graphics.height-30,2,Color.new(255,255,255),Color.new(20,20,20,120),1],
                                ["Captura: #{numcaptura_ui}",Graphics.width-20,Graphics.height-30,1,Color.new(255,255,255),Color.new(20,20,20,120),1]
                            )
                            pbSetSystemFont(@overlay.bitmap)
                            pbDrawTextPositions(@overlay.bitmap,textpos)

                            @sprites["capturaAmpliada"].setBitmap(first_matching_file)
                            @sprites["capturaAmpliada"].visible = true
                            @sprites["borde_datos"].setBitmap("Graphics/UI/Album/Borde")
                            @sprites["borde_datos"].visible = true
                            @viendofoto=true
                        end
                    end
                end
			elsif Input.trigger?(Input::DOWN) && @viendofoto==false
				if (@photo==0 || @photo==1)
					@sprites["seleccion"].y=CURSORABAJY
					@photo+=2
					pbPlayCursorSE
				end
			elsif Input.trigger?(Input::UP) && @viendofoto==false
				if (@photo==2 || @photo==3)
					@sprites["seleccion"].y=CURSORARRIY
					@photo-=2
					pbPlayCursorSE
				end
			# Entrar en una foto
			elsif Input.trigger?(Input::USE) && @viendofoto==false && (((@page*4)+@photo)< @numcapturas )
				pbPlayDecisionSE
                @overlay.bitmap.clear
                textpos = []
                nombre_foto = sprintf("capture%03d",(@page*4)+@photo)
                file_pattern = File.join(ALBUM_DIR, "#{nombre_foto}*.png")

                # Buscamos el archivo que se llame así.
                matching_files = Dir.glob(file_pattern)
                if !matching_files.empty?
                    first_matching_file = matching_files.first
                    nombre_sin_png = first_matching_file.chomp(".png")
                    parts = nombre_sin_png.split('_')

                    numcaptura_ui = ((@page*4)+@photo)+1 
                    dia = parts[-3].to_i
                    mes = parts[-2].to_i
                    anyo = parts[-1].to_i
                    textpos.push(
                        ["C/X: Salir",20,Graphics.height-30,0,Color.new(255,255,255),Color.new(20,20,20,120),1],
                        ["#{dia}/#{mes}/#{anyo}",Graphics.width/2,Graphics.height-30,2,Color.new(255,255,255),Color.new(20,20,20,120),1],
                        ["Captura: #{numcaptura_ui}",Graphics.width-20,Graphics.height-30,1,Color.new(255,255,255),Color.new(20,20,20,120),1]
                    )
                    pbSetSystemFont(@overlay.bitmap)
                    pbDrawTextPositions(@overlay.bitmap,textpos)

                    @sprites["capturaAmpliada"].setBitmap(first_matching_file)
                    @sprites["capturaAmpliada"].visible = true
                    @sprites["borde_datos"].setBitmap("Graphics/UI/Album/Borde")
                    @sprites["borde_datos"].visible = true
                    @viendofoto=true
                end

			# Cuando estás viendo una foto
			elsif (Input.trigger?(Input::BACK)||Input.trigger?(Input::USE)) && @viendofoto==true
				@sprites["capturaAmpliada"].visible = false
                @sprites["borde_datos"].visible = false
				@viendofoto=false
				escribirTextos
				pbPlayCancelSE
			# Salir del álbum
			elsif Input.trigger?(Input::BACK) && @viendofoto==false
                pbPlayCancelSE
				break
			end
		end	
	end
	
	def escribirTextos
		@overlay.bitmap.clear
        textpos = []
        textpos.push(
            ["FOTOS",Graphics.width/2,10,2,Color.new(255,255,255),Color.new(20,20,20,120),1],
            ["C: Abrir foto",20,Graphics.height-30,0,Color.new(255,255,255),Color.new(20,20,20,120),1],
            ["X: Salir",Graphics.width/2,Graphics.height-30,2,Color.new(255,255,255),Color.new(20,20,20,120),1],
            ["Página: #{@page+1}/#{@numpages}",Graphics.width-20,Graphics.height-30,1,Color.new(255,255,255),Color.new(20,20,20,120),1]
        )
        pbSetSystemFont(@overlay.bitmap)
        pbDrawTextPositions(@overlay.bitmap,textpos)
	end
	
	def avanzarPagina
		#Movemos el cursor
		@sprites["seleccion"].x=CURSORIZDAX
        @photo-=1
        
        if @page+1 == @numpages
            @page = 0
        else
            @page+=1
        end
        
        # Limpiar todos los sprites de capturas antes de cargar las nuevas
        for i in 0...4
            @sprites["captura#{i+1}"].setBitmap(nil)
        end
        
		for i in 0...4
            numcaptura = sprintf("capture%03d",((@page*4)+i))
            file_pattern = File.join(ALBUM_DIR, "#{numcaptura}*.png")
            # Buscamos el archivo que se llame así.
            matching_files = Dir.glob(file_pattern)
            if !matching_files.empty?
                first_matching_file = matching_files.first
                @sprites["captura#{i+1}"].setBitmap(first_matching_file)
                @sprites["captura#{i+1}"].zoom_x = 0.354
                @sprites["captura#{i+1}"].zoom_y = 0.354
            else
                echoln "No se encontró ningún archivo que coincida con el patrón #{file_pattern}"
            end
		end
		escribirTextos
	end
	
	def retrocederPagina
		#Movemos el cursor
		@sprites["seleccion"].x=CURSORDCHAX
		@photo+=1
		
        if @page == 0
            @page = (@numpages-1)
        else
            @page-=1
        end

        # Limpiar todos los sprites de capturas antes de cargar las nuevas
        for i in 0...4
            @sprites["captura#{i+1}"].setBitmap(nil)
        end

		for i in 0...4
            numcaptura = sprintf("capture%03d",((@page*4)+i))
            file_pattern = File.join(ALBUM_DIR, "#{numcaptura}*.png")
            # Buscamos el archivo que se llame así.
            matching_files = Dir.glob(file_pattern)
            if !matching_files.empty?
                first_matching_file = matching_files.first
                @sprites["captura#{i+1}"].setBitmap(first_matching_file)
                @sprites["captura#{i+1}"].zoom_x = 0.354
                @sprites["captura#{i+1}"].zoom_y = 0.354
            else
                echoln "No se encontró ningún archivo que coincida con el patrón #{file_pattern}"
            end
		end    
		escribirTextos
	end

	def pbEndScene
		@overlay.bitmap.clear
		pbFadeOutAndHide(@sprites)
		@overlay.dispose
		@viewport.dispose
		pbDisposeSpriteHash(@sprites)
	end	
end

def pbAbrirAlbum
	scene=AlbumFotos_Scene.new
	screen=AlbumFotos.new(scene)
	screen.pbStartScreen
end

class AlbumFotos
  def initialize(scene)
    @scene=scene
  end
 
  def pbStartScreen
	pbFadeOutIn(99999){
		@scene.pbStartScene
		@scene.pbEndScene
	}
  end
end

def copiar_fotos_de_carpeta_sistema_a_juego
    return if $joiplay
    # Define las rutas de origen y destino
    appdata_folder = File.join(System.data_directory, "Fotos/")
    game_folder = File.join(Dir.pwd, 'Fotos')

    # Crea el directorio de destino si no existe
    Dir.mkdir(game_folder) unless Dir.exist?(game_folder)

    # Verifica que la carpeta de origen exista
    unless Dir.exist?(appdata_folder)
        echoln "La carpeta de origen no existe: #{appdata_folder}"
        return
    end

    # Copia todos los archivos del directorio de origen al directorio de destino
    Dir.foreach(appdata_folder) do |file|
        next if file == '.' or file == '..'
        
        # Define la ruta del archivo de origen y destino
        src_file = File.join(appdata_folder, file)
        dest_file = File.join(game_folder, file)

        # Solo copia si el archivo no existe o es más reciente
        if File.file?(src_file) && (!File.exist?(dest_file) || File.mtime(src_file) > File.mtime(dest_file))
            File.open(src_file, 'rb') do |source|
                File.open(dest_file, 'wb') do |destination|
                    IO.copy_stream(source, destination)
                end
            end
            echoln "Archivo copiado: #{File.basename(dest_file)}"
        end
    end
    echoln "Copia completada."
end

# ITEMS EXTRA
ItemHandlers::UseInField.add(:ALBUMFOTOS, proc { |item|
  pbAbrirAlbum
  next true
})

ItemHandlers::UseFromBag.add(:ALBUMFOTOS, proc { |item|
  pbAbrirAlbum
  next 1
})
#==============================================================================
# * PokemonControls_Scene / Scene_Controls para Nintendo Switch
#------------------------------------------------------------------------------
# Interfaz visual premium con esquema del mando de Nintendo Switch (Joy-Cons),
# probador de botones en vivo con feedback luminoso, doble pulsación de B
# para salir, atajos de aventura y menú de configuración en caliente.
#==============================================================================

class PokemonControls_Scene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    
    # 1. Fondo estático elegante con degradado oscuro de alta fidelidad
    @sprites["background"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    bg = @sprites["background"].bitmap
    for y in 0...Graphics.height
      ratio = y.to_f / Graphics.height
      r = (12 + ratio * 14).to_i
      g = (16 + ratio * 18).to_i
      b = (28 + ratio * 28).to_i
      bg.fill_rect(0, y, Graphics.width, 1, Color.new(r, g, b))
    end
    
    # 2. Overlay estático para textos y paneles de información
    @sprites["static_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @static_overlay = @sprites["static_overlay"].bitmap
    pbSetSystemFont(@static_overlay)
    
    # 3. Overlay dinámico de 60 FPS para el probador de botones del mando y avisos
    @sprites["live_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @live_overlay = @sprites["live_overlay"].bitmap
    pbSetSystemFont(@live_overlay)
    
    @current_tab = 0 # 0: Mando y Aventura, 1: Menú y Combate, 2: Ajustes de Botones
    @cfg_index = 0   # Opción seleccionada en Ajustes
    @b_press_timer = 0 # Contador para doble pulsación de B
    @pulse_frame = 0
    
    @tabs = [
      _INTL("Mando Switch"),
      _INTL("Menú y Combate"),
      _INTL("Ajustes de Botones")
    ]
    
    redraw_static_elements
  end

  def pbEndScene
    @sprites.each_value { |s| s.dispose if s && !s.disposed? }
    @sprites.clear
    @viewport.dispose
  end

  # Redibuja los elementos fijos al cambiar de pestaña
  def redraw_static_elements
    @static_overlay.clear
    draw_header
    case @current_tab
    when 0
      draw_controller_base
      draw_adventure_labels
    when 1
      draw_tab_menu_and_battle
    when 2
      draw_tab_settings
    end
    draw_footer_base
  end

  # Barra superior de navegación con pestañas
  def draw_header
    @static_overlay.fill_rect(0, 0, Graphics.width, 38, Color.new(18, 24, 38, 240))
    @static_overlay.fill_rect(0, 37, Graphics.width, 2, Color.new(0, 160, 240, 255))
    
    tab_w = Graphics.width / @tabs.length
    @tabs.each_with_index do |name, idx|
      is_sel = (idx == @current_tab)
      tx = idx * tab_w
      if is_sel
        @static_overlay.fill_rect(tx + 6, 4, tab_w - 12, 30, Color.new(28, 64, 128, 220))
        @static_overlay.fill_rect(tx + 6, 33, tab_w - 12, 3, Color.new(0, 200, 255, 255))
      end
      @static_overlay.font.size = 17
      @static_overlay.font.bold = is_sel
      color = is_sel ? Color.new(255, 255, 255) : Color.new(150, 175, 210)
      @static_overlay.font.color = color
      @static_overlay.draw_text(tx, 7, tab_w, 24, name, 1)
    end
    
    @static_overlay.font.size = 15
    @static_overlay.font.bold = true
    @static_overlay.font.color = Color.new(0, 200, 255)
    @static_overlay.draw_text(10, 7, 34, 24, "[L]", 0)
    @static_overlay.draw_text(Graphics.width - 44, 7, 34, 24, "[R]", 2)
  end

  # Dibujo estático de la Nintendo Switch (chasis y pantalla)
  def draw_controller_base
    sw_x = 120
    sw_y = 44
    sw_w = 272
    sw_h = 138
    jc_w = 46
    
    # Sombra del chasis
    @static_overlay.fill_rect(sw_x - 2, sw_y - 2, sw_w + 4, sw_h + 4, Color.new(8, 12, 18, 180))
    
    # Joy-Con Izquierdo (Azul Neón)
    @static_overlay.fill_rect(sw_x, sw_y, jc_w, sw_h, Color.new(0, 160, 235))
    @static_overlay.fill_rect(sw_x, sw_y, 4, sw_h, Color.new(0, 120, 190)) # Borde izquierdo curvado
    
    # Joy-Con Derecho (Rojo Neón)
    @static_overlay.fill_rect(sw_x + sw_w - jc_w, sw_y, jc_w, sw_h, Color.new(255, 60, 70))
    @static_overlay.fill_rect(sw_x + sw_w - 4, sw_y, 4, sw_h, Color.new(200, 30, 40)) # Borde derecho
    
    # Pantalla central (Consola Negra)
    scr_x = sw_x + jc_w
    scr_w = sw_w - jc_w * 2
    @static_overlay.fill_rect(scr_x, sw_y, scr_w, sw_h, Color.new(22, 26, 34))
    @static_overlay.fill_rect(scr_x + 6, sw_y + 8, scr_w - 12, sw_h - 16, Color.new(10, 14, 20))
    @static_overlay.fill_rect(scr_x + 8, sw_y + 10, scr_w - 16, sw_h - 20, Color.new(16, 24, 42))
    
    # Logotipo estilizado en pantalla de la Switch
    @static_overlay.font.size = 15
    @static_overlay.font.bold = true
    @static_overlay.font.color = Color.new(80, 160, 255)
    @static_overlay.draw_text(scr_x, sw_y + 42, scr_w, 22, "POKÉMON AÑIL 4.0", 1)
    @static_overlay.font.size = 12
    @static_overlay.font.bold = false
    @static_overlay.font.color = Color.new(140, 180, 230)
    @static_overlay.draw_text(scr_x, sw_y + 66, scr_w, 18, "Nintendo Switch Edition", 1)
    
    # Indicador de probador en pantalla de la consola
    @static_overlay.font.size = 11
    @static_overlay.font.color = Color.new(100, 220, 140)
    @static_overlay.draw_text(scr_x, sw_y + 94, scr_w, 16, "● TESTER ACTIVO", 1)
  end

  # Tarjetas explicativas de controles de aventura en Tab 0
  def draw_adventure_labels
    @static_overlay.fill_rect(16, 188, Graphics.width - 32, 154, Color.new(16, 22, 34, 220))
    @static_overlay.fill_rect(16, 188, Graphics.width - 32, 2, Color.new(0, 140, 220, 200))
    
    layout_name = ($PokemonSystem&.button_layout == 1) ? _INTL("[PC/Xbox]") : _INTL("[Nintendo]")
    
    left_items = [
      [_INTL("Botón A:"), _INTL("Confirmar / Hablar / Interactuar {1}", layout_name)],
      [_INTL("Botón B:"), _INTL("Cancelar / Volver / Mantener para Correr")],
      [_INTL("Botón X:"), _INTL("Abrir Menú de Pausa principal")],
      [_INTL("Botón Y:"), _INTL("Acceso a Objetos Clave registrados")],
      [_INTL("Stick / D-Pad:"), _INTL("Desplazarse en 4 u 8 direcciones")]
    ]
    
    right_items = [
      [_INTL("Botón L:"), _INTL("Alternar Modo Turbo (Velocidad de juego)")],
      [_INTL("Botón R:"), _INTL("Repelente Infinito (en Menú de Pausa)")],
      [_INTL("Botón ZL:"), _INTL("Atajo rápido de Pokémontura (Volar)")],
      [_INTL("Gatillo ZR:"), _INTL("Atajo Pokéradar (en Menú de Pausa)")],
      [_INTL("Botón (+):"), _INTL("Guardado Rápido automático")]
    ]
    
    sy = 194
    gap = 26
    left_items.each_with_index do |(lbl, desc), i|
      @static_overlay.font.size = 14
      @static_overlay.font.bold = true
      @static_overlay.font.color = Color.new(255, 215, 80)
      @static_overlay.draw_text(24, sy + i * gap, 90, 22, lbl, 0)
      @static_overlay.font.bold = false
      @static_overlay.font.color = Color.new(235, 242, 255)
      @static_overlay.draw_text(115, sy + i * gap, 155, 22, desc, 0)
    end
    
    right_items.each_with_index do |(lbl, desc), i|
      @static_overlay.font.size = 14
      @static_overlay.font.bold = true
      @static_overlay.font.color = Color.new(100, 210, 255)
      @static_overlay.draw_text(278, sy + i * gap, 90, 22, lbl, 0)
      @static_overlay.font.bold = false
      @static_overlay.font.color = Color.new(235, 242, 255)
      @static_overlay.draw_text(370, sy + i * gap, 130, 22, desc, 0)
    end
  end

  # Dibuja los botones dinámicos en vivo sobre la consola Switch (Tab 0)
  def draw_live_controller_tester
    @live_overlay.clear
    return if @current_tab != 0
    
    sw_x = 120
    sw_y = 44
    sw_w = 272
    jc_w = 46
    
    # Comprobación de pulsaciones físicas
    btn_a = Input.press?(Input::USE) rescue false
    btn_b = Input.press?(Input::BACK) || (@b_press_timer > 0) rescue false
    btn_x = Input.press?(Input::ACTION) rescue false
    btn_y = Input.press?(Input::JUMPUP) rescue false
    btn_l = (defined?(Input::Controller) && Input::Controller.pressex?(:LEFTSHOULDER)) || (Input.press?(Input::L) rescue false)
    btn_r = (defined?(Input::Controller) && Input::Controller.pressex?(:RIGHTSHOULDER)) || (Input.press?(Input::R) rescue false)
    btn_minus = (defined?(Input::Controller) && Input::Controller.pressex?(:BACK)) || (Input.press?(Input::SPECIAL) rescue false)
    btn_plus  = (defined?(Input::Controller) && Input::Controller.pressex?(:START)) rescue false
    btn_up    = Input.press?(Input::UP) rescue false
    btn_down  = Input.press?(Input::DOWN) rescue false
    btn_left  = Input.press?(Input::LEFT) rescue false
    btn_right = Input.press?(Input::RIGHT) rescue false
    
    # Gatillos superiores L y R
    @live_overlay.fill_rect(sw_x, sw_y - 6, jc_w, 6, btn_l ? Color.new(255, 255, 255) : Color.new(0, 100, 170))
    @live_overlay.fill_rect(sw_x + sw_w - jc_w, sw_y - 6, jc_w, 6, btn_r ? Color.new(255, 255, 255) : Color.new(180, 25, 35))
    
    # Botón Minus (-)
    m_col = btn_minus ? Color.new(255, 255, 255) : Color.new(25, 30, 42)
    @live_overlay.fill_rect(sw_x + jc_w - 14, sw_y + 12, 9, 3, m_col)
    
    # Stick Izquierdo (con feedback direccional)
    stk_x = sw_x + 14 + (btn_right ? 2 : (btn_left ? -2 : 0))
    stk_y = sw_y + 26 + (btn_down ? 2 : (btn_up ? -2 : 0))
    @live_overlay.fill_rect(stk_x, stk_y, 20, 20, Color.new(45, 52, 68))
    @live_overlay.fill_rect(stk_x + 3, stk_y + 3, 14, 14, (btn_up || btn_down || btn_left || btn_right) ? Color.new(255, 255, 255) : Color.new(75, 86, 110))
    
    # Cruceta Direccional D-Pad
    d_cx = sw_x + 24
    d_cy = sw_y + 80
    draw_dpad_button(d_cx - 5, d_cy - 16, 10, 10, btn_up)
    draw_dpad_button(d_cx - 5, d_cy + 6, 10, 10, btn_down)
    draw_dpad_button(d_cx - 16, d_cy - 5, 10, 10, btn_left)
    draw_dpad_button(d_cx + 6, d_cy - 5, 10, 10, btn_right)
    
    # Botón Plus (+)
    p_col = btn_plus ? Color.new(255, 255, 255) : Color.new(25, 30, 42)
    @live_overlay.fill_rect(sw_x + sw_w - jc_w + 6, sw_y + 10, 9, 9, p_col)
    @live_overlay.fill_rect(sw_x + sw_w - jc_w + 9, sw_y + 7, 3, 15, p_col)
    
    # Botones Frontales (X, Y, A, B)
    f_cx = sw_x + sw_w - jc_w + 23
    f_cy = sw_y + 36
    draw_face_button(f_cx, f_cy - 14, "X", btn_x, Color.new(0, 195, 255))
    draw_face_button(f_cx - 14, f_cy, "Y", btn_y, Color.new(100, 230, 100))
    draw_face_button(f_cx + 14, f_cy, "A", btn_a, Color.new(255, 65, 75))
    draw_face_button(f_cx, f_cy + 14, "B", btn_b, Color.new(255, 215, 0))
    
    # Stick Derecho
    @live_overlay.fill_rect(sw_x + sw_w - 33, sw_y + 75, 20, 20, Color.new(45, 52, 68))
    @live_overlay.fill_rect(sw_x + sw_w - 30, sw_y + 78, 14, 14, Color.new(75, 86, 110))
    
    # Banner dinámico de salida con doble pulsación de B
    draw_footer_dynamic
  end

  def draw_face_button(x, y, label, is_pressed, base_col)
    if is_pressed
      # Halo luminoso activo
      @live_overlay.fill_rect(x - 8, y - 8, 16, 16, Color.new(255, 255, 255, 180))
      @live_overlay.fill_rect(x - 6, y - 6, 12, 12, Color.new(255, 255, 255))
      txt_col = Color.new(20, 25, 35)
    else
      @live_overlay.fill_rect(x - 6, y - 6, 12, 12, Color.new(35, 40, 52))
      txt_col = base_col
    end
    @live_overlay.font.size = 11
    @live_overlay.font.bold = true
    @live_overlay.font.color = txt_col
    @live_overlay.draw_text(x - 6, y - 7, 12, 12, label, 1)
  end

  def draw_dpad_button(x, y, w, h, is_pressed)
    bg = is_pressed ? Color.new(0, 220, 255) : Color.new(30, 36, 48)
    @live_overlay.fill_rect(x, y, w, h, bg)
  end

  # Pestaña 1: Menú y Combate
  def draw_tab_menu_and_battle
    @static_overlay.fill_rect(16, 48, Graphics.width - 32, 294, Color.new(16, 22, 34, 225))
    @static_overlay.fill_rect(16, 48, Graphics.width - 32, 2, Color.new(0, 140, 220, 220))
    
    @static_overlay.font.size = 17
    @static_overlay.font.bold = true
    @static_overlay.font.color = Color.new(255, 215, 80)
    @static_overlay.draw_text(32, 56, 450, 22, "ATAJOS EXCLUSIVOS DEL MENÚ DE PAUSA", 0)
    
    menu_shortcuts = [
      ["[ZL] Pokémontura:", "Vuelo instantáneo con Pokérider a cualquier ciudad visitada."],
      ["[Y] Pokévial:", "Cura y restaura al 100% la salud y PP de todo tu equipo al instante."],
      ["[ZR] Pokéradar:", "Escanea y localiza especies salvajes y formas de la ruta."],
      ["[R] Repelente Infinito:", "Activa o desactiva el repelente ilimitado para avanzar sin cortes."],
      ["[-] / Menú Controles:", "Abre esta pantalla explicativa y de configuración de botones."]
    ]
    
    my = 82
    menu_shortcuts.each do |btn, desc|
      @static_overlay.font.size = 14
      @static_overlay.font.bold = true
      @static_overlay.font.color = Color.new(90, 210, 255)
      @static_overlay.draw_text(36, my, 160, 20, btn, 0)
      @static_overlay.font.bold = false
      @static_overlay.font.color = Color.new(235, 242, 255)
      @static_overlay.draw_text(200, my, 280, 20, desc, 0)
      my += 23
    end
    
    @static_overlay.fill_rect(32, my + 6, Graphics.width - 64, 1, Color.new(50, 70, 100))
    my += 16
    
    @static_overlay.font.size = 17
    @static_overlay.font.bold = true
    @static_overlay.font.color = Color.new(255, 110, 110)
    @static_overlay.draw_text(32, my, 450, 22, "MANDOS DURANTE EL COMBATE", 0)
    my += 26
    
    battle_controls = [
      ["Botón A:", "Elegir movimiento, seleccionar Pokémon o confirmar acción."],
      ["Botón B:", "Volver al menú de combate anterior o cancelar selección."],
      ["Botón X:", "Activar Megaevolución / Dinamax / Teracristalización."],
      ["Botón Y:", "Consultar datos del movimiento (Tipo, Potencia, Precisión, Efecto)."],
      ["Botón L:", "Acelerar la velocidad de las animaciones y diálogos (Turbo)."],
      ["Gatillo ZL:", "Atajo directo para lanzar Poké Ball en combate salvaje."]
    ]
    
    battle_controls.each do |btn, desc|
      @static_overlay.font.size = 14
      @static_overlay.font.bold = true
      @static_overlay.font.color = Color.new(255, 175, 175)
      @static_overlay.draw_text(36, my, 120, 20, btn, 0)
      @static_overlay.font.bold = false
      @static_overlay.font.color = Color.new(235, 242, 255)
      @static_overlay.draw_text(160, my, 320, 20, desc, 0)
      my += 23
    end
  end

  # Pestaña 2: Configuración y Remapeo de Botones
  def draw_tab_settings
    @static_overlay.fill_rect(16, 48, Graphics.width - 32, 294, Color.new(16, 22, 34, 225))
    @static_overlay.fill_rect(16, 48, Graphics.width - 32, 2, Color.new(0, 140, 220, 220))
    
    @static_overlay.font.size = 17
    @static_overlay.font.bold = true
    @static_overlay.font.color = Color.new(0, 210, 255)
    @static_overlay.draw_text(32, 56, 450, 22, "CONFIGURACIÓN PERSONALIZADA DE CONTROLES", 0)
    
    @static_overlay.font.size = 13
    @static_overlay.font.bold = false
    @static_overlay.font.color = Color.new(170, 190, 225)
    @static_overlay.draw_text(32, 78, 450, 18, "Cambia la asignación de botones a tu preferencia. Se guardan al instante.", 0)
    
    layout_val = ($PokemonSystem&.button_layout || 0) rescue 0
    turbo_val  = ($PokemonSystem&.turbo_button || 0) rescue 0
    plus_val   = ($PokemonSystem&.plus_action || 0) rescue 0
    
    options = [
      [
        _INTL("Disposición Botones A / B"),
        (layout_val == 0) ? _INTL("Estilo Nintendo (A: Confirmar / B: Cancelar)") : _INTL("Estilo PC/Xbox (B: Confirmar / A: Cancelar)"),
        _INTL("Ajusta si confirmas con el botón derecho (A) o inferior (B).")
      ],
      [
        _INTL("Botón de Modo Turbo"),
        case turbo_val
        when 1 then _INTL("Botón R")
        when 2 then _INTL("Gatillo ZR")
        else _INTL("Botón L (Predeterminado)")
        end,
        _INTL("Selecciona qué botón físico cicla la velocidad de juego.")
      ],
      [
        _INTL("Acción Directa del Botón (+)"),
        case plus_val
        when 1 then _INTL("Abrir Mochila")
        when 2 then _INTL("Abrir Pokédex")
        else _INTL("Guardado Rápido (Quick Save)")
        end,
        _INTL("Asigna un atajo inmediato al presionar el botón + en el mapa.")
      ],
      [
        _INTL("Restablecer Configuración"),
        _INTL("[ Pulsar A para restablecer valores de fábrica ]"),
        _INTL("Devuelve todos los controles a la configuración oficial recomendada.")
      ]
    ]
    
    sy = 106
    options.each_with_index do |(title, val_text, hint), idx|
      is_sel = (idx == @cfg_index)
      if is_sel
        @static_overlay.fill_rect(26, sy - 2, Graphics.width - 52, 48, Color.new(35, 75, 145, 200))
        @static_overlay.fill_rect(26, sy - 2, 4, 48, Color.new(255, 215, 60))
      end
      
      @static_overlay.font.size = 15
      @static_overlay.font.bold = true
      @static_overlay.font.color = is_sel ? Color.new(255, 255, 255) : Color.new(215, 230, 250)
      @static_overlay.draw_text(36, sy, 220, 22, title, 0)
      
      @static_overlay.font.size = 14
      @static_overlay.font.bold = is_sel
      @static_overlay.font.color = is_sel ? Color.new(255, 220, 80) : Color.new(140, 195, 255)
      @static_overlay.draw_text(240, sy, Graphics.width - 275, 22, val_text, 2)
      
      @static_overlay.font.size = 12
      @static_overlay.font.bold = false
      @static_overlay.font.color = Color.new(160, 185, 215)
      @static_overlay.draw_text(36, sy + 22, Graphics.width - 72, 18, hint, 0)
      
      sy += 52
    end
  end

  def draw_footer_base
    fy = Graphics.height - 34
    @static_overlay.fill_rect(0, fy, Graphics.width, 34, Color.new(14, 20, 32, 245))
    @static_overlay.fill_rect(0, fy, Graphics.width, 1, Color.new(35, 50, 80))
  end

  def draw_footer_dynamic
    fy = Graphics.height - 34
    
    if @current_tab == 2
      @live_overlay.font.size = 14
      @live_overlay.font.bold = false
      @live_overlay.font.color = Color.new(160, 190, 230)
      @live_overlay.draw_text(16, fy + 7, 340, 20, _INTL("Cruceta / Stick: Elegir   |   A / Izq / Der: Cambiar"), 0)
      @live_overlay.font.bold = true
      @live_overlay.font.color = Color.new(255, 215, 90)
      @live_overlay.draw_text(Graphics.width - 150, fy + 7, 134, 20, _INTL("(B) Salir"), 2)
    else
      if @b_press_timer > 0
        # Banner pulsante de aviso para doble toque
        pulse = (@b_press_timer % 20 < 10)
        pill_col = pulse ? Color.new(200, 50, 40, 230) : Color.new(240, 80, 50, 230)
        @live_overlay.fill_rect(16, fy + 4, 260, 26, pill_col)
        @live_overlay.font.size = 13
        @live_overlay.font.bold = true
        @live_overlay.font.color = Color.new(255, 255, 255)
        @live_overlay.draw_text(20, fy + 7, 252, 20, _INTL("⚠ Pulsa B de nuevo para salir"), 1)
      else
        @live_overlay.font.size = 13
        @live_overlay.font.bold = false
        @live_overlay.font.color = Color.new(160, 190, 230)
        @live_overlay.draw_text(16, fy + 7, 340, 20, _INTL("Pulsa botones en tu Switch para probarlos en pantalla"), 0)
      end
      
      @live_overlay.font.size = 13
      @live_overlay.font.bold = true
      @live_overlay.font.color = Color.new(255, 215, 90)
      @live_overlay.draw_text(Graphics.width - 160, fy + 7, 144, 20, _INTL("(B) Doble toque Salir"), 2)
    end
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      
      @pulse_frame += 1
      @b_press_timer -= 1 if @b_press_timer > 0
      
      # Navegación entre pestañas con L y R
      if Input.trigger?(Input::L) || (defined?(Input::Controller) && Input::Controller.triggerex?(:LEFTSHOULDER))
        pbPlayCursorSE
        @current_tab = (@current_tab - 1) % @tabs.length
        @b_press_timer = 0
        redraw_static_elements
      elsif Input.trigger?(Input::R) || (defined?(Input::Controller) && Input::Controller.triggerex?(:RIGHTSHOULDER))
        pbPlayCursorSE
        @current_tab = (@current_tab + 1) % @tabs.length
        @b_press_timer = 0
        redraw_static_elements
      end
      
      # Salida inmediata con botón (-) Minus o (+) Plus desde cualquier pestaña
      if (defined?(Input::Controller) && (Input::Controller.triggerex?(:BACK) || Input::Controller.triggerex?(:START)))
        pbPlayCloseMenuSE
        break
      end
      
      # Gestión del botón B
      if Input.trigger?(Input::BACK)
        if @current_tab == 0
          if @b_press_timer > 0
            # Segunda pulsación en ventana de tiempo: salir limpiamente
            pbPlayCloseMenuSE
            break
          else
            # Primera pulsación: marcar botón en pantalla y armar temporizador de salida
            @b_press_timer = 90 # 1.5 segundos a 60 FPS
            pbPlayDecisionSE
          end
        else
          # En otras pestañas, salir o volver a Tab 0
          pbPlayCloseMenuSE
          break
        end
      end
      
      # En la pestaña de configuración de botones:
      if @current_tab == 2
        if Input.trigger?(Input::UP)
          pbPlayCursorSE
          @cfg_index = (@cfg_index - 1) % 4
          redraw_static_elements
        elsif Input.trigger?(Input::DOWN)
          pbPlayCursorSE
          @cfg_index = (@cfg_index + 1) % 4
          redraw_static_elements
        elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT) || Input.trigger?(Input::USE)
          handle_setting_change
        end
      end
      
      # Actualizar overlay dinámico en cada fotograma
      draw_live_controller_tester
    end
  end

  def handle_setting_change
    $PokemonSystem ||= PokemonSystem.new rescue nil
    case @cfg_index
    when 0 # Disposición A / B
      cur = ($PokemonSystem&.button_layout || 0) rescue 0
      new_val = (cur == 0) ? 1 : 0
      $PokemonSystem.button_layout = new_val if $PokemonSystem.respond_to?(:button_layout=)
      pbPlayDecisionSE
      redraw_static_elements
    when 1 # Botón Turbo
      cur = ($PokemonSystem&.turbo_button || 0) rescue 0
      new_val = (cur + 1) % 3
      $PokemonSystem.turbo_button = new_val if $PokemonSystem.respond_to?(:turbo_button=)
      pbPlayDecisionSE
      redraw_static_elements
    when 2 # Función Botón +
      cur = ($PokemonSystem&.plus_action || 0) rescue 0
      new_val = (cur + 1) % 3
      $PokemonSystem.plus_action = new_val if $PokemonSystem.respond_to?(:plus_action=)
      pbPlayDecisionSE
      redraw_static_elements
    when 3 # Restablecer
      $PokemonSystem.button_layout = 0 if $PokemonSystem.respond_to?(:button_layout=)
      $PokemonSystem.turbo_button  = 0 if $PokemonSystem.respond_to?(:turbo_button=)
      $PokemonSystem.plus_action   = 0 if $PokemonSystem.respond_to?(:plus_action=)
      pbPlayDecisionSE
      redraw_static_elements
      pbMessage(_INTL("Se ha restaurado la configuración oficial predeterminada de Nintendo Switch."))
      redraw_static_elements
    end
  end
end

class PokemonControlsScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbMain
    @scene.pbEndScene
  end
end

# Envoltura de compatibilidad hacia atrás
class ButtonEventScene
  def initialize(viewport = nil)
    scene = PokemonControls_Scene.new
    screen = PokemonControlsScreen.new(scene)
    screen.pbStartScreen
  end
end

def pbOpenControlsScreen
  pbFadeOutIn do
    scene = PokemonControls_Scene.new
    screen = PokemonControlsScreen.new(scene)
    screen.pbStartScreen
  end
end



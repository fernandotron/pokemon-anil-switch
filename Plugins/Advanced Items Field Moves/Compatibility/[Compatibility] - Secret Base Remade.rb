if PluginManager.installed?("Secret Bases Remade")

#Secret Base
module AdvancedItemsFieldMoves
# Custom
  SECRETBASE_CONFIG = {
    #===================[Item Config]===================#
      :internal_name                    => :SECRETPOWERITEM,         # :ICESMASHITEM
      :item                             => true,                  # Default: true
      :item_needed_badge                => 0,                     # Default: 0
      :item_needed_switches             => [],                    # Default: []
      :allow_item_debug                 => false,                 # Default: false
    #===================[Move Config]===================#
      :move_name                        => [:SECRETPOWER],              # :EMBER
      :move                             => true,                  # Default: true
      :uses_pp                          => false,                 # Default: false
      :move_needed_badge                => 0,                     # Default: 0
      :move_needed_switches             => [],                    # Default: []
      :allow_move_debug                 => false,                 # Default: false
    #===================[Text Config]===================#                       [\\c[1] is color change in the text\\c[0]]
    #===[Item Text]===#
        :text_item_badge                => _INTL("Medalla"),
        :text_item_comfirm              => _INTL("¿Quieres usar el \\c[1]{2}\\c[0]?"), # {2} = Item

    #===[Move Text]===#
        :text_move_badge                => _INTL("Medalla"),                #
        :text_move_confirm              => _INTL("¿Quieres usar \\c[1]{2}\\c[0]?"), # {2} = Move
        :text_move_confirm_plus         => _INTL("¿Qué movimiento quieres usar?"),
        #[Missing PP]
        :missing_PP                     => _INTL("No tienes suficientes \\c[1]PP\\c[0]..."),

    #===[Interact Failed Text]===#
        #[Missing Item and Move] if Both are Enable
        :missing_element_both           => _INTL("Tal vez algo podría crear una base secreta aquí"), # {2} = item name, {3} = move name (first if mulitple choice)

        #[IDLE] if Both are Disable
        :both_disable                   => _INTL("Nada creará una base secreta aquí"), # {2} = item name, {3} = move name (first if mulitple choice)

        #[Missing Item] if Item is Enable and Move is Disable
        :missing_element_item           => _INTL("Tal vez el \\c[1]{2}\\c[0] podía crear una base secreta aquí"), # {2} = item_name
        #[Player has Item - Missing Bagde] - {2} = number of badges
        :missing_bagde_item             => _INTL("Necesitas al menos \\c[1]{2} {3}\\c[0],\npara usar el \\c[1]{4}\\c[0]"), # {2} = badge count, {3} = badge reference, {4} = item name

        #[Missing Move] if Move is Enable and Item is Disable
        :missing_element_move           => _INTL("Tal vez el \\c[1]{2}\\c[0] podía crear una base secreta aquí"), # {2} = move name (first if mulitple choice)
        #[Pokémon have Move - Missing Bagde]
        :missing_bagde_move             => _INTL("Necesitas al menos \\c[1]{2} {3}\\c[0],\npara usar el \\c[1]{4}\\c[0]"), # {2} = badge count, {3} = badge reference, {4} = move name (first if mulitple choice)
  }
end

AIFM_SecretBase     = Show_SecretBase     = AdvancedItemsFieldMoves::SECRETBASE_CONFIG

def pbNewSecretBase(base_id)
  config_name = AIFM_SecretBase
  item = config_name[:internal_name]
  item_name = GameData::Item.get(item).name
  move_basic = config_name[:move_name]
  pp_check = config_name[:uses_pp]

  base_data = GameData::SecretBase.get(base_id)
  template_data = GameData::SecretBaseTemplate.get(base_data.map_template)
  messages_anim = SecretBaseSettings::SECRET_BASE_MESSAGES_ANIM[template_data.type]

  player_base = $PokemonGlobal.secret_base_list[0]
  moved_bases = false
  if player_base.id && player_base.id != base_id
    # semi-redundant check, but if the player has a base at all (id is not nil), and it's not this one.
    map_name = pbGetMapNameFromId(GameData::SecretBase.get(player_base.id).location[0])
    pbMessage(_INTL("Solo puedes crear 1 base secreta.\\1"))
    if pbConfirmMessage(_INTL("¿Quieres mudarte de la Base Secreta cerca de {1}?",map_name))
      pbMessage(_INTL("Todos las decoraciones y muebles en tu Base Secreta serán devueltos al PC.\\1"))
      if pbConfirmMessage(_INTL("¿Quieres continuar?"))
        # Pack up the base.
        pbFadeOutIn {
          player_base.remove_decorations((0...SecretBaseSettings::SECRET_BASE_MAX_DECORATIONS).to_a)
          $secret_bag.unplace_all
          player_base.id = nil
        }
        pbMessage(_INTL("Mudanza terminada.\\1"))
        $stats.moved_secret_base_count+=1
        moved_bases = true
      else
        return
      end
    else
      return
    end
  end
  if !moved_bases
    pbMessage(sprintf("%s\\1",_INTL(messages_anim[0])))
  end

  if pbCanUseItem(config_name) && config_name[:item]
    if pbConfirmMessage(_INTL("{1}", config_name[:text_item_comfirm], item_name))
      pbCallItemAnimation(config_name)
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", $player.name, item_name))

      _, x, y = pbFacingTile
      spriteset = $scene.spriteset($game_map.map_id)
      sprite = spriteset&.addUserAnimation(messages_anim[2], x, y, true, 1)
      SecretBaseMethods.animate_base_opening(base_id, sprite,messages_anim[2],messages_anim[3])
      pbMessage(_INTL(messages_anim[1]))
      pbSEPlay("Door Exit", 80, 100)
      dx,dy = template_data.door_location
      pbFadeOutIn(99999){
        $game_temp.player_transferring   = true
        $game_temp.transition_processing = true
        $game_temp.player_new_map_id    = SecretBaseSettings::SECRET_BASE_MAP
        $game_temp.player_new_x         = dx
        $game_temp.player_new_y         = dy-1
        $game_temp.player_new_direction = 8
        $scene.transfer_player
      }
      move_route=[]
      template_data.preview_steps.times do
        move_route.push(PBMoveRoute::UP)
      end
      pbMoveRoute($game_player,move_route)
      loop do
        Graphics.update
        Input.update
        pbUpdateSceneMap
        break unless $game_player.move_route_forcing
      end
      if !pbConfirmMessage(_INTL("¿Quieres crear una Base Secreta aquí?"))
        pbFadeOutIn(99999){
          $game_temp.player_transferring   = true
          $game_temp.transition_processing = true
          $game_temp.player_new_map_id    = base_data.location[0]
          $game_temp.player_new_x         = base_data.location[1]
          $game_temp.player_new_y         = base_data.location[2]+1
          $game_temp.player_new_direction = 2
          $scene.transfer_player
        }
      else
        px,py = template_data.pc_location
        pbFadeOutIn(99999){
          $PokemonMap.current_base_id = base_id
          player_base.id = base_id
          $game_temp.player_transferring   = true
          $game_temp.transition_processing = true
          $game_temp.player_new_map_id    = SecretBaseSettings::SECRET_BASE_MAP
          $game_temp.player_new_x         = px
          $game_temp.player_new_y         = py+1
          $game_temp.player_new_direction = 8
          $scene.transfer_player
        }
      end

      return true
    end
    return false
    # Check if the player can use the required move
  elsif config_name[:move]
    moves = []
    pkmn, moves_and_pp = pbCheckForMove(config_name)
    if pkmn
      moves_and_pp.each do |pkmn, move_data|
        move_data.each do |move_id, pp|
          next unless move_id
          move_name = GameData::Move.get(move_id).name
          max_pp = GameData::Move.get(move_id).total_pp
          moves.push([move_id, move_name, $player.party.index(pkmn), { pp: pp, max_pp: max_pp }])
        end
      end
      if pbCanUseMove(config_name)
        # If there are multiple moves, use SelectMoveMenu
        if moves.length > 1 && $PokemonSystem.hidden_moves_option == 0
          pbMessage(_INTL("{1}", config_name[:text_move_confirm_plus]))
          # Call pbSelectMoveMenu and store the result in selected_move
          selected_pokemon, selected_move = pbSelectMoveMenu(moves, pp_check)
          # If no move is selected, return false
          return false unless selected_move
          # Extract the Pokémon and move ID from selected_move
          pkmn = selected_pokemon
          move_id = selected_move
          move_name = GameData::Move.get(move_id).name
        else
          # Handle the case where there is only one move available
          pkmn = pkmn.first if moves.length > 1 && $PokemonSystem.hidden_moves_option == 1
          move_id = moves.first[0]
          move_name = GameData::Move.get(move_id).name
          return false unless pbConfirmMessage(_INTL("{1}", config_name[:text_move_confirm], move_name))
        end
        pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pkmn.name, move_name))

        pbCallMoveAnimation(pkmn)
        move = pkmn.moves.find { |m| m.id == move_id}
        move.pp -= 1 if pp_check && move

        _, x, y = pbFacingTile
        spriteset = $scene.spriteset($game_map.map_id)
        sprite = spriteset&.addUserAnimation(messages_anim[2], x, y, true, 1)
        SecretBaseMethods.animate_base_opening(base_id, sprite,messages_anim[2],messages_anim[3])
        pbMessage(_INTL(messages_anim[1]))
        pbSEPlay("Door Exit", 80, 100)
        dx,dy = template_data.door_location
        pbFadeOutIn(99999){
          $game_temp.player_transferring   = true
          $game_temp.transition_processing = true
          $game_temp.player_new_map_id    = SecretBaseSettings::SECRET_BASE_MAP
          $game_temp.player_new_x         = dx
          $game_temp.player_new_y         = dy-1
          $game_temp.player_new_direction = 8
          $scene.transfer_player
        }
        move_route=[]
        template_data.preview_steps.times do
          move_route.push(PBMoveRoute::UP)
        end
        pbMoveRoute($game_player,move_route)
        loop do
          Graphics.update
          Input.update
          pbUpdateSceneMap
          break unless $game_player.move_route_forcing
        end
        if !pbConfirmMessage(_INTL("¿Quieres crear una Base Secreta aquí?"))
          pbFadeOutIn(99999){
            $game_temp.player_transferring   = true
            $game_temp.transition_processing = true
            $game_temp.player_new_map_id    = base_data.location[0]
            $game_temp.player_new_x         = base_data.location[1]
            $game_temp.player_new_y         = base_data.location[2]+1
            $game_temp.player_new_direction = 2
            $scene.transfer_player
          }
        else
          px,py = template_data.pc_location
          pbFadeOutIn(99999){
            $PokemonMap.current_base_id = base_id
            player_base.id = base_id
            $game_temp.player_transferring   = true
            $game_temp.transition_processing = true
            $game_temp.player_new_map_id    = SecretBaseSettings::SECRET_BASE_MAP
            $game_temp.player_new_x         = px
            $game_temp.player_new_y         = py+1
            $game_temp.player_new_direction = 8
            $scene.transfer_player
          }
        end
        return true
      end
    end
  end
  move_id = ((moves.any? unless moves.nil?) ? moves.first[0] : move_basic[0])
  move_name = GameData::Move.get(move_id).name
  failMessage(config_name, item_name, move_name)
end




#===============================================================================
#
#================================[Event Handler]================================
EventHandlers.add(:on_player_interact, :secret_base_event,
  proc {
    next if $game_player.direction!=8 # must face up
    facingEvent = $game_player.pbFacingEvent
    if facingEvent && facingEvent.name[/SecretBase\((\w+)\)/]
      pbNewSecretBase($~[1].to_sym)
    end
  }
)

#================================[Item Handler]================================#
if AIFM_SecretBase[:item]
  ItemHandlers::UseFromBag.add(AIFM_SecretBase[:internal_name], proc do |item|
    config_name = AIFM_SecretBase
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_SecretBase[:internal_name], proc do |item|
    config_name = AIFM_SecretBase
    facingEvent = $game_player.pbFacingEvent
    item_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    item_name = GameData::Item.get(config_name[:internal_name]).name
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    if facingEvent && facingEvent.name[/SecretBase\((\w+)\)/]
      pbNewSecretBase($~[1].to_sym)
    end
    pbMessage(_INTL("¡No tiene sentido usar el \\c[0]{1}\\c[0] ahora!", item_name))
    next false
  end)
end

#================================[Move Handler]================================#
if AIFM_SecretBase[:move]
  AIFM_SecretBase[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_SecretBase
    move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
        next false
      end
      if $game_player.direction!=8
        pbMessage(_INTL("No puedes usar eso aquí")) if showmsg
        next false
      end
      facingEvent = $game_player.pbFacingEvent
      if !facingEvent || !facingEvent.name[/SecretBase\(\w+\)/]
        pbMessage(_INTL("No puedes usar eso aquí")) if showmsg
        next false
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      facingEvent = $game_player.pbFacingEvent
      if facingEvent && facingEvent.name[/SecretBase\((\w+)\)/]
        pbNewSecretBase($~[1].to_sym)
      end
    })
  end
end

end

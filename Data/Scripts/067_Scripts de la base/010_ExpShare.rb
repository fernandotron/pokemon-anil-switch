#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#                         Script : Repartir Exp 5.5                             #
#                             Selfish - Público                                 #
#                         Rescrito para Essentials 21 por DPertierra            #
#                         Remember to give Credits!				                #
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#                  Creado para RPG Maker XP con base Essentials                 #
#                          Compatible : versión 21.1                            #
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
if Settings::USE_NEW_EXP_SHARE
    class PokemonSystem
        attr_accessor :expshareon
        attr_accessor :repartir_exp
    end

    class PokemonGlobalMetadata
        attr_writer :expshare_enabled
        def expshare_enabled
            @expshare_enabled = (Settings::EXPSHARE_ENABLED rescue false) if @expshare_enabled.nil?
            @expshare_enabled
        end
        alias initialize_expshare initialize rescue nil
        def initialize
            initialize_expshare rescue nil
            @expshare_enabled = (Settings::EXPSHARE_ENABLED rescue false)
        end
    end


    MenuHandlers.add(:options_menu, :repartir_exp, {
        "name"        => _INTL("Repartir Exp."),
        "order"       => 42,
        "type"        => EnumOption,
        "parameters"  => [_INTL("Sí"), _INTL("No")],
        "description" => _INTL("Activa o desactiva la distribución de experiencia en todo el equipo."),
        "get_proc"    => proc { next ($PokemonSystem&.repartir_exp || 0) },
        "set_proc"    => proc { |value, _scene|
            if $PokemonSystem
                $PokemonSystem.repartir_exp = value
                if $player&.party
                    new_val = (value == 0)
                    $player.party.each { |pkmn| pkmn.expshare = new_val if pkmn.respond_to?(:expshare=) }
                end
            end
        }
    })



    MenuHandlers.add(:party_menu, :expshare, {
        "name"      => _INTL("Repartir Exp."),
        "order"     => 70,
        "condition" => proc { next expshare_enabled? },
        "effect"    => proc { |screen, party, party_idx|
            if $PokemonSystem&.repartir_exp == 1
                pbMessage(_INTL("El Repartir Experiencia global está desactivado en Opciones."))
                next
            end
            pokemon = party[party_idx]
            var_msg = pokemon.expshare ? _INTL("desactivar") : _INTL("activar")
            pokemon.expshare = !pokemon.expshare if pbConfirmMessage(_INTL("¿Quieres {1} el Repartir Experiencia en este Pokémon?", var_msg))
        }   
    })


    def expshare_enabled?
        return false unless defined?($PokemonGlobal) && $PokemonGlobal
        return false unless $PokemonGlobal.respond_to?(:expshare_enabled)
        return $PokemonGlobal.expshare_enabled ? true : false
    end

    def toggle_expshare
        return unless defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:expshare_enabled=)
        $PokemonGlobal.expshare_enabled = !$PokemonGlobal.expshare_enabled
        $player.party.each { |pokemon| pokemon.expshare = $PokemonGlobal.expshare_enabled } if $player&.party
    end
    
    class Pokemon
        attr_writer(:expshare)    # Repartir experiencia
        def expshare
            return false if $PokemonSystem&.repartir_exp == 1
            return @expshare.nil? ? true : @expshare
        end
        alias initialize_expshare initialize unless method_defined?(:initialize_expshare)
        def initialize(species, level, player = $player, withMoves = true, recheck_form = true)
            initialize_expshare(species, level, player, withMoves, recheck_form)
            @expshare = ($PokemonSystem&.repartir_exp != 1)
        end 
    end
    
    
    class PokemonPartyPanel < Sprite

        alias initialize_old initialize
        def initialize(pokemon,index,viewport=nil)
            initialize_old(pokemon,index,viewport)
            if @pokemon.expshare && !@pokemon.egg?
                @expicon = ChangelingSprite.new(0, 0, viewport)
                @expicon.add_bitmap(:expicon,"Graphics/Pictures/expicon")
                @expicon.z=self.z+3 # For compatibility with RGSS2
            end
        end


        alias refresh_overlay_information_old refresh_overlay_information
        def refresh_overlay_information
            refresh_overlay_information_old
            draw_exp_icon
        end

        def draw_exp_icon
            return if !@pokemon.expshare || @pokemon.egg?
            pbDrawImagePositions(@overlaysprite.bitmap, 
            [["Graphics/Pictures/expicon", 226, 70, 0, 0]])
        end

        def refresh_exp_icon
            return if !@expicon || @expicon.disposed?
            @expicon.visible = (@pokemon.expshare && !@pokemon.egg?)
            @expicon.x=self.x+226
            @expicon.y=self.y+68
            @expicon.color=self.color
        end

        def dispose
            @panelbgsprite.dispose
            @hpbgsprite.dispose
            @ballsprite.dispose
            @pkmnsprite.dispose
            @helditemsprite.dispose
            @overlaysprite.bitmap.dispose
            @overlaysprite.dispose
            @hpbar.dispose
            @statuses.dispose
            @expicon.dispose if @expicon
            super
        end
        
        def refresh
            return if disposed?
            return if @refreshing
            @refreshing = true
            refresh_panel_graphic
            refresh_hp_bar_graphic
            refresh_ball_graphic
            refresh_pokemon_icon
            refresh_held_item_icon
            refresh_exp_icon
            if @overlaysprite && !@overlaysprite.disposed?
            @overlaysprite.x     = self.x
            @overlaysprite.y     = self.y
            @overlaysprite.color = self.color
            end
            refresh_overlay_information
            @refreshBitmap = false
            @refreshing = false
        end

        alias update_old update
        def update
            update_old
            @expicon.update if @expicon 
        end
        
    end
    
    class Battle 
    ################################################################################
    # Experiencia en captura reducida
    ################################################################################
        def pbGainExp
            return if $game_switches[NO_EXP_SWITCH] # Switch para no ganar experiencia
            # Play wild victory music if it's the end of the battle (has to be here)
            @scene.pbWildBattleSuccess if wildBattle? && pbAllFainted?(1) && !pbAllFainted?(0)
            return if !@internalBattle || !@expGain
            # Go through each battler in turn to find the Pokémon that participated in
            # battle against it, and award those Pokémon Exp/EVs
            expAll = ($player.has_exp_all || $bag.has?(:EXPALL)) && ($PokemonSystem&.repartir_exp != 1) 
            p1 = pbParty(0)
            @battlers.each do |b|
            next unless b&.opposes?   # Can only gain Exp from fainted foes
            next if b.participants.length == 0
            next unless b.fainted? || b.captured
            # Count the number of participants
            numPartic = 0
            b.participants.each do |partic|
                next unless p1[partic]&.able? && pbIsOwner?(0, partic)
                numPartic += 1
            end
            # Find which Pokémon have an Exp Share
            expShare = []
            if !expAll
                eachInTeam(0, 0) do |pkmn, i|
                    next if !pkmn.able?
                    next if (!pkmn.hasItem?(:EXPSHARE) && GameData::Item.try_get(@initialItems[0][i]) != :EXPSHARE) && !pkmn.expshare
                    expShare.push(i)
                end
            end
            # Calculate EV and Exp gains for the participants
            if numPartic > 0 || expShare.length > 0 || expAll
                unGroupMessage = !Settings::GROUP_EXP_SHARE_MESSAGE && expShare.length > 0 && expShare.length > b.participants.length ? true : false
                # Gain EVs and Exp for participants
                eachInTeam(0, 0) do |pkmn, i|
                    next if !pkmn.able?
                    next unless b.participants.include?(i) || expShare.include?(i)
                    showMessage = b.participants.include?(i) || unGroupMessage ? true : false
                    pbGainEVsOne(i, b)
                    pbGainExpOne(i, b, numPartic, expShare, expAll, showMessage)
                end
                if !unGroupMessage && (expShare.length > numPartic && pbParty(0).length > 1)
                    pbDisplayPaused(_INTL("¡Tus otros Pokémon también ganaron puntos de experiencia!"))
                end
                # Gain EVs and Exp for all other Pokémon because of Exp All
                if expAll
                    showMessage = true
                    eachInTeam(0, 0) do |pkmn, i|
                        next if !pkmn.able?
                        next if b.participants.include?(i) || expShare.include?(i) 
                        pbDisplayPaused(_INTL("¡Tus otros Pokémon también ganaron puntos de experiencia!")) if showMessage && (expShare.length > numPartic && pbParty(0).length > 1)
                        showMessage = false
                        pbGainEVsOne(i, b)
                        pbGainExpOne(i, b, numPartic, expShare, expAll, false)
                    end
                end
            end
            # Clear the participants array
            b.participants = []
            end
        end
    end
end
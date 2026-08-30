class PokemonMartScreen
    alias pbBuyScreen_original pbBuyScreen
		def pbBuyScreen
			return pbBuyScreen_original unless ChallengeModes.on?(:HEALING_ITEMS_PURCHASE)
			@scene.pbStartBuyScene(@stock, @adapter)
			item = nil
			loop do
				item = @scene.pbChooseBuyItem
				break if !item
				quantity       = 0
				itemname       = @adapter.getName(item)
				itemnameplural = @adapter.getNamePlural(item)
				price = @adapter.getPrice(item)
				if ChallengeModes.on?(:HEALING_ITEMS_PURCHASE) && GameData::Item.get(item).is_healing_item?
					rule_name = ChallengeModes::RULES[:HEALING_ITEMS_PURCHASE][:display_name]
					pbDisplayPaused(_INTL("¡La regla \"{1}\" te impide comprar objetos de curación en las tiendas!", rule_name))
					next
				end
				if ChallengeModes.on?(:BATTLE_ITEMS_PURCHASE) &&  GameData::Item.get(item).is_stat_boost_item?
					rule_name = ChallengeModes::RULES[:BATTLE_ITEMS_PURCHASE][:display_name]
					pbDisplayPaused(_INTL("¡La regla \"{1}\" te impide comprar objetos de combate en las tiendas!", rule_name))
					next
				end
				if ChallengeModes.on?(:VITAMINS_PURCHASE) && GameData::Item.get(item).is_vitamin?
					rule_name = ChallengeModes::RULES[:VITAMINS_PURCHASE][:display_name]
					pbDisplayPaused(_INTL("¡La regla \"{1}\" te impide comprar vitaminas en las tiendas!", rule_name))
					next
				end
				if @adapter.getMoney < price
					pbDisplayPaused(_INTL("No tienes suficiente dinero."))
					next
				end
				if GameData::Item.get(item).is_important?
					next if !pbConfirm(_INTL("¿Así que quieres {1}?\nSerán ${2}. ¿Te parece bien?",
																	 itemname, price.to_s_formatted))
					quantity = 1
				else
					maxafford = (price <= 0) ? Settings::BAG_MAX_PER_SLOT : @adapter.getMoney / price
					maxafford = Settings::BAG_MAX_PER_SLOT if maxafford > Settings::BAG_MAX_PER_SLOT
					quantity = @scene.pbChooseNumber(
						_INTL("¿Cuántos {1} quieres?", itemnameplural), item, maxafford
					)
					next if quantity == 0
					price *= quantity
					if quantity > 1
						next if !pbConfirm(_INTL("¿Así que quieres {1} {2}?\nSerán ${3}. ¿Te parece bien?",
																		 quantity, itemnameplural, price.to_s_formatted))
					elsif quantity > 0
						next if !pbConfirm(_INTL("¿Así que quieres {1} {2}?\nSerán ${3}. ¿Te parece bien?",
																		 quantity, itemname, price.to_s_formatted))
					end
				end
				if @adapter.getMoney < price
					pbDisplayPaused(_INTL("No tienes suficiente dinero."))
					next
				end
				added = 0
				quantity.times do
					break if !@adapter.addItem(item)
					added += 1
				end
				if added == quantity
					$stats.money_spent_at_marts += price
					$stats.mart_items_bought += quantity
					@adapter.setMoney(@adapter.getMoney - price)
					@stock.delete_if { |itm| GameData::Item.get(itm).is_important? && $bag.has?(itm) }
					pbDisplayPaused(_INTL("¡Aquí tienes! ¡Muchas gracias!")) { pbSEPlay("Mart buy item") }
					if quantity >= 10 && GameData::Item.exists?(:PREMIERBALL)
						if Settings::MORE_BONUS_PREMIER_BALLS && GameData::Item.get(item).is_poke_ball?
							premier_balls_added = 0
							(quantity / 10).times do
								break if !@adapter.addItem(:PREMIERBALL)
								premier_balls_added += 1
							end
							ball_name = GameData::Item.get(:PREMIERBALL).portion_name
							ball_name = GameData::Item.get(:PREMIERBALL).portion_name_plural if premier_balls_added > 1
							$stats.premier_balls_earned += premier_balls_added
							pbDisplayPaused(_INTL("Recibes {1} {2} extra.", premier_balls_added, ball_name))
						elsif !Settings::MORE_BONUS_PREMIER_BALLS && GameData::Item.get(item) == :POKEBALL
							if @adapter.addItem(:PREMIERBALL)
								ball_name = GameData::Item.get(:PREMIERBALL).name
								$stats.premier_balls_earned += 1
								pbDisplayPaused(_INTL("Recibes 1 {1} extra.", ball_name))
							end
						end
					end
				else
					added.times do
						if !@adapter.removeItem(item)
							raise _INTL("Fallo al eliminar los objetos guardados")
						end
					end
					pbDisplayPaused(_INTL("No tienes hueco en tu Mochila."))
				end
			end
			@scene.pbEndBuyScene
		end
end
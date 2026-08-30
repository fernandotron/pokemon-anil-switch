if false

    module Compiler
    def self.insert_endspeech_scripts(event)
        return nil if !event || event.pages.empty?
        changed = false

        pbEachPage(event) do |page|
        list = page.list
        i = 0
        while i < list.length
            cmd = list[i]
            if cmd.code == 108 && cmd.parameters[0][/^EndSpeech\:\s*(.+)/i]
            text_lines = []
            indent = cmd.indent
            text_lines << $1.strip
            j = i + 1
            # Recolectar líneas 408 (continuación de comentario)
            while j < list.length && list[j].code == 408
                text_lines << list[j].parameters[0].strip
                j += 1
            end
            full_text = text_lines.join(" ")

            # Eliminar las líneas del comentario (desde i hasta j-1)
            (j - i).times { list.delete_at(i) }

            # Insertar el script en la misma posición original del comentario
            script_line = RPG::EventCommand.new(355, indent, ["setBattleRule(\"opponentlosetext\", \"#{full_text}\")"])
            list.insert(i, script_line)

            changed = true
            i += 1
            else
            i += 1
            end
        end
        end

        return changed ? event : nil
    end

    class << self
        alias endspeech_compile_trainer_events compile_trainer_events
        def compile_trainer_events(mustcompile)
        endspeech_compile_trainer_events(mustcompile)

        Console.echo_li("→ Insertando 'setBattleRule' en lugar de comentarios EndSpeech...")
        mapData = MapData.new
        count = 0
        mapData.mapinfos.keys.each do |id|
            map = mapData.getMap(id)
            next unless map
            changed = false
            map.events.each_value do |event|
            result = insert_endspeech_scripts(event)
            changed ||= !!result
            end
            if changed
            mapData.saveMap(id)
            count += 1
            end
        end
        Console.echo_done(true)
        Console.echo_li("✔ Eventos modificados en #{count} mapa(s).") if count > 0
        end
    end
    end


end
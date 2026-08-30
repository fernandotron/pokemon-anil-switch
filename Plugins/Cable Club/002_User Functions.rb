
# Returns false if an error occurred.
def pbCableClub
  return false if !$player.connecting_online
  scene = CableClub_Scene.new
  screen = CableClubScreen.new(scene)
  ret = screen.pbStartScreen
  return ret
end

def pbChangeOnlineTrainerType
  old_trainer_type = $player.online_trainer_type
  if $player.online_trainer_type==$player.trainer_type
    pbMessage(_INTL("Hmmm...!\\1"))
    pbMessage(_INTL("¿Cuál es tu tipo de Entrenador favorito?\\n¿Podrías decirme?\\1"))
  else
    trainername=GameData::TrainerType.get($player.online_trainer_type).name
    # if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
    msg=_INTL("¡Hola! Te confundieron con un {1}, no?\\1",trainername)
    # else
      # msg=_INTL("Hello! You've been mistaken for a {1}, haven't you?\\1",trainername)
    # end
    pbMessage(msg)
    pbMessage(_INTL("Pero creo que también podrías pasar por un tipo de Entrenador diferente.\\1"))
    pbMessage(_INTL("Entonces, ¿qué tal si me dices que tipo de Entrenador te gusta?\\1"))
  end
  commands=[]
  trainer_types=[]
  CableClub::ONLINE_TRAINER_TYPE_LIST.each do |type|
    t=type
    t=type[$player.gender] if type.is_a?(Array)
    commands.push(GameData::TrainerType.get(t).name)
    trainer_types.push(t)
  end
  commands.push(_INTL("Cancelar"))
  loop do
    cmd=pbMessage(_INTL("¿Qué tipo de Entrenador quisieras ser?"),commands,-1)
    if cmd>=0 && cmd<commands.length-1
      trainername=commands[cmd]
      # if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
        # msg=_INTL("An {1} is the kind of Trainer you want to be?",trainername)
      # else
      msg=_INTL("Un {1}, ¿ese es el tipo de Entrenador que quieres ser?",trainername)
      # end
      if pbConfirmMessage(msg)
        # if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
        #   msg=_INTL("I see! So an {1} is the kind of Trainer you like.\\1",trainername)
        # else
        msg=_INTL("¡Ya veo! entonces te gustan los {1}.\\1",trainername)
        # end
        pbMessage(msg)
        pbMessage(_INTL("En ese caso, otros podrán verte de esa misma manera.\\1"))
        $player.online_trainer_type=trainer_types[cmd]
        break
      end
    else
      break
    end
  end
  pbMessage(_INTL("De acuerdo, ¡nos vemos luego!"))
  if old_trainer_type != $player.online_trainer_type
    EventHandlers.trigger(:cable_club_trainer_type_updated,$player.online_trainer_type)
  end
end

def pbChangeOnlineWinText
  # pbMessage(_INTL("Cuando ganas un combate, a powerful victory speech is the way to go.\\1"))
  pbMessage(_INTL("Elige la frase a decir cuando ganes un combate.\\1"))
  commands = []
  CableClub::ONLINE_WIN_SPEECHES_LIST.each do |text|
    commands.push(_INTL(text))
  end
  commands.push(_INTL("Cancelar"))
  loop do
    cmd=pbMessage(_INTL("¿Que frase te gusta?"),commands,-1)
    if cmd>=0 && cmd<CableClub::ONLINE_WIN_SPEECHES_LIST.length-1
      win_text=commands[cmd]
      if pbConfirmMessage(_INTL("\"{1}\"\\n¿Esto es lo que quieres decir?",win_text))
        pbMessage(_INTL(win_text))
        $player.online_win_text=cmd
        break
      end
    else
      break
    end
  end
  # pbMessage(_INTL("Show your strength with your speech!"))
end

def pbChangeOnlineLoseText
  # pbMessage(_INTL("When you lose a battle, you still need to say something...\\1"))
  pbMessage(_INTL("Elige la frase a decir cuando pierdas un combate.\\1"))
  commands = []
  CableClub::ONLINE_LOSE_SPEECHES_LIST.each do |text|
    commands.push(_INTL(text))
  end
  commands.push(_INTL("Cancelar"))
  loop do
    cmd=pbMessage(_INTL("¿Que frase te gusta?"),commands,-1)
    if cmd>=0 && cmd<CableClub::ONLINE_LOSE_SPEECHES_LIST.length-1
      lose_text=commands[cmd]
      if pbConfirmMessage(_INTL("\"{1}\"\\n¿Esto es lo que quieres decir?",lose_text))
        pbMessage(_INTL(lose_text))
        # pbMessage(_INTL("\"{1}\"\\nYeah... That sounds good...\\1",lose_text))
        $player.online_lose_text=cmd
        break
      end
    else
      break
    end
  end
  # pbMessage(_INTL("...Hopefully you don't need to use it."))
end
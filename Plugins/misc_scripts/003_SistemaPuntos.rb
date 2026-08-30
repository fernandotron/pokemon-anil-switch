######################################################
#         Sistema de puntuación por progreso         #
#                   Autor: Bezier                    #
######################################################

# Variable que contendrá los puntos de progreso del juego
POKEBATTLE_POINTS_VARIABLE = 234

# Puntos que se consiguen al derrotar un entrenador
POKEBATTLE_POINTS_DEFEAT_TRAINER = 3
# Puntos que se pierden si se debilita un Pokémon del equipo
POKEBATTLE_POINTS_POKEMON_DEAD = 2

# Puntos adicionales que se obtienen al derrotar a ciertos entrenadores
SPECIAL_TRAINERS = {
  "Prueba1" => 2,
  "Prueba2" => 2,
  "Prueba3" => 2
}

class Battle::Scene
    alias pbTrainerBattleSuccessPoints pbTrainerBattleSuccess
    def pbTrainerBattleSuccess
        pbTrainerBattleSuccessPoints
        pts=pbGet(POKEBATTLE_POINTS_VARIABLE)+POKEBATTLE_POINTS_DEFEAT_TRAINER
        if SPECIAL_TRAINERS[@battle.opponent[0].name]
          pts+=SPECIAL_TRAINERS[@battle.opponent.name]
        end
        pbSet(POKEBATTLE_POINTS_VARIABLE,pts)
    end
end

class Battle::Battler
    alias pbFaintPoints pbFaint
    def pbFaint(showMessage = true)
        fainted = @fainted
        done=pbFaintPoints(showMessage)
        if !fainted && @fainted && @battle.pbOwnedByPlayer?(@index)
          pts = pbGet(POKEBATTLE_POINTS_VARIABLE) - POKEBATTLE_POINTS_POKEMON_DEAD
          pts = 0 if pts < 0
          pbSet(POKEBATTLE_POINTS_VARIABLE, pts)
        end
        return done 
    end
end
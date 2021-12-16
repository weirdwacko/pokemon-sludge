$DEBUG=true;
###This is just a quick function to save myself the trouble of recreating a
###team whenever I restart the game.
def pbSkipMeTeambuilding
  greninja = Pokemon.new(:GRENINJA,70)
  greninja.ability_index =2
  greninja.ev[:HP]=0
  greninja.ev[:ATTACK]=3
  greninja.ev[:DEFENSE]=3
  greninja.ev[:SPATK]=252
  greninja.ev[:SPDEF]=0
  greninja.ev[:SPEED]=252
  greninja.makeMale
  greninja.item= :ROCKGEM
  greninja.iv[:HP]=29
  greninja.iv[:ATTACK]=31
  greninja.iv[:DEFENSE]=16
  greninja.iv[:SPATK]=31
  greninja.iv[:SPDEF]=28
  greninja.iv[:SPEED]=29
  greninja.learn_move(:EXTRASENSORY)
  greninja.learn_move(:SURF)
  greninja.learn_move(:SMACKDOWN)
  greninja.learn_move(:AERIALACE)
  greninja.nature= :RASH
  pbAddPokemonSilent(greninja)
  
  bewear = Pokemon.new(:BEWEAR,67)
  bewear.ability_index =0
  bewear.ev[:HP]=252
  bewear.ev[:ATTACK]=252
  bewear.ev[:DEFENSE]=0
  bewear.ev[:SPATK]=4
  bewear.ev[:SPDEF]=1
  bewear.ev[:SPEED]=1
  bewear.makeFemale
  bewear.item= :MUSCLEBAND
  bewear.iv[:HP]=31
  bewear.iv[:ATTACK]=31
  bewear.iv[:DEFENSE]=6
  bewear.iv[:SPATK]=26
  bewear.iv[:SPDEF]=28
  bewear.iv[:SPEED]=29
  bewear.learn_move(:HAMMERARM)
  bewear.learn_move(:SUPERPOWER)
  bewear.learn_move(:AERIALACE)
  bewear.learn_move(:PAYBACK)
  bewear.nature= :BASHFUL
  pbAddPokemonSilent(bewear)
  
  scolipede = Pokemon.new(:SCOLIPEDE,65)
  scolipede.ability_index=2
  scolipede.ev[:HP]=2
  scolipede.ev[:ATTACK]=252
  scolipede.ev[:DEFENSE]=0
  scolipede.ev[:SPATK]=4
  scolipede.ev[:SPDEF]=0
  scolipede.ev[:SPEED]=252
  scolipede.makeFemale
  scolipede.item= :POISONBARB
  scolipede.iv[:HP]=22
  scolipede.iv[:ATTACK]=17
  scolipede.iv[:DEFENSE]=24
  scolipede.iv[:SPATK]=12
  scolipede.iv[:SPDEF]=26
  scolipede.iv[:SPEED]=29
  scolipede.learn_move(:TOXIC)
  scolipede.learn_move(:POISONTAIL)
  scolipede.learn_move(:MEGAHORN)
  scolipede.learn_move(:PROTECT)
  scolipede.nature = :HASTY
  pbAddPokemonSilent(scolipede)
  
  magmortar = Pokemon.new(:MAGMORTAR,67)
  magmortar.ability_index=0
  magmortar.ev[:HP]=0
  magmortar.ev[:ATTACK]=2
  magmortar.ev[:DEFENSE]=1
  magmortar.ev[:SPATK]=252
  magmortar.ev[:SPDEF]=3
  magmortar.ev[:SPEED]=252
  magmortar.makeMale
  magmortar.item= :EXPSHARE
  magmortar.iv[:HP]=29
  magmortar.iv[:ATTACK]=28
  magmortar.iv[:DEFENSE]=24
  magmortar.iv[:SPATK]=31
  magmortar.iv[:SPDEF]=18
  magmortar.iv[:SPEED]=31
  magmortar.learn_move(:LAVAPLUME)
  magmortar.learn_move(:CLEARSMOG)
  magmortar.learn_move(:FLAMETHROWER)
  magmortar.learn_move(:FIREBLAST)
  magmortar.nature = :HASTY
  pbAddPokemonSilent(magmortar)
  
  raichu = Pokemon.new(:RAICHU,70)
  raichu.ability_index=2
  raichu.ev[:HP]=0
  raichu.ev[:ATTACK]=4
  raichu.ev[:DEFENSE]=2
  raichu.ev[:SPATK]=252
  raichu.ev[:SPDEF]=0
  raichu.ev[:SPEED]=252
  raichu.makeMale
  raichu.shiny = true
  raichu.iv[:HP]=31
  raichu.iv[:ATTACK]=31
  raichu.iv[:DEFENSE]=14
  raichu.iv[:SPATK]=29
  raichu.iv[:SPDEF]=31
  raichu.iv[:SPEED]=8
  raichu.learn_move(:THUNDERBOLT)
  raichu.learn_move(:DISCHARGE)
  raichu.learn_move(:NASTYPLOT)
  raichu.learn_move(:THUNDERWAVE)
  raichu.nature = :MILD
  pbAddPokemonSilent(raichu)
  
  donphan = Pokemon.new(:DONPHAN,67)
  donphan.ability_index=0
  donphan.ev[:HP]=252
  donphan.ev[:ATTACK]=252
  donphan.ev[:DEFENSE]=0
  donphan.ev[:SPATK]=4
  donphan.ev[:SPDEF]=1
  donphan.ev[:SPEED]=1
  donphan.makeMale
  donphan.item= :SOFTSAND
  donphan.iv[:HP]=18
  donphan.iv[:ATTACK]=15
  donphan.iv[:DEFENSE]=24
  donphan.iv[:SPATK]=12
  donphan.iv[:SPDEF]=28
  donphan.iv[:SPEED]=29
  donphan.learn_move(:SCARYFACE)
  donphan.learn_move(:EARTHQUAKE)
  donphan.learn_move(:HEADSMASH)
  donphan.learn_move(:ICESHARD)
  donphan.nature = :LONELY
  pbAddPokemonSilent(donphan)
  
  garchomp = Pokemon.new(:GABITE,69)
  garchomp.ability_index=2
  garchomp.ev[:HP]=0
  garchomp.ev[:ATTACK]=252
  garchomp.ev[:DEFENSE]=0
  garchomp.ev[:SPATK]=0
  garchomp.ev[:SPDEF]=0
  garchomp.ev[:SPEED]=252
  garchomp.item= :RARECANDY
  garchomp.iv[:HP]=31
  garchomp.iv[:ATTACK]=31
  garchomp.iv[:DEFENSE]=31
  garchomp.iv[:SPATK]=31
  garchomp.iv[:SPDEF]=31
  garchomp.iv[:SPEED]=31
  garchomp.learn_move(:EARTHQUAKE)
  garchomp.learn_move(:FIREBLAST)
  garchomp.learn_move(:STONEEDGE)
  garchomp.learn_move(:DRACOMETEOR)
  garchomp.nature= :ADAMANT
  pbAddPokemonSilent(garchomp)
  
  blaziken = Pokemon.new(:BLAZIKEN,70)
  blaziken.ability_index=2
  blaziken.ev[:HP]=0
  blaziken.ev[:ATTACK]=252
  blaziken.ev[:DEFENSE]=0
  blaziken.ev[:SPATK]=0
  blaziken.ev[:SPDEF]=0
  blaziken.ev[:SPEED]=252
  blaziken.item = :BLAZIKENITE
  blaziken.iv[:HP]=31
  blaziken.iv[:ATTACK]=31
  blaziken.iv[:DEFENSE]=31
  blaziken.iv[:SPATK]=31
  blaziken.iv[:SPDEF]=31
  blaziken.iv[:SPEED]=31
  blaziken.learn_move(:HIGHJUMPKICK)
  blaziken.learn_move(:BRAVEBIRD)
  blaziken.learn_move(:FLAREBLITZ)
  blaziken.learn_move(:SWORDSDANCE)
  blaziken.nature= :ADAMANT
  pbAddPokemonSilent(blaziken)
  
  mamoswine = Pokemon.new(:MAMOSWINE,70)
  mamoswine.ability_index=2
  mamoswine.ev[:HP]=0
  mamoswine.ev[:ATTACK]=252
  mamoswine.ev[:DEFENSE]=0
  mamoswine.ev[:SPATK]=0
  mamoswine.ev[:SPDEF]=0
  mamoswine.ev[:SPEED]=252
  mamoswine.item= :CHOICESCARF
  mamoswine.iv[:HP]=31
  mamoswine.iv[:ATTACK]=31
  mamoswine.iv[:DEFENSE]=31
  mamoswine.iv[:SPATK]=31
  mamoswine.iv[:SPDEF]=31
  mamoswine.iv[:SPEED]=31
  mamoswine.learn_move(:EARTHQUAKE)
  mamoswine.learn_move(:ICESHARD)
  mamoswine.learn_move(:ICEFANG)
  mamoswine.learn_move(:STONEEDGE)
  mamoswine.nature= :ADAMANT
  pbAddPokemonSilent(mamoswine)
  
  magnezone = Pokemon.new(:MAGNEZONE,70)
  magnezone.ability_index=1
  magnezone.ev[:HP]=252
  magnezone.ev[:ATTACK]=0
  magnezone.ev[:DEFENSE]=0
  magnezone.ev[:SPATK]=252
  magnezone.ev[:SPDEF]=0
  magnezone.ev[:SPEED]=0
  magnezone.item=:LIGHTCLAY
  magnezone.iv[:HP]=31
  magnezone.iv[:ATTACK]=31
  magnezone.iv[:DEFENSE]=31
  magnezone.iv[:SPATK]=31
  magnezone.iv[:SPDEF]=31
  magnezone.iv[:SPEED]=31
  magnezone.learn_move(:FLASHCANNON)
  magnezone.learn_move(:THUNDERBOLT)
  magnezone.learn_move(:REFLECT)
  magnezone.learn_move(:LIGHTSCREEN)
  magnezone.nature= :MODEST
  pbAddPokemonSilent(magnezone)
  
  aegislash = Pokemon.new(:AEGISLASH,70)
  aegislash.ability_index= 1
  aegislash.ev[:HP]=252
  aegislash.ev[:ATTACK]=252
  aegislash.ev[:DEFENSE]=0
  aegislash.ev[:SPATK]=0
  aegislash.ev[:SPDEF]=0
  aegislash.ev[:SPEED]=0
  aegislash.item = :LEFTOVERS
  aegislash.iv[:HP]=31
  aegislash.iv[:ATTACK]=31
  aegislash.iv[:DEFENSE]=31
  aegislash.iv[:SPATK]=31
  aegislash.iv[:SPDEF]=31
  aegislash.iv[:SPEED]=31
  aegislash.learn_move(:SWORDSDANCE)
  aegislash.learn_move(:IRONHEAD)
  aegislash.learn_move(:SHADOWSNEAK)
  aegislash.learn_move(:KINGSSHIELD)
  aegislash.nature= :ADAMANT
  pbAddPokemonSilent(aegislash)
end
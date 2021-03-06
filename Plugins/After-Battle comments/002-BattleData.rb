class Battle_Data
  ##Careful there, OpponentName is an array if you've fought two people at once
  attr_accessor :opponentName
  ##Is nil if you didn't have a partner, obviously
  attr_accessor :partnerName
  attr_accessor :playerTeam
  attr_accessor :opponentTeam
  ##how many "points" each pokemon has scored throughout the battle, one array for
  ## each side.
  attr_accessor :playerTeamScores
  attr_accessor :opponentTeamScores
  ##the number of healing items has been used for both sides of the battle.
  attr_accessor :playerItemsUsed
  attr_accessor :opponentItemsUsed
  ##the name (as in, nickname) of the pokemon who was the MVP of a previous battle
  ## with a same opponent.
  attr_accessor :oldMVPName
  ##Used for graphical purpose in DisplayBattlers. Keeps track of who was the player's
  ##last pokemon to battle and who were they battling.
  attr_accessor :lastPokemonUsed  
  attr_accessor :lastPokemonAttacked
  ##Used for the nicknaming flag. Stores the nickname of the whole party.
  attr_accessor :nickname
  ##Used for the monotype flag. Stores the ID of the type the player's team shares.
  attr_accessor :monotype
  ##Sizes of the parties of each trainer involved. Always will follow the following
  ##Order : Player => Opponent 1 =>Partner =>Opponent 2 => Opponent 3, with zeroes 
  #if not applicable.
  attr_accessor :partySizes
  
  ##Constructor of the class. Only the the opponent name, their team and the player
  ##team are used as parameters, everything else is initialized at zero.
  def initialize(opponentName,playerTeam,opponentTeam,partySizes)
    ##enemy arrays has 18 entries to account for triple battle,
    ##player array has 12 to accoutn for double battles with a partner
    @playerTeamScores=[0,0,0,0,0,0,0,0,0,0,0,0]
    @opponentTeamScores=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    @playerItemsUsed=0
    @opponentItemsUsed=0
    @opponentName=opponentName
    ##We specifically clone because not doing so means the state of your team gets
    ##updated ay after the battle is over, meaning it voids all flags comparing your team.
    @playerTeam=playerTeam.clone
    @opponentTeam=opponentTeam
    @oldMVPName=nil
    @lastPokemonUsed=nil
    @lastPokemonAttacked=nil
    
    @partySizes=partySizes
    ##We fill the party array up to 5 with zeroes on the missing places so there's
    ##no bad surprise calling that array later.
    while @partySizes.length<5
      @partySizes << 0
    end
    @partnerName= $PokemonGlobal.partner ? $PokemonGlobal.partner[1]:nil
  end
  
  ##Called by ProcessFlags. Just so we're clear, this is strictly about
  ##healing items and such. held items are none of our business.
  def afterBattleItemsResult
    ##Self-explanatory : if the player used no items
    if @playerItemsUsed==0
      itemsResult = "NO_ITEMS"
    ##Case if the player used items, but less than the opponent did.
    elsif @playerItemsUsed>0 && @playerItemsUsed<=@opponentItemsUsed
      itemsResult = "LESS_ITEMS_THAN_OPPONENT"
    ##Selef explanatory : if the player used more items than the opponent.
    else
      itemsResult = "MORE_ITEMS_THAN_OPPONENT"
    end
    return itemsResult
  end

  ##called by the PokeBattle_Battler class, checks who fainted who and attributes
  ##points to the mon who did the kill based on whether they're legendaries,
  ##hold a Z-crystal or a mega-stone. (Zcrystal thing is disabled for Essentials version)
  def pokemonFaintedAnEnemy(battlers,user,target,move)
    #case the player is scoring
    if([0,2,4].include?(battlers.rindex(user)) && \
      [1,3,5].include?(battlers.rindex(target)))
      playerTeamIndex = user.pokemonIndex
      opponentTeamIndex = target.pokemonIndex
      score = 0 
      if (target.hasMega?||target.isMega?)
        score = 3
      #elsif (pbIsZCrystal2?(target.item)||pbIsZCrystal?(target.item))
       # score = 2
      else
        score = 1
      end
      if isLegendary(target.species)
        score = score * 2
      end
      @playerTeamScores[playerTeamIndex]+=score
      @lastPokemonUsed = user.pokemon.clone
      @lastPokemonAttacked = target.pokemon.clone
      #p @playerTeamScores
    #case the opponent is scoring
    elsif([0,2,4].include?(battlers.rindex(target)) && \
      [1,3,5].include?(battlers.rindex(user)))
      opponentTeamIndex = user.pokemonIndex
      playerTeamIndex = target.pokemonIndex
      score = 0 
      if (target.hasMega?||target.isMega?)
        score = 3
      #elsif (pbIsZCrystal2?(target.item)||pbIsZCrystal?(target.item))
       # score = 2
      else
        score = 1
      end
      if isLegendary(target.species)
        score = score * 2
      end
      @opponentTeamScores[opponentTeamIndex]+=score
      #p @opponentTeamScores
    end
  end

  ###Called by ProcessFlags
  ###Calculates if the battle was won by a landslide or was more of a close call.
  ###Does So by checking how many mons are still unfainted on the player side
  ###decides which flag to send depending of the  value of battleresult
  def afterBattleStateOfPartyResult
    total = @playerTeam.length
    faintedMons=0
    for i in 0..@playerTeam.length-1
      faintedMons+=1 if @playerTeam[i].hp==0
    end
    if (faintedMons ==0 && @playerItemsUsed ==0)
      battleResult = "6-0"
    elsif (faintedMons <3)      
      battleResult = "CURB_STOMP"
    elsif (faintedMons >4)
      battleResult = "CLOSE_CALL"
    end
    return battleResult
  end
  
  ###Called by ProcessFlags
  ###Provided that the player already fought a trainer with the same name, it loads
  ###the data of the previous match and returns various flags depending on the differences
  def getRematchData
    rematch = findIfRematchExists
    flags = []
    if !rematch.nil?
      sameTeam=establishTeamSimilarity(rematch)
      sameMVP=establishMVPSimilarity(rematch)
      ###fills the oldTeam array with the values of the team used in the previous match
      oldTeam = []
      rematch.playerTeam.each{ |n| oldTeam<<n.personalID}
      mvp = self.getMVPs[0]
      tempflag=""
      ##If the team contains 4 or more mons that were present at the previous battle
      if sameTeam
        tempflag="SAME_TEAM_"
      ##If at least 3 mons are different since last time
      else
        tempflag="NEW_TEAM_"
      end
      ##if the mvp was the same as last time
      if sameMVP
        tempflag+="SAME_MVP"
      ##if not but the mvp was already part of your old team
      elsif oldTeam.include?(self.getMVPs[0].personalID)
        tempflag+="DIFFERENT_MVP"
      else
        tempflag+="NEW_MVP"
      end
      flags<<tempflag
      ###If the MVP was already in the old team but is now a different species/
      ###has a mega-stone/has a z-move compared to last time.
      if oldTeam.include?(self.getMVPs[0].personalID)
        oldMon = rematch.playerTeam.find{|i| i.personalID==mvp.personalID}
        flags<<"MVP_EVOLVED" if hasMVPEvolved(oldMon,mvp)
        flags<<"MVP_MEGA" if acquiredMega(oldMon,mvp)
        #flags<<"MVP_Z_CRYSTAL" if acquiredZCrystal(oldMon,mvp)
      end
      ###If the MVP from last time is no longer in the player team
      currentTeam =[]
      @playerTeam.each{ |n| currentTeam<<n.personalID}
      if !currentTeam.include?(rematch.getMVPs[0].personalID)
        flags<<"OLD_MVP_DISAPPEARED"
      end
    end
    return flags
  end
  
  ###Called by ProcessFlags. Returns whether or not every mon in the team shares a
  ###common type or an identical nickname, and whether or not the opponent's team is
  ###outnumbering the player's.
  def miscFlags
    flags = []
    names = []
    @playerTeam.each {|i| names << i.name}
    if names.uniq.size ==1 && @playerTeam.length>1
      flags << "IDENTICAL_NICKNAMES"
      @nickname = @playerTeam[0].name
    end
    type1 = @playerTeam[0].type1
    type2 = @playerTeam[0].type2
    count1 =0
    count2 =0
    @playerTeam.each {|i| 
      if (i.type1==type1 || i.type2 == type1)
        count1+=1
      end
      if (i.type1==type2 || i.type2 == type2)
        count2+=1
      end}
    if count1==@playerTeam.length || count2==@playerTeam.length
      flags << "MONOTYPE"
    end
    if count1==@playerTeam.length  
      @monotype = type1
    elsif count2==@playerTeam.length
      @monotype = type2
    end
    if @playerTeam.length<@opponentTeam.length
      flags <<"OUTNUMBERED"
    elsif @playerTeam.length>@opponentTeam.length
      flags <<"OUTNUMBERING"
    end
    return flags
  end
  
  ###Called by getRematchData. Establish how many mons were changed compared to the
  ###last battle. Does so by using the personalID unique to each mon.
  def establishTeamSimilarity(match)
    oldTeam =[]
    match.playerTeam.each{ |n| oldTeam<<n.personalID}
    newTeam = []
    @playerTeam.each{ |n| newTeam<<n.personalID}
    p newTeam&oldTeam
    return (newTeam&oldTeam).length>3
  end
  
  ###Called by getRematchData. Finds the ID of the old MVP and compares it to the ID
  ###of the current MVP
  def establishMVPSimilarity(match)
    oldMVP=match.getMVPs[0]
    @oldMVPName=oldMVP.name
    newMVP=self.getMVPs[0]
    return oldMVP.personalID==newMVP.personalID
  end
  
  ###Called by getRematchData. Checks for evolution by comparing the species of the mvp
  ###back in the last battle compared to now.
  def hasMVPEvolved(oldMon,mvp)
    return oldMon.species != mvp.species
  end
  
  ###Called by getRematchData. Similar as above
  def acquiredMega(oldMon,mvp)
    return !oldMon.hasMegaForm? && mvp.hasMegaForm?
  end
  
  ###Called by getRematchData. Similar as above
  #def acquiredZCrystal(oldMon,mvp)
   # return (!(pbIsZCrystal2?(oldMon.item)||pbIsZCrystal?(oldMon.item))&& \
   # (pbIsZCrystal2?(mvp.item)||pbIsZCrystal?(mvp.item)))
  #end
  
  ###Called by getRematchData. Ensures there is a point at all in doing any of this
  def findIfRematchExists
    ##we're voluntarily stopping 1 entry in the array short so we don't arrive at
    ##the current battle and have it compare to itself
    hasFoundMatch = nil
    for i in 0..$battleDataArray.length-2
      ##name is the best thing I could come up to recognize a trainer,
      ##so you'll have to improvise if you want to mess around with names
      ##Also, since opponentName can be an array, fighting two opponents at once
      ##will only ever register as a rematch if you've fought them as a duo before.
      if $battleDataArray[i].opponentName ==@opponentName       
        hasFoundMatch = $battleDataArray[i]
      end
    end
    return hasFoundMatch
  end
  
  ###Called by CharacterResponses. Loops through both player and enemy team arrays,
  ###splits them based on the teamSizes paramter, and find which mon has the 
  ##highest score in each of thegroups. 
  def getMVPs
    mvps = []
    player1 = @playerTeamScores.first(@partySizes[0])
    mvps<< @playerTeam[player1.rindex(player1.max)]
    opponent1= @opponentTeamScores.first(@partySizes[1])
    mvps<< @opponentTeam[opponent1.rindex(opponent1.max)]
    if(@partySizes[2]!=0)
      player2 = @playerTeamScores.last(@partySizes[2])
      mvps<< @playerTeam[@partySizes[0]+player2.rindex(player2.max)]
    end
    if(@partySizes[3]!=0)
      opponent2= @opponentTeamScores[@partySizes[1]..@partySizes[1]+@partySizes[3]]
      mvps<< @opponentTeam[@partySizes[1]+opponent2.rindex(opponent2.max)]
    end
    if(@partySizes[4]!=0)
      opponent3= @opponentTeamScores.last(@partySizes[4])
      mvps<< @opponentTeam[@partySizes[1]+@partySizes[3]+opponent3.rindex(opponent3.max)]
    end
    #p mvps
    return mvps
  end
  
  ###Same as above, but this time, it returns the mon with the lowest score.
  ###If there is a tie, first with the lowest score is picked.
  def getLVPs
    lvps = []
    player1 = @playerTeamScores.first(@partySizes[0])
    lvps<< @playerTeam[player1.find_index(player1.min)]
    opponent1= @opponentTeamScores.first(@partySizes[1])
    lvps<< @opponentTeam[opponent1.find_index(opponent1.min)]
    if(partySizes[2]!=0)
      player2 = @playerTeamScores.last(@partySizes[2])
      lvps<< @playerTeam[@partySizes[0]+player2.find_index(player2.min)]
    end
    if(!partySizes[3]!=0)
      opponent2= @opponentTeamScores[@partySizes[1]..@partySizes[1]+@partySizes[3]]
      lvps<< @opponentTeam[@partySizes[1]+opponent2.find_index(opponent2.min)]
    end
    return lvps
    if(partySizes[4])
      opponent3= @opponentTeamScores.last(@partySizes[4])
      lvps<< @opponentTeam[@partySizes[1]+@partySizes[3]+opponent2.find_index(opponent3.min)]
    end
    return lvps
  end
  
  ###Called by the Battle Class. Simply increments the ItemsUsed attribute.
  def playerUsedAnItem
    $battleDataArray.last().playerItemsUsed+=1
  end

  ###Same as above but for the opponent
  def opponentUsedAnItem
    $battleDataArray.last().opponentItemsUsed+=1
  end
  ###Used for the score calculation bit of PokemonFaintedAnEnemy to determine whether
  ###or not a mon counts as a legendary. Currently also includes mythicals and 
  ##Ultra-beasts indiscriminately.
  def isLegendary(species)
    return [144,145,146,150,151,243,244,245,249,250,251,377,378,379,380,
    381,382,383,384,385,386,480,481,482,483,484,485,486,4867,488,489,
    490,491,492,493,494,638,639,640,641,642,643,644,645,646,647,648,
    649,772,773,785,786,787,788,793,794,795,795,797,798,799,803,804,
    805,806,891,892,894,895,896,897].include? species
  end
  
  def isThereMVP()
    if @playerTeamScores.max()>=3
      return "MVP"
    end
  end
###OBSOLETE: currently unused, replaced by a different version that instead
###Checks for how many mons are still alive in the player team, still left in in case
###you feel like using it.
  def afterBattleStateOfPartyResultOld
    total = @playerTeam.length
    percentHP = 0.0
    for i in 0..@playerTeam.length-1
      percentHP = percentHP + @playerTeam[i].hp.to_f / @playerTeam[i].totalhp.to_f
    end
    percentHP = percentHP.to_f/total.to_f
    if (percentHP > 0.66)
      battleResult = "CURB_STOMP"
    elsif (percentHP < 0.33)
      battleResult = "CLOSE_CALL"
    end
    return battleResult
  end
end
###YUMIL - 01 - NPC REACTION MOD - START   
SaveData.register(:battleDataArray) do
  ensure_class :Array
  save_value { $battleDataArray }
  load_value { |value| $battleDataArray = value }
  new_game_value { $battleDataArray=[] }
end
###YUMIL - 01 - NPC REACTION MOD - END

class PokeBattle_Battler
  #=============================================================================
  # Effect per hit
  #=============================================================================
  def pbEffectsOnMakingHit(move,user,target)
    if target.damageState.calcDamage>0 && !target.damageState.substitute
      # Target's ability
      if target.abilityActive?(true)
        oldHP = user.hp
        BattleHandlers.triggerTargetAbilityOnHit(target.ability,user,target,move,@battle)
        user.pbItemHPHealCheck if user.hp<oldHP
      end
      # User's ability
      if user.abilityActive?(true)
        BattleHandlers.triggerUserAbilityOnHit(user.ability,user,target,move,@battle)
        user.pbItemHPHealCheck
      end
      # Target's item
      if target.itemActive?(true)
        oldHP = user.hp
        BattleHandlers.triggerTargetItemOnHit(target.item,user,target,move,@battle)
        user.pbItemHPHealCheck if user.hp<oldHP
      end
    end
    if target.opposes?(user)
      # Rage
      if target.effects[PBEffects::Rage] && !target.fainted?
        if target.pbCanRaiseStatStage?(:ATTACK,target)
          @battle.pbDisplay(_INTL("{1}'s rage is building!",target.pbThis))
          target.pbRaiseStatStage(:ATTACK,1,target)
        end
      end
      # Beak Blast
      if target.effects[PBEffects::BeakBlast]
        PBDebug.log("[Lingering effect] #{target.pbThis}'s Beak Blast")
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          target.pbBurn(user) if target.pbCanBurn?(user,false,self)
        end
      end
      # Shell Trap (make the trapper move next if the trap was triggered)
      if target.effects[PBEffects::ShellTrap] &&
         @battle.choices[target.index][0]==:UseMove && !target.movedThisRound?
        if target.damageState.hpLost>0 && !target.damageState.substitute && move.physicalMove?
          target.tookPhysicalHit              = true
          target.effects[PBEffects::MoveNext] = true
          target.effects[PBEffects::Quash]    = 0
        end
      end
      # Grudge
      if target.effects[PBEffects::Grudge] && target.fainted?
        move.pp = 0
        @battle.pbDisplay(_INTL("{1}'s {2} lost all of its PP due to the grudge!",
           user.pbThis,move.name))
      end
      # Destiny Bond (recording that it should apply)
      if target.effects[PBEffects::DestinyBond] && target.fainted?
        if user.effects[PBEffects::DestinyBondTarget]<0
          user.effects[PBEffects::DestinyBondTarget] = target.index
        end
      end
		   ###YUMIL - 02 - NPC REACTION MOD - START  
      if target.isFainted? && @battle.recorded
          $battleDataArray.last().pokemonFaintedAnEnemy(@battle.battlers,user,target,move)
      end
		  ### YUMIL - 02 - NPC REACTION MOD - END 
    end
  end
end

class PokeBattle_Battle
  attr_reader   :scene            # Scene object for this battle
  attr_reader   :peer
  attr_reader   :field            # Effects common to the whole of a battle
  attr_reader   :sides            # Effects common to each side of a battle
  attr_reader   :positions        # Effects that apply to a battler position
  attr_reader   :battlers         # Currently active Pokémon
  attr_reader   :sideSizes        # Array of number of battlers per side
  attr_accessor :backdrop         # Filename fragment used for background graphics
  attr_accessor :backdropBase     # Filename fragment used for base graphics
  attr_accessor :time             # Time of day (0=day, 1=eve, 2=night)
  attr_accessor :environment      # Battle surroundings (for mechanics purposes)
  attr_reader   :turnCount
  attr_accessor :decision         # Decision: 0=undecided; 1=win; 2=loss; 3=escaped; 4=caught
  attr_reader   :player           # Player trainer (or array of trainers)
  attr_reader   :opponent         # Opponent trainer (or array of trainers)
  attr_accessor :items            # Items held by opponents
  attr_accessor :endSpeeches
  attr_accessor :endSpeechesWin
  attr_accessor :party1starts     # Array of start indexes for each player-side trainer's party
  attr_accessor :party2starts     # Array of start indexes for each opponent-side trainer's party
  attr_accessor :internalBattle   # Internal battle flag
  attr_accessor :debug            # Debug flag
  attr_accessor :canRun           # True if player can run from battle
  attr_accessor :canLose          # True if player won't black out if they lose
  attr_accessor :switchStyle      # Switch/Set "battle style" option
  attr_accessor :showAnims        # "Battle Effects" option
  attr_accessor :controlPlayer    # Whether player's Pokémon are AI controlled
  attr_accessor :expGain          # Whether Pokémon can gain Exp/EVs
  attr_accessor :moneyGain        # Whether the player can gain/lose money
  attr_accessor :rules
  attr_accessor :choices          # Choices made by each Pokémon this round
  attr_accessor :megaEvolution    # Battle index of each trainer's Pokémon to Mega Evolve
  attr_reader   :initialItems
  attr_reader   :recycleItems
  attr_reader   :belch
  attr_reader   :battleBond
  attr_reader   :usedInBattle     # Whether each Pokémon was used in battle (for Burmy)
  attr_reader   :successStates    # Success states
  attr_accessor :lastMoveUsed     # Last move used
  attr_accessor :lastMoveUser     # Last move user
  attr_reader   :switching        # True if during the switching phase of the round
  attr_reader   :futureSight      # True if Future Sight is hitting
  attr_reader   :endOfRound       # True during the end of round
  attr_accessor :moldBreaker      # True if Mold Breaker applies
  attr_reader   :struggle         # The Struggle move
#### YUMIL - 03 - NPC REACTION MOD - START  
  attr_accessor(:recorded)
  attr_accessor(:partysizes)
#### YUMIL - 03 - NPC REACTION MOD - END 


#### YUMIL - 04 - NPC REACTION MOD - START  
  def initialize(scene,p1,p2,player,opponent,recorded,partysizes)
    #### YUMIL - 04 - NPC REACTION MOD - START  
    if p1.length==0
      raise ArgumentError.new(_INTL("Party 1 has no Pokémon."))
    elsif p2.length==0
      raise ArgumentError.new(_INTL("Party 2 has no Pokémon."))
    end
    @scene             = scene
    @peer              = PokeBattle_BattlePeer.create
    @battleAI          = PokeBattle_AI.new(self)
    @field             = PokeBattle_ActiveField.new    # Whole field (gravity/rooms)
    @sides             = [PokeBattle_ActiveSide.new,   # Player's side
                          PokeBattle_ActiveSide.new]   # Foe's side
    @positions         = []                            # Battler positions
    @battlers          = []
    @sideSizes         = [1,1]   # Single battle, 1v1
    @backdrop          = ""
    @backdropBase      = nil
    @time              = 0
    @environment       = :None   # e.g. Tall grass, cave, still water
    @turnCount         = 0
    @decision          = 0
    @caughtPokemon     = []
    player   = [player] if !player.nil? && !player.is_a?(Array)
    opponent = [opponent] if !opponent.nil? && !opponent.is_a?(Array)
    @player            = player     # Array of Player/NPCTrainer objects, or nil
    @opponent          = opponent   # Array of NPCTrainer objects, or nil
    @items             = nil
    @endSpeeches       = []
    @endSpeechesWin    = []
    @party1            = p1
    @party2            = p2
    @party1order       = Array.new(@party1.length) { |i| i }
    @party2order       = Array.new(@party2.length) { |i| i }
    @party1starts      = [0]
    @party2starts      = [0]
    @internalBattle    = true
    @debug             = false
    @canRun            = true
    @canLose           = false
    @switchStyle       = true
    @showAnims         = true
    @controlPlayer     = false
    @expGain           = true
    @moneyGain         = true
    @rules             = {}
    @priority          = []
    @priorityTrickRoom = false
    @choices           = []
    @megaEvolution     = [
       [-1] * (@player ? @player.length : 1),
       [-1] * (@opponent ? @opponent.length : 1)
    ]
    @initialItems      = [
       Array.new(@party1.length) { |i| (@party1[i]) ? @party1[i].item_id : nil },
       Array.new(@party2.length) { |i| (@party2[i]) ? @party2[i].item_id : nil }
    ]
    @recycleItems      = [Array.new(@party1.length, nil),   Array.new(@party2.length, nil)]
    @belch             = [Array.new(@party1.length, false), Array.new(@party2.length, false)]
    @battleBond        = [Array.new(@party1.length, false), Array.new(@party2.length, false)]
    @usedInBattle      = [Array.new(@party1.length, false), Array.new(@party2.length, false)]
    @successStates     = []
    @lastMoveUsed      = nil
    @lastMoveUser      = -1
    @switching         = false
    @futureSight       = false
    @endOfRound        = false
    @moldBreaker       = false
    @runCommand        = 0
    @nextPickupUse     = 0
    if GameData::Move.exists?(:STRUGGLE)
      @struggle = PokeBattle_Move.from_pokemon_move(self, Pokemon::Move.new(:STRUGGLE))
    else
      @struggle = PokeBattle_Struggle.new(self, nil)
    end
    #### YUMIL - 05 - NPC REACTION MOD - START
    @recorded        = recorded
    @partysizes      = partysizes
		if @recorded == true
		  createNewBattleRecord
		end  
    #### YUMIL - 05 - NPC REACTION MOD - END 
  end
  
   #### YUMIL - 06 - NPC REACTION MOD - START  
  def createNewBattleRecord
    if $battleDataArray.nil?
      $battleDataArray=[]
    end
    if @opponent.length==3
      $battleDataArray<<Battle_Data.new([@opponent[0].name,@opponent[1].name,@opponent[2].name],@party1,@party2,@partysizes)
    elsif @opponent.length==2
      $battleDataArray<<Battle_Data.new([@opponent[0].name,@opponent[1].name],@party1,@party2,@partysizes)
    else
      $battleDataArray<<Battle_Data.new(@opponent[0].name,@party1,@party2,@partysizes)
    end
  end
  #### YUMIL - 06 - NPC REACTION MOD - END 
end

class PokeBattle_Battle
# Uses an item on a Pokémon in the trainer's party.
  def pbUseItemOnPokemon(item,idxParty,userBattler)
    trainerName = pbGetOwnerName(userBattler.index)
    pbUseItemMessage(item,trainerName)
    pkmn = pbParty(userBattler.index)[idxParty]
    battler = pbFindBattler(idxParty,userBattler.index)
    ch = @choices[userBattler.index]
    if ItemHandlers.triggerCanUseInBattle(item,pkmn,battler,ch[3],true,self,@scene,false)
      ItemHandlers.triggerBattleUseOnPokemon(item,pkmn,battler,ch,@scene)
      #### YUMIL - 07 - NPC REACTION MOD - START
      if @recorded == true
        if opposes?(userBattler.index)
          $battleDataArray.last().opponentUsedAnItem
        else
          $battleDataArray.last().playerUsedAnItem
        end
      end
      #### YUMIL - 07 - NPC REACTION MOD - END 
      ch[1] = nil   # Delete item from choice
      return
    end
    pbDisplay(_INTL("But it had no effect!"))
    # Return unused item to Bag
    pbReturnUnusedItemToBag(item,userBattler.index)
  end

  # Uses an item on a Pokémon in battle that belongs to the trainer.
  def pbUseItemOnBattler(item,idxParty,userBattler)
    trainerName = pbGetOwnerName(userBattler.index)
    pbUseItemMessage(item,trainerName)
    battler = pbFindBattler(idxParty,userBattler.index)
    ch = @choices[userBattler.index]
    if battler
      if ItemHandlers.triggerCanUseInBattle(item,battler.pokemon,battler,ch[3],true,self,@scene,false)
        ItemHandlers.triggerBattleUseOnBattler(item,battler,@scene)
        #### YUMIL - 08 - NPC REACTION MOD - START
                if @recorded == true
          if opposes?(userBattler.index)
            $battleDataArray.last().opponentUsedAnItem
          else
            $battleDataArray.last().playerUsedAnItem
          end
        end
        #### YUMIL - 08 - NPC REACTION MOD - END 
        ch[1] = nil   # Delete item from choice
        return
      else
        pbDisplay(_INTL("But it had no effect!"))
      end
    else
      pbDisplay(_INTL("But it's not where this item can be used!"))
    end
    # Return unused item to Bag
    pbReturnUnusedItemToBag(item,userBattler.index)
  end
  # Uses an item in battle directly.
  def pbUseItemInBattle(item,idxBattler,userBattler)
    trainerName = pbGetOwnerName(userBattler.index)
    pbUseItemMessage(item,trainerName)
    battler = (idxBattler<0) ? userBattler : @battlers[idxBattler]
    pkmn = battler.pokemon
    ch = @choices[userBattler.index]
    if ItemHandlers.triggerCanUseInBattle(item,pkmn,battler,ch[3],true,self,@scene,false)
      ItemHandlers.triggerUseInBattle(item,battler,self)
      #### YUMIL - 09 - NPC REACTION MOD - START
        if @recorded == true
          if opposes?(userBattler.index)
            $battleDataArray.last().opponentUsedAnItem
          else
            $battleDataArray.last().playerUsedAnItem
          end
        end
        #### YUMIL - 09 - NPC REACTION MOD - END 
      ch[1] = nil   # Delete item from choice
      return
    end
    pbDisplay(_INTL("But it had no effect!"))
    # Return unused item to Bag
    pbReturnUnusedItemToBag(item,userBattler.index)
  end
end

def pbTrainerBattleCore(*args)
  outcomeVar = $PokemonTemp.battleRules["outcomeVar"] || 1
  canLose    = $PokemonTemp.battleRules["canLose"] || false
  # Skip battle if the player has no able Pokémon, or if holding Ctrl in Debug mode
  if $Trainer.able_pokemon_count == 0 || ($DEBUG && Input.press?(Input::CTRL))
    pbMessage(_INTL("SKIPPING BATTLE...")) if $DEBUG
    pbMessage(_INTL("AFTER WINNING...")) if $DEBUG && $Trainer.able_pokemon_count > 0
    pbSet(outcomeVar,($Trainer.able_pokemon_count == 0) ? 0 : 1)   # Treat it as undecided/a win
    $PokemonTemp.clearBattleRules
    $PokemonGlobal.nextBattleBGM       = nil
    $PokemonGlobal.nextBattleME        = nil
    $PokemonGlobal.nextBattleCaptureME = nil
    $PokemonGlobal.nextBattleBack      = nil
    pbMEStop
    return ($Trainer.able_pokemon_count == 0) ? 0 : 1   # Treat it as undecided/a win
  end
  # Record information about party Pokémon to be used at the end of battle (e.g.
  # comparing levels for an evolution check)
  Events.onStartBattle.trigger(nil)
  # Generate trainers and their parties based on the arguments given
  foeTrainers    = []
  foeItems       = []
  foeEndSpeeches = []
  foeParty       = []
  foePartyStarts = []
  ###Yumil - 10 - NPC Reaction - End  
  partysizes=[]
  ###Yumil - 10 - NPC Reaction - End  
  for arg in args
    if arg.is_a?(NPCTrainer)
      foeTrainers.push(arg)
      foePartyStarts.push(foeParty.length)
      arg.party.each { |pkmn| foeParty.push(pkmn) }
      foeEndSpeeches.push(arg.lose_text)
      foeItems.push(arg.items)
    elsif arg.is_a?(Array)   # [trainer type, trainer name, ID, speech (optional)]
      trainer = pbLoadTrainer(arg[0],arg[1],arg[2])
      pbMissingTrainer(arg[0],arg[1],arg[2]) if !trainer
      return 0 if !trainer
      Events.onTrainerPartyLoad.trigger(nil,trainer)
      foeTrainers.push(trainer)
      foePartyStarts.push(foeParty.length)
      trainer.party.each { |pkmn| foeParty.push(pkmn) }
      foeEndSpeeches.push(arg[3] || trainer.lose_text)
      foeItems.push(trainer.items)
    ###Yumil - 11 - NPC Reaction - Begin
    elsif [true, false].include? arg
      recorded = arg
      partysizes<<$Trainer.party.length
      for arg2 in args
        if arg2.is_a?(NPCTrainer)
            partysizes<<arg2.party.length
        elsif arg2.is_a?(Array)
          trainer = pbLoadTrainer(arg2[0],arg2[1],arg2[2])
          partysizes<<trainer.party.length
        end
      end
      if $PokemonGlobal.partner!=nil
        partysizes.insert(2,$PokemonGlobal.partner[3].length)
      else
        partysizes.insert(2,0)
      end
    ###Yumil - 11 - NPC Reaction - End
    else
      raise _INTL("Expected NPCTrainer or array of trainer data, got {1}.", arg)
    end
  end
  # Calculate who the player trainer(s) and their party are
  playerTrainers    = [$Trainer]
  playerParty       = $Trainer.party
  playerPartyStarts = [0]
  room_for_partner = (foeParty.length > 1)
  if !room_for_partner && $PokemonTemp.battleRules["size"] &&
     !["single", "1v1", "1v2", "1v3"].include?($PokemonTemp.battleRules["size"])
    room_for_partner = true
  end
  if $PokemonGlobal.partner && !$PokemonTemp.battleRules["noPartner"] && room_for_partner
    ally = NPCTrainer.new($PokemonGlobal.partner[1], $PokemonGlobal.partner[0])
    ally.id    = $PokemonGlobal.partner[2]
    ally.party = $PokemonGlobal.partner[3]
    playerTrainers.push(ally)
    playerParty = []
    $Trainer.party.each { |pkmn| playerParty.push(pkmn) }
    playerPartyStarts.push(playerParty.length)
    ally.party.each { |pkmn| playerParty.push(pkmn) }
    setBattleRule("double") if !$PokemonTemp.battleRules["size"]
  end
  # Create the battle scene (the visual side of it)
  scene = pbNewBattleScene
  # Create the battle class (the mechanics side of it)
  ###Yumil - 12 - NPC Reaction - Begin
  battle = PokeBattle_Battle.new(scene,playerParty,foeParty,playerTrainers,foeTrainers,recorded,partysizes)
  ###Yumil - 12 - NPC Reaction - End
  battle.party1starts = playerPartyStarts
  battle.party2starts = foePartyStarts
  battle.items        = foeItems
  battle.endSpeeches  = foeEndSpeeches
  # Set various other properties in the battle class
  pbPrepareBattle(battle)
  $PokemonTemp.clearBattleRules
  # End the trainer intro music
  Audio.me_stop
  # Perform the battle itself
  decision = 0
  pbBattleAnimation(pbGetTrainerBattleBGM(foeTrainers),(battle.singleBattle?) ? 1 : 3,foeTrainers) {
    pbSceneStandby {
      decision = battle.pbStartBattle
    }
    pbAfterBattle(decision,canLose)
  }
  Input.update
  # Save the result of the battle in a Game Variable (1 by default)
  #    0 - Undecided or aborted
  #    1 - Player won
  #    2 - Player lost
  #    3 - Player or wild Pokémon ran from battle, or player forfeited the match
  #    5 - Draw
  pbSet(outcomeVar,decision)
  return decision
end

#===============================================================================
# Standard methods that start a trainer battle of various sizes
#===============================================================================
# Used by most trainer events, which can be positioned in such a way that
# multiple trainer events spot the player at once. The extra code in this method
# deals with that case and can cause a double trainer battle instead.
###Yumil - 13 - NPC Reaction - Begin
def pbTrainerBattle(trainerID, trainerName, endSpeech=nil,
                    doubleBattle=false, trainerPartyID=0, canLose=false, outcomeVar=1, recorded=false)
###Yumil - 13 - NPC Reaction - END
  # If there is another NPC trainer who spotted the player at the same time, and
  # it is possible to have a double battle (the player has 2+ able Pokémon or
  # has a partner trainer), then record this first NPC trainer into
  # $PokemonTemp.waitingTrainer and end this method. That second NPC event will
  # then trigger and cause the battle to happen against this first trainer and
  # themselves.
  if !$PokemonTemp.waitingTrainer && pbMapInterpreterRunning? &&
     ($Trainer.able_pokemon_count > 1 ||
     ($Trainer.able_pokemon_count > 0 && $PokemonGlobal.partner))
    thisEvent = pbMapInterpreter.get_character(0)
    # Find all other triggered trainer events
    triggeredEvents = $game_player.pbTriggeredTrainerEvents([2],false)
    otherEvent = []
    for i in triggeredEvents
      next if i.id==thisEvent.id
      next if $game_self_switches[[$game_map.map_id,i.id,"A"]]
      otherEvent.push(i)
    end
    # Load the trainer's data, and call an event which might modify it
    trainer = pbLoadTrainer(trainerID,trainerName,trainerPartyID)
    pbMissingTrainer(trainerID,trainerName,trainerPartyID) if !trainer
    return false if !trainer
    Events.onTrainerPartyLoad.trigger(nil,trainer)
    # If there is exactly 1 other triggered trainer event, and this trainer has
    # 6 or fewer Pokémon, record this trainer for a double battle caused by the
    # other triggered trainer event
    if otherEvent.length == 1 && trainer.party.length <= Settings::MAX_PARTY_SIZE
      trainer.lose_text = endSpeech if endSpeech && !endSpeech.empty?
      $PokemonTemp.waitingTrainer = [trainer, thisEvent.id]
      return false
    end
  end
  # Set some battle rules
  setBattleRule("outcomeVar",outcomeVar) if outcomeVar!=1
  setBattleRule("canLose") if canLose
  setBattleRule("double") if doubleBattle || $PokemonTemp.waitingTrainer
  # Perform the battle
  
  ###Yumil - 14 - NPC Reaction - Begin
  if $PokemonTemp.waitingTrainer
    decision = pbTrainerBattleCore($PokemonTemp.waitingTrainer[0],
       [trainerID,trainerName,trainerPartyID,endSpeech],recorded
    )
  else
    decision = pbTrainerBattleCore([trainerID,trainerName,trainerPartyID,endSpeech],recorded)
  end
  ###Yumil - 14 - NPC Reaction - END
  
  # Finish off the recorded waiting trainer, because they have now been battled
  if decision==1 && $PokemonTemp.waitingTrainer   # Win
    pbMapInterpreter.pbSetSelfSwitch($PokemonTemp.waitingTrainer[1], "A", true)
  end
  $PokemonTemp.waitingTrainer = nil
  # Return true if the player won the battle, and false if any other result
  return (decision==1)
end

###Yumil - 15 - NPC Reaction - Begin
def pbDoubleTrainerBattle(trainerID1, trainerName1, trainerPartyID1, endSpeech1,
                          trainerID2, trainerName2, trainerPartyID2=0, endSpeech2=nil,
                          canLose=false, outcomeVar=1, recorded = false)
###Yumil - 15 - NPC Reaction - End                         
  # Set some battle rules
  setBattleRule("outcomeVar",outcomeVar) if outcomeVar!=1
  setBattleRule("canLose") if canLose
  setBattleRule("double")
  # Perform the battle
  ###Yumil - 16 - NPC Reaction - Begin
  decision = pbTrainerBattleCore(
     [trainerID1,trainerName1,trainerPartyID1,endSpeech1],
     [trainerID2,trainerName2,trainerPartyID2,endSpeech2],recorded
  )
  ###Yumil - 16 - NPC Reaction - End
  # Return true if the player won the battle, and false if any other result
  return (decision==1)
end

###Yumil - 17 - NPC Reaction - Begin
def pbTripleTrainerBattle(trainerID1, trainerName1, trainerPartyID1, endSpeech1,
                          trainerID2, trainerName2, trainerPartyID2, endSpeech2,
                          trainerID3, trainerName3, trainerPartyID3=0, endSpeech3=nil,
                          canLose=false, outcomeVar=1,recorded=false)
###Yumil - 17 - NPC Reaction - End
  # Set some battle rules
  setBattleRule("outcomeVar",outcomeVar) if outcomeVar!=1
  setBattleRule("canLose") if canLose
  setBattleRule("triple")
  # Perform the battle
  ###Yumil - 18 - NPC Reaction - Begin
  decision = pbTrainerBattleCore(
     [trainerID1,trainerName1,trainerPartyID1,endSpeech1],
     [trainerID2,trainerName2,trainerPartyID2,endSpeech2],
     [trainerID3,trainerName3,trainerPartyID3,endSpeech3],recorded
  )
  ###Yumil - 18 - NPC Reaction - End
  # Return true if the player won the battle, and false if any other result
  return (decision==1)
end

=begin
class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    if SaveData.exists?
      @save_data = load_save_file(SaveData::FILE_PATH)
    else
      @save_data = {}
    end
    ###Yumil - 19 - NPC Reaction - Begin
		$NPCReactions = load_data("Data/npcreactions.dat") if !$NPCReactions
		###Yumil - 19 - NPC Reaction - End
  end
end

module Compiler
def compile_all(mustCompile)
    FileLineData.clear
    if (!$INEDITOR || Settings::LANGUAGES.length < 2) && safeExists?("Data/messages.dat")
      MessageTypes.loadMessageFile("Data/messages.dat")
    end
    if mustCompile
      echoln _INTL("*** Starting full compile ***")
      echoln ""
      yield(_INTL("Compiling town map data"))
      compile_town_map               # No dependencies
      yield(_INTL("Compiling map connection data"))
      compile_connections            # No dependencies
      yield(_INTL("Compiling phone data"))
      compile_phone
      yield(_INTL("Compiling type data"))
      compile_types                  # No dependencies
      yield(_INTL("Compiling ability data"))
      compile_abilities              # No dependencies
      yield(_INTL("Compiling move data"))
      compile_moves                  # Depends on Type
      yield(_INTL("Compiling item data"))
      compile_items                  # Depends on Move
      yield(_INTL("Compiling berry plant data"))
      compile_berry_plants           # Depends on Item
      yield(_INTL("Compiling Pokémon data"))
      compile_pokemon                # Depends on Move, Item, Type, Ability
      yield(_INTL("Compiling Pokémon forms data"))
      compile_pokemon_forms          # Depends on Species, Move, Item, Type, Ability
      yield(_INTL("Compiling machine data"))
      compile_move_compatibilities   # Depends on Species, Move
      yield(_INTL("Compiling shadow moveset data"))
      compile_shadow_movesets        # Depends on Species, Move
      yield(_INTL("Compiling Regional Dexes"))
      compile_regional_dexes         # Depends on Species
      yield(_INTL("Compiling ribbon data"))
      compile_ribbons                # No dependencies
      yield(_INTL("Compiling encounter data"))
      compile_encounters             # Depends on Species
      yield(_INTL("Compiling Trainer type data"))
      compile_trainer_types          # No dependencies
      yield(_INTL("Compiling Trainer data"))
      compile_trainers               # Depends on Species, Item, Move
      yield(_INTL("Compiling battle Trainer data"))
      compile_trainer_lists          # Depends on TrainerType
      yield(_INTL("Compiling metadata"))
      compile_metadata               # Depends on TrainerType
      yield(_INTL("Compiling animations"))
      compile_animations
      yield(_INTL("Converting events"))
      compile_trainer_events(mustCompile)
      ###Yumil -- 20 -- NPC REACTIONS -- BEGIN
      yield(_INTL("Compiling NPC Reactions"))
      pbCompileNPCReactions
      ###Yumil -- 20 -- NPC REACTIONS -- END
      yield(_INTL("Saving messages"))
      pbSetTextMessages
      MessageTypes.saveMessages
      echoln ""
      echoln _INTL("*** Finished full compile ***")
      echoln ""
      System.reload_cache
    end
    pbSetWindowText(nil)
  end
  
  def main
    return if !$DEBUG
    begin
      dataFiles = [
         "berry_plants.dat",
         "encounters.dat",
         "form2species.dat",
         "items.dat",
         "map_connections.dat",
         "metadata.dat",
         "moves.dat",
         "phone.dat",
         "regional_dexes.dat",
         "ribbons.dat",
         "shadow_movesets.dat",
         "species.dat",
         "species_eggmoves.dat",
         "species_evolutions.dat",
         "species_metrics.dat",
         "species_movesets.dat",
         "tm.dat",
         "town_map.dat",
         "trainer_lists.dat",
         "trainer_types.dat",
         "trainers.dat",
         ###Yumil - 21 - NPC Reaction - Begin
         "npcreactions.dat",
         ###Yumil - 21 - NPC Reaction - End
         "types.dat"
      ]
      textFiles = [
         "abilities.txt",
         "berryplants.txt",
         "connections.txt",
         "encounters.txt",
         "items.txt",
         "metadata.txt",
         "moves.txt",
         "phone.txt",
         "pokemon.txt",
         "pokemonforms.txt",
         "regionaldexes.txt",
         "ribbons.txt",
         "shadowmoves.txt",
         "townmap.txt",
         "trainerlists.txt",
         "trainers.txt",
         "trainertypes.txt",
          ###Yumil - 22 - NPC Reaction - Begin
         "npcreactions.txt",
          ###Yumil - 22 - NPC Reaction - End
         "types.txt"
      ]
      latestDataTime = 0
      latestTextTime = 0
      mustCompile = false
      # Should recompile if new maps were imported
      mustCompile |= import_new_maps
      # If no PBS file, create one and fill it, then recompile
      if !safeIsDirectory?("PBS")
        Dir.mkdir("PBS") rescue nil
        write_all
        mustCompile = true
      end
      # Check data files and PBS files, and recompile if any PBS file was edited
      # more recently than the data files were last created
      dataFiles.each do |filename|
        next if !safeExists?("Data/" + filename)
        begin
          File.open("Data/#{filename}") { |file|
            latestDataTime = [latestDataTime, file.mtime.to_i].max
          }
        rescue SystemCallError
          mustCompile = true
        end
      end
      textFiles.each do |filename|
        next if !safeExists?("PBS/" + filename)
        begin
          File.open("PBS/#{filename}") { |file|
            latestTextTime = [latestTextTime, file.mtime.to_i].max
          }
        rescue SystemCallError
        end
      end
      mustCompile |= (latestTextTime >= latestDataTime)
      # Should recompile if holding Ctrl
      Input.update
      mustCompile = true if Input.press?(Input::CTRL)
      # Delete old data files in preparation for recompiling
      if mustCompile
        for i in 0...dataFiles.length
          begin
            File.delete("Data/#{dataFiles[i]}") if safeExists?("Data/#{dataFiles[i]}")
          rescue SystemCallError
          end
        end
      end
      # Recompile all data
      compile_all(mustCompile) { |msg| pbSetWindowText(msg); echoln(msg) }
    rescue Exception
      e = $!
      raise e if "#{e.class}"=="Reset" || e.is_a?(Reset) || e.is_a?(SystemExit)
      pbPrintException(e)
      for i in 0...dataFiles.length
        begin
          File.delete("Data/#{dataFiles[i]}")
        rescue SystemCallError
        end
      end
      raise Reset.new if e.is_a?(Hangup)
      loop do
        Graphics.update
      end
    end
  end
end

module Compiler
  ###Yumil -- 23 -- NPC REACTIONS -- BEGIN
	def pbCompileNPCReactions
	  sections = {}
	  if File.exists?("PBS/npcreactions.txt")
		file = File.open("PBS/npcreactions.txt", "r") 
		file_data = file.read
		section = {}
		mainkey = nil
		subkey = nil
		content = []
		file_data.each_line {|line|		
		  if line.chomp == "#-------------------"
			if section != {} || mainkey !=nil
			  section.store(subkey, content)
			  sections.store(mainkey, section)
			  subkey = nil
			  content = []
			end
		  section = {}
		  mainkey = nil
		  subkey = nil
		  content = []
		  elsif (section=={} && mainkey ==nil)
			mainkey = line.chomp
		  elsif (subkey ==nil)
			subkey = line.chomp
		  elsif (line.chomp=="")
			section.store(subkey, content)
			subkey = nil
			content = []
		  elsif(line[0..1]=="##")
			
		  else
			content << line.chomp
		  end
		}
	  save_data(sections,"Data/npcreactions.dat")
	  $NPCReactions = sections
	  end
	end
	###-- Yumil -- 23 -- NPC REACTIONS -- END
end
=end
def pbSave(safesave = false)
  Deprecation.warn_method('pbSave', 'Game.save', 'v20')
  Game.save(safe: safesave)
end

def pbEmergencySave
  oldscene = $scene
  $scene = nil
  pbMessage(_INTL("The script is taking too long. The game will restart."))
  return if !$Trainer
  if SaveData.exists?
    File.open(SaveData::FILE_PATH, 'rb') do |r|
      File.open(SaveData::FILE_PATH + '.bak', 'wb') do |w|
        while s = r.read(4096)
          w.write s
        end
      end
    end
  end
  if Game.save
    pbMessage(_INTL("\\se[]The game was saved.\\me[GUI save game] The previous save file has been backed up.\\wtnp[30]"))
  else
    pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
  end
  $scene = oldscene
end


class PokemonSave_Scene
  def pbStartScreen
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites={}
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    mapname=$game_map.name
    time=_ISPRINTF("{1:02d}:{2:02d}",hour,min)
    datenow=_ISPRINTF("{2:d} {1:s} {3:d}",
    pbGetAbbrevMonthName($PokemonGlobal.pbGetTimeNow.mon),
    $PokemonGlobal.pbGetTimeNow.day,
    $PokemonGlobal.pbGetTimeNow.year)
    @sprites["bg"]=IconSprite.new(0,0,@viewport)
    if BGSTYLE==0
      @sprites["bg"].setBitmap("Graphics/Pictures/Save/bw_background")
    elsif BGSTYLE==1
      @sprites["bg"].setBitmap("Graphics/Pictures/Save/bw2_background")
    end  
    # Creating Party Icons.
    if $Trainer
      if $Trainer.party.length>0
        for i in 0...$Trainer.party.length
          @sprites["pokemon#{i}"]=PokemonIconSprite.new($Trainer.party[i],@viewport)
          @sprites["pokemon#{i}"].x = 64+64*(i)
          @sprites["pokemon#{i}"].y = 122
        end
      end
    end
    @sprites["overlay"]=BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    bwbaseColor    = Color.new(80,80,88)
    bwshadowColor  = Color.new(160,160,168)
    bw2baseColor   = Color.new(231,231,231)
    bw2shadowColor = Color.new(140,140,140)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    textos=[]
    if CLOCK==true
      if BGSTYLE==0
        textos.push([_ISPRINTF("{1:02d} : {2:02d}", Time.now.hour, Time.now.min),256,-2,2,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("Badges: {1}",$Trainer.numbadges),48,197,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("Pokédex: {1}", $Trainer.pokedexSeen),256,197,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("{1}",$game_map.name),48,82,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("Time: {1}", time),48,227,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("{1}", datenow),46,50,false,bwbaseColor,bwshadowColor])
        pbDrawTextPositions(overlay,textos)
      elsif BGSTYLE==1
        textos.push([_ISPRINTF("{1:02d} : {2:02d}", Time.now.hour, Time.now.min),256,-2,2,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("Badges: {1}",$Trainer.numbadges),48,197,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("Pokédex: {1}", $Trainer.pokedexSeen),256,197,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("{1}",$game_map.name),48,82,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("Time: {1}", time),48,227,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("{1}", datenow),46,50,false,bw2baseColor,bw2shadowColor])
        pbDrawTextPositions(overlay,textos)
      end
    elsif CLOCK==false
      if BGSTYLE==0
        textos.push([_INTL("Badges: {1}",$Trainer.numbadges),48,197,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("Pokédex: {1}", $Trainer.pokedexSeen),256,197,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("{1}",$game_map.name),48,82,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("Time: {1}", time),48,227,false,bwbaseColor,bwshadowColor])
        textos.push([_INTL("{1}", datenow),46,50,false,bwbaseColor,bwshadowColor])
        pbDrawTextPositions(overlay,textos)
      elsif BGSTYLE==1
        textos.push([_INTL("Badges: {1}",$Trainer.numbadges),48,197,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("Pokédex: {1}", $Trainer.pokedexSeen),256,197,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("{1}",$game_map.name),48,82,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("Time: {1}", time),48,227,false,bw2baseColor,bw2shadowColor])
        textos.push([_INTL("{1}", datenow),46,50,false,bw2baseColor,bw2shadowColor])
        pbDrawTextPositions(overlay,textos)
      end
    end
  end

  def pbGetTimeNow
    return Time.now
  end

  def pbEndScreen
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonSaveScreen
  def initialize(scene)
    @scene=scene
  end

  def pbDisplay(text,brief=false)
    @scene.pbDisplay(text,brief)
  end

  def pbDisplayPaused(text)
    @scene.pbDisplayPaused(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  def pbSaveScreen
    ret=false
    @scene.pbStartScreen
    if pbConfirmMessage(_INTL("Would you like to save the game?"))
#    if pbConfirmMessageSystemModern(0,false,_INTL("Would you like to save the game?"))
      if safeExists?(RTP.getSaveFileName("Game.rxdata"))
        if $PokemonTemp.begunNewGame
          pbMessage(_INTL("WARNING!"))
          pbMessage(_INTL("There is a different game file that is already saved."))
          pbMessage(_INTL("If you save now, the other file's adventure, including items and Pokémon, will be entirely lost."))
          if !pbConfirmMessageSerious(
             _INTL("Are you sure you want to save now and overwrite the other save file?"))
            pbSEPlay("GUI save choice")
            @scene.pbEndScreen
            return false
          end
        end
      end
      $PokemonTemp.begunNewGame=false
      pbSEPlay("GUI save choice")
      if pbSave
        pbMessage(_INTL("\\se[]{1} saved the game.\\me[GUI save game]\\wtnp[30]",$Trainer.name))
        ret=true
      else
        pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
        ret=false
      end
    else
      pbSEPlay("GUI save choice")
    end
    @scene.pbEndScreen
    return ret
  end
end



def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  ret = screen.pbSaveScreen
  return ret
end
#-------------------------------------------------------------------------------
# Stat Down/Up Animation by bo4p5687 
# Graphics by LDEJRuff
#-------------------------------------------------------------------------------
# 8 animations, each stat has one animation
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
class StatAnimation
	# Set SE (sound effect) when animation is running
	# File SE put in 'Audio\SE'
	SE_PLAY = "Battle ball drop"

	def initialize(pokemon, statname, sin, vp, time = 15, scrollvalue = 7, opavalue = 17, dir = "Graphics/Pictures/Stats Animation")
		@sprites = {}
		@viewport = vp
		@sprites["image"] = BitmapWrapper.new(Graphics.width,Graphics.height)
		@sprites["stat"] = Sprite.new(@viewport)
		@sprites["stat"].bitmap = Bitmap.new("#{dir}/#{sin}")
		@sprites["stat"].visible = false
		@sprites["scroll"] = Sprite.new(@viewport)
		@sprites["scroll"].bitmap = Bitmap.new(Graphics.width,Graphics.height)
		@sprites["scroll"].opacity = 0
		@moved = 0
		# Animated
		pkmn = pokemon.bitmap
		maxw = self.widthBitmap(pkmn)
		maxh = self.heightBitmap(pkmn)
		left = self.widthLeftRight(pkmn)
		top  = self.heightTopBot(pkmn)
		time.times {
			# Update
			self.update_ingame
			statname=="StatDown" ? self.scroll(2, scrollvalue, opavalue, true, maxw, maxh, left, top, pokemon) : self.scroll(8, scrollvalue, opavalue, true, maxw, maxh, left, top, pokemon)
			@moved += 1
		}
		pbSEPlay(SE_PLAY)
		time.times {
			# Update
			self.update_ingame
			statname=="StatDown" ? self.scroll(2, scrollvalue, opavalue, false, maxw, maxh, left, top, pokemon) : self.scroll(8, scrollvalue, opavalue, false, maxw, maxh, left, top, pokemon)
			@moved += 1
		}
		self.endScene
	end
	# Scroll bitmap
	def scroll(dir, value, opavalue, opaplus = false, maxw = nil, maxh = nil, left = nil, top = nil, pokemon=nil)
		pkmn = pokemon.bitmap
		bitmap = @sprites["scroll"].bitmap
		bitmap.clear
		(0...pkmn.width).each { |i|
			(0...pkmn.height).each { |j|
				if pkmn.get_pixel(i,j).alpha > 0
					x = pokemon.x + i - pkmn.width/2
					y = pokemon.y + j - pkmn.height
					minw = i - left
					minh = j - top
					case dir
					when 8 # Up
						srcx = minw
						srcy = minh + @moved * value
						if srcy > maxh * 2 - 1
							@moved = 0
							srcy = minh
						end
					when 2 # Down
						srcx = minw
						srcy = minh + maxh - @moved * value
						if srcy < minh
							@moved = 0
							srcy = minh + maxh
						end
					when 4 # Left
						srcx = minw + maxw - @moved * value
						if srcx < minw
							@moved = 0
							srcx = minw + maxw
						end
						srcy = minh
					when 6 # Right
						srcx = minw + @moved * value
						if srcx > maxw * 2 - 1
							@moved = 0
							srcx = minw
						end
						srcy = minh
					end
					bitmap.blt( x, y, @sprites["stat"].bitmap, Rect.new( srcx, srcy, 1, 1 ) )
				end
			}
		}
		opaplus ? (@sprites["scroll"].opacity += opavalue) : (@sprites["scroll"].opacity -= opavalue)
		if @sprites["scroll"].opacity > 255
			@sprites["scroll"].opacity = 255
		elsif @sprites["scroll"].opacity < 0
			@sprites["scroll"].opacity = 0
		end
	end
	# Check pokemon bitmap
	# Height
	def heightTopBot(bitmap,bottom=false)
		return 0 if !bitmap
		if bottom
			(1..bitmap.height).each { |i|
				(0..bitmap.width-1).each { |j|
					return bitmap.height-i+1 if bitmap.get_pixel(j,bitmap.height-i).alpha>0
				} 
			}
		else
			h = []; min = bitmap.height
			(1..bitmap.height).each { |i| 
				(0..bitmap.width-1).each { |j|
					h << bitmap.height-i if bitmap.get_pixel(j,bitmap.height-i).alpha>0
				} 
			}
			return h.min
		end
		return 0
	end
	def heightBitmap(bitmap)
		return self.heightTopBot(bitmap,true) - self.heightTopBot(bitmap)
	end
	# Width
	def widthLeftRight(bitmap,right=false)
		return 0 if !bitmap
		if right
			(1..bitmap.width).each { |i|
				(0..bitmap.height-1).each { |j|
					return bitmap.width-i+1 if bitmap.get_pixel(bitmap.width-i,j).alpha>0
				} 
			}
		else
			w = []; min = bitmap.width
			(1..bitmap.width).each { |i| 
				(0..bitmap.height-1).each { |j|
					w << bitmap.width-i if bitmap.get_pixel(bitmap.width-i,j).alpha>0
				} 
			}
			return w.min
		end
		return 0
	end
	def widthBitmap(bitmap)
		return self.widthLeftRight(bitmap,true) - self.widthLeftRight(bitmap)
	end
#------------------------------------------------------------------------------#
	# Update
	def update_ingame
		Graphics.update
		pbUpdateSpriteHash(@sprites)
	end
	# End
	def endScene
		# Dipose sprites
		pbDisposeSpriteHash(@sprites)
	end
end
class PokeBattle_Scene
	alias old_common_anim pbCommonAnimation
	def pbCommonAnimationStat(animName,sin,user=nil,target=nil)
		if !user.nil? && (animName=="StatDown" || animName=="StatUp")
			# Viewport
			@vp2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @vp2.z = 99999
			@vp3 = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @vp3.z = @vp2.z + 1
			# Set new viewport
			@sprites["cmdBar_bg"].viewport = @vp3
			@sprites["messageBox"].viewport = @vp3
			@sprites["messageWindow"].viewport = @vp3
			2.times { |i| @sprites["abilityBar_#{i}"].viewport = @vp3 if PokeBattle_SceneConstants::USE_ABILITY_SPLASH }
			@battle.battlers.each_with_index { |b, i|
				next if !b
				@sprites["dataBox_#{i}"].viewport = @vp3
				@sprites["dataBox_#{i}"].update_viewport_on_bar(@vp3)
			}
			# Set viewport of pokemon's bitmap
			index = user.index
			3.times { |i|
				if index.even?
					next if i * 2 <= index
					battler = @battle.battlers[i*2]
					next unless battler
					next unless battler && !battler.fainted?
					@sprites["pokemon_#{i*2}"].viewport = @vp2
				else
					next if 1 + i * 2 >= index
					battler = @battle.battlers[1+i*2]
					next unless battler
					next unless battler && !battler.fainted?
					@sprites["pokemon_#{1+i*2}"].viewport = @vp2
				end
			}
			# Create animation
			StatAnimation.new(@sprites["pokemon_#{index}"], animName, sin, @vp2)
			# Set viewport of pokemon's bitmap
			3.times { |i|
				if index.even?
					next if i * 2 <= index
					battler = @battle.battlers[i*2]
					next unless battler
					next unless battler && !battler.fainted?
					@sprites["pokemon_#{i*2}"].viewport = @viewport
				else
					next if 1 + i * 2 >= index
					battler = @battle.battlers[1+i*2]
					next unless battler
					next unless battler && !battler.fainted?
					@sprites["pokemon_#{1+i*2}"].viewport = @viewport
				end
			}
			# Reset
			@sprites["cmdBar_bg"].viewport = @viewport
			@sprites["cmdBar_bg"].z = 180
			@sprites["messageBox"].viewport = @viewport
			@sprites["messageBox"].z = 195
			@sprites["messageWindow"].viewport = @viewport
			@sprites["messageWindow"].z = 200
			2.times { |i| @sprites["abilityBar_#{i}"].viewport = @viewport if PokeBattle_SceneConstants::USE_ABILITY_SPLASH }
			@battle.battlers.each_with_index { |b, i|
				next if !b
				@sprites["dataBox_#{i}"].viewport = @viewport
				@sprites["dataBox_#{i}"].update_viewport_on_bar(@viewport)
			}
			# Dispose
			@vp2.dispose
			@vp3.dispose
			return
		end
		old_common_anim(animName,user,target)
	end
end
class PokeBattle_Battle
	def pbCommonAnimationStat(name,sin=nil,user=nil,targets=nil)
		@scene.pbCommonAnimationStat(name,sin,user,targets) if @showAnims
	end
end
class PokemonDataBox
	def update_viewport_on_bar(vp)
		@sprites["hpNumbers"].viewport = vp
		@sprites["hpBar"].viewport = vp
		@sprites["expBar"].viewport = vp
	end
end
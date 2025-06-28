pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--pocket tactics
--calvin pavlidis

function _init()
	level = 0
	max_level = 6
	li = 1
	music(0,1000,1)
 tile = 16
	palt(14,true)
	palt(0,false)
	state = {"idle",
	"attack",
	"special",
	"move",
	"dead",
	"damaged"}
	actions = {{a="move",y=0},
	{a="attack",y=0},
	{a="special",y=0},
	{a="end",y=0}}	
	ai = 1
	arrow = {x=0,y=0}
	pi=1
	moveable_space=false
	s_start = 0
	active_enemy_i = 1
	new_level(0,0)
end

function _update()
	get_s_sprite()
	get_a_sprite()
	get_sorc_sprite()
	get_es_sprite()
	get_ea_sprite()
	get_e_sorc_sprite()
	next_level_title()
	if slash_animation then
		get_slash_sprites()
	end
	ani_cursor()
	crsr_x_bind = crsr.x
	crsr_y_bind = crsr.y
	if menu_closed then
		if not game_over then
			ai = 1
		else
			ai = 2
		end
		option = {}
		arrow.y = 0
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
			if (level_title) or not active_player return
			if (btnp(0)) crsr.x -= 16
			if (btnp(1))	crsr.x += 16 
			if (btnp(2))	crsr.y -= 16 
			if (btnp(3)) crsr.y += 16 
			sfx(4,-1)
			if crsr.x < cam.x or crsr.x > (cam.x + 127) then
				crsr.x = crsr_x_bind
			end
			if crsr.y < cam.y or crsr.y > (cam.y + 127) then
				crsr.y = crsr_y_bind
			end 
			char_select(crsr.x,crsr.y)
			attack_range(active_char.x,active_char.y)
			if not setting_move and char_select(crsr.x,crsr.y) then
				find_moveable_spaces(active_char.x,active_char.y,active_char.movement)
			end
			if setting_move and can_move(crsr.x,crsr.y) then
				if not move_cost[crsr.x..','..crsr.y] then
					moveable_space=false
					return
				elseif move_cost[crsr.x..','..crsr.y]>char_movement then
					moveable_space=false
					return
				else
					a_star(active_char.x,active_char.y,crsr.x,crsr.y)
					assign_dir(closed)
					attack_range(crsr.x,crsr.y)
				end
			end
			
		end
		if (btnp(🅾️)) setting_move = false setting_attack = false setting_special = false sfx(6,-1)
	
	else
		if btnp(2) then
			if (ai != 1 and not game_over) or (game_over and ai!=2) then
		 	ai-=1
		 else
		 	if game_over then
		 		ai = #fail_message
		 	else
		  	ai = #actions
		  end
		 end 
			sfx(5,-1)
		end
		if btnp(3) then
			if (ai != #actions and not game_over) or (fail_message and (ai!=#fail_message and game_over)) then
				ai+=1
			else
				if game_over then
					ai = 2
				else
			 	ai = 1
			 end
			end 
			
			sfx(5,-1)
		end
		if not game_over then
			arrow.x = s_start + #actions[ai].a*4
			arrow.y = actions[ai].y 
		else
			arrow.x = s_start + #fail_message[ai].a*4
			arrow.y = fail_message[ai].y
		end
		if (btnp(🅾️)) menu_closed = true sfx(6)
	end
	if btnp(❎) then
		if game_over then
	 	if arrow.y == fail_message[2].y then
				if level == max_level and #active_heroes > 0 then
					extcmd("shutdown")
				else
					level -= 1
					new_level(map_pos.x,map_pos.y)
					game_over = false
					menu_closed = true
				end
			elseif arrow.y == fail_message[3].y then
				extcmd("shutdown")
			end
		end
	 if char_select(crsr.x,crsr.y) and not setting_move then
	  if menu_closed then
		  menu_closed=false 
		  sfx(5,-1)	
		 else
		 	sfx(5,-1)
		 	if arrow.y == actions[1].y then
		 		if active_char.moves > 0 then
		 			set_move()
		 			menu_closed = true
		 		else
		 			sfx(7,-1)
		 		end
		 	elseif arrow.y == actions[2].y then
		 		if active_char.attacks > 0 and #attack_targets >0 then
			 		set_attack()
			 		menu_closed = true
			 	else
			 		sfx(7,-1)
		 		end
		 	elseif arrow.y == actions[3].y then
		 		if active_char.attacks > 0 and active_char.specials > 0 then
			 		set_special()
			 		menu_closed = true
			 	else
			 		sfx(7,-1)
		 		end
		 	elseif arrow.y == actions[4].y then
		 		if active_player then
		 			active_player = false
		 			menu_closed = true
		 			for hero in all(active_heroes) do
			 			hero.moves = 1
			 			hero.attacks = 1
		 			end
		 			active_char = active_enemies[active_enemy_i]
		 			move_enemy(active_char)
		 		end
		 	end
		 end	
	 elseif setting_move then
  	if moveable_space then
	  	setting_move=false
	  	menu_closed = true
		 	active_char.moves -= 1
	  	move()
	  else
  	 sfx(7,-1)
  	end
	 elseif setting_attack then
	 	if in_range(crsr.x,crsr.y) then
	 		menu_closed = true	
	 		setting_attack=false 		
	 		if setting_special then
	 			setting_special=false
	 			special()
	 		else
	 			attack()
	 		end
	 	else
  	 sfx(7,-1)
  	end
  end
	end	
end

function _draw()
	cls()
	camera(cam.x,cam.y)
	map(map_pos.x,map_pos.y)
	if active_player and char_select(crsr.x,crsr.y) and active_char.action == state[1] or setting_move or setting_attack then
 	if not setting_attack or not setting_special then
	 	for space in all(queue) do
		 	sspr(16,80,16,16,space.x,space.y)
		 end
		end
	 for space in all(attack_targets) do
	 	sspr(80,80,16,16,space.x,space.y)
	 end
	 if setting_move and moveable_space then
	 	for arrow in all(closed) do
	 		print_arrow(arrow.x,arrow.y,arrow.d)			
			end
		else
			spr(177,crsr.x+4,crsr.y+4)
		end
 end
 get_s_colours()
 sspr(soldier.p_x,soldier.p_y,16,16,soldier.x,
 soldier.y,16,16,soldier.x_flip,soldier.y_flip)
 reset_col()
 get_a_colour()
 sspr(archer.p_x,archer.p_y,16,16,archer.x,archer.y,16,16,archer.x_flip,archer.y_flip)
 reset_col()
 get_sorc_colour()
 sspr(sorcerer.p_x,sorcerer.p_y,16,16,sorcerer.x,sorcerer.y,16,16,sorcerer.x_flip,sorcerer.y_flip)
 reset_col()
 get_enemy_soldier_col()
 sspr(enemy_soldier.p_x,enemy_soldier.p_y,16,16,enemy_soldier.x,enemy_soldier.y,16,16,enemy_soldier.x_flip,enemy_soldier.y_flip)
 reset_col()
 get_enemy_archer_col()
 sspr(enemy_archer.p_x,enemy_archer.p_y,16,16,enemy_archer.x,enemy_archer.y,16,16,enemy_archer.x_flip,enemy_archer.y_flip)
	reset_col()
	get_enemy_sorcerer_col()
	sspr(enemy_sorcerer.p_x,enemy_sorcerer.p_y,16,16,enemy_sorcerer.x,enemy_sorcerer.y,16,16,enemy_sorcerer.x_flip,enemy_sorcerer.y_flip)
 reset_col()
 if active_player and (char_select(crsr.x,crsr.y) or enemy_selected(crsr.x,crsr.y)) and menu_closed and active_player and not setting_move and active_char.action==state[1] and not attacking() then
  if setting_attack then
  	if enemy_selected(crsr.x,crsr.y) and indexof(crsr.x,crsr.y,attack_targets) then
	  	local character_stats = {{a=ne.name},
		  {a="hp: "..ne.hp.." >>> "..ne.hp-ceil(active_char.attack/ne.tb)},
		  {a="attack: "..ne.attack},
		  {a="range: "..ne.range},
		  {a="tb: "..ne.tb}}
		  menu_box(character_stats)
  	end
  else
	  local character_stats = {{a=active_char.name},
	  {a="hp: "..active_char.hp},
	  {a="attack: "..active_char.attack},
	  {a="range: "..active_char.range},
	  {a="tb: "..active_char.tb}}
	  menu_box(character_stats)
 	end
 end
 if (not menu_closed and not game_over) menu_box(actions)
 if #active_heroes < 1 or game_over then
 	fail_message = {{a="you lose",y=0},
 	{a="restart level",y=0},
 	{a="quit",y=0}}
 	if (level == max_level and #active_heroes > 0) del(fail_message,fail_message[2]) fail_message[1].a = "you finished the game!" crsr.x=0
 	menu_box(fail_message)
 	menu_closed = false
 	if (arrow.y==fail_message[1].y) arrow.y=fail_message[2].y ai=2
 	game_over = true
 end
 if active_player or game_over then
	 if menu_closed then
	 	if active_char.action == state[1] and not level_title then
	 		sspr(crsr.sx,crsr.sy,16,16,crsr.x,
	 crsr.y,16,16)
	 	end
	 else
	 	spr(148,arrow.x,arrow.y)
	 end
	end
 local cx = crsr.x
 local cy = crsr.y
 if slash_animation then
 	for char in all(slash_chars) do
 		sspr(ssp[char].x,ssp[char].y,16,16,ssp[char].px,ssp[char].py)
 	end
 end
 if screen_flash then
 	rectfill(cam.x,cam.y,cam.x+127,cam.y+127,7)
		sfx(0,-1)
		flash_screen()
	end
 if #active_enemies < 1 and not game_over then
 	if (level == max_level) game_over = true return
 	level_str = {{a="victory"}}
 	crsr.x = 80
 	crsr.y = 64
 	menu_closed = true
 	level_title = true
 	if (li == 59) new_level(map_pos.x+16,0) li=1
 end
 
 if level_title then
 	menu_box(level_str)
 end
end

function reset_col()
	pal()
 palt(14,true)
	palt(0,false)
end

function next_level_title()
	if not level_title then
		return
	end	
	if li == 60 then
		li = 1
		level_title=false
	else
		li+=1
	end
end
		
-->8
--animations
		
function attack()
	slash_sprites = {}
 active_char.action = state[2]
 active_char.i = 0
 active_char.ani_frame = 0
 active_char.ani_spd = 4
 active_char.attacks -= 1
	menu_closed = true
	updating_dmg = true
end

function move()
 if active_char.action != state[4] then
	 active_char.action = state[4]
	 active_char.i = 0
	 active_char.ani_frame = 0
	 active_char.ani_spd = 5
	 pi = 1
	end
end

function set_special()
	setting_special = true
	setting_attack = true
end

function special()
	slash_sprites = {}
 active_char.action = state[3]
 active_char.i = 1
 active_char.ani_frame = 0
 active_char.ani_spd = 2
 active_char.specials = 0
 active_char.attacks = 0
 menu_closed = true
 updating_dmg = true
end

function set_attack()
	setting_attack = true
end

function set_move()
 char_movement = active_char.movement
	a_star(active_char.x,active_char.y,crsr.x,crsr.y)
	setting_move=true	
end

function attacking()
	for character in all(active_heroes) do
		if character.action == state[2] or character.action == state[3] then
			return true
		end
	end
	return false
end

function inflict_dmg(char)
	if char.tb > 1 then
		char.hp -= ceil(active_char.attack/2)
	else
		char.hp -= active_char.attack
	end
 if char.hp < 1 then
 	char.i = 1
 	char.action = state[5]
 else
 	slash_ani(char)
 	char.action = state[1]
 	attacking_player = false
 end
 updating_dmg = false
end

function kill_character(char)
	if char.i == 25 then
	 if enemy_selected(char.x,char.y) then
 		del(active_enemies,char)
 	else
 		del(active_heroes,char)
 		if #active_heroes == 0 then
				active_enemy_i = #active_enemies
			end
 	end
 	attacking_player = false
		char.x = -20
		char.y = -20
		char.i = 1
		char.action = state[1]
	elseif char.i == 1 then
		sfx(22,-1)
		char.i += 1
	else
		char.i += 1
	end
end

function move_animation(char)
	if char.ani_frame != char.ani_spd then				
			char.ani_frame += 1	
	else		
		char.ani_frame = 0	
		if char.i >1 then	
			char.i=1
			sfx(1,-1)
		else	
			char.i += 1
			sfx(2,-1)
		end	
		char.p_x = char.move[char.i].x	
		char.p_y = char.move[char.i].y			
		move_char(active_char,closed)	
	end		
end

function idle_animation(char)
	char.ani_spd = 4		
	if char.ani_frame != char.ani_spd then		
		char.ani_frame += 1	
	else		
		char.ani_frame = 0	
		if (char.i == 3 and (char == archer or char == soldier or char == enemy_soldier or char == enemy_archer)) or (char.i==2 and (char==sorcerer or char==enemy_sorcerer)) then	
			char.i = 1
			if not running_function and not active_player and not attacking_player and active_char == char then	
				end_move()
			end	
		else	
			char.i += 1
		end	
			char.p_x = char.idle[char.i].x	
			char.p_y = char.idle[char.i].y	
	end				
end

function damage_animation(char)
	if char.ani_frame != char.ani_spd then				
		char.ani_frame += 1
	else
		char.ani_frame = 1
		if char.i >= 2 then
			if char.x_flip then
				char.x -= 3
			else
				char.x += 3
			end
			char.i = 1
			inflict_dmg(char)
		else
			if char.x_flip then
				char.x += 3
			else
				char.x -= 3
			end
			char.i += 1
		end
	end
end
			
function update_dmg_states(char)
	char.i=1	
	if char.action == state[3] then
		for enemy in all(attack_targets) do
			updating_dmg = true
			enemy_selected(enemy.x,enemy.y)
			ne.action = state[6]
			ne.i = 1
		end
	else
		ne.action = state[6]
		ne.i = 1	
	end
	char.action = state[1]
end	
	
function slash_ani(char)
	add(slash_chars,char.name)
	slash_animation = true
	slash[char.name] = {i=1,spd=2}
	slash_sprites[char.name]={{x=72,y=16,px=ne.x,py=ne.y},
	{x=88,y=16,px=char.x,py=char.y},
	{x=104,y=16,px=char.x,py=char.y},
	{x=104,y=16,px=char.x,py=char.y}}
end

function get_slash_sprites()
	for char in all(slash_chars) do		
		ssp[char] = {x=slash_sprites[char][slash[char].i].x,		
		y=slash_sprites[char][slash[char].i].y,		
		px=slash_sprites[char][slash[char].i].px,		
		py=slash_sprites[char][slash[char].i].py}		
		slash[char].spd -= 1		
		if slash[char].spd < 1 then		
			slash[char].spd = 2
			slash[char].i += 1	
			if slash[char].i == 5 then	
				slash[char].i = 1
				slash_animation = false
				flash_screen()
			end	
		end		
	end
end					

function flash_screen()
	if slash[slash_chars[1]].i == 1 then
		screen_flash = true
		slash[slash_chars[1]].i += 1
	else	
		screen_flash = false
		slash[slash_chars[1]].i = 1
	end
end

function set_slash_arrs()
	slash = {}
	slash_sprites = {}
	ssp = {}
	slash_chars = {}
end
	
-->8
--ui

function get_cursor()
	crsr = {x=start_pos[1].x,
	y=start_pos[1].y,sx=112,sy=64}
	c_spd = 2
	c_frame = 0
	ci = 1
	c_frames = {{x=112,y=64},
	{x=112, y=80},
	{x=96,y=80},
	{x=112, y=80}}
end 

function ani_cursor()
	if c_frame != c_spd then
			c_frame += 1
	else
		c_frame = 0
		if ci == 4 then
		 ci = 1
		else
			ci += 1
		end
		crsr.sx = c_frames[ci].x
		crsr.sy = c_frames[ci].y
	end
end

function char_select(x,y)
	if setting_attack or updating_dmg then
		return
	end
	if x == soldier.x and y == soldier.y then
		if not setting_move then
			if active_player then
				active_char = soldier
			else
				ne = soldier
			end
		else
			moveable_space = false
		end
		return true
	elseif x == archer.x and y == archer.y then
		if not setting_move then
			if active_player then
				active_char = archer
			else
				ne = archer
			end
		else
			moveable_space = false
		end
		return true
	elseif x == sorcerer.x and y == sorcerer.y then			
		if not setting_move then	
			if active_player then
				active_char = sorcerer
			else
				ne = sorcerer
			end
		else	
			moveable_space = false
		end	
		return true	
	elseif x == enemy_soldier.x and y == enemy_soldier.y then
		if not setting_move and active_player then
			active_char = enemy_soldier
		else
			moveable_space = false
		end
		if active_player then
			return false
		else
			return true
		end
	elseif x == enemy_archer.x and y == enemy_archer.y then
		if not setting_move and active_player then
			active_char = enemy_archer
		else
			moveable_space = false
		end
		if active_player then
			return false
		else
			return true
		end
	elseif x == enemy_sorcerer.x and y == enemy_sorcerer.y then
		if not setting_move and active_player then
			active_char = enemy_sorcerer
		else
			moveable_space = false
		end
		if active_player then
			return false
		else
			return true
		end
	else
		return false
	end
	nearest_enemy()
end

function enemy_selected(x,y)
	if x == enemy_soldier.x and y == enemy_soldier.y then
		if not active_player or setting_attack or updating_dmg then
			ne = enemy_soldier
			nearest_enemy()
		end
		return true
	elseif x == enemy_archer.x and y == enemy_archer.y then
		if not active_player or setting_attack or updating_dmg then
			ne = enemy_archer
			nearest_enemy()
		end
		return true
	elseif x == enemy_sorcerer.x and y == enemy_sorcerer.y then
		if not active_player or setting_attack or updating_dmg then
			ne = enemy_sorcerer
			nearest_enemy()
		end
		return true
	else
		return false
	end
end

function print_box(i,box_w,box_h)
	local bs = {{s="mid",x=24,y=72,xf=false,yf=false},
 {s="top l",x=0,y=80,xf=false,yf=false},
 {s="left", x=0,y=88,xf=false,yf=false},
 {s="right",x=0,y=88,xf=true,yf=false},
 {s="top r",x=0,y=80,xf=true,yf=false},
 {s="bottom l",x=0,y=80,xf=false,yf=true},
 {s="bottom r",x=0,y=80,xf=true,yf=true},
 {s="bottom",x=8,y=80,xf=false,yf=true},
 {s="top",x=8,y=80,xf=false,yf=false}}
 
 sspr(bs[i].x,bs[i].y,8,8,box_w,box_h,8,8,bs[i].xf,bs[i].yf)
end

function menu_box(arr)
	local cam = camera()+63
	local max_char = 0
	local middle = 1
	local top_left = 2
	local left = 3
	local right = 4
	local top_right = 5
	local bottom_left = 6
	local bottom_right = 7
	local bottom = 8
	local top = 9
	for x=1,#arr do
		if #arr[x].a > max_char then
			max_char = #arr[x].a
		end 
	end
	local w = max_char/1.7
	local box_w = crsr.x
	local spr_h = 0
	local spr_w = 0
	local s_reset = 0
	local menu_w = 0
	
	if crsr.y > cam then
		spr_h = -8
		s_reset = crsr.y - 8
	else
		spr_h = 8
		s_reset = crsr.y + 8
	end
	
	if crsr.x > cam then
		spr_w = -8
		s_start = crsr.x-max_char*4
	else
		spr_w = 8
		s_start=crsr.x+8
	end

	local box_h = s_reset
	--print first corner box corresponding with cursor pos
	if crsr.y > cam and crsr.x < cam then
		print_box(bottom_left,box_w,box_h)
	elseif crsr.y > cam and crsr.x > cam then
		print_box(bottom_right,box_w,box_h)
	elseif crsr.y < cam and crsr.x > cam then
		print_box(top_right,box_w,box_h)
	elseif crsr.y < cam and crsr.x < cam then
		print_box(top_left,box_w,box_h)
	end
	box_h += spr_h
	--print first side of box
	for x=1,#arr do
		if crsr.x < cam then
		 print_box(left,box_w,box_h)
		else
			print_box(right,box_w,box_h)
		end
		box_h += spr_h
	end
	--print the opposite corner on the same same (left or right)
	if crsr.y > cam and crsr.x < cam then
		print_box(top_left,box_w,box_h)
	elseif crsr.y > cam and crsr.x > cam then
		print_box(top_right,box_w,box_h)
	elseif crsr.y < cam and crsr.x > cam then
		print_box(bottom_right,box_w,box_h)
	elseif crsr.y < cam and crsr.x < cam then
		print_box(bottom_left,box_w,box_h)
	end
	box_h = s_reset
	--along the width,fill in the middle sprites
	for x=1,w do
		box_w += spr_w
		if crsr.y > cam then
			print_box(bottom,box_w,box_h)
		else
			print_box(top,box_w,box_h)
		end
		box_h += spr_h
		if crsr.y > cam then
			for x=#arr,1,-1 do
			 	print_box(middle,box_w,box_h)
			 	if active_char.moves < 1 and arr[x].a == "move" then
				 	print(arr[x].a,s_start,box_h,13)
					elseif active_char.attacks < 1 and arr[x].a == "attack" then
						print(arr[x].a,s_start,box_h,13)
					elseif arr[x].a == "special" and (active_char.specials < 1 or active_char.attacks < 1) then
						print(arr[x].a,s_start,box_h,13)
					else
					 print(arr[x].a,s_start,box_h,1)
					end
			 	arr[x].y = box_h-2
			 	if arrow.y == 0 and x==1 then
			 		arrow.y = box_h-2
			 		arrow.x = s_start + #arr[1].a*4
			 		menu_w = box_w
			 	end
			 	box_h += spr_h
			 end
		else
		 for x=1,#arr do
		 	print_box(middle,box_w,box_h)
		 	if active_char.moves < 1 and arr[x].a == "move" then
			 	print(arr[x].a,s_start,box_h,13)
				elseif active_char.attacks < 1 and arr[x].a == "attack" then
						print(arr[x].a,s_start,box_h,13)
					elseif arr[x].a == "special" and (active_char.specials < 1 or active_char.attacks < 1) then
						print(arr[x].a,s_start,box_h,13)
					else
					 print(arr[x].a,s_start,box_h,1)
					end
		 	arr[x].y = box_h-2
		 	if arrow.y == 0 and x==1 then
		 		arrow.y = box_h-2
		 		arrow.x = s_start + #arr[1].a*4
		 		menu_w = box_w - (#arr*4)
		 	end
		 	box_h += spr_h
		 end
		end
		if crsr.y > cam then
		 print_box(top,box_w,box_h)
		else
			print_box(bottom,box_w,box_h)
		end 
	 box_h = s_reset
	end	
	box_w += spr_w
	if crsr.y > cam and crsr.x < cam then
		print_box(bottom_right,box_w,box_h)
	elseif crsr.y > cam and crsr.x > cam then
		print_box(bottom_left,box_w,box_h)
	elseif crsr.y < cam and crsr.x > cam then
		print_box(top_left,box_w,box_h)
	elseif crsr.y < cam and crsr.x < cam then
		print_box(top_right,box_w,box_h)
	end
	box_h += spr_h
	for x=1,#arr do
		if crsr.x < cam then
		 print_box(right,box_w,box_h)
		else
			print_box(left,box_w,box_h)
		end
		box_h += spr_h
	end
	if crsr.y > cam and crsr.x < cam then
		print_box(top_right,box_w,box_h)
	elseif crsr.y > cam and crsr.x > cam then
		print_box(top_left,box_w,box_h)
	elseif crsr.y < cam and crsr.x > cam then
		print_box(bottom_left,box_w,box_h)
	elseif crsr.y < cam and crsr.x < cam then
		print_box(bottom_right,box_w,box_h)
	end
end

function print_arrow(x,y,i)
	local ad = {{d="up",x=64,y=80,posx=x,posy=y,xf=false,yf=true,s=16},
	{d="down",x=64,y=80,posx=x,posy=y,xf=false,xy=false,s=16},
	{d="left",x=32,y=80,posx=x,posy=y,xf=true,xy=false,s=16},
	{d="right",x=32,y=80,posx=x,posy=y,xf=false,xy=false,s=16},
	{d="up_left",x=48,y=80,posx=x,posy=y,xf=false,yf=false,s=16},
	{d="up_right",x=48,y=80,posx=x,posy=y,xf=true,yf=false,s=16},
	{d="down_left",x=48,y=80,posx=x,posy=y,xf=false,yf=true,s=16},
	{d="down_right",x=48,y=80,posx=x,posy=y,xf=true,yf=true,s=16},
	{d="up_end",x=40,y=72,posx=x+4,posy=y+8,xf=false,yf=true,s=8},
	{d="down_end",x=40,y=72,posx=x+4,posy=y,xf=false,yf=false,s=8},
	{d="left_end",x=32,y=72,posx=x+8,posy=y+4,xf=false,yf=false,s=8},
	{d="right_end",x=32,y=72,posx=x,posy=y+4,xf=true,yf=false,s=8}}
	
	
	sspr(ad[i].x,ad[i].y,ad[i].s,ad[i].s,ad[i].posx,ad[i].posy,ad[i].s,ad[i].s,ad[i].xf,ad[i].yf)
end



function seq_arrows(first,prev,current)
	if not prev then
		current.d=9
	elseif not first then
		if current.x==prev.x and current.y<prev.y then
			current.d=9
			prev.d=1
		elseif current.x==prev.x and current.y>prev.y then
			current.d=10
			prev.d=2
		elseif current.y==prev.y and current.x<prev.x then
			current.d=11
			prev.d=3
		elseif current.y==prev.y and current.x>prev.x then
			current.d=12
			prev.d=4
		end
	else
		if current.x==prev.x and current.y<prev.y and first.x==prev.x and first.y>prev.y then
			current.d=9
			prev.d=1
		elseif current.x==prev.x and current.y>prev.y and first.x==prev.x and first.y<prev.y then
			current.d=10
			prev.d=2
		elseif current.y==prev.y and current.x<prev.x and first.y==prev.y and prev.x<first.x then
			current.d=11
			prev.d=3
		elseif current.y==prev.y and current.x>prev.x and first.y==prev.y and prev.x>first.x then
			current.d=12
			prev.d=4
		elseif first.x==prev.x and first.y<prev.y and current.y==prev.y and current.x<prev.x then
			current.d=11
			prev.d=7
		elseif first.x==prev.x and first.y<prev.y and current.y==prev.y and current.x>prev.x then
			current.d=12
			prev.d=8
		elseif first.x==prev.x and first.y>prev.y and current.y==prev.y and current.x<prev.x then
			current.d=11
			prev.d=5
		elseif first.x==prev.x and first.y>prev.y and current.y==prev.y and current.x>prev.x then
			current.d=12
			prev.d=6
		elseif first.x>prev.x and first.y==prev.y and current.y>prev.y and current.x==prev.x then
			current.d=10
			prev.d=6
		elseif first.x>prev.x and first.y==prev.y and current.y<prev.y and current.x==prev.x then
			current.d=9
			prev.d=8
		elseif first.x<prev.x and first.y==prev.y and current.y<prev.y and current.x==prev.x then
			current.d=9
			prev.d=7
		elseif first.x<prev.x and first.y==prev.y and current.y>prev.y and current.x==prev.x then
			current.d=10
			prev.d=5
		end
	end
end

function assign_dir(arr)
	for x=1,#arr do
	 	seq_arrows(arr[x-2],arr[x-1],arr[x])
	end
end	

function attack_range(cx,cy)
	if setting_attack or updating_dmg then
		return
	end
	range_spaces = {}
	attack_targets = {}
	local up = {x=cx,y=cy}
	local down = {x=cx,y=cy}	
	local left = {x=cx,y=cy}
	local right = {x=cx,y=cy}
	for x=1, active_char.range do
		up={x=up.x,y=up.y-tile}
		add(range_spaces,up)
		down={x=down.x,y=down.y+tile}
		add(range_spaces,down)
		left={x=left.x-tile,y=left.y}
		add(range_spaces,left)
		right={x=right.x+tile,y=right.y}
		add(range_spaces,right)
	end
	for space in all(range_spaces) do
		if active_player then
			if indexof(space.x,space.y,active_enemies) then
				add(attack_targets,space)
			end
		else 
			if indexof(space.x,space.y,active_heroes) then
				add(attack_targets,space)
			end
		end
	end
end	
-->8
--pathfinding

function find_moveable_spaces(x,y,m)
	queue = {{x=x,y=y}}
	local open = {}
	local start = {x=x,y=y}
	local current = start
	came_from = {}
	came_from[start.x..','..start.y]=start
	move_cost = {}
	move_cost[start.x..','..start.y]=0
	local neighbour = {{x=x-16,y=y},
	{x=x+16,y=y},
	{x=x,y=y-16},
	{x=x,y=y+16}}
	while current.y < y+(m*tile) do
		local c = current.x..','..current.y
	 for space in all(neighbour) do
	  if can_move(space.x,space.y) and not indexof(space.x,space.y,queue) and not indexof(space.x,space.y,open) then 
	   local i = space.x..','..space.y
	   if not came_from[i] then
	   	came_from[i] = current
	  	elseif move_cost[c]<move_cost[came_from[i].x..','..came_from[i].y] then
		  	came_from[i] = current
		  end
	  	if not move_cost[i] then
	  		move_cost[i] = move_cost[c]+get_move_cost(space.x,space.y)
				elseif move_cost[c]+get_move_cost(space.x,space.y)<move_cost[i] then
					move_cost[i] = move_cost[c]+get_move_cost(space.x,space.y)
	  	end
	  	add(open,space)
	  end
	 end
	 current = open[1]
	 if current then
		 if not indexof(current.x,current.y,queue) then
			 if move_cost[current.x..','..current.y]<m+1 then
			 	add(queue,current)
			 end
			end
		else
			return
		end
	 if not active_player then
	 	if char_select(current.x,current.y) or #active_heroes < 1 then
	 		if ne.action != state[5] or #active_heroes < 1 then
	 			return
	 		end
	 	end
	 end
	 neighbour={}
	 add(neighbour,{x=current.x-16,y=current.y})
	 add(neighbour,{x=current.x,y=current.y-16})
	 add(neighbour,{x=current.x+16,y=current.y})
	 add(neighbour,{x=current.x,y=current.y+16})
	 del(open,current)
	end
end

function a_star(ox,oy,gx,gy)
	moveable_space=true
	closed = {}
	local current = {x=gx,y=gy}
	local start = {x=ox,y=oy}
	while get_astar(current.x,current.y,start.x,start.y)>=1 do
		add(closed, {x=current.x,y=current.y,d=1},1)
		current = came_from[current.x..','..current.y]
		print(#closed,1,80,0)
		if not current then
			break
		end
	end
	if active_player then
		add(closed,{x=ox,y=oy,d=1},1)
	else
		deli(closed)
	end
end

function move_char(char,path)
	if #closed > 0 then
		if pi == #closed then
	 	char.x = path[pi].x
	 	char.y = path[pi].y
	 	char.action = state[1]
	 	char.tb=get_move_cost(char.x,char.y)
	 	pi = 1
			attack_range(char.x,char.y)
			nearest_enemy()
			find_moveable_spaces(char.x,char.y,char.movement)
	 	if not active_player then
	 		enemy_attack()
	 	end
	 else
	 	char.x = path[pi].x
	 	char.y = path[pi].y
	  pi += 1
	 end
 else
 	char.action = state[1]
 	pi = 1
		attack_range(char.x,char.y)
 	if not active_player then
 		enemy_attack()
 	end
 end
end

function can_move(x,y)
	moveable_space = false
	local mx = (x/8)+map_pos.x
	local my = (y/8)+map_pos.y
	if not fget(mget(mx,my),0) then
		if active_player then
				return true
		else
			if not indexof(x,y,active_enemies) and not out_of_bounds(x,y) then 
				return true
			end
		end
	else
		return false
	end
end



function get_astar(sx,sy,x,y)
	local sx_val = abs(sx-x)/tile
	local sy_val = abs(sy-y)/tile
	local astar = sx_val + sy_val
	return astar
end

function indexof(x,y,arr)
	for space in all(arr) do
		if space.x == x and space.y == y then
			return true
		end
	end
	return false
end

function get_move_cost(x,y)
	local mx = x/8+map_pos.x
	local my = y/8+map_pos.y
	if fget(mget(mx,my),1) then
		return 2
	else
		return 1
	end
end

function out_of_bounds(x,y)
	local tile_pos = {x=x,y=y}
	local start_boundary = {x=cam.x,y=cam.y}
	local end_boundary = {x=cam.x+127,y=cam.y+127}
	if tile_pos.x<start_boundary.x or tile_pos.x > end_boundary.x or tile_pos.y<start_boundary.y or tile_pos.y>end_boundary.y then
		return true
	else
		return false
	end
end
-->8
--enemy soldier

function get_enemy_soldier()
	enemy_soldier = {x=e_start_pos[1].x,
	y=e_start_pos[1].y,
	x_flip=true,
	y_flip=false,
	movement=3,
	action=state[1],
	i=0,
	ani_frame=0,
	ani_spd=3,
	ani_loop=0,
	range=1,
	hp=22,
	attack=16,
	tb=1,
	moves=1,
	attacks=1,
	name="enemy soldier",
	move=soldier.move,
	idle=soldier.idle,
	p_x=0,
	p_y=0}
end

function get_enemy_soldier_col()
	enemy_col=pal({[13]=0,[12]=8,[6]=13})
	if enemy_soldier.action == state[5] then
		if enemy_soldier.i > 10 then
			palt(0,true)
			enemy_col=pal({[13]=8,[12]=8,[6]=8,[4]=8,[15]=8,[7]=8})
		else
			enemy_col=pal({[13]=8,[12]=8,[6]=8,[0]=8,[4]=8,[15]=8,[7]=8})
		end
	end
end

function get_es_sprite()						
	if enemy_soldier.action == state[1] then					
		idle_animation(enemy_soldier)
	elseif enemy_soldier.action == state[2] then					
		soldier_attack(enemy_soldier)
	elseif enemy_soldier.action == state[4] then					
		move_animation(enemy_soldier)
	elseif enemy_soldier.action == state[3] then					
		soldier_special(enemy_soldier)				
	elseif enemy_soldier.action == state[5] then
		kill_character(enemy_soldier)
	elseif enemy_soldier.action == state[6] then				
		damage_animation(enemy_soldier)
	end
end						
-->8
--archer

function get_archer()
	archer = {x=start_pos[2].x,
	y=start_pos[2].y,
	x_flip=false,
	y_flip=false,
	movement=3,
	action=state[1],
	i=0,
	ani_frame=0,
	ani_spd=2,
	ani_loop=0,
	range=2,
	hp=20,
	attack=12,
	tb=1,
	moves=1,
	attacks=1,
	specials=1,
	name="archer",
	p_x=0,
	p_y=0,
	idle = {{sprite=1,x=0,y=32},
	{sprite=2,x=16,y=32},
	{sprite=3,x=32,y=32}},
	move = {{sprite=1,x=48,y=32},
	{sprite=2,x=64,y=32}}}
	a_attack = {{sprite=1,x=0,y=32},
	{sprite=2,x=80,y=32},
	{sprite=3,x=96,y=32}}
end

function get_a_colour()
	if archer.action == state[5] then						
		if archer.i > 10 then				
			palt(0,true)			
			col=pal({[15]=8,[4]=8,[3]=8,[5]=8,[9]=8,[6]=8,[7]=8})			
		else				
			col=pal({[15]=8,[4]=8,[3]=8,[5]=8,[9]=8,[6]=8,[7]=8,[0]=8})			
		end				
	end	
end

function get_a_sprite()						
	if archer.action == state[1] then					
		idle_animation(archer)	
	elseif archer.action == state[2] then					
		archer_attack(archer,7)
	elseif archer.action == state[4] then					
		move_animation(archer)
	elseif archer.action == state[3] then					
		archer_attack(archer,10)
	elseif archer.action == state[5] then
		kill_character(archer)
	elseif archer.action == state[6] then						
		damage_animation(archer)	
	end
end										

function archer_attack(char,s)
	char.ani_spd = s			
	if char.ani_frame != char.ani_spd then			
		char.ani_frame += 1		
	else			
		char.ani_frame = 0		
		if char.i == 3 then		
			set_slash_arrs()
			update_dmg_states(char)
		elseif char.i == 1 then		
			if s==7 then
				sfx(13,-1)	
			else
				sfx(24,-1)
			end
			char.i += 1	
		else		
			if (char.ani_loop == 3 and char.i==2) or s ==7 then
				char.i += 1 
				char.ani_loop = 0
			else
				char.ani_loop += 1
			end	
		end		
		char.p_x = a_attack[char.i].x		
		char.p_y = a_attack[char.i].y
	end				
end					
-->8
--soldier

function get_soldier()
	soldier = {x=start_pos[1].x,
	y=start_pos[1].y,
	x_flip=false,
	y_flip=false,
	movement=3,
	action=state[1],
	i=0,
	ani_frame=0,
	ani_spd=3,
	ani_loop=0,
	moves=1,
	attacks=1,
	specials=1,
	range=1,
	hp=22,
	attack=16,
	tb=1,
	moves=1,
	name="soldier",
	p_x=0,
	p_y=0,
	idle = {{sprite=1,x=8,y=0},
	{sprite=2,x=24,y=0},
	{sprite=3,x=40,y=0}},
	move = {{sprite=1,x=8,y=16},
	{sprite=2,x=24,y=16}}}
	s_attack = {{sprite=1,x=56,y=0},
	{sprite=2,x=72,y=0},
	{sprite=3,x=88,y=0}}
	s_special= {{sprite=1,x=88,y=0,xf=false,yf=false},
	{sprite=2,x=56,y=16,xf=false,yf=false},
	{sprite=3,x=88,y=0,xf=true,yf=false},
	{sprite=4,x=40,y=16,xf=true,yf=false}}
	find_moveable_spaces(soldier.x,soldier.y,soldier.movement)
	--a_star(soldier.x,soldier.y,crsr.x,crsr.y)
end

function get_s_colours()
	if soldier.action == state[5] then					
		if soldier.i > 10 then			
			palt(0,true)		
			col=pal({[13]=8,[12]=8,[6]=8,[0]=8,[4]=8,[15]=8,[7]=8})		
		else			
			col=pal({[13]=8,[12]=8,[6]=8,[0]=8,[4]=8,[15]=8,[7]=8})		
		end							
	else					
		return				
	end			
end		

function get_s_sprite()						
	if soldier.action == state[1] then					
		idle_animation(soldier)	
	elseif soldier.action == state[2] then					
		soldier_attack(soldier)
	elseif soldier.action == state[4] then					
		move_animation(soldier)
	elseif soldier.action == state[3] then					
		soldier_special(soldier)
	elseif soldier.action == state[5] then		
		kill_character(soldier)
	elseif soldier.action == state[6] then								
		damage_animation(soldier)
	end
end						

--soldier animations

function soldier_attack(char)
	if char.ani_frame != char.ani_spd then					
			char.ani_frame += 1		
	else			
		char.ani_frame = 0		
		if char.i == 3 then
			set_slash_arrs()		
			update_dmg_states(char)
		elseif char.i == 1 then		
			sfx(0,-1)	
			char.i += 1	
		else		
			char.i += 1	
		end		
		char.p_x = s_attack[char.i].x		
		char.p_y = s_attack[char.i].y		
	end	
end		

function soldier_special(char)
	if char.ani_frame != char.ani_spd then						
		if (char.i ==1)	sfx(3,-1)	set_slash_arrs()		
			char.ani_frame += 1			
		else				
			char.ani_frame = 0			
			if char.i == 4 then			
				char.i=1		
				sfx(1,-1)		
				if char.ani_loop == 2 then		
					char.ani_loop = 0	
					update_dmg_states(active_char)
					char.action = state[1]	
					char.ani_spd = 4	
				else		
				char.ani_loop += 1		
				end		
			else			
				char.i += 1		
			end		
			char.p_x = s_special[char.i].x			
			char.p_y = s_special[char.i].y			
			char.x_flip = s_special[char.i].xf			
			char.y_flip = s_special[char.i].yf			
		end				
end
-->8
--enemy ai

function nearest_enemy()
	
	if ne.x<active_char.x then
		active_char.x_flip = true
		ne.x_flip = false
	else
		active_char.x_flip = false
		ne.x_flip = true
	end
end

function path_to_target()
	local max_steps_y = 12
	find_moveable_spaces(active_char.x,active_char.y,max_steps_y)
end

function limit_movement()
	local steps_removed = #closed-active_char.movement
	for x=1,steps_removed do
		deli(closed)
	end
end	

function move_enemy()
	path_to_target()
	a_star(active_char.x,active_char.y,ne.x,ne.y)
	limit_movement()
	nearest_enemy()
	if not in_range(ne.x,ne.y) then
		active_char.i = 0
		active_char.action = state[4]
	else
		enemy_attack()
	end
end

function enemy_attack()
	attacking_player = true
	if in_range(ne.x,ne.y) then
		active_char.i = 0
		active_char.action = state[2]
	else
		attacking_player = false
	end	
end

function end_move()
	running_function = true
	if #active_enemies>active_enemy_i then
		active_enemy_i += 1
		active_char = active_enemies[active_enemy_i]
		move_enemy()
	else		
		active_player = true
		active_enemy_i = 1
		char_select(crsr.x,crsr.y)
		find_moveable_spaces(active_char.x,active_char.y,active_char.movement)
		attack_range(active_char.x,active_char.y)
	end
	running_function = false
end

function in_range(x,y)
	attack_range(active_char.x,active_char.y)
	if indexof(x,y,attack_targets) then
		enemy_selected(x,y)
		return true
	else 
		return false
	end
end
-->8
--sorcerer									
									
function get_sorcerer()									
	sorcerer = {x=start_pos[3].x,								
	y=start_pos[3].y,								
	x_flip=false,								
	y_flip=false,								
	movement=3,								
	action=state[1],								
	i=0,								
	ani_frame=0,								
	ani_spd=5,								
	ani_loop=0,								
	range=3,
	hp=15,
	attack=14,
	tb=1,
	moves=1,
	attacks=1,
	specials=1,
	name="sorcerer",
	p_x=0,
	p_y=0,					
	idle = {{sprite=1,x=0,y=48},								
	{sprite=2,x=16,y=48}},
	move = {{sprite=1,x=16,y=48},								
	{sprite=2,x=112,y=48}}}						
	sorc_attack = {{sprite=1,x=32,y=48},								
	{sprite=2,x=48,y=48},								
	{sprite=3,x=64,y=48},								
	{sprite=4,x=48,y=48},								
	{sprite=5,x=64,y=48},								
	{sprite=6,x=80,y=48},								
	{sprite=7,x=96,y=48},								
	{sprite=8,x=80,y=48},								
	{sprite=9,x=96,y=48}}																				
end					

function get_sorc_colour()
	if sorcerer.action == state[5] then				
		if sorcerer.i > 10 then			
			palt(0,true)		
			col=pal({[15]=8,[4]=8,[3]=8,[5]=8,[9]=8,[7]=8,[6]=8})		
		else			
			col=pal({[15]=8,[4]=8,[3]=8,[5]=8,[9]=8,[7]=8,[6]=8,[0]=8})		
		end			
	end				
end				
									
function get_sorc_sprite()									
	if sorcerer.action == state[1] then								
		idle_animation(sorcerer)	
	elseif sorcerer.action == state[2] then								
		sorcerer_attack(sorcerer,4)	
	elseif sorcerer.action == state[4] then								
		move_animation(sorcerer)	
	elseif sorcerer.action == state[3] then								
		sorcerer_attack(sorcerer,8)		
	elseif sorcerer.action == state[5] then
		kill_character(sorcerer)
	elseif sorcerer.action == state[6] then	
		damage_animation(sorcerer)	
	end								
end									

--sorcerer animations

function sorcerer_attack(char,s)
	char.ani_spd = s		
if char.ani_frame != char.ani_spd then		
	char.ani_frame += 1	
else		
	char.ani_frame = 0	
	if char.i == 9 then	
		set_slash_arrs()
		update_dmg_states(char)	
	elseif char.i == 1 then	
		sfx(23,-1)
		char.i += 1
	else	
		char.i += 1
	end	
	char.p_x = sorc_attack[char.i].x	
	char.p_y = sorc_attack[char.i].y	
	end
end		

-->8
--enemy archer

function get_enemy_archer()								
	enemy_archer = {x=e_start_pos[2].x,							
	y=e_start_pos[2].y,							
	x_flip=true,							
	y_flip=false,							
	movement=4,							
	action=state[1],							
	i=0,							
	ani_frame=0,							
	ani_spd=2,							
	ani_loop=0,							
	range=2,
	hp=20,
	attack=12,
	tb=1,
	moves=1,
	attacks=1,
	name="enemy archer",
	move=archer.move,
	idle=archer.idle,
	p_x=0,
	p_y=0}							
end								

function get_enemy_archer_col()
	enemy_col=pal({[4]=8,[3]=1})
	if enemy_archer.action == state[5] then						
		if enemy_archer.i > 10 then				
			palt(0,true)			
			enemy_col=pal({[15]=8,[4]=8,[3]=8,[5]=8,[9]=8,[6]=8,[7]=8})			
		else				
			enemy_col=pal({[15]=8,[4]=8,[3]=8,[5]=8,[9]=8,[6]=8,[7]=8,[0]=8})			
		end				
	end					
end							
								
function get_ea_sprite()								
	if enemy_archer.action == state[1] then							
		idle_animation(enemy_archer)
	elseif enemy_archer.action == state[2] then							
		archer_attack(enemy_archer,7)	
	elseif enemy_archer.action == state[4] then							
		move_animation(enemy_archer)			
	elseif enemy_archer.action == state[3] then							
		archer_attack(enemy_archer,20)
	elseif enemy_archer.action == state[5] then		
		kill_character(enemy_archer)
	elseif enemy_archer.action == state[6] then										
		damage_animation(enemy_archer)
	end
end								
								
									
-->8
--enemy sorcerer

function get_enemy_sorcerer()							
	enemy_sorcerer = {x=e_start_pos[3].x,						
	y=e_start_pos[3].y,						
	x_flip=true,						
	y_flip=false,						
	movement=3,						
	action=state[1],						
	i=0,						
	ani_frame=0,						
	ani_spd=5,						
	ani_loop=0,						
	range=3,
	hp=15,
	attack=14,
	tb=1,
	moves=1,
	attacks=1,
	name="enemy sorcerer",
	move=sorcerer.move,
	idle=sorcerer.idle,
	p_x=0,
	p_y=0}						
end			

function get_enemy_sorcerer_col()
	enemy_col=pal({[4]=8,[2]=1,[12]=9,[8]=13})
	if enemy_sorcerer.action == state[5] then				
		if enemy_sorcerer.i > 10 then			
			palt(0,true)		
			enemy_col=pal({[4]=8,[2]=8,[12]=8,[8]=8,[15]=8,[5]=8,[6]=8})		
		else			
			enemy_col=pal({[4]=8,[2]=8,[12]=8,[8]=8,[15]=8,[5]=8,[6]=8,[0]=8})		
		end			
	end				
end				
							
function get_e_sorc_sprite()							
	if enemy_sorcerer.action == state[1] then						
		idle_animation(enemy_sorcerer)
	elseif enemy_sorcerer.action == state[2] then						
		sorcerer_attack(enemy_sorcerer,4)
	elseif enemy_sorcerer.action == state[4] then						
		move_animation(enemy_sorcerer)
	elseif enemy_sorcerer.action == state[3] then						
		sorcerer_attack(enemy_sorcerer,8)
	elseif enemy_sorcerer.action == state[5] then		
		kill_character(enemy_sorcerer)
	elseif enemy_sorcerer.action == state[6] then			
		damage_animation(enemy_sorcerer)						
	end
end							
-->8
--level manager

function new_level(mx,my)
 cam = {x=0,y=0}
 map_pos = {x=mx,y=my}
 start_pos ={}
 e_start_pos = {}
 get_starting_points()
 get_cursor()
	active_player=true
 crsr.x = cam.x+80
 crsr.y = cam.y+64
	get_soldier()
	get_archer()
	get_sorcerer()
	get_enemy_soldier()
	get_enemy_archer()
	get_enemy_sorcerer()
	menu_closed=true
	setting_move=false
	active_char=soldier
	active_heroes = {soldier,archer,sorcerer}
	active_enemies = {enemy_soldier,enemy_archer,enemy_sorcerer}
	attack_range(active_char.x,active_char.y)
	ne=enemy_soldier
	slash_chars = {}
	level += 1
	level_str ={{a="level "..level}}
	level_title = true
end

function get_starting_points()
	local mx = map_pos.x
	local my = map_pos.y
	local mxo = mx*8
	local myo = my*8
	for x=1,64 do
		if fget(mget(mx,my),2) then
			add(start_pos,{x=mx*8-mxo,y=my*8-myo})
		end
		if fget(mget(mx,my),3) then
			add(e_start_pos,{x=mx*8-mxo,y=my*8-myo})
		end
		my += 2
		if x/8 == ceil(x/8) then
			my = myo
			mx += 2
		end
	end
end

__gfx__
00000000eeeeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
00000000eeeeee00000eeeeeeeee0444440eeeeeeeeeee00000eeeeeeeee0444440eeeeeeeee00000eeeeeeeeeee00000eeeeeee000000000000000000000000
00700700eeeee0444440eeeeeee044fff40eeeeeeeeee0444440eeeeeee044fff40eeeeeeee0444440eeeeeeeee0444440eeeeee000000000000000000000000
00077000eeee044fff40eeeeeee04fcfcf0eeeeeeeee044fff40eeee0ee04fcfcf0eeeeeee04444f40eeeeeeee04444f40eeeeee000000000000000000000000
00077000eeee04fcfc40eeeeeee0ff0d0f0eeeeeeeee04fcfcf0eeee70e0ffffff0eeeeeee0444fcf7ee7eeeee0444fcf0eeeeee000000000000000000000000
00700700eeee0fff0df0eeeeeee0f0d70f0eeeeeeeee0f0d0ff0eeeed700ffffff0eeeeeee044ffff07ee7eeee044ffff0eeeeee000000000000000000000000
00000000eeee0ff0d7f000eeee0d0d7600000eeeeeee00d70ff0eeee0d70666600000eeeee0ffffff007ee7eee0ffffff00eeeee000000000000000000000000
00000000eee0060d7ddd660ee0d0d700ddd660eeeee0d07066660eeee0d70060ddd660eeee0d666000d07007ee0d666000d00000000000000000000000000000
00000000ee0d60d70ddd660ee0d67060ddd760eeee0d0d70600000eeee0d7d60ddd660eeee0d066660d77777ee0d066660d77777000000000000000000000000
00000000ee00dd700ddd660ee0d6d660ddd670eeee0dd7060ddd670eeed0d600ddd660eeee0d600000d00000ee0d600000d00000000000000000000000000000
00000000ee0d6d0660dd70eee0dd06660dd60eeeee0d6d660ddd660eee0d66060dd70eeeee0d660ddd00eeeeee0d660ddd00eeee000000000000000000000000
00000000ee0dd066660d0eeeee00d66660d0eeeeee0dd0660ddd660eeee0dd6660d0eeeeee0d660ddd60eeeeee0d660ddd60eeee000000000000000000000000
00000000eee00d666660eeeeee0d6600d60eeeeeeee00d6660dd60eeee0d6600d60eeeeee00d6660dd60eeeee00d6660dd60eeee000000000000000000000000
00000000ee0dd6600d60eeeeee0d60e0d60eeeeeee0dd6600d0d0eeeee0d60e0d60eeeee0d66600d0d0eeeee0d66600d0d0eeeee000000000000000000000000
00000000ee0d660e0d660eeeee0d60e0d660eeeeee0d660e0d60eeeeee0d60e0d660eeee0d660e0d600eeeee0d660e0d600eeeee000000000000000000000000
00000000eee000ee0000eeeeeee00eee000eeeeeeee0000ee000eeeeeee00eee000eeeeee000eee000eeeeeee000eee000eeeeee000000000000000000000000
00000000eeeeeee0000eeeeeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
00000000eeeeee044440eeeeeeeeee044440eeeeeeeeee00000eeeeeeeeeee00000eeeee7777eeeeeeeeeeee7777eeeeeeeeeeee7777eeeeeeeeeeee00000000
00000000eeeeee044ff0eeeeeeeeee044ff0eeeeeeeee0444440eeeeeeeee0444440eeeeee777eeeeeeeeeeeee777eeeeeeeeeeeee777eeeeeeeeeee00000000
00000000eeeeee04fcf0eeeeeeeeee04ffc0eeeeeeee04444440eeeeeeee044fff40eeeeeee777eeeeeeeeeeeee777eeeeeeeeeeeee777eeeeeeeeee00000000
00000000eeeeee0ffff0eeeeeeeeee0ffff0eeeeeeee04444440eeeeeeee04fcfcf0eeeeeeeeeeeeeeeeeeeeeee7777eeeeeeeeeeee7777eeeeeeeee00000000
00000000eeee000ffff0eeeeeeeeee0ffff00eeeeeee04444440eeeeeeee0ffffff0eeeeeeeeeeeeeeeeeeeeeeee7777eeeeeeeeeeee7777eeeeeeee00000000
00000000eeee0d666600000eeeeee0d6660670eeeeee0ffffff0eeeeeeee0ffffff0eeeeeeeeeeeeeeeeeeeeeeeee7777eeeeeeeeeeee7777eeeeeee00000000
00000000eee0d0dddd0dd60eeeeee0d6606700eeeee0d66666660eeeeee0d66006660eeeeeeeeeeeeeeeeeeeeeeeee7777eeeeeeeeeeee7777eeeeee00000000
00000000eee0d6777770d70eeeeee0d00670d0eeee0d6666666600eeee0d6606600000eeeeeeeeeeeeeeeeeeeeeeeee77eeeeeeeeeeeeee777eeeeee00000000
00000000eee0d6d000ddd60eeeeee0d60700d0eeee0d666666660d0eee0d6067760d670eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777eeeee00000000
00000000eee0dd06660dd60eeeeee0d66060d0eeee00066666660d0eee0d660660dd660eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777eeee00000000
00000000eeee00d60d60d0eeeeeee0d00000d0eeeee0d6666660dd0eeee0d0600ddd660eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777eee00000000
00000000eeee0d600d600eeeeeeeee0d60d00eeeeee0d6666660d0eeeee00d6660dd60eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77eee00000000
00000000eee0d60e0d60eeeeeeeeee0d6000eeeeee0d66600d0d0eeeee0dd6600d0d0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77ee00000000
00000000eee0d6600d660eeeeeeeee0d66d0eeeeee0d660e0d60eeeeee0d660e0d60eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7ee00000000
00000000eeee000ee000eeeeeeeeeee0000eeeeeeee0000ee000eeeeeee0000ee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7ee00000000
eeeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000eeeeeeeee
eeeee00000eeeeeeeee0333330eeeeeeeeeee00000eeeeeeeeee0333330eeeeeeeee0333330eeeeeeeeee00000eeeeeeeeeee00000eeeeeee011cc0ee000000e
eeee0333330eeeeeee033fff30eeeeeeeeee0333330eeeeeeee033fff30eeeeeeee033fff30eeeeeeeee03333300eeeeeeee03333300eeeee011cc0ee011cc0e
eee033fff30eeeeeee03f4f430ee0eeeeee033fff30eeeeeeee03f4f430eee0eeee03f4f430eee0eeee033fff3090eeeeee033fff3090eeeee01c0eee011cc0e
eee03f4f430eee0eee03ffff30e790eeeee03f4f430ee0eeeee03ffff30ee790eee03ffff30ee790eee03f4f470090eeeee03f4f430090eeee01c0eeee01c0ee
eee03ffff30ee790ee03ffff307090eeeee03ffff30e790eeee03ffff30e7090eee03ffff30e7090eee03fff730e090eeee03ffff37e090eeee00eeeee01c0ee
eee03ffff30e7090e013333337e090eeeee03ffff307090eee0133333337e090ee0133333337e09000e00ff7f30ee09e00e00ffff37ee09eeeeeeeeeeee00eee
ee0133333337e09001333300730990eeee013333337e090eee0133330070e990ee0133330070e990040550799999999604055033337e009eeeeeeeeeeeeeeeee
ee0133330070e9900544405503090eeee0133330070e990eee0444405500990eee0444405500990e040550333330509e040550333370509eeeeeeeee00000000
ee0444405500990e054440550050eeeee0544405500990eeee044440550050eeee044440550050ee000004744440009e000004444470009eeeeeeeee0111ccc0
ee044440550050ee000007000050eeeee054440550050eeeee000007000050eeee000007000050eeee0544474440090eee0544444470090ee000000e0111ccc0
ee000007000050eee0547000900eeeeee000007000050eeeeee0547000900eeeeee0547000900eeeee054444744090eeee054444447090eee011cc0e0111ccc0
ee05407000900eeee0509999040eeeeeee0547000900eeeeeee050999900eeeeeee050999900eeeeee05400057490eeeee05400054490eeee011cc0e0111ccc0
e05540999900eeeee0540ee0540eeeeee0554999900eeeeeee05440450eeeeeeeee05400540eeeeee05540e05470eeeee05540e05440eeeeee01c0eee011cc0e
e05440e05440eeeee0540ee05440eeeee05440e05440eeeeee044004440eeeeeeee054400540eeeee05440e05440eeeee05440e05440eeeeee01c0eeee01c0ee
ee000ee0000eeeeeee00eeee000eeeeeee0000e00000eeeeee000e00000eeeeeeee00000e000eeeeee000ee0000eeeeeee000ee0000eeeeeeee00eeeeee00eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7eeeeeeeeeeeee7eeeeeeeeeeeeeeeee7eeeeeeeeeeeee7eeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeee00000eeeeeeeeeee00000eeeceeeeeee00000e7eceeeeeee00000eeeceeeeeee00000e7eceeeeeee00000eeeceeeeeee00000eeeeee
eeeee00000eeeeeeeeee0666660eeecceeee0066660eccceeeee0066660eccceeeee0066660eccc7eeee0066660eccceeeee0066660eccc7eeee0066660eeeee
eeee0666660eeecceee066ffff0eeccceeee066fff0eccceeeee066fff0eccceeeee066fff0eccceeeee066fff0eccceeeee066fff0eccceeeee066fff0eeeee
eee066ffff0eeccceee06f4f4f0e00cceeee06ff4f0ee5eeeeee06ff4f0ee5eeeeee06ff4f0ee5eeeeee06ff4f0ee5eeeeee06ff4f0ee5eeeeee06ff4f0eeecc
eee06f4f4f0e00cceee0ffffff00440ceeee0fffff0e00eeeeee0fffff0e00eeeeee0fffff0e00eeeeee0fffff0e00eeeeee0fffff0e00eeeeee0fffff0eeccc
eee0ffffff00440ceee0ffffff05440eeeee0fffff00440eeeee0fff9aaa440eeeee0fffaa99440eeeee0fffff00440eeeee0fffff00440eeeee0fffff0e00cc
ee00ffffff05440eee028888885500eeeeee02800000440eeeee08800000940eeeee08800000a40eeeee088000099aaaeeee0880000a99aaeeee02888880440c
ee028888885500eee0288888855080eeeeee0288044000eeeeee08880440a0eeeeee08880440a0eeeeee08880440aa99eeee088804409aa9eeee02888885540e
e0288888855080eee028808855200eeeeeee02880440e5eeeeee08880440a5eeeeee0888044095eeeeee08880440aaaaeeee08880440aaaaeeee0280000500ee
e028808855200eeee02888055280eeeeeeee02880000e5eeeeee0888000095eeeeee0888000095eeeeee08880009999aeeee08880009a999eeee02880440eeee
e02888055280eeeeee0880442880eeeeeeee08000280e5eeeeee08000aa9e5eeeeee080009aae5eeeeee08000880e5eeeeee08000880e5eeeeee02880440eeee
ee0880442880eeeeee0000440880eeeeeeee08888880e5eeeeee08222880e5eeeeee08222880e5eeeeee08222880e5eeeeee08222880e5eeeeee08855000eeee
e00000440880eeeee02885500880eeeeeee028888880e5eeeee088888880e5eeeee088888880e5eeeee082288880e5eeeee082288880e5eeeee028552880eeee
e02885500880eeeee02855888880eeeeeee028888880e5eeeee088888880e5eeeee088888880e5eeeee088888880e5eeeee088888880e5eeeee025528880eeee
e00055000000eeeee00550000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeee055000000eeee
cccccccccccccccc0000000000000000000000000000000099999999cccccccccccccccccccccccccccccccccccccccc000000000000000088888eeeeee88888
cccccccccccccccc000000000000000000000000000000009aaaaaaacccccccccccccccccccccccccccccccccccccccc000000000000000088888eeeeee88888
cccccccccccccccc000000000000000000000000000000009aaaaaaacccccccccccccccccccccccccccccccccccccccc000000000000000088eeeeeeeeeeee88
cccccccccccccccc000000000000000000000000000000009aaa9aaacccccccccccccccccccccccccccccccccccccccc000000000000000088eeeeeeeeeeee88
cccccccccccccccc000000000000000000000000000000009aaa9aaacccccccccccccccccccccccccccccccccccccccc000000000000000088eeeeeeeeeeee88
cccccccccccccccc000000000000000000000000000000009aaa9aaacccccccccccccccccccccccccccccccccccccccc0000000000000000eeeeeeeeeeeeeeee
cccccccccccccccc000000000000000000000000000000009aaa9aaacccccccccccccccccccccccccccccccccccccccc0000000000000000eeeeeeeeeeeeeeee
cccccccccccccccc000000000000000000000000000000009aaa9aaa999999999999999999999999999999999ccccccc0000000000000000eeeeeeeeeeeeeeee
ccccccccccccccccccccccccaaaaaaaaeee8eeeeee8888ee9aaaaaaa9aaaaa9aaaaa9aa9aaaa9aaaaa9aaaaaaccccccc0000000000000000eeeeeeeeeeeeeeee
ccccccccccccccccccccccccaaaaaaaaee88eeeeee8888ee9aaaaaaa9aa9aa9aaaaa9aa9aaaa9aaaaa9aaaaaaccccccc0000000000000000eeeeeeeeeeeeeeee
ccccccccccccccccccccccccaaaaaaaae8888888ee8888ee9aaaaaaa9aa9aa9aaccc9aa9aaac9aa99ccc9aaccccccccc0000000000000000eeeeeeeeeeeeeeee
ccccccccccccccccccccccccaaaaaaaa88888888ee8888ee9aaacccc9aa9aa9aaccc9aaaaacc9aaaaccc9aaccccccccc000000000000000088eeeeeeeeeeee88
ccccccccccccccccccccccccaaaaaaaa88888888888888889aaacccc9aa9aa9aaccc9aaaaa9c9aaaaccc9aaccccccccc000000000000000088eeeeeeeeeeee88
ccccccccccccccccccccccccaaaaaaaae8888888e888888e9aaacccc9aa9aa9aa9999aa9aaa99aa999cc9aaccccccccc000000000000000088eeeeeeeeeeee88
ccccccccccccccccccccccccaaaaaaaaee88eeeeee8888ee9aaacccc9aa9aa9aaaaa9aa9aaaa9aaaaacc9aaccccccccc000000000000000088888eeeeee88888
ccccccccccccccccccccccccaaaaaaaaeee8eeeeeee88eee9aaacccc9aaaaa9aaaaa9aa9aaaa9aaaaacc9aaccccccccc000000000000000088888eeeeee88888
a999999999999999aeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
9aaaaaaaaaaaaaaaeaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeee8888eeeeee8888e
9aaaaaaaaaaaaaaaaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eee8888eeee8888eee8888eeeeee8888e
9aaaaaaaaaaaaaaaeaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8ee8888eeee8888eee88eeeeeeeeee88e
9aaaaaaaaaaaaaaaaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eee88eeeeeeee88eee88eeeeeeeeee88e
9aaaaaaaaaaaaaaaeaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8ee88eeeeeeee88eeeeeeeeeeeeeeeeee
9aaaaaaaaaaaaaaaaeaeaeaeaeaeaeae88888888888888888888888888eeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
9aaaaaaaaaaaaaaaeaeaeaeaeaeaeaea88888888888888888888888888eeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
9aaaaaaa88eeee88aeaeaeaeaeaeaeae88888888888888888888888888eeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
9aaaaaaa888ee888eaeaeaeaeaeaeaea88888888888888888888888888eeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
9aaaaaaae888888eaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeee8888eeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eee88eeeeeeee88eeeeeeeeeeeeeeeeee
9aaaaaaaee8888eeeaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeee8888eeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8ee88eeeeeeee88eee88eeeeeeeeee88e
9aaaaaaaee8888eeaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeee8888eeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eee8888eeee8888eee88eeeeeeeeee88e
9aaaaaaae888888eeaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeee8888eeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8ee8888eeee8888eee8888eeeeee8888e
9aaaaaaa888ee888aeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeeee8888eeeeeeeeeeee8888eeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeeee8888eeeeee8888e
9aaaaaaa88eeee88eaeaeaeaeaeaeaeaeeeeeeeeeeeeeeeeeeeeee8888eeeeeeeeeeee8888eeeeeee8e8e8e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bbbbbbbbbbbbbbbbbbbbbbb575bbbbbbccccccccccccccccc114444444444cccbbb555555b55555bccccccccccccccccccc67ccccccccccc0000000000000000
bbbbbbbbbbbbbbbb3bbbbb56775bbbbbcc7ccc7ccc7ccc7cc114999999999c7cb553333335333335cc7ccc7cccccccccccc67ccccccccccc0000000000000000
bbbbbbbbbbbbbbbb33bbb5677775bbb3c777ccccc777ccccc774999999999cccb533333333337733c777ccccccccccccccc67ccccccccccc0000000000000000
bbbbbbbbbbbbbbbb333b566777777b3349949949949949947114444444444cccb5333333333337357ccc7cccccccccccccc67ccccccccccc0000000000000000
bbb3bbbbbbbbbbbb333516677777d5334994994994994994c114999999999ccc5333333333333335cccccccccccccc7cccc67ccccccccccc0000000000000000
bb3b3bbbbbbbbbbb33515167776ddd534994994994994994c174999999999ccc5333335333533333cccccccccccc777ccccc7ccccccccccc0000000000000000
bbbbbbbbbbbbbbbb351515177dddddd54994994994994994c11444444444477cb535555333353335cc77777ccccccccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb31111111dddddddd4994994994994994c114999999999c7c5333333335333335cccccc7ccccccccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb51111111ddddd6dd4994994994994994c114999999999ccc555533335555535bcccccccccccccccccccccccccccccccc0000000000000000
bbbbbbbbbb3bbbbb11111111dddd6d6d4994994994994994c114444444444c7cbbb55555444bb5bbcccccccccccccccccccccccccccccccc0000000000000000
bbbbbbbbb3b3bbbb1115111dddd6dddd4994994994994994c714999999999cccbbbbbb54444bbbbbccccccccc7777ccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb1151511ddd6ddddd49949949949949947114999999999cccbb333354444bbbbbcccccccc77c77ccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb1151151dd6dddddd4444444444444444c114444444444cccb33333544444bbbbc777cccccccccccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb1511151ddddddddd1711111711171111c174999999999cccb33335444444bbbbccc7cccccccccccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb151111ddddddddddcc7777cccc7777ccc11499999999977cb3335444445444bbcccccccccccccccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb11111dddddddddddcccccc7ccccccc7cc114444444444c7cbbb34bbbbbb4bbbbcccccccccccccccccccccccccccccccc0000000000000000
bbbbbbbbbbbbbbbb3b33b3b333b3b333bbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3cc6666cccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcc6666cccccccccccccccccccccccccccccccccccccccccc
bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc66ccccccccccccccccccccccccccccccccccccccccccc
bb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc66ccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbb3bbbbbbbbbbbbccc66c677ccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbb3b3bbbbbbbbbbb666666677ccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb67c67ccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67c9999999999999999999999999999999999cccccccc
bbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67c9aaaaa9aaaaa9aaaaaa9aa9aaaaa9aaaaacccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbb3bbbbbccc67c9aa9aa9aaaaa9aaaaaa9aa9aaaaa9aaaaacccccccc
bbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbb3b3bbbbccc67c9aa9aa9aaccccc9aacc9aa9aaccc9aa9cccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67c9aa9aa9aaccccc9aacc9aa9aacccc9aa9ccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67c9aaaaa9aaccccc9aacc9aa9aaccccc9aa9cccccccc
3b33b3b333b3b333bbbbbbbbbbbbbbbb3b34444444444333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67c9aa9aa9aa999cc9aacc9aa9aa999999aaacccccccc
9999949999994999bbbbbbbbbbbbbbbb9554999999999499bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67c9aa9aa9aaaaacc9aacc9aa9aaaaa9aaaaacccccccc
9999999949999999bbbbbbbbbbbbbbbb9554999999999499bbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbccc67c9aa9aa9aaaaacc9aacc9aa9aaaaa9aaaaacccccccc
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaaaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaaaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaa9aaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaa9aaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaa9aaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaa9aaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaa9aaa999999999999999999999999999999999ccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaaaaaa9aaaaa9aaaaa9aa9aaaa9aaaaa9aaaaaaccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaaaaaa9aa9aa9aaaaa9aa9aaaa9aaaaa9aaaaaaccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaaaaaa9aa9aa9aaccc9aa9aaac9aa99ccc9aaccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaacccc9aa9aa9aaccc9aaaaacc9aaaaccc9aaccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaacccc9aa9aa9aaccc9aaaaa9c9aaaaccc9aaccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaacccc9aa9aa9aa9999aa9aaa99aa999cc9aaccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaacccc9aa9aa9aaaaa9aa9aaaa9aaaaacc9aaccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9aaacccc9aaaaa9aaaaa9aa9aaaa9aaaaacc9aaccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc6666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc6666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc66ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc66ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc66c677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc666666677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc67c67ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9999999999999999999999999999999999cccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aaaaa9aaaaa9aaaaaa9aa9aaaaa9aaaaacccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aa9aa9aaaaa9aaaaaa9aa9aaaaa9aaaaacccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aa9aa9aaccccc9aacc9aa9aaccc9aa9cccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aa9aa9aaccccc9aacc9aa9aacccc9aa9ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aaaaa9aaccccc9aacc9aa9aaccccc9aa9cccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aa9aa9aa999cc9aacc9aa9aa999999aaacccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aa9aa9aaaaacc9aacc9aa9aaaaa9aaaaacccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67c9aa9aa9aaaaacc9aacc9aa9aaaaa9aaaaacccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc67cccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cccccccccccc00000ccccc
ccccccccccccccccccccccccccccccccccccccccccc67ccccccccccccccccccccccccccccccccccccccccccccccccccccccc0444440ccccc99ccc0666660cccc
ccccccccccccccccccccccccccccccccccccccccccc67ccccccccccccccccccccccccccccccccccccccccccccccccccccccc04fff440cccc999cc0ffff660ccc
ccccccccccccccccccccccccccccccccccccccccccc67ccccccccccccccccccccccccccccccccccccccccccccccccccccccc0f8f8f40cccc9900c0f8f8f60ccc
cccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccc0ff000f0cccc908800ffffff0ccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0ff07000ccccc08850ffffff0ccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0dddd07000ccccc0055dddddd10cc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000d070000cccc0d055dddddd10c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07d0000d07000ccccc00155dd0dd10c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0dd0000dd0d00cccccc0d1550ddd10c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0dd0000dd0000cccccc0dd1880dd0cc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0d000ddd000ccccccc0dd0880000cc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000dd000cccccc0dd0055dd10c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0d00c0dd00cccccc0ddddd55d10c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000cc0000ccccccc00000005500c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc00000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccc
ccccccccccccccccccccc0444440ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0111110cccccccccccccccccccc
cccccccccccccccccccc044fff40ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc01fff110ccccccccccccccccccc
cccccccccccccccccccc04fcfcf0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0cc018f8f10ccccccccccccccccccc
cccccccccccccccccccc0f0d0ff0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc097c01ffff10ccccccccccccccccccc
cccccccccccccccccccc00d70ff0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc090701ffff10ccccccccccccccccccc
ccccccccccccccccccc0d07066660cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc090c711111110cccccccccccccccccc
cccccccccccccccccc0d0d70600000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc099c0700111110ccccccccccccccccc
cccccccccccccccccc0dd7060ddd670ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0990055088850ccccccccccccccccc
cccccccccccccccccc0d6d660ddd660cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc050055088850ccccccccccccccccc
cccccccccccccccccc0dd0660ddd660cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc050000700000ccccccccccccccccc
ccccccccccccccccccc00d6660dd60cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0090007850cccccccccccccccccc
cccccccccccccccccc0dd6600d0d0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0099998550ccccccccccccccccc
cccccccccccccccccc0d660c0d60cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc08850c08850ccccccccccccccccc
ccccccccccccccccccc0000cc000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000c0000cccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccc00000ccccccccccc00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc0333330ccccccccc0666660ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc033fff30cccccccc066ffff0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc03f4f430cc0ccccc06f4f4f0c00cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc03ffff30c790cccc0ffffff00440ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc03ffff307090cccc0ffffff05440ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccc013333337c090ccc028888885500cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc0133330070c990cc0288888855080cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc0544405500990ccc028808855200ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc054440550050cccc02888055280cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc000007000050ccccc0880442880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccc0547000900cccccc0000440880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc0554999900cccccc02885500880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc05440c05440ccccc02855888880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccc0000c00000ccccc00550000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202000000000202010100000000000002020000000002020101000000000000000000000404080800000000000000000000000004040808000000000000
__map__
c2c3c2c3c2c3c2c3c2c3c2c3c2c3c2c3c0c1c0c1c0c1cacbcacbc2c3c2c3c2c3c8c9e0e1c8c9e0e1e4e5e0e1e0e1c0c1c8c9c8c9c0c1c0c1c0c1c0c1c0c1c0c1c2c3c2c3c2c3c2c3c2c3c2c3c2c3c2c3c0c1cacbcacbcacbcacbcacbcacbc0c10000000000000000000000000000000000000000000000000000000000000000
d2d3d2d3d2d3d2d3d2d3d2d3d2d3d2d3d0d1d0d1d0d1dadbdadbd2d3d2d3d2d3d8d9f0f1d8d9f0f1f4f5f0f1f0f1d0d1d8d9d8d9d0d1d0d1d0d1d0d1d0d1d0d1d2d3d2d3d2d3d2d3d2d3d2d3d2d3d2d3d0d1dadbdadbdadbdadbdadbdadbd0d10000000000000000000000000000000000000000000000000000000000000000
c8c9c0c1e0e1e4e5e0e1e0e1c0c1c0c1e6e7c0c1c8c9cacbcacbc0c1c0c1c0c1e6e7cacbcacbcacbc6c7cacbcacbc0c1c8c9c8c9c0c1c0c1c0c1c0c1c0c1c0c1e6e7c0c1c0c1c0c1c0c1c0c1c0c1c0c1e6e7cacbcacbcacbcacbcacbcacbe8e90000000000000000000000000000000000000000000000000000000000000000
d8d9d0d1f0f1f4f5f0f1f0f1d0d1d0d1f6f7d0d1d8d9dadbdadbd0d1d0d1d0d1f6f7dadbdadbdadbd6d7dadbdadbd0d1d8d9d8d9d0d1d0d1d0d1d0d1d0d1d0d1f6f7d0d1d0d1d0d1d0d1d0d1d0d1d0d1f6f7dadbdadbdadbdadbdadbdadbf8f90000000000000000000000000000000000000000000000000000000000000000
c0c1c0c1cacbc6c7cacbcacbc0c1c0c1c0c1c0c1c0c1c4c5c4c5c0c1c0c1e8e9c8c9cacbe2e3e2e3e2e3e8e9cacbe8e9e6e7c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1e6e7c0c1c0c1c0c1c0c1c0c1c0c1e6e7c4c5c4c5c4c5c4c5c4c5c4c5e8e90000000000000000000000000000000000000000000000000000000000000000
d0d1d0d1dadbd6d7dadbdadbd0d1c0c1d0d1d0d1d0d1d4d5d4d5d0d1d0d1f8f9d8d9dadbf2f3f2f3f2f3f8f9dadbf8f9f6f7d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1f6f7d0d1d0d1d0d1d0d1d0d1d0d1f6f7d4d5d4d5d4d5d4d5d4d5d4d5f8f90000000000000000000000000000000000000000000000000000000000000000
e0e1e4e5cacbe0e1e0e1e0e1c0c1d0d1e6e7c0c1c0c1cacbcacbc8c9e8e9e8e9e6e7cacbe0e1e0e1e0e1e0e1c4c5c0c1e6e7c0c1c0c1c8c9c8c9c0c1c0c1e8e9e6e7e0e1e0e1e0e1e4e5e0e1e0e1e0e1c0c1cacbcacbcacbcacbcacbcacbc0c10000000000000000000000000000000000000000000000000000000000000000
f0f1f4f5dadbf0f1f0f1f0f1c0c1c0c1f6f7c0c1d0d1dadbdadbd8d9f8f9f8f9f6f7dadbf0f1f0f1f0f1f0f1d4d5d0d1f6f7d0d1d0d1d8d9d8d9d0d1d0d1f8f9f6f7f0f1f0f1f0f1f4f5f0f1f0f1f0f1d0d1dadbdadbdadbdadbdadbdadbd0d10000000000000000000000000000000000000000000000000000000000000000
cacbc6c7cacbcacacacbcacbe8e9e8e9d0d1d0d1c0c1cacbcacbc0c1c0c1c0c1e6e7cacbcacbcacbcacbcacbcacbe8e9e6e7c0c1c0c1c8c9c8c9c0c1c0c1e8e9cacbcacbcacbcacbc6c7cacbcacbcacbe6e7c4c5c4c5c4c5c4c5c4c5c4c5e8e90000000000000000000000000000000000000000000000000000000000000000
dadbd6d7dadbdadadadbdadbf8f9f8f9d0d1d0d1d0d1dadbdadbd0d1d0d1d0d1f6f7dadbdadbdadbdadbdadbdadbf8f9f6f7d0d1d0d1d8d9d8d9d0d1d0d1f8f9dadbdadbdadbdadbd6d7dadbdadbdadbf6f7d4d5d4d5d4d5d4d5d4d5d4d5f8f90000000000000000000000000000000000000000000000000000000000000000
e2e3e6e7e3e2c8c9e3e2e3c0e8e9d0d1e6e7c0c1c0c1c4c5c4c5c0c1c0c1c0c1c0c1c0c1c8c9c0c1c0c1c8c9c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1e8e9e2e3e2e3e2e3e2e3e2e3e2e3e8e9e8e9c0c1cacbcacbcacbcacbcacbcacbc0c10000000000000000000000000000000000000000000000000000000000000000
f2f3f6f7f3f2d8d9f3f2f3d0f8f9f3f2f6f7d0d1d0d1d4d5d4d5d0d1d0d1d0d1d0d1d0d1d8d9d0d1d0d1d8d9d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1f8f9f2f3f2f3f2f3f2f3f2f3f2f3f8f9f8f9d0d1dadbdadbdadbdadbdadbdadbd0d10000000000000000000000000000000000000000000000000000000000000000
c0c1e6e7e6e7c0c1c8c9c0c1c0c1c0c1c0c1c0c1c8c9cacbcacbc0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c8c9c8c9c0c1c0c1c0c1c0c1c0c1c0c1c0c1e8e9c0c1cacbcacbcacbcacbcacbcacbc0c10000000000000000000000000000000000000000000000000000000000000000
d0d1f6f7f6f7d0d1d8d9d0d1d0d1d0d1d0d1d0d1d8d9dadbdadbd0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d8d9d8d9d0d1d0d1d0d1d0d1d0d1d0d1d0d1f8f9d0d1dadbdadbdadbdadbdadbdadbd0d10000000000000000000000000000000000000000000000000000000000000000
c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1c0c1cacbcacbc2c3c2c3c2c3c2c3c2c3c2c3c2c3c2c3c2c3c2c3c2c3c0c1c0c1c0c1c0c1c0c1c0c1c8c9c8c9c2c3c2c3c2c3c2c3c2c3c2c3c2c3c2c3c0c1cacbcacbcacbcacbcacbcacbc0c10000000000000000000000000000000080818081808180818081808180818081
d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1d0d1dadbdadbd2d3d2d3d2d3d2d3d2d3d2d3d2d3d2d3d2d3d2d3d2d3d0d1d0d1d0d1d0d1d0d1d0d1d8d9d8d9d2d3d2d3d2d3d2d3d2d3d2d3d2d3d2d3d0d1dadbdadbdadbdadbdadbdadbd0d10000000000000000000000000000000090919091909190919091909190919091
0000000000000000000000000000000000000000000000000000000000000000eaebeaebeaebeaebeaebeaeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808080808080808080808080
0000000000000000000000000000000000000000000000000000000000000000fafbfafbfafbfafbfafbfafafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808080808080808080808080
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808080868788898a8b8080808080
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808080969798999a9b8080808080
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808081eaebecedeeef8080808080
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080809091fafbfcfdfeff8080808080
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808080cccd808180818080808080
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808080dcdd909190918080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808081808090918080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080809091808080808080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808080808080808080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808080808080808080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808080808080808080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808080808080808080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000092929292929292929292929292929292
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccc
__sfx__
000400000a6511c6512c6513f6512e6013160135601386013a6013e6013b6013c6013d6013d6013e6013e6013e6013e6013d6013d6013d6013c6013c6013d6010060100601006010060100601006010060100601
000a00000a6300e600116001360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00001763000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a000035551375513a5513b5513d5513f5512a5012c5012e5013350136501375010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
001000000955000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000100001b5511f551235512655100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
000200001855114551125510e5510b551095510655105551215011f5011c5011b5010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
000900000955009550095500955000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
060a0000084351940510435174050843508405084351a4050c435284050c435284050c4351140512435144050b435304050b435304050b435074050f4350b4050b435074050b435074050b435034050643507405
150a00000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e5000e5300e500
ac0a00002a2202f20030200302002a2200020000200002002a2202e20000200302002a2200020000200002002a2200020000200002002a2200020000200002002a22032200202200020033220002002022000200
010a000000600006003060030600036501c600306000060000600006002260022600036501c600226002260022600226000060000600036501c600226002260022600226000060000600036501c6000060000600
640a000014520195001c520175001452008500145201a5001852028500185202850018520115001e520145001752030500175203050017520075001b5200b5001752007500175200750017520035001252007500
000300000e551135511a551245512a5512e55133551275012a5012c5012d5012e5013150132501355013a5013a501005010050100501005010050100501005010050100501005010050100501005010050100501
000a0000171301710003130031500313000100031300310003130001000312000100031300310003130001000313000100031300010003130031000313000100031300310000130191000f13014100001301e100
180a00002075000700247502470029750007002475000700207500070024750247002975000700247500070020750007002475024700297500070024750007002075000700247502470029750007002475000700
650a0000185521855218552185521855218552185521855218552185521855218552185521855218552185521f5521f5521f5521f5521f5521f5521f5521f5521855218552185521855218552185521855218552
650a0000165521655216552165521655216552165521655216552165521655216552165521655216552165521f5521f5521f5521f5521f5521f5521f5521f5521155211552115521155211552115521155211552
280a00002075000700247502470029750007002475000700207500070024750247002975000700247500070020750007002475024700297500070024750007002075000700247502470029750007002475000700
290a0000127500070022750247001b750007002275000700127500070022750247001b750007002275000700127500070022750247001b750007002275000700127500070022750247001b750007002275000700
180a0000127500070022750247001b750007002275000700127500070022750247001b750007002275000700127500070022750247001b750007002275000700127500070022750247001b750007002275000700
14040000006430064301643036430464306643086430a6430b6430c6430d6430d6430d6430d6430d64313643176431c6432064324643390433900339003330033300333003330030b60308603066030560303603
6f0b0000266512565123651226511f6511d6511b6511965115651116510e6510a6510765101651000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
4e0500002b65029650276502665023650216501e6501d6501b65018650176501565015650176501a6501c650206502365026650296502c6502e6503165034650366503c6503f6500000000000000000000000000
010500000a3510c3510e3510f3511135112351133511535116351193511b3511b3511c3511d3511f35121351223512335126351293512b3512c3512f351313513335100301003010030100301133013f3513f351
__music__
01 08094a4b
00 080b0944
01 080b0944
01 08090b4c
02 48090b4c
00 08090b0c
01 0f101244
02 14111344


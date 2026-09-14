extends Control
## 1280x720 design canvas. Menus use real Controls; touch combat keeps per-finger ownership.
var game: Node
var font: Font
var controls: Array[Control]=[]
var touch_regions: Array[Dictionary]=[]
var fingers: Dictionary={}
var portraits: Dictionary={}
var training_panel := false
var move_side := 0
const PAPER=Color("f3e8d2")
const INK=Color("151311")
const RED=Color("ef5a3c")
const MUTED=Color("b9ae99")
func _ready() -> void:
	font=load("res://assets/fonts/TaiwanUI.otf") if ResourceLoader.exists("res://assets/fonts/TaiwanUI.otf") else ThemeDB.fallback_font
	for id in game.model.roster: portraits[id]=load(game.model.roster[id].portrait)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:
	var cinematic: bool=not game.model.cinematic.is_empty() and game.screen=="battle" and not game.paused
	for c in controls: c.visible=not cinematic
func style(color: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=color; s.set_corner_radius_all(2); return s
func button(text: String, rect: Rect2, callback: Callable, primary: bool=false) -> void:
	var b:=Button.new(); b.text=text; b.position=rect.position; b.size=rect.size
	if game.screen=="battle" and not game.paused and not game.help_open: b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_override("font",font); b.add_theme_font_size_override("font_size",28)
	b.add_theme_color_override("font_color",INK if primary else PAPER)
	b.add_theme_stylebox_override("normal",style(RED if primary else Color("302c27")))
	b.add_theme_stylebox_override("hover",style(Color("9b442e")))
	b.add_theme_stylebox_override("pressed",style(Color("aa4a31")))
	var focus=style(Color(0,0,0,0)); focus.border_color=PAPER; focus.set_border_width_all(3)
	b.add_theme_stylebox_override("focus",focus)
	b.pressed.connect(func():game.sound.play_event({"type":"ui"}); callback.call())
	add_child(b); controls.append(b)
func label(text: String, rect: Rect2, size_value: int=28, color: Color=PAPER) -> void:
	var l:=Label.new(); l.text=text; l.position=rect.position; l.size=rect.size
	l.add_theme_font_override("font",font); l.add_theme_font_size_override("font_size",size_value); l.add_theme_color_override("font_color",color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(l); controls.append(l)
func rebuild() -> void:
	for c in controls: remove_child(c); c.queue_free()
	controls.clear(); touch_regions.clear(); fingers.clear(); game.touch_held.clear()
	if game.help_open:
		if game.help_page=="moves":
			var f: Dictionary=game.model.fighters[move_side]
			label(f.data.name+"　招式表",Rect2(85,40,1050,70),42)
			label("招式／輸入　　　　　　　　　發生・有效・收招　傷害　氣",Rect2(85,115,1080,55),26)
			var input_names={"punch":"J","kick":"K","crouch_punch":"S＋J","crouch_kick":"S＋K","air_punch":"空中 J","air_kick":"空中 K","command":"前＋K","special_punch":"U / 236 J","special_kick":"I / 236 K","super":"O / 236236 J","awakening":"L / 236236 K"}
			var row:=0
			for id in f.data.moves:
				var m: Dictionary=f.data.moves[id]
				label(m.name+"　"+input_names.get(id,id),Rect2(85,170+row*36,590,36),24)
				label("%d / %d / %d　　 %d　　 %d"%[m.startup,m.active,m.recovery,m.damage,m.cost],Rect2(680,170+row*36,520,36),24)
				row+=1
			label("Super／覺醒為兩段命中；表列單段基礎傷害，連段會遞減。",Rect2(85,575,1100,35),22,MUTED)
			button("另一位鬥士",Rect2(85,625,300,72),func():move_side=1-move_side;rebuild())
			button("返回對戰",Rect2(895,625,300,72),func():game.help_open=false;game.paused=false;game.clean_input();rebuild(),true)
			return
		label("操作與招式",Rect2(100,65,1080,65),40)
		label("移動 A / D　蹲 S　跳 W　防禦 空白鍵　衝刺 Shift\n站／蹲／空中：J 拳、K 腳　前＋K 中段下劈\n必殺 U / I（或 236＋J / K）\nSuper O（100 氣）　覺醒 L（200 氣）\n進阶指令：236236＋J / K；方向以角色面向為準。\n命中或擋住普通技後，可接必殺／Super。空振不能取消。\n玩家 2：方向鍵、數字鍵盤 1/2 拳腳、4/5 必殺、6 超、3 覺醒、0 防、7 衝刺\nEsc 暫停　R 重開　F2 判定　F3 減少動態　F4 觸控　M 靜音",Rect2(100,155,1080,440),26)
		button("返回",Rect2(940,620,240,72),func():game.help_open=false;game.paused=false;game.clean_input();rebuild(),true)
		return
	if game.paused:
		label("暫停對戰",Rect2(150,90,980,80),48)
		button("繼續",Rect2(150,220,440,90),game.toggle_pause,true)
		button("重新開始",Rect2(650,220,440,90),func():game.begin_battle())
		button("音樂："+("開" if game.sound.music_enabled else "關"),Rect2(150,340,440,90),func():game.sound.music_enabled=not game.sound.music_enabled;game.sound.music.stop();rebuild())
		button("減少動態："+("開" if game.reduced_motion else "關"),Rect2(650,340,440,90),func():game.reduced_motion=not game.reduced_motion;game.stage.motion=not game.reduced_motion;rebuild())
		button("招式表　TAB",Rect2(150,460,440,90),func():game.help_page="moves";game.help_open=true;rebuild())
		button("回主選單",Rect2(650,460,440,90),game.show_home)
		return
	match game.screen:
		"home":
			label("武鬥台灣魂",Rect2(65,75,720,110),72)
			label("巷口開打。把日常，練成絕招。",Rect2(70,195,700,60),30)
			button("街頭對戰",Rect2(70,305,300,90),func():game.enter_mode("cpu"),true)
			button("故事模式",Rect2(390,305,300,90),func():game.enter_mode("story"))
			button("訓練場",Rect2(70,415,300,90),func():game.enter_mode("training"))
			button("同機雙人",Rect2(390,415,300,90),func():game.enter_mode("local"))
			button("操作說明",Rect2(70,525,300,80),func():game.help_open=true;rebuild())
			label("重構候選 0.2　／　兩名鬥士・雨夜街口",Rect2(70,635,900,45),22,MUTED)
		"select":
			label("選擇你的鬥士",Rect2(65,40,1000,70),44)
			var ids: Array=game.model.roster.keys()
			for i in ids.size():
				var id: String=ids[i]
				button(game.model.roster[id].name+(" ✓" if game.selected==id else ""),Rect2(65+i*255,430,235,80),func():game.selected=id;rebuild(),game.selected==id)
			button("對手："+game.model.roster[game.opponent].name,Rect2(65,530,340,74),func():game.opponent=ids[(ids.find(game.opponent)+1)%ids.size()];rebuild())
			button("難度："+{"easy":"簡單","normal":"普通","hard":"困難"}[game.difficulty],Rect2(430,530,340,74),func():var levels=["easy","normal","hard"];game.difficulty=levels[(levels.find(game.difficulty)+1)%3];rebuild())
			button("準備對戰",Rect2(855,530,350,90),game.confirm_select,true)
			button("返回",Rect2(65,630,230,65),game.show_home)
		"story_menu":
			label("街區故事",Rect2(70,60,1050,80),52)
			for i in game.flow.routes.size():
				var route: Dictionary=game.flow.routes[i]
				button(route.title+("　已通關" if game.flow.cleared.has(route.id) else ""),Rect2(70,210+i*165,590,90),func():game.start_story(i),i==0)
				label(route.synopsis,Rect2(85,310+i*165,1080,60),27)
			button("返回",Rect2(70,610,260,80),game.show_home)
		"dialogue":
			var line: Array=game.flow.node().lines[game.flow.line_index]
			label(str(line[0]),Rect2(85,405,1050,55),32,RED)
			label(str(line[1]),Rect2(85,472,1080,115),32)
			button("繼續 →",Rect2(920,610,280,80),game.advance_dialogue,true)
			button("略過這段",Rect2(70,610,280,80),func():game.flow.advance();game.story_node())
		"vs":
			label("即將交手",Rect2(70,45,1100,70),44)
			label(game.model.roster[game.selected].name,Rect2(130,465,400,70),48)
			label(game.model.roster[game.opponent].name,Rect2(825,465,370,70),48)
			label(game.stages[game.stage_id].name+"　／　"+{"training":"訓練","cpu":"街頭對戰","story":"故事","local":"同機雙人"}[game.mode],Rect2(330,555,750,55),30)
			button("開打　ENTER",Rect2(450,625,380,80),game.begin_battle,true)
		"result":
			var won: bool=game.model.winner==0
			label(("挑戰成功" if won else "再試一次")+"　%d : %d"%[game.model.wins[0],game.model.wins[1]],Rect2(150,120,1000,100),60)
			label("觀察距離，擋住重招，再抓收招反擊。",Rect2(150,270,1000,90),30)
			button("繼續故事" if game.mode=="story" and won else "再戰一場",Rect2(150,450,430,95),game.continue_result,true)
			button("回主選單",Rect2(650,450,430,95),game.show_home)
		"clear":
			label("這條路，走完了。",Rect2(120,135,1050,100),60)
			label(game.flow.route.title+"　／　通關紀錄已保存",Rect2(125,270,1030,80),32)
			button("其他街區故事",Rect2(150,450,440,95),func():game.enter_mode("story"),true)
			button("回主選單",Rect2(660,450,440,95),game.show_home)
		"battle":
			button("Ⅱ",Rect2(604,106,72,58),game.toggle_pause)
			if game.model.phase=="round_end":
				button("結算" if game.model.wins.max()>=2 else "下一回合",Rect2(455,380,370,85),game.continue_round,true)
			elif game.mode=="training":
				button("訓練設定",Rect2(35,143,185,58),func():training_panel=not training_panel;rebuild())
				if training_panel:
					button("重置 R",Rect2(35,214,190,60),game.reset_training)
					button("木樁："+("防" if game.dummy=="guard" else "靜"),Rect2(35,280,190,60),func():game.dummy="guard" if game.dummy=="idle" else "idle";rebuild())
					button("氣："+("無限" if game.model.infinite_meter else "正常"),Rect2(35,346,190,60),func():game.model.infinite_meter=not game.model.infinite_meter;rebuild())
					button("回血："+("開" if game.model.recover_health else "關"),Rect2(35,412,190,60),func():game.model.recover_health=not game.model.recover_health;rebuild())
					button("骨架 F7",Rect2(35,478,190,60),func():game.rig_enabled=not game.rig_enabled;rebuild())
			if game.touch_enabled: build_touch()

func build_touch() -> void:
	var positions={"left":Rect2(25,604,115,96),"right":Rect2(165,604,115,96),"jump":Rect2(95,495,115,96),"down":Rect2(305,604,115,96),"guard":Rect2(305,495,115,96),"dash":Rect2(445,604,115,96),"punch":Rect2(850,495,115,96),"kick":Rect2(990,495,115,96),"special_punch":Rect2(1130,495,115,96),"special_kick":Rect2(850,604,115,96),"super":Rect2(990,604,115,96),"awakening":Rect2(1130,604,115,96)}
	var names={"left":"←","right":"→","jump":"跳","down":"蹲","guard":"防","dash":"衝","punch":"拳","kick":"腳","special_punch":"必殺Ⅰ","special_kick":"必殺Ⅱ","super":"超","awakening":"覺醒"}
	for action in positions: touch_regions.append({"action":action,"rect":positions[action],"label":names[action]})
func set_finger(index: int, point: Vector2, pressed: bool) -> void:
	if fingers.has(index):
		var previous: String=fingers[index]; fingers.erase(index)
		if not fingers.values().has(previous): game.touch_held[previous]=false
	if not pressed: return
	for region in touch_regions:
		if region.rect.has_point(point):
			fingers[index]=region.action; game.touch_held[region.action]=true
			if region.action not in ["left","right","down","guard"]: game.action_pressed(region.action)
			return
func _input(event: InputEvent) -> void:
	if game.screen!="battle" or game.paused or touch_regions.is_empty(): return
	if event is InputEventScreenTouch:
		set_finger(event.index,event.position,event.pressed)
		if fingers.has(event.index): get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		var old: String=fingers.get(event.index,"")
		var over: String=""
		for r in touch_regions:
			if r.rect.has_point(event.position): over=r.action; break
		if over!=old: set_finger(event.index,event.position,over!="")
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		set_finger(-1,event.position,event.pressed)

func text(value: String, position_value: Vector2, size_value: int=28, color: Color=PAPER) -> void:
	draw_string(font,position_value,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
func portrait(id: String, rect: Rect2, mirrored: bool=false) -> void:
	var texture: Texture2D=portraits[id]
	if mirrored:
		draw_set_transform(Vector2(rect.position.x+rect.size.x,rect.position.y),0,Vector2(-1,1)); draw_texture_rect(texture,Rect2(Vector2.ZERO,rect.size),false); draw_set_transform(Vector2.ZERO)
	else: draw_texture_rect(texture,rect,false)
func _draw() -> void:
	if not font or game.model.fighters.is_empty(): return
	if game.screen!="battle":
		draw_rect(Rect2(0,0,1280,720),Color(0.05,0.04,0.03,0.53))
		if game.screen=="home": draw_rect(Rect2(0,0,730,720),Color(0.06,0.05,0.04,0.72))
		if game.screen in ["select","vs","dialogue"]:
			portrait(game.selected,Rect2(95,105,410,410))
			portrait(game.opponent,Rect2(795,105,410,410),true)
			if game.screen=="vs": text("VS",Vector2(565,350),90,RED)
			if game.screen=="dialogue": draw_rect(Rect2(45,390,1190,310),Color(0.08,0.07,0.06,0.96))
	if game.screen=="battle": draw_battle()
	if game.paused or game.help_open: draw_rect(Rect2(0,0,1280,720),Color(0.055,0.047,0.04,0.97))
	if not game.model.cinematic.is_empty() and game.screen=="battle" and not game.paused: draw_cinematic()

func draw_battle() -> void:
	for i in 2:
		var f: Dictionary=game.model.fighters[i]
		var x: float=35 if i==0 else 765
		draw_rect(Rect2(x-10,18,500,108),Color(0.07,0.06,0.05,0.91))
		text(f.data.name,Vector2(x,51),30)
		text(str(f.hp),Vector2(x+390,51),26)
		if not f.get("buff",{}).is_empty(): text(f.buff.get("label","強化"),Vector2(x+240,51),20,RED)
		draw_rect(Rect2(x,64,470,24),Color("4e4942"))
		draw_rect(Rect2(x,64,470*float(f.hp)/1000,24),Color("d9a52e") if i==0 else Color("ef7953"))
		draw_rect(Rect2(x,95,330*f.guard/100,6),Color("b9ae99"))
		for n in 2: draw_circle(Vector2(x+432+n*28,102),7,RED if game.model.wins[i]>n else Color("57514a"))
		var meter_x: float=35 if i==0 else 895
		var meter_y: float=458 if game.touch_enabled else 648
		draw_rect(Rect2(meter_x-6,meter_y-20,360,51),Color(0.05,0.04,0.03,0.85))
		text("氣　%d / 300"%int(f.meter),Vector2(meter_x,meter_y),23)
		for n in 3:
			draw_rect(Rect2(meter_x+n*115,meter_y+10,108,9),Color("4e4942"))
			draw_rect(Rect2(meter_x+n*115,meter_y+10,108*clampf((f.meter-n*100)/100,0,1),9),Color(f.data.accent))
	text("∞" if game.mode=="training" else str(ceili(float(game.model.remaining)/60)),Vector2(605,72),48)
	if game.debug_boxes: text("%d FPS"%Engine.get_frames_per_second(),Vector2(594,96),18)
	if game.model.phase=="intro": text("第 %d 回合"%game.model.round_number,Vector2(490,330),52)
	if game.model.phase=="round_end":
		draw_rect(Rect2(380,250,520,115),Color(0.08,0.06,0.04,0.92))
		text("平手" if game.model.winner<0 else game.model.fighters[game.model.winner].data.name+" 拿下回合",Vector2(430,325),42)
	if game.mode=="training" and game.model.fighters[0].y>=-60:
		var a: Dictionary=game.model.fighters[0]; var b: Dictionary=game.model.fighters[1]
		draw_rect(Rect2(240,133,995,36),Color(0.06,0.05,0.04,0.78))
		text("%s　幀 %d　%s"%[a.move_id if a.move_id!="" else a.state,a.ticks,a.confirm],Vector2(252,158),19)
		text("上次 %s %d 傷害　連段 %d / %d"%[b.last_contact,b.last_damage,b.combo,b.combo_damage],Vector2(705,158),19)
		if game.rig_enabled: text("單一來源骨架",Vector2(40,235),20,RED)
	if not game.touch_enabled: text("A D 移動　W 跳　S 蹲　J K 拳腳　U I 必殺　O 超　L 覺醒　空白 防　F1 說明",Vector2(65,707),22,MUTED)
	for r in touch_regions:
		var active: bool=game.touch_held.get(r.action,false)
		draw_style_box(style(Color(0.7,0.25,0.12,0.9) if active else Color(0.08,0.07,0.06,0.63)),r.rect)
		text(r.label,r.rect.position+Vector2(18,59),29)

func draw_cinematic() -> void:
	var c: Dictionary=game.model.cinematic
	var f: Dictionary=game.model.fighters[c.fighter]
	var p: float=float(c.tick)/c.duration
	var accent:=Color(f.data.accent)
	draw_rect(Rect2(0,0,1280,720),Color(0.015,0.015,0.02,0.85 if p<0.8 else (1-p)*3))
	# Moving diagonal cut-in, close-up, impact treatment and letterbox share one bounded clock.
	var slide: float=(1-ease(clampf((p-0.1)/0.25,0,1),0.35))*350
	var left: bool=c.fighter==0
	var rect:=Rect2(70-slide,70,660,660)
	portrait(f.id,rect,not left)
	var points:=PackedVector2Array([Vector2(710,180),Vector2(1230,140),Vector2(1230,530),Vector2(640,570)])
	draw_colored_polygon(points,Color(0.09,0.07,0.06,0.93))
	draw_line(Vector2(705,183),Vector2(1225,143),accent,8,true)
	text("覺醒" if c.kind=="awakening" else "超必殺",Vector2(770,240),30,accent)
	var name: String=f.data.moves[c.move].name
	text(name,Vector2(735,340),43)
	text(f.data.quote,Vector2(735,415),25)
	for n in 16:
		var y: float=150+n*26
		var offset: float=fmod(p*900+n*97,350)
		draw_line(Vector2(offset-300,y),Vector2(offset-190,y-20),Color(accent,0.35),2,true)
	draw_rect(Rect2(0,0,1280,55),INK); draw_rect(Rect2(0,665,1280,55),INK)
	if p>0.83 and not game.reduced_motion: draw_rect(Rect2(0,0,1280,720),Color(1,0.94,0.8,(1-p)*1.3))

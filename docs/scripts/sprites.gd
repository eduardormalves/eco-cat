class_name GameSprites

static var _cat_tex: ImageTexture
static var _gem_tex: ImageTexture
static var _bin_tex: ImageTexture
static var _grass_tex: ImageTexture
static var _dirt_tex: ImageTexture
static var _leaf_tex: ImageTexture
static var _icon_cache: Dictionary = {}

const _OUTLINE := Color("#2c1810")


static func _build(pixels: Array, palette: Dictionary, scale: int) -> ImageTexture:
	var h: int = pixels.size()
	var w: int = (pixels[0] as Array).size() if h > 0 else 0
	var img := Image.create(w * scale, h * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		var row: Array = pixels[y]
		for x in range(row.size()):
			var idx: int = row[x]
			if not palette.has(idx):
				continue
			var col: Color = palette[idx]
			for dy in range(scale):
				for dx in range(scale):
					img.set_pixel(x * scale + dx, y * scale + dy, col)
	return ImageTexture.create_from_image(img)


static func cat() -> ImageTexture:
	if _cat_tex:
		return _cat_tex
	var pal := {
		1:  Color("#2c1810"),
		2:  Color("#f5c490"),
		3:  Color("#c8834a"),
		4:  Color("#fff2dd"),
		5:  Color("#f0a8a8"),
		6:  Color("#1a0e08"),
		7:  Color("#d95050"),
		8:  Color("#45c46a"),
		9:  Color("#2e8a4a"),
		10: Color("#8a6a3a"),
	}
	# 16x16 pixel art cat — ears (rows 1-3), head (4-10), scarf (11), body (12-13), legs (14-15)
	var p: Array = [
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
		[0, 0, 0, 1, 2, 5, 1, 0, 1, 5, 2, 1, 0, 0, 0, 0],
		[0, 0, 0, 1, 2, 2, 1, 0, 1, 2, 2, 1, 0, 0, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 1, 2, 2, 6, 2, 2, 2, 2, 2, 6, 2, 2, 2, 1, 0],
		[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
		[0, 1, 2, 4, 4, 4, 2, 7, 2, 4, 4, 4, 2, 2, 1, 0],
		[0, 1, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 1, 0],
		[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 0, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 0, 0, 0],
		[0, 0, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 0, 0, 0],
		[0, 0, 9, 10, 9, 9, 9, 9, 9, 9, 10, 9, 9, 0, 0, 0],
		[0, 0, 1, 3, 3, 1, 0, 0, 0, 1, 3, 3, 1, 0, 0, 0],
		[0, 0, 0, 1, 3, 1, 0, 0, 0, 1, 3, 1, 0, 0, 0, 0],
	]
	_cat_tex = _build(p, pal, 3)
	return _cat_tex


static func waste_gem() -> ImageTexture:
	if _gem_tex:
		return _gem_tex
	var pal := {
		1: Color("#2c1810"),
		2: Color("#f0f0f0"),
		3: Color("#c0c0c0"),
		4: Color("#ffffff"),
	}
	# 8x8 diamond gem — tinted via Sprite2D.modulate to match waste type color
	var p: Array = [
		[0, 0, 0, 1, 1, 0, 0, 0],
		[0, 0, 1, 4, 2, 1, 0, 0],
		[0, 1, 4, 2, 2, 2, 1, 0],
		[1, 3, 2, 2, 2, 2, 3, 1],
		[1, 2, 2, 2, 2, 2, 2, 1],
		[0, 1, 2, 2, 2, 2, 1, 0],
		[0, 0, 1, 2, 2, 1, 0, 0],
		[0, 0, 0, 1, 1, 0, 0, 0],
	]
	_gem_tex = _build(p, pal, 3)
	return _gem_tex


static func grass_tile() -> ImageTexture:
	if _grass_tex:
		return _grass_tex
	var pal := {
		1: Color("#3d7a1a"),
		2: Color("#4d8c28"),
		3: Color("#5ea036"),
		4: Color("#70b448"),
		5: Color("#82c85a"),
	}
	# 16x16 grass tile — natural variation of greens, scale 2 = 32x32 repeating tile
	var p: Array = [
		[3,2,3,4,2,3,2,3,4,2,3,2,3,4,2,3],
		[2,4,2,2,3,2,4,2,2,3,2,4,2,2,3,2],
		[1,2,3,1,2,3,2,1,3,2,1,2,3,1,2,3],
		[3,1,2,4,3,2,1,3,2,4,3,2,1,4,3,2],
		[2,3,2,2,2,4,3,2,2,2,4,3,2,2,2,4],
		[4,2,1,3,1,2,2,4,1,3,1,2,2,4,1,3],
		[2,3,3,2,4,1,3,2,3,2,4,1,3,2,3,2],
		[1,2,2,3,2,3,2,1,2,3,2,3,2,1,2,3],
		[3,4,1,2,3,2,4,3,1,2,3,2,4,3,1,2],
		[2,2,3,1,2,4,2,2,3,1,2,4,2,2,3,1],
		[4,1,2,3,1,2,3,4,1,2,3,1,2,3,4,1],
		[2,3,4,2,3,1,2,2,3,4,2,3,1,2,2,3],
		[1,2,2,4,2,3,4,1,2,2,4,2,3,4,1,2],
		[3,4,1,2,4,2,2,3,4,1,2,4,2,2,3,4],
		[2,2,3,1,2,4,1,2,2,3,1,2,4,1,2,2],
		[4,1,2,3,1,2,3,4,1,2,3,1,2,3,4,1],
	]
	_grass_tex = _build(p, pal, 4)
	return _grass_tex


static func dirt_tile() -> ImageTexture:
	if _dirt_tex:
		return _dirt_tex
	var pal := {
		1: Color("#8a6018"),
		2: Color("#a07028"),
		3: Color("#b88038"),
		4: Color("#cc9048"),
		5: Color("#dea858"),
	}
	# 16x16 dirt/road tile — earthy variation, scale 2 = 32x32
	var p: Array = [
		[3,2,3,4,3,2,3,4,3,2,4,3,2,3,4,3],
		[2,4,2,2,2,4,2,2,2,4,2,2,2,4,2,2],
		[1,2,3,1,1,2,3,1,1,2,3,1,1,2,3,1],
		[3,1,2,4,3,1,2,4,3,1,2,4,3,1,2,4],
		[2,3,4,2,2,3,4,2,2,3,4,2,2,3,4,2],
		[4,2,2,3,4,2,2,3,4,2,2,3,4,2,2,3],
		[2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2],
		[1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4],
		[3,4,2,2,3,4,2,2,3,4,2,2,3,4,2,2],
		[2,2,4,1,2,2,4,1,2,2,4,1,2,2,4,1],
		[4,1,2,3,4,1,2,3,4,1,2,3,4,1,2,3],
		[2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2],
		[1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4],
		[3,4,2,3,3,4,2,3,3,4,2,3,3,4,2,3],
		[2,2,4,2,2,2,4,2,2,2,4,2,2,2,4,2],
		[4,1,2,1,4,1,2,1,4,1,2,1,4,1,2,1],
	]
	_dirt_tex = _build(p, pal, 4)
	return _dirt_tex


static func recycle_bin() -> ImageTexture:
	if _bin_tex:
		return _bin_tex
	var pal := {
		1: Color("#2c1810"),
		2: Color("#ffffff"),
		3: Color("#eeeeee"),
		4: Color("#cccccc"),
		5: Color("#aaaaaa"),
	}
	# 16x20 bin (scale 2 = 32x40) — tinted via Sprite2D.modulate to match bin type color
	var p: Array = [
		[0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
		[0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0],
		[0, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 0],
		[0, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, 0, 0],
		[0, 0, 1, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 1, 3, 3, 3, 3, 1, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
		[0, 0, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 0, 0],
		[0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
	]
	_bin_tex = _build(p, pal, 2)
	return _bin_tex


# --------------------------------------------------------------------------- #
# Residuos com aparencia neutra (o objeto real, nao a cor da lixeira)
# --------------------------------------------------------------------------- #

## Monta uma textura a partir de linhas de texto: cada caractere e um pixel e
## indexa a paleta ("." ou caractere fora da paleta = transparente).
static func _from_rows(rows: Array, pal: Dictionary, scale: int) -> ImageTexture:
	var h := rows.size()
	var w := String(rows[0]).length()
	var img := Image.create(w * scale, h * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		var row := String(rows[y])
		for x in range(row.length()):
			var ch := row[x]
			if not pal.has(ch):
				continue
			img.fill_rect(Rect2i(x * scale, y * scale, scale, scale), pal[ch])
	return ImageTexture.create_from_image(img)


## Icone 12x12 (escala 3 = 36x36) de cada residuo do catalogo de main.gd.
static func waste_icon(id: String) -> ImageTexture:
	if _icon_cache.has(id):
		return _icon_cache[id]
	var data := _icon_data(id)
	if data.is_empty():
		return waste_gem()
	var tex := _from_rows(data[0], data[1], 3)
	_icon_cache[id] = tex
	return tex


static func _icon_data(id: String) -> Array:
	var k := _OUTLINE
	match id:
		"pet":  # garrafa PET
			return [[
				"....kcck....",
				"....kcck....",
				"....kbbk....",
				"...kbbbbk...",
				"..kbhbbbbk..",
				"..kllllllk..",
				"..kllllllk..",
				"..kbhbbbbk..",
				"..kbhbbbbk..",
				"..kbbbbbbk..",
				"..kbbbbbbk..",
				"...kkkkkk...",
			], {"k": k, "b": Color("#cfeaf5"), "h": Color("#ffffff"), "c": Color("#f08a2a"), "l": Color("#2fa89a")}]
		"sacola":  # sacola plastica
			return [[
				"..kkk..kkk..",
				"..k.k..k.k..",
				"..k.k..k.k..",
				".kkkkkkkkkk.",
				".kwwwwwwwwk.",
				".kwsswwwwwk.",
				".kwwwwwwwsk.",
				".kwwwwwwwwk.",
				".kswwwwwwwk.",
				".kwwwwwsswk.",
				"..kwwwwwwk..",
				"...kkkkkk...",
			], {"k": k, "w": Color("#f7f7f2"), "s": Color("#d6d6cf")}]
		"jornal":
			return [[
				"............",
				".kkkkkkkkkk.",
				".kwwwwwwwwk.",
				".kwttttwppk.",
				".kwwwwwwppk.",
				".kwttwtttwk.",
				".kwwwwwwwwk.",
				".kwtttwttwk.",
				".kwwwwwwwwk.",
				".kwttwtttwk.",
				".kkkkkkkkkk.",
				"............",
			], {"k": k, "w": Color("#f4f1e8"), "t": Color("#9a9a9a"), "p": Color("#7fa6c8")}]
		"caixa":  # caixa de papelao
			return [[
				"............",
				".kkkkkkkkkk.",
				".kddddddddk.",
				".kkkkttkkkk.",
				".kcccttccck.",
				".kcccttccck.",
				".kcccccccck.",
				".kcccccccck.",
				".kcckkkkcck.",
				".kcckwwkcck.",
				".kcckkkkcck.",
				".kkkkkkkkkk.",
			], {"k": k, "c": Color("#d6a565"), "d": Color("#b5834a"), "t": Color("#efe0b0"), "w": Color("#f4f1e8")}]
		"garrafa_vidro":
			return [[
				"....kkkk....",
				"....kaak....",
				"....kaak....",
				"....kaak....",
				"...kaaaak...",
				"..kahaaaak..",
				"..kallllak..",
				"..kallllak..",
				"..kahaaaak..",
				"..kahaaaak..",
				"..kaaaaaak..",
				"...kkkkkk...",
			], {"k": k, "a": Color("#b8742c"), "h": Color("#f3d9a8"), "l": Color("#f4f1e8")}]
		"pote_vidro":
			return [[
				"............",
				"..kkkkkkkk..",
				"..kmmmmmmk..",
				"..kmmmmmmk..",
				".kkkkkkkkkk.",
				".kghggggggk.",
				".kghggggggk.",
				".kghggggggk.",
				".kggggggggk.",
				".kggggggggk.",
				".kggggggggk.",
				"..kkkkkkkk..",
			], {"k": k, "g": Color("#cfeee8"), "h": Color("#ffffff"), "m": Color("#9aa0a6")}]
		"lata":  # lata de refrigerante
			return [[
				"............",
				"...kkkkkk...",
				"..kdssssdk..",
				"..kshssssk..",
				"..krrrrrrk..",
				"..krhrrrrk..",
				"..krrrrrrk..",
				"..kshssssk..",
				"..kshssssk..",
				"..kssssssk..",
				"..kdssssdk..",
				"...kkkkkk...",
			], {"k": k, "s": Color("#c8ccd0"), "h": Color("#f0f2f4"), "d": Color("#8a9096"), "r": Color("#c0407a")}]
		"lata_conserva":
			return [[
				"............",
				".kkkkkkkkkk.",
				".kssssssssk.",
				".kddddddddk.",
				".kllllllllk.",
				".kllrrllllk.",
				".klrrrrlllk.",
				".kllrrllllk.",
				".kllllllllk.",
				".kddddddddk.",
				".kssssssssk.",
				".kkkkkkkkkk.",
			], {"k": k, "s": Color("#c8ccd0"), "d": Color("#8a9096"), "l": Color("#efe2c0"), "r": Color("#d84a3a")}]
		"banana":  # casca de banana
			return [[
				".....kk.....",
				".....kbk....",
				"....kyyk....",
				"....kyyk....",
				"...kyyyyk...",
				"..kyyyyyyk..",
				".kyykyykyyk.",
				".kyk.kyk.kyk",
				"kyk.kyyk.kyk",
				"kyk..kyk.kyk",
				"kbk..kbk.kbk",
				".k....k...k.",
			], {"k": k, "y": Color("#f2d23a"), "b": Color("#8a5a28")}]
		"maca":  # resto de maca
			return [[
				".....bgg....",
				".....b......",
				"...kkkkkk...",
				"..krrrrrrk..",
				"..krrrrrrk..",
				"...kffffk...",
				"....kffk....",
				"....kbfk....",
				"...kffffk...",
				"..krrrrrrk..",
				"..krrrrrrk..",
				"...kkkkkk...",
			], {"k": k, "r": Color("#d8453a"), "f": Color("#f6efd0"), "b": Color("#6b4a2b"), "g": Color("#5aa04a")}]
		"guardanapo":  # guardanapo sujo
			return [[
				"..kkkk.kk...",
				".kwwwwkwwk..",
				".kwwmwwwwwk.",
				"kwwmmwwswwk.",
				"kwwwwwsswk..",
				".kwswwwwmmk.",
				".kwwwwwwmk..",
				"kwwwnwwwwk..",
				".kwwwwswwwk.",
				"..kkwwwkkk..",
				"....kkk.....",
				"............",
			], {"k": k, "w": Color("#f7f4ee"), "s": Color("#d9d2c4"), "m": Color("#c98a3a"), "n": Color("#b0412f")}]
		"esponja":  # esponja de cozinha
			return [[
				"............",
				"............",
				".kkkkkkkkkk.",
				".kggggggggk.",
				".kggggggggk.",
				".kkkkkkkkkk.",
				".kyyyyyyyyk.",
				".kyyoyyyoyk.",
				".kyyyyoyyyk.",
				".kyoyyyyyyk.",
				".kkkkkkkkkk.",
				"............",
			], {"k": k, "g": Color("#3f8a3a"), "y": Color("#f2d23a"), "o": Color("#d4b028")}]
		"pizza":  # caixa de pizza engordurada (pegadinha: parece papel)
			return [[
				"............",
				"............",
				"............",
				"kkkkkkkkkkkk",
				"kddddddddddk",
				"kcccrrcccgck",
				"kccrccrcggck",
				"kcccrrccccck",
				"kcgccccccgck",
				"kggcccccccck",
				"kkkkkkkkkkkk",
				"............",
			], {"k": k, "c": Color("#d6a565"), "d": Color("#b5834a"), "g": Color("#7a4e1c"), "r": Color("#d8453a")}]
		"espelho":  # espelho quebrado (pegadinha: parece vidro)
			return [[
				"..kkkkkkkk..",
				".kffffffffk.",
				".kfmmmmmmfk.",
				".kfmhmmxmfk.",
				".kfmmhxmmfk.",
				".kfmmxmmmfk.",
				".kfmxmxmmfk.",
				".kfxmmmxmfk.",
				".kfmmmmmxfk.",
				".kfmmmmmmfk.",
				".kffffffffk.",
				"..kkkkkkkk..",
			], {"k": k, "f": Color("#8a5a28"), "m": Color("#cfe6f0"), "h": Color("#ffffff"), "x": Color("#5a6a74")}]
		"cupom":  # cupom fiscal (pegadinha: parece papel)
			return [[
				"...kkkkkk...",
				"...kwwwwk...",
				"...kttttk...",
				"...kwwwwk...",
				"...ktwttk...",
				"...kwwwwk...",
				"...ktttwk...",
				"...kwwwwk...",
				"...kttwtk...",
				"...kwwwwk...",
				"...kwwwwk...",
				"...kkkkkk...",
			], {"k": k, "w": Color("#fbfaf4"), "t": Color("#a0a0a0")}]
		"pilha":  # pilha usada (e-lixo)
			return [[
				"............",
				".....kk.....",
				"....kssk....",
				"...kkkkkk...",
				"...kcwcck...",
				"...kwwwck...",
				"...kcwcck...",
				"...kppppk...",
				"...kppppk...",
				"...kppppk...",
				"...kppppk...",
				"...kkkkkk...",
			], {"k": k, "s": Color("#c8ccd0"), "c": Color("#d89a3a"), "w": Color("#ffffff"), "p": Color("#9b59b6")}]
	return []


## Folha usada no HUD para as chances da Licenca Ambiental.
static func leaf() -> ImageTexture:
	if _leaf_tex:
		return _leaf_tex
	_leaf_tex = _from_rows([
		"........kk..",
		"......kkgk..",
		"....kkgggk..",
		"...kggggdk..",
		"..kgggvgdk..",
		"..kggvggdk..",
		".kggvgggk...",
		".kgvgggdk...",
		".kvgggdk....",
		"kvkkkkk.....",
		"kk..........",
		"............",
	], {"k": _OUTLINE, "g": Color("#5fae4b"), "d": Color("#3f7a2a"), "v": Color("#2c5a1f")}, 3)
	return _leaf_tex

class_name GameSprites

static var _cat_tex: ImageTexture
static var _gem_tex: ImageTexture
static var _bin_tex: ImageTexture
static var _grass_tex: ImageTexture
static var _dirt_tex: ImageTexture


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

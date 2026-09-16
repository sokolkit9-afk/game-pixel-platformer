## Помощник для нарезки тайлсетов Kenney на отдельные текстуры.
##
## Ассеты лежат двумя «упакованными» листами (packed) без отступов между
## тайлами, поэтому регион любого тайла считается простым умножением.
class_name Tiles
extends RefCounted

## Размер тайла ландшафта и предметов.
const TILE := 18
## Размер тайла с персонажами.
const CHAR_TILE := 24

# --- Ландшафт ---
# Колонка 2 листа — единственная, где тайлы полностью непрозрачны и стыкуются
# сами с собой без швов. Строка 0 — трава, строка 6 — гладкая почва.
## Верхний тайл земли с травой.
const GRASS := Vector2i(2, 0)
## Заливка земли под травой.
const DIRT := Vector2i(2, 6)

# --- Предметы ---
const COIN := Vector2i(11, 7)
const GEM := Vector2i(7, 3)
const HEART := Vector2i(4, 2)
const HEART_EMPTY := Vector2i(6, 2)

# --- Декор ---
const BUSH := Vector2i(4, 6)
const MUSHROOM := Vector2i(8, 6)
const CACTUS := Vector2i(7, 6)
const PINE := Vector2i(6, 6)
const SIGN := Vector2i(4, 4)
const FENCE := Vector2i(5, 5)
const CRATE := Vector2i(11, 5)
const BARREL := Vector2i(10, 6)
const CLOUD := Vector2i(14, 7)

# --- Финиш: флагшток. Полотнище рисуется вектором, см. goal.gd ---
const POLE := Vector2i(9, 5)
const POLE_TOP := Vector2i(9, 4)

# --- Цифры для счёта: строка 8, колонки 0..9 ---
const DIGIT_ROW := 8

static var _tiles_sheet: Texture2D = null
static var _chars_sheet: Texture2D = null
## Кэш нарезанных тайлов: один AtlasTexture на координату вместо сотен копий.
static var _cache: Dictionary = {}


static func sheet_tiles() -> Texture2D:
	if _tiles_sheet == null:
		_tiles_sheet = load("res://assets/tiles.png")
	return _tiles_sheet


static func sheet_characters() -> Texture2D:
	if _chars_sheet == null:
		_chars_sheet = load("res://assets/characters.png")
	return _chars_sheet


## Тайл ландшафта по координатам (колонка, строка) в листе.
static func tile(at: Vector2i) -> AtlasTexture:
	return _make(sheet_tiles(), TILE, at.x, at.y)


## Спрайт персонажа по координатам (колонка, строка) в листе.
static func character(at: Vector2i) -> AtlasTexture:
	return _make(sheet_characters(), CHAR_TILE, at.x, at.y)


## Тайл с цифрой 0..9.
static func digit(value: int) -> AtlasTexture:
	return _make(sheet_tiles(), TILE, clampi(value, 0, 9), DIGIT_ROW)


static func _make(sheet: Texture2D, size: int, col: int, row: int) -> AtlasTexture:
	var key := "%d:%d:%d:%d" % [sheet.get_instance_id(), size, col, row]
	if _cache.has(key):
		return _cache[key]
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(col * size, row * size, size, size)
	# Без этого соседние тайлы «протекают» по краям при масштабировании.
	atlas.filter_clip = true
	_cache[key] = atlas
	return atlas

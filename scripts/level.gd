## Строит уровень из текстовой карты.
##
## Каждый символ карты — один тайл 18×18. Ландшафт расставляется с
## автотайлингом (трава сверху, земля внутри, кромки по бокам), а коллизия
## собирается горизонтальными полосами, чтобы не плодить сотни шейпов.
class_name Level
extends Node2D

## Карта уровня. Расшифровка символов — в CHAR_* ниже.
const MAP := [
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	".........................................................................................*..........",
	"........................................................................................oo..........",
	"..................................................*................................fooo.##..........",
	".............o...............oo................oof##....................f...........###.##..........",
	".......ooo...+...ooo........###.....ooo........##.##...ooo....oo..+.oo.oo...ooo.....###.............",
	"..P...s...........e..b..m...###..c......e......##.........e...n..r...........t..e.............b.G.k.",
	"############...############.....##############.......##################...##########################",
	"############...############.....##############.......##################...##########################",
	"############...############.....##############.......##################...##########################",
	"############...############.....##############.......##################...##########################",
]

const CHAR_SOLID := "#"
const CHAR_PLAYER := "P"
const CHAR_GOAL := "G"
const CHAR_COIN := "o"
const CHAR_GEM := "*"
const CHAR_HEART := "+"
const CHAR_WALKER := "e"
const CHAR_FLYER := "f"

## Декор: символ карты -> координаты тайла в листе. Vector2i(-1, -1) — не декор.
static func decor_tile(c: String) -> Vector2i:
	match c:
		"b":
			return Tiles.BUSH
		"m":
			return Tiles.MUSHROOM
		"c":
			return Tiles.CACTUS
		"t":
			return Tiles.PINE
		"s":
			return Tiles.SIGN
		"n":
			return Tiles.FENCE
		"k":
			return Tiles.CRATE
		"r":
			return Tiles.BARREL
	return Vector2i(-1, -1)

## Сколько облаков насыпать на небе и в каких пределах по высоте.
const CLOUD_CLUSTERS := 26
const CLOUD_MIN_Y := 10.0
const CLOUD_MAX_Y := 78.0
## Фиксированный seed — небо одинаковое при каждом запуске.
const CLOUD_SEED := 20260916

var width := 0
var height := 0

## Слой неба: двигается медленнее мира, создавая параллакс.
var sky: Node2D = null

var player_spawn := Vector2.ZERO
var goal_cell := Vector2i(-1, -1)
var walker_cells: Array[Vector2i] = []
var flyer_cells: Array[Vector2i] = []
## Пары [ячейка, вид предмета]: "coin" | "gem" | "heart".
var pickup_cells: Array = []

var _grid: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_parse()
	_build_sky()
	_build_terrain()
	_build_decor()


## Размер уровня в пикселях — нужен камере для ограничения обзора.
func pixel_size() -> Vector2:
	return Vector2(width * Tiles.TILE, height * Tiles.TILE)


## Центр тайла в мировых координатах.
static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * Tiles.TILE + Tiles.TILE * 0.5,
		cell.y * Tiles.TILE + Tiles.TILE * 0.5
	)


func _parse() -> void:
	height = MAP.size()
	for line in MAP:
		width = maxi(width, line.length())

	var padded := PackedStringArray()
	for row in MAP:
		var l: String = row
		if l.length() < width:
			l += ".".repeat(width - l.length())
		padded.append(l)
	_grid = padded

	walker_cells.clear()
	flyer_cells.clear()
	pickup_cells.clear()

	for y in height:
		var line := _grid[y]
		for x in width:
			var c := line[x]
			match c:
				CHAR_PLAYER:
					# Спавн ставим ногами на тайл под символом.
					player_spawn = cell_center(Vector2i(x, y)) + Vector2(0, Tiles.TILE * 0.5)
				CHAR_GOAL:
					goal_cell = Vector2i(x, y)
				CHAR_WALKER:
					walker_cells.append(Vector2i(x, y))
				CHAR_FLYER:
					flyer_cells.append(Vector2i(x, y))
				CHAR_COIN:
					pickup_cells.append([Vector2i(x, y), "coin"])
				CHAR_GEM:
					pickup_cells.append([Vector2i(x, y), "gem"])
				CHAR_HEART:
					pickup_cells.append([Vector2i(x, y), "heart"])


func _is_solid(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return _grid[y][x] == CHAR_SOLID


## Раскладывает облака по небу. Позицию самого слоя двигает game.gd.
func _build_sky() -> void:
	sky = Node2D.new()
	sky.name = "Sky"
	sky.z_index = -10
	add_child(sky)

	var rng := RandomNumberGenerator.new()
	rng.seed = CLOUD_SEED
	var limit := pixel_size().x + 80.0
	for i in CLOUD_CLUSTERS:
		var x := rng.randf_range(-80.0, limit)
		var y := rng.randf_range(CLOUD_MIN_Y, CLOUD_MAX_Y)
		var count := rng.randi_range(2, 4)
		for j in count:
			var cloud := Sprite2D.new()
			cloud.texture = Tiles.tile(Tiles.CLOUD)
			cloud.position = Vector2(x + j * Tiles.TILE, y)
			cloud.modulate.a = rng.randf_range(0.55, 0.9)
			sky.add_child(cloud)


func _build_terrain() -> void:
	var terrain := StaticBody2D.new()
	terrain.name = "Terrain"
	terrain.collision_layer = 1
	terrain.collision_mask = 0
	add_child(terrain)

	var art := Node2D.new()
	art.name = "Art"
	add_child(art)

	for y in height:
		var x := 0
		while x < width:
			if not _is_solid(x, y):
				x += 1
				continue
			# Длина сплошной полосы в этой строке.
			var run := 1
			while x + run < width and _is_solid(x + run, y):
				run += 1
			# Спрайт — на КАЖДУЮ клетку полосы, иначе земля рисуется столбиками.
			for i in run:
				_add_tile_sprite(art, x + i, y)
			# А коллизия — одна на всю полосу, чтобы не плодить сотни шейпов.
			var shape := RectangleShape2D.new()
			shape.size = Vector2(run * Tiles.TILE, Tiles.TILE)
			var body := CollisionShape2D.new()
			body.shape = shape
			body.position = Vector2(
				(x + run * 0.5) * Tiles.TILE,
				(y + 0.5) * Tiles.TILE
			)
			terrain.add_child(body)
			x += run


func _add_tile_sprite(parent: Node2D, x: int, y: int) -> void:
	var surface := not _is_solid(x, y - 1)
	var sprite := Sprite2D.new()
	sprite.texture = Tiles.tile(Tiles.GRASS if surface else Tiles.DIRT)
	sprite.position = cell_center(Vector2i(x, y))
	parent.add_child(sprite)


func _build_decor() -> void:
	var art := Node2D.new()
	art.name = "Decor"
	add_child(art)

	for y in height:
		var line := _grid[y]
		for x in width:
			var at := decor_tile(line[x])
			if at.x < 0:
				continue
			var sprite := Sprite2D.new()
			sprite.texture = Tiles.tile(at)
			sprite.position = cell_center(Vector2i(x, y))
			art.add_child(sprite)

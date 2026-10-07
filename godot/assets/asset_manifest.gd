extends Node
## The swap table. Autoloaded as `Assets`.
##
## Every asset ID from CHANGE-BRIEF.md resolves here and nowhere else.
## An empty path means "use the generated placeholder". To drop in a real
## file, replace "" with its res:// path -- that is the whole change.

const PlaceholderFactory = preload("res://assets/placeholder_factory.gd")

const ART := {
	"CHAR-IDLE": "res://art/char_idle.png",
	"CHAR-WALK": "",
	"CHAR-AIM": "res://art/char_aim.png",
	"CHAR-SHOOT-FOLLOWTHROUGH": "res://art/char_shoot.png",
	"CHAR-HURT": "res://art/char_hurt.png",
	"CHAR-GRABBED-FAIL": "res://art/char_grabbed.png",
	"CHAR-RECOVER": "",
	"CHAR-CELEBRATE": "",
	"ZOMBIE-SHAMBLE": "",
	"ZOMBIE-DOWN": "",
	"ENV-FACTORY-FLOOR": "",
}

const AUDIO := {
	"SFX-SHOT": "",
	"SFX-DOWN": "",
	"SFX-HURT": "",
	"SFX-CLEAR": "",
	# A real MUS-LOOP file also needs Loop enabled in its Import settings.
	"MUS-LOOP": "",
}

var _textures := {}
var _streams := {}


func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		assert(ART.has(id), "Unknown art ID: %s" % id)
		var path: String = ART[id]
		_textures[id] = load(path) if path != "" else PlaceholderFactory.make_texture(id)
	return _textures[id]


func stream(id: String) -> AudioStream:
	if not _streams.has(id):
		assert(AUDIO.has(id), "Unknown audio ID: %s" % id)
		var path: String = AUDIO[id]
		_streams[id] = load(path) if path != "" else PlaceholderFactory.make_stream(id)
	return _streams[id]

extends RefCounted
## Shared read-back helpers for the A7 clip tests. Written by Claude Code.
##
## track_problems(anim, root) returns one string per track that does not
## resolve, branched on the track type:
##   TYPE_VALUE / TYPE_BEZIER: the node exists under `root` and the property
##       (with any sub-property, e.g. position:x) exists on it;
##   TYPE_POSITION_3D / ROTATION_3D / SCALE_3D: the node exists and is a
##       Node3D, or a Skeleton3D whose subname is a real bone;
##   TYPE_BLEND_SHAPE: the node is a MeshInstance3D whose mesh has the
##       named blend shape;
##   TYPE_METHOD: the node exists and has the method named in every key;
##   anything else (audio, animation): the node exists.
## The 3D bone and blend-shape branches are here for completeness; the A7
## rigs are 2D and have none.

const TYPE_NAMES := {
	Animation.TYPE_VALUE: "value", Animation.TYPE_POSITION_3D: "position_3d",
	Animation.TYPE_ROTATION_3D: "rotation_3d", Animation.TYPE_SCALE_3D: "scale_3d",
	Animation.TYPE_BLEND_SHAPE: "blend_shape", Animation.TYPE_METHOD: "method",
	Animation.TYPE_BEZIER: "bezier", Animation.TYPE_AUDIO: "audio",
	Animation.TYPE_ANIMATION: "animation",
}


static func type_name(t: int) -> String:
	return TYPE_NAMES.get(t, "type %d" % t)


static func _has_property(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p.name == prop:
			return true
	return false


static func track_problems(anim: Animation, root: Node) -> Array[String]:
	var out: Array[String] = []
	for i in anim.get_track_count():
		var path := anim.track_get_path(i)
		var t := anim.track_get_type(i)
		var node_path := NodePath(String(path.get_concatenated_names()))
		var node: Node = root.get_node_or_null(node_path) if path.get_name_count() > 0 else root
		var where := "track %d (%s) '%s'" % [i, type_name(t), path]
		if node == null:
			out.append("%s: no node '%s' under %s" % [where, node_path, root.name])
			continue
		var subs := String(path.get_concatenated_subnames())
		match t:
			Animation.TYPE_VALUE, Animation.TYPE_BEZIER:
				if subs.is_empty():
					out.append("%s: no property named" % where)
					continue
				var first := path.get_subname(0)
				if not _has_property(node, first):
					out.append("%s: %s has no property '%s'" % [where, node.get_class(), first])
					continue
				if path.get_subname_count() > 1 and node.get_indexed(NodePath(":" + subs)) == null:
					out.append("%s: '%s' does not resolve on %s" % [where, subs, node.get_class()])
			Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D:
				if node is Skeleton3D and not subs.is_empty():
					if (node as Skeleton3D).find_bone(subs) < 0:
						out.append("%s: skeleton has no bone '%s'" % [where, subs])
				elif not (node is Node3D):
					out.append("%s: %s is not a Node3D" % [where, node.get_class()])
			Animation.TYPE_BLEND_SHAPE:
				var mi := node as MeshInstance3D
				if mi == null or mi.mesh == null or mi.find_blend_shape_by_name(StringName(subs)) < 0:
					out.append("%s: no blend shape '%s'" % [where, subs])
			Animation.TYPE_METHOD:
				for k in anim.track_get_key_count(i):
					var m := String(anim.method_track_get_name(i, k))
					if not node.has_method(m):
						out.append("%s: no method '%s'" % [where, m])
			_:
				pass
	return out


## Key times of track `i`.
static func key_times(anim: Animation, i: int) -> Array[float]:
	var out: Array[float] = []
	for k in anim.track_get_key_count(i):
		out.append(anim.track_get_key_time(i, k))
	return out


static func find_track(anim: Animation, path: String) -> int:
	for i in anim.get_track_count():
		if String(anim.track_get_path(i)) == path:
			return i
	return -1

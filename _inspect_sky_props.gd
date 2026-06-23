extends SceneTree
func _init():
	var mat := ProceduralSkyMaterial.new()
	for p in mat.get_property_list():
		var name: String = p.name
		if name.contains("sun"):
			print(name)
	quit()

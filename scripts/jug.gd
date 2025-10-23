extends Node3D
class_name JuiceJug  # optional, gives a type name for casting

var layers: int
var juice_layers = []
var top_layer: int

func create(n):
	layers = n
	var juice_invis = $juice_invis
	var colors = []
	var increment = 1/float(n)
	for i in n:
		colors.append(Color(1-increment*i,increment*i,0))
	top_layer = layers-1
	var x = float(1)/layers
	var full_height = juice_invis.get_aabb().size.y
	var layer_height = full_height/layers
	for i in range(layers):
		var juice_layer = juice_invis.duplicate()
		var mat = StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		juice_layer.material_override = mat
		juice_layer.scale = Vector3(1.3 + 0.01*i, 1.3*x, 1.3 + 0.01*i)
		juice_layer.position.y += -full_height/2 + layer_height*i +  layer_height/2
		juice_layer.visible = true
		add_child(juice_layer)
		juice_layers.append(juice_layer)

func drink():
	if top_layer >= 0:
		juice_layers[top_layer].visible = false
		top_layer -= 1

func is_empty() -> bool:
	return top_layer < 0

func refill():
	top_layer += 1
	if top_layer > layers-1:
		top_layer = layers-1
	juice_layers[top_layer].visible = true

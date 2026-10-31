extends SceneTree
func _initialize() -> void:
	var p=JSON.parse_string('{"version":1,"checkpoint":3,"boss":true,"dash":true,"fragment":true,"habitat":true,"complete":true}')
	print("version=",p.version==1," cp=",p.checkpoint in [0,3]," cpnot=",not p.get("checkpoint",-1) in [0,3]," type=",typeof(p.checkpoint))
	for k in ["boss","dash","fragment","habitat","complete"]: print(k," bool ",p.get(k) is bool," not=",not p.get(k) is bool)
	quit()

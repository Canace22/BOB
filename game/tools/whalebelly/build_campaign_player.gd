@warning_ignore_start("untyped_declaration")
extends SceneTree
func _initialize() -> void:
	var player=load("res://content/whalebelly/Player.tscn").instantiate()
	preload("res://src/campaign/campaign_profile.gd").apply(player)
	player.world_collision_mask=5
	var output:String='[gd_scene load_steps=3 format=3]\n\n[ext_resource type="PackedScene" path="res://content/whalebelly/Player.tscn" id="1"]\n[ext_resource type="Script" path="res://src/campaign/campaign_player.gd" id="2"]\n\n[node name="Player" instance=ExtResource("1")]\nscript = ExtResource("2")\n'
	for line in FileAccess.get_file_as_string("res://src/campaign/campaign_profile.gd").split("\n"):
		if line.strip_edges().begins_with("player."):
			var key:String=line.strip_edges().split("=")[0].trim_prefix("player.")
			output+=key+" = "+var_to_str(player.get(key))+"\n"
	var f:=FileAccess.open("res://content/whalebelly/CampaignPlayer.tscn",FileAccess.WRITE);f.store_string(output);f.close()
	player.free();print("CAMPAIGN_SCENE_BUILT");quit()

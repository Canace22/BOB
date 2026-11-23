extends TestSuite
## 同一命中时钟下核对发力停留；格挡受力帧只由成功事件驱动。

func test_basic_slashes_hold_contact_pose_and_finish_recovery() -> void:
	var phases:=TideVisualPhaseMap.new()
	var manifest: Dictionary=phases.load_manifest("res://art/tide-picker-action36/")
	for key: String in ["strike1","strike2"]:
		var spec: Dictionary=manifest[key]
		var event: float=float(spec.event_phase)
		for progress: float in [0.08,0.16,0.25,0.32]:
			eq(phases.index_from_context(key,spec,lerpf(event,1.0,progress),{}),7,"contact drawing stays planted during follow-through hold")
		eq(phases.index_from_context(key,spec,0.999,{}),15,"hold still reaches complete recovery")
		eq(phases.index_from_context(key,spec,event-0.0001,{}),5,"loaded pose remains before real release")

func test_block_reaction_uses_new_drawings_without_changing_guard_clock() -> void:
	var phases:=TideVisualPhaseMap.new()
	var manifest: Dictionary=phases.load_manifest("res://art/tide-picker-action36/")
	var context: Dictionary={"active":true,"visual_key":"parry","elapsed":0.48,"duration":0.70,"release":0.02,"parry_end":0.55,"clock":0.1}
	var held: int=phases.index_from_context("parry",manifest.parry,0.25,context)
	check(held in [3,4,5,6],"idle guard uses the braced stance, not contact recoil")
	context.guard_impact_age=0.04
	eq(phases.index_from_context("parry",manifest.parry,0.25,context),8,"successful block compresses behind the weapon")
	context.guard_impact_age=0.16
	eq(phases.index_from_context("parry",manifest.parry,0.25,context),11,"body pushes back into guard")
	eq(context.elapsed,0.48,"presentation leaves defense timing untouched")

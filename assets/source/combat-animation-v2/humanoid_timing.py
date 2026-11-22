"""人形动作的蓄势/爆发节奏；只重排现有帧，不修改技能执行器。"""
import copy

HUMANOIDS = {'pump_warden', 'beam_guard', 'elder_guardian'}
PREPARE = [0.0, 0.04, 0.18, 0.40, 0.66, 0.84]
RECOVER = [0.0, 0.08, 0.20, 0.40, 0.66, 0.88]
# 仅供没有角色上下文的静态夹具使用；实机传入当前阶段实际时长。
ACTIVE_DURATIONS = {
    'warden_barrage': 0.65, 'warden_vortex': 0.55, 'warden_waterstep': 0.20,
    'warden_thrust': 0.16, 'warden_push': 0.25, 'warden_double': 0.14,
    'beam_press': 0.22, 'beam_return': 0.24, 'beam_brace': 0.18, 'beam_riposte': 0.20,
    'elder_sweep': 0.24, 'elder_thrust': 0.25, 'elder_grip': 0.18, 'elder_vault': 0.18,
}


def schedule(clip, drawings, times, seconds=False):
    assert len(drawings) == len(times)
    clip['frames'] = [dict(copy.deepcopy(frame), at=at) for frame, at in zip(drawings, times)]
    if seconds:
        clip['time_unit'] = 'seconds'
        clip['reference_duration'] = ACTIVE_DURATIONS[clip['action']]
    clip['timing_basis'] = 'slow load / fast contact / weighted follow-through; presentation only'


def apply(merged):
    for profile in HUMANOIDS:
        entry = merged['enemies'][profile]
        vault = next(clip for clip in entry['clips'] if clip['action'] == 'elder_vault' and clip['state'] == 'tell') if profile == 'elder_guardian' else None
        for kind in ['clips', 'windups']:
            for clip in entry[kind]:
                frames = clip['frames']
                action, state = clip['action'], clip['state']
                # 防御举架保持原来的及时到位；复制释放仍由幻影执行器拥有。
                if action == 'beam_guard':
                    continue
                if state in ['tell', 'reform'] and len(frames) == 6:
                    schedule(clip, frames, PREPARE)
                elif kind == 'clips' and state == 'recover' and len(frames) == 6:
                    schedule(clip, frames, RECOVER)
                if kind != 'clips' or state != 'active' or action not in ACTIVE_DURATIONS:
                    continue
                if action == 'elder_vault':
                    continue
                if action == 'warden_barrage':
                    # 三枚水弹分别在0.04/0.26/0.48秒实际发射，不把整段做成一次慢推手。
                    drawings, times = [], []
                    for start in [0.0, 0.22, 0.44]:
                        drawings.extend(frames)
                        times.extend([start + value for value in [0.0, 1.0 / 60.0, 0.04, 0.085]])
                    schedule(clip, drawings, times, seconds=True)
                elif len(frames) == 4:
                    contact = 0.06 if profile == 'pump_warden' else 0.04
                    schedule(clip, frames, [0.0, 1.0 / 60.0, contact, contact + 0.045], seconds=True)
        if vault is not None:
            # 第10张仍是双脚悬空的下降姿势；落地仅保持第11张，再于命中进入第12张。
            source = next(clip for clip in entry['clips'] if clip['action'] == 'elder_vault' and clip['state'] == 'recover')
            recovery = source['frames']
            # 已复核第11张脚底y=241，原按行中位数登记为220；只改枢轴，不缩放身体。
            recovery[1]['pivot'][1] = 241
            recovery[1]['ground_contact'] = [165, 241]
            for clip in entry['clips']:
                if clip['action'] != 'elder_vault':
                    continue
                if clip['state'] == 'settle':
                    schedule(clip, recovery[1:2], [0.0])
                elif clip['state'] == 'active':
                    schedule(clip, recovery[1:3], [0.0, 0.04], seconds=True)
                elif clip['state'] == 'recover':
                    schedule(clip, recovery[3:], [0.0, 0.30, 0.68])

"""复用已验像素裁片流程，补全真实返回/回稳阶段并替换弱准备动作。"""
from pathlib import Path
import importlib.util
import json

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
spec = importlib.util.spec_from_file_location('special', BASE / 'build_special.py')
special = importlib.util.module_from_spec(spec)
spec.loader.exec_module(special)


def main():
    config = {'schema_version': 1, 'enemies': {}}
    reports = []
    for profile, action in [('membrane_hunter', 'hunter_return'),
                            ('elder_guardian', 'elder_reground'),
                            ('mudback', 'press'), ('shell_guard', 'shell_push')]:
        packed, report = special.extract({'profile': profile, 'action': action})
        assert packed is not None, report
        if action == 'elder_reground':
            # 首帧是下蹲，取末帧立稳的实体高度作为统一标尺，不能把蹲姿放大成站高。
            box = report['frames'][-1]['coreBBox']
            packed['reference_height'] = box[3] - box[1]
            report['reference_height'] = packed['reference_height']
            report['scale_basis'] = 'last authored standing frame, not first crouched frame'
            for previous in ['elder_sweep', 'elder_thrust', 'elder_grip', 'elder_vault', 'elder_mimic']:
                special.add_clip(config, packed, 'reground', list(range(16)), action=previous,
                                 source_note='real replant keeps preceding move_key; shared authored recovery')
        elif action == 'hunter_return':
            for previous in ['hunter_pounce', 'hunter_glide', 'hunter_drop', 'hunter_escape']:
                special.add_clip(config, packed, 'return', list(range(16)), action=previous,
                                 source_note='real return keeps preceding move_key; authored swim')
        else:
            for state, frames in special.PHASES.items():
                special.add_clip(config, packed, state, frames)
            report['supersedes'] = f'{profile}-{action}.png'
        reports.append(report)
    special.OUT.joinpath('animations-followup.json').write_bytes(
        (json.dumps(config, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))
    HERE.joinpath('production.json').write_bytes(
        (json.dumps({'authored_frames': 64, 'actions': reports}, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))
    print('followup: 4 sheets / 64 authored frames; 2 replacements and 2 missing phase sequences')


if __name__ == '__main__':
    main()

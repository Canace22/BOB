"""Generate the action36 coverage document from actual manifests and hash-bound evidence.

Read-only except docs/action36-asset-coverage.md. Does not run Godot or promote assets.
Usage from repository root: python build_asset_coverage.py
"""
from pathlib import Path
import hashlib
import json

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT/'assets/source/tide-picker-action36'
RUNTIME=ROOT/'assets/runtime/sprites/tide-picker-action36'

def read(path,default=None):
    return json.loads(path.read_text(encoding='utf-8-sig')) if path.exists() else default

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

def source_link(value):
    if not value:return '来源未记载'
    normalized=str(value).replace('\\','/')
    return f'[{normalized.rsplit("/",1)[-1]}](<{normalized}>)'

def source_kind(spec):
    kind=str(spec.get('source_kind','')).lower()
    return 'AI补制精灵表' if 'sheet' in kind or spec.get('source_grid') else '视频提取'

def review_status(validation,key,hashes):
    record=validation.get('actions',{}).get(key,{})
    matched=all(layer in record.get('hashes',{}) and record['hashes'][layer]==hashes[layer] for layer in ('body','fx'))
    result={}
    for stage in ('technical','runtime','art'):
        value=record.get(stage,{})
        complete=(isinstance(value,dict) and value.get('reviewer') and value.get('reviewed_at') and
                  isinstance(value.get('evidence'),list) and bool(value['evidence']) and
                  all(isinstance(item,str) and item.strip() for item in value['evidence']))
        result[stage]=value.get('status','pending') if matched and complete else 'pending'
    return result

def main():
    manifest_path=RUNTIME/'animations.json'
    actions=read(manifest_path)['actions']
    validation=read(SOURCE/'validation.json',{'actions':{}})
    integrity=read(ROOT/'game/build/qa/action36/atlas-integrity.json',{})
    integrity_rows={row['key']:row for row in integrity.get('actions',[])}
    controls=(ROOT/'docs/action36-controls.md').read_text(encoding='utf8')
    mappings={}
    for line in controls.splitlines():
        if not line.startswith('| '):continue
        cells=[cell.strip() for cell in line.strip('|').split('|')]
        key=cells[0].split(' ')[0]
        if key in actions and len(cells)==6:mappings[key]=cells
    if len(actions)!=36 or set(actions)!=set(mappings):raise ValueError('Expected exactly 36 explicit controls/manifest mappings')
    lines=[
        '# 拾潮者36项资产与逻辑覆盖',
        '',
        '由仓库根目录 `build_asset_coverage.py` 根据实际 `animations.json`、[操作映射](action36-controls.md)、独立 `validation.json`（存在时）和哈希绑定的图集完整性报告生成。重跑：`python build_asset_coverage.py`。本表不会写入验收状态或修改运行清单。',
        '',
        f'动画清单 SHA-256：`{sha(manifest_path)}`。',
        '',
        '技术完整性只包含源/图集帧数、字节哈希、透明边界和矩形范围；不代表操控、美术或正式取得流程通过。逻辑回归与GPU外观分别记录，最终日志见 `game/build/qa/action36/tests-final.log`；不能以逻辑测试替代外观结论。逐项实机/美术状态仅采用当前图集哈希匹配且证据完整的 validation 记录；缺失时明确待验，候选不自动升格。',
        '',
        '表内FPS是素材名义帧率；运行时走跑由位移驱动，攻击按事件重映射，跳跃/下砸/长冲按物理阶段选择，并不播放整段展示视频。左右使用一套图集的一次 facing 镜像；腰灯/持叉手遵循整体2D镜像规范。',
        '',
        '| key / 名称 | 逻辑ID / 现有实现 | 本体来源与当前采用 | 帧数 / FPS | FX分层与来源 | 本批类型 | 技术 / 实机 / 美术 | 验收入口（两向） |',
        '|---|---|---|---|---|---|---|---|',
    ]
    technical_count=0
    for key,cells in mappings.items():
        action=actions[key];body=action['body'];fx=action.get('fx')
        hashes={layer:sha(RUNTIME/Path(action[layer]['texture']).name) if action.get(layer) else None for layer in ('body','fx')}
        states=review_status(validation,key,hashes)
        row=integrity_rows.get(key,{})
        technical=(not integrity.get('errors',['missing']) and not integrity.get('warnings',['missing']) and
                   all(hashes[layer]==row.get('layers',{}).get(layer,{}).get('sha256')==action[layer].get('sha256') for layer in ('body','fx') if action.get(layer)))
        technical_count+=int(technical)
        technical_label='完整性通过' if technical else '待验/报告过期'
        if states['technical']=='failed':technical_label='验收失败'
        runtime_label={'passed':'证据通过','failed':'失败','pending':'待最终GPU'}.get(states['runtime'],'待验')
        art_label={'passed':'独立审阅通过','failed':'失败','pending':'候选待验'}.get(states['art'],'待验')
        reused=''
        if key=='shadow_dash':reused='；复用dash本体，冷青色调'
        elif key=='dark_dive':reused='；复用dive本体及地面环'
        source=body.get('source',action.get('source'))
        source_description=source_kind(action)+' '+source_link(source)+reused
        fx_notes=[]
        if fx:
            space='世界地面环' if key in ('heavy','dive','dark_dive','scan') else '角色局部层'
            count=fx.get('frame_count',action['frame_count'])
            event=f'，event_frame={fx["event_frame"]}' if 'event_frame' in fx else ''
            fx_source=fx.get('source',action.get('source'))
            fx_notes.append(f'{space} {count}帧{event}；'+('同源拆分' if fx_source==source else source_link(fx_source)))
        else:fx_notes.append('无独立图集FX')
        if key in ('dash','shadow_dash','crystal_dash','slit'):fx_notes.append('历史本体快照残影，世界空间')
        if key in ('orb','shadow_orb'):fx_notes.append(('shadow_projectile.png' if key=='shadow_orb' else 'projectile.png')+'离体弹体；来源见effects-sources.json')
        if key=='anchor':fx_notes.append('tether.png世界位图绳；来源见effects-sources.json')
        if key=='parry':fx_notes.append('成功时复用projectile.png闪光；窗口开始不播放')
        batch='复用现有源片并返修抠像/配准'
        if 'sprite-sheets' in str(source):batch='新增AI精灵表替换缺陷视频本体'
        elif '/jobs/' in str(source).replace('\\','/'):batch='新增AI补制视频并提取本体'
        if key in ('shadow_dash','dark_dive'):batch='复用修复本体，保留独立升级逻辑'
        entry=f'{cells[2]}；{cells[3]}；{cells[5]}'
        if key in ('swim','tram'):entry+='；独立最小条件，非正式七房已配置'
        else:entry+='；主场景/隔离F9'
        values=[f'`{key}` {action["title"]}',cells[1]+'；'+cells[4],source_description,
                f'{action["frame_count"]} / {action["fps"]}', '；'.join(fx_notes),batch,
                f'{technical_label} / {runtime_label} / {art_label}',entry]
        lines.append('| '+' | '.join(str(value).replace('|','/').replace('\n',' ') for value in values)+' |')
    lines.extend(['',f'当前哈希匹配的完整性通过：**{technical_count}/36**；报告错误 {len(integrity.get("errors",[]))}，警告 {len(integrity.get("warnings",[]))}。',
                  '', '验收脚本：`game/tests/whalebelly/action36_coverage.gd` 通过正式主场景共享角色检查两向；记录带 `practice_only_evidence`，包含按键/API和临时条件，不等同于操作系统键盘全流程。正式解锁、可照做路线、取消规则与参数见[操作说明](action36-controls.md)。最终录屏、性能、发布和未完成项以[进度](../game/progress.md)及独立验收记录为准。',
                  '', 'FX独立帧数以图层自己的 `frame_count` 为准，世界环从 `event_frame` 开始，生命周期由真实释放/落地事件决定。本批heavy/dive/dark_dive共享独立纯地环，峰值起播并按范围等比缩放；升级深钟复用基础下砸本体，差异为伤害、范围、深青色调和落地保护，未虚构一套新身体动画。', ''])
    out=ROOT/'docs/action36-asset-coverage.md'
    out.write_text('\n'.join(lines),encoding='utf8',newline='\n')
    print(json.dumps({'path':str(out),'actions':len(mappings),'technical_hash_matched':technical_count,'validation_present':(SOURCE/'validation.json').exists()}))

if __name__=='__main__':main()

"""Register this batch only, preserving unrelated catalog entries."""
import json
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
NAMES = {"sweep_tell": "低扫蓄力", "sweep_active": "低扫挥出", "slam_tell": "双钳抬高", "slam_active": "双钳下砸", "charge": "收钳横冲"}


def main():
    report = json.loads((HERE / "export.json").read_text(encoding="utf-8"))
    path = ROOT / "assets/catalog.json"
    catalog = json.loads(path.read_text(encoding="utf-8"))
    for item in report["assets"]:
        key = item["key"]
        if key == "idle":
            continue  # Derived existing art does not count as new artwork.
        asset_id = "mother-crab-prototype-" + key.replace("_", "-")
        prompts = [f"assets/source/crab-boss-prototype/prompts/{key}.txt"]
        if key == "sweep_active":
            prompts.append("assets/source/crab-boss-prototype/prompts/sweep-active-correction.txt")
        entry = {
            "id": asset_id, "name": "搬壳母蟹 · " + NAMES[key], "kind": "character", "region": "R1",
            "tags": ["Boss原型", "母蟹", "关键静态姿态"], "status": "accepted", "target": "2d",
            "notes": "用户选定巨大搬壳母蟹身份；关键静态姿态，非逐帧动画；实机验收见 game/progress.md。",
            "file": item["file"], "width": 1024, "height": 768, "bbox": item["alphaBboxes"]["8"],
            "pivot": report["pivot"], "sha256": item["sha256"], "alphaRange": item["alphaRange"],
            "alphaBboxes": item["alphaBboxes"], "spriteType": "static", "familyId": "shell-mother-crab",
            "source": {
                "batchId": "crab-boss-prototype", "method": "内置 imagegen 参考重绘；等比缩放与透明根对齐派生",
                "references": ["assets/source/crab-boss-prototype/references/shell-mother-crab.png"],
                "prompts": prompts, "originalId": key,
                "rights": "用户指定项目既有素材用于 BOB；无新增独立第三方授权声明"
            },
            "qa": {
                "scope": "静态透明边缘、统一比例与深浅背景合成；本地原型截图及真实按键路线通过，详见 game/progress.md", "passed": True,
                "limitations": ["关键姿态缺少帧间过渡，不是正式逐帧动画", "用户未确认美术；局部路线通过不等于完整平衡或跨设备验收"],
                "report": "assets/source/crab-boss-prototype/acceptance.md"
            },
            "integrationStatus": "integrated",
            "integration": {
                "version": "godot-crab-prototype", "date": "2026-10-28", "manifest": "game/art/manifest.json",
                "renderer": "game/src/enemies/crab_prototype/crab_visual.gd", "evidence": "game/progress.md",
                "scope": "已接入独立Godot原型；本地素材加载、截图与真实按键路线通过，线上状态以本轮发布记录为准",
                "runtimeFile": f"game/art/enemies/crab_prototype/{key}.png"
            }
        }
        index = next((i for i, value in enumerate(catalog["assets"]) if value["id"] == asset_id), None)
        if index is None:
            catalog["assets"].append(entry)
        else:
            catalog["assets"][index] = entry
    catalog["revision"] += 1
    catalog["updatedAt"] = datetime.now(timezone.utc).isoformat()
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Registered five mother-crab key poses; reused idle not counted as new art.")


if __name__ == "__main__":
    main()

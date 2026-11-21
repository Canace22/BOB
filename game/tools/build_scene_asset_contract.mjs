#!/usr/bin/env node
/** Build the auditable 19-room art/coordinate contract from current sources. */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const project = join(root, "..");
const read = (file) => JSON.parse(readFileSync(join(project, file), "utf8"));
const world = read("content/whalebelly/world/recipes/_world.json");
const anatomy = read("content/whalebelly/world/anatomy_map_contract.json");
const chapters = read("content/whalebelly/world/chapter_map.json");
const inventory = read("../assets/source/all-level-asset-split-v1/asset-inventory.json");
const motion = read("../assets/source/all-level-asset-split-v1/motion-coverage.json");
const baseRooms = read("art/whalebelly/rooms.json");
const rooms = read("content/whalebelly/world/rooms.json").rooms;
const byId = new Map([...baseRooms, ...rooms].map((room) => [room.id, room]));
const chapterByRoom = new Map();
for (const chapter of chapters.chapters) for (const id of chapter.rooms) chapterByRoom.set(id, chapter);
const assetByRoom = new Map();
for (const asset of inventory.assets) {
  for (const id of asset.rooms ?? []) {
    if (!assetByRoom.has(id)) assetByRoom.set(id, []);
    assetByRoom.get(id).push({ id: asset.id, category: asset.category, source: asset.source, runtime: asset.runtime ?? null, alpha: asset.has_alpha, status: asset.status });
  }
}

const formalIds = chapters.chapters.flatMap((chapter) => chapter.rooms);
const result = {
  version: 1,
  design: "V4/V5",
  sourceDesign: "G:/鲸落万物生/outputs/鲸落万物生_V5.2_完整游戏设计",
  sourceInventory: "assets/source/all-level-asset-split-v1/asset-inventory.json",
  guide: "docs/正式地图章节编排指南.md",
  roomCount: formalIds.length,
  coordinateContract: {
    originalArt: "anatomy_map_contract.rooms[*].rangePercent / expectedX",
    whaleWorld: "recipes/_world.json.map.world normalized [0..1]",
    gameWorld: "CampaignStreamingLayout.build(rooms).origins",
    streamingLocal: "content/whalebelly/world/rooms.json rooms[*].size/spawn/doors",
    note: "原画范围约束横向器官带；局部房间尺寸、碰撞和门点以正式运行数据为准。"
  },
  dynamicRoomCount: motion.dynamic_room_count,
  rooms: formalIds.map((id) => {
    const room = byId.get(id);
    const chapter = chapterByRoom.get(id) ?? {};
    const anatomyRoom = anatomy.rooms[id] ?? {};
    return {
      id,
      chapter: { id: chapter.id ?? "", index: chapter.index ?? 0, name: chapter.name ?? "" },
      anatomy: { rangePercent: anatomyRoom.rangePercent ?? [], expectedX: anatomyRoom.expectedX ?? null, anchor: anatomyRoom.anatomy ?? "" },
      whaleWorld: world.map.world[id] ?? null,
      gameScene: `res://content/whalebelly/${id.startsWith("R1-") ? "r1" : id.startsWith("R2-") ? "r2" : id.startsWith("R3-") ? "r3" : id.startsWith("R4-") ? "r4" : "r5"}/${id}.tscn`,
      streamingLocal: { size: room?.size ?? [], spawn: room?.spawn ?? room?.play_spawn ?? [], doors: (room?.doors ?? []).map((door) => ({ id: door.id ?? "", to_id: door.to_id ?? "", pos: door.pos ?? [] })) },
      assets: assetByRoom.get(id) ?? [],
      dynamic: motion.rooms[id] ?? []
    };
  })
};

const output = join(project, "content/whalebelly/world/scene_asset_coordinate_contract.json");
mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, `${JSON.stringify(result, null, 2)}\n`);
console.log(JSON.stringify({ output, rooms: result.roomCount, dynamicRoomCount: result.dynamicRoomCount, assets: inventory.asset_count }, null, 2));

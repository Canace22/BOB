# 美术资源预览与管理

在浏览器打开[线上美术资源预览](https://canace22.github.io/BOB/art/)，即可搜索、筛选和放大素材，下载原图、图集页面与清单，也能查看完整需求和场景拼装预览。

线上是只读快照。需要修改名称、标签、备注或验收状态时，在仓库根目录运行 `npm --prefix assets/manager start`，打开[本机管理页](http://127.0.0.1:4176/)。素材制作、入库与验收范围见[资源管理说明](../README.md)。

## 更新线上预览

在仓库根目录运行：

```sh
npm --prefix assets/manager run check
npm --prefix assets/manager test
node tools/deploy-art-pages.mjs
```

发布脚本从当前台账生成静态快照，复制页面实际使用的素材和制作来源，在现有 `gh-pages` 分支中更新 `/art/` 并正常推送。下载图集坐标后，可按索引中的文件名取得同目录下的全部图集 PNG 和 JSON；ZIP 仍在本机按需生成。

只生成本地预览可用 `node tools/deploy-art-pages.mjs --build-only`，输出到 `game/build/art-site/`。把这个目录作为静态服务根目录即可查看。源文件、缩略图或图集缺失会中止构建；已清理的可选制作参考会从发布快照的链接中省略，原台账保持原样。Git LFS 指针需要先执行 `git lfs pull` 取得实际内容。

推送后等待 GitHub Pages 部署成功，再检查线上页面及 `/BOB/art/build.json` 中的源码提交、台账摘要和文件摘要。每次发布使用当前工作区的台账与素材；构建清单中的摘要用于确认实际快照。发布和验证记录见[进度](progress.md)。

## 检查

`npm --prefix assets/manager run check` 检查页面、服务和发布脚本语法；`npm --prefix assets/manager test` 检查本机保存、冲突与访问限制。`test:ui` 在临时副本中验证编辑，不会修改实际台账。

生成静态预览后，运行 `npm --prefix assets/manager run test:preview`，在独立 Chrome 中检查子目录路径、图片、只读状态、筛选、下载、需求页往返与手机宽度。需要 Node.js 20+、Playwright 和 Chrome；可用 `PLAYWRIGHT_MODULE` 指定模块文件，用 `PLAYWRIGHT_CHANNEL` 选择其他已安装的浏览器。设置 `ART_PREVIEW_URL=https://canace22.github.io/BOB/art/` 可复测线上版本。截图输出到 `game/build/qa/art-preview/`，不提交。

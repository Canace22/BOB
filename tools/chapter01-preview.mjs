import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createServer} from 'node:http';
import os from 'node:os';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const game=path.join(root,'game');
const project=path.join(game,'build','chapter01-project');
const web=path.join(game,'build','chapter01-web');
const template=path.join(root,'.tools','godot-templates','web_nothreads_release.zip');
const version=fs.readFileSync(path.join(game,'.godot-version'),'utf8').trim();
const candidates=[process.env.GODOT,path.join(root,'.tools','godot',`Godot_v${version}-stable_win64_console.exe`),`F:/Godot_v${version}/Godot_v${version}-stable_win64_console.exe`].filter(Boolean);

function run(executable,args,cwd=root){
  const result=spawnSync(executable,args,{cwd,encoding:'utf8',maxBuffer:32*1024*1024});
  const output=(result.stdout??'')+(result.stderr??'');
  fs.mkdirSync(path.join(game,'build','qa','chapter01'),{recursive:true});
  fs.appendFileSync(path.join(game,'build','qa','chapter01','export.log'),output);
  if(result.status!==0 || /SCRIPT ERROR|Parse Error|^ERROR:/m.test(output)){process.stdout.write(output.slice(-16000));throw new Error('Godot command failed.');}
}

function copy(relative){
  const from=path.join(game,relative),to=path.join(project,relative);
  fs.mkdirSync(path.dirname(to),{recursive:true});
  fs.cpSync(from,to,{recursive:true,filter:file=>!file.endsWith('.import')});
}

function build(){
  const engine=candidates.find(file=>fs.existsSync(file));
  if(!engine)throw new Error(`Godot ${version} not found; set GODOT.`);
  const actual=spawnSync(engine,['--version'],{encoding:'utf8'}).stdout.trim();
  if(!actual.startsWith(version+'.stable.'))throw new Error(`Unexpected Godot: ${actual}`);
  if(!fs.existsSync(template))throw new Error('Place the matching official web_nothreads_release.zip in .tools/godot-templates/.');
  if(fs.existsSync(project)){
    if(fs.lstatSync(project).isSymbolicLink()||path.dirname(fs.realpathSync(project))!==fs.realpathSync(path.join(game,'build')))throw new Error('Linked preview staging.');
    fs.rmSync(project,{recursive:true});
  }
  fs.mkdirSync(project,{recursive:true});fs.mkdirSync(web,{recursive:true});
  fs.writeFileSync(path.join(game,'build','.gdignore'),'');
  copy('src/prototypes/chapter01');copy('content/prototypes/chapter01');
  copy('art/whalebelly/rooms.json');copy('art/fonts/WhalefallUI.ttf');copy('art/fonts/OFL.txt');
  copy('art/scenery/v02/gate.png');copy('art/whalebelly/animations/player/idle/000.png');
  copy('art/whalebelly/runtime/tide-picker-run-v03/run.tres');copy('art/whalebelly/runtime/tide-picker-run-v03/run-atlas.png');
  for(let index=1;index<=4;index++)for(const layer of ['Far','Middle','World','Foreground'])copy(`art/whalebelly/runtime/layers/R1-0${index}/${layer}.png`);
  // 仅构建预览所需依赖；正式工程主场景与导出预设保持原样。
  fs.writeFileSync(path.join(project,'project.godot'),`config_version=5\n[application]\nconfig/name="鲸须庭 · 探索预览"\nrun/main_scene="res://content/prototypes/chapter01/main.tscn"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="WhalefallChapter01Preview"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n`);
  fs.writeFileSync(path.join(project,'export_presets.cfg'),`[preset.0]\nname="Web"\nplatform="Web"\nrunnable=true\nexport_filter="all_resources"\ninclude_filter="**/*.json,**/*.txt"\nexclude_filter=""\nexport_path="../chapter01-web/index.html"\nscript_export_mode=2\n[preset.0.options]\ncustom_template/release="${template.split(path.sep).join('/')}"\nvariant/extensions_support=false\nvariant/thread_support=false\nvram_texture_compression/for_desktop=true\nvram_texture_compression/for_mobile=false\nhtml/canvas_resize_policy=2\nhtml/focus_canvas_on_start=true\nprogressive_web_app/enabled=false\n`);
  run(engine,['--headless','--path',project,'--import']);
  run(engine,['--headless','--path',project,'--export-release','Web',path.join(web,'index.html')]);
  const compress=spawnSync(process.execPath,[path.join(root,'tools','prepare-web.mjs')],{cwd:root,encoding:'utf8',env:{...process.env,BOB_WEB_DIRECTORY:web}});
  if(compress.status!==0)throw new Error(compress.stderr||'Web compression failed.');
  process.stdout.write(compress.stdout);
  // 此预览不使用音频。先选择 Dummy，避免内网 HTTP 触发 Web 音频 Worklet。
  // 只移除该预览不使用的安全上下文前置要求，保留 WebGL、Fetch 和 WASM 检查。
  const shellFile=path.join(web,'index.html');let shell=fs.readFileSync(shellFile,'utf8');
  const bootstrap='const engine = new Engine(GODOT_CONFIG);';
  const features='const missing = Engine.getMissingFeatures({\n\t\tthreads: GODOT_THREADS_ENABLED,\n\t});';
  if(!shell.includes(bootstrap)||!shell.includes(features))throw new Error('Unexpected preview Web shell; inspect before patching.');
  shell=shell.replace(bootstrap,'GODOT_CONFIG.args = ["--audio-driver", "Dummy"];\n'+bootstrap);
  shell=shell.replace(features,'const missing = Engine.getMissingFeatures({\n\t\tthreads: GODOT_THREADS_ENABLED,\n\t}).filter(feature => !feature.startsWith("Secure Context"));');
  fs.writeFileSync(shellFile,shell);
  fs.writeFileSync(path.join(web,'build.json'),JSON.stringify({kind:'chapter01-exploration-preview',engine:actual,rooms:10,combat:false,save:false,audio:false,exportedAt:new Date().toISOString()},null,2)+'\n');
  console.log(`Chapter 01 Web preview: ${web}`);
}

function serve(){
  if(!fs.existsSync(path.join(web,'index.html')))throw new Error('Run node tools/chapter01-preview.mjs build first.');
  const port=Number(process.env.CHAPTER01_PORT??4320);
  const types={'.html':'text/html; charset=utf-8','.js':'text/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.json':'application/json'};
  const server=createServer((request,response)=>{
    if(!['GET','HEAD'].includes(request.method)){response.writeHead(405).end();return;}
    try{
      const url=new URL(request.url,'http://localhost');
      if(url.pathname==='/'||url.pathname==='/chapter01'){response.writeHead(302,{Location:'/chapter01/'}).end();return;}
      if(!url.pathname.startsWith('/chapter01/')){response.writeHead(404).end();return;}
      const relative=decodeURIComponent(url.pathname.slice('/chapter01/'.length));
      const file=path.resolve(web,relative||'index.html');
      if(!file.startsWith(web+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){response.writeHead(404).end();return;}
      const content=fs.readFileSync(file);response.writeHead(200,{'Content-Type':types[path.extname(file)]??'application/octet-stream','Content-Length':content.length,'Cache-Control':'no-store'});response.end(request.method==='HEAD'?undefined:content);
    }catch{response.writeHead(400).end();}
  });
  server.listen(port,'0.0.0.0',()=>{
    const urls=Object.values(os.networkInterfaces()).flat().filter(item=>item.family==='IPv4'&&!item.internal).map(item=>`http://${item.address}:${port}/chapter01/`);
    fs.mkdirSync(path.join(root,'.tools'),{recursive:true});
    fs.writeFileSync(path.join(root,'.tools','chapter01-server.json'),JSON.stringify({pid:process.pid,port,urls,root:web},null,2)+'\n');
    console.log(`Local: http://127.0.0.1:${port}/chapter01/`);urls.forEach(url=>console.log(`LAN: ${url}`));
  });
}

const command=process.argv[2]??'start';
if(command==='build')build();else if(command==='serve')serve();else if(command==='start'){build();serve();}else throw new Error('Use build, serve or start.');

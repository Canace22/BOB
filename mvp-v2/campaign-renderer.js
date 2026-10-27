import { Renderer } from './renderer.js';
import { campaignHazardPhase } from './campaign-engine.js';
import { ART_ASSETS } from './art-manifest.js';
import { terrainHeightAt } from './terrain.js';

// Campaign geometry is shared with collision; source art remains static poses.
export class CampaignRenderer extends Renderer {
  draw(s, room) {
    const c = this.ctx, dpr = Math.min(devicePixelRatio || 1, 2);
    if (this.canvas.width !== 1280 * dpr || this.canvas.height !== 720 * dpr) {
      this.canvas.width = 1280 * dpr; this.canvas.height = 720 * dpr;
    }
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.globalAlpha = 1; this.time = s.time || 0; this.camera = s.camera?.x || 0;
    if (!room || s.mode === 'title') { this.title(); return; }
    const artRoom = { ...room, id: 'mouth' };
    if (room.anatomy === 'esophagus') {
      c.fillStyle='#17363b';c.fillRect(0,0,1280,720);
      const water=this.art.image('r1-water-base');
      if(water)c.drawImage(water,0,0,1280,720);
      c.fillStyle='#162d3070';c.fillRect(0,0,1280,720);
    } else {
      this.background(s, artRoom);
      const curtain=this.art.image('r1-baleen-curtain');
      if(curtain){c.save();c.globalAlpha=.42;c.drawImage(curtain,-100-this.camera*.08,-95,1500,curtain.height/curtain.width*1500);c.restore();}
    }
    c.save(); c.translate(-this.camera, -(s.camera?.y || 0));
    this.scenery(room);
    this.lowerAnatomy(room);
    for (const p of room.terrain || []) this.organicTerrain(p, room);
    for (const p of room.platforms || []) {
      this.pillar(p.x+p.w/2,p.y,Math.min(room.height+100,p.y+260),Math.min(p.w*.26,48));
      if (!this.art.platform(p, artRoom, s)) {
        c.fillStyle = '#55706c'; c.fillRect(p.x, p.y, p.w, p.h);
        this.line([[p.x,p.y],[p.x+p.w,p.y]], '#d6d4b2', 2);
      }
    }
    for (const h of room.hazards || []) {
      const phase=campaignHazardPhase(h,s.hazardTime).phase;
      c.fillStyle=({warning:'#e5c78045',active:'#d77f616b',safe:'#91d9d01c',soft:'#91d9d01c'})[phase];c.fillRect(h.x,h.y,h.w,h.h);
      this.line([[h.x,h.y],[h.x+h.w,h.y]],phase==='active'?'#e89b83':phase==='warning'?'#f9dfa0':'#91d9d0',2);
      if(phase==='warning'||phase==='active')this.label(phase==='warning'?'即将涌动':'危险 · 跃过',h.x+h.w/2,h.y-19,phase==='warning'?'#f9dfa0':'#e9ae98');
    }
    for (const camp of room.camps || []) {
      this.glow(camp.x,camp.y-25,80,'134,220,195',.25);
      this.spriteOrMark('shell-camp',camp.x,camp.y,'营地');
    }
    for (const o of room.objects || []) {
      if (s.collected.has(o.id) && o.type !== 'ability' && o.type !== 'habitat') continue;
      if (o.requires?.some(flag => !s.flags.has(flag) && !s.abilities.has(flag))) continue;
      const ids = { ability: s.abilities.has('A1') ? 'dash-grant-cocoon-open' : 'dash-grant-cocoon-closed', fragment:'life-fragment', habitat:'empty-shell', module:'empty-shell', memory:'life-fragment' };
      this.glow(o.x,o.y-20,50,'205,187,117',.18);
      this.spriteOrMark(ids[o.type] || 'empty-shell',o.x,o.y,o.label || o.name || '刻痕');
    }
    for (const e of s.enemies || []) {
      if (e.hp <= 0) continue;
      const boss = e.type === 'gate-shell-crab';
      this.spriteOrMark(boss ? 'gate-shell-crab' : 'corpse-crab',e.x+e.w/2,e.y+e.h,boss?'负壳蟹':'尸蟹');
      const telegraph = /telegraph|windup/.test(e.phase);
      if (telegraph) {
        if(e.preview) {
          this.volume(e.preview,'#ffd39224');
          c.save();c.setLineDash([7,5]);c.strokeStyle='#ffd392';c.lineWidth=2;
          c.strokeRect(e.preview.x,e.preview.y,e.preview.w,e.preview.h);c.restore();
        }
        this.ellipse(e.x+e.w/2,e.y+e.h, e.w*.8,14,'#ffc78c33','#ffd099',2);
        this.label('预兆 · 留意攻击范围',e.x+e.w/2,e.y-23,'#ffca8f');
      }
      if (e.attack) this.volume(e.attack,'#ed886862');
      c.fillStyle='#07171dbb'; c.fillRect(e.x,e.y-12,e.w,4);
      c.fillStyle= boss ? '#d7b075':'#b9d8b5'; c.fillRect(e.x,e.y-12,e.w*e.hp/e.maxHp,4);
    }
    for(const anchor of room.anchors || []) {
      this.ellipse(anchor.x,anchor.y,10,10,null,'#89b4a6',2);
      this.label('A3',anchor.x,anchor.y-20,'#89b4a6');
    }
    for (const exit of room.exits || []) {
      const locked = exit.requires?.some(f => !s.flags.has(f) && !s.abilities.has(f));
      this.ellipse(exit.x,exit.y-25,20,38,null,locked?'#ad9281':'#a4d9c6',2);
      this.label(exit.label || exit.to,exit.x,exit.y-73,locked?'#c5a88a':'#badbd1');
      if (locked) this.label(`需要 ${exit.requires.join(' + ')}`,exit.x,exit.y-54,'#d4b58f');
    }
    const p = s.player;
    c.save();
    if (s.invulnerable > 0) c.globalAlpha = .55 + Math.sin(this.time*30)*.25;
    if (s.lamp) this.glow(p.x+p.w/2,p.y+20,105,'164,224,201',.18);
    if (!this.art.hero(p,s)) {
      c.fillStyle='#d7d9ba'; c.fillRect(p.x,p.y,p.w,p.h);
    }
    c.restore();
    if(room.anatomy!=='esophagus')this.art.foreground(artRoom);
    if (s.attack) this.volume(s.attack,s.attack.kind === 'heavy'?'#edcf8c88':'#a8ece699');
    c.restore();
    if (s.respawnFlash > 0) { c.fillStyle=`rgba(186,220,212,${Math.min(.5,s.respawnFlash*.4)})`; c.fillRect(0,0,1280,720); }
  }

  scenery(room) {
    if(room.anatomy==='esophagus') {
      const image=this.art.image('r1-esophagus-fold');
      if(image){const c=this.ctx;c.save();c.globalAlpha=.4;c.drawImage(image,this.camera-180,-270,1600,780);c.translate(this.camera+1380,room.height+390);c.rotate(Math.PI);c.globalAlpha=.18;c.drawImage(image,0,0,1600,780);c.restore();}
    }
  }
  lowerAnatomy(room) {
    // Recessed tissue and narrow roots give the walkable rim its anatomical
    // structure. They never create extra collision or cover the route.
    const c=this.ctx, y=room.height-35;
    c.save();c.globalAlpha=.38;
    for(let x=-100;x<room.width;x+=610)this.art.sprite(room.anatomy==='esophagus'?'r1-esophagus-fold':'r1-wound-section',x+350,y+205,{units:35,alpha:.6});
    c.restore();
  }
  pillar(x,top,bottom,radius) {
    const c=this.ctx,image=this.art.image('r1-tongue-ledge');
    c.save();c.beginPath();c.moveTo(x-radius*2,top+15);
    c.bezierCurveTo(x-radius*.3,top+50,x-radius*.6,bottom-30,x-radius*1.5,bottom);
    c.lineTo(x+radius*1.5,bottom);
    c.bezierCurveTo(x+radius*.6,bottom-30,x+radius*.3,top+50,x+radius*2,top+15);c.closePath();c.clip();
    c.fillStyle='#374a46';c.fillRect(x-radius*2,top,radius*4,bottom-top);
    if(image){c.globalAlpha=.65;c.drawImage(image,image.width*.28,image.height*.25,image.width*.25,image.height*.65,x-radius*2,top,radius*4,bottom-top);}
    c.restore();
  }
  organicTerrain(surface,room) {
    const key=`organic-${surface.id}`;
    let cached=this.art.terrainCache.get(key);
    if(!cached) {
      const first=surface.points[0],last=surface.points.at(-1),top=Math.floor(Math.min(...surface.points.map(p=>p.y)));
      const canvas=document.createElement('canvas');canvas.width=Math.ceil(last.x-first.x)+2;canvas.height=Math.ceil(room.height+110-top);
      const old=this.ctx,c=canvas.getContext('2d');c.translate(-first.x,-top);this.ctx=c;
      if(last.x-first.x>300)for(let x=first.x+150;x<last.x-70;x+=390)this.pillar(x,terrainHeightAt(surface,x),room.height+100,35);
      const image=this.art.image('r1-tongue-ledge'),a=ART_ASSETS['r1-tongue-ledge'];
      if(image) {
        const scale=this.art.scale('r1-tongue-ledge'),cropY=220*a.exportScaleY,left=a.bbox[0]+80*a.exportScale,sw=a.bbox[2]-left-80*a.exportScale,sh=a.bbox[3]-cropY;
        for(let x=first.x;x<last.x;x+=3) {
          const width=Math.min(3,last.x-x),y=terrainHeightAt(surface,x+width/2),sx=left+((x-first.x)/scale%Math.max(1,sw-width/scale));
          c.drawImage(image,sx,cropY,width/scale,sh,x,y,width+.5,sh*scale);
        }
      } else {
        c.beginPath();surface.points.forEach((p,i)=>i?c.lineTo(p.x,p.y):c.moveTo(p.x,p.y));
        for(const p of [...surface.points].reverse())c.lineTo(p.x,p.y+65);c.closePath();c.fillStyle='#5e7770';c.fill();
      }
      this.line(surface.points.map(p=>[p.x,p.y+.5]),'#d5cfac',1.2);this.ctx=old;
      cached={canvas,x:first.x,y:top};this.art.terrainCache.set(key,cached);
    }
    this.ctx.drawImage(cached.canvas,cached.x,cached.y);
  }
  spriteOrMark(id,x,y,label) {
    if (!this.art.sprite(id,x,y)) {
      this.ellipse(x,y-18,18,18,'#95bbae','#cfe6c6'); this.label(label,x,y-43);
    }
  }
  label(text,x,y,color='#d9e2d0') {
    const c=this.ctx; c.font='13px "Microsoft YaHei", sans-serif'; c.textAlign='center';
    const width=c.measureText(text).width;
    x=Math.max(this.camera+width/2+10,Math.min(this.camera+1270-width/2,x));
    c.fillStyle='#061c25d9'; c.fillRect(x-width/2-7,y-15,width+14,21);
    c.fillStyle=color; c.fillText(text,x,y);
  }
  volume(v,color) { const c=this.ctx; c.fillStyle=color; c.fillRect(v.x,v.y,v.w,v.h); }
}

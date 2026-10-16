import * as THREE from '/node_modules/three/build/three.module.js';

const W = 1280, H = 720, FLOOR = 574;
const rand = n => { const a = Math.sin(n * 127.1 + 311.7) * 43758.5453; return a - Math.floor(a); };
const point = (x, y, z) => new THREE.Vector3(x, y, z);
const worldY = y => (FLOOR - y) / 100;

/** Real perspective 3D scene; game coordinates are centimetres, scene coordinates metres. */
export class Renderer {
  constructor(canvas) {
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, preserveDrawingBuffer: true });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    this.renderer.setSize(W, H, false);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.3;
    this.camera = new THREE.PerspectiveCamera(35, W / H, .1, 95);
    this.worlds = new Map();
    this.makeMaterials();
  }

  async load() { return this; }

  makeMaterials() {
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = 256;
    const c = canvas.getContext('2d');
    c.fillStyle = '#a5a39a'; c.fillRect(0, 0, 256, 256);
    for (let i = 0; i < 6000; i++) {
      const value = 80 + Math.floor(rand(i) * 100);
      c.fillStyle = `rgba(${value},${value},${value},${.1 + rand(i + 1) * .25})`;
      c.fillRect(rand(i + 2) * 256, rand(i + 4) * 256, 1 + rand(i + 5) * 4, 1 + rand(i + 7) * 3);
    }
    for (let i = 0; i < 25; i++) {
      c.strokeStyle = '#656a652c'; c.lineWidth = .6;
      c.beginPath(); c.moveTo(rand(i + 30) * 256, rand(i + 31) * 256);
      c.lineTo(rand(i + 30) * 256 + 15, rand(i + 31) * 256 + 60); c.stroke();
    }
    const texture = new THREE.CanvasTexture(canvas);
    texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
    texture.repeat.set(2, 2);
    texture.colorSpace = THREE.SRGBColorSpace;
    this.materials = {
      bone: new THREE.MeshStandardMaterial({ color: '#83968a', roughness: .93, map: texture, bumpMap: texture, bumpScale: .045 }),
      boneLight: new THREE.MeshStandardMaterial({ color: '#b8baa3', roughness: .9, map: texture, bumpMap: texture, bumpScale: .035 }),
      boneDark: new THREE.MeshStandardMaterial({ color: '#435e5d', roughness: 1, map: texture }),
      floor: new THREE.MeshStandardMaterial({ color: '#3d595d', roughness: .92, map: texture, bumpMap: texture, bumpScale: .03 }),
      edge: new THREE.MeshStandardMaterial({ color: '#82928a', roughness: .78, map: texture }),
      dark: new THREE.MeshStandardMaterial({ color: '#142c35', roughness: .9 }),
      black: new THREE.MeshStandardMaterial({ color: '#07151e', roughness: .89 }),
      metal: new THREE.MeshStandardMaterial({ color: '#586e65', roughness: .6, metalness: .65, map: texture }),
      copper: new THREE.MeshStandardMaterial({ color: '#a8855b', roughness: .63, metalness: .55, map: texture }),
      wood: new THREE.MeshStandardMaterial({ color: '#8f7651', roughness: .95, map: texture, bumpMap: texture, bumpScale: .03 }),
      orange: new THREE.MeshStandardMaterial({ color: '#c98547', roughness: 1 }),
      hood: new THREE.MeshStandardMaterial({ color: '#e0a264', roughness: .98 }),
      skin: new THREE.MeshStandardMaterial({ color: '#e2c49d', roughness: .9 }),
      moss: new THREE.MeshStandardMaterial({ color: '#71885e', roughness: 1 }),
      warm: new THREE.MeshStandardMaterial({ color: '#f2d29c', emissive: '#e7aa5d', emissiveIntensity: 2.2, roughness: .4 }),
      green: new THREE.MeshStandardMaterial({ color: '#d2e3ad', emissive: '#9bb676', emissiveIntensity: 1.3 }),
      blue: new THREE.MeshStandardMaterial({ color: '#c3e0da', emissive: '#79afb4', emissiveIntensity: 1.3 }),
      red: new THREE.MeshStandardMaterial({ color: '#c18f58', emissive: '#8a4d2e', emissiveIntensity: .5 }),
    };
  }

  group(parent, x = 0, y = 0, z = 0) {
    const g = new THREE.Group(); g.position.set(x, y, z); parent.add(g); return g;
  }

  mesh(parent, geometry, material, x = 0, y = 0, z = 0, cast = false) {
    const m = new THREE.Mesh(geometry, typeof material === 'string' ? this.materials[material] : material);
    m.position.set(x, y, z); m.castShadow = cast; m.receiveShadow = true; parent.add(m); return m;
  }

  box(parent, x, y, z, w, h, d, mat = 'bone', cast = false) {
    return this.mesh(parent, new THREE.BoxGeometry(w, h, d), mat, x, y, z, cast);
  }

  sphere(parent, x, y, z, r, mat, scale = [1, 1, 1]) {
    const m = this.mesh(parent, new THREE.SphereGeometry(r, 18, 12), mat, x, y, z, true);
    m.scale.set(...scale); return m;
  }

  rod(parent, from, to, radius, material = 'metal', endRadius = radius, cast = true) {
    const a = point(...from), b = point(...to), delta = b.clone().sub(a);
    const m = this.mesh(parent, new THREE.CylinderGeometry(endRadius, radius, delta.length(), 10), material, 0, 0, 0, cast);
    m.position.copy(a.add(b).multiplyScalar(.5));
    m.quaternion.setFromUnitVectors(point(0, 1, 0), delta.normalize());
    return m;
  }

  curve(parent, coords, radius, material, segments = 32) {
    const path = new THREE.CatmullRomCurve3(coords.map(v => point(...v)));
    return this.mesh(parent, new THREE.TubeGeometry(path, segments, radius, 9, false), material, 0, 0, 0, true);
  }

  torus(parent, x, y, z, radius, tube, material, rotateX = 0) {
    const m = this.mesh(parent, new THREE.TorusGeometry(radius, tube, 9, 32), material, x, y, z, true);
    m.rotation.x = rotateX; return m;
  }

  light(parent, x, y, z, color, intensity, range = 8) {
    const l = new THREE.PointLight(color, intensity, range, 2); l.position.set(x, y, z); parent.add(l); return l;
  }

  makeWorld(key, level, title = false) {
    const scene = new THREE.Scene();
    scene.background = new THREE.Color('#132a36');
    scene.fog = new THREE.FogExp2('#183440', .042);
    const world = { scene, key, title, level, objects: new Map(), valves: [], animated: [], gate: null };
    const room = title ? 0 : key;
    scene.add(new THREE.HemisphereLight('#b0d5dd', '#293438', 1.3));
    const sun = new THREE.DirectionalLight('#c7d5ca', 2.2);
    sun.position.set(4, 9, 5); sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    Object.assign(sun.shadow.camera, { left: -10, right: 10, top: 8, bottom: -5, near: .5, far: 30 });
    sun.shadow.bias = -.0008; sun.shadow.normalBias = .02;
    scene.add(sun); scene.add(sun.target); world.sun = sun;
    const width = title ? 20 : level.width / 100;
    this.environment(world, width, room, title);
    this.floor(world, width, title ? [] : level.gaps || []);
    if (!title) {
      for (const p of level.platforms || []) this.obstacle(world, p);
      if (level.gate) this.makeGate(world, level.gate);
      if (level.crawl) this.makeCrawl(world, level.crawl);
      for (const hide of level.hides || []) this.makeHide(world, hide);
      for (const o of level.objects || []) this.makeObject(world, o);
      if (room === 0) { this.makeCrate(world); this.makePlate(world, level); }
      if (room === 1) this.makeWatcher(world);
      if (room === 2) { this.makePump(world); this.makeFlood(world); }
      if (level.exit) this.makeExit(world, level.exit);
    }
    world.hero = this.makeHero(scene);
    world.hero.root.position.set(title ? 9.55 : 1.5, 0, title ? .6 : 0);
    this.makeDust(world, width);
    this.worlds.set(key, world);
    return world;
  }

  environment(world, width, room, title) {
    const { scene } = world;
    // Whale ribs are real curved bones, enclosing the rear and ceiling of a long tunnel.
    for (let x = -2; x < width + 7; x += 3.3) {
      const rib = this.group(scene, x, 0, -2.5);
      const tilt = (rand(x + 17) - .5) * .45;
      this.curve(rib, [[-.5, -.1, 0], [-.35, 1.6, -.55], [.08, 3.4, -.75], [.55, 5.1, -.5], [.85, 6.2, .8], [.45, 6.8, 3.2]], .22 + rand(x) * .1, 'bone');
      this.curve(rib, [[-.6, -.1, -.08], [-.45, 1.6, -.61], [-.04, 3.4, -.83], [.42, 5.1, -.56], [.73, 6.2, .74]], .035, 'boneLight');
      this.sphere(rib, -.5, .15, 0, .36, 'bone', [.95, 1.35, 1.2]);
      rib.rotation.z = tilt;
      for (let j = 0; j < 3; j++) {
        const h = 1.2 + j * 1.35;
        this.torus(rib, -.35 + j * .2, h, -.5, .28, .045, 'boneDark', Math.PI / 2 - .3);
      }
    }
    // Distant catwalks, columns and tiny lamps establish the enormous scale.
    for (let x = -3; x < width + 8; x += 2.8) {
      const h = 1.1 + rand(x + 21) * 3.3;
      this.rod(scene, [x, -1.5, -7.3], [x, h, -7.3], .19, 'boneDark');
      this.box(scene, x, h, -7.3, 2.1, .15, 1.25, 'boneDark');
      this.rod(scene, [x - .85, h, -6.8], [x - .85, h + .5, -6.8], .022, 'metal', .022, false);
      this.rod(scene, [x + .85, h, -6.8], [x + .85, h + .5, -6.8], .022, 'metal', .022, false);
      this.rod(scene, [x - .85, h + .48, -6.8], [x + .85, h + .48, -6.8], .022, 'metal', .022, false);
      if (Math.round(x * 10) % 3 === 0) {
        this.box(scene, x + .3, h + .3, -7.1, .08, .12, .08, 'warm');
      }
    }
    // Pipework, corrosion bands and small hanging cages, all behind the playable path.
    for (let x = 1.8; x < width; x += 5.8) {
      this.curve(scene, [[x - 1, 5.8, -1.3], [x - .7, 4.2, -1.5], [x + 1, 3.1, -1.5], [x + 1.05, .2, -1.7]], .11, 'metal');
      for (let j = 0; j < 3; j++) this.torus(scene, x + 1.05, .6 + j * .6, -1.7, .13, .025, 'copper', Math.PI / 2);
      this.curve(scene, [[x - 2.5, 5, -.8], [x, 3.8, -.6], [x + 3.2, 5.3, -1.2]], .016, 'black');
      this.rod(scene, [x, 3.94, -.65], [x, 2.85, -.65], .012, 'metal', .012, false);
      this.lantern(scene, x, 2.77, -.65, false);
      this.light(scene, x, 2.65, -.4, room === 2 ? '#ddb079' : '#adccc4', 2, 5.5);
    }
    const rearRail = this.group(scene);
    for (let x = -.5; x < width; x += 1.6) {
      this.rod(rearRail, [x, 0, -1.5], [x, .7, -1.5], .035, 'metal', .03, true);
      this.sphere(rearRail, x, .72, -1.5, .056, 'copper');
    }
    this.rod(rearRail, [-1, .65, -1.5], [width + 1, .65, -1.5], .03, 'metal');
    this.rod(rearRail, [-1, .32, -1.5], [width + 1, .32, -1.5], .018, 'metal');
    // Rib shards at the forward lip give parallax without hiding the walking line.
    for (let x = .8; x < width; x += 5.2) {
      this.curve(scene, [[x, -1.5, 2.05], [x + .25, -.68, 2.13], [x + .1, -.08, 2.2]], .13, 'boneDark', 12);
      this.sphere(scene, x + .1, -.08, 2.2, .16, 'boneDark', [1.1, .65, 1]);
    }
    if (title) {
      // The entrance forms an unmistakably three-dimensional monumental frame.
      this.curve(scene, [[7.6, -.9, .2], [7.2, 1.4, -.1], [7.8, 4.8, -.4], [10.3, 6.1, -.2], [12.9, 4.7, .25], [13.5, 1, .6]], .31, 'boneLight', 44);
      this.curve(scene, [[7.43, -.8, .18], [7.03, 1.4, -.12], [7.64, 4.8, -.43], [10.3, 5.94, -.2], [12.73, 4.7, .25]], .045, 'boneDark', 40);
      this.light(scene, 10.7, 3.5, 1.3, '#d2e4d4', 20, 8);
      this.light(scene, 9.7, 1.4, 1.6, '#f0bc79', 2, 4);
      this.box(scene, 4.2, -.62, .2, 6.2, 1.2, 5, 'dark');
    }
  }

  floor(world, width, gaps) {
    const { scene } = world;
    let start = -.8;
    for (const gap of [...gaps, { x: (width + .8) * 100, w: 0 }]) {
      const end = gap.x / 100;
      const length = end - start;
      if (length > 0) {
        this.box(scene, (start + end) / 2, -.5, 0, length, 1, 3.6, 'floor', true);
        this.box(scene, (start + end) / 2, -.035, 0, length, .07, 3.6, 'edge');
        this.box(scene, (start + end) / 2, -.16, 1.79, length, .12, .06, 'boneDark');
        this.box(scene, (start + end) / 2, -.34, 1.82, length, .045, .045, 'metal');
        for (let x = Math.ceil(start * 2) / 2; x < end; x += .5) {
          this.box(scene, x, .003, 0, .011, .008, 3.5, 'boneDark');
          if (Math.round(x * 2) % 2 === 0) {
            this.box(scene, x, -.3, 1.85, .09, .62, .08, 'metal');
            this.sphere(scene, x, -.13, 1.91, .026, 'copper');
          }
        }
        for (let x = Math.ceil(start); x < end - .1; x += 1.6) {
          this.curve(scene, [[x, -.7, 1.5], [x + .12, -1.3, 1.53], [x -.1, -2.2, 1.45]], .025, 'dark', 8);
          this.moss(scene, x + .15, .01, -1.2, 6);
        }
      }
      start = (gap.x + gap.w) / 100;
    }
    const water = new THREE.MeshStandardMaterial({ color: '#183640', roughness: .25, metalness: .4, transparent: true, opacity: .8 });
    this.box(scene, width / 2, -2.7, 0, width + 12, .03, 16, water);
  }

  moss(parent, x, y, z, count) {
    for (let i = 0; i < count; i++) {
      const xx = x + (rand(i + x * 10) - .5) * .42;
      const zz = z + (rand(i + z * 10) - .5) * .32;
      const h = .06 + rand(i * 9 + x) * .12;
      this.rod(parent, [xx, y, zz], [xx + .02, y + h, zz], .008, 'moss', .005, false);
      this.sphere(parent, xx + .02, y + h, zz, .026, 'moss', [1, .7, 1]);
    }
  }

  obstacle(world, p) {
    const x = (p.x + p.w / 2) / 100, y = worldY(p.y), h = p.h / 100;
    this.box(world.scene, x, y - h / 2, 0, p.w / 100, h, 3.5, 'bone', true);
    this.box(world.scene, x, y + .015, 0, p.w / 100 + .04, .04, 3.55, 'boneLight', true);
    for (const z of [-1.45, 1.45]) this.box(world.scene, x, y - h / 2, z, .1, h + .04, .05, 'metal');
  }

  makeCrate(world) {
    const g = this.group(world.scene);
    this.box(g, .35, .31, 0, .7, .62, 1.5, 'wood', true);
    for (const z of [-.758, .758]) {
      for (const x of [.1, .59]) this.box(g, x, .31, z, .065, .63, .03, 'metal', true);
      for (let i = 1; i < 5; i++) this.box(g, i * .14, .31, z, .009, .6, .008, 'dark');
      const brace = this.box(g, .35, .31, z + Math.sign(z) * .014, .6, .07, .035, 'wood', true);
      brace.rotation.z = .65;
      for (const x of [.1, .59]) for (const y of [.08, .54]) this.sphere(g, x, y, z + Math.sign(z) * .025, .018, 'copper');
    }
    this.torus(g, .35, .35, .789, .075, .012, 'copper');
    world.crate = g;
  }

  makePlate(world, level) {
    const p = level.plate;
    if (!p) return;
    const x = (p.x + p.w / 2) / 100;
    world.plate = this.box(world.scene, x, .035, 0, p.w / 100, .07, 1.1, 'copper', true);
    for (let i = 0; i < 6; i++) this.box(world.plate, -.42 + i * .17, .04, 0, .026, .01, .85, 'dark');
    const wire = new THREE.MeshStandardMaterial({ color: '#ae8b58', emissive: '#3d2b12', emissiveIntensity: .5, metalness: .4, roughness: .65 });
    world.wireMaterial = wire;
    this.curve(world.scene, [[x, .025, .6], [x, .025, 1.17], [level.gate.x / 100 + .21, .025, 1.17], [level.gate.x / 100 + .21, 1.3, 1.17]], .018, wire, 24);
  }

  makeGate(world, gate) {
    const x = (gate.x + gate.w / 2) / 100, top = worldY(gate.y), h = gate.h / 100;
    for (const z of [-1.5, 1.5]) {
      this.box(world.scene, x, top / 2, z, .35, top + .22, .27, 'bone', true);
      this.box(world.scene, x + .03, top / 2, z + .15, .12, top + .2, .06, 'copper');
    }
    this.box(world.scene, x, top + .1, 0, .48, .25, 3.6, 'boneLight', true);
    const bars = this.group(world.scene, x, 0, 0);
    for (let z = -1.33; z < 1.4; z += .24) {
      this.rod(bars, [0, .05, z], [0, top, z], .035, 'metal');
      const tip = this.mesh(bars, new THREE.ConeGeometry(.07, .17, 6), 'boneLight', 0, .03, z);
      tip.rotation.z = Math.PI;
    }
    this.box(bars, 0, .3, 0, .11, .1, 2.9, 'copper', true);
    this.box(bars, 0, top - .2, 0, .11, .1, 2.9, 'copper', true);
    world.gate = bars; world.gateHeight = h;
    world.gateLamp = this.lantern(world.scene, x, top + .4, .1, false);
  }

  makeCrawl(world, crawl) {
    const x = crawl.x / 100, w = crawl.w / 100, clear = crawl.clearance / 100;
    // Open the near side like a stage cutaway: the true low ceiling remains visible
    // behind the child instead of completely obscuring a crouching silhouette.
    this.box(world.scene, x + w / 2, clear + .28, -.91, w, .56, 1.78, 'bone', true);
    this.box(world.scene, x + w / 2, clear + .55, -.91, w + .12, .08, 1.88, 'boneLight');
    for (let i = 0; i < 6; i++) {
      this.curve(world.scene, [[x + .15 + i * .43, clear + .02, .05], [x + .2 + i * .43, clear + .3, .09], [x + .15 + i * .43, clear + .55, .05]], .055, 'boneLight', 10);
    }
    for (const xx of [x + .1, x + w - .1]) {
      this.box(world.scene, xx, .32, -1.6, .2, .64, .25, 'bone', true);
      this.rod(world.scene, [xx, clear + .08, -.05], [xx, clear + .08, 1.5], .048, 'boneLight');
    }
  }

  makeHide(world, h) {
    const x = (h.x + h.w / 2) / 100, w = h.w / 100;
    const g = this.group(world.scene, x, 0, -.96);
    this.box(g, 0, .47, -.38, w, .95, .15, 'dark', true);
    this.box(g, 0, 1.03, -.05, w + .15, .23, .92, 'bone', true);
    for (const side of [-1, 1]) {
      this.rod(g, [side * (w / 2 - .09), .04, .27], [side * (w / 2 - .09), 1.02, .27], .11, 'bone', .15, true);
      this.sphere(g, side * (w / 2 - .09), 1.02, .27, .18, 'boneLight', [1.1, .7, 1.1]);
      this.box(g, side * w / 2, .48, -.12, .14, .95, .78, 'boneDark', true);
    }
    this.curve(g, [[-w / 2, .95, .35], [-w / 4, 1.2, .35], [w / 4, 1.2, .35], [w / 2, .95, .35]], .095, 'boneLight', 15);
    this.moss(g, -.4, 1.17, 0, 5);
  }

  makeObject(world, o) {
    const g = this.group(world.scene, o.x / 100, worldY(o.y), o.z || 0);
    world.objects.set(o.id, { root: g, object: o, initialY: g.position.y });
    if (o.kind === 'mural') {
      const plaque = this.box(g, 0, .17, -.15, 1.03, .68, .13, 'bone', true);
      plaque.rotation.z = -.035;
      this.rod(g, [-.35, -.5, -.15], [-.35, .48, -.15], .04, 'metal');
      this.rod(g, [.35, -.5, -.15], [.35, .48, -.15], .04, 'metal');
      if (world.key === 2) [2, 1, 3].forEach((n, i) => this.dots(g, -.32 + i * .32, .19, -.065, n));
      else if (world.key === 0) {
        this.box(g, -.24, .2, -.06, .22, .22, .025, 'copper');
        this.box(g, -.24, .05, -.06, .36, .035, .025, 'copper');
        this.rod(g, [-.02, .15, -.06], [.18, .15, -.06], .014, 'copper');
        for (let i = 0; i < 3; i++) this.box(g, .21 + i * .08, .22, -.06, .025, .28, .025, 'copper');
      } else {
        this.torus(g, -.22, .2, -.06, .13, .02, 'copper');
        this.box(g, -.22, .2, -.05, .05, .13, .025, 'copper');
        this.rod(g, [.15, .02, -.05], [.15, .36, -.05], .02, 'copper');
        this.rod(g, [.15, .36, -.05], [.38, .36, -.05], .02, 'copper');
        this.sphere(g, .28, .11, -.045, .06, 'copper');
      }
      this.light(g, 0, .4, .3, '#dbbd7b', .65, 2);
    } else if (o.kind === 'memory') {
      const shell = this.sphere(g, 0, 0, 0, .09, 'blue', [.65, 1.3, .55]);
      shell.rotation.z = -.4;
      this.torus(g, 0, 0, 0, .15, .008, 'copper', .5);
      this.light(g, 0, .05, .1, '#b8e4df', 1.2, 2.4);
    } else if (o.kind === 'fuse') {
      this.rod(g, [-.15, 0, 0], [.15, 0, 0], .06, 'warm', .06);
      for (const x of [-.14, .14]) this.rod(g, [x, -.09, 0], [x, .09, 0], .04, 'copper');
      this.light(g, 0, 0, .1, '#f3bf77', 1, 2.4);
    } else if (o.kind === 'socket') {
      this.box(g, 0, .03, 0, .55, .65, .3, 'metal', true);
      this.box(g, 0, .04, .16, .34, .17, .025, 'black');
      const insert = this.box(g, 0, .04, .18, .26, .09, .045, 'green'); insert.visible = false;
      world.objects.get(o.id).insert = insert;
      this.rod(g, [-.2, -.53, 0], [-.2, -.18, 0], .04, 'metal');
      this.rod(g, [.2, -.53, 0], [.2, -.18, 0], .04, 'metal');
      world.socketLamp = this.sphere(g, 0, .23, .18, .045, 'red');
    } else if (o.kind === 'valve') {
      this.rod(g, [0, -worldY(o.y), 0], [0, 0, 0], .09, 'metal');
      this.torus(g, 0, -worldY(o.y) + .02, 0, .19, .025, 'copper', Math.PI / 2);
      const wheel = this.group(g, 0, 0, .05);
      this.torus(wheel, 0, 0, 0, .23, .035, 'copper');
      for (let i = 0; i < 3; i++) {
        const a = i * Math.PI * 2 / 3;
        this.rod(wheel, [0, 0, 0], [Math.cos(a) * .22, Math.sin(a) * .22, 0], .022, 'copper');
      }
      this.sphere(wheel, 0, 0, .02, .055, 'boneLight');
      this.box(g, 0, .43, 0, .55, .23, .1, 'metal');
      this.dots(g, 0, .43, .057, o.number || 1);
      const lamp = this.sphere(g, 0, .63, 0, .037, 'red');
      world.valves.push({ wheel, number: o.number, lamp });
    }
  }

  dots(parent, x, y, z, count) {
    for (let i = 0; i < count; i++) this.sphere(parent, x + (i - (count - 1) / 2) * .095, y, z, .024, 'warm', [1, 1, .35]);
  }

  lantern(parent, x, y, z, warm = true) {
    const g = this.group(parent, x, y, z);
    this.box(g, 0, 0, 0, .1, .16, .1, warm ? 'warm' : 'blue');
    for (const xx of [-.065, .065]) for (const zz of [-.065, .065]) this.rod(g, [xx, -.11, zz], [xx, .11, zz], .008, 'metal');
    this.box(g, 0, .11, 0, .19, .035, .19, 'metal');
    this.box(g, 0, -.11, 0, .16, .035, .16, 'metal');
    return g;
  }

  makeHero(parent) {
    const root = this.group(parent);
    const body = this.group(root);
    const legs = [];
    for (const side of [-1, 1]) {
      const leg = this.group(body, side * .065, .19, 0);
      this.rod(leg, [0, 0, 0], [0, -.14, 0], .033, 'dark');
      this.sphere(leg, .02, -.16, .026, .05, 'boneDark', [1.3, .55, 1.05]); legs.push(leg);
    }
    // A short, flared travelling cloak with an asymmetric hem, built from real geometry.
    const cloak = this.mesh(body, new THREE.CylinderGeometry(.085, .16, .3, 8, 1, true), 'orange', 0, .31, 0, true);
    cloak.scale.z = .7;
    this.sphere(body, 0, .43, 0, .1, 'orange', [1.05, .7, .8]);
    const head = this.group(body, .015, .51, 0);
    this.sphere(head, 0, 0, 0, .115, 'hood', [1.02, 1.07, .88]);
    this.sphere(head, .081, -.004, .035, .071, 'dark', [.55, .92, .8]);
    this.sphere(head, .103, .006, .071, .013, 'skin');
    this.curve(head, [[.08, -.07, .085], [.11, .015, .081], [.065, .09, .052]], .014, 'hood', 10);
    this.rod(body, [.055, .405, .055], [.16, .27, .07], .028, 'orange');
    this.sphere(body, .16, .27, .07, .031, 'skin');
    const lantern = this.lantern(body, .19, .16, .11, true); lantern.scale.setScalar(.57);
    this.torus(body, .19, .25, .11, .035, .006, 'metal');
    const light = this.light(root, .22, .35, .5, '#ffbd71', .8, 2.6);
    return { root, body, head, legs, light, cloak };
  }

  makeExit(world, exit) {
    const x = exit.x / 100;
    const g = this.group(world.scene, x + .2, 0, -.2);
    this.curve(g, [[-.42, 0, 0], [-.42, 1.18, 0], [0, 1.52, 0], [.42, 1.18, 0], [.42, 0, 0]], .09, 'boneLight', 20);
    this.box(g, 0, .62, -.22, .72, 1.24, .06, 'dark');
    for (let i = 0; i < 4; i++) this.box(g, 0, .025 + i * .055, .35 - i * .14, .72, .05, .2, 'boneDark');
    this.lantern(g, 0, 1.56, .04, false);
    this.light(g, 0, .8, .5, '#b9dac2', 2.2, 3.4);
  }

  makeWatcher(world) {
    const g = this.group(world.scene, 13.7, 2.05, -2.2);
    world.watcher = g;
    this.sphere(g, 0, 0, 0, 1.27, 'bone', [1.7, 1.15, .75]);
    this.sphere(g, .65, -.55, .1, .87, 'boneLight', [1.25, .75, .9]);
    const socket = this.sphere(g, -.25, .07, .89, .55, 'black', [1.08, .78, .18]);
    socket.rotation.z = .15;
    const eye = this.sphere(g, -.25, .07, 1.02, .22, 'warm', [.78, 1, .4]);
    world.watcherEye = eye;
    const lid = this.box(g, -.25, .07, 1.05, .94, .07, .06, 'boneLight'); lid.rotation.z = .1;
    world.watcherLid = lid;
    this.sphere(g, 1.22, -.45, .74, .2, 'dark', [.55, .8, .25]);
    for (let i = 0; i < 6; i++) {
      this.rod(g, [-.75 + i * .34, -.86, .53], [-.64 + i * .34, -1.18 - rand(i) * .22, .58], .1, 'boneLight', .012);
    }
    this.curve(g, [[-1.42, -.2, -.2], [-2, -1.2, -.3], [-1.7, -2.05, -.1]], .21, 'bone', 20);
    this.curve(g, [[1.34, .55, -.5], [1.8, 1.6, -.7], [1.1, 3.2, -.8]], .3, 'bone', 24);
    this.light(g, -.2, .15, 1.3, '#d7b575', 1.7, 5.4);
    const beamMat = new THREE.MeshBasicMaterial({ color: '#e0c087', transparent: true, opacity: .11, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending });
    const beam = this.mesh(world.scene, new THREE.ConeGeometry(1.3, 1, 32, 1, true), beamMat);
    world.beam = beam;
    const spot = new THREE.SpotLight('#e1bf87', 10, 14, .32, .55, 1.2);
    spot.position.set(13.45, 2.12, -1.15); world.scene.add(spot); world.scene.add(spot.target); world.watchLight = spot;
  }

  makePump(world) {
    const g = this.group(world.scene, 6.4, 2.5, -2.7);
    this.torus(g, 0, 0, 0, 1.5, .23, 'metal');
    this.torus(g, 0, 0, .15, 1.47, .045, 'copper');
    const back = this.mesh(g, new THREE.CylinderGeometry(1.4, 1.4, .4, 40), 'dark'); back.rotation.x = Math.PI / 2;
    const rotor = this.group(g, 0, 0, .27); world.rotor = rotor;
    for (let i = 0; i < 8; i++) {
      const a = i * Math.PI / 4;
      const vane = this.box(rotor, Math.cos(a) * .8, Math.sin(a) * .8, 0, .72, .24, .17, 'copper', true);
      vane.rotation.z = a + .55;
      this.sphere(g, Math.cos(a) * 1.51, Math.sin(a) * 1.51, .27, .065, 'boneLight');
    }
    this.sphere(g, 0, 0, .4, .38, 'metal', [1, 1, .45]);
    world.pumpCore = this.sphere(g, 0, 0, .57, .16, 'red', [1, 1, .35]);
    for (const side of [-1, 1]) {
      this.curve(g, [[side * 1.2, -.65, -.2], [side * 2, -1.1, -.25], [side * 1.9, -2.5, -.25], [side * 3.4, -2.5, -.1]], .2, 'metal', 20);
      this.curve(g, [[side * .8, 1.2, -.2], [side * 1.1, 2.1, -.2], [side * .4, 3.7, -.5]], .15, 'metal', 20);
    }
    this.light(g, 0, 0, 1.1, '#cba270', 7, 6);
  }

  makeFlood(world) {
    const g = this.group(world.scene, -8, 0, 0);
    const mat = new THREE.MeshStandardMaterial({ color: '#061923', roughness: .23, metalness: .34 });
    this.box(g, -10, -.2, 0, 20, 2, 3.8, mat);
    world.waves = [];
    for (let i = 0; i < 12; i++) {
      const ball = this.sphere(g, -.25 - rand(i) * .5, .2 + rand(i + 3) * 1.1, (rand(i + 7) - .5) * 3.4, .6, mat, [.75, .65, 1.2]);
      world.waves.push(ball);
    }
    world.flood = g;
  }

  makeDust(world, width) {
    const positions = new Float32Array(180 * 3);
    for (let i = 0; i < 180; i++) {
      positions[i * 3] = rand(i * 4) * (width + 4) - 2;
      positions[i * 3 + 1] = rand(i * 4 + 1) * 6;
      positions[i * 3 + 2] = rand(i * 4 + 2) * 9 - 5;
    }
    const geometry = new THREE.BufferGeometry(); geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const points = new THREE.Points(geometry, new THREE.PointsMaterial({ color: '#bbd5cb', size: .018, transparent: true, opacity: .45, depthWrite: false }));
    world.scene.add(points); world.dust = points;
  }

  draw(state, level = {}) {
    const title = state.mode === 'title' || state.mode === 'ending';
    const key = title ? 'title' : state.room;
    const world = this.worlds.get(key) || this.makeWorld(key, level, title);
    const t = state.time || 0;
    const center = title ? 7.5 : ((state.camera || 0) + 640) / 100;
    const shake = (state.shake || 0) / 100;
    this.camera.position.set(center + Math.sin(t * 36) * shake, 3.9 + Math.sin(t * 43) * shake * .4, 11.6);
    this.camera.lookAt(center, 2.05, 0);
    world.sun.position.set(center - 2.5, 8, 4.5); world.sun.target.position.set(center, 0, 0);
    world.dust.position.y = Math.sin(t * .08) * .1;
    const hero = world.hero;
    if (title) {
      hero.body.rotation.z = Math.sin(t * 1.7) * .012;
      hero.root.rotation.y = -.24;
      this.renderer.toneMappingExposure = state.mode === 'ending' ? 1.6 : 1.22;
    } else {
      this.renderer.toneMappingExposure = 1.3;
      const p = state.player;
      if (p) {
        hero.root.position.set((p.x + p.w / 2) / 100, worldY(p.y + p.h), p.z || 0);
        hero.root.rotation.y = p.facing === -1 ? Math.PI - .22 : -.22;
        const walk = p.grounded && Math.abs(p.vx) > 10 ? Math.sin(t * 13) : 0;
        hero.body.position.y = Math.abs(walk) * .015;
        hero.body.scale.y = p.crouching ? .56 : 1;
        hero.body.rotation.z = p.crouching ? -.11 : walk * .022;
        hero.legs[0].rotation.z = walk * .48; hero.legs[1].rotation.z = -walk * .48;
        hero.cloak.rotation.z = Math.abs(p.vx) > 10 ? -.08 : Math.sin(t * 2) * .012;
        hero.light.intensity = p.hidden ? .22 : .8;
      }
      if (world.crate) world.crate.position.set(state.crate.x / 100, worldY(state.crate.y + state.crate.h), 0);
      if (world.plate) {
        world.plate.position.y = state.plateDown ? .009 : .035;
        world.plate.material = state.plateDown ? this.materials.metal : this.materials.copper;
        world.wireMaterial.emissive.set(state.gateOpen ? '#a7d28c' : '#3d2b12');
        world.wireMaterial.emissiveIntensity = state.gateOpen ? .85 : .5;
      }
      if (world.gate) world.gate.position.y = state.gateOpen ? world.gateHeight - .25 : 0;
      for (const [id, object] of world.objects) {
        if (object.object.kind === 'memory') {
          object.root.visible = !(state.memories || []).includes(id);
          object.root.position.y = object.initialY + Math.sin(t * 2 + object.object.x) * .045;
          object.root.rotation.y = t * .3;
        }
        if (id === 'fuse') object.root.visible = !state.fuseTaken;
        if (id === 'socket') object.insert.visible = !!state.powerOn;
      }
      if (world.socketLamp) world.socketLamp.material = state.powerOn ? this.materials.green : this.materials.red;
      for (const v of world.valves) {
        const active = (state.sequence || []).includes(v.number) || state.pumpOn;
        v.wheel.rotation.z = state.pumpOn ? t * .8 : active ? .55 : 0;
        v.lamp.material = active ? this.materials.green : this.materials.red;
      }
      if (world.watcher) this.updateWatcher(world, state, t);
      if (world.rotor) {
        world.rotor.rotation.z = state.pumpOn ? t * .8 : -.1;
        world.pumpCore.material = state.pumpOn ? this.materials.green : this.materials.red;
        world.flood.visible = !!state.pumpOn;
        world.flood.position.x = (state.chaseX || -320) / 100;
        world.waves.forEach((wave, i) => { wave.position.x = -.25 + Math.sin(t * 3 + i) * .18; wave.rotation.z = Math.sin(t * 2 + i) * .2; });
      }
    }
    this.renderer.render(world.scene, this.camera);
  }

  updateWatcher(world, state, t) {
    const watch = state.watcher || { phase: 'sleep', beamX: 1250 };
    const awake = watch.phase !== 'sleep';
    world.watcherEye.visible = awake;
    world.watcherLid.visible = !awake;
    world.watcher.rotation.z = Math.sin(t * .55) * .025;
    world.beam.visible = awake; world.watchLight.visible = awake;
    if (!awake) return;
    const eye = point(13.45, 2.12, -1.15), target = point(watch.beamX / 100, .02, 0);
    const delta = eye.clone().sub(target);
    world.beam.position.copy(eye.clone().add(target).multiplyScalar(.5));
    world.beam.scale.set(1, delta.length(), 1);
    world.beam.quaternion.setFromUnitVectors(point(0, 1, 0), delta.normalize());
    world.beam.material.opacity = watch.phase === 'watch' ? .13 : .055;
    world.watchLight.target.position.copy(target);
    world.watchLight.intensity = watch.phase === 'watch' ? 12 : 4;
  }
}

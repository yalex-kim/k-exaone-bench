

And here's a self-contained HTML document that builds a 3D windmill scene with Three.js, using only basic shapes and no external model files.
```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>언덕 위의 풍차 · Three.js</title>
<style>
  html, body { margin: 0; height: 100%; overflow: hidden; background: #0b1220; }
  canvas { display: block; }
  #hud {
    position: fixed; left: 16px; bottom: 14px; padding: 8px 12px; border-radius: 10px;
    font: 13px/1.5 ui-sans-serif, system-ui, "Segoe UI", sans-serif;
    color: #eaf3ff; background: rgba(8, 18, 32, .45); backdrop-filter: blur(6px);
    pointer-events: none; user-select: none;
  }
  #fallback {
    display: none; position: fixed; inset: 0; place-items: center;
    font: 15px/1.6 system-ui, sans-serif; color: #ffd9d9; background: #2a0f14;
  }
</style>
</head>
<body>
<canvas id="scene"></canvas>
<div id="hud">드래그 : 회전 · 휠 : 확대/축소 · 우클릭 드래그 : 화면 이동</div>
<div id="fallback">이 브라우저에서는 WebGL을 사용할 수 없어 장면을 표시할 수 없습니다.</div>

<script type="importmap">
{ "imports": {
   "three": "https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js",
   "three/addons/": "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"
 }
}
</script>

<script type="module">
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

/* ============================ 상수 ============================ */
const HILL  = { radius: 11, height: 2.4, radialSegments: 64, verticalSegments: 20, apexTrim: 0.03 };
const GROUND = { radius: 60 };
const SKY   = { radius: 700, horizon: 0xbfd9ec, zenith: 0x3f83c4 };
const FOG   = { color: 0xc6dfee, near: 16, far: 72 };
const SUN   = { position: new THREE.Vector3(12, 24, 6), intensity: 2.4, mapSize: 2048,
                shadowLeft: -52, shadowRight: 52, shadowTop: 52, shadowBottom: -52,
                shadowNear: 1, shadowFar: 140, bias: -0.0008 };
const WIND  = { baseSpeed: 1.05, gustAmount: 0.16, gustFreq: 0.7 };
const CAMERA = { fov: 45, near: 0.1, far: 600, start: new THREE.Vector3(-20, 11, -24),
                 target: new THREE.Vector3(0, 3.4, 0), minDistance: 7, maxDistance: 90 };
const TREES = [
  { x:  6.9, z:  3.1, scale: 1.20, tint: 0x3f7a3a, lean:  0.06 },
  { x: -7.2, z:  4.0, scale: 1.00, tint: 0x4a8a3f, lean: -0.05 },
  { x:  3.6, z: -7.6, scale: 1.10, tint: 0x356b31, lean:  0.04 },
  { x: -4.4, z: -7.1, scale: 0.95, tint: 0x4f9a45, lean: -0.06 },
  { x:  8.3, z: -5.0, scale: 0.90, tint: 0x3f7a3a, lean:  0.05 }
];

/* ============================ 캔버스 / 렌더러 ============================ */
const canvas = document.getElementById('scene');
const fallback = document.getElementById('fallback');
const context = canvas.getContext('webgl2', { antialias: true })
             || canvas.getContext('webgl', { antialias: true })
             || canvas.getContext('experimental-webgl');
if (!context) { fallback.style.display = 'grid'; throw new Error('WebGL 초기화 실패'); }

const renderer = new THREE.WebGLRenderer({ canvas, context, antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.02;

/* ============================ 씬 / 카메라 / 컨트롤 ============================ */
const scene = new THREE.Scene();
scene.background = new THREE.Color(SKY.horizon);

const camera = new THREE.PerspectiveCamera(
  CAMERA.fov, window.innerWidth / window.innerHeight, CAMERA.near, CAMERA.far
);
camera.position.copy(CAMERA.start);

const controls = new OrbitControls(camera, canvas);
controls.target.copy(CAMERA.target);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.minDistance = CAMERA.minDistance;
controls.maxDistance = CAMERA.maxDistance;
controls.minPolarAngle = 0.02;
controls.maxPolarAngle = Math.PI * 0.5 - 0.02;
controls.enablePan = true;

/* ============================ 유틸 ============================ */
// 언덕 단면(반구) 위의 높이: y = h·√(1 − (r/R)²)
function hillHeightAt(radius) {
  const t = radius / HILL.radius;
  return t >= 1 ? 0 : HILL.height * Math.sqrt(Math.max(0, 1 - t * t));
}

function smoothstep(t) { return t * t * (3 - 2 * t); }

/* ============================ 하늘 (그라디언트 스피어) ============================ */
function createSky() {
  const geo = new THREE.SphereGeometry(SKY.radius, 48, 32);
  const pos = geo.getAttribute('position');
  const horizon = new THREE.Color(SKY.horizon);
  const zenith = new THREE.Color(SKY.zenith);
  const colors = new Float32Array(pos.count * 3);
  for (let i = 0; i < pos.count; i++) {
    const t = smoothstep(Math.max(0, Math.min(1, pos.getY(i) / SKY.radius)));
    const c = horizon.clone().lerp(zenith, t);
    colors[i * 3] = c.r; colors[i * 3 + 1] = c.g; colors[i * 3 + 2] = c.b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  const mat = new THREE.MeshBasicMaterial({ vertexColors: true, side: THREE.BackSide, fog: false });
  return new THREE.Mesh(geo, mat);
}

/* ============================ 지면 & 언덕 ============================ */
function createGround() {
  const geo = new THREE.CircleGeometry(GROUND.radius, 96);
  const mat = new THREE.MeshStandardMaterial({ color: 0x5f9a40, roughness: 1, metalness: 0 });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.y = 0;
  mesh.receiveShadow = true;
  return mesh;
}

function createHill() {
  const { radius, height, radialSegments, verticalSegments, apexTrim } = HILL;
  const geo = new THREE.BufferGeometry();
  const positions = [];
  const indices = [];
  for (let i = 0; i <= verticalSegments; i++) {
    const phi = apexTrim + (i / verticalSegments) * (Math.PI / 2 - apexTrim);
    const y = height * Math.cos(phi);
    const r = radius * Math.sin(phi);
    for (let j = 0; j <= radialSegments; j++) {
      const theta = (j / radialSegments) * Math.PI * 2;
      positions.push(r * Math.cos(theta), y, r * Math.sin(theta));
    }
  }
  for (let i = 0; i < verticalSegments; i++) {
    for (let j = 0; j < radialSegments; j++) {
      const a = i * (radialSegments + 1) + j;
      const b = a + 1;
      const c = a + radialSegments + 1;
      const d = c + 1;
      indices.push(a, b, c, b, d, c);
    }
  }
  geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geo.setIndex(indices);
  geo.computeVertexNormals();
  geo.computeBoundingSphere();

  const mat = new THREE.MeshStandardMaterial({
    color: 0x79b352, roughness: 0.95, metalness: 0
  });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.y = 0;
  mesh.receiveShadow = true;
  mesh.side = THREE.DoubleSide;
  return mesh;
}

/* ============================ 풍차 ============================ */
function createWindmill() {
  const g = new THREE.Group();
  g.position.y = 1.6;               // 언덕 꼭대기에 살짝 묻히게
  g.castShadow = true;

  const stoneMat    = new THREE.MeshStandardMaterial({ color: 0xc9c1b1, roughness: 0.95, metalness: 0 });
  const roofMat     = new THREE.MeshStandardMaterial({ color: 0xae9f8c, roughness: 0.95, metalness: 0 });
  const woodMat     = new THREE.MeshStandardMaterial({ color: 0x5d4531, roughness: 0.78, metalness: 0.12 });
  const sailMat     = new THREE.MeshStandardMaterial({ color: 0xc2a878, roughness: 0.90, metalness: 0.02 });

  // 돌 원통 몸통
  const body = new THREE.Mesh(
    new THREE.CylinderGeometry(3.05, 3.35, 8.6, 26, 2, false), stoneMat
  );
  body.position.y = 4.3;
  body.castShadow = true;
  body.receiveShadow = true;
  g.add(body);

  // 원뿔 지붕
  const roof = new THREE.Mesh(new THREE.ConeGeometry(3.35, 5.2, 12, 1, false), roofMat);
  roof.position.y = 11.2;
  roof.castShadow = true;
  g.add(roof);

  const finial = new THREE.Mesh(new THREE.SphereGeometry(0.32, 10, 8), roofMat);
  finial.position.y = 13.72;
  finial.castShadow = true;
  g.add(finial);

  // 회전부: 앞으로 튀어나온 축 + 허브 + 4개 날개
  const rotor = new THREE.Group();
  rotor.position.y = 8.0;

  const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.30, 4.4, 12), woodMat);
  shaft.rotation.x = Math.PI / 2;
  shaft.position.z = 4.3;      // 몸통 안쪽(z≈2.1)부터 앞쪽 허브까지
  shaft.castShadow = true;
  rotor.add(shaft);

  const hub = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.62, 0.5, 18), woodMat);
  hub.rotation.x = Math.PI / 2;
  hub.position.z = 6.45;
  hub.castShadow = true;
  rotor.add(hub);

  const BLADE_RADIUS = 4.35;   // 허브 중심 기준 날개 길이
  for (let i = 0; i < 4; i++) {
    const blade = new THREE.Group();
    blade.rotation.z = (i * Math.PI) / 2;   // 90° 간격 4장

    const spar = new THREE.Mesh(new THREE.BoxGeometry(3.7, 0.4, 0.15), woodMat);
    spar.position.x = 2.15;                 // 반지름 방향으로 놓인 보강재
    spar.castShadow = true;
    blade.add(spar);

    const sail = new THREE.Mesh(new THREE.BoxGeometry(3.9, 3.5, 0.07), sailMat);
    sail.position.x = 2.3;
    sail.castShadow = true;
    blade.add(sail);

    rotor.add(blade);
  }

  g.add(rotor);
  return { group: g, rotor };
}

/* ============================ 나무 ============================ */
function createTree({ x, z, scale, tint, lean }) {
  const group = new THREE.Group();
  group.position.set(x, hillHeightAt(Math.hypot(x, z)) - 0.08, z);
  group.rotation.z = lean;
  group.castShadow = true;

  const trunkMat = new THREE.MeshStandardMaterial({ color: 0x6b4a2f, roughness: 0.98, metalness: 0 });
  const trunk = new THREE.Mesh(
    new THREE.CylinderGeometry(0.26 * scale, 0.34 * scale, 1.9 * scale, 10), trunkMat
  );
  trunk.position.y = 0.95 * scale;
  trunk.castShadow = true;
  group.add(trunk);

  const leafMat = new THREE.MeshStandardMaterial({ color: tint, roughness: 0.9, metalness: 0 });
  const blobs = [
    { x: 0,     y: 1.45, z: 0,     r: 0.85 },
    { x: 0.55,  y: 2.05, z: -0.35, r: 0.66 },
    { x: -0.60, y: 2.15, z:  0.40, r: 0.60 }
  ];
  for (const b of blobs) {
    const s = new THREE.Mesh(
      new THREE.SphereGeometry(b.r * scale, 12, 10), leafMat
    );
    s.position.set(b.x * scale, b.y * scale, b.z * scale);
    s.castShadow = true;
    group.add(s);
  }
  return group;
}

/* ============================ 조명 ============================ */
function createLights() {
  const sun = new THREE.DirectionalLight(0xfff3e0, SUN.intensity);
  sun.position.copy(SUN.position);
  sun.castShadow = true;
  sun.shadow.mapSize.set(SUN.mapSize, SUN.mapSize);
  sun.shadow.camera.left = SUN.shadowLeft;
  sun.shadow.camera.right = SUN.shadowRight;
  sun.shadow.camera.top = SUN.shadowTop;
  sun.shadow.camera.bottom = SUN.shadowBottom;
  sun.shadow.camera.near = SUN.shadowNear;
  sun.shadow.camera.far = SUN.shadowFar;
  sun.shadow.bias = SUN.bias;
  sun.shadow.normalBias = 0.02;
  sun.target.position.set(0, 0, 0);
  scene.add(sun);
  scene.add(sun.target);

  const hemi = new THREE.HemisphereLight(0x9dc6ea, 0x7d9a52, 0.55);
  scene.add(hemi);
  return sun;
}

/* ============================ 장면 조립 ============================ */
const windmill = createWindmill();
scene.add(createSky());
scene.add(createGround());
scene.add(createHill());
for (const t of TREES) scene.add(createTree(t));
scene.add(windmill.group);
createLights();

scene.fog = new THREE.Fog(FOG.color, FOG.near, FOG.far);

/* ============================ 크기 조정 ============================ */
function resize() {
  const w = window.innerWidth;
  const h = window.innerHeight;
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(w, h, true);
}
window.addEventListener('resize', resize);
resize();

/* ============================ 애니메이션 ============================ */
const clock = new THREE.Clock();
canvas.addEventListener('contextmenu', (e) => e.preventDefault());

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.05);
  const t = clock.getElapsedTime();

  // 날개 회전 (미세한 바람 변동 포함)
  const speed = WIND.baseSpeed * (1 + WIND.gustAmount * Math.sin(t * WIND.gustFreq));
  windmill.rotor.rotation.z += speed * dt;

  controls.update();
  renderer.render(scene, camera);
}
animate();
</script>
</body>
</html>
```
### Windmill Mechanics & Scene Composition

The scene combines a few simple systems to let you interact with the windmill and its surroundings.

- **Rotating blades**: Four blades are mounted on a shaft that sticks out from the front of the stone tower. Their rotation speed is slightly modulated by a sine wave, so the spinning feels gently wind-driven.
- **Drag & drop navigation**: Mouse drag orbits the camera around the hill, scroll wheel zooms in and out, and right-drag pans the view. Damping smooths out the movement.
- **Lighting & shadows**: A directional light casts soft shadows from the top-right, while a hemisphere light fills the scene with ambient sky and ground color.
- **Terrain & props**: A grassy disc ground, a raised dome hill, and five procedurally placed trees (with trunk and leaf spheres) sit under the windmill.
- **Daylight sky**: A large backside sphere paints a color gradient from pale horizon blue to deeper zenith, wrapped in atmospheric fog.
---

**Optimization Tip:** You can adjust `WIND.baseSpeed` and `WIND.gustAmount` to change how fast and how subtly the blades spin. For a different scene layout, modify the `TREES` array entries (position, scale, tint) or change `SUN.intensity` and color temperature.
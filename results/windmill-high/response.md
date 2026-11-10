

Three.js CDN(importmap)과 기본 도형만으로 만든 단일 HTML 파일입니다. 돌 원통 몸통, 원뿔 지붕, 실제로 회전하는 격자 날개(앞으로 돌출된 축), 나무 5그루, 잔디 언덕/지면, 그라데이션 하늘, 방향광 그림자, OrbitControls 마우스로 모두 동작합니다.

```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>언덕 위의 풍차 · Three.js</title>
<style>
  html, body { margin: 0; height: 100%; overflow: hidden; background: #8ecae6;
    font-family: system-ui, -apple-system, "Segoe UI", "Malgun Gothic", sans-serif; }
  canvas { display: block; width: 100vw; height: 100vh; touch-action: none; cursor: grab; }
  canvas:active { cursor: grabbing; }
  .hud { position: fixed; left: 16px; bottom: 16px; padding: 8px 14px; border-radius: 999px;
    background: rgba(255,255,255,.55); color: #17323f; font-size: 12.5px; letter-spacing: .02em;
    pointer-events: none; user-select: none; box-shadow: 0 2px 12px rgba(16,58,78,.16); }
</style>
<script type="importmap">
{
  "imports": {
    "three": "https://unpkg.com/three@0.160.0/build/three.module.js",
    "three/addons/": "https://unpkg.com/three@0.160.0/examples/jsm/"
  }
}
</script>
</head>
<body>
<canvas id="view"></canvas>
<div class="hud">드래그 : 회전 · 휠 : 확대/축소 · 우클릭 드래그 : 이동</div>

<script type="module">
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

/* ───────── 유틸 ───────── */
function makeMesh(geometry, material, position) {
  const m = new THREE.Mesh(geometry, material);
  if (position) m.position.set(position[0], position[1], position[2]);
  m.castShadow = true;
  m.receiveShadow = true;
  return m;
}

/* ───────── 렌더러 ───────── */
const canvas = document.getElementById('view');
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.setClearColor(new THREE.Color(0x8ecae6), 1);

/* ───────── 장면 ───────── */
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x8ecae6);
scene.fog = new THREE.Fog(0xa9d6ea, 70, 300);

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);

/* 하늘 : 그라데이션 돔 (실패해도 하늘색 단색으로 보임) */
const skyMat = new THREE.ShaderMaterial({
  side: THREE.BackSide,
  depthWrite: false,
  fog: false,
  uniforms: {
    uTop: { value: new THREE.Color(0x3f97d8) },
    uHorizon: { value: new THREE.Color(0xd3e9f2) }
  },
  vertexShader: `
    varying vec3 vPos;
    void main() { vPos = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }
  `,
  fragmentShader: `
    uniform vec3 uTop; uniform vec3 uHorizon; varying vec3 vPos;
    void main() {
      float h = normalize(vPos).y;
      gl_FragColor = vec4(mix(uHorizon, uTop, smoothstep(-0.1, 0.8, h)), 1.0);
    }
  `
});
skyMat.fog = false;
scene.add(new THREE.Mesh(new THREE.SphereGeometry(900, 32, 20), skyMat));

/* 잔디 지면 */
const ground = makeMesh(new THREE.PlaneGeometry(800, 800),
  new THREE.MeshStandardMaterial({ color: 0x6f9e47, roughness: 1 }), [0, 0, 0]);
ground.rotation.x = -Math.PI / 2;
scene.add(ground);

/* 언덕 (반구형 돔) */
const HILL_R = 46;
const HILL_SCALE = new THREE.Vector3(1.2, 0.68, 1.1);
const hill = makeMesh(new THREE.SphereGeometry(HILL_R, 40, 24),
  new THREE.MeshStandardMaterial({ color: 0x5f8f42, roughness: 1 }), [0, 0, 0]);
hill.scale.copy(HILL_SCALE);
scene.add(hill);

/* 타원 돔 표면 높이 계산 */
const hillY = (x, z) => {
  const a = HILL_R * HILL_SCALE.x, b = HILL_R * HILL_SCALE.y, c = HILL_R * HILL_SCALE.z;
  const q = (x / a) ** 2 + (z / c) ** 2;
  return q < 1 ? b * Math.sqrt(1 - q) : 0;
};

/* ───────── 풍차 ───────── */
const mill = new THREE.Group();
mill.position.y = hillY(0, 0) - 0.4;   // 언덕 꼭대기에 살짝 묻어 고정
scene.add(mill);

const stoneMat = new THREE.MeshStandardMaterial({ color: 0xb6ae9e, roughness: 0.92, metalness: 0.02 });
const roofMat = new THREE.MeshStandardMaterial({ color: 0x8b8071, roughness: 0.92, metalness: 0.02 });
const axleMat = new THREE.MeshStandardMaterial({ color: 0x6f7479, roughness: 0.45, metalness: 0.5 });
const hubMat = new THREE.MeshStandardMaterial({ color: 0x666b70, roughness: 0.4, metalness: 0.55 });
const sailMat = new THREE.MeshStandardMaterial({ color: 0xc9a173, roughness: 0.95 });

// 돌 원통 몸통
const body = makeMesh(new THREE.CylinderGeometry(12, 12, 26, 40, 1), stoneMat, [0, 13, 0]);
body.material.flatShading = true;
mill.add(body);

// 앞문
mill.add(makeMesh(new THREE.BoxGeometry(3.8, 4.8, 0.8),
  new THREE.MeshStandardMaterial({ color: 0x5b4030, roughness: 0.95 }), [0, 2.4, 12.4]));

// 원뿔 지붕 (몸통 위로 살짝 겹쳐 물림)
const roof = makeMesh(new THREE.ConeGeometry(13.5, 0, 48, 1), roofMat, [0, 32, 0]);
roof.material.flatShading = true;
mill.add(roof);
mill.add(makeMesh(new THREE.SphereGeometry(1.1, 8, 6),
  new THREE.MeshStandardMaterial({ color: 0x7a7164 }), [0, 41, 0]));

// 날개 축 : 몸통 앞으로 돌출 (축이 Z방향이라 앞에서 뚫고 나옴)
const axle = makeMesh(new THREE.CylinderGeometry(1.7, 1.8, 40, 12), axleMat, [0, 32, 14]);
axle.rotation.x = Math.PI / 2;
mill.add(axle);
mill.add(makeMesh(new THREE.SphereGeometry(2.6, 12, 8), hubMat, [0, 32, 14]));

// 날개 4장 : 축을 중심으로 XY 평면(바람개비면)에서 회전
const sails = new THREE.Group();
sails.position.set(0, 32, 14);

const SAIL_INNER = 5;
const SAIL_OUTER = 26;
const SAIL_LEN = SAIL_OUTER - SAIL_INNER;

function addSailFrame(parent) {
  parent.add(makeMesh(new THREE.BoxGeometry(SAIL_LEN, 2.0, 2.0), sailMat,
    [(SAIL_INNER + SAIL_OUTER) / 2, 0, 0]));                       // 세로 대
  parent.add(makeMesh(new THREE.BoxGeometry(2.0, 7.0, 2.0), sailMat,
    [SAIL_INNER + 1.5, 0, 0]));                                     // 가로대 3개
  parent.add(makeMesh(new THREE.BoxGeometry(2.0, 8.0, 2.0), sailMat,
    [SAIL_INNER + SAIL_LEN * 0.35, 0, 0]));
  parent.add(makeMesh(new THREE.BoxGeometry(2.0, 5.0, 2.0), sailMat,
    [SAIL_OUTER - 1.2, 0, 0]));
}
for (let i = 0; i < 4; i++) {
  const blade = new THREE.Group();
  blade.rotation.z = (i * Math.PI) / 2;
  addSailFrame(blade);
  sails.add(blade);
}
mill.add(sails);

/* ───────── 나무 5그루 (줄기 + 잎 덩어리) ───────── */
function createTree(x, y, z, scale, leafColor) {
  const tree = new THREE.Group();
  tree.position.set(x, y, z);
  tree.scale.setScalar(scale);

  tree.add(makeMesh(new THREE.CylinderGeometry(0.32, 0.48, 3.6, 8),
    new THREE.MeshStandardMaterial({ color: 0x6b4a30, roughness: 1 }), [0, 1.8, 0]));

  const leafMat = new THREE.MeshStandardMaterial({ color: leafColor, roughness: 0.95 });
  const blobs = [[0, 3.9, 0, 1.55], [-0.62, 3.25, 0.32, 1.22], [0.6, 3.35, -0.36, 1.28]];
  for (const [bx, by, bz, br] of blobs) {
    tree.add(makeMesh(new THREE.SphereGeometry(br, 14, 10), leafMat, [bx, by, bz]));
  }
  scene.add(tree);
}

createTree(-48, 0, -32, 1.15, 0x3c8a3f);
createTree(36, 0, 34, 0.95, 0x2f7a37);
createTree(0, 0, 64, 0.8, 0x3f8f45);
createTree(-26, hillY(-26, -4), -4, 0.85, 0x35843c);   // 언덕 위
createTree(62, 0, -18, 1.05, 0x2f7a37);

/* ───────── 조명 ───────── */
scene.add(new THREE.HemisphereLight(0xbfdcf0, 0x4d6b33, 0.9));

const sun = new THREE.DirectionalLight(0xfff0d8, 1.5);
sun.position.set(70, 78, 52);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.bias = -0.0004;
sun.shadow.normalBias = 0.02;
sun.shadow.camera.left = -110;
sun.shadow.camera.right = 110;
sun.shadow.camera.top = 110;
sun.shadow.camera.bottom = -110;
sun.shadow.camera.near = 1;
sun.shadow.camera.far = 520;
sun.shadow.camera.updateProjectionMatrix();
sun.target.position.set(0, 22, 0);
scene.add(sun.target);
scene.add(sun);

/* ───────── 카메라 & 컨트롤 ───────── */
camera.position.set(38, 48, 92);
const controls = new OrbitControls(camera, canvas);
controls.target.set(0, 30, 0);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.minDistance = 22;
controls.maxDistance = 170;
controls.maxPolarAngle = Math.PI / 2;
controls.update();
canvas.addEventListener('contextmenu', (e) => e.preventDefault());

/* ───────── 리사이즈 ───────── */
function resize() {
  const w = window.innerWidth, h = window.innerHeight;
  renderer.setSize(w, h, false);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}
window.addEventListener('resize', resize);
resize();

/* ───────── 애니메이션 루프 ───────── */
const clock = new THREE.Clock();
renderer.setAnimationLoop(() => {
  const dt = Math.min(clock.getDelta(), 0.05);   // 초
  sails.rotation.z += dt * 0.7;                  // 약 9초에 한 바퀴
  controls.update();
  renderer.render(scene, camera);
});
</script>
</body>
</html>
```
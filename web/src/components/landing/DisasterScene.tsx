"use client";

import { useEffect, useRef } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";

export type DisasterScenario = "gempa" | "tsunami" | "banjir";

type Props = {
  scenario: DisasterScenario;
  className?: string;
};

// Ukuran dunia dan resolusi grid. Grid sengaja moderat agar ringan di laptop dan ponsel.
const WORLD = 24;
const TERRAIN_SEGMENTS = 150;
const WATER_SEGMENTS = 110;
const TEX_SIZE = 512;

// Palet Siagaku. Warna status hanya dipakai untuk makna status.
const COLOR = {
  navy: 0x12263f,
  cream: 0xf4f2ee,
  border: 0xd9d5cd,
  awas: 0xc62828,
  aman: 0x2e7d32,
  info: 0x1565c0,
};

// Parameter per skenario. Nilai dicampur halus saat skenario berganti.
const SCENARIO_PARAMS: Record<
  DisasterScenario,
  { waterLevel: number; shake: number; tsunami: number; rain: number; ripple: number }
> = {
  gempa: { waterLevel: 0, shake: 1, tsunami: 0, rain: 0, ripple: 0.6 },
  tsunami: { waterLevel: 0.05, shake: 0, tsunami: 1, rain: 0, ripple: 0.4 },
  banjir: { waterLevel: 0.62, shake: 0, tsunami: 0, rain: 1, ripple: 0.25 },
};

/* ---------- Noise prosedural (value noise + fbm), deterministik ---------- */

function hash(x: number, y: number) {
  const s = Math.sin(x * 127.1 + y * 311.7) * 43758.5453123;
  return s - Math.floor(s);
}

function valueNoise(x: number, y: number) {
  const xi = Math.floor(x);
  const yi = Math.floor(y);
  const xf = x - xi;
  const yf = y - yi;
  const u = xf * xf * (3 - 2 * xf);
  const v = yf * yf * (3 - 2 * yf);
  const a = hash(xi, yi);
  const b = hash(xi + 1, yi);
  const c = hash(xi, yi + 1);
  const d = hash(xi + 1, yi + 1);
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}

function fbm(x: number, y: number, octaves = 4) {
  let sum = 0;
  let amp = 0.5;
  let freq = 1;
  for (let i = 0; i < octaves; i++) {
    sum += amp * valueNoise(x * freq, y * freq);
    freq *= 2;
    amp *= 0.5;
  }
  return sum;
}

function smoothstep(e0: number, e1: number, x: number) {
  const t = Math.min(1, Math.max(0, (x - e0) / (e1 - e0)));
  return t * t * (3 - 2 * t);
}

// Koordinat garis pantai. Nilai negatif berarti daratan, positif berarti laut.
function coast(x: number, z: number) {
  return x - 1.2 + Math.sin(z * 0.32) * 0.9 + Math.sin(z * 0.11 + 1.3) * 0.6;
}

function terrainHeight(x: number, z: number) {
  const s = coast(x, z);
  // Lereng pantai landai lalu dasar laut.
  const shore = THREE.MathUtils.clamp(-s * 0.16, -1.4, 0.55);
  // Perbukitan di sisi darat yang jauh dari pantai, tempat titik evakuasi.
  const hillMask = smoothstep(-3.5, -9, s);
  const hills = hillMask * (fbm(x * 0.16 + 3.1, z * 0.16 - 1.7, 4) * 4.2 - 0.6);
  const detail = (fbm(x * 0.9, z * 0.9, 3) - 0.5) * 0.12;
  return shore + Math.max(0, hills) + detail;
}

/* ---------- Tekstur PBR prosedural (pengganti map_Kd / map_Pr / map_Bump) ---------- */

function makeTerrainTextures() {
  const size = TEX_SIZE;
  const albedo = document.createElement("canvas");
  const rough = document.createElement("canvas");
  const normal = document.createElement("canvas");
  for (const c of [albedo, rough, normal]) {
    c.width = size;
    c.height = size;
  }
  const aCtx = albedo.getContext("2d")!;
  const rCtx = rough.getContext("2d")!;
  const nCtx = normal.getContext("2d")!;
  const aImg = aCtx.createImageData(size, size);
  const rImg = rCtx.createImageData(size, size);
  const nImg = nCtx.createImageData(size, size);

  const sand = new THREE.Color(0xe7dcc6);
  const wetSand = new THREE.Color(0xb9a98c);
  const seabed = new THREE.Color(0x52606b);
  const grass = new THREE.Color(0x8a9670);
  const hill = new THREE.Color(0x6d7a5a);
  const rock = new THREE.Color(0x8c8577);
  const tmp = new THREE.Color();

  for (let j = 0; j < size; j++) {
    for (let i = 0; i < size; i++) {
      const x = (i / size) * WORLD - WORLD / 2;
      const z = (j / size) * WORLD - WORLD / 2;
      const h = terrainHeight(x, z);
      const grain = fbm(x * 3.2, z * 3.2, 3);

      // Albedo berdasar ketinggian, seperti peta topografi yang tenang.
      if (h < -0.15) tmp.copy(seabed).lerp(wetSand, smoothstep(-1.2, -0.15, h));
      else if (h < 0.12) tmp.copy(wetSand).lerp(sand, smoothstep(-0.15, 0.12, h));
      else if (h < 0.7) tmp.copy(sand).lerp(grass, smoothstep(0.12, 0.7, h));
      else if (h < 2.2) tmp.copy(grass).lerp(hill, smoothstep(0.7, 2.2, h));
      else tmp.copy(hill).lerp(rock, smoothstep(2.2, 3.4, h));
      tmp.offsetHSL(0, 0, (grain - 0.5) * 0.08);

      const k = (j * size + i) * 4;
      aImg.data[k] = tmp.r * 255;
      aImg.data[k + 1] = tmp.g * 255;
      aImg.data[k + 2] = tmp.b * 255;
      aImg.data[k + 3] = 255;

      // Roughness, pasir basah di bibir pantai lebih mengkilap.
      const wet = 1 - smoothstep(-0.05, 0.25, Math.abs(h));
      const r = THREE.MathUtils.clamp(0.92 - wet * 0.45 + (grain - 0.5) * 0.15, 0.3, 1);
      rImg.data[k] = rImg.data[k + 1] = rImg.data[k + 2] = r * 255;
      rImg.data[k + 3] = 255;

      // Normal map detail mikro dari turunan noise halus.
      const e = 0.04;
      const fx = fbm((x + e) * 3.2, z * 3.2, 3) - grain;
      const fz = fbm(x * 3.2, (z + e) * 3.2, 3) - grain;
      const nx = -fx * 6;
      const ny = -fz * 6;
      const len = Math.hypot(nx, ny, 1);
      nImg.data[k] = (nx / len * 0.5 + 0.5) * 255;
      nImg.data[k + 1] = (ny / len * 0.5 + 0.5) * 255;
      nImg.data[k + 2] = (1 / len * 0.5 + 0.5) * 255;
      nImg.data[k + 3] = 255;
    }
  }
  aCtx.putImageData(aImg, 0, 0);
  rCtx.putImageData(rImg, 0, 0);
  nCtx.putImageData(nImg, 0, 0);

  // Kanvas baris 0 dipetakan ke z = -WORLD/2, jadi flipY dimatikan agar cocok dengan UV plane.
  const map = new THREE.CanvasTexture(albedo);
  map.colorSpace = THREE.SRGBColorSpace;
  const roughnessMap = new THREE.CanvasTexture(rough);
  const normalMap = new THREE.CanvasTexture(normal);
  for (const t of [map, roughnessMap, normalMap]) {
    t.flipY = false;
    t.anisotropy = 4;
  }
  return { map, roughnessMap, normalMap };
}

function makeFacadeTexture() {
  // Fasad gedung sederhana dengan jendela, dipakai sebagai map dan roughnessMap.
  const c = document.createElement("canvas");
  c.width = 64;
  c.height = 128;
  const ctx = c.getContext("2d")!;
  ctx.fillStyle = "#ffffff";
  ctx.fillRect(0, 0, 64, 128);
  ctx.fillStyle = "#9aa3ab";
  for (let y = 10; y < 124; y += 16) {
    for (let x = 8; x < 60; x += 16) ctx.fillRect(x, y, 9, 8);
  }
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  return t;
}

/* ---------- Komponen ---------- */

export default function DisasterScene({ scenario, className }: Props) {
  const mountRef = useRef<HTMLDivElement>(null);
  const scenarioRef = useRef<DisasterScenario>(scenario);

  useEffect(() => {
    scenarioRef.current = scenario;
  }, [scenario]);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return;

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: "high-performance" });
    } catch {
      mount.dataset.webgl = "unavailable";
      return;
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.05;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.domElement.setAttribute("aria-hidden", "true");
    mount.appendChild(renderer.domElement);

    const scene = new THREE.Scene();
    scene.fog = new THREE.Fog(COLOR.navy, 26, 48);

    // Lingkungan IBL agar material PBR punya pantulan yang meyakinkan.
    const pmrem = new THREE.PMREMGenerator(renderer);
    const envTex = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
    scene.environment = envTex;
    scene.environmentIntensity = 0.55;

    const camera = new THREE.PerspectiveCamera(38, 1, 0.1, 100);
    camera.position.set(20, 16, 20);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.target.set(-1.5, -0.6, 0);
    controls.enableDamping = true;
    controls.enableZoom = false;
    controls.enablePan = false;
    controls.minPolarAngle = Math.PI * 0.18;
    controls.maxPolarAngle = Math.PI * 0.42;
    controls.autoRotate = !reducedMotion;
    controls.autoRotateSpeed = 0.35;

    // Cahaya: matahari hangat + pengisi dingin dari langit.
    const sun = new THREE.DirectionalLight(0xfff1dc, 2.6);
    sun.position.set(-10, 16, 8);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    const sc = sun.shadow.camera;
    sc.left = sc.bottom = -14;
    sc.right = sc.top = 14;
    sc.near = 1;
    sc.far = 50;
    sun.shadow.bias = -0.0004;
    sun.shadow.normalBias = 0.03;
    scene.add(sun);
    scene.add(new THREE.HemisphereLight(0xcfe0ff, 0x3a3328, 0.6));

    // Grup yang ikut bergetar saat gempa.
    const ground = new THREE.Group();
    scene.add(ground);

    /* Terrain */
    const terrainGeo = new THREE.PlaneGeometry(WORLD, WORLD, TERRAIN_SEGMENTS, TERRAIN_SEGMENTS);
    terrainGeo.rotateX(-Math.PI / 2);
    {
      const pos = terrainGeo.attributes.position;
      for (let i = 0; i < pos.count; i++) {
        pos.setY(i, terrainHeight(pos.getX(i), pos.getZ(i)));
      }
      terrainGeo.computeVertexNormals();
      // Plane yang diputar membalik sumbu V. Samakan UV dengan koordinat dunia z.
      const uv = terrainGeo.attributes.uv;
      for (let i = 0; i < uv.count; i++) {
        uv.setXY(i, (pos.getX(i) + WORLD / 2) / WORLD, (pos.getZ(i) + WORLD / 2) / WORLD);
      }
    }
    const terrainTex = makeTerrainTextures();
    const terrainMat = new THREE.MeshStandardMaterial({
      ...terrainTex,
      metalness: 0,
      roughness: 1,
      normalScale: new THREE.Vector2(0.8, 0.8),
    });
    const terrain = new THREE.Mesh(terrainGeo, terrainMat);
    terrain.receiveShadow = true;
    terrain.castShadow = true;
    ground.add(terrain);

    // Dasar diorama, memberi kesan maket fisik.
    const baseGeo = new THREE.BoxGeometry(WORLD, 1.6, WORLD);
    const baseMat = new THREE.MeshStandardMaterial({ color: COLOR.navy, roughness: 0.55, metalness: 0.2 });
    const base = new THREE.Mesh(baseGeo, baseMat);
    base.position.y = -2.2;
    ground.add(base);

    /* Gedung kota pesisir (InstancedMesh) */
    const facade = makeFacadeTexture();
    const buildingGeo = new THREE.BoxGeometry(1, 1, 1);
    buildingGeo.translate(0, 0.5, 0);
    const buildingMat = new THREE.MeshStandardMaterial({
      map: facade,
      roughness: 0.62,
      metalness: 0.08,
    });
    type Building = { x: number; z: number; w: number; d: number; h: number; base: number; tilt: number };
    const buildings: Building[] = [];
    for (let gx = -10; gx <= 3; gx += 0.95) {
      for (let gz = -10; gz <= 10; gz += 0.95) {
        const jx = gx + (hash(gx, gz) - 0.5) * 0.3;
        const jz = gz + (hash(gz, gx) - 0.5) * 0.3;
        const s = coast(jx, jz);
        const h0 = terrainHeight(jx, jz);
        if (s > -0.9 || s < -6.5 || h0 > 1.1 || h0 < 0.12) continue;
        if (hash(jx * 3.1, jz * 1.7) < 0.32) continue; // jalan dan ruang terbuka
        const nearCoast = 1 - smoothstep(-6.5, -0.9, s);
        buildings.push({
          x: jx,
          z: jz,
          w: 0.45 + hash(jx, 1) * 0.3,
          d: 0.45 + hash(1, jz) * 0.3,
          h: 0.35 + hash(jx * 2, jz * 2) ** 2 * (0.6 + nearCoast * 1.6),
          base: h0 - 0.05,
          tilt: (hash(jx * 5, jz * 7) - 0.5) * 2,
        });
      }
    }
    const buildingMesh = new THREE.InstancedMesh(buildingGeo, buildingMat, buildings.length);
    buildingMesh.castShadow = true;
    buildingMesh.receiveShadow = true;
    const palette = [new THREE.Color(COLOR.cream), new THREE.Color(0xffffff), new THREE.Color(COLOR.border), new THREE.Color(0x2b4565)];
    buildings.forEach((b, i) => {
      const r = hash(b.x * 9, b.z * 9);
      buildingMesh.setColorAt(i, palette[r < 0.4 ? 0 : r < 0.7 ? 1 : r < 0.9 ? 2 : 3]);
    });
    ground.add(buildingMesh);

    const dummy = new THREE.Object3D();
    function layoutBuildings(quake: number, t: number) {
      buildings.forEach((b, i) => {
        dummy.position.set(b.x, b.base, b.z);
        // Gedung bergoyang kecil saat gempa, bukan runtuh dramatis.
        const sway = quake * 0.05 * Math.sin(t * 22 + b.x * 3);
        dummy.rotation.set(sway * b.tilt, 0, sway);
        dummy.scale.set(b.w, b.h, b.d);
        dummy.updateMatrix();
        buildingMesh.setMatrixAt(i, dummy.matrix);
      });
      buildingMesh.instanceMatrix.needsUpdate = true;
    }
    layoutBuildings(0, 0);

    /* Titik evakuasi di puncak bukit tertinggi (status AMAN) */
    let evac = { x: -8, z: 0, h: 0 };
    for (let x = -11; x < -3; x += 0.25) {
      for (let z = -10; z < 10; z += 0.25) {
        const h = terrainHeight(x, z);
        if (h > evac.h) evac = { x, z, h };
      }
    }
    const evacGroup = new THREE.Group();
    evacGroup.position.set(evac.x, evac.h, evac.z);
    const amanMat = new THREE.MeshStandardMaterial({
      color: COLOR.aman,
      emissive: COLOR.aman,
      emissiveIntensity: 0.35,
      roughness: 0.4,
      metalness: 0.1,
    });
    const pad = new THREE.Mesh(new THREE.CylinderGeometry(0.9, 1, 0.12, 40), amanMat);
    pad.receiveShadow = true;
    evacGroup.add(pad);
    const pole = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.035, 2, 12),
      new THREE.MeshStandardMaterial({ color: 0xe8e8e8, metalness: 0.9, roughness: 0.25 }),
    );
    pole.position.y = 1;
    pole.castShadow = true;
    evacGroup.add(pole);
    const flag = new THREE.Mesh(new THREE.PlaneGeometry(0.7, 0.42, 10, 4), amanMat.clone());
    (flag.material as THREE.MeshStandardMaterial).side = THREE.DoubleSide;
    flag.position.set(0.36, 1.74, 0);
    evacGroup.add(flag);
    const amanRing = new THREE.Mesh(
      new THREE.RingGeometry(1.05, 1.2, 64),
      new THREE.MeshBasicMaterial({ color: COLOR.aman, transparent: true, opacity: 0.7, side: THREE.DoubleSide }),
    );
    amanRing.rotation.x = -Math.PI / 2;
    amanRing.position.y = 0.08;
    evacGroup.add(amanRing);
    ground.add(evacGroup);

    // Jalur evakuasi putus-putus dari kota menuju bukit.
    const routeStart = buildings.reduce((best, b) => (coast(b.x, b.z) > coast(best.x, best.z) ? b : best), buildings[0]);
    const routePts: THREE.Vector3[] = [];
    if (routeStart) {
      for (let i = 0; i <= 40; i++) {
        const t = i / 40;
        const x = THREE.MathUtils.lerp(routeStart.x, evac.x, t);
        const z = THREE.MathUtils.lerp(routeStart.z, evac.z, t) + Math.sin(t * Math.PI) * 1.4;
        routePts.push(new THREE.Vector3(x, terrainHeight(x, z) + 0.09, z));
      }
    }
    const routeGeo = new THREE.BufferGeometry().setFromPoints(routePts);
    const routeMat = new THREE.LineDashedMaterial({ color: 0xffffff, dashSize: 0.22, gapSize: 0.14 });
    const route = new THREE.Line(routeGeo, routeMat);
    route.computeLineDistances();
    ground.add(route);

    /* Sinyal SOS (status AWAS) di salah satu gedung dekat pantai */
    const sosTarget = routeStart ?? { x: 0, z: 0, base: 0, h: 1 };
    const sosGroup = new THREE.Group();
    sosGroup.position.set(sosTarget.x, sosTarget.base + sosTarget.h + 0.05, sosTarget.z);
    const sosCore = new THREE.Mesh(
      new THREE.SphereGeometry(0.13, 24, 16),
      new THREE.MeshStandardMaterial({ color: COLOR.awas, emissive: COLOR.awas, emissiveIntensity: 1.6 }),
    );
    sosCore.position.y = 0.15;
    sosGroup.add(sosCore);
    const sosRings = [0, 1, 2].map(() => {
      const ring = new THREE.Mesh(
        new THREE.RingGeometry(0.2, 0.26, 48),
        new THREE.MeshBasicMaterial({ color: COLOR.awas, transparent: true, side: THREE.DoubleSide, depthWrite: false }),
      );
      ring.rotation.x = -Math.PI / 2;
      sosGroup.add(ring);
      return ring;
    });
    ground.add(sosGroup);

    /* Gelombang seismik dari episentrum di laut (hanya skenario gempa) */
    const epicenter = new THREE.Vector3(7, 0, -3);
    const quakeRings = [0, 1, 2].map(() => {
      const ring = new THREE.Mesh(
        new THREE.RingGeometry(0.96, 1, 96),
        new THREE.MeshBasicMaterial({ color: COLOR.awas, transparent: true, side: THREE.DoubleSide, depthWrite: false }),
      );
      ring.rotation.x = -Math.PI / 2;
      ring.position.set(epicenter.x, 0.12, epicenter.z);
      scene.add(ring);
      return ring;
    });

    /* Air laut dengan material fisik (clearcoat + vertex color untuk buih) */
    const waterGeo = new THREE.PlaneGeometry(WORLD, WORLD, WATER_SEGMENTS, WATER_SEGMENTS);
    waterGeo.rotateX(-Math.PI / 2);
    const waterPos = waterGeo.attributes.position;
    // Ketinggian dasar dan jarak ke pantai statis, cukup dihitung sekali.
    const waterGround = new Float32Array(waterPos.count);
    const waterCoast = new Float32Array(waterPos.count);
    const waterX = new Float32Array(waterPos.count);
    const waterZ = new Float32Array(waterPos.count);
    for (let i = 0; i < waterPos.count; i++) {
      waterX[i] = waterPos.getX(i);
      waterZ[i] = waterPos.getZ(i);
      waterGround[i] = terrainHeight(waterX[i], waterZ[i]);
      waterCoast[i] = coast(waterX[i], waterZ[i]);
    }
    const waterColors = new Float32Array(waterPos.count * 3);
    waterGeo.setAttribute("color", new THREE.BufferAttribute(waterColors, 3));
    const waterMat = new THREE.MeshPhysicalMaterial({
      vertexColors: true,
      roughness: 0.12,
      metalness: 0,
      clearcoat: 1,
      clearcoatRoughness: 0.08,
      transparent: true,
      opacity: 0.86,
      envMapIntensity: 1.2,
    });
    const water = new THREE.Mesh(waterGeo, waterMat);
    water.receiveShadow = true;
    scene.add(water);
    const deep = new THREE.Color(0x0d3b6e);
    const shallow = new THREE.Color(COLOR.info);
    const foam = new THREE.Color(0xf4f7fa);
    const muddy = new THREE.Color(0x6b5a3e);
    const wc = new THREE.Color();

    /* Hujan untuk skenario banjir */
    const RAIN = 1400;
    const rainGeo = new THREE.BufferGeometry();
    const rainPos = new Float32Array(RAIN * 3);
    for (let i = 0; i < RAIN; i++) {
      rainPos[i * 3] = (Math.random() - 0.5) * WORLD;
      rainPos[i * 3 + 1] = Math.random() * 14;
      rainPos[i * 3 + 2] = (Math.random() - 0.5) * WORLD;
    }
    rainGeo.setAttribute("position", new THREE.BufferAttribute(rainPos, 3));
    const rainMat = new THREE.PointsMaterial({ color: 0xcfe0f5, size: 0.1, transparent: true, opacity: 0, depthWrite: false });
    const rain = new THREE.Points(rainGeo, rainMat);
    scene.add(rain);

    /* Resize, visibilitas, dan loop */
    function resize() {
      const w = mount!.clientWidth;
      const h = mount!.clientHeight;
      if (!w || !h) return;
      renderer.setSize(w, h, false);
      renderer.domElement.style.width = "100%";
      renderer.domElement.style.height = "100%";
      camera.aspect = w / h;
      // Jauhkan kamera di layar sempit agar seluruh diorama terlihat.
      camera.fov = w / h < 1 ? 52 : 40;
      camera.updateProjectionMatrix();
    }
    const ro = new ResizeObserver(resize);
    ro.observe(mount);
    resize();

    let visible = true;
    const io = new IntersectionObserver(([entry]) => {
      visible = entry.isIntersecting;
    });
    io.observe(mount);

    const current = { ...SCENARIO_PARAMS[scenarioRef.current] };
    const clock = new THREE.Clock();
    let tsunamiPhase = 0;
    let raf = 0;
    const motion = reducedMotion ? 0.25 : 1;

    function tick() {
      raf = requestAnimationFrame(tick);
      if (!visible || document.hidden) {
        clock.getDelta();
        return;
      }
      const dt = Math.min(clock.getDelta(), 0.05);
      const t = clock.elapsedTime;

      const target = SCENARIO_PARAMS[scenarioRef.current];
      const k = 1 - Math.exp(-dt * 2.2);
      for (const key of Object.keys(current) as (keyof typeof current)[]) {
        current[key] += (target[key] - current[key]) * k;
      }

      // Gempa: guncangan acak teredam pada daratan.
      const quake = current.shake * motion * (0.55 + 0.45 * Math.sin(t * 0.9) ** 2);
      ground.position.set(
        (valueNoise(t * 18, 0.5) - 0.5) * 0.14 * quake,
        (valueNoise(t * 21, 4.2) - 0.5) * 0.05 * quake,
        (valueNoise(0.8, t * 16) - 0.5) * 0.14 * quake,
      );
      layoutBuildings(quake, t);
      quakeRings.forEach((ring, i) => {
        const p = (t * 0.32 + i / 3) % 1;
        const r = 0.5 + p * 15;
        ring.scale.set(r, r, 1);
        (ring.material as THREE.MeshBasicMaterial).opacity = (1 - p) * 0.55 * current.shake;
        ring.visible = current.shake > 0.02;
      });

      // Tsunami: puncak gelombang bergerak dari laut ke darat lalu surut.
      tsunamiPhase = (tsunamiPhase + dt * 0.11 * motion) % 1;
      const front = THREE.MathUtils.lerp(13, -5.5, smoothstep(0, 0.75, tsunamiPhase));
      const fade = 1 - smoothstep(0.75, 1, tsunamiPhase);

      for (let i = 0; i < waterPos.count; i++) {
        const x = waterX[i];
        const z = waterZ[i];
        const s = waterCoast[i];
        let y =
          current.waterLevel +
          current.ripple *
            (Math.sin(x * 1.3 + t * 1.4) * 0.05 + Math.sin(z * 1.7 - t * 1.1) * 0.04 + Math.sin((x + z) * 2.3 + t * 2) * 0.02);
        const d = s - (front - 1.2);
        const crest = Math.exp(-(d * d) / 2.2) * 1.15 + (d < 0 ? 0 : Math.exp(-d / 3) * 0.35);
        const surge = crest * current.tsunami * fade;
        y += surge;
        waterPos.setY(i, y);

        const depth = THREE.MathUtils.clamp(y - waterGround[i], 0, 1.5) / 1.5;
        wc.copy(shallow).lerp(deep, depth);
        wc.lerp(muddy, current.rain * 0.55 * smoothstep(-8, 0, -s));
        wc.lerp(foam, THREE.MathUtils.clamp(surge * 0.9 - 0.25, 0, 0.85));
        waterColors[i * 3] = wc.r;
        waterColors[i * 3 + 1] = wc.g;
        waterColors[i * 3 + 2] = wc.b;
      }
      waterPos.needsUpdate = true;
      (waterGeo.attributes.color as THREE.BufferAttribute).needsUpdate = true;
      waterGeo.computeVertexNormals();

      // Hujan
      rainMat.opacity = current.rain * 0.75;
      rain.visible = current.rain > 0.02;
      if (rain.visible) {
        const rp = rainGeo.attributes.position as THREE.BufferAttribute;
        for (let i = 0; i < RAIN; i++) {
          let y = rp.getY(i) - dt * 9 * motion;
          if (y < current.waterLevel) y += 14;
          rp.setY(i, y);
        }
        rp.needsUpdate = true;
      }

      // Denyut sinyal SOS dan bendera titik evakuasi.
      sosRings.forEach((ring, i) => {
        const p = (t * 0.7 + i / 3) % 1;
        const r = 1 + p * 5;
        ring.scale.set(r, r, 1);
        (ring.material as THREE.MeshBasicMaterial).opacity = (1 - p) * 0.9;
      });
      (sosCore.material as THREE.MeshStandardMaterial).emissiveIntensity = 1.2 + Math.sin(t * 6) * 0.6;
      const fp = flag.geometry.attributes.position as THREE.BufferAttribute;
      for (let i = 0; i < fp.count; i++) {
        const fx = fp.getX(i) + 0.35;
        fp.setZ(i, Math.sin(fx * 7 - t * 5 * motion) * 0.05 * fx);
      }
      fp.needsUpdate = true;
      amanRing.scale.setScalar(1 + Math.sin(t * 2) * 0.04);

      controls.update();
      renderer.render(scene, camera);
    }
    tick();

    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      io.disconnect();
      controls.dispose();
      scene.traverse((obj) => {
        const mesh = obj as THREE.Mesh;
        mesh.geometry?.dispose();
        const mat = mesh.material as THREE.Material | THREE.Material[] | undefined;
        (Array.isArray(mat) ? mat : mat ? [mat] : []).forEach((m) => m.dispose());
      });
      Object.values(terrainTex).forEach((tex) => tex.dispose());
      facade.dispose();
      envTex.dispose();
      pmrem.dispose();
      renderer.dispose();
      renderer.domElement.remove();
    };
  }, []);

  return <div ref={mountRef} className={className} />;
}

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { testnetCollection } from "./testnet-collection.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ASSETS_ROOT = path.resolve(
  __dirname,
  "../assets/season-1",
);

const errors: string[] = [];
const assetKeys = new Set<string>();
const ids = new Set<number>();

let pngCount = 0;
let glbCount = 0;

function normalize(value: string): string {
  return value.toLowerCase();
}

console.log("=== Testnet asset validation ===\n");

if (testnetCollection.length !== 20) {
  errors.push(
    `Expected 20 collectibles, found ${testnetCollection.length}.`,
  );
}

for (const collectible of testnetCollection) {
  const {
    id,
    side,
    material,
    piece,
    edition,
    maxSupply,
  } = collectible;

  if (ids.has(id)) {
    errors.push(`Duplicate collectible id: ${id}`);
  }

  ids.add(id);

  if (edition < 1) {
    errors.push(
      `Collectible ${id}: invalid edition ${edition}.`,
    );
  }

  if (maxSupply < 1) {
    errors.push(
      `Collectible ${id}: invalid maxSupply ${maxSupply}.`,
    );
  }

  if (edition > maxSupply) {
    errors.push(
      `Collectible ${id}: edition ${edition} exceeds maxSupply ${maxSupply}.`,
    );
  }

  const relativeDirectory = path.join(
    normalize(material),
    normalize(side),
    normalize(piece),
  );

  const assetKey = path.join(
    relativeDirectory,
    String(edition),
  );

  if (assetKeys.has(assetKey)) {
    errors.push(
      `Duplicate asset entry: ${assetKey}`,
    );
  }

  assetKeys.add(assetKey);

  const pngPath = path.join(
    ASSETS_ROOT,
    relativeDirectory,
    `${edition}.png`,
  );

  const glbPath = path.join(
    ASSETS_ROOT,
    relativeDirectory,
    `${edition}.glb`,
  );

  const pngExists = fs.existsSync(pngPath);
  const glbExists = fs.existsSync(glbPath);

  if (pngExists) {
    pngCount++;
  } else {
    errors.push(
      `Missing PNG: ${path.relative(ASSETS_ROOT, pngPath)}`,
    );
  }

  if (glbExists) {
    glbCount++;
  } else {
    errors.push(
      `Missing GLB: ${path.relative(ASSETS_ROOT, glbPath)}`,
    );
  }

  if (pngExists && fs.statSync(pngPath).size === 0) {
    errors.push(
      `Empty PNG: ${path.relative(ASSETS_ROOT, pngPath)}`,
    );
  }

  if (glbExists && fs.statSync(glbPath).size === 0) {
    errors.push(
      `Empty GLB: ${path.relative(ASSETS_ROOT, glbPath)}`,
    );
  }
}

console.log(`Testnet collectibles : ${testnetCollection.length}`);
console.log(`Expected PNG files   : ${testnetCollection.length}`);
console.log(`Expected GLB files   : ${testnetCollection.length}`);
console.log(`PNG found            : ${pngCount}`);
console.log(`GLB found            : ${glbCount}`);
console.log(`Assets found         : ${pngCount + glbCount}`);

if (errors.length > 0) {
  console.error("\nValidation failed:\n");

  for (const error of errors) {
    console.error(`- ${error}`);
  }

  process.exit(1);
}

console.log("\n✅ Testnet asset collection is valid.");
console.log("✅ 20 collectibles");
console.log("✅ 20 PNG");
console.log("✅ 20 GLB");
console.log("✅ 40 required asset files");

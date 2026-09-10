import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  materials,
  pieces,
  SEASON,
  sides,
} from "./season1.js";

import {
  assetSpec,
} from "./asset-spec.js";

const __filename =
  fileURLToPath(import.meta.url);

const __dirname =
  path.dirname(__filename);

const ASSETS_DIR = path.resolve(
  __dirname,
  "../assets",
  `season-${SEASON}`,
);

function slug(value: string): string {
  return value
    .toLowerCase()
    .replaceAll(" ", "-");
}

async function exists(
  filePath: string,
): Promise<boolean> {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function main() {
  let expectedAssets = 0;
  let existingAssets = 0;

  const missing: string[] = [];

  for (const material of materials) {
    for (
      let pieceIndex = 0;
      pieceIndex < pieces.length;
      pieceIndex++
    ) {
      const piece =
        pieces[pieceIndex];

      const maxSupply =
        material.supplies[pieceIndex];

      for (const side of sides) {
        for (
          let edition = 1;
          edition <= maxSupply;
          edition++
        ) {
          const directory = path.join(
            ASSETS_DIR,
            slug(material.name),
            slug(side),
            slug(piece.type),
          );

          const imagePath = path.join(
            directory,
            `${edition}${assetSpec.image.extension}`,
          );

          const modelPath = path.join(
            directory,
            `${edition}${assetSpec.model.extension}`,
          );

          expectedAssets += 2;

          if (await exists(imagePath)) {
            existingAssets++;
          } else {
            missing.push(imagePath);
          }

          if (await exists(modelPath)) {
            existingAssets++;
          } else {
            missing.push(modelPath);
          }
        }
      }
    }
  }

  console.log(
    `Season: ${SEASON}`,
  );

  console.log(
    "Collectibles: 3960",
  );

  console.log(
    `Expected asset files: ${expectedAssets}`,
  );

  console.log(
    `Existing asset files: ${existingAssets}`,
  );

  console.log(
    `Missing asset files: ${missing.length}`,
  );

  if (missing.length > 0) {
  console.log(
    "\nFirst missing assets:",
  );

  for (
    const file of missing.slice(0, 20)
  ) {
    console.log(
      `- ${path.relative(
        ASSETS_DIR,
        file,
      )}`,
    );
  }

  console.log(
    "\nAsset collection is still incomplete.",
  );

  return;
}

  console.log(
    "\nAll Season 1 assets are present.",
  );
}

main().catch((error) => {
  console.error(
    "Asset validation failed:",
  );

  console.error(error);

  process.exit(1);
});
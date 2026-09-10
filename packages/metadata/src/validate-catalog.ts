import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  materials,
  pieces,
  SEASON,
  sides,
} from "./season1.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SOLIDITY_CATALOG = path.resolve(
  __dirname,
  "../../contracts/src/catalog/Season1Catalog.sol",
);

type SolidityMaterial = {
  name: string;
  supplies: number[];
};

async function main() {
  const source = await fs.readFile(
    SOLIDITY_CATALOG,
    "utf8",
  );

  // -------------------------------------------------
  // Validate season
  // -------------------------------------------------

  const seasonMatch = source.match(
    /uint16\s+internal\s+constant\s+SEASON\s*=\s*(\d+)/,
  );

  if (!seasonMatch) {
    throw new Error(
      "Could not find SEASON in Season1Catalog.sol",
    );
  }

  const soliditySeason =
    Number(seasonMatch[1]);

  if (soliditySeason !== SEASON) {
    throw new Error(
      `Season mismatch: Solidity=${soliditySeason}, TypeScript=${SEASON}`,
    );
  }

  // -------------------------------------------------
  // Validate materials + supplies
  // -------------------------------------------------

  const materialRegex =
    /_addMaterial\(\s*configs,\s*index,\s*ChessTypes\.Material\.(\w+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\)/g;

  const solidityMaterials: SolidityMaterial[] =
    [];

  for (
    const match of source.matchAll(materialRegex)
  ) {
    solidityMaterials.push({
      name: match[1],
      supplies: [
        Number(match[2]),
        Number(match[3]),
        Number(match[4]),
        Number(match[5]),
        Number(match[6]),
        Number(match[7]),
      ],
    });
  }

  if (
    solidityMaterials.length !==
    materials.length
  ) {
    throw new Error(
      `Material count mismatch: Solidity=${solidityMaterials.length}, TypeScript=${materials.length}`,
    );
  }

  for (
    let i = 0;
    i < materials.length;
    i++
  ) {
    const solidityMaterial =
      solidityMaterials[i];

    const tsMaterial =
      materials[i];

    if (
      solidityMaterial.name !==
      tsMaterial.name
    ) {
      throw new Error(
        `Material mismatch at index ${i}: Solidity=${solidityMaterial.name}, TypeScript=${tsMaterial.name}`,
      );
    }

    for (
      let pieceIndex = 0;
      pieceIndex < pieces.length;
      pieceIndex++
    ) {
      const soliditySupply =
        solidityMaterial.supplies[
          pieceIndex
        ];

      const tsSupply =
        tsMaterial.supplies[
          pieceIndex
        ];

      if (
        soliditySupply !== tsSupply
      ) {
        throw new Error(
          `${tsMaterial.name} ${pieces[pieceIndex].type} supply mismatch: Solidity=${soliditySupply}, TypeScript=${tsSupply}`,
        );
      }
    }
  }

  // -------------------------------------------------
  // Validate piece rarities
  // -------------------------------------------------

  const pairRegex =
    /ChessTypes\.PieceType\.(\w+),\s*material,\s*ChessTypes\.Rarity\.(\w+)/g;

  const solidityPieces =
    Array.from(
      source.matchAll(pairRegex),
      (match) => ({
        type: match[1],
        rarity: match[2],
      }),
    );

  if (
    solidityPieces.length !==
    pieces.length
  ) {
    throw new Error(
      `Piece count mismatch: Solidity=${solidityPieces.length}, TypeScript=${pieces.length}`,
    );
  }

  for (
    let i = 0;
    i < pieces.length;
    i++
  ) {
    if (
      solidityPieces[i].type !==
      pieces[i].type
    ) {
      throw new Error(
        `Piece mismatch: Solidity=${solidityPieces[i].type}, TypeScript=${pieces[i].type}`,
      );
    }

    if (
      solidityPieces[i].rarity !==
      pieces[i].rarity
    ) {
      throw new Error(
        `${pieces[i].type} rarity mismatch: Solidity=${solidityPieces[i].rarity}, TypeScript=${pieces[i].rarity}`,
      );
    }
  }

  // -------------------------------------------------
  // Global totals
  // -------------------------------------------------

  const seriesCount =
    materials.length *
    pieces.length *
    sides.length;

  const totalSupply =
    materials.reduce(
      (materialTotal, material) =>
        materialTotal +
        material.supplies.reduce(
          (sum, supply) =>
            sum + supply,
          0,
        ) *
          sides.length,
      0,
    );

  if (seriesCount !== 60) {
    throw new Error(
      `Expected 60 series, got ${seriesCount}`,
    );
  }

  if (totalSupply !== 3960) {
    throw new Error(
      `Expected total supply 3960, got ${totalSupply}`,
    );
  }

  console.log(
    "Season 1 catalog validation passed.",
  );

  console.log(
    `Season: ${SEASON}`,
  );

  console.log(
    `Materials: ${materials.length}`,
  );

  console.log(
    `Pieces: ${pieces.length}`,
  );

  console.log(
    `Sides: ${sides.length}`,
  );

  console.log(
    `Series: ${seriesCount}`,
  );

  console.log(
    `Maximum collectibles: ${totalSupply}`,
  );
}

main().catch((error) => {
  console.error(
    "Catalog validation failed:",
  );

  console.error(error);

  process.exit(1);
});
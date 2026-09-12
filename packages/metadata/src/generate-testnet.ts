import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { testnetCollection } from "./testnet-collection.js";
import {
  materials,
  pieces,
  SEASON,
  sides,
} from "./season1.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const OUTPUT_DIR = path.resolve(
  __dirname,
  "../generated/testnet/season-1",
);

const ASSET_BASE_URI =
  process.env.ASSET_BASE_URI ??
  "ipfs://REPLACE_WITH_ASSET_CID";

const PUBLIC_APP_URL =
  process.env.PUBLIC_APP_URL ??
  "http://localhost:3000";

function slug(value: string): string {
  return value
    .toLowerCase()
    .replaceAll(" ", "-");
}

function validateAgainstOfficialCatalog(
  collectible: (typeof testnetCollection)[number],
) {
  const material = materials.find(
    (candidate) =>
      candidate.name === collectible.material,
  );

  if (!material) {
    throw new Error(
      `Unknown material for collectible ${collectible.id}: ` +
      collectible.material,
    );
  }

  const pieceIndex = pieces.findIndex(
    (candidate) =>
      candidate.type === collectible.piece,
  );

  if (pieceIndex === -1) {
    throw new Error(
      `Unknown piece for collectible ${collectible.id}: ` +
      collectible.piece,
    );
  }

  const officialPiece = pieces[pieceIndex];
  const officialMaxSupply =
    material.supplies[pieceIndex];

  if (
    officialPiece.rarity !==
    collectible.rarity
  ) {
    throw new Error(
      `Rarity mismatch for collectible ${collectible.id}: ` +
      `manifest=${collectible.rarity}, ` +
      `catalog=${officialPiece.rarity}`,
    );
  }

  if (
    officialMaxSupply !==
    collectible.maxSupply
  ) {
    throw new Error(
      `Max supply mismatch for collectible ${collectible.id}: ` +
      `manifest=${collectible.maxSupply}, ` +
      `catalog=${officialMaxSupply}`,
    );
  }

  if (
    !sides.some(
      (side) => side === collectible.side,
    )
  ) {
    throw new Error(
      `Invalid side for collectible ${collectible.id}: ` +
      collectible.side,
    );
  }
}

async function main() {
  console.log(
    "=== Generate testnet metadata ===\n",
  );

  await fs.rm(
    OUTPUT_DIR,
    {
      recursive: true,
      force: true,
    },
  );

  let generated = 0;

  for (
    const collectible of testnetCollection
  ) {
    validateAgainstOfficialCatalog(
      collectible,
    );

    const {
      id,
      side,
      material,
      piece,
      rarity,
      edition,
      maxSupply,
    } = collectible;

    const materialSlug = slug(material);
    const sideSlug = slug(side);
    const pieceSlug = slug(piece);

    const directory = path.join(
      OUTPUT_DIR,
      materialSlug,
      sideSlug,
      pieceSlug,
    );

    await fs.mkdir(
      directory,
      {
        recursive: true,
      },
    );

    const assetPath =
      `${materialSlug}/` +
      `${sideSlug}/` +
      `${pieceSlug}/` +
      `${edition}`;

    const metadata = {
      name:
        `${side} ` +
        `${material} ` +
        `${piece} ` +
        `#${edition}/${maxSupply}`,

      description:
        `${side} ` +
        `${material} ` +
        `${piece} collectible ` +
        `from Web3 Chess Season ${SEASON}.`,

      image:
        `${ASSET_BASE_URI}/` +
        `${assetPath}.png`,

      animation_url:
        `${ASSET_BASE_URI}/` +
        `${assetPath}.glb`,

      attributes: [
        {
          trait_type: "Piece",
          value: piece,
        },
        {
          trait_type: "Side",
          value: side,
        },
        {
          trait_type: "Material",
          value: material,
        },
        {
          trait_type: "Rarity",
          value: rarity,
        },
        {
          trait_type: "Season",
          value: SEASON,
        },
        {
          trait_type: "Edition",
          value: edition,
        },
        {
          trait_type: "Max Supply",
          value: maxSupply,
        },
        {
          trait_type: "Edition Mark",
          value: `${edition}/${maxSupply}`,
        },
      ],
    };

    await fs.writeFile(
      path.join(
        directory,
        `${edition}.json`,
      ),
      JSON.stringify(
        metadata,
        null,
        2,
      ) + "\n",
      "utf8",
    );

    generated++;

    console.log(
      `✓ ${String(id).padStart(2, "0")} ` +
      `${metadata.name}`,
    );
  }

  if (
    generated !==
    testnetCollection.length
  ) {
    throw new Error(
      `Expected ${testnetCollection.length} metadata files, ` +
      `generated ${generated}.`,
    );
  }

  console.log("");
  console.log(
    `✅ Generated ${generated} testnet metadata files.`,
  );

  console.log(
    `📁 ${OUTPUT_DIR}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

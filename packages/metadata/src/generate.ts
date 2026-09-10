import fs from "node:fs/promises";
import path from "node:path";

import {
  materials,
  pieces,
  SEASON,
  sides,
} from "./season1.js";

const OUTPUT_DIR = path.resolve(
  "packages/metadata/generated/season-1",
);

const ASSET_BASE_URI =
  process.env.ASSET_BASE_URI ??
  "ipfs://REPLACE_WITH_ASSET_CID";

const PUBLIC_APP_URL =
  process.env.PUBLIC_APP_URL ??
  "http://localhost:3000";

function slug(value: string): string {
  return value.toLowerCase().replaceAll(" ", "-");
}

async function main() {
  await fs.rm(OUTPUT_DIR, {
    recursive: true,
    force: true,
  });

  let generated = 0;

  for (const material of materials) {
    for (
      let pieceIndex = 0;
      pieceIndex < pieces.length;
      pieceIndex++
    ) {
      const piece = pieces[pieceIndex];
      const maxSupply =
        material.supplies[pieceIndex];

      for (const side of sides) {
        for (
          let edition = 1;
          edition <= maxSupply;
          edition++
        ) {
          const materialSlug =
            slug(material.name);

          const pieceSlug =
            slug(piece.type);

          const sideSlug =
            slug(side);

          const directory = path.join(
            OUTPUT_DIR,
            materialSlug,
            sideSlug,
            pieceSlug,
          );

          await fs.mkdir(directory, {
            recursive: true,
          });

          const assetPath =
            `season-1/${materialSlug}/${sideSlug}/${pieceSlug}/${edition}`;

          const metadata = {
            name:
              `${side} ${material.name} ${piece.type} ` +
              `#${edition}/${maxSupply}`,

            description:
              `${side} ${material.name} ${piece.type} ` +
              `collectible from Web3 Chess Season ${SEASON}.`,

            image:
              `${ASSET_BASE_URI}/${assetPath}.png`,

            animation_url:
              `${ASSET_BASE_URI}/${assetPath}.glb`,

            external_url:
              `${PUBLIC_APP_URL}/collectibles/season-1/` +
              `${materialSlug}/${sideSlug}/${pieceSlug}/${edition}`,

            attributes: [
              {
                trait_type: "Piece",
                value: piece.type,
              },
              {
                trait_type: "Side",
                value: side,
              },
              {
                trait_type: "Material",
                value: material.name,
              },
              {
                trait_type: "Rarity",
                value: piece.rarity,
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
        }
      }
    }
  }

  console.log(
    `Generated ${generated} metadata files.`,
  );

  if (generated !== 3960) {
    throw new Error(
      `Expected 3960 files, got ${generated}`,
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
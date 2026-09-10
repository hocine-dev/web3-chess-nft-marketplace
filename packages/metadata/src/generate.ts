import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  getEditionTraits,
} from "./edition-traits.js";

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
  "../generated/season-1",
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

async function main() {
  /*
   * Remove the previous generated metadata
   * so every generation starts clean.
   */
  await fs.rm(
    OUTPUT_DIR,
    {
      recursive: true,
      force: true,
    },
  );

  let generated = 0;

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
          const materialSlug =
            slug(material.name);

          const pieceSlug =
            slug(piece.type);

          const sideSlug =
            slug(side);

          /*
           * Example:
           *
           * generated/
           * season-1/
           * platinum/
           * white/
           * queen/
           */
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

          /*
           * Example:
           *
           * season-1/platinum/white/queen/2
           */
          const assetPath =
            `season-${SEASON}/` +
            `${materialSlug}/` +
            `${sideSlug}/` +
            `${pieceSlug}/` +
            `${edition}`;

          /*
           * Deterministic visual traits.
           *
           * The same collectible always receives
           * the same traits when regenerated.
           */
          const editionTraits =
            getEditionTraits({
              season: SEASON,
              side,
              material: material.name,
              piece: piece.type,
              rarity: piece.rarity,
              edition,
              maxSupply,
            });

          const metadata = {
            name:
              `${side} ` +
              `${material.name} ` +
              `${piece.type} ` +
              `#${edition}/${maxSupply}`,

            description:
              `${side} ` +
              `${material.name} ` +
              `${piece.type} collectible ` +
              `from Web3 Chess Season ${SEASON}.`,

            /*
             * Temporary IPFS paths.
             *
             * The real CID will be supplied later
             * when the final assets are ready.
             */
            image:
              `${ASSET_BASE_URI}/` +
              `${assetPath}.png`,

            animation_url:
              `${ASSET_BASE_URI}/` +
              `${assetPath}.glb`,

            external_url:
              `${PUBLIC_APP_URL}/` +
              `collectibles/` +
              `season-${SEASON}/` +
              `${materialSlug}/` +
              `${sideSlug}/` +
              `${pieceSlug}/` +
              `${edition}`,

            attributes: [
              /*
               * Core collectible identity.
               */
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

              /*
               * Edition information.
               */
              {
                trait_type: "Edition",
                value: edition,
              },
              {
                trait_type: "Max Supply",
                value: maxSupply,
              },

              /*
               * Visual edition traits.
               */
              {
                trait_type: "Engraving",
                value:
                  editionTraits.engraving,
              },
              {
                trait_type: "Gem",
                value:
                  editionTraits.gem,
              },
              {
                trait_type: "Finish",
                value:
                  editionTraits.finish,
              },
              {
                trait_type: "Base Style",
                value:
                  editionTraits.baseStyle,
              },
              {
                trait_type: "Aura",
                value:
                  editionTraits.aura,
              },
              {
                trait_type: "Edition Mark",
                value:
                  editionTraits.editionMark,
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

  /*
   * Safety check.
   *
   * Season 1 must always generate exactly
   * 3960 collectible metadata files.
   */
  if (generated !== 3960) {
    throw new Error(
      `Expected 3960 files, got ${generated}`,
    );
  }
}

main().catch((error) => {
  console.error(
    "Metadata generation failed:",
  );

  console.error(error);

  process.exit(1);
});
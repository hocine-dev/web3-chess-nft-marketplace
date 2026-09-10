import { createHash } from "node:crypto";

type Rarity =
  | "Common"
  | "Rare"
  | "VeryRare"
  | "Mythic";

type Material =
  | "Bronze"
  | "Silver"
  | "Gold"
  | "Platinum"
  | "Diamond";

export type EditionTraits = {
  engraving: string;
  gem: string;
  finish: string;
  baseStyle: string;
  aura: string;
  editionMark: string;
};

const engravings = [
  "None",
  "Geometric",
  "Royal Lines",
  "Crown",
  "Runes",
] as const;

const baseStyles = [
  "Classic",
  "Modern",
  "Imperial",
] as const;

const auras = [
  "None",
  "Soft Glow",
  "Pulse",
  "Particles",
] as const;

const gemsByMaterial: Record<
  Material,
  readonly string[]
> = {
  Bronze: [
    "None",
    "Ruby",
    "Emerald",
  ],

  Silver: [
    "None",
    "Sapphire",
    "Emerald",
  ],

  Gold: [
    "None",
    "Ruby",
    "Emerald",
    "Sapphire",
  ],

  Platinum: [
    "None",
    "Sapphire",
    "Emerald",
    "Diamond",
  ],

  Diamond: [
    "None",
    "Ruby",
    "Emerald",
    "Sapphire",
  ],
};

const premiumGemsByMaterial: Record<
  Material,
  readonly string[]
> = {
  Bronze: [
    "Ruby",
    "Emerald",
  ],

  Silver: [
    "Sapphire",
    "Emerald",
  ],

  Gold: [
    "Ruby",
    "Emerald",
    "Sapphire",
  ],

  Platinum: [
    "Sapphire",
    "Emerald",
    "Diamond",
  ],

  Diamond: [
    "Ruby",
    "Emerald",
    "Sapphire",
  ],
};

const finishesByMaterial: Record<
  Material,
  readonly string[]
> = {
  Bronze: [
    "Matte",
    "Brushed",
    "Patinated",
    "Polished",
  ],

  Silver: [
    "Brushed",
    "Polished",
    "Mirror",
    "Frosted",
  ],

  Gold: [
    "Polished",
    "Mirror",
    "Brushed",
    "Satin",
  ],

  Platinum: [
    "Polished",
    "Mirror",
    "Satin",
    "Brushed",
  ],

  Diamond: [
    "Faceted",
    "Prismatic",
    "Crystal",
    "Polished",
  ],
};

function seedNumber(seed: string): number {
  const hash = createHash("sha256")
    .update(seed)
    .digest("hex");

  return Number.parseInt(
    hash.slice(0, 8),
    16,
  );
}

function pick<T>(
  values: readonly T[],
  seed: string,
): T {
  return values[
    seedNumber(seed) % values.length
  ];
}

export function getEditionTraits(params: {
  season: number;
  side: string;
  material: Material;
  piece: string;
  rarity: Rarity;
  edition: number;
  maxSupply: number;
}): EditionTraits {
  const {
    season,
    side,
    material,
    piece,
    rarity,
    edition,
    maxSupply,
  } = params;

  const baseSeed =
    `${season}:${side}:${material}:` +
    `${piece}:${edition}`;

  let gem = pick(
    gemsByMaterial[material],
    `${baseSeed}:gem`,
  );

  let aura = pick(
    auras,
    `${baseSeed}:aura`,
  );

  let engraving = pick(
    engravings,
    `${baseSeed}:engraving`,
  );

  /*
   * Common collectibles remain simple.
   * Most Common editions have no gem,
   * aura or engraving.
   */
  if (rarity === "Common") {
    aura = "None";

    if (
      seedNumber(
        `${baseSeed}:common-gem`,
      ) %
        5 !==
      0
    ) {
      gem = "None";
    }

    if (
      seedNumber(
        `${baseSeed}:common-engraving`,
      ) %
        3 !==
      0
    ) {
      engraving = "None";
    }
  }

  /*
   * Rare collectibles can receive gems
   * and engravings, but aura remains
   * relatively uncommon.
   */
  if (rarity === "Rare") {
    if (
      seedNumber(
        `${baseSeed}:rare-aura`,
      ) %
        2 ===
      0
    ) {
      aura = "None";
    }
  }

  /*
   * Very Rare collectibles must have
   * at least one strong visual trait.
   */
  if (rarity === "VeryRare") {
    if (
      gem === "None" &&
      aura === "None" &&
      engraving === "None"
    ) {
      gem = pick(
        premiumGemsByMaterial[material],
        `${baseSeed}:very-rare-gem`,
      );
    }
  }

  /*
   * Mythic collectibles always have:
   *
   * - a premium gem
   * - an aura
   * - an engraving
   */
  if (rarity === "Mythic") {
    if (gem === "None") {
      gem = pick(
        premiumGemsByMaterial[material],
        `${baseSeed}:mythic-gem`,
      );
    }

    if (aura === "None") {
      aura = "Soft Glow";
    }

    if (engraving === "None") {
      engraving = "Crown";
    }
  }

  const finish = pick(
    finishesByMaterial[material],
    `${baseSeed}:finish`,
  );

  return {
    engraving,

    gem,

    finish,

    baseStyle: pick(
      baseStyles,
      `${baseSeed}:base`,
    ),

    aura,

    editionMark:
      `${edition}/${maxSupply}`,
  };
}
export const SEASON = 1;

export const sides = ["White", "Black"] as const;

export const pieces = [
  {
    type: "Pawn",
    rarity: "Common",
  },
  {
    type: "Knight",
    rarity: "Rare",
  },
  {
    type: "Bishop",
    rarity: "VeryRare",
  },
  {
    type: "Rook",
    rarity: "VeryRare",
  },
  {
    type: "Queen",
    rarity: "Mythic",
  },
  {
    type: "King",
    rarity: "Mythic",
  },
] as const;

export const materials = [
  {
    name: "Bronze",
    supplies: [500, 100, 25, 25, 5, 5],
  },
  {
    name: "Silver",
    supplies: [400, 80, 20, 20, 4, 4],
  },
  {
    name: "Gold",
    supplies: [300, 60, 15, 15, 3, 3],
  },
  {
    name: "Platinum",
    supplies: [200, 40, 10, 10, 2, 2],
  },
  {
    name: "Diamond",
    supplies: [100, 20, 5, 5, 1, 1],
  },
] as const;
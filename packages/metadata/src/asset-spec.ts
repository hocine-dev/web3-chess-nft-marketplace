export const assetSpec = {
  season: 1,

  image: {
    extension: ".png",
    width: 2048,
    height: 2048,
  },

  model: {
    extension: ".glb",
  },

  requiredFilesPerEdition: [
    "image",
    "model",
  ],
} as const;
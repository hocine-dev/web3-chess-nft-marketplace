import Fastify from "fastify";
import cors from "@fastify/cors";

const app = Fastify({
  logger: true,
});

await app.register(cors, {
  origin: true,
});

app.get("/live", async () => ({
  status: "ok",
  service: "web3-chess-api",
}));

app.get("/ready", async () => ({
  status: "ready",
  service: "web3-chess-api",
}));

const port = Number(process.env.PORT ?? 3001);

await app.listen({
  port,
  host: "0.0.0.0",
});
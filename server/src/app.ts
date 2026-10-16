import { Hono } from "hono";
import { healthRoutes } from "./modules/health/routes";

const app = new Hono();

app.route("/health", healthRoutes);

export default app;

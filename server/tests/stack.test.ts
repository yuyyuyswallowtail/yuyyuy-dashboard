import { expect, test } from "bun:test";
import { Client } from "pg";
import { z } from "zod";
import { env } from "../src/config/env";

test("zod 4 parses a valid and an invalid object", () => {
  const schema = z.object({ email: z.email(), age: z.number().int() });
  expect(schema.safeParse({ email: "a@b.co", age: 20 }).success).toBe(true);
  expect(schema.safeParse({ email: "nope", age: 1.5 }).success).toBe(false);
});

test("database answers SELECT 1", async () => {
  const client = new Client({ connectionString: env.DATABASE_URL });
  await client.connect();
  const res = await client.query("SELECT 1 AS ok");
  await client.end();
  expect(res.rows[0].ok).toBe(1);
});

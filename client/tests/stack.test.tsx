import { expect, test } from "bun:test";
import { render, screen } from "@testing-library/react";
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import { z } from "zod";

test("happy-dom is registered", () => {
  expect(typeof document).toBe("object");
});

test("zod 4, clsx, tailwind-merge", () => {
  expect(z.email().safeParse("a@b.co").success).toBe(true);
  expect(z.email().safeParse("nope").success).toBe(false);
  expect(clsx("a", false, "b")).toBe("a b");
  expect(twMerge("p-2 p-4")).toBe("p-4");
});

test("renders a component", () => {
  render(<p>Hello</p>);
  expect(screen.getByText("Hello")).toBeTruthy();
});

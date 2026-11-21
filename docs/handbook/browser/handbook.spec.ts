import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const pages = ["guides", "reference", "internals"].flatMap((section) =>
  readdirSync(resolve(section)).filter((name) => name.endsWith(".md")).map((name) => {
    const source = readFileSync(resolve(section, name), "utf8");
    return {
      route: name === "introduction.md" ? "" : `${section}/${name.slice(0, -3)}`,
      title: source.match(/^# (.+)$/m)![1]!,
    };
  }),
);

for (const entry of pages) {
  test(`${entry.route || "home"}: navigation, layout and accessibility`, async ({ page }, info) => {
    const errors: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    const response = await page.goto(entry.route);
    expect(response?.status()).toBe(200);
    await expect(page.locator("h1")).toHaveText(entry.title);
    await expect(page.locator("html")).toHaveAttribute("data-theme", info.project.name.endsWith("dark") ? "dark" : "light");
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1)).toBe(true);
    const accessibility = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa"]).analyze();
    expect(accessibility.violations).toEqual([]);
    expect(errors).toEqual([]);
    if (entry.route === "reference/cli") {
      await page.screenshot({ path: info.outputPath("cli.png"), fullPage: true });
      await info.attach("CLI screenshot", { path: info.outputPath("cli.png"), contentType: "image/png" });
    }
  });
}

test("keyboard, responsive menu and theme controls", async ({ page }, info) => {
  await page.goto("");
  await page.keyboard.press("Tab");
  await expect(page.getByRole("link", { name: "Skip to main content" })).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.locator("main")).toBeVisible();
  if (info.project.name.startsWith("mobile")) {
    await page.getByRole("button", { name: "Toggle navigation bar" }).click();
    await page.locator(".navbar-sidebar").getByRole("link", { name: "CLI", exact: true }).click();
  } else {
    await page.locator(".navbar").getByRole("link", { name: "CLI", exact: true }).click();
    const theme = page.getByRole("button", { name: /Switch between dark and light mode/ });
    // Docusaurus cycles system/light/dark; system may match the next choice.
    const nextTheme = info.project.name.endsWith("dark") ? "light" : "dark";
    await theme.click();
    if (await page.locator("html").getAttribute("data-theme") !== nextTheme) await theme.click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", nextTheme);
  }
  await expect(page.locator("h1")).toHaveText("CLI reference");
  await expect(page).toHaveURL(/\/reference\/cli$/);
});

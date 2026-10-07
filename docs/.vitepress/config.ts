import { defineConfig } from "vitepress";

// Situs resi-shell (GitHub Pages). Sumber halaman: docs/**/*.md. Jalankan lokal: cd docs && npm install && npm run dev
const repo = "https://github.com/suryakencana007/dotconfigfiles";
// Domain kustom GitHub Pages (Settings > Pages > Custom domain): situs disajikan dari akar domain, jadi base "/".
// Kalau domain kustom dilepas, situs kembali ke suryakencana007.github.io/dotconfigfiles/ dan base harus "/dotconfigfiles/".
const site = "https://resi-arch.kubus.work/";

export default defineConfig({
  title: "Resi Arch",
  description: "A complete Arch Linux desktop that installs itself: Hyprland, Noctalia, rofi and a modern terminal",
  base: "/",
  cleanUrls: true,
  lastUpdated: true,
  srcExclude: ["README.md"],

  head: [
    ["link", { rel: "icon", href: "/logo-mark.png", type: "image/png" }],
    ["meta", { name: "theme-color", content: "#0b0b0f" }],
    ["meta", { property: "og:title", content: "Resi Arch | Arch Linux desktop that installs itself" }],
    ["meta", { property: "og:description", content: "Hyprland + Noctalia + rofi + a modern terminal, themed from your wallpaper. Offline installer ISO or one script." }],
    ["meta", { property: "og:type", content: "website" }],
    ["meta", { property: "og:url", content: site }],
    ["meta", { property: "og:image", content: site + "boot-splash.png" }],
  ],

  themeConfig: {
    logo: "/logo-mark.png",
    siteTitle: "Resi Arch",

    nav: [
      { text: "Guide", link: "/guide/", activeMatch: "/guide/" },
      { text: "Reference", link: "/reference/resi-shell", activeMatch: "/reference/" },
      { text: "Design notes", link: `${repo}/blob/main/NOTES.md` },
    ],

    sidebar: {
      "/guide/": [
        {
          text: "Getting started",
          items: [
            { text: "What is resi-shell?", link: "/guide/" },
            { text: "Install from the ISO", link: "/guide/install-iso" },
            { text: "Install with the script", link: "/guide/install-script" },
            { text: "First steps", link: "/guide/first-steps" },
          ],
        },
        {
          text: "Using the desktop",
          items: [
            { text: "Everyday keys", link: "/guide/keys" },
            { text: "The menu", link: "/guide/menu" },
            { text: "Features", link: "/guide/features" },
            { text: "Laptops", link: "/guide/laptops" },
            { text: "Development tools", link: "/guide/development" },
          ],
        },
        {
          text: "Keeping it running",
          items: [
            { text: "Updating", link: "/guide/updating" },
            { text: "Several machines", link: "/guide/machines" },
            { text: "Boot splash", link: "/guide/boot-splash" },
            { text: "Troubleshooting", link: "/guide/troubleshooting" },
          ],
        },
      ],
      "/reference/": [
        {
          text: "Reference",
          items: [
            { text: "The resi-shell command", link: "/reference/resi-shell" },
            { text: "Helper scripts", link: "/reference/helpers" },
            { text: "Repository layout", link: "/reference/repo-layout" },
            { text: "Installer ISO internals", link: "/reference/iso" },
          ],
        },
      ],
    },

    socialLinks: [{ icon: "github", link: repo }],
    search: { provider: "local" },
    outline: [2, 3],
    editLink: { pattern: `${repo}/edit/main/docs/:path`, text: "Edit this page on GitHub" },
    footer: {
      message: "Released under the MIT License. Built on Hyprland and Noctalia.",
      copyright: "Copyright © Surya Kencana",
    },
  },
});

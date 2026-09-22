-- TEMPLATE Noctalia. File ini dirender Noctalia menjadi lua/noctalia.lua setiap tema berubah.
-- Jangan edit noctalia.lua (hasil render), edit file ini. Peta warna: Material 3 -> base16.
local M = {}

function M.setup()
  vim.o.termguicolors = true
  require("base16-colorscheme").setup({
    -- latar
    base00 = "{{colors.surface.default.hex}}",                 -- background
    base01 = "{{colors.surface_container.default.hex}}",       -- status bar
    base02 = "{{colors.surface_container_high.default.hex}}",  -- selection
    base03 = "{{colors.outline.default.hex}}",                 -- komentar
    -- teks
    base04 = "{{colors.on_surface_variant.default.hex}}",
    base05 = "{{colors.on_surface.default.hex}}",              -- teks utama
    base06 = "{{colors.on_surface.default.hex}}",
    base07 = "{{colors.on_background.default.hex}}",
    -- aksen
    base08 = "{{colors.error.default.hex}}",                   -- variabel, error
    base09 = "{{colors.tertiary.default.hex}}",                -- angka, konstanta
    base0A = "{{colors.secondary.default.hex}}",               -- class, search
    base0B = "{{colors.primary.default.hex}}",                 -- string, diff tambah
    base0C = "{{colors.tertiary_fixed_dim.default.hex}}",      -- regex, escape
    base0D = "{{colors.primary_fixed_dim.default.hex}}",       -- fungsi
    base0E = "{{colors.secondary_fixed_dim.default.hex}}",     -- keyword
    base0F = "{{colors.error_container.default.hex}}",         -- deprecated
  })
  vim.g.colors_name = "noctalia"
end

return M

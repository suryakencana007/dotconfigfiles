-- Tema default: ikut Noctalia lewat base16-nvim.
-- Warna dirender Noctalia ke lua/noctalia.lua dari template lua/noctalia-template.lua
-- (lihat ~/.config/noctalia/nvim.toml). Versi monokai-pro ada di theme.lua.monokai.bak.
return {
	{
		"RRethy/base16-nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local function apply()
				package.loaded["noctalia"] = nil
				local ok, theme = pcall(require, "noctalia")
				if not ok then
					vim.notify("noctalia.lua belum dirender, jalankan: noctalia msg config-reload", vim.log.levels.WARN)
					return
				end
				theme.setup()
				-- terapkan lagi transparansi (plugin/after/transparency.lua) karena setup menulis ulang highlight
				pcall(dofile, vim.fn.stdpath("config") .. "/plugin/after/transparency.lua")
			end

			apply()

			-- Noctalia mengirim SIGUSR1 setiap tema berubah -> ganti warna tanpa restart
			local signal = vim.uv.new_signal()
			signal:start("sigusr1", vim.schedule_wrap(apply))
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = function()
				package.loaded["noctalia"] = nil
				local ok, theme = pcall(require, "noctalia")
				if ok then theme.setup() end
			end,
		},
	},
}

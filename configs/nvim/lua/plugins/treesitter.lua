vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter" } })

local TS = require("nvim-treesitter")

-- On Windows, `tree-sitter build` (invoked by nvim-treesitter's *main*
-- branch, which no longer compiles parsers itself) defaults to cl.exe
-- (MSVC), which isn't usable outside a VS Developer shell -> "program not
-- found". Point it at gcc instead (installed via `scoop install gcc`),
-- which works from a plain terminal — no wrapper script needed here, unlike
-- the zig cc setup this replaced, since gcc is a single-word command.
if vim.fn.has("win32") == 1 then
	vim.env.CC = "gcc"
	vim.env.CXX = "g++"
end

local ensure_installed = {
	"astro",
	-- "bash",
	"c",
	"cmake",
	"cpp",
	"css",
	"diff",
	"fish",
	"gitignore",
	"go",
	"graphql",
	"html",
	"http",
	"java",
	"javascript",
	"jsdoc",
	"json",
	"lua",
	"luadoc",
	"luap",
	"make",
	"markdown",
	"markdown_inline",
	"php",
	"printf",
	"python",
	"query",
	"regex",
	"rust",
	"scss",
	"sql",
	"svelte",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"xml",
	"yaml",
}

TS.install(ensure_installed)

-- MDX has no parser of its own; render it with the Markdown one.
vim.filetype.add({
	extension = {
		mdx = "mdx",
	},
})
vim.treesitter.language.register("markdown", "mdx")

local treesitter_group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = treesitter_group,
	callback = function(ev)
		local lang = vim.treesitter.language.get_lang(ev.match)
		if not lang or not vim.treesitter.language.add(lang) then
			return
		end

		if not vim.treesitter.highlighter.active[ev.buf] then
			vim.treesitter.start(ev.buf, lang)
		end

		vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

local hooks = function(ev)
	local name, kind = ev.data.spec.name, ev.data.kind
	if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
		vim.cmd("TSUpdate")
	end
end
vim.api.nvim_create_autocmd("PackChanged", { callback = hooks })

-- All keymaps for this config live in this one file, including keymaps for
-- plugins configured elsewhere (lua/plugins/*.lua). This file is required
-- last (init.lua), after every plugin has been installed and set up, so it
-- can safely `require` any of them below.

local keymap = vim.keymap.set

local opts = { noremap = true, silent = true }

keymap("n", "x", '"_x', { desc = "Delete char (no yank)" })
keymap("n", "<Leader>p", '"0p', { desc = "Paste after (no yank)" })
keymap("n", "<Leader>P", '"0P', { desc = "Paste before (no yank)" })
keymap("v", "<Leader>p", '"0p', { desc = "Paste over selection (no yank)" })
keymap("n", "<Leader>c", '"_c', { desc = "Change (no yank)" })
keymap("n", "<Leader>C", '"_C', { desc = "Change to end of line (no yank)" })
keymap("v", "<Leader>c", '"_c', { desc = "Change selection (no yank)" })
keymap("v", "<Leader>C", '"_C', { desc = "Change to end of line (no yank)" })
keymap("n", "<Leader>d", '"_d', { desc = "Delete (no yank)" })
keymap("n", "<Leader>D", '"_D', { desc = "Delete to end of line (no yank)" })
keymap("v", "<Leader>d", '"_d', { desc = "Delete selection (no yank)" })
keymap("v", "<Leader>D", '"_D', { desc = "Delete to end of line (no yank)" })

keymap("n", "+", "<C-a>", { desc = "Increment number" })
keymap("n", "-", "<C-x>", { desc = "Decrement number" })

keymap("n", "dw", 'vb"_d', { desc = "Delete word backwards (no yank)" })
keymap("n", "dW", "dw", { noremap = true, silent = true, desc = "Delete word forward (vanilla dw)" })

keymap("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })

keymap("n", "<Leader>o", "o<Esc>^Da", vim.tbl_extend("force", opts, { desc = "New line below (no comment continuation)" }))
keymap("n", "<Leader>O", "O<Esc>^Da", vim.tbl_extend("force", opts, { desc = "New line above (no comment continuation)" }))

keymap("n", "<C-m>", "<C-i>", vim.tbl_extend("force", opts, { desc = "Jumplist forward" }))

keymap("n", "te", ":tabedit<CR>", { desc = "New tab" })
keymap("n", "<tab>", ":tabnext<CR>", vim.tbl_extend("force", opts, { desc = "Next tab" }))
keymap("n", "<s-tab>", ":tabprev<CR>", vim.tbl_extend("force", opts, { desc = "Previous tab" }))
keymap("n", "ss", ":split<Return>", vim.tbl_extend("force", opts, { desc = "Split window horizontally" }))
keymap("n", "sv", ":vsplit<Return>", vim.tbl_extend("force", opts, { desc = "Split window vertically" }))
keymap("n", "sh", "<C-w>h", { desc = "Move to left window" })
keymap("n", "sk", "<C-w>k", { desc = "Move to window above" })
keymap("n", "sj", "<C-w>j", { desc = "Move to window below" })
keymap("n", "sl", "<C-w>l", { desc = "Move to right window" })

-- Same window-navigation keys, throughout: identical <C-h/j/k/l> in a plain
-- editor split AND in a terminal split, regardless of how many splits exist
-- either way -- <C-w>h/j/k/l is inherently directional (Vim resolves "the
-- window to the left" from wherever you currently are), so this already
-- generalizes to any split layout on its own; nothing extra needed for that
-- part. The only real difference between the two modes: a terminal in
-- Terminal-Job mode swallows every keystroke into the shell, so it has to
-- drop to Normal mode first (<C-\><C-n>) before <C-w> means anything --
-- a plain editor window doesn't need that step. sh/sj/sk/sl above still
-- work too (unchanged, Normal-mode only) -- this is the one set that also
-- reaches terminal buffers.
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
keymap("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left window" })
keymap("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to window below" })
keymap("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to window above" })
keymap("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right window" })

-- If the buffer has no name yet (a brand-new `enew`/<C-n> buffer), plain
-- :w always fails with "E32: No file name" -- it never prompts on its own,
-- unlike what I said earlier. This prompts for a path instead of erroring.
local function save_file()
	if vim.fn.expand("%") == "" then
		vim.ui.input({ prompt = "Save as: " }, function(name)
			if name and name ~= "" then
				vim.cmd("write " .. vim.fn.fnameescape(name))
			end
		end)
	else
		vim.cmd("write")
	end
end

keymap("n", "<C-s>", save_file, vim.tbl_extend("force", opts, { desc = "Save file" }))
keymap("i", "<C-s>", function()
	vim.cmd("stopinsert")
	save_file()
end, vim.tbl_extend("force", opts, { desc = "Save file" }))

keymap("n", "<leader>q", ":q<CR>", vim.tbl_extend("force", opts, { desc = "Quit" }))
keymap("n", "<leader>wq", ":wq!<CR>", vim.tbl_extend("force", opts, { desc = "Force save and quit" }))

keymap("n", "<M-Down>", ":m .+1<CR>==", vim.tbl_extend("force", opts, { desc = "Move line down" }))
keymap("n", "<M-Up>", ":m .-2<CR>==", vim.tbl_extend("force", opts, { desc = "Move line up" }))
keymap("i", "<M-Down>", "<Esc>:m .+1<CR>==gi", vim.tbl_extend("force", opts, { desc = "Move line down" }))
keymap("i", "<M-Up>", "<Esc>:m .-2<CR>==gi", vim.tbl_extend("force", opts, { desc = "Move line up" }))
keymap("v", "<M-Down>", ":m '>+1<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "Move selection down" }))
keymap("v", "<M-Up>", ":m '<-2<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "Move selection up" }))

keymap("n", "<leader>i", function() end, { desc = "Toggle inlay hints (not implemented)" })

keymap("n", "<leader>yf", function()
	require("utils.editor").yank_relative_path_with_line()
end, { desc = "Yank relative path with line number" })

keymap("n", "<leader>yp", function()
	require("utils.editor").yank_absolute_path_with_line()
end, { desc = "Yank absolute path with line number" })

keymap("v", "<leader>cb", ":<C-u>lua require('utils.editor').copy_as_codeblock()<CR>", { desc = "Copy selection as markdown codeblock" })

keymap("n", "<leader>j", function()
	require("utils.editor").open_package_json()
end, { desc = "Open package.json in floating window" })

keymap("n", "<leader>bd", function()
	require("utils.editor").delete_hidden_buffers()
end, { desc = "Delete hidden buffers" })

-- ============================================================
-- Plugin keymaps below. Each plugin's own setup()/config lives in its own
-- file under lua/plugins/ — this is the one place all their keymaps live.
-- ============================================================

local map = function(keymaps)
	for _, keymap_entry in ipairs(keymaps) do
		local lhs = keymap_entry[1]
		local rhs = keymap_entry[2]
		local mode = keymap_entry.mode or "n"
		local kopts = {
			desc = keymap_entry.desc,
			silent = keymap_entry.silent ~= false,
			noremap = keymap_entry.noremap ~= false,
			expr = keymap_entry.expr,
			nowait = keymap_entry.nowait,
			buffer = keymap_entry.buffer,
		}
		keymap(mode, lhs, rhs, kopts)
	end
end

-- Colorscheme picker (colorschemes.lua). NOT Snacks.picker.colorschemes()
-- directly -- that finder globs every "colors/*.{vim,lua}" file on the
-- entire runtimepath (confirmed straight from snacks.nvim's own source,
-- lua/snacks/picker/source/vim.lua), so it always also lists Neovim's
-- ~25 bundled stock schemes (blue, desert, habamax, ...) plus every light/
-- alternate variant each plugin ships (tokyonight-day, catppuccin-latte,
-- rose-pine-dawn, kanagawa-lotus, solarized-osaka-light, ...) -- none of
-- which belong in a curated, dark-only list. This reuses that same finder
-- (for its live preview + real setup-file preview pane) and just filters
-- its results down to exactly the 8 names actually configured below.
local Snacks = require("snacks")
local curated_colorschemes = {
	["rose-pine"] = true,
	["catppuccin"] = true,
	["tokyonight"] = true,
	["gruvbox"] = true,
	["kanagawa"] = true,
	["solarized-osaka"] = true,
	["horizon"] = true,
	["dracula"] = true,
}
keymap("n", "<leader>uc", function()
	local items = vim.tbl_filter(function(item)
		return curated_colorschemes[item.text]
	end, require("snacks.picker.source.vim").colorschemes())
	Snacks.picker.pick({
		source = "colorschemes",
		items = items,
		format = "text",
		preview = "colorscheme",
		preset = "vertical",
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.schedule(function()
					vim.cmd("colorscheme " .. item.text)
				end)
			end
		end,
	})
end, { noremap = true, silent = true, desc = "Pick colorscheme (curated, live preview)" })

-- Oil - File explorer (oil.lua)
map({
	{
		"sf",
		function()
			require("oil").open_float(nil, { preview = {} })
		end,
		desc = "Toggle file explorer",
	},
})

-- LSP (lsp.lua, blink.lua)
map({
	{
		"gI",
		function()
			local clients = vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })
			if #clients > 0 then
				local params = vim.lsp.util.make_position_params(0, "utf-16")
				clients[1]:request("workspace/executeCommand", {
					command = "typescript.goToSourceDefinition",
					arguments = { params.textDocument.uri, params.position },
				}, function(err, result)
					if err then
						vim.notify("goToSourceDefinition: " .. err.message, vim.log.levels.ERROR)
						return
					end
					if result and #result > 0 then
						vim.lsp.util.show_document(result[1], "utf-16", { focus = true })
					else
						vim.notify("No source definition found", vim.log.levels.INFO)
					end
				end, 0)
			else
				vim.lsp.buf.implementation()
			end
		end,
		desc = "Goto Source Definition / Implementation",
	},
	{
		"gd",
		function()
			Snacks.picker.lsp_definitions({ jump = { reuse_win = false } })
		end,
		desc = "LSP Goto Definition",
	},
	{ "gD", Snacks.picker.lsp_declarations, desc = "LSP Goto Declaration" },
	{ "gy", Snacks.picker.lsp_type_definitions, desc = "LSP Goto T[y]pe Definition" },
	{ "gr", Snacks.picker.lsp_references, desc = "LSP Goto Definition" },
	{ "K", vim.lsp.buf.hover, desc = "Hover" },
	{ "gK", vim.lsp.buf.signature_help, desc = "Signature Help" },
	{
		"<c-k>",
		vim.lsp.buf.signature_help,
		desc = "Signature Help",
		mode = "i",
	},
	{
		"]d",
		function()
			vim.diagnostic.jump({ count = 1, float = true })
		end,
		desc = "Jump to next diagnostic",
		mode = "n",
	},
	{
		"[d",
		function()
			vim.diagnostic.jump({ count = -1, float = true })
		end,
		desc = "Jump to previous diagnostic",
		mode = "n",
	},
	{
		"<leader>ca",
		vim.lsp.buf.code_action,
		desc = "Code Action",
		mode = { "n", "x" },
	},
	{
		"<leader>cc",
		vim.lsp.codelens.run,
		desc = "Run Codelens",
		mode = "n", -- normal-mode only (visual-mode <leader>cb is copy-as-codeblock, above)
	},
	{ "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens" },
	{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
	{
		"<leader>f",
		function()
			require("conform").format()
		end,
		desc = "Format code",
		mode = { "n", "x" },
	},
})

-- Snacks (snacks.lua)
map({
	{ "<leader>cl", Snacks.picker.lsp_config, desc = "Lsp Info" },
	{ "<leader>cR", Snacks.rename.rename_file, desc = "Rename File" },
	{ ";f", Snacks.picker.files, desc = "Find files" },
	{ ";r", Snacks.picker.grep, desc = "Live grep" },
	{ ";;", Snacks.picker.resume, desc = "Resume picker" },
	{
		"\\\\",
		function()
			Snacks.picker.buffers({
				confirm = function(picker, item)
					picker:close()
					if not item then
						return
					end
					-- If the buffer is already shown in a window (any tab),
					-- jump to that window instead of opening it here.
					vim.schedule(function()
						for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
							for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
								if vim.api.nvim_win_get_buf(win) == item.buf then
									vim.api.nvim_set_current_tabpage(tab)
									vim.api.nvim_set_current_win(win)
									return
								end
							end
						end
						vim.api.nvim_set_current_buf(item.buf)
					end)
				end,
			})
		end,
		desc = "List buffers",
	},
	{ ";e", Snacks.picker.diagnostics, desc = "Diagnostics" },
	{ ";c", Snacks.picker.lsp_incoming_calls, desc = "LSP incoming calls" },
	{ ";n", Snacks.picker.notifications, desc = "Notifications" },
	{
		";g",
		function()
			Snacks.lazygit.open()
		end,
		desc = "Lazygit",
	},
	{
		"]]",
		function()
			Snacks.words.jump(vim.v.count1)
		end,
		desc = "Next Reference",
		mode = { "n", "t" },
	},
	{
		"[[",
		function()
			Snacks.words.jump(-vim.v.count1)
		end,
		desc = "Prev Reference",
		mode = { "n", "t" },
	},
})

-- Bufferline (bufferline.lua) — ]b/[b for cycling since <tab>/<s-tab>
-- already navigate real Vim tab-pages (above) and <leader>bd already means
-- "delete hidden buffers" (also above) — kept separate rather than
-- colliding with either.
map({
	{
		"]b",
		function()
			require("bufferline.commands").cycle(vim.v.count1)
		end,
		desc = "Next buffer",
	},
	{
		"[b",
		function()
			require("bufferline.commands").cycle(-vim.v.count1)
		end,
		desc = "Previous buffer",
	},
	{ "<leader>bc", "<cmd>BufferLinePickClose<cr>", desc = "Pick buffer to close" },
	{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin/unpin buffer" },
	{ "<leader>bb", "<cmd>BufferLinePick<cr>", desc = "Pick buffer to jump to" },
	{ "<leader>bn", "<cmd>enew<cr>", desc = "New empty buffer" },
	{ "<C-n>", "<cmd>enew<cr>", desc = "New empty buffer" },
})

-- Terminal (Snacks) — floating toggle
map({
	{
		"<leader>tt",
		function()
			Snacks.terminal.toggle()
		end,
		desc = "Toggle terminal",
		mode = { "n", "t" },
	},
})

-- Gitsigns (gitsigns.lua) / mini.diff (mini-diff.lua)
map({
	{
		"<leader>gb",
		function()
			require("gitsigns").blame_line()
		end,
		desc = "Blame current line",
	},
	{
		"<leader>gB",
		function()
			require("gitsigns").blame()
		end,
		desc = "Blame buffer",
	},
	{
		"<leader>go",
		function()
			local async = require("gitsigns.async")
			local cache = require("gitsigns.cache").cache

			async.run(function()
				local bufnr = vim.api.nvim_get_current_buf()
				local lnum = vim.api.nvim_win_get_cursor(0)[1]
				local bcache = cache[bufnr]
				if not bcache then
					return
				end

				bcache:get_blame(lnum)
				local blame = bcache.blame
				if not blame or not blame.entries or not blame.entries[lnum] then
					return
				end

				local info = blame.entries[lnum]
				local sha = info.commit.sha

				-- Check if uncommitted (sha is all zeros)
				if tonumber("0x" .. sha:sub(1, 8)) == 0 then
					vim.notify("Line not committed yet", vim.log.levels.WARN)
					return
				end

				vim.cmd.tabnew()
				require("gitsigns.actions.diffthis").show(bufnr, sha, info.filename)
				async.schedule()
				pcall(vim.api.nvim_win_set_cursor, 0, { info.orig_lnum or lnum, 0 })
			end)
		end,
		desc = "Open file from blamed commit",
	},
	{
		"<leader>gd",
		function()
			local MiniDiff = require("mini.diff")
			MiniDiff.toggle_overlay()
		end,
	},
})

-- CodeDiff (codediff.lua)
map({
	{ "<leader>dv", "<cmd>CodeDiff<cr>", desc = "Toggle CodeDiff" },
	{ "<leader>dh", "<cmd>CodeDiff history %<cr>", desc = "File history (current file)" },
	{ "<leader>dH", "<cmd>CodeDiff history<cr>", desc = "File history (repo)" },
})

-- Multicursor (multicursor.lua) — VSCode-style: add cursors, then
-- type/edit once and it applies to all of them simultaneously.
local mc = require("multicursor-nvim")

-- Add or skip a cursor directly above/below the current one -- matches
-- VSCode's Ctrl+Alt+Up/Down (using just Ctrl here, not Ctrl+Alt -- that
-- combo isn't reliably sent as a distinct sequence by every terminal,
-- especially on Windows). Bare Up/Down were tried first and reverted:
-- they silently ate normal arrow-key navigation, so every plain up/down
-- press added a cursor instead of just moving -- not what "invoke it
-- when I want it" means.
keymap({ "n", "x" }, "<c-up>", function()
	mc.lineAddCursor(-1)
end, { desc = "Add cursor above" })
keymap({ "n", "x" }, "<c-down>", function()
	mc.lineAddCursor(1)
end, { desc = "Add cursor below" })
keymap({ "n", "x" }, "<leader><up>", function()
	mc.lineSkipCursor(-1)
end, { desc = "Skip line, add cursor above" })
keymap({ "n", "x" }, "<leader><down>", function()
	mc.lineSkipCursor(1)
end, { desc = "Skip line, add cursor below" })

-- Add or skip a cursor on the next/previous match of the word under the
-- cursor (or the current selection) -- matches VSCode's Ctrl+D. Key choices
-- match the plugin's own documented example exactly.
keymap({ "n", "x" }, "<leader>n", function()
	mc.matchAddCursor(1)
end, { desc = "Add cursor on next match" })
keymap({ "n", "x" }, "<leader>N", function()
	mc.matchAddCursor(-1)
end, { desc = "Add cursor on previous match" })
keymap({ "n", "x" }, "<leader>s", function()
	mc.matchSkipCursor(1)
end, { desc = "Skip match, find next" })
keymap({ "n", "x" }, "<leader>S", function()
	mc.matchSkipCursor(-1)
end, { desc = "Skip match, find previous" })

-- Add/remove cursors with Ctrl+click, matching VSCode's Alt+click (Ctrl
-- instead, since Alt-click is already claimed by window-manager conventions
-- on most desktops and wouldn't reach the terminal).
keymap("n", "<c-leftmouse>", mc.handleMouse)
keymap("n", "<c-leftdrag>", mc.handleMouseDrag)
keymap("n", "<c-leftrelease>", mc.handleMouseRelease)

-- Esc: enable/clear multi-cursors. Wrapped in addKeymapLayer (the plugin's
-- own documented pattern for this) so it ONLY takes effect while multiple
-- cursors actually exist -- normal <Esc> behavior is completely untouched
-- the rest of the time.
mc.addKeymapLayer(function(layerSet)
	layerSet({ "n", "x" }, "<left>", mc.prevCursor)
	layerSet({ "n", "x" }, "<right>", mc.nextCursor)
	layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
	layerSet("n", "<esc>", function()
		if not mc.cursorsEnabled() then
			mc.enableCursors()
		else
			mc.clearCursors()
		end
	end)
end)

-- which-key (whichkey.lua)
keymap("n", "<leader>?", function()
	require("which-key").show({ global = true })
end, { noremap = true, silent = true, desc = "Show all keybindings (which-key)" })

-- Obsidian (obsidian.lua) — vault's Home.md, root-level, and a Snacks-
-- backed vault file picker. Both read the vault root from the global
-- `Obsidian.dir` (set by obsidian.setup(), an obsidian.Path object -- hence
-- tostring() below) rather than hardcoding the path a second time here, so
-- a future vault move/rename only needs to be updated in obsidian.lua.
-- NOT require("obsidian").get_client().dir -- that's the older per-client
-- accessor the plugin's own source marks "TODO: remove in 4.0.0";
-- Obsidian.dir is the one meant to replace it. NOT <leader>oh either --
-- <leader>o is already bound above ("new line below"), which would eat
-- the "o" before "h" ever registered.
keymap("n", "<leader>vh", function()
	vim.cmd("edit " .. vim.fn.fnameescape(tostring(Obsidian.dir) .. "/Home.md"))
end, { desc = "Open Obsidian vault home" })

-- picker.name = "snacks.picker" (obsidian.lua) means :Obsidian quick_switch
-- already renders through Snacks -- this just gives it a keymap, matching
-- the <leader>v... prefix <leader>vh already established above.
keymap("n", "<leader>vf", "<cmd>Obsidian quick_switch<cr>", { desc = "Find note in vault (Snacks picker)" })

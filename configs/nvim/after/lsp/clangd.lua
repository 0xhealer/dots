return {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--completion-style=detailed",
		"--header-insertion=iwyu",
		"--all-scopes-completion",
		"--cross-file-rename",
		"--offset-encoding=utf-16",
		-- Ensures clangd actually reads .clangd and the global config.yaml
		-- (see clangd/config.yaml next to this file's install instructions).
		-- Default-on since clangd 14ish, but explicit here since we can't be
		-- 100% sure of the exact version cutoff and this is a harmless no-op
		-- if it's already the default.
		"--enable-config",
		-- Whitelists gcc/g++ (scoop's `gcc` package) as an allowed compiler to
		-- query for system include paths. This alone does nothing without
		-- CompileFlags.Compiler also naming one of these in either a project
		-- .clangd file OR the global config.yaml — see that file for why the
		-- global one is the actual permanent fix, not a per-project file you
		-- have to remember to create every time.
		"--query-driver=**/gcc.exe,**/g++.exe,**/gcc,**/g++",
	},
}

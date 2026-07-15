-------------------------------------------------------------------------------
local M = {}
-------------------------------------------------------------------------------

local function default_data_dir()
    return vim.fs.joinpath(vim.fn.stdpath("data"), "nova_cs/")
end

M.defaults = {
    -- Directory where the generated palettes will be stored
    palette_dir = vim.fs.joinpath(default_data_dir(), "palettes/"),

    -- Directory where the `nova_cs_gen` CLI will be clones
    cli_repo_dir = vim.fs.joinpath(default_data_dir(), "bin/nova_cs_gen"),

    -- `nova_cs_gen` CLI clone URL
    cli_repo_url = "https://github.com/5ohue/nova_cs_gen",

    -- Automatically set the colorscheme at the start
    auto_load = true,

    -- Default palette to use when current palette can't be used
    default_palette = "everforest",

    -- Ignore the current palette on the disk and use the one from the variable
    palette_override = nil,

    -- Which colorscheme to set by default
    colorscheme = nil,
}

M.options = {}

M.setup = function(user_options)
    M.options = vim.tbl_deep_extend("force", M.defaults, user_options or {})
end

-------------------------------------------------------------------------------
return M
-------------------------------------------------------------------------------

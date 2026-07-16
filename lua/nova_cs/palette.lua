-------------------------------------------------------------------------------
local M = {}
local cfg = require("nova_cs.config")
local cli = require("nova_cs.cli")
-------------------------------------------------------------------------------

M.current_file = nil
M.current = nil
M.current_palette_table = {}

M.palettes = {}

M.init = function()
    M.current_file = vim.fs.joinpath(cfg.options.palette_dir, "config.json")

    M.palettes = {}
    local files = vim.split(vim.fn.glob(vim.fs.joinpath(cfg.options.palette_dir, "*.lua")), '\n', { trimempty = true })
    for _, file in ipairs(files) do
        table.insert(M.palettes, vim.fn.fnamemodify(file, ":t:r"))
    end
    table.sort(M.palettes)

    M.set_current(cfg.options.palette_override or M.read_current_file())
    if cfg.options.auto_load then
        M.apply_current_palette()
    end
end

M.read_current_file = function()
    if vim.fn.filereadable(M.current_file) == 1 then
        local ok, contents = pcall(
            vim.json.decode,
            table.concat(vim.fn.readfile(M.current_file), "\n")
        )

        if ok then
            return contents.palette
        end
    end

    return cfg.options.default_palette
end

M.build = function()
    local function get_plugin_root()
        local source = debug.getinfo(1, "S").source:sub(2) -- path to init.lua
        -- Walk up directories to reach the repository root: lua/nova_cs/init.lua -> 3 levels up
        return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
    end

    local files = vim.split(vim.fn.glob(vim.fs.joinpath(get_plugin_root(), "palettes/*.lua")), '\n', { trimempty = true })

    for _, file in ipairs(files) do
        if vim.fn.isdirectory(file) == 0 then
            local fname = vim.fs.basename(file)
            local destination = vim.fs.joinpath(cfg.options.palette_dir, fname)

            if vim.fn.filereadable(destination) == 0 then
                vim.fn.filecopy(file, destination)
            end
        end
    end

    M.init()
end

-- Generating palettes --------------------------------------------------------

local function lua_string_to_table(str)
    local chunk, err = load(str)

    if not chunk then
        return nil, err
    end

    local ok, result = pcall(chunk)

    if not ok then
        return nil, result
    end

    return result
end

M.generate_from_text = function(palette_name, text)
    if not palette_name then
        return
    end

    cli.generate_from_string(text, function(obj)
        if obj.code == 0 then
            local dest = vim.fs.joinpath(cfg.options.palette_dir, palette_name .. ".lua")
            vim.schedule(function()
                vim.fn.writefile(obj.stdout, dest)
            end)
            if not vim.tbl_contains(M.palettes, palette_name) then
                table.insert(M.palettes, palette_name)
                table.sort(M.palettes)
            end
        else
            vim.schedule(function()
                vim.notify("[nova_cs] Failed to generate palette: " .. (obj.stderr or ""), vim.log.levels.ERROR)
            end)
        end
    end)
end

M.preview_from_text = function(text)
    cli.generate_from_string(text, function(obj)
        if obj.code == 0 then
            local palette_table, err = lua_string_to_table(obj.stdout)

            if not palette_table then
                vim.notify(
                    "[nova_cs] Invalid palette: " .. err,
                    vim.log.levels.ERROR
                )
                return
            end

            vim.schedule(function()
                M.apply_palette_table(palette_table)
            end)
        else
            vim.schedule(function()
                vim.notify("[nova_cs] Failed to generate palette: " .. (obj.stderr or ""), vim.log.levels.ERROR)
            end)
        end
    end)
end

-- Applying palettes ----------------------------------------------------------

M.set_current = function(palette_name, save_to_file)
    local palette_path = M.palette_path(palette_name)
    if vim.fn.filereadable(palette_path) == 0 then
        vim.notify(
            "[nova_cs] Missing palette: " .. palette_name .. ". Defaulting to " .. cfg.options.default_palette,
            vim.log.levels.ERROR
        )
        M.current = cfg.options.default_palette

        -- Don't save because of error
        return
    else
        M.current = palette_name
    end

    if save_to_file then
        vim.fn.writefile({
            vim.json.encode({
                palette = M.current
            })
        }, M.current_file)
    end
end

M.get_current = function()
    return M.current
end

M.get_current_palette_table = function()
    return M.current_palette_table
end

M.palette_path = function(palette_name)
    return vim.fs.joinpath(cfg.options.palette_dir, palette_name .. ".lua")
end

M.reload = function()
    M.set_current(M.read_current_file())
    M.apply_current_palette()
end

M.apply_current_palette = function()
    M.apply_palette(M.current)
end

M.apply_palette = function(palette_name)
    local palette_path = M.palette_path(palette_name)
    local palette_table = dofile(palette_path)
    M.apply_palette_table(palette_table)
end

M.apply_palette_table = function(palette_table)
    M.current_palette_table = palette_table

    -- Set the colorscheme
    if cfg.options.colorscheme then
        vim.cmd.colorscheme(cfg.options.colorscheme)
    else
        -- Just set the current colorscheme again
        vim.cmd.colorscheme(vim.g.colors_name)
    end
end

-- Other ----------------------------------------------------------------------

M.delete_palette = function(palette_name)
    if palette_name == cfg.options.default_palette then
        vim.notify(
            "[nova_cs] " .. palette_name .. " is a default palette! I won't delete it!",
            vim.log.levels.ERROR
        )
        return
    end

    local palette_path = M.palette_path(palette_name)
    if vim.fn.filereadable(palette_path) == 0 then
        vim.notify(
            "[nova_cs] Trying to delete a non existing palette: File not found " .. palette_path,
            vim.log.levels.ERROR
        )
        return
    end

    if M.current == palette_name then
        M.set_current(cfg.options.default_palette, true)
        M.apply_current_palette()
    end

    vim.fs.rm(palette_path)
    for i, name in ipairs(M.palettes) do
        if name == palette_name then
            table.remove(M.palettes, i)
            break
        end
    end
end

-------------------------------------------------------------------------------
return M
-------------------------------------------------------------------------------

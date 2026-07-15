-------------------------------------------------------------------------------

local M = { _building = false }
local cfg = require("nova_cs.config")

-- Ensure the CLI -------------------------------------------------------------

function M.binary_path()
    local path = vim.fs.joinpath(
        cfg.options.cli_repo_dir,
        "target",
        "release",
        "nova_cs_gen"
    )

    if vim.fn.has("win32") == 1 then
        path = path .. ".exe"
    end

    return path
end

M.has_binary = function()
    local bin = M.binary_path()
    if not bin or vim.fn.filereadable(bin) == 0 then
        return false
    end
    return true
end

M.build = function()
    if M._building then
        return
    end
    M._building = true

    local vendor = cfg.options.cli_repo_dir
    local git_dir = vim.fs.joinpath(vendor, ".git")

    if vim.fn.isdirectory(git_dir) == 0 then
        vim.system({
            "git",
            "clone",
            cfg.options.cli_repo_url,
            vendor,
        }, function(obj)
            if obj.code == 0 then
                M.compile()
            else
                vim.schedule(function()
                    vim.notify("[nova_cs] CLI repo clone error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
                end)
            end
        end)
    else
        vim.system({
            "git",
            "-C",
            vendor,
            "pull"
        }, function(obj)
            if obj.code == 0 then
                M.compile()
            else
                vim.schedule(function()
                    vim.notify("[nova_cs] CLI repo pull error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
                end)
            end
        end)
    end
end

M.compile = function()
    vim.system({ "cargo", "build", "--release" }, { cwd = cfg.options.cli_repo_dir }, function(obj)
        if obj.code == 0 then
            vim.schedule(function()
                vim.notify("[nova_cs] Dependencies compiled successfully!", vim.log.levels.INFO)
            end)
        else
            vim.schedule(function()
                vim.notify("[nova_cs] Compilation failed: " .. (obj.stderr or ""), vim.log.levels.ERROR)
            end)
        end
    end)
end

-- Running the CLI ------------------------------------------------------------

-- Function to run the compiled binary and get its output
M.run = function(args, stdin, callback)
    if not M.has_binary() then
        vim.notify("[nova_cs] Binary not available yet.", vim.log.levels.WARN)
        return
    end

    vim.system(
        { M.binary_path(), unpack(args or {}) },
        { text = true, stdin = stdin, }, callback)
end

-- Function that generates a theme and return the stdout
M.generate_from_string = function(toml_input, callback)
    M.run({}, toml_input, callback)
end

-------------------------------------------------------------------------------
return M
-------------------------------------------------------------------------------

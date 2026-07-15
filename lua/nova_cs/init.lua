-------------------------------------------------------------------------------
local M = {}
local cfg = require("nova_cs.config")
local cli = require("nova_cs.cli")
local palette = require("nova_cs.palette")
-------------------------------------------------------------------------------

M.setup = function(user_options)
    cfg.setup(user_options)
    palette.init()
end

M.build = function(user_options)
    cfg.setup(user_options)

    vim.fn.mkdir(cfg.options.palette_dir, "p")
    vim.fn.mkdir(vim.fs.dirname(cfg.options.cli_repo_dir), "p")

    palette.build()
    cli.build()
end

-- Commands -------------------------------------------------------------------

local function get_cur_buf_text()
    return table.concat(
        vim.api.nvim_buf_get_lines(0, 0, -1, false),
        "\n"
    ) .. "\n"
end

local function get_file_text(path)
    if vim.fn.filereadable(path) == 0 then
        vim.notify(
            "[nova_cs] Cannot open file: " .. path,
            vim.log.levels.ERROR
        )

        return ""
    end

    return table.concat(
        vim.fn.readfile(path),
        "\n"
    ) .. "\n"
end

local function palette_picker(prompt, on_select, on_move, on_exit)
    if #palette.palettes == 0 then
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    pickers.new({
        layout_strategy = "center",
        layout_config = {
            width = 35,
            height = math.min(#palette.palettes + 4, 15),
        },
    }, {
        prompt_title = prompt or "NovaCS Palettes",

        finder = finders.new_table({
            results = palette.palettes,
        }),

        sorter = conf.generic_sorter({}),

        previewer = false,

        attach_mappings = function(prompt_bufnr, map)
            -- Helper to run the movement callback safely
            local function run_on_move()
                if on_move then
                    local selection = action_state.get_selected_entry()
                    if selection then
                        on_move(selection.value)
                    end
                end
            end

            -- Trigger on_move on initial open (after Telescope is ready)
            if on_move then
                on_move(palette.palettes[1])
            end

            -- Run on_move whenever the selection changes (cursor moves)
            -- We intercept the default movement actions to trigger our callback
            local function move_and_preview(prompt_buf, move_action)
                move_action(prompt_buf)
                run_on_move()
            end

            map({ "i", "n" }, "<Tab>", function(buf) move_and_preview(buf, actions.move_selection_next) end)
            map({ "i", "n" }, "<S-Tab>", function(buf) move_and_preview(buf, actions.move_selection_previous) end)
            map({ "i", "n" }, "<Down>", function(buf) move_and_preview(buf, actions.move_selection_next) end)
            map({ "i", "n" }, "<Up>", function(buf) move_and_preview(buf, actions.move_selection_previous) end)
            map({ "i", "n" }, "<C-n>", function(buf) move_and_preview(buf, actions.move_selection_next) end)
            map({ "i", "n" }, "<C-p>", function(buf) move_and_preview(buf, actions.move_selection_previous) end)

            -- Selection callback (when hitting Enter)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    if on_select then
                        on_select(selection.value)
                    end
                end
            end)

            -- Hook into the exit event
            -- This autocmd triggers when the Telescope buffer is wiped out (closed)
            if on_exit then
                local prompt_buf = vim.api.nvim_win_get_buf(0)
                vim.api.nvim_create_autocmd("BufWipeout", {
                    buffer = prompt_buf,
                    once = true,
                    callback = function()
                        on_exit()
                    end,
                })
            end

            return true
        end,
    }):find()
end

--- Generate and save a new palette (don't preview it)
M.generate = function(args)
    local text = ""
    local palette_name = ""
    if not args[1] or args[1] == '%' then
        local buf_name = vim.api.nvim_buf_get_name(0)
        palette_name = vim.fn.fnamemodify(buf_name, ":t:r")
        text = get_cur_buf_text()
    else
        palette_name = args[2] or vim.fn.fnamemodify(args[1], ":t:r")
        text = get_file_text(args[1])
    end

    if text == "" then
        return
    end

    palette.generate_from_text(palette_name, text)
end

--- Preview the palette without setting it as default
M.preview = function(args)
    local text = ""
    if not args[1] or args[1] == '%' then
        text = get_cur_buf_text()
    else
        text = get_file_text(args[1])
    end

    if text == "" then
        return
    end

    palette.preview_from_text(text)
end

--- Select a new default palette
M.select = function(args)
    if args[1] then
        palette.set_current(args[1], true)
        palette.apply_current_palette()
        return
    end

    local cur_palette = palette.get_current()

    palette_picker(
        "Select NovaCS Palette",
        function(selection)
            vim.schedule(function()
                palette.set_current(
                    selection,
                    true
                )

                palette.apply_current_palette()
            end)
        end,
        function(selection)
            vim.schedule(function()
                palette.apply_palette(selection)
            end)
        end,
        function()
            vim.schedule(function()
                palette.apply_palette(cur_palette)
            end)
        end
    )
end

--- Delete an existing palette
M.delete = function(args)
    if args[1] then
        palette.delete_palette(args[1])
        return
    end

    local cur_palette = palette.get_current()

    palette_picker(
        "Delete NovaCS Palette",
        function(selection)
            palette.delete_palette(selection)
        end,
        function(selection)
            vim.schedule(function()
                palette.apply_palette(selection)
            end)
        end,
        function()
            vim.schedule(function()
                palette.apply_palette(cur_palette)
            end)
        end
    )
end

--- Print the current palette
M.current = function(_)
    vim.notify(
        "[nova_cs] Current palette is " .. palette.get_current(),
        vim.log.levels.INFO
    )
end

--- Change to a different theme
M.theme = function(args)
    if args[1] then
        cfg.options.colorscheme = args[1]
        palette.apply_current_palette()
    end
end

-------------------------------------------------------------------------------
return M
-------------------------------------------------------------------------------

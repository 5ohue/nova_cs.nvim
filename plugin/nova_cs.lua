-------------------------------------------------------------------------------
if vim.g.loaded_nova_cs then
    return
end
vim.g.loaded_nova_cs = true
-------------------------------------------------------------------------------

local subcommands = {
    generate = true,
    preview = true,
    select = true,
    delete = true,
    current = true,
    theme = true,
}

vim.api.nvim_create_user_command("NovaCS",
    function(args)
        if args.fargs[1] then
            local command = args.fargs[1]
            local command_args = vim.list_slice(args.fargs, 2)

            if command == "generate" then
                require("nova_cs").generate(command_args)
            elseif command == "preview" then
                require("nova_cs").preview(command_args)
            elseif command == "select" then
                require("nova_cs").select(command_args)
            elseif command == "delete" then
                require("nova_cs").delete(command_args)
            elseif command == "current" then
                require("nova_cs").current(command_args)
            elseif command == "theme" then
                require("nova_cs").theme(command_args)
            end
        end
    end, {
        nargs = '*',
        complete = function(arg_lead, cmd_line, _)
            -- Split command line by space to see which argument we are typing
            local parts = vim.split(cmd_line, "%s+")

            -- If we are typing the first argument (the subcommand)
            if #parts <= 2 then
                local keys = vim.tbl_keys(subcommands)
                return vim.tbl_filter(function(key)
                    return key:find("^" .. arg_lead)
                end, keys)
            end

            -- Optional: Add file completion for commands like generate/preview
            local active_subcmd = parts[2]
            if active_subcmd == "generate" or active_subcmd == "preview" then
                return vim.fn.getcompletion(arg_lead, "file")
            end
        end
    }
)

-------------------------------------------------------------------------------

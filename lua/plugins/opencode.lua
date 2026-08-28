return {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = {
        "folke/snacks.nvim",  -- ask()/select() pick up snacks.input/snacks.picker automatically when present
    },
    config = function()
        ---@type opencode.Opts
        vim.g.opencode_opts = {
            server = {
                -- Open the OpenCode server in a vertical split instead of a float
                start = function()
                    local cur_win = vim.api.nvim_get_current_win()
                    require("snacks").terminal.open("opencode --port", {
                        win = { style = "terminal", position = "right", width = 0.4 },
                    })
                    -- Snacks focuses the new terminal split; jump back so @this still
                    -- resolves against your original buffer/selection, not the terminal.
                    vim.schedule(function()
                        if vim.api.nvim_win_is_valid(cur_win) then
                            vim.api.nvim_set_current_win(cur_win)
                        end
                    end)
                end,
            },
            events = {
                permissions = {
                    -- Disable the built-in prompt/tabnew+diffpatch handlers — we render
                    -- our own inline mini.diff preview below instead.
                    enabled = false,
                    edits = {
                        enabled = false,
                    },
                },
            },
        }

        -- Resolve OpenCode's reported filepath the same way its own (built-in) diff
        -- handler does — it's sometimes absolute, sometimes relative to HOME.
        local function resolve_edit_filepath(filepath)
            local absolute_filepath = vim.fn.fnamemodify(filepath, ":p")
            if vim.fn.filereadable(absolute_filepath) == 1 then
                return absolute_filepath
            end
            if vim.env.HOME and vim.env.HOME ~= "" then
                local home_filepath = vim.fs.normalize(vim.fs.joinpath(vim.env.HOME, filepath))
                if vim.fn.filereadable(home_filepath) == 1 then
                    return home_filepath
                end
            end
            if vim.fn.filereadable(filepath) == 1 then
                return filepath
            end
            return nil
        end

        -- Apply a unified diff to `filepath`'s on-disk content using Vim's own
        -- `:diffpatch`, inside a throwaway tab so nothing is ever shown to the user.
        -- Returns the patched lines, or nil on failure.
        local function diffpatch_lines(filepath, diff_text)
            local patch_filepath = vim.fn.tempname() .. ".patch"
            if vim.fn.writefile(vim.split(diff_text, "\n"), patch_filepath) ~= 0 then
                return nil
            end

            if not pcall(vim.cmd, "noautocmd tabnew " .. vim.fn.fnameescape(filepath)) then
                return nil
            end

            local patched_ok = pcall(vim.cmd, "silent vert diffpatch " .. vim.fn.fnameescape(patch_filepath))
            local lines = nil
            if patched_ok then
                lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            end

            pcall(vim.cmd, "tabclose!")
            return lines
        end

        -- Parse a unified diff into hunks expressed purely in terms of the *new*
        -- (post-patch) file's line numbers, so rendering never has to re-derive
        -- alignment — we trust OpenCode's own hunk boundaries exactly as given.
        -- Each hunk: { added = { {line=<1-based new-file line>, text=...}, ... },
        --              deleted_groups = { {before=<1-based new-file line>, lines={...}}, ... } }
        local function parse_diff_hunks(diff_text)
            local lines = vim.split(diff_text, "\n", { plain = true })
            local header_idxs = {}
            for idx, l in ipairs(lines) do
                if l:match("^@@ %-%d") then table.insert(header_idxs, idx) end
            end

            local hunks = {}
            for h, idx in ipairs(header_idxs) do
                local header = lines[idx]
                local c_start = tonumber(header:match("%+(%d+)"))
                if c_start then
                    local body_end = (header_idxs[h + 1] or (#lines + 1)) - 1
                    local new_line = c_start
                    local added = {}
                    local deleted_groups = {}
                    local cur_delete_group = nil

                    for i = idx + 1, body_end do
                        local l = lines[i]
                        local tag = l:sub(1, 1)
                        local text = l:sub(2)
                        if tag == " " then
                            cur_delete_group = nil
                            new_line = new_line + 1
                        elseif tag == "+" then
                            cur_delete_group = nil
                            table.insert(added, { line = new_line, text = text })
                            new_line = new_line + 1
                        elseif tag == "-" then
                            if not cur_delete_group then
                                cur_delete_group = { before = new_line, lines = {} }
                                table.insert(deleted_groups, cur_delete_group)
                            end
                            table.insert(cur_delete_group.lines, text)
                        else
                            cur_delete_group = nil
                        end
                    end

                    table.insert(hunks, { added = added, deleted_groups = deleted_groups })
                end
            end
            return hunks
        end

        local diff_ns = vim.api.nvim_create_namespace("opencode_diff_preview")

        -- Render OpenCode's own hunks directly as extmarks: added lines get a
        -- whole-line highlight, deleted lines are shown as virtual text right
        -- above where they used to be. No diff recomputation, no re-alignment —
        -- what you see is exactly OpenCode's patch, hunk for hunk.
        local function render_diff_hunks(bufnr, hunks)
            vim.api.nvim_buf_clear_namespace(bufnr, diff_ns, 0, -1)
            local line_count = vim.api.nvim_buf_line_count(bufnr)

            for _, hunk in ipairs(hunks) do
                for _, a in ipairs(hunk.added) do
                    if a.line >= 1 and a.line <= line_count then
                        vim.api.nvim_buf_set_extmark(bufnr, diff_ns, a.line - 1, 0, {
                            line_hl_group = "DiffAdd",
                            priority = 200,
                        })
                    end
                end

                for _, grp in ipairs(hunk.deleted_groups) do
                    local virt_lines = {}
                    for _, t in ipairs(grp.lines) do
                        table.insert(virt_lines, { { t, "DiffDelete" } })
                    end

                    local row = grp.before - 1
                    local above = true
                    if row >= line_count then
                        row = math.max(line_count - 1, 0)
                        above = false
                    end
                    row = math.max(row, 0)

                    vim.api.nvim_buf_set_extmark(bufnr, diff_ns, row, 0, {
                        virt_lines = virt_lines,
                        virt_lines_above = above,
                        priority = 200,
                    })
                end
            end
        end

        -- Preview an OpenCode edit inline — virtual-text diff shown directly in
        -- the real buffer, built straight from OpenCode's own diff hunks (no
        -- separate diff engine involved), no tab/split needed.
        -- @return Promise<"once"|"always"|"reject">
        local function preview_edit_inline(diff_text, raw_filepath)
            local Promise = require("opencode.promise")

            local filepath = resolve_edit_filepath(raw_filepath)
            if not filepath then
                return Promise.reject("Cannot resolve OpenCode edit target file: " .. tostring(raw_filepath))
            end

            local new_lines = diffpatch_lines(filepath, diff_text)
            if not new_lines then
                return Promise.reject("Failed to apply OpenCode's diff to " .. filepath)
            end

            local hunks = parse_diff_hunks(diff_text)

            local bufnr = vim.fn.bufadd(filepath)
            vim.fn.bufload(bufnr)

            local original_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            -- Show the buffer (reusing its window if already open) so the preview is visible.
            local winid = vim.fn.bufwinid(bufnr)
            if winid == -1 then
                vim.cmd("vertical sbuffer " .. bufnr)
            else
                vim.api.nvim_set_current_win(winid)
            end

            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
            render_diff_hunks(bufnr, hunks)

            vim.notify(
                "OpenCode wants to edit "
                    .. vim.fn.fnamemodify(filepath, ":t")
                    .. " — y accept once, Y accept always, n reject",
                vim.log.levels.INFO,
                { title = "opencode" }
            )

            return Promise.new(function(resolve)
                local function cleanup()
                    pcall(vim.keymap.del, "n", "y", { buffer = bufnr })
                    pcall(vim.keymap.del, "n", "Y", { buffer = bufnr })
                    pcall(vim.keymap.del, "n", "n", { buffer = bufnr })
                    vim.api.nvim_buf_clear_namespace(bufnr, diff_ns, 0, -1)
                end

                local function accept(reply)
                    cleanup()
                    -- Buffer already matches the accepted content; mark clean so the
                    -- server's write + our autoread reload sync silently, no conflict.
                    vim.bo[bufnr].modified = false
                    vim.cmd("checktime " .. bufnr)
                    resolve(reply)
                end

                local function reject()
                    cleanup()
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, original_lines)
                    vim.bo[bufnr].modified = false
                    resolve("reject")
                end

                local km_opts = { buffer = bufnr, nowait = true, silent = true }
                vim.keymap.set("n", "y", function() accept("once") end, km_opts)
                vim.keymap.set("n", "Y", function() accept("always") end, km_opts)
                vim.keymap.set("n", "n", reject, km_opts)
            end)
        end

        vim.api.nvim_create_autocmd("User", {
            pattern = "OpencodeEvent:permission.asked",
            group = vim.api.nvim_create_augroup("OpencodeCustomPermissions", { clear = true }),
            desc = "Render inline mini.diff previews / prompts for OpenCode permission requests",
            callback = function(args)
                ---@type opencode.server.Event
                local event = args.data.event
                local url = args.data.url
                if event.type ~= "permission.asked" then
                    return
                end

                require("opencode.server")
                    .new(url)
                    :next(function(server)
                        local meta = event.properties.metadata
                        if event.properties.permission == "edit" and meta and meta.diff then
                            return preview_edit_inline(meta.diff, meta.filepath):next(function(reply)
                                return server:permit(event.properties.id, reply)
                            end)
                        end

                        -- Non-edit permissions (e.g. bash) get a plain Once/Always/Reject prompt.
                        return require("opencode.promise.ui")
                            .select({ "Once", "Always", "Reject" }, {
                                prompt = "Permit opencode to: "
                                    .. event.properties.permission
                                    .. " "
                                    .. table.concat(event.properties.patterns or {}, ", ")
                                    .. "?: ",
                                format_item = function(item) return item end,
                            })
                            :next(function(choice)
                                return server:permit(event.properties.id, choice:lower())
                            end)
                    end)
                    :catch(function(err)
                        if err then
                            vim.notify("OpenCode permission error: " .. err, vim.log.levels.ERROR, { title = "opencode" })
                        end
                    end)
            end,
        })

        vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ") end,
            { desc = "Ask OpenCode…" })
        vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,
            { desc = "Select OpenCode…" })
        vim.keymap.set({ "n", "x" }, "aa", function() return require("opencode").operator("@this ") end,
            { desc = "Append range to OpenCode", expr = true })
    end,
}


{
  autoCmd = [
    {
      event = [ "VimEnter" ];
      callback = {
        __raw = ''
          function()
            if vim.fn.argv(0) == "" then
              require('telescope.builtin').find_files()
            end
          end
        '';
      };
      desc = "Start vim with file finder";
    }
    {
      event = [ "TextYankPost" ];
      callback = {
        __raw = ''
          function()
            vim.highlight.on_yank()
          end
        '';
      };
      desc = "Highlight when yanking text";
    }
    {
      event = [ "LspProgress" ];
      desc = "Display LSP progress";
      callback = {
        __raw = ''
          function(ev)
            local progress = vim.defaulttable()
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
            if not client or type(value) ~= "table" then
              return
            end
            local p = progress[client.id]

            for i = 1, #p + 1 do
              if i == #p + 1 or p[i].token == ev.data.params.token then
                p[i] = {
                  token = ev.data.params.token,
                  msg = ("[%3d%%] %s%s"):format(
                    value.kind == "end" and 100 or value.percentage or 100,
                    value.title or "",
                    value.message and (" **%s**"):format(value.message) or ""
                  ),
                  done = value.kind == "end",
                }
                break
              end
            end

            local msg = {} ---@type string[]
            progress[client.id] = vim.tbl_filter(function(v)
              return table.insert(msg, v.msg) or not v.done
            end, p)

            local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
            vim.notify(table.concat(msg, "\n"), "info", {
              id = "lsp_progress",
              title = client.name,
              opts = function(notif)
                notif.icon = #progress[client.id] == 0 and " "
                  or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
              end,
            })
          end
        '';
      };
    }
  ];
}

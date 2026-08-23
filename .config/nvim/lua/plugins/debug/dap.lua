-- Debugging (DAP = Debug Adapter Protocol, the same engine VS Code uses).
--
--   * nvim-dap ................ the debugger core (breakpoints, stepping)
--   * nvim-dap-ui ............. panels: variables / scopes / breakpoints / watches / REPL
--   * nvim-dap-virtual-text ... shows each variable's live value inline next to your code
--   * mason-nvim-dap .......... auto-installs debug adapters through your existing Mason
--
-- Adapters are declared in `ensure_installed` below. "python" pulls in debugpy.
-- Add more later (e.g. "codelldb" for C/C++/Rust, "delve" for Go).

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- required by nvim-dap-ui
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
      "williamboman/mason.nvim",
    },
    -- Load lazily the first time you touch any debug keybind.
    keys = {
      { "<leader>dc", function() require("dap").continue() end,          desc = "Debug: Start / Continue" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "Debug: Conditional Breakpoint",
      },
      { "<leader>di", function() require("dap").step_into() end,   desc = "Debug: Step Into" },
      { "<leader>do", function() require("dap").step_over() end,   desc = "Debug: Step Over" },
      { "<leader>dO", function() require("dap").step_out() end,    desc = "Debug: Step Out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug: Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end,    desc = "Debug: Run Last" },
      { "<leader>dt", function() require("dap").terminate() end,   desc = "Debug: Terminate" },
      { "<leader>du", function() require("dapui").toggle() end,    desc = "Debug: Toggle UI" },
      {
        "<leader>de",
        function() require("dapui").eval() end,
        mode = { "n", "v" },
        desc = "Debug: Evaluate Expression",
      },
      -- VS Code-style function keys, for muscle memory.
      { "<F5>",  function() require("dap").continue() end,          desc = "Debug: Start / Continue" },
      { "<F10>", function() require("dap").step_over() end,         desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end,         desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end,          desc = "Debug: Step Out" },
      { "<F9>",  function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Auto-install the adapters. "python" == debugpy.
      require("mason-nvim-dap").setup({
        ensure_installed = { "python" },
        automatic_installation = true,
        handlers = {}, -- use mason-nvim-dap's default handlers (wires adapters + configs for you)
      })

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- Open the debug UI automatically when a session starts, close it when it ends.
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- Prettier breakpoint gutter signs.
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticInfo", linehl = "Visual", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
    end,
  },
}

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "ollama",
    },
    inline = {
      adapter = "ollama",
    },
  },

  adapters = {
    ollama = function()
      return require("codecompanion.adapters").extend("ollama", {
        schema = {
          model = {
            -- default = "deepseek-coder:1.3b",
            default = "qwen3:8b"
          },
        },
        env = {
          url = "http://192.168.3.104:11434",
          -- api_key = "OLLAMA_API_KEY",
        },
        headers = {
          ["Content-Type"] = "application/json",
          -- ["Authorization"] = "Bearer ${api_key}",
        },
        parameters = {
          sync = true,
        },
      })
    end,
  },
})

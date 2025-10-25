require("codecompanion").setup({
      -- Define strategies for different types of interactions
      strategies = {
        chat = {
          adapter = "qwen3_local",
        },
        inline = {
          adapter = "qwen3_local",
        },
        agent = {
          adapter = "qwen3_local",
        },
      },

      -- Updated adapter configuration using the new adapters.http structure
      adapters = {
        http = {
          qwen3_local = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              name = "qwen3_local",
              env = {
                url = "http://127.0.0.1:9000",
                api_key = "dummy_key", -- ramalama doesn't require real API key
              },
              headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer dummy_key",
              },
              parameters = {
                sync = true,
              },
              schema = {
                model = {
                  default = "qwen3-coder",
                  choices = {
                    "qwen3-coder",
                  },
                },
                max_tokens = {
                  default = 4096,
                  range = { 1, 8192 },
                },
                temperature = {
                  default = 0.1,
                  range = { 0, 2 },
                },
                top_p = {
                  default = 0.95,
                  range = { 0, 1 },
                },
                stop = {
                  default = nil,
                },
                stream = {
                  default = false,
                },
              },
            })
          end,
          -- Additional http adapter options can go here
          opts = {
            allow_insecure = true, -- Allow HTTP instead of HTTPS
            -- proxy = nil, -- Set proxy if needed
          },
        },
      },

      -- Display settings
      display = {
        action_palette = {
          width = 95,
          height = 10,
        },
        chat = {
          window = {
            layout = "vertical", -- "vertical", "horizontal", "float", "buffer"
            width = 0.45,
            height = 0.8,
            relative = "editor",
            border = "single",
            title = "CodeCompanion Chat",
          },
          intro_message = "Welcome! I'm powered by Qwen3-coder running locally via ramalama.",
          separator = "─",
          show_settings = true,
        },
      },
  
  
      -- Key mappings
      keymaps = {
        ["q"] = "keymaps.cancel_request", -- Cancel ongoing request
      },


-- Logging for troubleshooting
  log_level = "DEBUG", -- Change to "DEBUG" for troubleshooting
})

-- require("codecompanion").setup({
--   strategies = {
--     chat = {
--       adapter = "ollama",
--     },
--     inline = {
--       adapter = "ollama",
--     },
--   },
-- 
--   adapters = {
--     ollama = function()
--       return require("codecompanion.adapters").extend("ollama", {
--         schema = {
--           model = {
--             -- default = "deepseek-coder:1.3b",
--             default = "qwen3-coder:latest"
--           },
--         },
--         env = {
--           url = "http://192.168.1.152:9000",
--           -- api_key = "OLLAMA_API_KEY",
--         },
--         headers = {
--           ["Content-Type"] = "application/json",
--           -- ["Authorization"] = "Bearer ${api_key}",
--         },
--         parameters = {
--           sync = true,
--         },
--       })
--     end,
--   },
-- })

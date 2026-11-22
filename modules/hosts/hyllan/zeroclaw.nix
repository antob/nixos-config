{ inputs, ... }:
{
  flake.modules.nixos.hyllan =
    { config, pkgs, ... }:

    let
      inherit (config.sops) secrets;
      dataDir = "/mnt/tank/services/zeroclaw";
      workspace = "${dataDir}/agents/assistant/workspace";
    in
    {
      imports = [ "${inputs.zeroclaw}/nix/module.nix" ];

      antob.agent-access.logUnits = [
        "zeroclaw-assistant"
      ];

      services.zeroclaw.instances.assistant = {
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.zeroclaw;
        inherit dataDir;
        # Must define TELEGRAM_BOT_TOKEN, HA_TOKEN and LLAMA_API_KEY
        environmentFile = secrets.zeroclaw_env.path;

        # Declarative persona, read-only for the agent.
        bindReadOnlyPaths = {
          "${workspace}/IDENTITY.md" = ./_files/zeroclaw/IDENTITY.md;
          "${workspace}/SOUL.md" = ./_files/zeroclaw/SOUL.md;
        };

        settings = {
          schema_version = 4;

          # llama-server on desktob over wg0. No fallback: the assistant stays private.
          providers.models.llamacpp.desktob = {
            uri = "http://10.64.1.6:8080/v1";
            model = "zeroclaw";
            api_key = "$LLAMA_API_KEY";
            timeout_secs = 90;
            # Guard against runaway generation (one request ran for 5 minutes).
            max_tokens = 1024;
          };

          agents.assistant = {
            model_provider = "llamacpp.desktob";
            risk_profile = "assistant";
            runtime_profile = "assistant";
            channels = [ "telegram.home" ];
            # The reply/no-reply classifier is for group chats and costs a full LLM call per message.
            precheck.enabled = false;
            mcp_bundles = [ "home" ];
          };

          risk_profiles.assistant = {
            level = "supervised";
            # Other HA tools (media, light settings, ...) still ask for approval on Telegram.
            auto_approve = [
              "ha__homeassistant__GetLiveContext"
              "ha__llm__GetDateTime"
              "ha__intent__HassTurnOn"
              "ha__intent__HassTurnOff"
            ];
            # Not needed for a home assistant, and they keep the system prompt small.
            excluded_tools = [
              "shell"
              "file_write"
              "file_edit"
              "git_operations"
              "web_fetch"
              "web_search_tool"
              "browser"
              "browser_open"
              "browser_delegate"
              "text_browser"
              "screenshot"
              "image_gen"
              "pushover"
              "weather"
              "email_read"
              "email_search"
              # Unused HA tools. HassBroadcast was picked instead of HassTurnOn in tests.
              "ha__assist_satellite__HassBroadcast"
              "ha__intent__HassCancelAllTimers"
              "ha__todo__get_items"
              "ha__todo__HassListAddItem"
              "ha__todo__HassListCompleteItem"
              "ha__todo__HassListRemoveItem"
            ];
          };

          # The llama-server context is 32k, so keep the prompt and history well below it.
          runtime_profiles.assistant = {
            compact_context = true;
            deferred_builtin_tools = true;
            max_context_tokens = 24000;
          };

          skills.prompt_injection_mode = "compact";

          # Home Assistant "Device control" tools, limited to what is exposed to Assist.
          mcp.servers = [
            {
              name = "ha";
              transport = "http";
              url = "http://127.0.0.1:8123/api/mcp/assist";
              headers.Authorization = "Bearer $HA_TOKEN";
            }
          ];
          mcp_bundles.home.servers = [ "ha" ];

          channels.telegram.home = {
            enabled = true;
            bot_token = "$TELEGRAM_BOT_TOKEN";
          };

          peer_groups.telegram_home = {
            channel = "telegram.home";
            agents = [ "assistant" ];
            external_peers = [ "8660620274" ];
          };
        };
      };

      systemd.services.zeroclaw-assistant.serviceConfig.MemoryMax = "1G";

      sops.secrets.zeroclaw_env = { };
    };
}

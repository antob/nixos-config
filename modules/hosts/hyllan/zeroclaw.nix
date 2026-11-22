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

          # Telegram voice notes, transcribed by whisper-server on desktob (language detected there).
          transcription.enabled = true;
          providers.transcription.local_whisper.desktob = {
            uri = "http://10.64.1.6:8091/inference";
            timeout_secs = 60;
          };

          agents.assistant = {
            model_provider = "llamacpp.desktob";
            risk_profile = "assistant";
            runtime_profile = "assistant";
            channels = [ "telegram.home" ];
            # The reply/no-reply classifier is for group chats and costs a full LLM call per message.
            precheck.enabled = false;
            mcp_bundles = [ "home" ];
            transcription_provider = "local_whisper.desktob";
          };

          risk_profiles.assistant = {
            level = "supervised";
            # Every HA tool left after excluded_tools. A tool HA adds later asks for approval on Telegram.
            auto_approve = [
              "ha__homeassistant__GetLiveContext"
              "ha__llm__GetDateTime"
              "ha__intent__HassTurnOn"
              "ha__intent__HassTurnOff"
              "ha__script__play_music"
              "ha__script__announce"
              "ha__media_player__HassMediaPause"
              "ha__media_player__HassMediaUnpause"
              "ha__media_player__HassSetVolume"
              "ha__media_player__HassSetVolumeRelative"
              "ha__media_player__HassMediaPlayerMute"
              "ha__media_player__HassMediaPlayerUnmute"
              "ha__media_player__HassMediaNext"
              "ha__media_player__HassMediaPrevious"
              "ha__light__HassLightSet"
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
              # Generic media search and play: playing an artist made Music Assistant fetch every
              # track from every provider and time out. script.play_music asks MA directly.
              "ha__media_player__search_media"
              "ha__media_player__play_media"
            ];
          };

          # The llama-server context is 32k, so keep the prompt and history well below it.
          runtime_profiles.assistant = {
            compact_context = true;
            deferred_builtin_tools = true;
            max_context_tokens = 24000;
          };

          skills.prompt_injection_mode = "compact";

          # SHA-256 hashes. Runtime pairings would be lost: config.toml is re-rendered on start.
          gateway.paired_tokens = [
            "26d1643f5ab5a9b054865580177c36bafc8d7a5a528717947961264369017e97" # Home Assistant Assist
          ];

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

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

        bindReadOnlyPaths = {
          "${workspace}/IDENTITY.md" = ./_files/zeroclaw/IDENTITY.md;
          "${workspace}/SOUL.md" = ./_files/zeroclaw/SOUL.md;
          "${workspace}/USER.md" = ./_files/zeroclaw/USER.md;
        };

        settings = {
          schema_version = 4;

          # No fallback: the assistant stays private.
          providers.models.llamacpp.desktob = {
            uri = "http://10.64.1.6:8080/v1";
            model = "zeroclaw";
            api_key = "$LLAMA_API_KEY";
            timeout_secs = 90;
            # Guard against runaway generation (one request ran for 5 minutes).
            max_tokens = 1024;
          };

          transcription.enabled = true;

          # Voice replies after a Telegram voice note, through tts-bridge (Piper). The key is unused.
          # Disabled: Telegram does not autoplay voice messages. Set to true to re-enable.
          tts.enabled = false;
          providers.tts.openai.home = {
            uri = "http://127.0.0.1:10210/v1/audio/speech";
            api_key = "local";
            voice = "en_GB-jenny_dioco-medium";
            response_format = "opus";
          };
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
            mcp_bundles = [
              "home"
              "ops"
            ];
            transcription_provider = "local_whisper.desktob";
            tts_provider = "openai.home";
          };

          risk_profiles.assistant = {
            level = "supervised";
            # New HA tools still ask for approval.
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
              # Read-only hyllan diagnosis tools (hyllan-diag).
              "ops__failed_units"
              "ops__unit_status"
              "ops__log_units"
              "ops__logs"
              "ops__recent_failures"
              "ops__timers"
              "ops__zpool_status"
              "ops__disk_usage"
              "ops__deployed_generation"
              "ops__backup_status"
              "ops__syncthing_status"
              # Discovery of deferred tools, so the model finds the ops tools without asking each time.
              "tool_search"
            ];
            # Keeps the system prompt small.
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
              # The built-in backup tool manages ZeroClaw's own workspace backups and was picked
              # instead of ops__backup_status.
              "backup"
              "data_management"
              # Unused HA tools. HassBroadcast was picked instead of HassTurnOn in tests.
              "ha__assist_satellite__HassBroadcast"
              "ha__intent__HassCancelAllTimers"
              "ha__todo__get_items"
              "ha__todo__HassListAddItem"
              "ha__todo__HassListCompleteItem"
              "ha__todo__HassListRemoveItem"
              # Playing an artist through these made Music Assistant time out; use script.play_music.
              "ha__media_player__search_media"
              "ha__media_player__play_media"
            ];
          };

          # The llama-server context is 32k, so keep the prompt and history well below it.
          runtime_profiles.assistant = {
            compact_context = true;
            deferred_builtin_tools = true;
            max_context_tokens = 24000;
            max_tool_iterations = 15;
          };

          skills.prompt_injection_mode = "compact";

          # SHA-256 hashes. Runtime pairings would be lost: config.toml is re-rendered on start.
          gateway.paired_tokens = [
            "26d1643f5ab5a9b054865580177c36bafc8d7a5a528717947961264369017e97" # Home Assistant Assist
          ];

          mcp.servers = [
            {
              name = "ha";
              transport = "http";
              url = "http://127.0.0.1:8123/api/mcp/assist";
              headers.Authorization = "Bearer $HA_TOKEN";
            }
            {
              name = "ops";
              transport = "http";
              url = "http://127.0.0.1:10220/mcp";
              tool_timeout_secs = 30;
            }
          ];
          mcp_bundles.home.servers = [ "ha" ];
          mcp_bundles.ops.servers = [ "ops" ];

          channels.telegram.home = {
            enabled = true;
            bot_token = "$TELEGRAM_BOT_TOKEN";
            # Draft streaming; its final send queues the voice reply without the 10 s debounce.
            stream_mode = "partial";
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

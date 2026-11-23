{
  flake.modules.nixos.desktob = {
    # CTranslate2 has no ROCm build, so this runs on the CPU.
    services.wyoming.faster-whisper.servers.assist = {
      enable = true;
      sttLibrary = "faster-whisper";
      # Swedish fine-tune; downloaded from Hugging Face on first start (not pinned).
      model = "KBLab/kb-whisper-small";
      language = "sv";
      uri = "tcp://0.0.0.0:10300";
      zeroconf.enable = false;
      beamSize = 1;
      extraArgs = [
        "--compute-type"
        "int8"
        "--cpu-threads"
        "8"
        # Drops non-speech; silence otherwise comes back as subtitle credits.
        "--vad-filter"
      ];
    };

    # Wyoming has no authentication.
    networking.firewall.extraInputRules = ''
      iifname "wg0" ip saddr { 10.64.1.2 } tcp dport 10300 accept
    '';

    antob.persistence.directories = [ "/var/lib/private/wyoming/faster-whisper" ];
  };
}

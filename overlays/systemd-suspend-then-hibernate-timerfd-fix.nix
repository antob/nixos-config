# https://github.com/systemd/systemd/issues/38193 - suspend-then-hibernate's
# post-resume timerfd poll uses a 0 timeout, which can race the kernel and
# make it think a person woke the machine instead of the RTC alarm, silently
# skipping hibernation. See docs/systemd-suspend-then-hibernate-timerfd-bug.md.
#
# Not part of the shared overlay set: patching systemd means a from-source
# rebuild with no binary cache hit for anything depending on this derivation.
# Applied to laptob only, via its own nixpkgs.overlays.
final: prev: {
  systemd = prev.systemd.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/sleep/sleep.c \
        --replace-fail 'fd_wait_for_event(tfd, POLLIN, 0)' \
                        'fd_wait_for_event(tfd, POLLIN, 500 * 1000)'
    '';
  });
}

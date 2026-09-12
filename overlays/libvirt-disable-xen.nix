# We only use libvirtd/virt-manager for qemu:///system, never Xen. Disabling
# Xen support drops the xen -> openvswitch dependency chain, whose test suite
# (PMD/ALB tests requiring specific multi-core CPU topology) is flaky to the
# point of unbuildable in the nightly cache-build's Nix sandbox.
#
# This must be a global overlay rather than just `virtualisation.libvirtd.package`:
# programs.virt-manager pulls in libvirt-glib/libvirt-python, which depend on
# the plain pkgs.libvirt independently of the libvirtd service package.
final: prev: {
  libvirt = prev.libvirt.override { enableXen = false; };
}

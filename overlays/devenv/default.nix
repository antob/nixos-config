{ devenv, ... }:

final: prev: {
  devenv = devenv.packages."${prev.system}".devenv;
}

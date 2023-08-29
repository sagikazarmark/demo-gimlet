{
  description = "Gimlet demo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    gimlet.url = "github:sagikazarmark/nix-gimlet";
    gimlet.inputs.nixpkgs.follows = "nixpkgs";
    garden.url = "github:sagikazarmark/nix-garden";
    garden.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];

      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: rec {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;

          config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
            "ngrok"
          ];
        };

        devenv.shells = {
          default = {
            packages = with pkgs; [
              gh

              kind
              kubectl
              kustomize
              kubernetes-helm
              fluxcd

              ngrok

              rust-petname
            ] ++ [
              inputs'.gimlet.packages.gimlet-bin
              inputs'.garden.packages.garden
            ];

            env = {
              KUBECONFIG = "${config.devenv.shells.default.env.DEVENV_STATE}/kube/config";
              KIND_CLUSTER_NAME = "demo-gimlet";

              HELM_CACHE_HOME = "${config.devenv.shells.default.env.DEVENV_STATE}/helm/cache";
              HELM_CONFIG_HOME = "${config.devenv.shells.default.env.DEVENV_STATE}/helm/config";
              HELM_DATA_HOME = "${config.devenv.shells.default.env.DEVENV_STATE}/helm/data";
            };

            dotenv.disableHint = true;

            # https://github.com/cachix/devenv/issues/528#issuecomment-1556108767
            containers = pkgs.lib.mkForce { };
          };
        };
      };
    };
}

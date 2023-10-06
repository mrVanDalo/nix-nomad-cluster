{
  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-legacy_2211.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-legacy_2205.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-legacy_2105.url = "github:nixos/nixpkgs/nixos-21.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";

    sops-nix.url = "github:Mic92/sops-nix";
    nixinate.url = "github:matthewcroughan/nixinate";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    permown = {
      url = "github:mrVanDalo/module.permown";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , disko
    , dns
    , home-manager
    , nixinate
    , nixos-anywhere
    , nixos-hardware
    , nixpkgs
    , nixpkgs-legacy_2105
    , nixpkgs-legacy_2205
    , nixpkgs-legacy_2211
    , nixpkgs-unstable
    , permown
    , sops-nix
    }:
    let

      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (nixpkgs) lib;

      meta = rec {
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;

          overlays = [
            (_self: _super: {
              unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
              legacy_2211 = import nixpkgs-legacy_2211 {
                inherit system;
              };
              legacy_2205 = import nixpkgs-legacy_2205 {
                inherit system;
              };
              legacy_2105 = nixpkgs-legacy_2105 {
                inherit system;
              };
            })
          ];
        };
        specialArgs = { };
      };

      nixosConfigurationSetup =
        { name
        , host ? "${name}.private"
        , modules
        }:

        lib.nixosSystem {
          inherit (meta) system specialArgs pkgs;
          modules = modules ++ defaultModules ++ [
            {
              _module.args.nixinate = {
                host = host;
                sshUser = "root";
                buildOn = "remote"; # valid args are "local" or "remote"
                substituteOnTarget = false; # if buildOn is "local" then it will substitute on the target, "-s"
                hermetic = false;
              };
            }
            {
              imports = [
                ./nixos/${name}/configuration.nix
              ];
            }
          ];
        };

      defaultModules = [

        {
          # todo : find out what this is?
          # make flake inputs accessiable in NixOS
          _module.args.self = self;
          _module.args.inputs = self.inputs;
        }

        ({ pkgs, lib, ... }:

          {
            nix = {
              # no channesl needed this way
              nixPath = [ "nixpkgs=${pkgs.path}" ];
              # make flakes available
              package = pkgs.nixUnstable;
              extraOptions = ''
                experimental-features = nix-command flakes
              '';
            };
          })

        { nix.settings.substituters = [ "https://cache.nixos.org/" ]; }

        {
          boot.tmp.useTmpfs = lib.mkDefault true;
          imports = [
            permown.nixosModules.permown
            disko.nixosModules.disko
          ];
        }

      ];
      final = pkgs;

      generateNixOSAnywhere = flake:
        let
          machines = builtins.attrNames flake.nixosConfigurations;
          validMachines = final.lib.remove "" (final.lib.forEach machines (x: final.lib.optionalString (flake.nixosConfigurations."${x}"._module.args ? nixinate) "${x}"));
          mkDeployScript = { machine, dryRun }:
            let
              n = flake.nixosConfigurations.${machine}._module.args.nixinate;
              user = n.sshUser or "root";
              host = n.host;

              script =
                ''
                  set -e
                  echo "👤 SSH User: ${user}"
                  echo "🌐 SSH Host: ${host}"
                  echo
                  echo "🧹 nixos-anywhere --flake .#${machine} root@${host}"
                  echo "🧹 ${nixos-anywhere.packages.${system}.nixos-anywhere}/bin/nixos-anywhere --flake .#${machine} root@${host}"
                  echo
                '';
            in
            final.writeScript "deploy-${machine}.sh" script;
        in
        {
          nixos-anywhere = nixpkgs.lib.genAttrs validMachines (x:
            {
              type = "app";
              program = toString (mkDeployScript {
                machine = x;
                dryRun = false;
              });
            });
        };


    in
    {
      devShells.${system}.default =
        pkgs.mkShell {
          buildInputs = [
            pkgs.awscli2
            (pkgs.writers.writeDashBin "sshuttle" ''
              ${pkgs.sshuttle}/bin/sshuttle \
                -r root@65.21.159.93 \
                10.0.0.0/8
            '')
          ];
        };

      apps = (nixinate.nixinate.x86_64-linux self) // (generateNixOSAnywhere self);

      nixosConfigurations =
        {
          jumphost = nixosConfigurationSetup {
            name = "jumphost";
            host = "65.21.159.93";
            modules = [
              ./nixos/jumphost/configuration.nix
            ];
          };
        };
    };
}







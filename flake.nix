{
  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-legacy_2211.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-legacy_2205.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-legacy_2105.url = "github:nixos/nixpkgs/nixos-21.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";

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
            (import ./nixos/pkgs)
          ];
        };
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
                ./nixos/machines/${name}/configuration.nix
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

    in
    {
    devShells.${system}.default =
             pkgs.mkShell {
               buildInputs = [
                 pkgs.awscli2
               ];
             };

      apps = nixinate.nixinate.x86_64-linux self;

      nixosConfigurations =
        {
          sternchen = nixosConfigurationSetup {
            name = "sternchen";
            host = "sternchen.secret";
            modules = [
              nixos-hardware.nixosModules.lenovo-thinkpad-x220
            ];
          };
        };
    };
}







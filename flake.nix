{
  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-legacy_2211.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-legacy_2205.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-legacy_2105.url = "github:nixos/nixpkgs/nixos-21.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-images.url = "github:nix-community/nixos-images";

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
    , nixos-images
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
        specialArgs = { inherit machines; };
      };

      defaultModules = [
        {
          _module.args.self = self;
          # make flake inputs accessiable in NixOS
          _module.args.inputs = self.inputs;
        }
        ({ pkgs, lib, ... }: {
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
        {
          boot.tmp.useTmpfs = lib.mkDefault true;
          imports = [
            permown.nixosModules.permown
            disko.nixosModules.disko
          ];
        }
      ];

      final = pkgs;
      allMachines = import ./machines lib;
      machines = allMachines.machines;
      filteredMachines = f: builtins.filter f machines;
      mapListToAttr = f: l: builtins.listToAttrs (builtins.map f l);

      generateNixOSAnywhere = flake:
        let
          machines = builtins.attrNames flake.nixosConfigurations;
          validMachines = final.lib.remove "" (final.lib.forEach machines (x: final.lib.optionalString (flake.nixosConfigurations."${x}"._module.args ? nixinate) "${x}"));
          mkDeployScript = { machine, dryRun }:
            let
              n = flake.nixosConfigurations.${machine}._module.args.nixinate;
              c = flake.nixosConfigurations.${machine}._module.args.cluster;
              user = n.sshUser or "root";
              host = n.host;
              # todo : use c.cachehosts
              #substitute = if !builtins.elem c.role [ "cache" "gateway" ] then "--option trusted-substituters http://10.0.0.3 --option substituters http://10.0.0.3" else "";
              #substitute = if !builtins.elem c.role [ "cache" "gateway" ] then "--option trusted-substituters http://10.0.0.3 --option substituters http://10.0.0.3 --option builders-use-substitutes true" else "";
              substitute = "";
              script =
                ''
                  set -e
                  echo "👤 SSH User: ${user}"
                  echo "🌐 SSH Host: ${host}"
                  echo
                  echo "🧹 nixos-anywhere ${substitute} --build-on-remote -L --flake .#${machine} root@${host}"
                  ${pkgs.gum}/bin/gum confirm "Really want to Re-Initalize (format) $machine?" || exit 0
                  ${nixos-anywhere.packages.${system}.nixos-anywhere}/bin/nixos-anywhere ${substitute} -L --build-on-remote --flake .#${machine} root@${host}
                  echo
                '';
            in
            final.writeScript "deploy-${machine}.sh" script;
        in
        {
          init = nixpkgs.lib.genAttrs validMachines (x:
            {
              type = "app";
              program = toString (mkDeployScript {
                machine = x;
                dryRun = false;
              });
            });
        };


      substituterModule = { role, ... }: {
        imports = [
          { nix.settings.substituters = [ "https://cache.nixos.org/" ]; }
          (if !builtins.elem role [ "cache" "gateway" ] then {
            nix.settings.substituters = map ({ private_ipv4, ... }: "http://${private_ipv4}") allMachines.cachehosts;
            # fixme: hardcoded and unsecure!
            nix.settings.trusted-public-keys = [ "nomad-cluster-cache:9N2kLCc7dUndvNy7ZgO13R19ByA9JmI6dYhE8MzwIOw=" ];
          } else { })
        ];
      };

    in
    {
      devShells.${system}.default =
        pkgs.mkShell {
          buildInputs = [
            pkgs.awscli2
          ];
        };

      apps = {
        ${system} = {

          sshuttle = {
            type = "app";
            program =
              let
                machinesList = pkgs.writeText "machines" (lib.concatStringsSep "\n" (map ({ id, ... }: id) allMachines.jumphosts));
              in
              toString (pkgs.writers.writeBash "gummy-all" ''
                set -e
                export PATH=${pkgs.gum}/bin:${pkgs.findutils}/bin:$PATH
                machine=$( cat ${machinesList} | gum filter )
                job=sshuttle
                nix run .#apps.$job.$machine
              '');
          };
          default = {
            type = "app";
            program =
              let
                machinesList = pkgs.writeText "machines" (lib.concatStringsSep "\n" (map ({ id, ... }: id) machines));
              in
              toString (pkgs.writers.writeBash "gummy-all" ''
                set -e
                export PATH=${pkgs.gum}/bin:${pkgs.findutils}/bin:$PATH
                machine=$( cat ${machinesList} | gum filter )
                job=$( gum choose nixinate init )
                nix run .#apps.$job.$machine
              '');
          };
        };
      } //
      (nixinate.nixinate.x86_64-linux self) //
      (generateNixOSAnywhere self) //
      {
        sshuttle = mapListToAttr
          ({ name, id, public_ipv4, ... }: {
            name = id;
            value =
              {
                type = "app";
                program = toString (pkgs.writers.writeDash "sshuttle" ''
                  ${pkgs.sshuttle}/bin/sshuttle \
                    -r root@${public_ipv4} \
                    10.0.0.0/8
                '');
              };
          })
          allMachines.jumphosts;
      } //
      {
        cacheupdate = mapListToAttr
          ({ name, id, private_ipv4, ... }: {
            name = id;
            value =
              let
                inherit (pkgs.lib) getExe optionalString concatStringsSep;
                nix = "${getExe pkgs.nix}";
                nixOptions = "";
                flake = self;
                user = "root";
                cacheHost = private_ipv4;
                nixos-rebuild = "${getExe pkgs.nixos-rebuild}";
                openssh = "${getExe pkgs.openssh}";
                flock = "${getExe final.flock}";
                commands = map
                  ({ id, name, ... }: ''
                    echo "🤞 build configuration for ${name} on ${cacheHost}"
                    ( set -x; ${openssh} -t ${user}@${cacheHost} "sudo flock -w 60 /dev/shm/nixinate-${id} nixos-rebuild build --flake ${flake}#${id}" )
                    ( set -x; ${openssh} -t ${user}@${cacheHost} "sudo flock -w 60 /dev/shm/nix-images-${id} nix build #${id}" )
                  '')
                  allMachines.machines;
              in
              {
                type = "app";
                program = toString (pkgs.writers.writeDash "update" ''
                  echo "🚀 Sending flake to ${cacheHost} via nix copy:"
                  ( set -x; ${nix} ${nixOptions} copy ${flake} --to ssh://${user}@${cacheHost} )
                  ${concatStringsSep "\n" commands}
                '');
              };
          })
          allMachines.cachehosts;
      };

      colmena = {
        meta = {
          nixpkgs = meta.pkgs;
          specialArgs = meta.specialArgs;
        };
      } // {
        meta.nodeSpecialArgs =
          (mapListToAttr (
            (machine@{ id, ... }:
              {
                name = id;
                value = { inherit machine; };
              }
            )
          ));
      } // (mapListToAttr
        (machine@{ name, id, public_ipv4, private_ipv4, tags, role, environment, ... }:
          {
            name = id;
            value = {
              imports = [
                {
                  deployment.targetHost = if public_ipv4 != "" then public_ipv4 else private_ipv4;
                  deployment.tags = "${role},${environment}";
                  deployment.buildOnTarget = true;
                }
                {
                  networking.hostName = name;
                }
                ({ modulesPath, ... }: {
                  imports = [
                    (modulesPath + "/installer/scan/not-detected.nix")
                    (modulesPath + "/profiles/qemu-guest.nix")
                  ];
                })
                ./nixos/roles/${tags.role}
                ./nixos/components
              ];
            };
          })
        machines);

      nixosConfigurations = (mapListToAttr
        (machine@{ name, id, public_ipv4, private_ipv4, role, ... }:
          {
            name = id;
            value = lib.nixosSystem {
              inherit (meta) system pkgs;
              specialArgs = meta.specialArgs // { inherit machine; };
              modules = defaultModules ++ [
                {
                  _module.args.nixinate = {
                    host = if public_ipv4 != "" then public_ipv4 else private_ipv4;
                    sshUser = "root";
                    buildOn = "remote"; # valid args are "local" or "remote"
                    substituteOnTarget = false; # if buildOn is "local" then it will substitute on the target, "-s"
                    hermetic = false;
                  };
                }
                {
                  _module.args.cluster = {
                    inherit (machine) name id role;
                    inherit (allMachines) machines jumphosts cachehosts;
                  };
                }
                (substituterModule machine)
                { networking.hostName = name; }
                ({ modulesPath, ... }: {
                  imports = [
                    (modulesPath + "/installer/scan/not-detected.nix")
                    (modulesPath + "/profiles/qemu-guest.nix")
                  ];
                })
                ./nixos/roles/${role}
                ./nixos/components
              ];
            };

          })
        machines);
    };
}







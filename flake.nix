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
    cluster.url = path:./cluster-flake;
  };

  outputs =
    { self
    , disko
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
    , cluster
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

      defaultModules = [
        {
          # make flake accessiable in NixOS
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

      machines = import ./machines lib;

      # todo : rename to machines.all
      cacheHost = builtins.head machines.cachehosts;

      mapListToAttr = f: l: builtins.listToAttrs (builtins.map f l);

      # todo : cluster-flake
      generateBuildKexec = flake:
        with pkgs.lib;
        let
          machines = builtins.attrNames flake.nixosConfigurations;
          validMachines = filter
            (machine:
              (flake.nixosConfigurations."${machine}"._module.args ? nixinate) &&
              (flake.nixosConfigurations."${machine}"._module.args ? cluster)
            )
            machines;
          cacheMachines = filter
            (machine: flake.nixosConfigurations."${machine}"._module.args.cluster.role == "cache")
            validMachines;
          mkDeployScript = machine:
            let
              n = flake.nixosConfigurations.${machine}._module.args.nixinate;
              c = flake.nixosConfigurations.${machine}._module.args.cluster;
              user = n.sshUser or "root";
              host = n.host;
              openssh = getExe pkgs.openssh;
              nix = getExe pkgs.nix;
              nixOptions = n.nixOptions or "";
            in
            pkgs.writers.writeBash "deploy-${machine}.sh"
              ''
                echo "🚀 Sending flake to ${host} via nix copy:"
                ( set -x; ${nix} ${nixOptions} copy ${flake} --to ssh://${user}@${host} )
                ( set -x; ${openssh} -t ${user}@${host} "sudo flock -w 60 /dev/shm/buildCacheImage nix build --out-link /srv/downloads ${flake}#cachedInstaller" )
              '';
        in
        {
          build-kexec = nixpkgs.lib.genAttrs cacheMachines (machine:
            {
              type = "app";
              program = toString (mkDeployScript machine);
            }
          );
        };

      # todo : cluster-flake
      # todo : put this in a component
      substituterModule = { role, ... }: {
        imports = [
          { nix.settings.substituters = [ "https://cache.nixos.org/" ]; }
          (if !builtins.elem role [ "cache" "gateway" ] then {
            nix.settings.substituters = map ({ private_ipv4, ... }: "http://${private_ipv4}") machines.cachehosts;
            # fixme: hardcoded and unsecure!
            nix.settings.trusted-public-keys = [ "nomad-cluster-cache:9N2kLCc7dUndvNy7ZgO13R19ByA9JmI6dYhE8MzwIOw=" ];
          } else { })
        ];
      };

    in
    {

      packages.${system} = {
        default = self.packages.${system}.cachedInstaller;
        # todo : cluster-flake
        cachedInstaller =
          (pkgs.nixos ([
            {
              nix.settings.substituters =
                let
                  privateCache = map ({ private_ipv4, ... }: "http://${private_ipv4}") machines.cachehosts;
                in
                privateCache ++ [ "https://cache.nixos.org" ];
              # todo: use proper key here
              nix.settings.trusted-public-keys = [ "nomad-cluster-cache:9N2kLCc7dUndvNy7ZgO13R19ByA9JmI6dYhE8MzwIOw=" ];
            }
            { system.kexec-installer.name = "nixos-kexec-installer-noninteractive"; }
            nixos-images.nixosModules.noninteractive
            nixos-images.nixosModules.kexec-installer
          ])).config.system.build.kexecTarball;
      };

      apps = {
        ${system} = {
          sshuttle = {
            type = "app";
            program =
              let
                machinesList = pkgs.writeText "machines" (lib.concatStringsSep "\n" (map ({ id, ... }: id) machines.jumphosts));
              in
              toString (pkgs.writers.writeBash "gummy-all" ''
                set -e
                export PATH=${pkgs.gum}/bin:${pkgs.findutils}/bin:$PATH
                machine=$( cat ${machinesList} | gum filter )
                job=sshuttle
                nix run .#apps.$job.$machine
              '');
          };
          cost = {
            type = "app";
            program =
              let
                machinesList = pkgs.writeText "machines" (lib.concatStringsSep "\n" (map ({ id, ... }: id) machines));
              in
              toString (pkgs.writers.writeBash "gummy-all" ''
                set -e
                export PATH=${pkgs.gojq}/bin:$PATH
                cat machines/*.json | gojq '.tags.cost | tonumber' | gojq --slurp --raw-output 'add | "Monthly Costs \(.)€\nDaily Costs \(. / 30)€"'
              '');
          };
          default = {
            type = "app";
            program =
              let
                machinesList = pkgs.writeText "machines" (lib.concatStringsSep "\n" (map ({ id, ... }: id) machines.all));
              in
              toString (pkgs.writers.writeBash "gummy-all" ''
                set -e
                export PATH=${pkgs.gum}/bin:${pkgs.findutils}/bin:$PATH
                machine=$( cat ${machinesList} | gum filter )
                job=$( gum choose apply init )
                nix run .#apps.$job.$machine
              '');
          };
        };
      } //
      (cluster.cluster self) //
      (generateBuildKexec self) //
      {
        sshuttle = mapListToAttr
          ({ name, id, public_ipv4, nameserver, cidr, ... }: {
            name = id;
            value =
              {
                type = "app";
                program = toString (pkgs.writers.writeBash "sshuttle" ''
                  dns=$( ${lib.getExe pkgs.gum} choose DNS noDNS )
                  if [[ $dns == DNS ]]
                  then
                    (set -x; ${lib.getExe pkgs.sshuttle} -r root@${public_ipv4} --dns --ns-hosts ${nameserver} ${cidr})
                  else
                    (set -x; ${lib.getExe pkgs.sshuttle} -r root@${public_ipv4} ${cidr})
                  fi
                '');
              };
          })
          machines.jumphosts;
      };

      nixosConfigurations = (mapListToAttr
        (machine@{ name, id, public_ipv4, private_ipv4, role, ... }:
          {
            name = id;
            value = lib.nixosSystem {
              inherit (meta) system pkgs;
              specialArgs = meta.specialArgs // {
                machines = machines.all;
                inherit machine;
                toplevelDomain = "cluster";
              };
              modules = defaultModules ++ [
                {
                  _module.args.nixinate = {
                    host = if public_ipv4 != "" then public_ipv4 else private_ipv4;
                    sshUser = "root";
                    buildOn = "remote"; # valid args are "local" or "remote"
                    substituteOnTarget = false; # if buildOn is "local" then it will substitute on the target, "-s"
                    hermetic = false;
                  };
                  _module.args.cluster = {
                    inherit (machine) name id role;
                    inherit (machines) all jumphosts cachehosts;
                    toplevelDomain = "cluster";
                  } // (
                    if (
                      # cache and gateway can't be initialized by the cache hosted kexec installer
                      role != "cache" || role != "gateway"
                    ) then {
                      kexec = "http://${cacheHost.private_ipv4}/downloads/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz";
                    } else { }
                  );
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
        machines.all);
    };
}







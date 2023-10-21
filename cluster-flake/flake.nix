{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixinate.url = "github:matthewcroughan/nixinate";
  };

  outputs =
    { self
    , nixinate
    , nixos-anywhere
    , nixpkgs
    }:
    let

      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (nixpkgs) lib;

      generateCacheUpdate = flake:
        # todo : with lib;
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
              commands = map
                (name: ''
                  echo "🤞 build configuration for ${name} on ${machine} (${host})"
                  ( set -x; ${openssh} -t ${user}@${host} "sudo flock -w 60 /dev/shm/nixinate-${name} nixos-rebuild build --flake ${flake}#${name}" )
                '')
                validMachines;
            in
            pkgs.writers.writeBash "deploy-${machine}.sh"
              ''
                echo "🚀 Sending flake to ${host} via nix copy:"
                ( set -x; ${nix} ${nixOptions} copy ${flake} --to ssh://${user}@${host} )
                ${concatStringsSep "\n" commands}
              '';
        in
        {
          update-cache = nixpkgs.lib.genAttrs cacheMachines (machine:
            {
              type = "app";
              program = toString (mkDeployScript machine);
            }
          );
        };

      generateInit = flake:
        with pkgs.lib;
        let
          machines = builtins.attrNames flake.nixosConfigurations;
          validMachines = filter
            (machine:
              (flake.nixosConfigurations."${machine}"._module.args ? nixinate) &&
              (flake.nixosConfigurations."${machine}"._module.args ? cluster)
            )
            machines;
          mkDeployScript = machine:
            let
              n = flake.nixosConfigurations.${machine}._module.args.nixinate;
              c = flake.nixosConfigurations.${machine}._module.args.cluster;
              user = n.sshUser or "root";
              host = n.host;
              kexec = optionalString (c ? kexec) "--kexec \"${c.kexec}\"";
              command = "nixos-anywhere --build-on-remote ${kexec} --flake .#${machine} root@${host}";
              script =
                ''
                  set -e
                  export PATH=${nixos-anywhere.packages.${system}.nixos-anywhere}/bin:${pkgs.gum}/bin:$PATH

                  echo "👤 SSH User: ${user}"
                  echo "🌐 SSH Host: ${host}"
                  echo
                  echo "🍕 ${command}"
                  gum confirm "Really want to Re-Initalize ${machine}?" || exit 0
                  ${command}
                '';
            in
            pkgs.writers.writeBash "deploy-${machine}.sh" script;
        in
        {
          init = nixpkgs.lib.genAttrs validMachines (machine:
            {
              type = "app";
              program = toString (mkDeployScript machine);
            }
          );
        };

      # map nixinate to apply app
      generateApply = flake: {
        apply = (nixinate.nixinate.x86_64-linux flake).nixinate;
      };

    in
    {

      # todo : add parallel execution
      # todo : add option to toggle gum confirm on init
      cluster = flake:
        (generateApply flake) //
        (generateInit flake) //
        (generateCacheUpdate flake);
    };
}

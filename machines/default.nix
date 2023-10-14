lib:
let

  machines = map
    (name: lib.importJSON ./${name})
    (builtins.attrNames (lib.filterAttrs
      (name: type: type == "regular" && builtins.match ".*\\.json" name != null)
      (builtins.readDir ./.)));
in
{
  inherit machines;

  jumphosts = builtins.filter ({ public_ipv4, ... }: public_ipv4 != "") machines;
  cachehosts = builtins.filter ({ role, ... }: role == "cache") machines;

  # machines by environment

  # machines by environment.role

}

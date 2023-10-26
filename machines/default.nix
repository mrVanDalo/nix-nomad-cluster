lib:
let

  all = map
    (name: lib.importJSON ./${name})
    (builtins.attrNames (lib.filterAttrs
      (name: type: type == "regular" && builtins.match ".*\\.json" name != null)
      (builtins.readDir ./.)));
in
{
  inherit all;
  jumphosts = builtins.filter ({ public_ipv4, ... }: public_ipv4 != "") all;
  cachehosts = builtins.filter ({ role, ... }: role == "cache") all;

  # machines by environment

  # machines by environment.role

}

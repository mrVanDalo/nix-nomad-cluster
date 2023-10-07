lib:
{
  machines = map
    (name: lib.importJSON ./${name})
    (builtins.attrNames (lib.filterAttrs
      (name: type: type == "regular" && builtins.match ".*\\.json" name != null)
      (builtins.readDir ./.)));

  # machines by environment

  # machines by environment.role

}

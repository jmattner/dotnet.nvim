# dotnet.nvim

tooling to replace lost functionality moving from other tools
based loosely on easy-dotnet, but written in an opinionated way for my workflow

## TODO

- name buffer?
- toggle run window
- highlights etc. for printing command
- create a DotNET command
- handle nerdfonts in the output buffer
- build out opts object in setup call, with defaults etc.
- add handling for other shells
- only make command and bindings available in .net solutions
  - command to load in non-.net slns in case of failure to detect
- clean command
- build command
  - find and select builds from sln or proj
  - manual entry of configuration?
- run command
  - find and select dlls etc.
  - manual entry of dll?
- sql server dacpac tooling? - might belong elsewhere
- nuget mgmt
- package reference mgmt

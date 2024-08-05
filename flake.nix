{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/master";
  inputs.yandex-browser.url = "github:Teu5us/nix-yandex-browser";
  inputs.yandex-browser.inputs.nixpkgs.follows = "nixpkgs";
  inputs.last-working-dbeaver-bin.url = "github:nixos/nixpkgs/4d10225ee46c0ab16332a2450b493e0277d1741a";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  outputs = { self, nixpkgs
  , last-working-dbeaver-bin
  , nixos-hardware
  , yandex-browser
  }@inputs: {
    nixosConfigurations.a7 = nixpkgs.lib.nixosSystem {
      modules = [ 
        ./configuration.nix
        nixos-hardware.nixosModules.common-gpu-amd
        nixos-hardware.nixosModules.common-cpu-amd
        nixos-hardware.nixosModules.common-cpu-amd-pstate
      ];
      specialArgs.inputs = inputs;
      system = "x86_64-linux";
    };
  };
}

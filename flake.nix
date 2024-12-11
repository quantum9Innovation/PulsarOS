{

  # /*****                                                  /******   /****
  # |*    *|  |*   |  |*       ****     **    *****        |*    |  /*    *
  # |*    *|  |*   |  |*      /*       /* *   |*   |      |*    |  |*
  # |*****/   |*   |  |*       ****   /*   *  |*   /     |*    |   ******
  # |         |*   |  |*           |  ******  *****     |*    |         |
  # |         |*   |  |*       *   |  |*   |  |*  *    |*    |   *     |
  # |          ****    *****    ****  |*   |  |*   *   ******    *****
  #
  #  ==========================================================================

  # This is the default PulsarOS system configuration flake.
  # It is the entry point for all PulsarOS-based systems.
  # You should include a specific version of this flake as an input
  # in your system configuration flake and then use the provided `make`
  # function to build your system using your own Pulsar configuration.
  description = "PulsarOS system configuration flake";

  inputs = {
    # PulsarOS uses the latest nixpkgs channel,
    # so new (but somewhat? stable) packages are used by default.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";

    # For incorporating hotfixes
    nixpkgs-upstream.url = "github:nixos/nixpkgs/nixos-unstable-small";

    # Home Manager manages user dotfiles in the Nix configuration language,
    # enhancing interoperability and consolidation of system configurations.
    # You should use Home Manager integrations
    # to configure all installed applications
    # in order to ensure complete reproducibility.
    # Home Manager is a critical system package
    # and is pinned to a specific release.
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Up-and-coming packages that have yet to be merged into nixpkgs at any level;
    # this is the bleeding edge of software development
    zen-browser.url = "github:youwen5/zen-browser-flake";

    # Lanzaboote is needed for NixOS to work when secure boot is enabled.
    # Incorrect Lanzaboote configurations could lead to an unbootable OS.
    # Lanzaboote is a critical system package
    # and is pinned to a specific release.
    # Enabling secure boot is not recommended for servers,
    # but can be done anyway with appropriate configuration.
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-upstream,
      home-manager,
      zen-browser,
      lanzaboote,
      ...
    }@inputs:
    {
      make =
        {
          hostname,
          user,
          name,
          git,
          hardware,
          system ? "x86_64-linux",
          kernel ? "zen",
          secureboot ? {
            enabled = false;
          },
          stateVersion ? "24.11",
          systemPackages,
          homePackages,
          autoLogin ? true,
          ssh ? {
            enabled = true;
          },
          locale ? "en_US.UTF-8",
          hyprland ? {
            mod = "SUPER";
          },
          graphics ? {
            opengl = true;
            nvidia = {
              enabled = false;
              intelBusId = null;
              nvidiaBusId = null;
            };
          },
          audio ? {
            jack = false;
          },
          overrides ? [ ],
          homeOverrides ? [ ],
          ollama ? false,
          ...
        }@pulsar:
        let
          # Secure boot configuration
          secureBoot = [
            lanzaboote.nixosModules.lanzaboote

            (
              { pkgs, lib, ... }:
              {
                environment.systemPackages = [
                  # For debugging and troubleshooting secure boot
                  pkgs.sbctl
                ];

                # Lanzaboote currently replaces the systemd-boot module.
                # This setting is usually set to true in configuration.nix,
                # generated at installation time.
                # So we force it to false for now.
                boot.loader.systemd-boot.enable = lib.mkForce false;

                boot.lanzaboote = {
                  enable = true;
                  pkiBundle = "/etc/secureboot";
                };
              }
            )
          ];

          # Modules without conditional add-ons
          baseModules = [
            # Primary system configuration module
            ./configuration.nix

            # Home Manager setup
            home-manager.nixosModules.home-manager
            {
              # Install from preconfigured nixpkgs channel
              home-manager.useGlobalPkgs = true;

              # Enable user packages for `nixos-rebuild build-vm`
              home-manager.useUserPackages = true;

              # Home Manager backup files will end in .backup
              home-manager.backupFileExtension = "backup";

              home-manager.users.${user} = {
                # Primary user Home Manager configuration module
                imports =
                  let
                    pack = [
                      zen-browser.packages."${system}".default
                    ];
                  in
                  [
                    (import ./home.nix pulsar nixpkgs-upstream.legacyPackages.${system}.hyprlandPlugins pack)
                  ]
                  ++ homeOverrides;
              };
            }
          ];

          # Modules with conditional add-ons
          modules = if secureboot.enabled then baseModules ++ secureBoot else baseModules;
        in
        {
          system = nixpkgs.lib.nixosSystem {
            # Forward external configurations to declared modules
            specialArgs = {
              inherit inputs;
              inherit pulsar;
            };

            # Official support is currently for x86_64-linux only
            system = system;

            # This does the heavy lifting of configuring the system
            modules = modules;
          };
        };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}

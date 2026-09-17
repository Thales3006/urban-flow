{
  description = "Urban Flow dev environment: Godot editor + Android SDK/NDK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Godot only: 25.11 is pinned to 4.5.1, so pull the editor + export
    # templates from unstable to get 4.6+ (full Android SAF Save dialog).
    # Everything else (Android SDK/NDK, JDK) stays on 25.11.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

        android = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "35" ];
          buildToolsVersions = [ "35.0.0" ];

          includeNDK = true;
          ndkVersions = [ "28.2.13676358" ];

          cmakeVersions = [ "3.22.1" ];
        };

        toolchainLinkDir = "$HOME/.cache/urban-flow-toolchain";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs-unstable.godot_4
            pkgs-unstable.godot_4-export-templates-bin
            pkgs.jdk17
            android.androidsdk

            pkgs.sqlite-interactive
          ];

          ANDROID_SDK_ROOT = "${android.androidsdk}/libexec/android-sdk";
          ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
          ANDROID_NDK_ROOT = "${android.androidsdk}/libexec/android-sdk/ndk/28.2.13676358";

          JAVA_HOME = "${pkgs.jdk17}";

          shellHook = ''
            mkdir -p "${toolchainLinkDir}"
            ln -sfn "$ANDROID_SDK_ROOT" "${toolchainLinkDir}/android-sdk"
            ln -sfn "$JAVA_HOME" "${toolchainLinkDir}/jdk"

            # Godot looks up export templates at a hardcoded path under
            # ~/.local/share/godot (no env var override, same deal as the
            # Editor Settings SDK/JDK paths above) -- keep it pointed at
            # the Nix-provided package. Link whatever version dir the package
            # ships so this survives Godot version bumps without editing here.
            mkdir -p "$HOME/.local/share/godot/export_templates"
            for tpl in ${pkgs-unstable.godot_4-export-templates-bin}/share/godot/export_templates/*; do
              ln -sfn "$tpl" "$HOME/.local/share/godot/export_templates/$(basename "$tpl")"
            done

            echo "Urban Flow dev environment ready."
            echo "Godot editor: godot --editor . (run from the repo root)"
            echo ""
            echo "One-time Godot setup: Editor Settings > Export > Android, set:"
            echo "  Android SDK Path: ${toolchainLinkDir}/android-sdk"
            echo "  Java SDK Path:    ${toolchainLinkDir}/jdk"
            echo "(these are stable symlinks kept up to date by this shellHook, so they"
            echo " survive Nix store path changes -- set them once, never touch again)"
          '';
        };
      }
    );
}

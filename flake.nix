{
  description = "Urban Flow dev environment: Godot editor + Android SDK/NDK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
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
            pkgs.godot_4
            pkgs.godot_4-export-templates-bin
            pkgs.jdk17
            android.androidsdk
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
            # the Nix-provided package matching this exact Godot version.
            mkdir -p "$HOME/.local/share/godot/export_templates"
            ln -sfn "${pkgs.godot_4-export-templates-bin}/share/godot/export_templates/4.5.1.stable" \
              "$HOME/.local/share/godot/export_templates/4.5.1.stable"

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

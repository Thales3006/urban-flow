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

        # Stable, never-changes-path symlinks pointing at the current
        # Nix store paths for the Android SDK and JDK. Nix store paths are
        # content-hashed and change on every rebuild, but Godot's Editor
        # Settings (Export > Android > SDK/Java Path) only accept a literal
        # path -- no env var expansion, no auto-detection. Point Editor
        # Settings at these symlinks ONCE; the shellHook below re-targets
        # them to whatever the current derivation is every time you enter
        # this shell, so the GUI config never goes stale.
        toolchainLinkDir = "$HOME/.cache/urban-flow-toolchain";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.godot_4
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

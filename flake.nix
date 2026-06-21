{
  description = "Urban Flow dev environment: Godot editor + prediction server";

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

        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            fastapi
            uvicorn
            numpy
            tensorflow
            python-multipart
            keras
            pillow
          ]
        );
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.godot_4

            pkgs.jdk17

            android.androidsdk
          ];

          ANDROID_SDK_ROOT = "${android.androidsdk}/libexec/android-sdk";
          ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
          ANDROID_NDK_ROOT = "${android.androidsdk}/libexec/android-sdk/ndk/28.2.13676358";

          JAVA_HOME = "${pkgs.jdk17}";

          shellHook = ''
            echo "Urban Flow dev environment ready."
            echo "Godot editor: godot --editor . (run from the repo root)"
            echo "Prediction server: cd server_predict && uvicorn server:app --reload"

            SETTINGS="$HOME/.config/godot/editor_settings-4.tres"
            if [ -f "$SETTINGS" ]; then
              sed -i "s|export/android/android_sdk_path = \".*\"|export/android/android_sdk_path = \"$ANDROID_SDK_ROOT\"|" "$SETTINGS"
              sed -i "s|export/android/java_sdk_path = \".*\"|export/android/java_sdk_path = \"$JAVA_HOME\"|" "$SETTINGS"
              echo "✓ Godot Android settings atualizados."
            else
              echo "Editor settings não encontrado. Abra o Godot uma vez primeiro, depois re-entre no shell."
            fi
          '';
        };

        packages.default = pythonEnv;
      }
    );
}

{
  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      system = "${system}";
      config.allowUnfree = true;
      config.android_sdk.accept_license = true;
    };
    buildToolsVersion = "33.0.1";
    androidComposition = pkgs.androidenv.composeAndroidPackages {
      buildToolsVersions = [ buildToolsVersion "28.0.3" "34.0.0" ];
      platformVersions = [ "36" "34" ];
      abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
      cmakeVersions = [ "3.22.1" ];
      includeNDK = true;
      ndkVersions = [ "28.2.13676358" ];
      includeEmulator = false;
      includeSystemImages = false;
    };
    androidSdk = androidComposition.androidsdk;
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.flutter
        pkgs.jdk21_headless
        pkgs.git
        androidSdk
      ];
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk/28.2.13676358";
      shellHook = "echo 'climbing_notes dev activated'";
    };
  };
}

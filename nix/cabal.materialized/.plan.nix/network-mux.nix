{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  {
    flags = { asserts = false; ipv6 = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "network-mux"; version = "0.1.0.0"; };
      license = "Apache-2.0";
      copyright = "2019 Input Output (Hong Kong) Ltd.";
      maintainer = "duncan@well-typed.com, marcin.szamotulski@iohk.io, marc.fontaine@iohk.io, karl.knutsson@iohk.io, alex@well-typed.com, neil.davies@pnsol.com";
      author = "Duncan Coutts, Marc Fontaine, Karl Knutsson, Marcin Szamotulski, Alexander Vieth, Neil Davies";
      homepage = "";
      url = "";
      synopsis = "Multiplexing library";
      description = "";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" "NOTICE" ];
      dataDir = "";
      dataFiles = [];
      extraSrcFiles = [ "CHANGELOG.md" ];
      extraTmpFiles = [];
      extraDocFiles = [];
      };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."io-sim-classes" or (errorHandler.buildDepError "io-sim-classes"))
          (hsPkgs."contra-tracer" or (errorHandler.buildDepError "contra-tracer"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."statistics-linreg" or (errorHandler.buildDepError "statistics-linreg"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ] ++ (pkgs.lib).optionals (system.isWindows) [
          (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))
          (hsPkgs."Win32-network" or (errorHandler.buildDepError "Win32-network"))
          ];
        buildable = true;
        modules = [
          "Network/Mux"
          "Network/Mux/Channel"
          "Network/Mux/Codec"
          "Network/Mux/Egress"
          "Network/Mux/Ingress"
          "Network/Mux/JobPool"
          "Network/Mux/Time"
          "Network/Mux/Timeout"
          "Network/Mux/Types"
          "Network/Mux/Trace"
          "Network/Mux/Bearer/Pipe"
          "Network/Mux/Bearer/Queues"
          "Network/Mux/Bearer/Socket"
          "Network/Mux/DeltaQ/TraceStats"
          "Network/Mux/DeltaQ/TraceStatsSupport"
          "Network/Mux/DeltaQ/TraceTransformer"
          "Network/Mux/DeltaQ/TraceTypes"
          ] ++ (pkgs.lib).optional (system.isWindows) "Network/Mux/Bearer/NamedPipe";
        hsSourceDirs = [ "src" ];
        };
      exes = {
        "mux-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."network-mux" or (errorHandler.buildDepError "network-mux"))
            (hsPkgs."io-sim-classes" or (errorHandler.buildDepError "io-sim-classes"))
            (hsPkgs."io-sim" or (errorHandler.buildDepError "io-sim"))
            (hsPkgs."contra-tracer" or (errorHandler.buildDepError "contra-tracer"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cborg" or (errorHandler.buildDepError "cborg"))
            (hsPkgs."serialise" or (errorHandler.buildDepError "serialise"))
            (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))
            (hsPkgs."Win32-network" or (errorHandler.buildDepError "Win32-network"))
            ];
          buildable = if !system.isWindows then false else true;
          modules = [ "Test/Mux/ReqResp" ];
          hsSourceDirs = [ "demo" "test" ];
          mainPath = [
            "mux-demo.hs"
            ] ++ (pkgs.lib).optional (!system.isWindows) "";
          };
        };
      tests = {
        "test-network-mux" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."io-sim-classes" or (errorHandler.buildDepError "io-sim-classes"))
            (hsPkgs."io-sim" or (errorHandler.buildDepError "io-sim"))
            (hsPkgs."contra-tracer" or (errorHandler.buildDepError "contra-tracer"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cborg" or (errorHandler.buildDepError "cborg"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."splitmix" or (errorHandler.buildDepError "splitmix"))
            (hsPkgs."serialise" or (errorHandler.buildDepError "serialise"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            ] ++ (pkgs.lib).optionals (system.isWindows) [
            (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))
            (hsPkgs."Win32-network" or (errorHandler.buildDepError "Win32-network"))
            ];
          buildable = true;
          modules = [
            "Network/Mux"
            "Network/Mux/Channel"
            "Network/Mux/Codec"
            "Network/Mux/Egress"
            "Network/Mux/Ingress"
            "Network/Mux/JobPool"
            "Network/Mux/Time"
            "Network/Mux/Timeout"
            "Network/Mux/Types"
            "Network/Mux/Trace"
            "Network/Mux/Bearer/Pipe"
            "Network/Mux/Bearer/Queues"
            "Network/Mux/Bearer/Socket"
            "Test/Mux"
            "Test/Mux/ReqResp"
            "Test/Mux/Timeout"
            ];
          hsSourceDirs = [ "test" "src" ];
          mainPath = [ "Main.hs" ];
          };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault .././.source-repository-packages/16; }
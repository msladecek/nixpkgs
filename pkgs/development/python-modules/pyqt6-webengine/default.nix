{
  lib,
  buildPythonPackage,
  fetchPypi,
  pkg-config,
  lndir,
  sip,
  pyqt-builder,
  qt6Packages,
  pythonOlder,
  pyqt6,
  python,
  mesa,
}:

buildPythonPackage rec {
  pname = "pyqt6-webengine";
  version = "6.8.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchPypi {
    pname = "PyQt6_WebEngine";
    inherit version;
    hash = "sha256-ZARepiK2pBiCwrGPVa6XFLhmCs/walTpEOtygiwvP/I=";
  };

  patches = [
    ./qvariant.patch
  ];

  # fix include path and increase verbosity
  postPatch = ''
    sed -i \
      '/\[tool.sip.project\]/a\
      verbose = true\
      sip-include-dirs = [\"${pyqt6}/${python.sitePackages}/PyQt6/bindings\"]' \
      pyproject.toml
  '';

  enableParallelBuilding = true;
  # HACK: paralellize compilation of make calls within pyqt's setup.py
  # pkgs/stdenv/generic/setup.sh doesn't set this for us because
  # make gets called by python code and not its build phase
  # format=pyproject means the pip-build-hook hook gets used to build this project
  # pkgs/development/interpreters/python/hooks/pip-build-hook.sh
  # does not use the enableParallelBuilding flag
  postUnpack = ''
    export MAKEFLAGS+=" -j$NIX_BUILD_CORES"
  '';

  outputs = [
    "out"
    "dev"
  ];

  dontWrapQtApps = true;

  build-system = [
    sip
    pyqt-builder
  ];

  dependencies = [
    pyqt6
  ];

  nativeBuildInputs = with qt6Packages; [
    pkg-config
    lndir
    qtwebengine
    qmake
  ];

  buildInputs = with qt6Packages; [ qtwebengine ];

  passthru = {
    inherit sip;
  };

  dontConfigure = true;

  # Checked using pythonImportsCheck, has no tests

  pythonImportsCheck = [
    "PyQt6.QtWebEngineCore"
    "PyQt6.QtWebEngineQuick"
    "PyQt6.QtWebEngineWidgets"
  ];

  meta = {
    description = "Python bindings for Qt6 WebEngine";
    homepage = "https://riverbankcomputing.com/";
    license = lib.licenses.gpl3Only;
    inherit (mesa.meta) platforms;
    maintainers = with lib.maintainers; [
      LunNova
    ];
  };
}

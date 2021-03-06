# TODO: Resolve the issues with the Mono bindings.

{ stdenv, fetchurl, lib, file
, pkgconfig, autoconf
, glib, dbus-glib, libdbusmenu-glib
, gtkVersion, gtk2 ? null, gtk3 ? null
, pythonPackages, gobjectIntrospection, vala, gnome-doc-utils
, monoSupport ? false, mono ? null, gtk-sharp-2_0 ? null
 }:

with lib;

let
  inherit (pythonPackages) python pygobject2 pygtk;
in stdenv.mkDerivation rec {
  name = let postfix = if gtkVersion == "2" && monoSupport then "sharp" else "gtk${gtkVersion}";
          in "libindicate-${postfix}-${version}";
  version = "${versionMajor}.${versionMinor}";
  versionMajor = "12.10";
  versionMinor = "1";

  src = fetchurl {
    url = "${meta.homepage}/${versionMajor}/${version}/+download/libindicate-${version}.tar.gz";
    sha256 = "10am0ymajx633b33anf6b79j37k61z30v9vaf5f9fwk1x5cw1q21";
  };

  nativeBuildInputs = [ pkgconfig autoconf gobjectIntrospection vala gnome-doc-utils ];

  buildInputs = [
    glib dbus-glib libdbusmenu-glib
    python pygobject2 pygtk
  ] ++ (if gtkVersion == "2"
    then [ gtk2 ] ++ optionals monoSupport [ mono gtk-sharp-2_0 ]
    else [ gtk3 ]);

  postPatch = ''
    substituteInPlace configure.ac \
      --replace '=codegendir pygtk-2.0' '=codegendir pygobject-2.0' \
      --replace 'pyglib-2.0-python$PYTHON_VERSION' 'pyglib-2.0-python'
    autoconf
    for f in {configure,ltmain.sh,m4/libtool.m4}; do
      substituteInPlace $f \
        --replace /usr/bin/file ${file}/bin/file
    done
  '';

  configureFlags = [
    "CFLAGS=-Wno-error"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-gtk=${gtkVersion}"
  ];

  installFlags = [
    "sysconfdir=\${out}/etc"
    "localstatedir=\${TMPDIR}"
  ];

  meta = {
    description = "Library for raising indicators via DBus";
    homepage = https://launchpad.net/libindicate;
    license = with licenses; [ lgpl21 lgpl3 ];
    platforms = platforms.linux;
    maintainers = [ maintainers.msteen ];
  };
}

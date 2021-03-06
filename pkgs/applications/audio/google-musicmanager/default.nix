{ stdenv, fetchurl, readline, patchelf, ncurses, qt48, libidn, expat, flac
, libvorbis }:

assert stdenv.system == "x86_64-linux" || stdenv.system == "1686-linux";

stdenv.mkDerivation rec {
  debversion = "beta_1.0.129.6633-r0";
  version = "beta_1.0.129.6633-r0"; # friendly to nix-env version sorting algo
  product = "google-musicmanager";
  name    = "${product}-${version}";

  # When looking for newer versions, since google doesn't let you list their repo dirs,
  # curl http://dl.google.com/linux/musicmanager/deb/dists/stable/Release
  # fetch an appropriate packages file eg main/binary-amd64/Packages
  # which will contain the links to all available *.debs for the arch.

  src = if stdenv.system == "x86_64-linux"
    then fetchurl {
      url    = "http://dl.google.com/linux/musicmanager/deb/pool/main/g/google-musicmanager-beta/google-musicmanager-${version}_amd64.deb";
      sha256 = "1fq2p721mzv8nd4dq6i9xiqvvqd5ak3v142vsxchg6yn14a9kbvr";
    }
    else fetchurl {
        url    = "http://dl.google.com/linux/musicmanager/deb/pool/main/g/google-musicmanager-beta/google-musicmanager-${version}_i386.deb";
        sha256 = "7914e3e6e2adb2e952ebaf383db5e04727c29cfa83401007f29977f6c5ff6873";
    };

  unpackPhase = ''
    ar vx ${src}
    tar -xvf data.tar.lzma
  '';

  buildInputs = [ patchelf ];

  buildPhase = ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "$out/opt/google/musicmanager:${readline}/lib:${ncurses}/lib:${stdenv.cc.libc}/lib:${qt48}/lib:${stdenv.cc.cc}/lib:${libidn}/lib:${expat}/lib:${flac}/lib:${libvorbis}/lib" opt/google/musicmanager/MusicManager
  '';

  dontPatchELF = true;
  dontStrip    = true;

  installPhase = ''
    mkdir -p "$out"
    cp -r opt "$out"
    mkdir "$out/bin"
    ln -s "$out/opt/google/musicmanager/google-musicmanager" "$out/bin"
  '';

  meta = with stdenv.lib; {
    description = "Uploads music from your computer to Google Play";
    homepage    = "https://support.google.com/googleplay/answer/1229970";
    license     = licenses.unfree;
    maintainers = with maintainers; [ lovek323 ];
    platforms   = platforms.linux;
  };
}

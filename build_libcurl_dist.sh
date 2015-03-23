#!/bin/bash

export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain

function build_for_arch() {
  ARCH=$1
  HOST=$2
  SYSROOT=$3
  PREFIX=$4
  IPHONEOS_DEPLOYMENT_TARGET="6.0"
  export PATH="${DEVROOT}/usr/bin/:${PATH}"
  export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${SYSROOT} -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET}"
  export LDFLAGS="-arch ${ARCH} -isysroot ${SYSROOT}"
  ./configure --disable-shared --enable-static --with-ssl=${HOME}/Desktop/openssl-ios-dist --host="${HOST}" --prefix=${PREFIX} && make -j8 && make install
}

TMP_DIR=/tmp/build_libcurl_$$

build_for_arch i386 i386-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.1.sdk ${TMP_DIR}/i386 || exit 1
build_for_arch x86_64 x86_64-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.1.sdk ${TMP_DIR}/x86_64 || exit 2
build_for_arch arm64 arm-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.1.sdk ${TMP_DIR}/arm64 || exit 3
build_for_arch armv7s armv7s-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.1.sdk ${TMP_DIR}/armv7s || exit 4
build_for_arch armv7 armv7-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.1.sdk ${TMP_DIR}/armv7 || exit 5

mkdir -p ${TMP_DIR}/lib/
${DEVROOT}/usr/bin/lipo \
	-arch i386 ${TMP_DIR}/i386/lib/libcurl.a \
	-arch x86_64 ${TMP_DIR}/x86_64/lib/libcurl.a \
	-arch armv7 ${TMP_DIR}/armv7/lib/libcurl.a \
	-arch armv7s ${TMP_DIR}/armv7s/lib/libcurl.a \
	-arch arm64 ${TMP_DIR}/arm64/lib/libcurl.a \
	-output ${TMP_DIR}/lib/libcurl.a -create


cp -r ${TMP_DIR}/armv7s/include ${TMP_DIR}/
curl -O https://raw.githubusercontent.com/sinofool/build-libcurl-ios/master/patch-include.patch
patch ${TMP_DIR}/include/curl/curlbuild.h < patch-include.patch

DIST_DIR=${HOME}/Desktop/libcurl-ios-dist
rm -rf ${DIST_DIR}
mkdir ${DIST_DIR}
cp -r ${TMP_DIR}/include ${TMP_DIR}/lib ${DIST_DIR}

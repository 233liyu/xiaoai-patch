PACKAGE_NAME="Perl Compatible Regular Expressions"
PACKAGE_VERSION="8.44"
# https://zenlayer.dl.sourceforge.net/project/pcre/pcre/8.44/pcre-8.44.tar.gz?viasf=1
PACKAGE_SRC="https://zenlayer.dl.sourceforge.net/project/pcre/pcre/${PACKAGE_VERSION}/pcre-${PACKAGE_VERSION}.tar.gz"
PACKAGE_DEPENDS="zlib bzip2"

configure_package() {
	CC="${BUILD_CC}" CFLAGS="--sysroot=${STAGING_DIR} -I${STAGING_DIR}/${INSTALL_PREFIX}/${BUILD_TARGET}/include ${BUILD_CFLAGS}" LDFLAGS="${BUILD_LDFLAGS}" \
	   CXX="${BUILD_CXX}" CXXFLAGS="--sysroot=${STAGING_DIR} -I${STAGING_DIR}/${INSTALL_PREFIX}/${BUILD_TARGET}/include ${BUILD_CFLAGS}" CPPFLAGS="${BUILD_CFLAGS}" \
	   PKG_CONFIG_LIBDIR="${BUILD_PKG_CONFIG_LIBDIR}" PKG_CONFIG_SYSROOT_DIR="${BUILD_PKG_CONFIG_SYSROOT_DIR}" \
	   ./configure --prefix=${INSTALL_PREFIX} --build=${MACHTYPE} --host=${BUILD_TARGET} \
	   --enable-utf \
	   --enable-pcregrep-libz --enable-pcregrep-libbz2 \
	   --with-sysroot=${STAGING_DIR}
}

make_package() {
	make -j${MAKE_JOBS}
}

install_package() {
	make DESTDIR=${STAGING_DIR} install
}

postinstall_package() {
	for NAME in pcregrep pcretest; do
		rm -vf ${STAGING_DIR}/usr/bin/${NAME}
	done
}

MODEL=l09a

WORKSPACE_DIR=$(pwd)

IMAGE=${WORKSPACE_DIR}/mico_firmware_1c348abf8_1.78.4.bin
EXTRACTION_DIR=${WORKSPACE_DIR}/extra
ROOT_SQUASHFS=${WORKSPACE_DIR}/squashfs-root
ROOTFS=$ROOT_SQUASHFS
BUILD_DIR=${WORKSPACE_DIR}/build-packages
BUILD_OUTPUT_DIR=${BUILD_DIR}/build
SRC_DOWNLOAD_DIR=${BUILD_DIR}/src
BUILD_PACKAGE_DIR=${BUILD_DIR}/packages

OUTPUT_IMG=${WORKSPACE_DIR}/xiao.img

HOST_ARCH=$(uname -m)

do_clear () {

    local dirs_to_clean=("${ROOT_SQUASHFS}" "${EXTRACTION_DIR}"  "${BUILD_PACKAGE_DIR}" "${BUILD_OUTPUT_DIR}" )
    for clean_dir in ${dirs_to_clean[@]}; do
        if [[ -d ${clean_dir} ]]; then
            echo "rm -rf ${clean_dir}"
            rm -rf ${clean_dir}
        fi
    done
}

apply_patches () {
    echo_stage "Applying patches"
    for patch in $(find ./mypatches -name "*.patch"); do
        echo "Applying patch: $patch"
        patch -p1 -d $ROOT_SQUASHFS < $patch
    done
}

remove_services () {
    echo "[*] Deleting run services"
    for SERVICE in \
        work_day_sync_service xiaomi_dns_server mediaplayer messagingagent \
        wifitool mitv-disc miio pns mibrain_service mico_ai_crontab mico_ir_agent \
        nano_httpd pns_ubus_helper quickplayer voip mdplay mibt_mesh_proxy \
        mico_helper mico_voip_service mico_voip_ubus_helper mico_voip_ubus_service \
        mico_aivs_lab didiagent aw_upgrade_autorun miot_agent miio_mpkg idmruntime \
        statpoints_daemon alarm notify dlnainit touchpad sound_effect linein \
        volctl cmcc_andlink cmcc_dm telecom_plugin telecom_zhejiang miplay; do

        # 删除服务
        rm -vf $ROOTFS/etc/rc.d/S??${SERVICE}
        # 删除自启动
        rm -vf $ROOTFS/etc/init.d/${SERVICE}

    done

    echo "[*] Deleting unused config cmcc"
    rm -vf $ROOTFS/etc/config/cmcc
    rm -rvf $ROOTFS/etc/tts
    rm -vf $ROOTFS/etc/miaudio.conf

}

remove_bins () {

    echo "[*] Deleting binary files"
    for FILE in alarmd carrier_chinatelecom.sh carrier.sh mediaplayer messagingagent mdplay mdplay_helper \
    bluez_mibt_ble mibt_ble bluez_mibt_classical \
    mibt_mesh mibt_mesh_rtl mibt_mesh_proxy mibt_mesh.automation mico_ble_service \
    mphelper mibrain_level mibrain_net_check mibrain_oauth_manager mibrain_service  \
    mipns-xiaomi mipns-sai mipns-horizon \
    mico_ai_crontab mico_vendor_helper mico_model_helper mico_aivs_lab mico-helper \
    heartbeatagent xiaomi_dns_server miio_helper miio_mpkg idmruntime \
    mijia_automation \
    miio_client miio_client_helper miio_recv_line miio_send_line miio_service notifyd pns_ubus_helper pns_upload_helper \
    mitv_pstream nano_httpd quickplayer mico_voip_applite voip_applite voip_helper voip_service work_day_sync_service \
    mico_voip_alarm mico_voip_ubus_service mico_voip_service.sh mico_voip_service mico_voip_service_helper mico_voip_ubus_helper \
    minet_client minet_service.sh telecom_plugind telecom_zhejiangd \
    upnp-disc ota-burnboot0 ota-burnuboot quark quarkd \
    statpoints statpoints_daemon matool miio_set_uid experience_plan \
    cmcc-ims cmcc_ims_service.sh cmcc-dm-deamon cmcc-andlink-deamon cmcc_helper cmcc_andlink_daemon \
    hci_tool pit_server \
    app_avk app_ble app_manager iozone mtd_crash_log didiagent config_mode linein check_mediaplayer_status \
    idmruntime mfgutil; do
    rm -vf $ROOTFS/usr/bin/$FILE
    done
    # matool = Messaging Agent, core of speaker.
    # we don't use this service, neither we interact with API services.
    rm -vf $ROOTFS/usr/bin/matool_*
    rm -vf $ROOTFS/usr/bin/procps-ng-*
    rm -vf $ROOTFS/bin/procps-ng-*

    for FILE in traceroute ssh_enable sound_effect qplayer usign urlcheck.sh upload_kernel_crash.sh dbus-launch.real \
    cpu_monitor fileop pwdx vmstat volctl tload snice skill ; do
    rm -vf $ROOTFS/usr/bin/$FILE
    done

    for FILE in collect_log.sh network_probe.sh tcpdump \
    pam_tally pam_tally2 pam_timestamp_check unix_chkpwd unix_update ; do
    rm -vf $ROOTFS/usr/sbin/$FILE
    done

    # NOTE: LX01 new ver. uses imiflash for binfo_create_lx01
    for FILE in imiflash; do
    rm -vf $ROOTFS/sbin/$FILE
    done

    # NOTE wakeup.sh is interesting :)
    for FILE in EnterFactory boardupgrade.sh flash.sh lx01_get_crashlog bind_device.sh \
    ota notify.sh touchpad tplay wakeup.sh wuw_upload.sh; do
    rm -vf $ROOTFS/bin/$FILE
    done

    echo "[*] Deleting unused Xiaomi libs"
    for FILE in libmibrain-common-sdk.so libmibrain-common-util.so libmibrainsdk.so \
        libxiaomi_crypto.so libxiaomi_didi.so libxiaomi_heartbeat.so libxiaomi_http.so libxiaomi_json.so \
        libxiaomimediaplayer.so libxiaomi_mico.so libxiaomi_miot.so libxiaomi_mosquitto.so libxiaomi_utils.so \
        libmdspeech.so libmdplay.so libmimc_sdk.so libiotdcm.so libiotdcm_mdplay.so \
        libvad.so libvoip.so libvoipengine.so libsai_miAPIs.so libmibrain-vendor-sdk.so libmibrain-util.so libota-burnboot.so \
        libDiracAPI_SHARED.so libdts.so libxaudio_engine.so libmesh.so libquark_lib.so libmivpm.so libvpm.so \
        libaivs_sdk.so libaivs-message-util.so libmijia_ble_api.so \
        libmilink.so libagora-rtc-sdk.so libsoup-2.4.so.1.8.0; do
    rm -vf $ROOTFS/usr/lib/$FILE
    done

    # not used in LX06 after removing bloatware
    # for FILE in libldns.so.1.6.17 liblua.so.5.1.5 libthrift_c_glib.so.0.0.0 libxmdtransceiver.so \
    # libstack.so liblibma.so \
    # libgmp.so.10.3.2 libgmp.so.10.3.0 libgnutls.so.30.14.8 libgnutls.so.30.6.3 libhogweed.so.4.3 libhogweed.so.4.1 \
    # libgupnp-1.0.so.4.0.1 libgssdp-1.0.so.3.0.1 \
    # libevent-2.0.so.5.1.10 libevent_{core,extra,openssl,pthreads}-2.0.so.5.1.10 \
    # libprotobuf-c.so.1.0.0 libprotobuf.so libglog.so.0 \
    # lib{ncurses,form,menu,panel}{,w}.so.{6.0,5.9} \
    # libnettle.so.6.3 libnettle.so.6.1 libprocps.so.5.0.0 libprocps.so.5 libprocps.so \
    # libgflags.so.2.2.2 libgflags_nothreads.so.2.2.2 libdplus.so \
    # libattr.so.1.1.2448 libuclient.so libutils.so libwrap.so.0.7.6 ; do
    # rm -vf $ROOTFS/usr/lib/$FILE
    # done

    # IMPORTANT! L09A micocfg uses libmbedtls.so.9 -> libmbedtls.so.1.3.14 , otherwise wifi is locked!
    # IMPORTANT! LX01 (new) micocfg uses libmbedtls.so.10 -> libmbedtls.so.2.6.0. CANNOT SWAP WITH libssl!
    # IMPORTANT! LX01 (new) micocfg uses libcrypto.1.0.0
    # libmbedcrypto.so.2.6.0 libmbedtls.so.2.6.0 libmbedtls.so.1.3.{14,16} libmbedx509.so.2.6.0 

    # removed from L09A
    # for FILE in libnetfilter_conntrack.so.3.6.0 libnfnetlink.so.0.2.0 libpcap.so.1 libpcap.so.1.3.0 \
    # libprotobuf-lite.so.13.0.0 libwebsockets.so ; do
    # rm -vf $ROOTFS/usr/lib/$FILE
    # done

    rm -vf $ROOTFS/usr/lib/.*_installed
    # rm -rvf $ROOTFS/usr/share/dlna
    rm -rvf $ROOTFS/usr/share/bash-completion
    rm -vf $ROOTFS/etc/diracmobile.config.* # S12?
    # rm -vf $ROOTFS/usr/lib/alsa-lib/libasound_module*.la # only libtool library file, unused
    rm -rvf $ROOTFS/usr/lib/opkg

    # fix repeated libs
    for FILE in libnghttp2.so.14.13.2 libevtlog.so.0.0.0 libprocps.so.5.0.0; do
    if [ -f "${ROOTFS}/usr/lib/${FILE}" ]; then
        for CUTNAME in 3 2; do
        SUBNAME=$(echo $FILE | cut -d '.' -f 1-${CUTNAME})
        rm -vf ${ROOTFS}/usr/lib/${SUBNAME}
        ln -svf ${FILE} ${ROOTFS}/usr/lib/${SUBNAME}
        done
    fi
    done

    echo "[*] Deleting Xiaomi hotword detection model"
    for NAME in xiaomi sai horizon mipns; do
    rm -rvf $ROOTFS/usr/share/$NAME
    done
}

build_sox () {
    # download sox file and compile it to 

    mkdir -p $SRC_DOWNLOAD_DIR && cd $SRC_DOWNLOAD_DIR && mkdir -p sox && cd sox
    download_file=sox-14.4.2.tar.bz2
    if [ ! -e $download_file ]; then 
        wget -O $download_file https://sourceforge.net/projects/sox/files/sox/14.4.2/sox-14.4.2.tar.bz2/download
    fi

    # unzip sox 
    mkdir -p $BUILD_PACKAGE_DIR/sox
    tar -xvjf $download_file -C $BUILD_PACKAGE_DIR/sox

    cd $BUILD_PACKAGE_DIR/sox/sox-14.4.2/

    export SYSROOT=/xiaoai/build-packages/src/arm-linux-gnueabihf/sysroot-eglibc-linaro-2017.01-arm-linux-gnueabihf

    # export CFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include"
    # export CPPFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include"
    export LDFLAGS="--sysroot=$SYSROOT -lm"

    CC=$BUILD_DIR/gcc-linaro/bin/arm-linux-gnueabihf-gcc 
    CXX=$BUILD_DIR/gcc-linaro/bin/arm-linux-gnueabihf-g++ 

    PATH=$PATH:$BUILD_DIR/gcc-linaro/bin/


    # cross compile from amd64 to aarch64 system
        # ./configure --help
        # `configure' configures SoX 14.4.2 to adapt to many kinds of systems.

        # Usage: ./configure [OPTION]... [VAR=VALUE]...

        # To assign environment variables (e.g., CC, CFLAGS...), specify them as
        # VAR=VALUE.  See below for descriptions of some of the useful variables.

        # Defaults for the options are specified in brackets.

        # Configuration:
        #   -h, --help              display this help and exit
        #       --help=short        display options specific to this package
        #       --help=recursive    display the short help of all the included packages
        #   -V, --version           display version information and exit
        #   -q, --quiet, --silent   do not print `checking ...' messages
        #       --cache-file=FILE   cache test results in FILE [disabled]
        #   -C, --config-cache      alias for `--cache-file=config.cache'
        #   -n, --no-create         do not create output files
        #       --srcdir=DIR        find the sources in DIR [configure dir or `..']

        # Installation directories:
        #   --prefix=PREFIX         install architecture-independent files in PREFIX
        #                           [/usr/local]
        #   --exec-prefix=EPREFIX   install architecture-dependent files in EPREFIX
        #                           [PREFIX]

        # By default, `make install' will install all the files in
        # `/usr/local/bin', `/usr/local/lib' etc.  You can specify
        # an installation prefix other than `/usr/local' using `--prefix',
        # for instance `--prefix=$HOME'.

        # For better control, use the options below.

        # Fine tuning of the installation directories:
        #   --bindir=DIR            user executables [EPREFIX/bin]
        #   --sbindir=DIR           system admin executables [EPREFIX/sbin]
        #   --libexecdir=DIR        program executables [EPREFIX/libexec]
        #   --sysconfdir=DIR        read-only single-machine data [PREFIX/etc]
        #   --sharedstatedir=DIR    modifiable architecture-independent data [PREFIX/com]
        #   --localstatedir=DIR     modifiable single-machine data [PREFIX/var]
        #   --libdir=DIR            object code libraries [EPREFIX/lib]
        #   --includedir=DIR        C header files [PREFIX/include]
        #   --oldincludedir=DIR     C header files for non-gcc [/usr/include]
        #   --datarootdir=DIR       read-only arch.-independent data root [PREFIX/share]
        #   --datadir=DIR           read-only architecture-independent data [DATAROOTDIR]
        #   --infodir=DIR           info documentation [DATAROOTDIR/info]
        #   --localedir=DIR         locale-dependent data [DATAROOTDIR/locale]
        #   --mandir=DIR            man documentation [DATAROOTDIR/man]
        #   --docdir=DIR            documentation root [DATAROOTDIR/doc/sox]
        #   --htmldir=DIR           html documentation [DOCDIR]
        #   --dvidir=DIR            dvi documentation [DOCDIR]
        #   --pdfdir=DIR            pdf documentation [DOCDIR]
        #   --psdir=DIR             ps documentation [DOCDIR]

        # Program names:
        #   --program-prefix=PREFIX            prepend PREFIX to installed program names
        #   --program-suffix=SUFFIX            append SUFFIX to installed program names
        #   --program-transform-name=PROGRAM   run sed PROGRAM on installed program names

        # System types:
        #   --build=BUILD     configure for building on BUILD [guessed]
        #   --host=HOST       cross-compile to build programs to run on HOST [BUILD]
        #   --target=TARGET   configure for building compilers for TARGET [HOST]

        # Optional Features:
        #   --disable-option-checking  ignore unrecognized --enable/--with options
        #   --disable-FEATURE       do not include FEATURE (same as --enable-FEATURE=no)
        #   --enable-FEATURE[=ARG]  include FEATURE [ARG=yes]
        #   --enable-silent-rules   less verbose build output (undo: "make V=1")
        #   --disable-silent-rules  verbose build output (undo: "make V=0")
        #   --enable-dependency-tracking
        #                           do not reject slow dependency extractors
        #   --disable-dependency-tracking
        #                           speeds up one-time build
        #   --enable-shared[=PKGS]  build shared libraries [default=yes]
        #   --enable-static[=PKGS]  build static libraries [default=yes]
        #   --enable-fast-install[=PKGS]
        #                           optimize for fast installation [default=yes]
        #   --disable-libtool-lock  avoid locking (might break parallel builds)
        #   --enable-debug          make a debug build
        #   --disable-stack-protector
        #                           Disable GCC's/libc's stack-smashing protection
        #   --disable-largefile     omit support for large files
        #   --disable-silent-libtool
        #                           Verbose libtool
        #   --disable-openmp        do not use OpenMP
        #   --enable-dl-mad         Dlopen mad instead of linking in.
        #   --enable-dl-lame        Dlopen lame instead of linking in.
        #   --enable-dl-twolame     Dlopen twolame instead of linking in.
        #   --enable-dl-amrwb       Dlopen amrbw instead of linking in.
        #   --enable-dl-amrnb       Dlopen amrnb instead of linking in.
        #   --enable-dl-sndfile     Dlopen sndfile instead of linking in.
        #   --disable-symlinks      Don't make any symlinks to sox.

        # Optional Packages:
        #   --with-PACKAGE[=ARG]    use PACKAGE [ARG=yes]
        #   --without-PACKAGE       do not use PACKAGE (same as --with-PACKAGE=no)
        #   --without-libltdl       Don't try to use libltdl for external dynamic
        #                           library support
        #   --with-pic[=PKGS]       try to use only PIC/non-PIC objects [default=use
        #                           both]
        #   --with-gnu-ld           assume the C compiler uses GNU ld [default=no]
        #   --with-sysroot=DIR Search for dependent libraries within DIR
        #                         (or the compiler's sysroot if not specified).
        #   --with-dyn-default      Default to loading optional formats dynamically
        #   --with-pkgconfigdir     location to install .pc files or "no" to disable
        #                           (default=$(libdir)/pkgconfig)
        #   --with-distro=distro    Provide distribution name
        #   --without-magic         Don't try to use magic
        #   --without-png           Don't try to use png
        #   --without-ladspa        Don't try to use LADSPA
        #   --with-ladspa-path      Default search path for LADSPA plugins
        #   --without-mad           Don't try to use MAD (MP3 Audio Decoder)
        #   --without-id3tag        Don't try to use id3tag
        #   --without-lame          Don't try to use LAME (LAME Ain't an MP3 Encoder)
        #   --without-twolame       Don't try to use Twolame (MP2 Audio Encoder)
        #   --with-oggvorbis=dyn    load oggvorbis dynamically
        #   --with-opus=dyn         load opus dynamically
        #   --with-flac=dyn         load flac dynamically
        #   --with-amrwb=dyn        load amrwb dynamically
        #   --with-amrnb=dyn        load amrnb dynamically
        #   --with-wavpack=dyn      load wavpack dynamically
        #   --with-sndio=dyn        load sndio dynamically
        #   --with-coreaudio=dyn    load coreaudio dynamically
        #   --with-alsa=dyn         load alsa dynamically
        #   --with-ao=dyn           load ao dynamically
        #   --with-pulseaudio=dyn   load pulseaudio dynamically
        #   --with-waveaudio=dyn    load waveaudio dynamically
        #   --with-sndfile=dyn      load sndfile dynamically
        #   --with-oss=dyn          load oss dynamically
        #   --with-sunaudio=dyn     load sunaudio dynamically
        #   --with-mp3=dyn          load mp3 dynamically
        #   --with-gsm=dyn          load gsm dynamically
        #   --with-lpc10=dyn        load lpc10 dynamically

        # Some influential environment variables:
        #   CC          C compiler command
        #   CFLAGS      C compiler flags
        #   LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries in a
        #               nonstandard directory <lib dir>
        #   LIBS        libraries to pass to the linker, e.g. -l<library>
        #   CPPFLAGS    (Objective) C/C++ preprocessor flags, e.g. -I<include dir> if
        #               you have headers in a nonstandard directory <include dir>
        #   CPP         C preprocessor
        #   PKG_CONFIG  path to pkg-config utility
        #   PKG_CONFIG_PATH
        #               directories to add to pkg-config's search path
        #   PKG_CONFIG_LIBDIR
        #               path overriding pkg-config's built-in search path
        #   OPUS_CFLAGS C compiler flags for OPUS, overriding pkg-config
        #   OPUS_LIBS   linker flags for OPUS, overriding pkg-config
        #   SNDFILE_CFLAGS
        #               C compiler flags for SNDFILE, overriding pkg-config
        #   SNDFILE_LIBS
        #               linker flags for SNDFILE, overriding pkg-config

        # Use these variables to override the choices made by `configure' or to help
        # it to find libraries and programs with nonstandard names/locations.
    mkdir -p $BUILD_OUTPUT_DIR $BUILD_OUTPUT_DIR/lib
    ./configure --prefix=$BUILD_OUTPUT_DIR/usr  --with-sysroot=$SYSROOT --host=arm-linux-gnueabihf 

    make -s && make install

    cp $SRC_DOWNLOAD_DIR/arm-linux-gnueabihf/sysroot-eglibc-linaro-2017.01-arm-linux-gnueabihf/lib/libgomp.so* $BUILD_OUTPUT_DIR/lib/
    # cp /usr/arm-linux-gnueabihf/lib/libgomp.so.1.0.0 $BUILD_OUTPUT_DIR/lib/
    # cp /usr/arm-linux-gnueabihf/lib/libc* $BUILD_OUTPUT_DIR/usr/lib/
    # cp /usr/arm-linux-gnueabihf/lib/libm* $BUILD_OUTPUT_DIR/usr/lib/

}


prepare_linaro (){
    echo "Preparing linaro toolchain"
    cd $SRC_DOWNLOAD_DIR/arm-linux-gnueabihf
    mkdir -p $BUILD_DIR/gcc-linaro

    rm gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar 

    xz -d gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz 
    tar -xvf gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar -C $BUILD_DIR/gcc-linaro

    xz -d sysroot-eglibc-linaro-2017.01-arm-linux-gnueabihf.tar.xz


    cd $BUILD_DIR/gcc-linaro && mv ./gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/* .
    
}



do_clear

mkdir -p $BUILD_DIR $BUILD_OUTPUT_DIR $BUILD_PACKAGE_DIR

# extract image
python3 ./tools/mico_firmware.py -e $IMAGE -d $EXTRACTION_DIR


# unsquashfs root
unsquashfs -dest $ROOT_SQUASHFS $EXTRACTION_DIR/root.squashfs

apply_patches

remove_services
remove_bins

# build_python
build_sox
# scripts/92_copy_build_packages.sh


FOLDER=$BUILD_OUTPUT_DIR

echo "[*] Checking for build-package folder"
if [ ! -d "${FOLDER}/" ]; then
  echo "[*] Folder does not exist, skipping."

else
    echo "[*] Copying content"
    rsync -avr ${FOLDER}/* ${ROOT_SQUASHFS}/

    # rm ${ROOT_SQUASHFS}/
fi


rm $OUTPUT_IMG
mksquashfs $ROOT_SQUASHFS $OUTPUT_IMG -b 131072 -comp xz -no-xattrs


IMAGE_MAX_SIZE=41943040


[ "`stat -L -c %s ${OUTPUT_IMG}`" -ge "${IMAGE_MAX_SIZE}" ] && echo "!!! WARNING: Image built is larger than allowed! - $(IMAGE_MAX_SIZE)" && exit 1 


echo "[*] Done output img size = `du -h ${OUTPUT_IMG}`"
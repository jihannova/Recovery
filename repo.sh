#!/bin/bash
    
sync () {
    cd ~/rom
    time rclone copy znxtproject:PitchBlack/manifest/maple_dsds.xml ~/rom -P
    repo init --depth=1 --no-repo-verify -u https://github.com/PitchBlackRecoveryProject/manifest_pb.git -b android-12.1 -g default,-mips,-darwin,-notdefault
    repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync
}

com () {
    #tar --use-compress-program="pigz -k -$2 " -cf $1.tar.gz $1
    tar "-I zstd -1 -T2" -cf $1.tar.zst $1
}

get_repo () {
  cd ~/rom
  time com .repo 1
  time rclone copy .repo.tar.* znxtproject:ccache/$ROM_PROJECT -P
  time rm .repo.tar.*
  ls -lh
}

build () {
     cd ~/rom
     . build/envsetup.sh
     export CCACHE_DIR=~/ccache
     export CCACHE_EXEC=$(which ccache)
     export USE_CCACHE=1
     ccache -M 50G
     ccache -z
     export BUILD_HOSTNAME=znxt
     export BUILD_USERNAME=znxt
     export TZ=Asia/Jakarta
     #export SELINUX_IGNORE_NEVERALLOWS=true
     export ALLOW_MISSING_DEPENDENCIES=true
     lunch omni_maple_dsds-eng
    #make bootimage -j8
    #make systemimage -j8
    #make vendorimage -j8
    #make installclean
    mka recoveryimage -j8
}

compile () {
    sync
    echo "done."
    #get_repo
    build
}

# Sorting final zip
compiled_zip() {
    DEVICE=$(ls $(pwd)/out/target/product)
	ZIP=$(find $(pwd)/out/target/product/${DEVICE}/ -maxdepth 1 -name "recovery.img" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
	RECOVERY=$(basename ${ZIP})
}

upload() {
	if [ -f $(pwd)/out/target/product/map*/${RECOVERY} ]; then
		echo "Successfully Build"
        time rclone copy $(pwd)/out/target/product/${DEVICE}/${RECOVERY} znxtproject:NusantaraProject/${DEVICE} -P
	else
		echo "Build failed"
	fi
}

cd ~/rom
ls -lh
compile #&
#sleep 55m
#sleep 113m
#kill %1
compiled_zip
upload

# Lets see machine specifications and environments
df -h
free -h
nproc
cat /etc/os*

#!/bin/bash
# GrifoDev script

export MODEL=star2lte
export VARIANT=eur
export ARCH=arm64
export BUILD_CROSS_COMPILE=../Toolchain/gcc-linaro-7.3.1_aarch64-linux-gnu/bin/aarch64-linux-gnu-
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`

RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts/exynos
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include

PAGE_SIZE=2048
DTB_PADDING=0

case $MODEL in
starlte)
	case $VARIANT in
	can|duos|eur|xx)
		KERNEL_DEFCONFIG=exynos9810-starlte_defconfig
		;;
	*)
		echo "Unknown variant: $VARIANT"
		exit 1
		;;
	esac
;;
star2lte)
	case $VARIANT in
	can|duos|eur|xx)
		KERNEL_DEFCONFIG=exynos9810-star2lte_defconfig
		;;
	*)
		echo "Unknown variant: $VARIANT"
		exit 1
		;;
	esac
;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac

FUNC_CLEAN_DTB()
{
	if ! [ -d $RDIR/arch/$ARCH/boot/dts ] ; then
		echo "no directory : "$RDIR/arch/$ARCH/boot/dts""
	else
		echo "rm files in : "$RDIR/arch/$ARCH/boot/dts/*.dtb""
		rm $RDIR/arch/$ARCH/boot/dts/*.dtb
		rm $RDIR/arch/$ARCH/boot/dtb/*.dtb
		rm $RDIR/arch/$ARCH/boot/boot.img-dtb
		rm $RDIR/arch/$ARCH/boot/boot.img-zImage
	fi
}

FUNC_BUILD_DTIMAGE_TARGET()
{
	[ -f "$DTCTOOL" ] || {
		echo "You need to run ./build.sh first!"
		exit 1
	}

	case $MODEL in
	starlte)
		case $VARIANT in
		can|duos|eur|xx)
			DTSFILES="exynos9810-starlte_eur_open_16 exynos9810-starlte_eur_open_17
					exynos9810-starlte_eur_open_18 exynos9810-starlte_eur_open_20
					exynos9810-starlte_eur_open_23 exynos9810-starlte_eur_open_26"
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	star2lte)
		case $VARIANT in
		can|duos|eur|xx)
			DTSFILES="exynos9810-star2lte_eur_open_16 exynos9810-star2lte_eur_open_17
					exynos9810-star2lte_eur_open_18 exynos9810-star2lte_eur_open_20
					exynos9810-star2lte_eur_open_23 exynos9810-star2lte_eur_open_26"
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	*)
		echo "Unknown device: $MODEL"
		exit 1
		;;
	esac

	mkdir -p $OUTDIR $DTBDIR

	cd $DTBDIR || {
		echo "Unable to cd to $DTBDIR!"
		exit 1
	}

	rm -f ./*

	echo "Processing dts files..."

	for dts in $DTSFILES; do
		echo "=> Processing: ${dts}.dts"
		${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
		echo "=> Generating: ${dts}.dtb"
		$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
	done

	echo "Generating dtb.img..."
	$RDIR/scripts/dtbTool/dtbTool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE

	echo "Done."
}

FUNC_BUILD_KERNEL()
{
	echo ""
        echo "=============================================="
        echo "START : FUNC_BUILD_KERNEL"
        echo "=============================================="
        echo ""
        echo "build common config="$KERNEL_DEFCONFIG ""
        echo "build model config="$MODEL ""

	FUNC_CLEAN_DTB

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG || exit -1

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1

	FUNC_BUILD_DTIMAGE_TARGET
	
	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}

FUNC_BUILD_RAMDISK()
{
	mv $RDIR/arch/$ARCH/boot/Image $RDIR/arch/$ARCH/boot/boot.img-zImage
	mv $RDIR/arch/$ARCH/boot/dtb.img $RDIR/arch/$ARCH/boot/boot.img-dtb

	case $MODEL in
	starlte)
		case $VARIANT in
		can|duos|eur|xx)
			rm -f $RDIR/ramdisk/SM-G960F/split_img/boot.img-zImage
			rm -f $RDIR/ramdisk/SM-G960F/split_img/boot.img-dtb
			mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/ramdisk/SM-G960F/split_img/boot.img-zImage
			mv -f $RDIR/arch/$ARCH/boot/boot.img-dtb $RDIR/ramdisk/SM-G960F/split_img/boot.img-dtb
			cd $RDIR/ramdisk/SM-G960F
			./repackimg.sh --nosudo
			echo SEANDROIDENFORCE >> image-new.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	star2lte)
		case $VARIANT in
		can|duos|eur|xx)
			rm -f $RDIR/ramdisk/SM-G965F/split_img/boot.img-zImage
			rm -f $RDIR/ramdisk/SM-G965F/split_img/boot.img-dtb
			mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/ramdisk/SM-G965F/split_img/boot.img-zImage
			mv -f $RDIR/arch/$ARCH/boot/boot.img-dtb $RDIR/ramdisk/SM-G965F/split_img/boot.img-dtb
			cd $RDIR/ramdisk/SM-G965F
			./repackimg.sh --nosudo
			echo SEANDROIDENFORCE >> image-new.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	*)
		echo "Unknown device: $MODEL"
		exit 1
		;;
	esac
}

FUNC_BUILD_ZIP()
{
	cd $RDIR/build
	rm $MODEL-$VARIANT.img
	case $MODEL in
	starlte)
		case $VARIANT in
		can|duos|eur|xx)
			mv -f $RDIR/ramdisk/SM-G960F/image-new.img $RDIR/build/$MODEL-$VARIANT.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	star2lte)
		case $VARIANT in
		can|duos|eur|xx)
			mv -f $RDIR/ramdisk/SM-G965F/image-new.img $RDIR/build/$MODEL-$VARIANT.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	*)
		echo "Unknown device: $MODEL"
		exit 1
		;;
	esac
}

# MAIN FUNCTION
rm -rf ./build.log
(
	START_TIME=`date +%s`

	FUNC_BUILD_KERNEL
	FUNC_BUILD_RAMDISK
	FUNC_BUILD_ZIP

	END_TIME=`date +%s`
	
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time was $ELAPSED_TIME seconds"

) 2>&1	 | tee -a ./build.log

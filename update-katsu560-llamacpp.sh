#!/bin/sh

# update katsu560/llama.cpp
# T902 Intel(R) Core(TM) i5-3320M CPU @ 2.60GHz  2C/4T F16C,AVX IvyBridge/3rd Gen.
# AH   Intel(R) Core(TM) i3-10110U CPU @ 2.10GHz  2C/4T F16C,AVX,AVX2,FMA CometLake/10th Gen.

MYNAME=update-katsu560-llamacpp.sh

# common code, functions
### return code/error code
RET_TRUE=1              # TRUE
RET_FALSE=0             # FALSE
RET_OK=0                # OK
RET_NG=1                # NG
RET_YES=1               # YES
RET_NO=0                # NO
RET_CANCEL=2            # CANCEL

ERR_USAGE=1             # usage
ERR_UNKNOWN=2           # unknown error
ERR_NOARG=3             # no argument
ERR_BADARG=4            # bad argument
ERR_NOTEXISTED=10       # not existed
ERR_EXISTED=11          # already existed
ERR_NOTFILE=12          # not file
ERR_NOTDIR=13           # not dir
ERR_CANTCREATE=14       # can't create
ERR_CANTOPEN=15         # can't open
ERR_CANTCOPY=16         # can't copy
ERR_CANTDEL=17          # can't delete

# set unique return code from 100
ERR_NOTOPDIR=100        # no topdir
ERR_NOBUILDDIR=101      # no build dir


### flags
VERBOSE=0               # -v --verbose flag, -v -v means more verbose
NOEXEC=$RET_FALSE       # -n --noexec flag
FORCE=$RET_FALSE        # -f --force flag
NODIE=$RET_FALSE        # -nd --nodie
NOCOPY=$RET_FALSE       # -ncp --nocopy
NOTHING=

###
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
# https://qiita.com/PruneMazui/items/8a023347772620025ad6
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
ESC=$(printf '\033')
ESCRESET="${ESC}[0m"
ESCBOLD="${ESC}[1m"
ESCFAINT="${ESC}[2m"
ESCITALIC="${ESC}[3m"
ESCUL="${ESC}[4m"	# underline
ESCBLINK="${ESC}[5m"	# slow blink
ESCRBLINK="${ESC}[6m"	# rapid blink
ESCREVERSE="${ESC}[7m"
ESCCONCEAL="${ESC}[8m"
ESCDELETED="${ESC}[9m"	# crossed-out
ESCBOLDOFF="${ESC}[22m"	# bold off, faint off
ESCITALICOFF="${ESC}[23m"  # italic off
ESCULOFF="${ESC}[24m"	# underline off
ESCBLINKOFF="${ESC}[25m"   # blink off
ESCREVERSEOFF="${ESC}[27m" # reverse off
ESCCONCEALOFF="${ESC}[28m" # conceal off
ESCDELETEDOFF="${ESC}[29m" # deleted off
ESCBLACK="${ESC}[30m"
ESCRED="${ESC}[31m"
ESCGREEN="${ESC}[32m"
ESCYELLOW="${ESC}[33m"
ESCBLUE="${ESC}[34m"
ESCMAGENTA="${ESC}[35m"
ESCCYAN="${ESC}[36m"
ESCWHITEL="${ESC}[37m"
ESCDEFAULT="${ESC}[38m"
ESCBACK="${ESC}[m"

ESCOK="$ESCGREEN"
ESCERR="$ESCRED"
ESCWARN="$ESCMAGENTA"
ESCINFO="$ESCWHITE"

xxmsg()
{
	if [ $VERBOSE -ge 2 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

xmsg()
{
	if [ $VERBOSE -ge 1 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

emsg()
{
        echo "${ESCERR}$MYNAME: $*${ESCBACK}" 1>&2
}

msg()
{
	echo "$MYNAME: $*"
}

die()
{
	local CODE

	CODE=$1
	shift
	xxmsg "die: CODE:$CODE msg:$*"

        msg "${ESCERR}$*${ESCBACK}"
	if [ $NODIE -eq $RET_TRUE ]; then
		xmsg "die: nodie"
		return
	fi
	exit $CODE
}

nothing()
{
	NOTHING=
}

chk_and_cp()
{
	local chkfiles cpopt narg argfiles dstpath ncp cpfiles i

	#xmsg "----"
	#xmsg "chk_and_cp: $*"
	#xmsg "chk_and_cp: nargs:$# args:$*"
	if [ $# -eq 0 ]; then
		msg "${ESCERR}chk_and_cp: no cpopt, chkfiles${ESCBACK}"
		return $ERR_NOARG
	fi

	# get cp opt
	cpopt=$1
	shift
	#xmsg "chk_and_cp: narg:$# args:$*"

	if [ $# -le 1 ]; then
		msg "${ESCERR}chk_and_cp: bad arg, not enough${ESCBACK}"
		return $ERR_BADARG
	fi

	narg=$#
	dstpath=`eval echo '${'$#'}'`
	#xmsg "chk_and_cp: narg:$# dstpath:$dstpath"
	if [ ! -d $dstpath ]; then
		dstpath=
	fi
	argfiles="$*"
	#xmsg "chk_and_cp: cpopt:$cpopt narg:$narg argfiles:$argfiles dstpath:$dstpath"

	ncp=1
	cpfiles=
	for i in $argfiles
	do
		#xmsg "chk_and_cp: ncp:$ncp/$narg i:$i"
		if [ $ncp -eq $narg ]; then
			dstpath="$i"
			break
		fi

		if [ -f $i ]; then
			cpfiles="$cpfiles $i"
		elif [ -d $i -a ! "x$i" = x"$dstpath" ]; then
			cpfiles="$cpfiles $i"
		else
			msg "${ESCWARN}chk_and_cp: $i: can't add to cpfiles, ignore${ESCBACK}"
			msg "ls -l $i"
			ls -l $i
		fi

		ncp=`expr $ncp + 1`
	done

	#xmsg "chk_and_cp: cpopt:$cpopt ncp:$ncp cpfiles:$cpfiles dstpath:$dstpath"
	if [ x"$cpfiles" = x ]; then
		msg "${ESCERR}chk_and_cp: bad arg, no cpfiles${ESCBACK}"
		return $ERR_BADARG
	fi

	if [ x"$dstpath" = x ]; then
		msg "${ESCERR}chk_and_cp: bad arg, no dstpath${ESCBACK}"
		return $ERR_BADARG
	fi

	if [ $ncp -eq 2 ]; then
		if [ -f $cpfiles -a ! -e $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -f $dstpath -a $cpfiles = $dstpath ]; then
			msg "${ESCERR}chk_and_cp: bad arg, same file${ESCBACK}"
			return $ERR_BADARG
		elif [ -d $cpfiles -a -f $dstpath ]; then
			msg "${ESCERR}chk_and_cp: bad arg, dir to file${ESCBACK}"
			return $ERR_BADARG
		elif [ -f $cpfiles -a -f $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -d $dstpath ]; then
			nothing
		fi
	elif [ ! -e $dstpath ]; then
		msg "${ESCERR}chk_and_cp: not existed${ESCBACK}"
		return $ERR_NOTEXISTED
	elif [ ! -d $dstpath ]; then
		msg "${ESCERR}chk_and_cp: not dir${ESCBACK}"
		return $ERR_NOTDIR
	fi

	if [ $NOEXEC -eq $RET_FALSE ]; then
		msg "cp $cpopt $cpfiles $dstpath"
		cp $cpopt $cpfiles $dstpath || return $?
	else
		msg "${ESCWARN}noexec: cp $cpopt $cpfiles $dstpath${ESCBACK}"
	fi

	return $RET_OK
}

# chk_and_cp test code
func_test()
{
	RETCODE=$?

	OKCODE=$1
	shift
	TESTMSG="$*"

	if [ $RETCODE -eq $OKCODE ]; then
		msg "${ESCOK}test:OK${ESCBACK}: ret:$RETCODE expected:$OKCODE $TESTMSG"
	else
		msg "${ESCERR}${ESCBOLD}test:NG${ESCBOLDOFF}${ESCBACK}: ret:$RETCODE expected:$OKCODE ${ESCRED}$TESTMSG${ESCBACK}"
	fi
	msg "----"
}

set_ret()
{
	return $1
}

test_chk_and_cp()
{
	# test files and dir, test-no.$$, testdir-no.$$: not existed
	touch test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$
	rm test-no.$$
	mkdir testdir.$$
	rmdir testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: create test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"

	# test code
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp
	func_test $ERR_NOARG "no cpopt: chk_and_cp"

	chk_and_cp -p
	func_test $ERR_BADARG "bad arg: chk_and_cp -p"

	chk_and_cp -p test-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$"
	chk_and_cp -p test.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test.$$"
	chk_and_cp -p testdir-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p testdir-no.$$"
	chk_and_cp -p testdir.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p testdir.$$"

	chk_and_cp -p test-no.$$ test-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ test-no.$$"
	chk_and_cp -p test-no.$$ test.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ test.$$"
	chk_and_cp -p test-no.$$ testdir-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ testdir-no.$$"
	chk_and_cp -p test-no.$$ testdir.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ testdir.$$"

	chk_and_cp -p test.$$ test-no.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-no.$$"
	msg "ls test-no.$$"; ls -l test-no.$$; rm -rf test-no.$$
	chk_and_cp -p test.$$ test-1.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$"
	msg "ls test-1.$$"; ls -l test-1.$$
	chk_and_cp -p test.$$ test.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test.$$ test.$$"
	chk_and_cp -p test.$$ testdir-no.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir-no.$$"
	msg "ls testdir-no.$$"; ls -l testdir-no.$$; rm -rf testdir-no.$$
	chk_and_cp -p test.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-no.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-no.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir-no.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir-no.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$


	rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$
	rm -rf testdir.$$ testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"
}
#msg "test_chk_and_cp"; VERBOSE=1; test_chk_and_cp; exit 0


###
BASEDIR=~/github/llama.cpp
TOPDIR=llama.cpp
BUILDPATH="$TOPDIR/build"
# script
SCRIPT=script
FIXBASE="fix"
SCRIPTNAME=llamacpp
UPDATENAME=update-katsu560-${SCRIPTNAME}.sh
FIXSHNAME=${FIXBASE}[0-9][0-9][0-9][0-9].sh
MKZIPNAME=mkzip-${SCRIPTNAME}.sh

PROMPT="Building a website can be done in 10 simple steps:"
PROMPTCHAT="Tell me about FIFA worldcup 2022 Qatar. What country win the match?"
PROMPTJP="日本語で回答ください。京都について教えてください"
SEED=1681527203
MAINOPT="--log-disable"

#CMKOPT=
OPENBLAS=`grep -sr LLAMA_OPENBLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*LLAMA_OPENBLAS.*/LLAMA_OPENBLAS/'`
BLAS=`grep -sr LLAMA_BLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*LLAMA_BLAS.*/LLAMA_BLAS/'`
if [ ! x"$OPENBLAS" = x ]; then
	# old CMakeLists.txt
	LLAMA_OPENBLAS="-DLLAMA_OPENBLAS=ON"
	BLASVENDOR=""
	echo "# use LLAMA_OPENBLAS=$LLAMA_OPENBLAS BLASVENDOR=$BLASVENDOR"
else
	LLAMA_OPENBLAS=
fi
if [ ! x"$BLAS" = x ]; then
	# new CMakeLists.txt from 2023.6
	LLAMA_OPENBLAS="-DLLAMA_BLAS=ON"
	BLASVENDOR="-DLLAMA_BLAS_VENDOR=OpenBLAS"
	echo "# use LLAMA_OPENBLAS=$LLAMA_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
CMKOPTBLAS="$LLAMA_OPENBLAS $BLASVENDOR"
CMKOPTNOAVX="-DLLAMA_AVX=OFF -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=OFF $CMKOPTBLAS -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPTAVX="-DLLAMA_AVX=ON -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=ON $CMKOPTBLAS -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPTAVX2="-DLLAMA_AVX=ON -DLLAMA_AVX2=ON -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=ON -DLLAMA_F16C=ON $CMKOPTBLAS -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPTNONE="$CMKOPTBLAS -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPT="$CMKOPTNONE"

TESTOPT="GGML_NLOOP=1 GGML_NTHREADS=4"
NOTGT="gguf llama-bench infill"
NOTEST="test-double-float test-opt"
TARGETS=
TESTS=
ALLBINS=

get_targets()
{
        if [ ! -e $TOPDIR/Makefile ]; then
                msg "no $TOPDIR/Makefile"
                return $ERR_NOTEXISTED
        fi

        TARGETS=`awk -v NOTGT0="$NOTGT" '
	BEGIN { ST=0; split(NOTGT0,NOTGT); }
	function is_notgt(tgt) {
       		for(i in NOTGT) { if (NOTGT[i]==tgt) return 1; continue }
       		return 0;
	}
	ST==1 && /^$/ { ST=2 }
	ST==1 && !/^$/ { T=$0; sub(/[\r\n]$/,"",T); sub(/^[ ]*/,"",T); sub(/\\\/,"",T); split(T,TGT0); for(I in TGT0) { if (is_notgt(TGT0[I])==0) { printf("%s ",TGT0[I]) } } }
	ST==0 && /^BUILD_TARGETS = / { ST=1 }
	' $TOPDIR/Makefile`
        msg "TARGETS: $TARGETS"

        TESTS=`awk -v NOTGT0="$NOTEST" '
	BEGIN { ST=0; split(NOTGT0,NOTGT); }
	function is_notgt(tgt) {
       		for(i in NOTGT) { if (NOTGT[i]==tgt) return 1; continue }
       		return 0;
	}
	ST==1 && /^$/ { ST=2 }
	ST==1 && !/^$/ { T=$0; sub(/[\r\n]$/,"",T); sub(/^[ ]*/,"",T); sub(/\\\/,"",T); gsub(/tests\//,"",T); split(T,TGT0); for(I in TGT0) { if (is_notgt(TGT0[I])==0) { printf("%s ",TGT0[I]) } } }
	ST==0 && /^TEST_TARGETS = / { ST=1 }
	' $TOPDIR/Makefile`
        msg "TESTS: $TESTS"

        return $RET_OK
}
#get_targets; exit 0

# default -avx
CMKOPT="$CMKOPTAVX"
CMKOPT2=""

MKCLEAN=0
NOCLEAN=0

usage()
{
	echo "usage: $MYNAME [-h][-nd][-nc][-up][-noavx|-avx|-avx2][-qkk64] dirname branch cmd"
	echo "-h|--help ... this message"
	echo "-nd|--nodie ... no die"
	echo "-nc|--noclean ... no make clean"
	echo "-up ... upstream, no mod source, skip benchmark-matmult"
	echo "-noavx|-avx|-avx2 ... set cmake option for no AVX, AVX, AVX2"
	echo "-qkk64 ... add cmake option for QKK_64"
	echo "dirname ... directory name ex. 0407up"
	echo "branch ... git branch ex. master, gq, devpr"
	echo "cmd ... sycpcmktstmain sy/sync,cp,cmk/cmake,tst/test,main"
	echo "cmd ... sycpcmktstnm sy,cp,cmk,tst,nm  nm .. build main but no exec"
	echo "cmd ... mainonly .. main execution only"
	echo "cmd ... ggufonly .. main execution w/ gguf models only"
	echo "cmd ... script .. push $UPDATENAME $MKZIPNAME $FIXSHNAME to remote"
}

###
if [ x"$1" = x -o $# -lt 3 ]; then
	usage
	exit $ERR_USAGE
fi

ALLOPT="$*"
OPTLOOP=$RET_TRUE
while [ $OPTLOOP -eq $RET_TRUE ];
do
	case $1 in
	-h|--help)	usage; exit $ERR_USAGE;;
	-v|--verbose)   VERBOSE=`expr $VERBOSE + 1`;;
	-n|--noexec)    NOEXEC=$RET_TRUE;;
	-nd|--nodie)	NODIE=$RET_TRUE;;
	-ncp|--nocopy)	NOCOPY=$RET_TRUE;;
	-nc|--noclean)	NOCLEAN=$RET_TRUE;;
	#-up)		ALLBINS="$ALLBINSUP";;
	-noavx)		CMKOPT="$CMKOPTNOAVX";;
	-avx)		CMKOPT="$CMKOPTAVX";;
	-avx2)		CMKOPT="$CMKOPTAVX2";;
	-qkk64)		CMKOPT2="-DLLAMA_QKK_64=ON";;
	-s|-seed)	shift; SEEDOPT=$1;;
	*)		OPTLOOP=$RET_FALSE; break;;
	esac
	shift
done

if [ x"$CMKOPT" = x"" ]; then
	CMKOPT="$CMKOPTAVX"
fi
CMKOPT="$CMKOPT $CMKOPT2"

DIRNAME="$1"
BRANCH="$2"
CMD="$3"

###
do_sync()
{
	# in build

	msg "# synchronizing ..."
	msg "git branch"
	git branch
	msg "git checkout $BRANCH"
	git checkout $BRANCH
	msg "git fetch"
	git fetch
	msg "git reset --hard origin/master"
	git reset --hard origin/master
}

do_cp()
{
	# in build

	msg "# copying ..."
	#msg "cp -p ../ggml.[ch] ../k_quants.[ch] ../ggml-alloc.h ../ggml-alloc.c ../ggml-opencl.h ../ggml-opencl.cpp ../llama.cpp ../llama.h ../llama-*.h ../CMakeLists.txt ../Makefile $DIRNAME"
	chk_and_cp -p ../ggml.[ch] ../k_quants.[ch] ../ggml-alloc.h ../ggml-alloc.c ../ggml-opencl.h ../ggml-opencl.cpp ../llama.cpp ../llama.h ../llama-*.h ../CMakeLists.txt ../Makefile $DIRNAME || die 201 "can't copy files"
	#msg "cp -pr ../examples $DIRNAME"
	chk_and_cp -pr ../examples $DIRNAME || die 202 "can't copy examples files"
	#msg "cp -pr ../tests $DIRNAME"
	chk_and_cp -pr ../tests $DIRNAME || die 203 "can't copy tests files"
	find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;
}

do_cmk()
{
	# in build

	msg "# do cmake"
	msg "rm CMakeCache.txt"
	rm CMakeCache.txt
	msg "cmake .. $CMKOPT"
	cmake .. $CMKOPT || die 301 "cmake failed"
	#msg "cp -p Makefile $DIRNAME/Makefile.build"
	chk_and_cp -p Makefile $DIRNAME/Makefile.build
}

do_test()
{
	# in build

	msg "# testing ..."
	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		make clean || die 401 "make clean failed"
		MKCLEAN=$RET_TRUE
	fi
	msg "make $TESTS"
	make $TESTS || die 402 "make test build failed"
	#msg "cp -p bin/test* $DIRNAME/"
	chk_and_cp -p bin/test* $DIRNAME || die 403 "can't cp tests"
	msg "env $TESTOPT make test"
	env $TESTOPT make test || die 404 "make test failed"
}

do_main()
{
	local DOMAINOPT SUBOPT BINS

	DOMAINOPT="$1"
	SUBOPT="$2"

	# in build

	msg "# executing main ... (DOMAINOPT:$DOMAINOPT SUBOPT:$SUBOPT)"
	# make main
	if [ ! x"$DOMAINOPT" = xNOMAKE ]; then
		if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
			msg "make clean"
			make clean || die 501 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
		msg "make $TARGETS"
		make $TARGETS || die 502 "make main failed"
		BINS=""; for i in $TARGETS ;do BINS="$BINS bin/$i" ;done
		#msg "cp -p $BINS $DIRNAME/"
		chk_and_cp -p $BINS $DIRNAME || die 503 "can't cp main"
	fi

	# main
	if [ ! x"$DOMAINOPT" = xNOEXEC ]; then
		if [ -f ./$DIRNAME/main -a ! x"$SUBOPT" = xGGUF ]; then
			msg "./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"

			#
			msg "./$DIRNAME/main -m ../models/ggml-vic7b-q4_0.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-vic7b-q4_0.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/ggml-vic7b-q4_1.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-vic7b-q4_1.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/ggml-vic7b-q4_0-new.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-vic7b-q4_0-new.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"
			#
			msg "./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q4_0.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q4_0.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_0.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_0.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_1.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_1.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"


			msg "./$DIRNAME/main -m ../models/Wizard-Vicuna-13B-Uncensored.ggml.q4_0.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/Wizard-Vicuna-13B-Uncensored.ggml.q4_0.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"

			# vicuna 1.1 2023.6
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q2_K.bin $MAINOPT $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q2_K.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_L.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_L.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_M.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_M.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_S.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_S.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_0.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_0.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_1.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_1.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_M.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_M.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_S.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_S.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_0.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_0.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_1.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_1.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_M.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_M.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_S.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_S.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q6_K.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q6_K.bin $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q8_0.bin $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q8_0.bin $MAINOPT -s $SEED -p "$PROMPT"
			#
			msg "./$DIRNAME/main -m ../models/7B/ggml-model-f32.bin $MAINOPT -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/7B/ggml-model-f32.bin $MAINOPT -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/7B/ggml-model-q4_0.bin $MAINOPT -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/7B/ggml-model-q4_0.bin $MAINOPT -p "$PROMPT"

		elif [ -f ./$DIRNAME/main ]; then
			# gguf since 2023.8
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q2_K.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q2_K.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q3_K_S.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q3_K_S.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q4_0.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q4_0.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q4_K_M.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q4_K_M.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q5_0.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q5_0.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_S.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_S.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_M.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_M.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q6_0.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q6_0.gguf $MAINOPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q8_0.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q8_0.gguf $MAINOPT -s $SEED -p "$PROMPT"
			#
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q2_K.gguf $MAINOPT -s $SEED -p \"$PROMPTCHAT\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q2_K.gguf $MAINOPT -s $SEED -p "$PROMPTCHAT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q4_K_M.gguf $MAINOPT -s $SEED -p \"$PROMPTCHAT\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q4_K_M.gguf $MAINOPT -s $SEED -p "$PROMPTCHAT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_S.gguf $MAINOPT -s $SEED -p \"$PROMPTJP\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_S.gguf $MAINOPT -s $SEED -p "$PROMPTJP"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_M.gguf $MAINOPT -s $SEED -p \"$PROMPTJP\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_M.gguf $MAINOPT -s $SEED -p "$PROMPTJP"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q8_0.gguf $MAINOPT -s $SEED -p \"$PROMPTJP\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q8_0.gguf $MAINOPT -s $SEED -p "$PROMPTJP"
		else
			msg "no ./$DIRNAME/main, skip executing main"
		fi

		msg "./$DIRNAME/quantize"
		./$DIRNAME/quantize
		msg "./$DIRNAME/quantize-stats"
		./$DIRNAME/quantize-stats
		msg "./$DIRNAME/perplexity"
		./$DIRNAME/perplexity
		msg "./$DIRNAME/embedding"
		./$DIRNAME/embedding
		if [ -f ./$DIRNAME/benchmark-matmult ]; then
			msg "./$DIRNAME/benchmark-matmult"
			./$DIRNAME/benchmark-matmult
		fi
	else
		msg "skip executing main, tests and others"
	fi
}

# yyyymmddHHMMSS filename
get_datefile()
{
	local FILE

	if [ ! $# -ge 1 ]; then
		emsg "get_datefile: RETCODE:$ERR_NOARG: ARG:$*: need FILENAME, error return"
		return $ERR_NOARG
	fi

	FILE="$1"

	xmsg "get_date: FILE:$FILE ARG:$*"

	#if [ ! -f $FILE ]; then
	#	emsg "get_datefile: RETCODE:$ERR_NOTEXISTED: $FILE: not found, error return"
	#	return $ERR_NOTEXISTED
	#fi

	ls -ltr --time-style=+%Y%m%d%H%M%S $FILE | awk '
	BEGIN { XDT="0"; XNM="" }
	#{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; printf("%s %s D:%s %s\n",XDT,XNM,DT,NM) >> /dev/stderr }
	{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; }
	END { printf("%s %s\n",XDT,XNM) }
	'

	return $?
}
test_get_datefile()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1

	DF=`get_datefile`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile"

	DF=`get_datefile $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_datefile $NGFILE"
	DF=`get_datefile $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile $OKFILE"
	DF=`get_datefile $NGFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_datefile $NGFILE2"
	DF=`get_datefile $OKFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile $OKFILE2"

	rm $OKFILE $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_datefile"; VERBOSE=2; test_get_datefile; exit 0

# Ymd|ymd|md|full yyyymmddHHMMSS filename
get_datefile_date()
{
	local DTFILE

	if [ ! $# -ge 3 ]; then
		emsg "get_datefile_date: RETCODE:$ERR_NOARG: ARG:$*: need OPT DATE FILENAME, error return"
		return $ERR_NOARG
	fi

	OPT="$1"
	shift
	DTFILE="$*" # date filename

	xmsg "get_datefile_date: OPT:$OPT DTFILE:$DTFILE"

	echo $DTFILE | awk -v OPT=$OPT '{ T=$0; sub(/[\n\r]$/,"",T); D=substr(T,1,14); if (OPT=="Ymd") { print substr(D,1,8) } else if (OPT=="ymd") { print substr(D,3,6) } else if (OPT=="md") { print substr(D,5,4) } else if (OPT=="full") { print D } else { print D } }'
	return $?
}
test_get_datefile_date()
{
	local DT OKFILE NGFILE DF RETCODE

	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	ls $OKFILE $NGFILE

	DF=`get_datefile_date`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date"
	DF=`get_datefile_date md`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date md"
	DF=`get_datefile_date $DT`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date $DT"
	DF=`get_datefile_date $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date $OKFILE"
	DF=`get_datefile_date $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date $DT $OKFILE"

	DF=`get_datefile_date Ymd $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date Ymd $DT $OKFILE"
	DF=`get_datefile_date ymd $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date ymd $DT $OKFILE"
	DF=`get_datefile_date md $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $OKFILE"
	DF=`get_datefile_date full $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date full $DT $OKFILE"
	DF=`get_datefile_date ngopt $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date ngopt $DT $OKFILE"
	DF=`get_datefile_date md $DT $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $NGFILE"

	DF=`get_datefile_date Ymd $DT $OKFILE extra`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date Ymd $DT $OKFILE extra"
	DF=`get_datefile_date md $DT $OKFILE extra`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $OKFILE extra"
	DF=`get_datefile_date md $DT $NGFILE extra`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $NGFILE extra"

	rm $OKFILE $NGFILE
}
#msg "test_get_datefile_date"; VERBOSE=2; test_get_datefile_date; exit 0

# yyyymmddHHMMSS filename
get_datefile_file()
{
	local DTFILE

	if [ ! $# -ge 2 ]; then
		emsg "get_datefile_file: RETCODE:$ERR_NOARG: ARG:$*: need DATE FILENAME, error return"
		return $ERR_NOARG
	fi

	DTFILE="$*" # date filename

	xmsg "get_datefile_file: DTFILE:$DTFILE"

	echo $DTFILE | awk '{ T=$0; sub(/[\n\r]$/,"",T); F=substr(T,16); print F }'
}
test_get_datefile_file()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1

	DF=`get_datefile_file`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file"

	DF=`get_datefile_file md`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file md"
	DF=`get_datefile_file $DT`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file $DT"
	DF=`get_datefile_file $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file $OKFILE"

	DF=`get_datefile_file $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $OKFILE"
	DF=`get_datefile_file $DT $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $NGFILE"
	DF=`get_datefile_file $DT $OKFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $OKFILE2"
	DF=`get_datefile_file $DT $NGFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $NGFILE2"

	rm $OKFILE $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_datefile_file"; VERBOSE=2; test_get_datefile_file; exit 0

# copy srcfile to dstfile.mmdd and dstfile
cp_script()
{
	local SRC DST DFSRC MDSRC DSTDT

	if [ ! $# -ge 2 ]; then
		emsg "cp_script: RETCODE:$ERR_NOARG: ARG:$*: need SRC DST, error return"
		return $ERR_NOARG
	fi

	SRC="$1"
	DST="$2"
	xmsg "cp_script: SRC:$SRC"
	xmsg "cp_script: DST:$DST"

	if [ ! -f "$SRC" ]; then
		emsg "cp_script: RETCODE:$ERR_NOTEXISTED: $SRC: not found, error return"
		return $ERR_NOTEXISTED
	fi
	if [ "$SRC" = "$DST" ]; then
		emsg "cp_script: RETCODE:$ERR_BADARG: $SRC: $DST: same file, error return"
		return $ERR_BADARG
	fi

	DFSRC=`get_datefile "$SRC"`
	xxmsg "cp_script: DFSRC:$DFSRC"
	MDSRC=`get_datefile_date md $DFSRC`
	xxmsg "cp_script: MDSRC:$MDSRC"
	DSTDT="${DST}.$MDSRC"
	msg "cp -p \"$SRC\" \"$DSTDT\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DSTDT"
	fi
	msg "cp -p \"$SRC\" \"$DST\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DST"
	fi
}
test_cp_script()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	DT=`date '+%m%d'`
	msg "DT:$DT0"
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}* $TMPDIR1"
	ls $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}* $TMPDIR1

	cp_script
	func_test $ERR_NOARG "no arg: cp_script"

	msg "ls -l $OKFILE $NGFILE $OKFILE2 $NGFILE2"
	cp_script $NGFILE
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $NGFILE"
	cp_script $OKFILE
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $OKFILE"
	cp_script $NGFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $NGFILE2"
	cp_script $OKFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $OKFILE2"

	cp_script $NGFILE $NGFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: cp_script $NGFILE $NGFILE2"
	cp_script $OKFILE $OKFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $OKFILE2"
	cp_script $OKFILE $NGFILE
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $NGFILE"
	rm $NGFILE
	cp_script $OKFILE $NGFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $NGFILE2"
	rm $NGFILE2


	msg "rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
	rmdir $TMPDIR1
	msg "ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
}
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_TRUE; test_cp_script; exit 0
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_FALSE; test_cp_script; exit 0

git_script()
{
	msg "# git push scripts ..."

	local DT0 ADDFILES COMMITFILES
	local DFUPDATE DFFIXSH DFMKZIP FUPDATE FFIXSH FMKZIP
	local DFUPDATEG DFFIXSHG DFMKZIPG FUPDATEG FFIXSHG FMKZIPG

	DT0=`date '+%m%d'`
	msg "DT0:$DT0"

	ADDFILES=""
	COMMITFILES=""

	# BASEDIR
	msg "cd $BASEDIR"
	cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
	fi
	DFUPDATE=`get_datefile "${UPDATENAME}"`
	DFFIXSH=`get_datefile "${FIXSHNAME}*"`
	DFMKZIP=`get_datefile "${MKZIPNAME}"`
	FUPDATE=`get_datefile_file $DFUPDATE`
	FFIXSH=`get_datefile_file $DFFIXSH`
	FMKZIP=`get_datefile_file $DFMKZIP`
	msg "FUPDATE:$FUPDATE"
	msg "FFIXSH:$FFIXSH"
	msg "FMKZIP:$FMKZIP"

	# git SCRIPT branch
	msg "cd $BASEDIR/$TOPDIR"
	cd $BASEDIR/$TOPDIR
	msg "git branch"
	git branch
	msg "git checkout $SCRIPT"
	git checkout $SCRIPT

	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
	fi
	# G git
	DFUPDATEG=`get_datefile "${UPDATENAME}"`
	DFFIXSHG=`get_datefile "${FIXSHNAME}*"`
	DFMKZIPG=`get_datefile "${MKZIPNAME}"`
	FUPDATEG=`get_datefile_file $DFUPDATEG`
	FFIXSHG=`get_datefile_file $DFFIXSHG`
	FMKZIPG=`get_datefile_file $DFMKZIPG`
	msg "FUPDATEG:$FUPDATEG"
	msg "FFIXSHG:$FFIXSHG"
	msg "FMKZIPG:$FMKZIPG"

	msg "diff $FUPDATEG $BASEDIR/$FUPDATE"
	if [ $VERBOSE -ge 1 ]; then
		diff $FUPDATEG $BASEDIR/$FUPDATE
	else
		diff $FUPDATEG $BASEDIR/$FUPDATE > /dev/null
	fi
	if [ $? -eq $RET_OK ]; then
		msg "same: no copy: $BASEDIR/$FUPDATE $FUPDATEG"
	else
		msg "diff: copy: $BASEDIR/$FUPDATE $FUPDATEG"
		cp_script $BASEDIR/$FUPDATE $FUPDATEG
		COMMITFILES="$COMMITFILES $FUPDATEG"
	fi

	if [ $FFIXSH = $FFIXSHG ]; then
		# diff, copy
		msg "diff $FFIXSHG $BASEDIR/$FFIXSH"
		if [ $VERBOSE -ge 1 ]; then
			diff $FFIXSHG $BASEDIR/$FFIXSH
		else
			diff $FFIXSHG $BASEDIR/$FFIXSH > /dev/null
		fi
		if [ $? -eq $RET_OK ]; then
			msg "same: no copy: $BASEDIR/$FFIXSH $FFIXSHG"
		else
			msg "diff: copy: $BASEDIR/$FFIXSH $FFIXSHG"
			cp_script $BASEDIR/$FFIXSH $FFIXSHG
			COMMITFILES="$COMMITFILES $FFIXSHG"
		fi
	else
		# always copy
		msg "always: copy: $BASEDIR/$FFIXSH $FFIXSH"
		msg "cp -p $BASEDIR/$FFIXSH $FFIXSH"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			cp -p $BASEDIR/$FFIXSH $FFIXSH
			ADDFILES="$ADDFILES $FFIXSH"
			COMMITFILES="$COMMITFILES $FFIXSH"
		fi
	fi

	msg "diff $FMKZIPG $BASEDIR/$FMKZIP"
	if [ $VERBOSE -ge 1 ]; then
		diff $FMKZIPG $BASEDIR/$FMKZIP
	else
		diff $FMKZIPG $BASEDIR/$FMKZIP > /dev/null
	fi
	if [ $? -eq $RET_OK ]; then
		msg "same: no copy: $BASEDIR/$FMKZIP $FMKZIPG"
	else
		msg "diff: copy: $BASEDIR/$FMKZIP $FMKZIPG"
		cp_script $BASEDIR/$FMKZIP $FMKZIPG
		COMMITFILES="$COMMITFILES $FMKZIPG"
	fi

	msg "ADDFILES:$ADDFILES"
	msg "COMMITFILES:$COMMITFILES"
	if [ ! x"$COMMITFILES" = x ]; then
		# avoid error: pathspec 'fix1202.sh' did not match any file(s) known to git.
		msg "git fetch"
		git fetch
		if [ ! x"$ADDFILES" = x ]; then
			msg "git add $ADDFILES"
			git add $ADDFILES
		fi
		msg "git commit -m \"update scripts\" $COMMITFILES"
		git commit -m "update scripts" $COMMITFILES
		msg "git status"
		git status
		msg "git push origin $SCRIPT"
		git push origin $SCRIPT
	fi

	# back
	msg "git checkout $BRANCH"
	git checkout $BRANCH
}
#msg "do_script"; NOEXEC=$RET_TRUE; VERBOSE=2; do_script; exit 0

###
msg "# start"

# warning:  Clock skew detected.  Your build may be incomplete.
msg "sudo ntpdate ntp.nict.jp"
sudo ntpdate ntp.nict.jp

# check
if [ ! -d $TOPDIR ]; then
	die $ERR_NOTOPDIR "# can't find $TOPDIR, exit"
fi
if [ ! -d $BUILDPATH ]; then
	msg "mkdir -p $BUILDPATH"
	mkdir -p $BUILDPATH
	if [ ! -d $BUILDPATH ]; then
		die $ERR_NOBUILDDIR "# can't find $BUILDPATH, exit"
	fi
fi

msg "cd $BUILDPATH"
cd $BUILDPATH

msg "git branch"
git branch
msg "git checkout $BRANCH"
git checkout $BRANCH

msg "mkdir $DIRNAME"
mkdir $DIRNAME
if [ ! -e $DIRNAME ]; then
	die $ERR_NOTEXISTED "no directory: $DIRNAME"
fi

case $CMD in
*sy*)		do_sync;;
*sync*)		do_sync;;
*)		msg "no sync";;
esac

case $CMD in
*cp*)		do_cp;;
*)		msg "no copy";;
esac

case $CMD in
*cmk*)		do_cmk;;
*cmake*)	do_cmk;;
*)		msg "no cmake";;
esac

case $CMD in
*tst*)		do_test;;
*test*)		do_test;;
*)		msg "no make test";;
esac

case $CMD in
*nm*)		do_main NOEXEC;;
*nomain*)	do_main NOEXEC;;
*mainonly*)	do_main NOMAKE;;
*mainggufonly*)	do_main NOMAKE GGUF;;
*ggufonly*)	do_main NOMAKE GGUF;;
*main*)		do_main;;
*)		msg "no make main";;
esac

case $CMD in
*script*)	git_script;;
*scr*)		git_script;;
*)		msg "no git push script";;
esac

msg "# done."


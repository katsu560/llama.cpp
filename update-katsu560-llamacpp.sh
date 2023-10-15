#!/bin/sh

# update katsu560/llama.cpp
# T902 Intel(R) Core(TM) i5-3320M CPU @ 2.60GHz  2C/4T F16C,AVX IvyBridge/3rd Gen.
# AH   Intel(R) Core(TM) i3-10110U CPU @ 2.10GHz  2C/4T F16C,AVX,AVX2,FMA CometLake/10th Gen.

MYNAME=update-katsu560-llamacpp.sh

TOPDIR=llama.cpp
BUILDPATH="$TOPDIR/build"

#CMKOPT=
OPENBLAS=`grep -sr LLAMA_OPENBLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*LLAMA_OPENBLAS.*/LLAMA_OPENBLAS/'`
BLAS=`grep -sr LLAMA_BLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*LLAMA_BLAS.*/LLAMA_BLAS/'`
if [ ! x"$OPENBLAS" = x ]; then
	# old CMakeLists.txt
	LLAMA_OPENBLAS="LLAMA_OPENBLAS"
	BLASVENDOR=""
	echo "# use LLAMA_OPENBLAS=$LLAMA_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
if [ ! x"$BLAS" = x ]; then
	# new CMakeLists.txt from 2023.6
	LLAMA_OPENBLAS="LLAMA_BLAS"
	BLASVENDOR="-DLLAMA_BLAS_VENDOR=OpenBLAS"
	echo "# use LLAMA_OPENBLAS=$LLAMA_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
CMKOPTNOAVX="-DLLAMA_AVX=OFF -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=OFF -D$LLAMA_OPENBLAS=OFF -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPTAVX="-DLLAMA_AVX=ON -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=ON -D$LLAMA_OPENBLAS=ON $BLASVENDOR -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPTAVX2="-DLLAMA_AVX=ON -DLLAMA_AVX2=ON -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=ON -DLLAMA_F16C=ON -D$LLAMA_OPENBLAS=ON $BLASVENDOR -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
TESTOPT="GGML_NLOOP=1 GGML_NTHREADS=4"
#TESTS="test-quantize-fns test-quantize-perf test-sampling test-tokenizer-0"
#TESTS="test-quantize-fns test-quantize-perf test-sampling test-tokenizer-0 test-grad0"
#TESTS="test-quantize-fns test-quantize-perf test-sampling test-grad0"
TESTS="test-quantize-fns test-quantize-perf"
TESTSCPP="test-grad0 test-llama-grammar test-grammar-parser test-rope test-sampling test-tokenizer-0 test-tokenizer-0-llama test-tokenizer-0-falcon test-tokenizer-1 test-tokenizer-1-llama test-tokenizer-1-bpe"
TESTSC="test-c"
NOTEST="test-double-float test-opt"
for i in $TESTSCPP
do
	if [ -f $TOPDIR/tests/$i.cpp ]; then
		TESTS="$TESTS $i"
	fi
done
for i in $TESTSC
do
	if [ -f $TOPDIR/tests/$i.c ]; then
		TESTS="$TESTS $i"
	fi
done
ALLBINSUP="main quantize quantize-stats perplexity embedding save-load-state"
ALLBINS="main quantize quantize-stats perplexity embedding save-load-state benchmark vdot q8dot"
BINSDIR="baby-llama batched beam-search export-lora finetune parallel server simple speculative batched-bench llava"
NOBINS="gguf llama-bench infill"
for i in $BINSDIR
do
	if [ -d $TOPDIR/examples/$i ]; then
		ALLBINS="$ALLBINS $i"
	fi
done
BINSCPP="benchmark/benckmark-matmult embd-input/embd-input-test"
for i in $BINSCPP
do
	if [ -d $TOPDIR/examples/$i.cpp ]; then
		BIN=`basename $i`
		ALLBINS="$ALLBINS $BIN"
	fi
done

CMKOPT=""
CMKOPT2=""

MKCLEAN=0
NODIE=0
NOCLEAN=0
NOCOPY=0

# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
ESC=$(printf '\033')
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
ESCRESET="${ESC}[0m"

msg()
{
	echo "$MYNAME: $*"
}

die()
{
	CODE=$1
	shift
	msg "${ESCRED}$*${ESCBACK}"
	if [ $NODIE = 0 ]; then
		exit $CODE
	fi
}

chk_and_cp()
{
	#msg "chk_and_cp: nargs:$# args:$*"
        chkfiles="$*"
        if [ x"$chkfiles" = x ]; then
                msg "chk_and_cp: no cpopt"
                return 1
        fi

	# get cp opt
        cpopt=$1
        shift
	#msg "chk_and_cp: n:$# args:$*"

        chkfiles="$*"
	ncp=$#
	dstdir=
	if [ $# -ge 2 ]; then
		dstdir=`eval echo '$'$#`
		if [ ! -d $dstdir ]; then
			dstdir=
		fi
	fi
	#msg "chk_and_cp: cpopt:$cpopt ncp:$ncp chkfiles:$chkfiles dstdir:$dstdir"

        cpfiles=
        for i in $chkfiles
        do
		#msg "chk_and_cp: ncp:$ncp i:$i"
		if [ $ncp -le 1 ]; then
			break
		fi

		if [ -f $i ]; then
			cpfiles="$cpfiles $i"
		elif [ -d $i -a ! "x$i" = x"$dstdir" ]; then
			cpfiles="$cpfiles $i"
		fi
	
		ncp=`expr $ncp - 1`
	done

	#msg "chk_and_cp: cpopt:$cpopt ncp:$ncp cpfiles:$cpfiles dstdir:$dstdir"
	if [ x"$cpfiles" = x ]; then
		msg "chk_and_cp: no cpfiles"
		return 2
	fi

	if [ x"$dstdir" = x ]; then
		msg "chk_and_cp: no dstdir"
		return 3
	elif [ ! -d $dstdir ]; then
		msg "chk_and_cp: not dir"
		return 4
	fi

        msg "cp $cpopt $cpfiles $dstdir"
        cp $cpopt $cpfiles $dstdir || return 2

        return 0
}

# chk_and_cp test code
func_test()
{
	RETCODE=$?

	OKCODE=$1
	shift
	TESTMSG="$*"

	if [ $RETCODE -eq $OKCODE ]; then
		msg "ret:$RETCODE expected:$OKCODE $TESTMSG"
	else
		msg "ret:$RETCODE expected:$OKCODE ${ESCRED}$TESTMSG${ESCBACK}"
	fi
}

test_chk_and_cp()
{
	# test files and dir, test-0.$$, testdir-0.$$: not existed
	touch test.$$ test-1.$$ test-2.$$
	mkdir testdir.$$
	ls -ld test.$$ test-1.$$ test-2.$$ testdir.$$
	msg "test_chk_and_cp: create test.$$ test-1.$$ test-2.$$ testdir.$$"

	# test code
	chk_and_cp
	func_test 1 "no cpopt: chk_and_cp"

	chk_and_cp -p
	func_test 2 "no cpfiles: chk_and_cp -p"

	chk_and_cp -p test-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$"
	chk_and_cp -p test.$$
	func_test 2 "no cpfiles: chk_and_cp -p test.$$"
	chk_and_cp -p testdir-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p testdir-0.$$"
	chk_and_cp -p testdir.$$
	func_test 2 "no cpfiles: chk_and_cp -p testdir.$$"

	chk_and_cp -p test-0.$$ test-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ test-0.$$"
	chk_and_cp -p test-0.$$ test.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ test.$$"
	chk_and_cp -p test-0.$$ testdir-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ testdir-0.$$"
	chk_and_cp -p test-0.$$ testdir.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ testdir.$$"

	chk_and_cp -p test.$$ test-0.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ test-0.$$"
	chk_and_cp -p test.$$ test.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ test.$$"
	chk_and_cp -p test.$$ test-1.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ test-1.$$"
	chk_and_cp -p test.$$ testdir-0.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ testdir-0.$$"
	chk_and_cp -p test.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-0.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test-0.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test-1.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir-0.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ testdir-0.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ testdir.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$


	rm test.$$ test-1.$$ test-2.$$
	rm -rf testdir.$$
	ls -ld test.$$ test-1.$$ test-2.$$ testdir.$$
	msg "test_chk_and_cp: rm test.$$ test-1.$$ test-2.$$ testdir.$$"
}
#msg "test_chk_and_cp"; test_chk_and_cp; exit 0

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
}

###
if [ x"$1" = x -o $# -lt 3 ]; then
	usage
	exit 1
fi

ALLOPT="$*"
OPTLOOP=1
while [ $OPTLOOP -eq 1 ];
do
	case $1 in
	-h|--help)	usage; exit 1;;
	-nd|--nodie)	NODIE=1;;
	-nc|--noclean)	NOCLEAN=1;;
	-ncp|--nocopy)	NOCOPY=1;;
	-up)		ALLBINS="$ALLBINSUP";;
	-noavx)		CMKOPT="$CMKOPTNOAVX";;
	-avx)		CMKOPT="$CMKOPTAVX";;
	-avx2)		CMKOPT="$CMKOPTAVX2";;
	-qkk64)		CMKOPT2="-DLLAMA_QKK_64=ON";;
	-s|-seed) shift; SEEDOPT=$1;;
	*)		OPTLOOP=0; break;;
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
	chk_and_cp -p ../ggml.[ch] ../k_quants.[ch] ../ggml-alloc.h ../ggml-alloc.c ../ggml-opencl.h ../ggml-opencl.cpp ../llama.cpp ../llama.h ../llama-*.h ../CMakeLists.txt ../Makefile $DIRNAME || die 21 "can't copy files"
	#msg "cp -pr ../examples $DIRNAME"
	chk_and_cp -pr ../examples $DIRNAME || die 22 "can't copy examples files"
	#msg "cp -pr ../tests $DIRNAME"
	chk_and_cp -pr ../tests $DIRNAME || die 23 "can't copy tests files"
	find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;
}

do_cmk()
{
	# in build

	msg "# do cmake"
	msg "rm CMakeCache.txt"
	rm CMakeCache.txt
	msg "cmake .. $CMKOPT"
	cmake .. $CMKOPT || die 31 "cmake failed"
	#msg "cp -p Makefile $DIRNAME/Makefile.build"
	chk_and_cp -p Makefile $DIRNAME/Makefile.build
}

do_test()
{
	# in build

	msg "# testing ..."
        if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
                MKCLEAN=1
                msg "make clean"
                make clean || die 41 "make clean failed"
        fi
	msg "make $TESTS"
	make $TESTS || die 42 "make test build failed"
	#msg "cp -p bin/test* $DIRNAME/"
	chk_and_cp -p bin/test* $DIRNAME || die 43 "can't cp tests"
	msg "env $TESTOPT make test"
	env $TESTOPT make test || die 44 "make test failed"
}

do_main()
{
	MAINOPT="$1"
	SUBOPT="$2"

	# in build

	msg "# executing main ... (MAINOPT:$MAINOPT SUBOPT:$SUBOPT)"
	# make main
	if [ ! x"$MAINOPT" = xNOMAKE ]; then
                if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
                        MKCLEAN=1
                        msg "make clean"
                        make clean || die 51 "make clean failed"
                fi
		msg "make $ALLBINS"
		make $ALLBINS || die 52 "make main failed"
		BINTESTS=""; for i in $ALLBINS ;do BINTESTS="$BINTESTS bin/$i" ;done
		msg "cp -p $BINTESTS $DIRNAME/"
		cp -p $BINTESTS $DIRNAME || die 53 "can't cp main"
	fi
	# main
	PROMPT="Building a website can be done in 10 simple steps:"
	PROMPTCHAT="Tell me about FIFA worldcup 2022 Qatar. What country win the match?"
	PROMPTJP="日本語で回答ください。京都について教えてください"
	SEED=1681527203
	OPT="--log-disable"

	if [ ! x"$MAINOPT" = xNOEXEC ]; then
		if [ -f ./$DIRNAME/main -a ! x"$SUBOPT" = xGGUF ]; then
			msg "./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $OPT -s $SEED -p "$PROMPT"

			#
			msg "./$DIRNAME/main -m ../models/ggml-vic7b-q4_0.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-vic7b-q4_0.bin -n 512 $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/ggml-vic7b-q4_1.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-vic7b-q4_1.bin -n 512 $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/ggml-vic7b-q4_0-new.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/ggml-vic7b-q4_0-new.bin -n 512 $OPT -s $SEED -p "$PROMPT"
			#
			msg "./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q4_0.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q4_0.bin -n 512 $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_0.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_0.bin -n 512 $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_1.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q5_1.bin -n 512 $OPT -s $SEED -p "$PROMPT"


			msg "./$DIRNAME/main -m ../models/Wizard-Vicuna-13B-Uncensored.ggml.q4_0.bin -n 512 $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/Wizard-Vicuna-13B-Uncensored.ggml.q4_0.bin -n 512 $OPT -s $SEED -p "$PROMPT"

			# vicuna 1.1 2023.6
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q2_K.bin $OPT $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q2_K.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_L.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_L.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_M.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_M.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_S.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q3_K_S.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_0.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_0.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_1.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_1.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_M.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_M.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_S.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q4_K_S.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_0.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_0.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_1.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_1.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_M.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_M.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_S.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q5_K_S.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q6_K.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q6_K.bin $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q8_0.bin $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q8_0.bin $OPT -s $SEED -p "$PROMPT"
			#
			msg "./$DIRNAME/main -m ../models/7B/ggml-model-f32.bin $OPT -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/7B/ggml-model-f32.bin $OPT -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/7B/ggml-model-q4_0.bin $OPT -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/7B/ggml-model-q4_0.bin $OPT -p "$PROMPT"

		elif [ -f ./$DIRNAME/main ]; then
			# gguf since 2023.8
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q2_K.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q2_K.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q3_K_S.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q3_K_S.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q4_0.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q4_0.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q4_K_M.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q4_K_M.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q5_0.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q5_0.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_S.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_S.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_M.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q5_K_M.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q6_0.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q6_0.gguf $OPT -s $SEED -p "$PROMPT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b.Q8_0.gguf $OPT -s $SEED -p \"$PROMPT\""
			./$DIRNAME/main -m ../models/llama-2-7b.Q8_0.gguf $OPT -s $SEED -p "$PROMPT"
			#
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q2_K.gguf $OPT -s $SEED -p \"$PROMPTCHAT\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q2_K.gguf $OPT -s $SEED -p "$PROMPTCHAT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q4_K_M.gguf $OPT -s $SEED -p \"$PROMPTCHAT\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q4_K_M.gguf $OPT -s $SEED -p "$PROMPTCHAT"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_S.gguf $OPT -s $SEED -p \"$PROMPTJP\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_S.gguf $OPT -s $SEED -p "$PROMPTJP"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_M.gguf $OPT -s $SEED -p \"$PROMPTJP\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q3_K_M.gguf $OPT -s $SEED -p "$PROMPTJP"
			msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q8_0.gguf $OPT -s $SEED -p \"$PROMPTJP\""
			./$DIRNAME/main -m ../models/llama-2-7b-chat.Q8_0.gguf $OPT -s $SEED -p "$PROMPTJP"
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

###
msg "# start"

# warning:  Clock skew detected.  Your build may be incomplete.
msg "sudo ntpdate ntp.nict.jp"
sudo ntpdate ntp.nict.jp

# check
if [ ! -d $TOPDIR ]; then
        msg "# can't find $TOPDIR, exit"
        exit 2
fi
if [ ! -d $BUILDPATH ]; then
        msg "mkdir -p $BUILDPATH"
        mkdir -p $BUILDPATH
        if [ ! -d $BUILDPATH ]; then
                msg "# can't find $BUILDPATH, exit"
                exit 3
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
        msg "no directory: $DIRNAME"
        exit 11
fi

case $CMD in
*sy*)	do_sync;;
*sync*)	do_sync;;
*)	msg "no sync";;
esac

case $CMD in
*cp*)	do_cp;;
*)	msg "no copy";;
esac

case $CMD in
*cmk*)	do_cmk;;
*cmake*) do_cmk;;
*)	msg "no cmake";;
esac

case $CMD in
*tst*)	do_test;;
*test*)	do_test;;
*)	msg "no make test";;
esac

case $CMD in
*nm*)		do_main NOEXEC;;
*nomain*)	do_main NOEXEC;;
*mainonly*)	do_main NOMAKE;;
*mainggufonly*)	do_main NOMAKE GGUF;;
*ggufonly*)	do_main NOMAKE GGUF;;
*main*)		do_main;;
*)	msg "no make main";;
esac

msg "# done."


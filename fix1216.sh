#!/bin/sh

MYNAME=fix1216.sh

TOPDIR=llama.cpp
NAMEBASE=fix

CMD=chk

###
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

###
#do_cp ggml.c	ggml.c.0625	ggml.c.0625mod

# diff old $1 $2 $OPT
diff_old()
{
	#msg "do_diff_old CMD:$CMD $1 $2 $3 $4  OPT:$OPT"
	# in $TOPDIR

	if [ ! x"$OPT" = x ]; then
		NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][0-9][0-9]\)/\2/'`
		#msg "diff: NEW:$NEWDATE"
		if [ ! x"$NEWDATE" = x"$OPT" ]; then
			msg "diff: skip $2 by $NEWDATE"
			return
		fi
	fi

	#msg "diff_old $1 $2"
	NEW="./$2"
	OLD=`find . -path './'$1'.[0-9][0-9][0-9][0-9]' | awk -v NEW="$NEW" '
	$0 != NEW { OLD=$0 }
	END   { print OLD }'`
	msg "${ESCGREEN}diff -c $OLD $NEW${ESCBACK}"
	diff -c $OLD $NEW
}

# do_cp target origin modified
do_cp()
{
	#msg "do_cp CMD:$CMD $1 $2 $3 $4"

	FILES="$1 $2"
	if [ -f $3 ]; then
		FILES="$FILES $3"
	fi
	if [ $# = 4 ]; then
		if [ -f $4 ]; then
			FILES="$FILES $4"
		fi
	fi

	# check
	case $CMD in
	chk|check)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $1 ]; then
			msg "${ESCGREEN}diff -c $2 $1${ESCBACK}"
			diff -c $2 $1
			#msg "RESULT: $RESULT $?"
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod|checkmod)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $3 ]; then
			msg "${ESCGREEN}diff -c $1 $3${ESCBACK}"
			diff -c $1 $3
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod2|checkmod2)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "${ESCGREEN}diff -c $1 $4${ESCBACK}"
				diff -c $1 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "${ESCGREEN}diff -c $1 $3${ESCBACK}"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "${ESCGREEN}diff -c $1 $3${ESCBACK}"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	chkmod12|checkmod12)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "${ESCGREEN}diff -c $3 $4${ESCBACK}"
				diff -c $3 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "${ESCGREEN}diff -c $2 $3${ESCBACK}"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "${ESCGREEN}diff -c $2 $3${ESCBACK}"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	master)
		msg "cp -p $2 $1"
		cp -p $2 $1
		RESULT=`expr $RESULT + $?`
		;;
	mod)
		if [ -f $3 ]; then
			msg "cp -p $3 $1"
			cp -p $3 $1
			RESULT=`expr $RESULT + $?`
		fi
		;;
	mod2)
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "cp -p $4 $1"
				cp -p $4 $1
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "cp -p $3 $1"
				cp -p $3 $1
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "cp -p $3 $1"
				cp -p $3 $1
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	diff)
		diff_old $1 $2
		;;
	*)	msg "${ESCRED}unknown command: $CMD${ESCBACK}"
		;;
	esac
}

do_mk()
{
	msg "making new $NAMEBASE script $NAMEBASE$DT1.sh and copy backup files ..."

#do_cp ggml.c	     ggml.c.0420	     ggml.c.0420mod    ggml.c.0420mod2
#do_cp examples/CMakeLists.txt examples/CMakeLists.txt.0413 examples/CMakeLists.txt.0415mod
	cat $MYNAME | awk -v DT0=$DT0 -v DT1=$DT1 -v TOP=$TOPDIR '
	function exists(file) {
		n=(getline _ < file);
		printf "# n:%d %s\n",n,file;
		if (n > 0) {
			return 1; # found
		} else if (n == 0) {
			return 1; # empty
		}
		return 0; # error
	}
	function update(L) {
		NARG=split(L, ARG, /[ \t]/);
		TOPFILE=TOP "/" ARG[2]
		TOPFILEDT1=TOP "/" ARG[2] "." DT1
		if (exists(TOPFILE)==0) { printf "# %s\n",L; return 1; }
		CMD="date '+%m%d' -r " TOPFILE;
		CMD | getline; DT=$0;
		TOPFILEDT=TOP "/" ARG[2] "." DT
		printf "do_cp %s\t%s.%s\t%s.%smod\n",ARG[2],ARG[2],DT,ARG[2],DT1;
		if (exists(TOPFILEDT)==1) { printf "# %s skip cp\n",TOPFILEDT; return 0; }
		if (DT==DT1) { CMD="cp -p " TOPFILE " " TOPFILEDT1; print CMD > stderr; system(CMD); }
		return 0;
	}
	BEGIN	   { stderr="/dev/stderr"; st=1 }
	st==1 && /^MYNAME=/     { L=$0; sub(DT0, DT1, L); print L; st=2; next }
	st==2 && /^usage/       { L=$0; print L; st=3; next }
	st==3 && /^do_cp /      { L=$0; update(L); next }
	st==3		   { L=$0; gsub(DT0, DT1, L); print L; next }
				{ L=$0; print L; next }
	' - > $NAMEBASE$DT1.sh

	msg "$NAMEBASE$DT1.sh created"
}

usage()
{
	echo "usage: $MYNAME [-h] chk|chkmod|chkmod2|chkmod12|master|mod|mod2|diff|mk|new [DT]"
	echo "-h ... this help message"
	echo "chk ... diff master"
	echo "chkmod ... diff mod"
	echo "chkmod2 ... diff mod2"
	echo "chkmod12 ... diff mod mod2"
	echo "master ... cp master files on 1216"
	echo "mod ... cp mod files on 1216"
	echo "mod2 ... cp mod2 files on 1216"
	echo "diff [DT] ... diff old and new, new on DT only if set DT"
	echo "mk [DT] ... create new shell script"
	echo "new [DT] ... show new files since DT"
}

###
if [ x"$1" = x -o x"$1" = "x-h" ]; then
	usage
	exit 1
fi
ORGCMD="$1"
CMD="$1"
OPT="$2"
msg "CMD: $CMD"
msg "OPT: $OPT"

if [ $CMD = "mk" ]; then
	DT0=`echo $MYNAME | sed -e 's/'$NAMEBASE'//' -e 's/.sh//'`
	DT1=`date '+%m%d'`
	# overwrite
	if [ ! x"$OPT" = x ]; then
		DT1="$OPT"
	fi
	msg "DT0: $DT0  DT1: $DT1"
	do_mk $DT0 $DT1
	exit 0
fi
if [ $CMD = "new" ]; then
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt.1001
	#-rw-r--r-- 1 user user 5898 Oct  1 04:40 ggml/README.md
	DT1=`date '+%m%d'`
	#NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][0-9][0-9]\)/\2/'`
	#find $TOPDIR -type f -mtime 0 -exec ls -l '{}' \; | awk -v DT1=$DT1 '
	find $TOPDIR -type f -mtime 0 | awk -v DT1=$DT1 '
	BEGIN { PREV="" }
	#{ print "line: ",$0; }
	#{ ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	#END { ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	{ ADDDT=PREV "." DT1; if (ADDDT==$0) { PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	END { ADDDT=PREV "." DT1; if (ADDDT==$0) { ; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	' -
	exit 0
fi


###
if [ ! -d $TOPDIR ]; then
	msg "no $TOPDIR, exit"
	exit 3
fi
cd $TOPDIR

msg "git branch"
git branch

# check:  ls -l target origin modified
# revert: cp -p origin target
# revise: cp -p modifid target
#
# do_cp target origin(master) modified(gq)
RESULT=0
# n:1 llama.cpp/CMakeLists.txt
do_cp CMakeLists.txt	CMakeLists.txt.1216	CMakeLists.txt.1216mod
# n:-1 llama.cpp/CMakeLists.txt.1216
# n:1 llama.cpp/Makefile
do_cp Makefile	Makefile.1216	Makefile.1216mod
# n:-1 llama.cpp/Makefile.1216
# n:1 llama.cpp/ggml.h
do_cp ggml.h	ggml.h.1216	ggml.h.1216mod
# n:-1 llama.cpp/ggml.h.1216
# n:1 llama.cpp/ggml.c
do_cp ggml.c	ggml.c.1216	ggml.c.1216mod
# n:-1 llama.cpp/ggml.c.1216
# n:1 llama.cpp/ggml-opencl.h
do_cp ggml-opencl.h	ggml-opencl.h.0616	ggml-opencl.h.1216mod
# n:1 llama.cpp/ggml-opencl.h.0616
# llama.cpp/ggml-opencl.h.0616 skip cp
# n:1 llama.cpp/ggml-opencl.cpp
do_cp ggml-opencl.cpp	ggml-opencl.cpp.1216	ggml-opencl.cpp.1216mod
# n:-1 llama.cpp/ggml-opencl.cpp.1216
# n:1 llama.cpp/ggml-alloc.h
do_cp ggml-alloc.h	ggml-alloc.h.1216	ggml-alloc.h.1216mod
# n:-1 llama.cpp/ggml-alloc.h.1216
# n:1 llama.cpp/ggml-alloc.c
do_cp ggml-alloc.c	ggml-alloc.c.1216	ggml-alloc.c.1216mod
# n:-1 llama.cpp/ggml-alloc.c.1216
# n:1 llama.cpp/llama.h
do_cp llama.h	llama.h.1216	llama.h.1216mod
# n:-1 llama.cpp/llama.h.1216
# n:1 llama.cpp/llama.cpp
do_cp llama.cpp	llama.cpp.1216	llama.cpp.1216mod
# n:-1 llama.cpp/llama.cpp.1216
# n:1 llama.cpp/common/CMakeLists.txt
do_cp common/CMakeLists.txt	common/CMakeLists.txt.1216	common/CMakeLists.txt.1216mod
# n:-1 llama.cpp/common/CMakeLists.txt.1216
# n:1 llama.cpp/common/common.h
do_cp common/common.h	common/common.h.1216	common/common.h.1216mod
# n:-1 llama.cpp/common/common.h.1216
# n:1 llama.cpp/common/common.cpp
do_cp common/common.cpp	common/common.cpp.1216	common/common.cpp.1216mod
# n:-1 llama.cpp/common/common.cpp.1216
# n:1 llama.cpp/common/console.h
do_cp common/console.h	common/console.h.0903	common/console.h.1216mod
# n:1 llama.cpp/common/console.h.0903
# llama.cpp/common/console.h.0903 skip cp
# n:1 llama.cpp/common/console.cpp
do_cp common/console.cpp	common/console.cpp.0930	common/console.cpp.1216mod
# n:1 llama.cpp/common/console.cpp.0930
# llama.cpp/common/console.cpp.0930 skip cp
# n:1 llama.cpp/common/grammar-parser.h
do_cp common/grammar-parser.h	common/grammar-parser.h.0903	common/grammar-parser.h.1216mod
# n:1 llama.cpp/common/grammar-parser.h.0903
# llama.cpp/common/grammar-parser.h.0903 skip cp
# n:1 llama.cpp/common/grammar-parser.cpp
do_cp common/grammar-parser.cpp	common/grammar-parser.cpp.1216	common/grammar-parser.cpp.1216mod
# n:-1 llama.cpp/common/grammar-parser.cpp.1216
# n:1 llama.cpp/common/log.h
do_cp common/log.h	common/log.h.1216	common/log.h.1216mod
# n:-1 llama.cpp/common/log.h.1216
# n:1 llama.cpp/examples/CMakeLists.txt
do_cp examples/CMakeLists.txt	examples/CMakeLists.txt.1216	examples/CMakeLists.txt.1216mod
# n:-1 llama.cpp/examples/CMakeLists.txt.1216
# n:1 llama.cpp/examples/main/main.cpp
do_cp examples/main/main.cpp	examples/main/main.cpp.1216	examples/main/main.cpp.1216mod
# n:-1 llama.cpp/examples/main/main.cpp.1216
# n:1 llama.cpp/examples/benchmark/benchmark-matmult.cpp
do_cp examples/benchmark/benchmark-matmult.cpp	examples/benchmark/benchmark-matmult.cpp.1216	examples/benchmark/benchmark-matmult.cpp.1216mod
# n:-1 llama.cpp/examples/benchmark/benchmark-matmult.cpp.1216
# n:1 llama.cpp/tests/CMakeLists.txt
do_cp tests/CMakeLists.txt	tests/CMakeLists.txt.1216	tests/CMakeLists.txt.1216mod
# n:-1 llama.cpp/tests/CMakeLists.txt.1216
# n:1 llama.cpp/tests/test-quantize-fns.cpp
do_cp tests/test-quantize-fns.cpp	tests/test-quantize-fns.cpp.1216	tests/test-quantize-fns.cpp.1216mod
# n:-1 llama.cpp/tests/test-quantize-fns.cpp.1216
# n:1 llama.cpp/tests/test-quantize-perf.cpp
do_cp tests/test-quantize-perf.cpp	tests/test-quantize-perf.cpp.1216	tests/test-quantize-perf.cpp.1216mod
# n:-1 llama.cpp/tests/test-quantize-perf.cpp.1216
# n:1 llama.cpp/tests/test-grad0.cpp
do_cp tests/test-grad0.cpp	tests/test-grad0.cpp.1216	tests/test-grad0.cpp.1216mod
# n:-1 llama.cpp/tests/test-grad0.cpp.1216
# n:1 llama.cpp/tests/test-opt.cpp
do_cp tests/test-opt.cpp	tests/test-opt.cpp.1216	tests/test-opt.cpp.1216mod
# n:-1 llama.cpp/tests/test-opt.cpp.1216
# n:1 llama.cpp/tests/test-sampling.cpp
do_cp tests/test-sampling.cpp	tests/test-sampling.cpp.1216	tests/test-sampling.cpp.1216mod
# n:-1 llama.cpp/tests/test-sampling.cpp.1216
# n:1 llama.cpp/tests/test-tokenizer-0-llama.cpp
do_cp tests/test-tokenizer-0-llama.cpp	tests/test-tokenizer-0-llama.cpp.1014	tests/test-tokenizer-0-llama.cpp.1216mod
# n:1 llama.cpp/tests/test-tokenizer-0-llama.cpp.1014
# llama.cpp/tests/test-tokenizer-0-llama.cpp.1014 skip cp
# n:1 llama.cpp/tests/test-tokenizer-0-falcon.cpp
do_cp tests/test-tokenizer-0-falcon.cpp	tests/test-tokenizer-0-falcon.cpp.1014	tests/test-tokenizer-0-falcon.cpp.1216mod
# n:1 llama.cpp/tests/test-tokenizer-0-falcon.cpp.1014
# llama.cpp/tests/test-tokenizer-0-falcon.cpp.1014 skip cp
# n:1 llama.cpp/tests/test-llama-grammar.cpp
do_cp tests/test-llama-grammar.cpp	tests/test-llama-grammar.cpp.0903	tests/test-llama-grammar.cpp.1216mod
# n:1 llama.cpp/tests/test-llama-grammar.cpp.0903
# llama.cpp/tests/test-llama-grammar.cpp.0903 skip cp
# n:1 llama.cpp/tests/test-grammar-parser.cpp
do_cp tests/test-grammar-parser.cpp	tests/test-grammar-parser.cpp.0903	tests/test-grammar-parser.cpp.1216mod
# n:1 llama.cpp/tests/test-grammar-parser.cpp.0903
# llama.cpp/tests/test-grammar-parser.cpp.0903 skip cp
# n:1 llama.cpp/tests/test-c.c
do_cp tests/test-c.c	tests/test-c.c.0903	tests/test-c.c.1216mod
# n:1 llama.cpp/tests/test-c.c.0903
# llama.cpp/tests/test-c.c.0903 skip cp
msg "RESULT: $RESULT"

if [ $CMD = "chk" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for zipping, syncing"
	else
		msg "${ESCRED}do $MYNAME chkmod and $MYNAME master before zipping, syncing${ESCBACK}"
	fi
fi
if [ $CMD = "chkmod" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		msg "${ESCRED}save files and update $MYNAME${ESCBACK}"
	fi
fi
if [ $CMD = "chkmod2" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		msg "${ESCRED}save files and update $MYNAME${ESCBACK}"
	fi
fi

# cmake .. -DLLAMA_AVX=ON -DLLAMA_AVX=OFF -DLLAMA_AVX512=OFF -DLLAMA_FMA=OFF -DLLAMA_OPENBLAS=ON -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_EXAMPLES=ON
# make test-quantize test-tokenizer-0
# GGML_NLOOP=1 GGML_NTHREADS=4 make test
msg "end"


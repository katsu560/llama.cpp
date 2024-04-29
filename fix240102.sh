#!/bin/sh

MYNAME=fix240102.sh

# common code, functions
### return code/error code
RET_TRUE=1		# TRUE
RET_FALSE=0		# FALSE
RET_OK=0		# OK
RET_NG=1		# NG
RET_YES=1		# YES
RET_NO=0		# NO
RET_CANCEL=2		# CANCEL

ERR_USAGE=1		# usage
ERR_UNKNOWN=2		# unknown error
ERR_NOARG=3		# no argument
ERR_BADARG=4		# bad argument
ERR_NOTEXISTED=10	# not existed
ERR_EXISTED=11		# already existed
ERR_NOTFILE=12		# not file
ERR_NOTDIR=13		# not dir
ERR_CANTCREATE=14	# can't create
ERR_CANTOPEN=15		# can't open
ERR_CANTCOPY=16		# can't copy
ERR_CANTDEL=17		# can't delete
ERR_BADSETTINGS=18	# bad settings
ERR_BADENVIRONMENT=19	# bad environment
ERR_BADENV=19		# bad environment, short name

### flags
VERBOSE=0		# -v --verbose flag, -v -v means more verbose
NOEXEC=$RET_FALSE	# -n --noexec flag
FORCE=$RET_FALSE	# -f --force flag
NODIE=$RET_FALSE	# -nd --nodie
NOCOPY=$RET_FALSE	# -ncp --nocopy
NOTHING=

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

ESCOK="$ESCGREEN"
ESCERR="$ESCRED"
ESCWARN="$ESCMAGENTA"
ESCINFO="$ESCWHITE"


# func:xxmsg ver:2023.12.23
# more verbose message to stderr
# xxmsg "messages"
xxmsg()
{
	if [ $VERBOSE -ge 2 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

# func:xmsg ver:2023.12.23
# verbose message to stderr
# xmsg "messages"
xmsg()
{
	if [ $VERBOSE -ge 1 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

# func:emsg ver:2023.12.31
# error message to stderr
# emsg "messages"
emsg()
{
        echo "$MYNAME: ${ESCERR}$*${ESCBACK}" 1>&2
}

# func:okmsg ver:2024.01.01
# ok message to stdout
# okmsg "messages"
okmsg()
{
        echo "$MYNAME: ${ESCOK}$*${ESCBACK}"
}

# func:msg ver:2023.12.23
# message to stdout
# msg "messages"
msg()
{
	echo "$MYNAME: $*"
}

###
TOPDIR=llama.cpp
NAMEBASE=fix

CMD=chk


###
#do_cp ggml.c	ggml.c.0625	ggml.c.0625mod

# diff old $1 $2 $OPT
diff_old()
{
	#msg "do_diff_old CMD:$CMD $1 $2 $3 $4  OPT:$OPT"
	# in $TOPDIR

	if [ ! x"$OPT" = x ]; then
		NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][01][0-9][0-3][0-9]\)/\2/'`
		#msg "diff: NEW:$NEWDATE"
		if [ ! x"$NEWDATE" = x"$OPT" ]; then
			msg "diff: skip $2 by $NEWDATE"
			return
		fi
	fi

	#msg "diff_old $1 $2"
	NEW="./$2"
	OLD=`find . -path './'$1'.[0-9][0-9][01][0-9][0-3][0-9]' | awk -v NEW="$NEW" '
	$0 != NEW { OLD=$0 }
	END   { print OLD }'`
	okmsg "diff -c $OLD $NEW"
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
			okmsg "diff -c $2 $1"
			diff -c $2 $1
			#msg "RESULT: $RESULT $?"
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod|checkmod)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $3 ]; then
			okmsg "diff -c $1 $3"
			diff -c $1 $3
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod2|checkmod2)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				okmsg "diff -c $1 $4"
				diff -c $1 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				okmsg "diff -c $1 $3"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				okmsg "diff -c $1 $3"
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
				okmsg "diff -c $3 $4"
				diff -c $3 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				okmsg "diff -c $2 $3"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				okmsg "diff -c $2 $3"
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
	*)	emsg "unknown command: $CMD"
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
		#printf "# n:%d %s\n",n,file;
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
		CMD="date '+%y%m%d' -r " TOPFILE;
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
	echo "usage: $MYNAME [-h][-v][-n][-nd][-ncp] chk|chkmod|chkmod2|chkmod12|master|mod|mod2|diff [DT]|mk [DT]|new [DT]"
	echo "options: (default)"
	echo "  -h|--help ... this message"
	echo "  -v|--verbose ... increase verbose message level"
	echo "  -n|--noexec ... no execution, test mode (FALSE)"
	echo "  -nd|--nodie ... no die (FALSE)"
	echo "  -ncp|--nocopy ... no copy (FALSE)"
	echo "  chk ... diff master"
	echo "  chkmod ... diff mod"
	echo "  chkmod2 ... diff mod2"
	echo "  chkmod12 ... diff mod mod2"
	echo "  master ... cp master files on 240102"
	echo "  mod ... cp mod files on 240102"
	echo "  mod2 ... cp mod2 files on 240102"
	echo "  diff [DT] ... diff old and new, new on DT only if set DT"
	echo "  mk [DT] ... create new shell script"
	echo "  new [DT] ... show new files since DT"
}

###
if [ x"$1" = x -o x"$1" = "x-h" ]; then
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
	*)		OPTLOOP=$RET_FALSE; break;;
	esac
	shift
done

ORGCMD="$1"
CMD="$1"
OPT="$2"
msg "CMD: $CMD"
msg "OPT: $OPT"

if [ $CMD = "mk" ]; then
	DT0=`echo $MYNAME | sed -e 's/'$NAMEBASE'//' -e 's/.sh//'`
	DT1=`date '+%y%m%d'`
	# overwrite
	if [ ! x"$OPT" = x ]; then
		DT1="$OPT"
	fi
	msg "DT0: $DT0  DT1: $DT1"
	do_mk $DT0 $DT1
	exit $RET_OK
fi
if [ $CMD = "new" ]; then
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt.1001
	#-rw-r--r-- 1 user user 5898 Oct  1 04:40 ggml/README.md
	DT1=`date '+%y%m%d'`
	#NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][01][0-9][0-3][0-9]\)/\2/'`
	#find $TOPDIR -type f -mtime 0 -exec ls -l '{}' \; | awk -v DT1=$DT1 '
	find $TOPDIR -type f -mtime 0 | awk -v DT1=$DT1 '
	BEGIN { PREV="" }
	#{ print "line: ",$0; }
	#{ ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	#END { ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	{ ADDDT=PREV "." DT1; if (ADDDT==$0) { PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	END { ADDDT=PREV "." DT1; if (ADDDT==$0) { ; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	' -
	exit $RET_OK
fi


###
if [ ! -d $TOPDIR ]; then
	die $ERR_NOTEXISTED "no $TOPDIR, exit"
fi
cd $TOPDIR

msg "git branch"
if [ $NOEXEC -eq $RET_FALSE ]; then
	git branch
fi

# check:  ls -l target origin modified
# revert: cp -p origin target
# revise: cp -p modifid target
#
# do_cp target origin(master) modified(gq)
RESULT=0
do_cp CMakeLists.txt	CMakeLists.txt.240102	CMakeLists.txt.240102mod
do_cp Makefile	Makefile.240102	Makefile.240102mod
do_cp ggml.h	ggml.h.240102	ggml.h.240102mod
do_cp ggml.c	ggml.c.240102	ggml.c.240102mod
do_cp ggml-opencl.h	ggml-opencl.h.240102	ggml-opencl.h.240102mod
do_cp ggml-opencl.cpp	ggml-opencl.cpp.231224	ggml-opencl.cpp.240102mod
do_cp ggml-alloc.h	ggml-alloc.h.231224	ggml-alloc.h.240102mod
do_cp ggml-alloc.c	ggml-alloc.c.231224	ggml-alloc.c.240102mod
do_cp llama.h	llama.h.231224	llama.h.240102mod
# llama.cpp/llama.h.231224 skip cp
do_cp llama.cpp	llama.cpp.240102	llama.cpp.240102mod
do_cp common/CMakeLists.txt	common/CMakeLists.txt.240102	common/CMakeLists.txt.240102mod
do_cp common/common.h	common/common.h.231224	common/common.h.240102mod
# llama.cpp/common/common.h.231224 skip cp
do_cp common/common.cpp	common/common.cpp.240102	common/common.cpp.240102mod
do_cp common/console.h	common/console.h.230903	common/console.h.240102mod
# llama.cpp/common/console.h.230903 skip cp
do_cp common/console.cpp	common/console.cpp.230930	common/console.cpp.240102mod
# llama.cpp/common/console.cpp.230930 skip cp
do_cp common/grammar-parser.h	common/grammar-parser.h.230903	common/grammar-parser.h.240102mod
# llama.cpp/common/grammar-parser.h.230903 skip cp
do_cp common/grammar-parser.cpp	common/grammar-parser.cpp.231224	common/grammar-parser.cpp.240102mod
do_cp common/log.h	common/log.h.231224	common/log.h.240102mod
do_cp examples/CMakeLists.txt	examples/CMakeLists.txt.231224	examples/CMakeLists.txt.240102mod
# llama.cpp/examples/CMakeLists.txt.231224 skip cp
do_cp examples/main/main.cpp	examples/main/main.cpp.231224	examples/main/main.cpp.240102mod
do_cp examples/benchmark/benchmark-matmult.cpp	examples/benchmark/benchmark-matmult.cpp.231224	examples/benchmark/benchmark-matmult.cpp.240102mod
do_cp tests/CMakeLists.txt	tests/CMakeLists.txt.240102	tests/CMakeLists.txt.240102mod
do_cp tests/test-quantize-fns.cpp	tests/test-quantize-fns.cpp.231224	tests/test-quantize-fns.cpp.240102mod
do_cp tests/test-quantize-perf.cpp	tests/test-quantize-perf.cpp.231224	tests/test-quantize-perf.cpp.240102mod
do_cp tests/test-grad0.cpp	tests/test-grad0.cpp.240102	tests/test-grad0.cpp.240102mod
do_cp tests/test-opt.cpp	tests/test-opt.cpp.231224	tests/test-opt.cpp.240102mod
do_cp tests/test-sampling.cpp	tests/test-sampling.cpp.231224	tests/test-sampling.cpp.240102mod
do_cp tests/test-tokenizer-0-llama.cpp	tests/test-tokenizer-0-llama.cpp.231014	tests/test-tokenizer-0-llama.cpp.240102mod
# llama.cpp/tests/test-tokenizer-0-llama.cpp.231014 skip cp
do_cp tests/test-tokenizer-0-falcon.cpp	tests/test-tokenizer-0-falcon.cpp.231014	tests/test-tokenizer-0-falcon.cpp.240102mod
# llama.cpp/tests/test-tokenizer-0-falcon.cpp.231014 skip cp
do_cp tests/test-llama-grammar.cpp	tests/test-llama-grammar.cpp.230903	tests/test-llama-grammar.cpp.240102mod
# llama.cpp/tests/test-llama-grammar.cpp.230903 skip cp
do_cp tests/test-grammar-parser.cpp	tests/test-grammar-parser.cpp.230903	tests/test-grammar-parser.cpp.240102mod
# llama.cpp/tests/test-grammar-parser.cpp.230903 skip cp
do_cp tests/test-c.c	tests/test-c.c.230903	tests/test-c.c.240102mod
# llama.cpp/tests/test-c.c.230903 skip cp
msg "RESULT: $RESULT"

if [ $CMD = "chk" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for zipping, syncing"
	else
		emsg "do $MYNAME chkmod and $MYNAME master before zipping, syncing"
	fi
fi
if [ $CMD = "chkmod" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		emsg "save files and update $MYNAME"
	fi
fi
if [ $CMD = "chkmod2" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		emsg "save files and update $MYNAME"
	fi
fi

# cmake .. -DLLAMA_AVX=ON -DLLAMA_AVX=OFF -DLLAMA_AVX512=OFF -DLLAMA_FMA=OFF -DLLAMA_OPENBLAS=ON -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_EXAMPLES=ON
# make test-quantize test-tokenizer-0
# GGML_NLOOP=1 GGML_NTHREADS=4 make test
msg "end"

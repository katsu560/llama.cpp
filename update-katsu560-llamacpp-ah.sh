#!/bin/bash

# update katsu560/llama.cpp
# T902 Intel(R) Core(TM) i5-3320M CPU @ 2.60GHz  2C/4T F16C,AVX IvyBridge/3rd Gen.
# AH   Intel(R) Core(TM) i3-10110U CPU @ 2.10GHz  2C/4T F16C,AVX,AVX2,FMA CometLake/10th Gen.

MYEXT="-ah"
MYNAME=update-katsu560-llamacpp${MYEXT}.sh

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
ERR_CANTMOVE=20		# can't move

# set unique return code from 100
ERR_NOTOPDIR=100	# no topdir
ERR_NOBUILDDIR=101	# no build dir
ERR_NOUSB=102		# no USB found
ERR_CANTGIT=103		# can't git, git failed
ERR_CANTCMAKE=104	# can't cmake, cmake failed
ERR_CANTBUILD=105	# can't cmake --build or make, cmake --build failed
ERR_CANTMAKE=106	# can't make, make failed
ERR_CANTCLEAN=107	# can't make clean
ERR_CANTTEST=108	# can't make test


### flags
VERBOSE=0		# -v --verbose flag, -v -v means more verbose
NOEXEC=$RET_FALSE	# -n --noexec flag
FORCE=$RET_FALSE	# -f --force flag
NODIE=$RET_FALSE	# -nd --nodie
NOCOPY=$RET_FALSE	# -ncp --nocopy
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
ESCUL="${ESC}[4m"		# underline
ESCBLINK="${ESC}[5m"		# slow blink
ESCRBLINK="${ESC}[6m"		# rapid blink
ESCREVERSE="${ESC}[7m"
ESCCONCEAL="${ESC}[8m"
ESCDELETED="${ESC}[9m"		# crossed-out
ESCBOLDOFF="${ESC}[22m"		# bold off, faint off
ESCITALICOFF="${ESC}[23m"	# italic off
ESCULOFF="${ESC}[24m"		# underline off
ESCBLINKOFF="${ESC}[25m"	# blink off
ESCREVERSEOFF="${ESC}[27m"	# reverse off
ESCCONCEALOFF="${ESC}[28m"	# conceal off
ESCDELETEDOFF="${ESC}[29m"	# deleted off
ESCBLACK="${ESC}[30m"
ESCRED="${ESC}[31m"
ESCGREEN="${ESC}[32m"
ESCYELLOW="${ESC}[33m"
ESCBLUE="${ESC}[34m"
ESCMAGENTA="${ESC}[35m"
ESCCYAN="${ESC}[36m"
ESCWHITE="${ESC}[37m"
ESCDEFAULT="${ESC}[39m"
ESCBGBLACK="${ESC}[40m"
ESCBGRED="${ESC}[41m"
ESCBGGREEN="${ESC}[42m"
ESCBGYELLOW="${ESC}[43m"
ESCBGBLUE="${ESC}[44m"
ESCBGMAGENTA="${ESC}[45m"
ESCBGCYAN="${ESC}[46m"
ESCBGWHITE="${ESC}[47m"
ESCBGDEFAULT="${ESC}[49m"
ESCBACK="${ESC}[m"

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

# func:emsg ver:2024.04.06
# warning message to stderr
# wmsg "messages"
wmsg()
{
	echo "$MYNAME: ${ESCWARN}$*${ESCBACK}" 1>&2
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

# func:die ver:2023.12.31
# die with RETCODE and error message
# die RETCODE "messages"
die()
{
	local RETCODE

	RETCODE=$1
	shift
	xxmsg "die: RETCODE:$RETCODE msg:$*"

	emsg "$*"
	if [ $NODIE -eq $RET_TRUE ]; then
		xmsg "die: nodie"
		return
	fi
	exit $RETCODE
}

# func:mcmd ver:2024.04.21
# show given command CMD message and always do(eval) it
# mcmd "CMD"
mcmd()
{
	msg $*
	eval $*
}

# func:xxcmd ver:2024.04.29
# show more verbose given command CMD and do(eval) it
# xxcmd "CMD"
xxcmd()
{
	xxmsg $*
	if [ $NOEXEC -eq $RET_FALSE ]; then
		eval $*
	fi
}

# func:xcmd ver:2024.04.21
# show verbose given command CMD and do(eval) it
# xcmd "CMD"
xcmd()
{
	xmsg $*
	if [ $NOEXEC -eq $RET_FALSE ]; then
		eval $*
	fi
}

# func:cmd ver:2024.02.17
# show given command CMD and do(eval) it
# cmd "CMD"
cmd()
{
	msg $*
	if [ $NOEXEC -eq $RET_FALSE ]; then
		eval $*
	fi
}

# func:nothing ver:2023.12.23
# do nothing function
# nothing
nothing()
{
	NOTHING=
}

FUNCTEST_OK=0
FUNCTEST_NG=0
# func:func_test_reset ver:2023.12.30
# reset FUNCTEST_OK, FUNCTEST_NG
# func_test_reset
func_test_reset()
{
	FUNCTEST_OK=0
	FUNCTEST_NG=0
	xmsg "func_test_reset: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG"
}

# func:func_test_show ver:2024.01.08
# show FUNCTEST_OK, FUNCTEST_NG
# func_test_reset
func_test_show()
{
	if [ $FUNCTEST_NG -eq 0 ]; then
		okmsg "func_test_show: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG"
	else
		emsg "func_test_show: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG"
	fi
}

# func:func_test_trail ver:2024.04.07
# output trail. for func test
# func_test_trail
func_test_trail()
{
	msg "----"
}

# func:func_test ver:2024.04.07
# check return code of func test with OKCODE and output message for test code
# func_test [NOTRAIL] OKCODE "messages"
func_test()
{
	RETCODE=$?
	NOTRAIL=$RET_FALSE

	if [ x"$1" = x"NOTRAIL" ]; then
		NOTRAIL=$RET_TRUE
		shift
	fi

	OKCODE=$1
	shift
	TESTMSG="$*"

	if [ $RETCODE -eq $OKCODE ]; then
		FUNCTEST_OK=`expr $FUNCTEST_OK + 1`
		msg "${ESCOK}test:OK${ESCBACK}: ret:$RETCODE expected:$OKCODE $TESTMSG"
	else
		FUNCTEST_NG=`expr $FUNCTEST_NG + 1`
		msg "${ESCERR}${ESCBOLD}test:NG${ESCBOLDOFF}${ESCBACK}: ret:$RETCODE expected:$OKCODE ${ESCRED}$TESTMSG${ESCBACK}"
	fi

	# output trail
	if [ $NOTRAIL -eq $RET_FALSE ]; then
		#msg "----"
		func_test_trail
	fi
}

# func:set_ret ver:2023.12.23
# set $? as return code for test code
# set_ret RETCODE
set_ret()
{
	return $1
}

# dolevel
LEVELMIN=1
LEVELSTD=3
LEVELMAX=5
DOLEVEL=$LEVELSTD
# func:chk_level ver: 2024.04.06
# check given LEVEL less or equal than DOLEVEL, then do ARGS
# chk_level LEVEL ARGS ...
chk_level()
{
	xxmsg "chk_level: DOLEVEL:$DOLEVEL LEVEL:$1 ARGS:$*"

	local LEVEL RETCODE CHK

	RETCODE=$RET_OK

	# check DOLEVEL
	if [ x"$DOLEVEL" = x ]; then
		emsg "chk_level: need set DOLEVEL, skip"
		return $ERR_BADSETTINGS
	fi
	# check args
	if [ x"$1" = x ]; then
		emsg "chk_level: need LEVEL, skip"
		return $ERR_NOARG
	fi
	LEVEL="$1"
	CHK=`echo $LEVEL | awk '!/['$LEVELMIN'-'$LEVELMAX']/ { print "BADVALUE"; exit } { print $0 }'`
	if [ $CHK = "BADVALUE" ]; then
		emsg "chk_level: LEVEL:$LEVEL bad value, skip"
		return $ERR_BADARG
	fi
	if [ $LEVEL -lt $LEVELMIN -o $LEVELMAX -lt $LEVEL ]; then
		emsg "chk_level: LEVEL:$LEVEL bad value, skip"
		return $ERR_BADARG
	fi
	shift
	if [ ! $# -gt 0 ]; then
		emsg "chk_level: need ARGS, skip"
		return $ERR_NOARG
	fi

	xmsg "chk_level: LEVEL:$DOLEVEL >= $LEVEL do $*"
	if [ $DOLEVEL -ge $LEVEL ]; then
		xmsg "chk_level: do $*"
		eval $*
		RETCODE=$?
	else
		wmsg "chk_level: skip $*"
		RETCODE=$RET_OK
	fi

	xxmsg "chk_level: RETCODE:$RETCODE"
	return $RETCODE
}
test_chk_level_func()
{
	okmsg "test_chk_level_func: $*"
	return $RET_OK
}
test_chk_level()
{
	local DOLEVELBK LEVELNONUM LEVELZERO LEVELBAD

	# set test env
	DOLEVELBK=$DOLEVEL
	LEVELNONUM="NONUM"
	LEVELZERO=`expr $LEVELMIN - 1`
	LEVELBAD=`expr $LEVELMAX + 1`
	func_test_reset

	# test code
	DOLEVEL=
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_BADSETTINGS "bad settings: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	DOLEVEL=$LEVELMIN
	msg "----"
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_NOARG "no arg: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_NOARG "no arg: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_NOARG "no arg: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_NOARG "no arg: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	DOLEVEL=$LEVELSTD
	msg "----"
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_NOARG "no arg: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_NOARG "no arg: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_NOARG "no arg: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_NOARG "no arg: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	DOLEVEL=$LEVELMAX
	msg "----"
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_NOARG "no arg: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_NOARG "no arg: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_NOARG "no arg: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_NOARG "no arg: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	# reset test env
	func_test_show
	DOLEVEL=$DOLEVELBK
}
#msg "test_chk_level"; VERBOSE=2; test_chk_level; exit 0

### date time
DTTMSHSTART=
# func:get_datetime ver:2023.12.31
# get date time and store to VARDTTM
# get_date VARDTTM
get_datetime()
{
	xxmsg "get_datetime: ARGS:$*"

	local RETCODE VARDTTM DTTM VALDTTM

	RETCODE=$RET_OK

	# check VARDTTM
	if [ x"$1" = x ]; then
		emsg "get_datetime: need VARDTTM, skip"
		return $ERR_NOARG
	fi
	VARDTTM="$1"
	xxmsg "get_datetime: VARDTTM:$VARDTTM"

	DTTM=`date '+%Y%m%d-%H%M%S'`
	eval $VARDTTM="$DTTM"
	VALDTTM=`eval echo '$'${VARDTTM}`
	xxmsg "get_datetime: DTTM:$DTTM $VARDTTM:$VALDTTM"

	return $RETCODE
}
test_get_datetime()
{
	local DTTMTEST

	# set test env
	DTTMTEST=
	msg "DTTMTEST:$DTTMTEST"
	date '+%Y%m%d-%H%M%S'
	func_test_reset

	# test code
	get_datetime
	func_test $ERR_NOARG "no arg: get_datetime"
	msg "DTTMTEST:$DTTMTEST"
	get_datetime DTTMTEST
	func_test $RET_OK "ok: get_datetime DTTMTEST"
	msg "DTTMTEST:$DTTMTEST"

	# reset test env
	func_test_show
	DTTMTEST=
}
#msg "test get_datetime"; VERBOSE=2; test_get_datetime; exit 0
get_datetime DTTMSHSTART

# func:diff_datetime ver:2023.12.31
# get date time difference in second
# get_date DTTMSTART DTTMEND
diff_datetime()
{
	xxmsg "diff_datetime: ARGS:$*"

	local RETCODE DTTMS DTTME DIFF

	RETCODE=$RET_OK

	# check
	if [ $# -lt 2 ]; then
		emsg "diff_datetime: need DTTMSTART DTTMEND, skip"
		return $ERR_NOARG
	fi
	DTTMS="$1"
	DTTME="$2"

	DIFF=`echo -e "$DTTMS\n$DTTME" | awk '
	{ T=$0; NDT=patsplit(T, DT, /([0-9][0-9])/); 
	  I=I+1; SDT[I]=sprintf("%02d%02d %2d %2d %2d %2d %2d\n",DT[1],DT[2],DT[3],DT[4],DT[5],DT[6],DT[7]); S[I]=mktime(SDT[I]) }
	END { DIFF=S[2]-S[1]; printf("%d",DIFF)}'`
	echo $DIFF

	return $RETCODE
}
test_diff_datetime()
{
	local DTTMS DTTME DTTME2 DTTMU DIFF DIFFOK

	# set test env
	DTTMS=20231229-064933
	DTTME=20231229-085939
	DTTME2=20231230-085939
	DTTMU=
	DIFF=
	DIFFOK=7806
	msg "DTTMS:$DTTMS DTTME:$DTTME DIFF:$DIFF"
	func_test_reset

	# test code
	DIFF=`diff_datetime`
	func_test $ERR_NOARG "no arg: diff_datetime"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS`
	func_test $ERR_NOARG "no arg: diff_datetime $DTTMS"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS $DTTME`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMS $DTTME2`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME2"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMS $DTTMS`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTMS"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTME $DTTMS`
	func_test $RET_OK "ok: diff_datetime $DTTME $DTTMS"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS $DTTMU`
	func_test $ERR_NOARG "no arg: diff_datetime $DTTMS $DTTMU"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMU $DTTME`
	func_test $ERR_NOARG "no arg: diff_datetime $DTTMU $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMS $DTTME`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS $DTTME ABC`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DIFF:$DIFF"

	# reset test env
	func_test_show
	DTTMS=
	DTTME=
	DTTMU=
	DIFF=
}
#msg "test diff_datetime"; VERBOSE=2; test_diff_datetime; exit 0

# func:get_physpath ver:2024.04.29
# get physical file path if it is symlink
# get_physpath VARPHYSPATH FILE
get_physpath()
{
	local XVARPHYSPATH XFILE RETCODE XPHYSPATH XVALPHYSPATH

	xmsg "get_physpath: ARGS:$*"
	if [ $# -lt 2 ]; then
		emsg "get_physpath: need VARPHYSPATH, FILE, skip"
		return $ERR_NOARG
	fi

	XVARPHYSPATH="$1"
	shift
	XFILE="$*"

	RETCODE=$RET_OK

	xxmsg "get_physpath: test XFILE:$XFILE"
	if [ ! -e "$XFILE" ]; then
		emsg "get_physpath: not existed: $XFILE"
		return $ERR_NOTEXISTED
	fi

	# $ ls -l llama.cpp/models/llama-2-7b.Q8_0*
	#-rwxrwxrwx 1 user user 7161089728 Sep  5 00:54 llama.cpp/models/llama-2-7b.Q8_0-local.gguf
	#lrwxrwxrwx 1 user user         60 Feb 12 06:13 llama.cpp/models/llama-2-7b.Q8_0.gguf -> /mnt/hd-le-b/gpt/llama2/gguf/llama-2-7b/llama-2-7b.Q8_0.gguf
	# ls -alng fix240218-ah.sh
	#-rw-r--r-- 1 109 12303 Feb 18 02:44 fix240218-ah.sh
	# ls -alng llama.cpp/models/llama-2-7b.Q8_0.gguf
	#lrwxrwxrwx 1 1000 60 Feb 12 06:13 llama.cpp/models/llama-2-7b.Q8_0.gguf -> /mnt/hd-le-b/gpt/llama2/gguf/llama-2-7b/llama-2-7b.Q8_0.gguf
	# ls -alng llama.cpp/models/llama-2-7b.Q8_0-local.gguf
	#-rwxrwxrwx 1 1000 7161089728 Sep  5 00:54 llama.cpp/models/llama-2-7b.Q8_0-local.gguf

	if [ $VERBOSE -ge 2 ]; then
		xxcmd ls -alngd "$XFILE"
	fi
	XPHYSPATH=`ls -alngd "$XFILE" | awk '/^l/ { T=$0; sub(/^.* -> /,"",T); printf "%s",T; exit } { T=$0; NDEL=10+length($2)+length($3)+length($4)+12+6; FP=substr(T,NDEL); printf "%s",FP; exit }'`
	xmsg "get_physpath: PHYSPATH:$XPHYSPATH"
	eval $XVARPHYSPATH=\""$XPHYSPATH"\"
	XVALPHYSPATH=`eval echo '$'${XVARPHYSPATH}`
	xmsg "get_physpath: PHYSPATH:$XPHYSPATH $XVARPHYSPATH:$XVALPHYSPATH"

	return $RETCODE
}
test_get_physpath()
{
	local FILE0 FILE1 FILE2 FILE3 FILE4 FILE5 FILE10 FILE11 FILE12 FILE13 FILE14 FILE15 PHYSPATH

	# set test env
	# FILE0, FILE10 do not existed, FILE5, FILE15 are dir
	FILE0=tmp-physpath0.$$
	FILE1=tmp-physpath1.$$
	FILE2=tmp-physpath2.$$
	FILE3="tmp-physpath3 with space.$$"
	FILE4=tmp-physpath4.$$
	FILE5=tmp-physpath5.$$
	FILE10=tmp-physpath10.$$
	FILE11=tmp-physpath11.$$
	FILE12=tmp-physpath12.$$
	FILE13=tmp-physpath13.$$
	FILE14="tmp-physpath14 with space.$$"
	FILE15=tmp-physpath15.$$
	mcmd rm -rf $FILE0 $FILE1 $FILE2 "$FILE3" $FILE4 $FILE5 $FILE10 $FILE11 $FILE12 $FILE13 "$FILE14" $FILE15
	touch $FILE1
	echo "1234567890" >> $FILE2
	echo "12345678901234567890" >> "$FILE3"
	echo "123456789012345678901234567890" >> $FILE4
	mkdir $FILE5
	ln -s $FILE1 $FILE11
	ln -s $FILE2 $FILE12
	ln -s "$FILE3" $FILE13
	ln -s $FILE4 "$FILE14"
	ln -s $FILE0 "$FILE10"
	ln -s $FILE5 $FILE15
	mcmd ls -ld $FILE0 $FILE1 $FILE2 "$FILE3" $FILE4 $FILE5 $FILE10 $FILE11 $FILE12 $FILE13 "$FILE14" $FILE15
	msg "PHYSPATH:$PHYSPATH"
	func_test_reset

	# test code
	PHYSPATH=
	get_physpath
	func_test $ERR_NOARG "no arg: PHYSPATH:$PHYSPATH get_physpath"
	get_physpath PHYSPATH
	func_test $ERR_NOARG "no arg: PHYSPATH:$PHYSPATH get_physpath PHYSPATH"

	PHYSPATH=
	get_physpath PHYSPATH $FILE0
	func_test $ERR_NOTEXISTED "not existed: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE0"
	PHYSPATH=
	get_physpath PHYSPATH $FILE1
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE1"
	PHYSPATH=
	get_physpath PHYSPATH $FILE2
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE2"
	PHYSPATH=
	get_physpath PHYSPATH $FILE3
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE3"
	PHYSPATH=
	get_physpath PHYSPATH "$FILE3"
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH \"$FILE3\""
	PHYSPATH=
	get_physpath PHYSPATH $FILE4
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE4"
	PHYSPATH=
	get_physpath PHYSPATH $FILE5
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE5"

	PHYSPATH=
	get_physpath PHYSPATH $FILE10
	func_test $ERR_NOTEXISTED "not existed: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE10"
	PHYSPATH=
	get_physpath PHYSPATH $FILE11
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE11"
	PHYSPATH=
	get_physpath PHYSPATH $FILE12
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE12"
	PHYSPATH=
	get_physpath PHYSPATH $FILE13
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE13"
	PHYSPATH=
	get_physpath PHYSPATH "$FILE13"
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH \"$FILE13\""
	PHYSPATH=
	get_physpath PHYSPATH $FILE14
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH $FILE14"
	PHYSPATH=
	get_physpath PHYSPATH "$FILE14"
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH \"$FILE14\""
	PHYSPATH=
	get_physpath PHYSPATH "$FILE15"
	func_test $RET_OK "ok: PHYSPATH:$PHYSPATH get_physpath PHYSPATH \"$FILE15\""

	# reset test env
	func_test_show
	mcmd rm -rf $FILE0 $FILE1 $FILE2 "$FILE3" $FILE4 $FILE5 $FILE10 $FILE11 $FILE12 $FILE13 "$FILE14" $FILE15
	mcmd ls -ld $FILE0 $FILE1 $FILE2 "$FILE3" $FILE4 $FILE5 $FILE10 $FILE11 $FILE12 $FILE13 "$FILE14" $FILE15
	msg "PHYSPATH:$PHYSPATH"
}
#msg "test get_physpath"; VERBOSE=2; test_get_physpath; exit 0
#msg "test get_physpath"; VERBOSE=0; test_get_physpath; exit 0

# func:chk_and_cp ver:2024.04.29
# do cp with cp option and check source file(s) and dir(s) to file or dir
# chk_and_cp CPOPT SRCFILE SRCDIR ... DSTPATH
chk_and_cp()
{
	local CHKFILES CPOPT NARG ARGFILES DSTPATH NCP CPFILES i ISSPC XARG

	#xmsg "----"
	#xmsg "chk_and_cp: VERBOSE:$VERBOSE NOEXEC:$NOEXEC NOCOPY:$NOCOPY"
	#xmsg "chk_and_cp: $*"
	xmsg "chk_and_cp: NARG:$# ARGS:$*"
	if [ $# -eq 0 ]; then
		emsg "chk_and_cp: ARGS:$*: no CPOPT, CHKFILES"
		return $ERR_NOARG
	fi

	# get cp opt
	CPOPT=$1
	shift
	xxmsg "chk_and_cp: NARG:$# ARGS:$*"

	if [ $# -le 1 ]; then
		emsg "chk_and_cp: CPOPT:$CPOPT ARGS:$*: bad arg, not enough"
		return $ERR_BADARG
	fi

	NARG=$#
	DSTPATH=`eval echo '${'$#'}'`
	xxmsg "chk_and_cp: NARG:$# DSTPATH:$DSTPATH"
	if [ ! -d "$DSTPATH" ]; then
		DSTPATH=
	fi
	ARGFILES="$*"
	xmsg "chk_and_cp: CPOPT:$CPOPT NARG:$NARG ARGFILES:$ARGFILES DSTPATH:$DSTPATH"

	NCP=1
	CPFILES=()
	while [ $NCP -le $NARG ];
	do
		ISSPC=`echo $1 | awk '{ T=$0; idx=index(T," "); printf("%d",idx); exit }'`
		if [ $ISSPC -eq $RET_FALSE ]; then
			XARG=$1
		else
			XARG="$1"
		fi
		xxmsg "chk_and_cp: NCP:$NCP/$NARG $1:$ISSPC:|$XARG|"
		if [ $NCP -eq $NARG ]; then
			DSTPATH="$XARG"
			break
		fi

		if [ -f "$XARG" ]; then
			CPFILES+=("$XARG")
		elif [ -d "$XARG" -a ! x"$XARG" = x"$DSTPATH" ]; then
			CPFILES+=("$XARG")
		else
			wmsg "chk_and_cp: $XARG: can't add to CPFILES, ignore"
			#cmd "ls -l $XARG"
		fi

		NCP=`expr $NCP + 1`
		shift
	done

	xmsg "chk_and_cp: CPOPT:$CPOPT NCP:$NCP CPFILES:${CPFILES[@]} DSTPATH:$DSTPATH"
	if [ x"${CPFILES[0]}" = x ]; then
		emsg "chk_and_cp: bad arg, no CPFILES"
		return $ERR_BADARG
	fi

	if [ x"$DSTPATH" = x ]; then
		emsg "chk_and_cp: bad arg, no DSTPATH"
		return $ERR_BADARG
	fi

	if [ $NCP -eq 1 ]; then
		emsg "chk_and_cp: bad arg, only 1 parameter:$CPFILES $DSTPATH"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			return $ERR_BADARG
		else
			wmsg "NOEXEC, return RET_OK"
			return $RET_OK
		fi
	elif [ $NCP -eq 2 ]; then
		xmsg "chk_and_cp: NCP=2: CPFILES:${CPFILES[@]} DSTPATH:$DSTPATH"
		if [ -f "${CPFILES[0]}" -a ! -e "$DSTPATH" ]; then
			nothing
		elif [ -f "${CPFILES[0]}" -a -f "$DSTPATH" -a "${CPFILES[0]}" = "$DSTPATH" ]; then
			emsg "chk_and_cp: bad arg, same file"
			return $ERR_BADARG
		elif [ -d "${CPFILES[0]}" -a -f "$DSTPATH" ]; then
			emsg "chk_and_cp: bad arg, dir to file"
			return $ERR_BADARG
		elif [ -f "${CPFILES[0]}" -a -f "$DSTPATH" ]; then
			nothing
		elif [ -f "${CPFILES[0]}" -a -d "$DSTPATH" ]; then
			nothing
		fi
	elif [ ! -e "$DSTPATH" ]; then
		emsg "chk_and_cp: DSTPATH:$DSTPATH: not existed"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			return $ERR_NOTEXISTED
		else
			wmsg "NOEXEC, return RET_OK"
			return $RET_OK
		fi
	elif [ ! -d "$DSTPATH" ]; then
		emsg "chk_and_cp: not dir"
		return $ERR_NOTDIR
	fi

	#msg "CPFILES=\`eval echo $CPFILES\`"
	#CPFILES=`eval echo $CPFILES`
	if [ $NOEXEC -eq $RET_FALSE -a $NOCOPY -eq $RET_FALSE ]; then
		if [ $VERBOSE -ge 2 ]; then
			#cmd "ls -a"
			nothing
		fi
		xmsg "chk_and_cp: CPFILES:${CPFILES[@]}"
		#mcmd cp $CPOPT "${CPFILES[@]}" $DSTPATH || return $?
		msg cp $CPOPT "${CPFILES[@]}" $DSTPATH
		cp $CPOPT "${CPFILES[@]}" $DSTPATH || return $?
	else
		wmsg "noexec: cp $CPOPT ${CPFILES[@]} $DSTPATH"
	fi

	return $RET_OK
}
# chk_and_cp test code
test_chk_and_cp()
{
	# test files and dir, test-no.$$, testdir-no.$$: not existed
	touch test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ "test with space.$$"
	rm test-no.$$
	mkdir testdir.$$
	rmdir testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ "test with space.$$" test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: create test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ \"test with space.$$\" test-no.$$ testdir.$$ testdir-no.$$"
	func_test_reset

	# test code
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp
	func_test $ERR_NOARG "no CPOPT: chk_and_cp"

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
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-no.$$"
	mcmd ls -l test-no.$$; rm -rf test-no.$$; func_test_trail
	chk_and_cp -p test.$$ test-1.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$"
	mcmd ls -l test-1.$$; func_test_trail
	chk_and_cp -p test.$$ test.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test.$$ test.$$"
	chk_and_cp -p test.$$ testdir-no.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ testdir-no.$$"
	mcmd ls -l testdir-no.$$; rm -rf testdir-no.$$; func_test_trail
	chk_and_cp -p test.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail

	chk_and_cp -p test.$$ test-no.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-no.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ test.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ test-1.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ testdir-no.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ testdir-no.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ testdir.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ testdir.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail

	# with space
	chk_and_cp -p "test with space.$$"
	func_test $ERR_BADARG "bad arg: chk_and_cp -p \"test with space.$$\""

	chk_and_cp -p test-no.$$ "test with space.$$"
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ \"test with space.$$\""

	chk_and_cp -p "test with space.$$" test-no.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p \"test with space.$$\" test-no.$$"
	mcmd ls -l test-no.$$; rm -rf test-no.$$; func_test_trail
	chk_and_cp -p "test with space.$$" testdir-no.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p \"test with space.$$\" testdir-no.$$"
	mcmd ls -l testdir-no.$$; rm -rf testdir-no.$$; func_test_trail
	chk_and_cp -p "test with space.$$" testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p \"test with space.$$\" testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p "test with space.$$" test-1.$$ test-no.$$
	func_test NOTRAIL $ERR_NOTEXISTED "not existed: chk_and_cp -p \"test with space.$$\" test-1.$$ test-no.$$"
	mcmd ls -l test-no.$$; rm -rf test-no.$$; func_test_trail
	chk_and_cp -p test-1.$$ "test with space.$$" test-no.$$
	func_test NOTRAIL $ERR_NOTEXISTED "not existed: chk_and_cp -p test-1.$$ \"test with space.$$\" test-no.$$"
	mcmd ls -l test-no.$$; rm -rf test-no.$$; func_test_trail
	chk_and_cp -p "test with space.$$" test-1.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p \"test with space.$$\" test-1.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test-1.$$ "test with space.$$" testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test-1.$$ \"test with space.$$\" testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail
	chk_and_cp -p test-1.$$ test-2.$$ "test with space.$$" test-3.$$ test-4.$$ testdir.$$
	func_test NOTRAIL $RET_OK "ok: chk_and_cp -p test-1.$$ test-2.$$ \"test with space.$$\" test-3.$$ test-4.$$ testdir.$$"
	mcmd ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$; func_test_trail

	# reset test env
	func_test_show
	rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ "test with space.$$"
	rm -rf testdir.$$ testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$ "test with space.$$"
	msg "test_chk_and_cp: rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$ \"test with space.$$\""
}
#msg "test_chk_and_cp"; VERBOSE=1; test_chk_and_cp; exit 0

# func:get_latestdatefile ver: 2024.04.29
# yyyymmddHHMMSS filename
# get latest date and filename given FILENAME
# get_datefile FILENAME
get_latestdatefile()
{
	local FILE FILES i

	if [ ! $# -ge 1 ]; then
		emsg "get_latestdatefile: RETCODE:$ERR_NOARG: ARG:$*: need FILENAME, error return"
		return $ERR_NOARG
	fi

	FILE="$1"

	xmsg "get_latestdatefile: FILE:$FILE ARG:$*"

	FILES=`eval echo $FILE`
	xmsg "get_latestdatefile: FILES:$FILES"
	for i in $FILES
	do
		if [ ! -e $i ]; then
			emsg "get_latestdatefile: RETCODE:$ERR_NOTEXISTED: $FILE: not found, error return"
			return $ERR_NOTEXISTED
		fi
	done

	ls -ltr --time-style=+%Y%m%d%H%M%S $FILES | awk '
	BEGIN { XDT="0"; XNM="" }
	#{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; printf("%s %s D:%s %s\n",XDT,XNM,DT,NM) >> /dev/stderr }
	{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; }
	END { printf("%s %s\n",XDT,XNM) }
	'

	return $?
}
test_get_latestdatefile()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	# set test env
	DT=20231203145627
	OKFILE=test.$$
	OKFILE1=test.$$.1
	NGFILE=test-no.$$
	touch $OKFILE $OKFILE1
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
	func_test_reset

	# test code
	DF=`get_latestdatefile`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_latestdatefile"

	DF=`get_latestdatefile $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_latestdatefile $NGFILE"
	DF=`get_latestdatefile $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE"
	DF=`get_latestdatefile $OKFILE1`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE1"
	DF=`get_latestdatefile $OKFILE*`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE*"
	DF=`get_latestdatefile "$OKFILE*"`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile \"$OKFILE*\""
	DF=`get_latestdatefile $NGFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_latestdatefile $NGFILE2"
	DF=`get_latestdatefile $OKFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE2"

	# reset test env
	func_test_show
	rm $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	mcmd ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_latestdatefile"; VERBOSE=2; test_get_latestdatefile; exit 0

# func:get_datefile_date ver: 2023.12.30
# Ymd|ymd|md|full yyyymmddHHMMSS filename
# get date given YMDoption(Ymd,ymd,md,full) DATE FILENAME
# get_datefile_date OPT DATE FILENAME
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

	# set test env
	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	ls $OKFILE $NGFILE
	func_test_reset

	# test code
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

	# reset test env
	func_test_show
	rm $OKFILE $NGFILE
}
#msg "test_get_datefile_date"; VERBOSE=2; test_get_datefile_date; exit 0

# func:get_datefile_file ver: 2024.04.29
# yyyymmddHHMMSS filename
# get filename given DATE FILENAME
# get_datefile_file DATE FILENAME
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

	# set test env
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
	mcmd ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
	func_test_reset

	# test code
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

	# reset test env
	func_test_show
	rm $OKFILE $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	mcmd ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_datefile_file"; VERBOSE=2; test_get_datefile_file; exit 0

# func:find_latest ver: 2024.04.29
# find latest created/modified files from DTTMSTART, use DTTMSHSTART if no VARDTTMSTART
# find_latest [VARDTTMSTART]
find_latest()
{
	local VARDTTMSTART DTTMNOW DTTMSTART DTTMSEC DTTMMIN

	if [ ! x"$1" = x ]; then
		VARDTTMSTART=$1
	else
		VARDTTMSTART=DTTMSHSTART
	fi

	get_datetime DTTMNOW
	xmsg "find_latest: DTTMNOW:$DTTMNOW"

	xmsg "find_latest: VARDTTMSTART:$VARDTTMSTART"
	DTTMSTART=`eval echo '$'${VARDTTMSTART}`
	xmsg "find_latest: DTTMSTART:$DTTMSTART"

	DTTMSEC=`diff_datetime $DTTMSTART $DTTMNOW`
	DTTMMIN=`expr $DTTMSEC + 59`
	DTTMMIN=`expr $DTTMMIN / 60`
	xmsg "find_latest: DTTMSEC:$DTTMSEC DTTMMIN:$DTTMMIN"

	xcmd find . -maxdepth 1 -type f -cmin -$DTTMMIN -mmin -$DTTMMIN -exec ls -l '{}' \;
}
test_find_latest()
{
	local DTTMSTART1 DTTMSTART2

	# set env
	sleep 1
	get_datetime DTTMSTART1
	touch tmp1.$$ tmp2.$$
	msg "wait 60 sec ..."
	sleep 60
	touch tmp3.$$ tmp4.$$
	get_datetime DTTMSTART2
	msg "DTTMSHSTART:$DTTMSHSTART DTTMSTART1:$DTTMSTART1 DTTMSTART2:$DTTMSTART2"
	ls -l tmp1.$$ tmp2.$$ tmp3.$$ tmp4.$$
	func_test_reset

	# test code
	find_latest
	func_test $RET_OK "ok: find_latest tmp1-4"
	find_latest DTTMSHSTART
	func_test $RET_OK "ok: find_latest DTTMSHSTART:$DTTMSHSTART tmp1-4"
	find_latest DTTMSTART1
	func_test $RET_OK "ok: find_latest DTTMSHSTART:$DTTMSTART1 tmp1-4"
	find_latest DTTMSTART2
	func_test $RET_OK "ok: find_latest DTTMSHSTART:$DTTMSTART2 tmp3-4"

	# reset env
	func_test_show
	DTTMSTART1=
	DTTMSTART2=
	rm tmp1.$$ tmp2.$$ tmp3.$$ tmp4.$$
}
#msg "test_find_latest"; VERBOSE=2; test_find_latest; exit 0


###
# intel oneAPI
INTELONEAPI=$RET_FALSE
SYCL=$RET_FALSE
IONEAPISH=/opt/intel/oneapi/setvars.sh

# func:chk_inteloneapi ver: 2024.02.18
# check Intel oneAPI compiler
# chk_inteloneapi
chk_inteloneapi()
{
	local RETCODE

	if [ ! -f $IONEAPISH ]; then
		emsg "can't exist $IONEAPISH, skip"
		return $ERR_NOTEXISTED
	fi

	cmd "source $IONEAPISH"
	RETCODE=$?
	if [ $RETCODE -eq $RET_OK -o $RETCODE -eq 3 ]; then
		msg "OK: RETCODE:$RETCODE $IONEAPI"
	else
		die $RETCODE "NG: $IONEAPI, exit"
	fi
	cmd icpx --version || die $? "RETCODE:$RETCODE: no icpx, exit"
	cmd icx --version || die $? "RETCODE:$RETCODE: no icx, exit"
	cmd icx-cc --version || die $? "RETCODE:$RETCODE: no icx-cc, exit"

	return $RET_OK
}
#msg "test chk_inteloneapi"; chk_inteloneapi; exit 0


###
# func:get_gitbranch ver: 2024.01.15
# get current git branch to VARBRANCH
# get_gitbranch VARBRANCH
get_gitbranch()
{
	local RETCODE VARBRANCH XPWD XBRANCH VALBRANCH

	xmsg "get_gitbranch: $*"

	if [ x"$GITDIR" = x ]; then
		emsg "get_gitbranch: no GITDIR, skip"
		return $ERR_BADSETTINGS
	fi
	if [ x"$1" = x ]; then
		emsg "get_gitbranch: need VARBRANCH, skip"
		return $ERR_NOARG
	fi

	RETCODE=$RET_OK

	VARBRANCH="$1"
	xxmsg "get_gitbranch: VARBRANCH:$VARBRANCH"

	#0 cd ~/github/stable-diffusion.cpp/
	#1 cd ~/github/stable-diffusion.cpp/stable-diffusion.cpp
	#1 cd ~/github/stable-diffusion.cpp/stable-diffusion.cpp/build
	#XPWD=`pwd`
	#xmsg "get_gitbranch: PWD:$XPWD"
	XPWD=`pwd | awk -v DIR="$GITDIR" '{ T=$0; I=index(T, DIR); print I }'`
	#xmsg "get_gitbranch: XPWD:$XPWD"
	if [ $XPWD -eq 0 ]; then
		XPWD=`pwd`
		xmsg "get_gitbranch: cd $GITDIR"
		cd $GITDIR
	else
		XPWD=""
		xmsg "get_gitbranch: under $GITDIR"
	fi

	XBRANCH=`git branch | awk '/^\*/ { T=$0; B=substr(T, 3); print B; exit }'`
	xmsg "get_gitbranch: XBRANCH:$XBRANCH"

	eval $VARBRANCH="$XBRANCH"
	VALBRANCH=`eval echo '$'${VARBRANCH}`
	xxmsg "get_gitbranch: XBRANCH:$XBRANCH $VARBRANCH:$VALBRANCH"

	if [ ! x"$XPWD" = x"" ]; then
		xmsg "get_gitbranch: cd $XPWD"
		cd $XPWD
	fi

	return $RETCODE
}
test_get_gitbranch()
{
	local GITDIR BRANCH

	# set env
	GITDIR=
	BRANCH=
	func_test_reset

	# test code
	GITDIR=
	get_gitbranch
	func_test $ERR_BADSETTINGS "bad settings: GITDIR:$GITDIR get_gitbranch"
	GITDIR=~/github/stable-diffusion.cpp/stable-diffusion.cpp
	cd ~/github/stable-diffusion.cpp
	get_gitbranch BRANCH
	func_test $RET_OK "ok: get_gitbranch BRANCH:$BRANCH"
	cd ~/github/stable-diffusion.cpp/stable-diffusion.cpp
	get_gitbranch BRANCH
	func_test $RET_OK "ok: get_gitbranch BRANCH:$BRANCH"
	cd ~/github/stable-diffusion.cpp/stable-diffusion.cpp/build
	get_gitbranch BRANCH
	func_test $RET_OK "ok: get_gitbranch BRANCH:$BRANCH"

	# reset env
	func_test_show
	BRANCH=
}
#msg "test_get_gitbranch"; VERBOSE=2; test_get_gitbranch; exit 0

TIMESTAMPS=$RET_FALSE

# func:git_init ver: 2024.04.21
# git init
# git_init GITTOKEN
git_init()
{
	# in git folder (TOPDIR)

	local GITTOKEN MAIL GITTOKENURL

	xmsg "git_init: $*"

	if [ x"$GITDIR" = x ]; then
		die $ERR_BADSETTINGS "git_init: need GITDIR, exit"
	fi
	if [ x"$GITNAME" = x ]; then
		die $ERR_BADSETTINGS "git_init: need GITNAME, exit"
	fi

	if [ x"$1" = x ]; then
		die $ERR_NOARG "git_init: need GITTOKEN like ghp_123456789012345678901234567890123456, exit"
	fi
	GITTOKEN="$1"

	# to GITDIR
	cmd cd "$GITDIR" || die $? "can't cd $GITDIR, exit"

	# check first time
	#if [ ! -f $TOPDIR/CMakeLists.txt ]; then
		msg "# setup git"
		cmd git init || die $? "can't git init, exit"

		MAIL="${GITNAME}@example.com"
		cmd git config --global user.email "$MAIL"
		cmd git config --global user.name "$GITNAME"

		# git remote add origin https://ghp_123456789012345678901234567890123456@github.com/GITNAME/ggml.git
		GITTOKENURL="https://${GITTOKEN}@github.com/${GITNAME}/${TOPDIR}.git"
		cmd git remote remove origin
		cmd git remote add origin $GITTOKENURL

		# save all timestamps
		if [ $TIMESTAMPS -eq $RET_TRUE ]; then
			mcmd $BASEDIR/pre-commit -a
			mcmd ls -la .timestamps*
		fi
	#fi
}

# func:git_showinfo ver: 2024.04.21
# show github info
# git_showinfo
git_showinfo()
{
	xmsg "git_showinfo: $*"

	if [ x"$GITDIR" = x ]; then
		die $ERR_BADSETTINGS "git_showinfo: need GITDIR, exit"
	fi

	# to GITDIR
	cmd cd $GITDIR || die $? "can't cd $GITDIR, exit"

	mcmd git config --list

	return $RET_OK
}

# func:do_sync ver: 2024.04.21
# update github token
# git_updatetoken GITTOKEN [removeadd]
git_updatetoken()
{
	local RETCODE XGITTOKEN XTOKENOPT XGITNAME XGITTOKENURL

	xmsg "git_updatetoken: $*"

	if [ x"$GITDIR" = x ]; then
		die $ERR_BADSETTINGS "git_updatetoken: need GITDIR, exit"
	fi
	if [ x"$GITNAME" = x ]; then
		die $ERR_BADSETTINGS "git_updatetoken: need GITNAME, exit"
	fi
	if [ x"$TOPDIR" = x ]; then
		die $ERR_BADSETTINGS "git_updatetoken: need TOPDIR, exit"
	fi

	if [ x"$1" = x ]; then
		#cmd cd $GITDIR || die $? "can't cd $GITDIR, exit"
		cmd cd $GITDIR || emsg "can't cd $GITDIR, skip"
		mcmd git config --list
		# no arg
		die $ERR_NOARG "git_updatetoken: need GITTOKEN like ghp_123456789012345678901234567890123456, exit"
	fi
	XGITTOKEN="$1"
	XTOKENOPT="$2"
	xmsg "XGITTOKEN:$XGITTOKEN"
	xmsg "XTOKENOPT:$XTOKENOPT"

	# to GITDIR
	cmd cd $GITDIR || die $? "can't cd $GITDIR, exit"

	mcmd git config --list

	XGITNAME=
	msg "git config --global user.name"
	XGITNAME=`git config --global user.name`
	msg "GITNAME:$GITNAME"

	# git remote add origin https://ghp_123456789012345678901234567890123456@github.com/GITNAME/ggml.git
	XGITTOKENURL="https://${GITNAME}:${XGITTOKEN}@github.com/${GITNAME}/${TOPDIR}.git"
	if [ x"$XTOKENOPT" = x"removeadd" ]; then
		cmd git remote remove origin
		cmd git remote add origin $XGITTOKENURL
	else
		cmd git remote set-url origin $XGITTOKENURL
	fi
	RETCODE=$?
	mcmd git config --list

	if [ ! $RETCODE -eq $RET_OK ]; then
		emsg "git_updatetoken: $RETCODE: error"
	fi

	return $RETCODE
}

# func:do_sync ver: 2024.04.21
# do synchronize remote BRANCH
# do_sync
do_sync()
{
	# in build

	msg "# synchronizing ..."

	if [ x"$BRANCH" = x ]; then
		die $ERR_BADSETTINGS "do_sync: need BRANCH, exit"
	fi

	msg "git branch"
	git branch
	cmd git checkout $BRANCH
	cmd git fetch || die $? "can not git fetch, exit"
	cmd git reset --hard origin/master

	#msg "ls -lad $GITDIR/*"; ls -lad $GITDIR/*
	if [ $TIMESTAMPS -eq $RET_TRUE ]; then
		mcmd ls -la $GITDIR/.timestamps*
		mcmd $BASEDIR/post-checkout -d $GITDIR
		mcmd ls -lad $GITDIR/*

		# save timestamps
		mcmd $BASEDIR/pre-commit -d $GITDIR
		mcmd ls -la $GITDIR/.timestamps*
	fi
}

###
GITNAME=katsu560
TOPDIR=llama.cpp
REMOTEURL=https://github.com/$GITNAME/$TOPDIR
BASEDIR=~/github/$TOPDIR
GITDIR="$BASEDIR/$TOPDIR"
BUILDPATH="$GITDIR/build"
# script
SCRIPT=script
FIXBASE="fix"
SCRIPTNAME=llamacpp
UPDATENAME=update-${GITNAME}-${SCRIPTNAME}${MYEXT}.sh
FIXSHNAME=${FIXBASE}[0-9][0-9][01][0-9][0-3][0-9]${MYEXT}.sh
FIXSHLATESTNAME=${FIXBASE}latest${MYEXT}.sh
MKZIPNAME=mkzip-${SCRIPTNAME}${MYEXT}.sh
# https://raw.githubusercontent.com/katsu560/stable-diffusion.cpp/script/mkzip-sdcpp.sh
REMOTERAWURL=https://raw.githubusercontent.com/$GITNAME
# https://ghp_123456789012345678901234567890123456@github.com/katsu560/ggml.git
GITTOKEN=


# setup by git clone, git init
if [ x"$1" = x"setup" ]; then
	if [ x"$1" = x ]; then
		die $ERR_NOARG "setup: need GITTOKEN, exit"
	fi

	GITTOKEN="$2"
	SETUPOPT="$3"
	msg "# setup from $REMOTEURL"
	if [ ! -d $GITDIR ]; then
		cmd git clone $REMOTEURL || die $? "RETCODE:$?: can't clone $REMOTEURL, exit"
	fi
	if [ ! -d $GITDIR ]; then
		die $ERR_NOTEXISTED "setup: no GITDIR $GITDIR, exit"
	fi
	if [ -d $GITDIR ]; then
		mcmd ls -ld $GITDIR
		okmsg "# git clone finished"

		cmd git_init $GITTOKEN $SETUPOPT || die $? "RETCODE:$?: can't git_init, exit"

		mcmd cd $BASEDIR
		okmsg "# git init finished"
	fi

	if [ ! -f $MKZIPNAME ]; then
		MKZIPNAMEURL="$REMOTERAWURL/$TOPDIR/$SCRIPT/$MKZIPNAME"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			#cmd wget -4 $MKZIPNAMEURL || die $? "RETCODE:$?: can't download $MKZIPNAME, exit"
			cmd wget -4 $MKZIPNAMEURL || emsg "RETCODE:$?: can't download $MKZIPNAME, skip"
		else
			chmod +x $MKZIPNAME
			okmsg "# $MKZIPNAME downloaded"
		fi
	else
		okmsg "# $MKZIPNAME already existed, skip"
	fi
	if [ ! -f $FIXSHLATESTNAME ]; then
		FIXSHLATESTNAMEURL="$REMOTERAWURL/$TOPDIR/$SCRIPT/$FIXSHLATESTNAME"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			#cmd wget -4 $FIXSHLATESTNAMEURL || die $? "RETCODE:$?: can't download $FIXSHLATESTNAME, exit"
			cmd wget -4 $FIXSHLATESTNAMEURL || emsg "RETCODE:$?: can't download $FIXSHLATESTNAME, skip"
		else
			chmod +x $FIXSHLATESTNAME
			okmsg "# $FIXSHLATESTNAME downloaded"
		fi
	else
		okmsg "# $FIXSHLATESTNAME already existed, skip"
	fi

	okmsg "# $MYNAME setup finished"
	exit $RET_OK
fi

# cmake
# check OpenBLAS
BLASCMKLIST="$TOPDIR/CMakeLists.txt"
if [ ! -f $BLASCMKLIST ]; then
	die $ERR_NOTEXISTED "not existed: BLASCMKLIST:$BLASCMKLIST, exit\nif you want to setup, do ./$MYNAME setup GITTOKEN like ghp_123456789012345678901234567890123456"
fi
OPENBLAS=`grep -sr LLAMA_OPENBLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*LLAMA_OPENBLAS.*/LLAMA_OPENBLAS/'`
BLAS=`grep -sr LLAMA_BLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*LLAMA_BLAS.*/LLAMA_BLAS/'`
if [ ! x"$OPENBLAS" = x ]; then
	# old CMakeLists.txt
	LLAMA_OPENBLAS="-DLLAMA_OPENBLAS=ON"
	BLASVENDOR=""
	msg "# use LLAMA_OPENBLAS=$LLAMA_OPENBLAS BLASVENDOR=$BLASVENDOR"
else
	LLAMA_OPENBLAS=
	BLASVENDOR=
fi
if [ ! x"$BLAS" = x ]; then
	# new CMakeLists.txt from 2023.6
	LLAMA_OPENBLAS="-DLLAMA_BLAS=ON"
	BLASVENDOR="-DLLAMA_BLAS_VENDOR=OpenBLAS"
	msg "# use LLAMA_BLAS=$LLAMA_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
if [ ! x"$LLAMA_OPENBLAS" = x ]; then
	CMKOPTBLAS="$LLAMA_OPENBLAS $BLASVENDOR"
else
	CMKOPTBLAS=""
fi

CMKCOMMON="-DLLAMA_CURL=ON -DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPTNOAVX="-DLLAMA_AVX=OFF -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=OFF $CMKOPTBLAS $CMKCOMMON"
CMKOPTAVX="-DLLAMA_AVX=ON -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=ON $CMKOPTBLAS $CMKCOMMON"
CMKOPTAVX2="-DLLAMA_AVX=ON -DLLAMA_AVX2=ON -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=ON -DLLAMA_F16C=ON $CMKOPTBLAS $CMKCOMMON"
CMKOPTNONE="$CMKOPTBLAS $CMKCOMMON"
CMKOPT="$CMKOPTNONE"
CMKOPT2=""
#msg "CMKOPTBLAS:$CMKOPTBLAS CMKOPT:$CMKOPT CMKOPT2:$CMKOPT2"; exit 0

# targets
# /llama.cpp/Makefile
# # Define the default target now so that it is always the first target
#BUILD_TARGETS = \
#	main quantize quantize-stats perplexity imatrix embedding vdot q8dot train-text-from-scratch convert-llama2c-to-ggml \
#	simple batched batched-bench save-load-state server gguf llama-bench libllava.a llava-cli baby-llama beam-search \
#	speculative infill tokenize benchmark-matmult parallel finetune export-lora lookahead lookup passkey tests/test-c.o
#
# Binaries only useful for tests
#TEST_TARGETS = \
#	tests/test-llama-grammar tests/test-grammar-parser tests/test-double-float tests/test-grad0 tests/test-opt \
#	tests/test-quantize-fns tests/test-quantize-perf tests/test-sampling tests/test-tokenizer-0-llama	  \
#	tests/test-tokenizer-0-falcon tests/test-tokenizer-1-llama tests/test-tokenizer-1-bpe tests/test-rope      \
#	tests/test-backend-ops tests/test-model-load-cancel tests/test-autorelease
#
# :
#test: $(TEST_TARGETS)
#tests: $(TEST_TARGETS)
#tests/test-llama-grammar: tests/test-llama-grammar.cpp ggml.o grammar-parser.o $(OBJS)
#tests/test-grammar-parser: tests/test-grammar-parser.cpp ggml.o llama.o grammar-parser.o $(OBJS)
# :
#tests/test-autorelease: tests/test-autorelease.cpp ggml.o llama.o tests/get-model.cpp $(COMMON_DEPS) $(OBJS)
#tests/test-chat-template: tests/test-chat-template.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)

NOTGTS="gguf libllava.a benchmark-matmult tests/test-c.o"
TARGETS=
TGTDONE=$RET_FALSE

# for llama.cpp
# func:get_targets ver: 2024.03.24
# get make targets to TARGETS for llama.cpp
# get_targets
get_targets()
{
	local MKFILE

	if [ $TGTDONE -eq $RET_TRUE ]; then
		return $RET_OK
	fi

	MKFILE=$GITDIR/Makefile
	if [ ! -e $MKFILE ]; then
		#die $ERR_NOTEXISTED "no $MKFILE, exit"
		emsg "no $MKFILE"
		return $ERR_NOTEXISTED
	fi

	TARGETS=""

	msg "NOTGTS:$NOTGTS"
	TARGETS=`awk -v NOTGT0="$NOTGTS" '
	BEGIN { ST=0; split(NOTGT0,NOTGT) }
	function is_notgt(tgt) {
       		for(i in NOTGT) { if (NOTGT[i]==tgt) return 1; continue }
       		return 0;
	}
	ST==1 && /^$/ { ST=2 }
	ST==1 && !/^$/ { T=$0; sub(/[\r\n]$/,"",T); sub(/^[ ]*/,"",T); sub(/\\\/,"",T); split(T,TGT0); for(I in TGT0) { if (is_notgt(TGT0[I])==0) { printf("%s ",TGT0[I]) } } }
	ST==0 && /^BUILD_TARGETS = / { ST=1 }
	' $MKFILE`
	msg "TARGETS:$TARGETS"

	if [ x"$TARGETS" = x ]; then
		die $ERR_NOARG "get_targets: no TARGETS, exit"
	fi

	TGTDONE=$RET_TRUE

	return $RET_OK
}
#get_targets; exit 0

# for test, main, examples execution
TESTENV="GGML_NLOOP=1 GGML_NTHREADS=4"

PROMPT="Building a website can be done in 10 simple steps:"
#PROMPTCHAT="Tell me about FIFA worldcup 2022 Qatar. What country win the match?"
PROMPTCHAT="### Instruction: What is the height of Mount Fuji?"
PROMPTJP="日本語で回答ください。京都について教えてください"
PROMPTCHATJP="### Intstruction: Answer in Japanese. 日本語で回答ください。富士山の高さは何メートルですか？"
SEEDOPT=1681527203
SEED=
MAINBIN="main"
#MAINOPT="--log-disable"
#MAINOPT=""
#MAINOPT="--repeat-last-n 128 --repeat-penalty 1.2 --frequency-penalty 1.2"
#MAINOPT="--repeat-last-n 64 --repeat-penalty 2.0 --frequency-penalty 2.0 --presence-penalty 2.0"
MAINOPT="-n 128 --repeat-last-n 64 --repeat-penalty 1.2 --frequency-penalty 1.2 --presence-penalty 1.2"

MKCLEAN=$RET_FALSE
NOCLEAN=$RET_FALSE
MKTARGET=$RET_TRUE

DIRNAME=
BRANCH=
CMD=

###
# func:cd_buildpath ver: 2024.04.21
# cd BUILDPATH
# cd_buildpath
cd_buildpath()
{
	# cd BUILDPATH
	cmd cd $BUILDPATH
}

NOFIXMK=$RET_FALSE
# func:do_mk_script ver: 2024.06.23
# do script(FIXBASEyymmddMYEXT.sh mk) for create script
# do_mk_script
do_mk_script()
{
	# in build

	# update fixsh in BASEDIR and save update files
	msg "# creating FIXSH ..."

	local DTNOW DFFIXSH FFIXSH DFIXSH

	if [ $NOFIXMK -eq $RET_TRUE ]; then
		wmsg "skip creating FIXSH"
		return $RET_OK
	fi

	DTNOW=`date '+%y%m%d'`
	msg "DTNOW:$DTNOW"


	# to BASEDIR
	mcmd cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		cmd ls -ltr ${FIXSHNAME}*
	fi
	DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
	DFIXSH=`get_datefile_date ymd $DFFIXSH`
	FFIXSH=`get_datefile_file $DFFIXSH`
	# git change date as today, so get date from file name
	DFIXSH=`echo $FFIXSH | sed -e 's/'${FIXBASE}'//' -e 's/'${MYEXT}'\.sh.*//'`
	msg "FIXSH:$FFIXSH"

	# check
	msg "FFIXSH: DTNOW:$DTNOW DFIXSH:$DFIXSH"
	if [ ! x"$DTNOW" = x"$DFIXSH" ]; then
		msg "sh $FFIXSH mk"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			sh $FFIXSH mk
			if [ ! $? -eq $RET_OK ]; then
				die $? "RETCODE:$?: can't make ${FIXBASE}${DTNOW}${MYEXT}.sh, exit"
			fi
			if [ ! -s $FFIXSH ]; then
				rm -f $FFIXSH
				die $ERR_CANTCREATE "size zero, can't create ${FIXBASE}${DTNOW}${MYEXT}.sh, exit"
			fi

			DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
			FFIXSH=`get_datefile_file $DFFIXSH`
			msg "$FFIXSH: created"
			mcmd ls -l $FFIXSH
			if [ ! -s $FFIXSH ]; then
				rm -f $FFIXSH
				die $ERR_CANTCREATE "size zero, can't create ${FIXBASE}${DTNOW}${MYEXT}.sh, exit"
			fi
		fi
	else
		msg "$FFIXSH: already existed, skip"	
	fi

	# back to BUILDPATH
	mcmd cd_buildpath
}
#VERBOSE=2; do_mk_script; exit 0

# for llama.cpp
# func:do_cp ver: 2024.04.27
# do copy source,examples,tests files to DIRNAME for llama.cpp
# do_cp
do_cp()
{
	# in build

	msg "# copying ..."
	chk_and_cp -p ../ggml.[ch] ../k_quants.[ch] ../ggml-alloc.h ../ggml-alloc.c ../ggml-opencl.h ../ggml-opencl.cpp ../llama.cpp ../llama.h ../llama-*.h ../CMakeLists.txt ../Makefile $DIRNAME || die 201 "can't copy files"
	chk_and_cp -pr ../examples $DIRNAME || die 202 "can't copy examples files"
	chk_and_cp -pr ../tests $DIRNAME || die 203 "can't copy tests files"
	chk_and_cp -pr ../common $DIRNAME || die 204 "can't copy common files"
	cmd find $DIRNAME -name '*.[0-9][0-9][01][0-9][0-3][0-9]*' -exec rm {} \;
}

# func:do_cmk ver: 2024.04.30
# do cmake .. CMKOPT CMKOPT2
# do_cmk
do_cmk()
{
	# in build

	if [ x"$CMKOPT" = x ]; then
		die $ERR_BADSETTINGS "do_cmk: need CMKOPT, exit"
	fi

	msg "# do cmake"
	if [ -f CMakeCache.txt ]; then
		cmd rm CMakeCache.txt || die $ERR_CANTDEL "can't delete CMakeCache.txt"
	fi
	cmd cmake .. $CMKOPT $CMKOPT2 || die $ERR_CANTCMAKE "cmake failed"
	chk_and_cp -p Makefile $DIRNAME/Makefile.build || die $? "can't copy Makefile as Makefile.build"

	# update targets
	mcmd get_targets
}

# func:mk_clean ver: 2024.04.30
# make clean
# mk_clean [MKOPT]
mk_clean()
{
	local XMKOPT

	xmsg "mk_clean: $*"

	XMKOPT=	
	if [ ! x"$1" = x ]; then
		XMKOPT="$1"
	fi
	
	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE -a ! x"$XMKOPT" = x"NOMAKE" ]; then
			make clean || die $ERR_CANTCLEAN "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi

	return $RET_OK
}

# for llama.cpp
# func:mk_main ver: 2024.05.20
# make main for llama.cpp
# mk_main [MKOPT]
mk_main()
{
	local XMKOPT XDTTM1 XDTTMSEC XDTTMMIN XBINS

	xmsg "mk_main: $*"

	XMKOPT=	
	if [ ! x"$1" = x ]; then
		XMKOPT="$1"
	fi

	if [ $NOCLEAN -eq $RET_FALSE ]; then
		if [ ! x"$MKOPT" = xNOMAKE -a $MKTARGET -eq $RET_TRUE ]; then
			mcmd get_targets || die $? "mk_main: RETCODE:$? can't get target, exit"
			TGTDONE=$RET_TRUE
			#cmd "cmake --build . --config Release --target $TARGETS" || die 252 "make main failed"
			cmd "cmake --build . --config Release" || die $ERR_CANTBUILD "make main failed"
			MKTARGET=$RET_FALSE
		fi
	fi
	if [ $NOCLEAN -eq $RET_FALSE ]; then
		if [ $TGTDONE -eq $RET_FALSE ]; then
			mcmd get_targets || die $? "mk_main: RETCODE:$? can't get target, exit"
			TGTDONE=$RET_TRUE
		fi
		if [ $MKTARGET -eq $RET_FALSE ]; then
			get_datetime XDTTM1
			XDTTMSEC=`diff_datetime $DTTM0 $XDTTM1`
			XDTTMMIN=`expr $XDTTMSEC + 59`
			XDTTMMIN=`expr $XDTTMMIN / 60`
			BINS=`find bin/ -type f -executable \( -cmin -$XDTTMMIN -o -mmin -$XDTTMMIN \) -exec echo '{}' \;`
			BINS=`echo $BINS | sed -e 's/\n/ /g'`
			msg "# copy $BINS to $DIRNAME ..."
			chk_and_cp -p $BINS $DIRNAME || die $? "can't cp main"
		fi
	fi

	return $RET_OK
}
test_cpbin()
{
	DTTM0=$1
	get_datetime XDTTM1
	msg "test_cpbin: DTTM0:$DTTM0 DTTM1:$XDTTM1"
	XDTTMSEC=`diff_datetime $DTTM0 $XDTTM1`
	XDTTMMIN=`expr $XDTTMSEC + 59`
	XDTTMMIN=`expr $XDTTMMIN / 60`
	ls -l bin/ | head
	#msg "BINS=\`find bin/ -type f -executable \( -cmin -$XDTTMMIN -o -mmin -$XDTTMMIN \) -exec echo \"'{}'\" \;\`"
	#BINS=`find bin/ -type f -executable \( -cmin -$XDTTMMIN -o -mmin -$XDTTMMIN \) -exec echo \"'{}'\" \;`
	msg "BINS=\`find bin/ -type f -executable \( -cmin -$XDTTMMIN -o -mmin -$XDTTMMIN \) -exec echo '{}' \;\`"
	BINS=`find bin/ -type f -executable \( -cmin -$XDTTMMIN -o -mmin -$XDTTMMIN \) -exec echo '{}' \;`
	#msg "BINS:$BINS"
	#msg "BINS=\`echo $BINS | sed -e 's/\n/ /g'\`"
	BINS=`echo $BINS | sed -e 's/\n/ /g'`
	msg "BINS:$BINS"
	msg "# copy $BINS to $DIRNAME ..."
	chk_and_cp -p $BINS $DIRNAME || die $? "can't cp main"
}
#VERBOSE=2; DIRNAME=240406up; cd_buildpath; test_cpbin $1; exit 0

# for llama.cpp
# func:do_test ver: 2024.05.20
# do make tests, then make test, move test exec-files to DIRNAME for llama.cpp
# do_test
do_test()
{
	# in build

	# update targets
	if [ $TGTDONE -eq $RET_FALSE ]; then
		mcmd get_targets || die $? "do_test: RETCODE:$? can't get target, exit"
		TGTDONE=$RET_TRUE
	fi

	msg "# testing ..."
	mk_clean
	mk_main

	cmd env $TESTENV make test || die $ERR_CANTTEST "make test failed"
}

CPSCRIPTFILES=
# func:cp_script ver: 2024.04.30
# copy srcfile to dstfile.yymmdd and dstfile, store dstfiles to CPSCRIPTFILES
# cp_script SRC DST
cp_script()
{
	local SRC DST DFSRC MDSRC DSTDT

	if [ ! $# -ge 2 ]; then
		emsg "cp_script: ARG:$*: need SRC DST, error return"
		return $ERR_NOARG
	fi

	SRC="$1"
	DST="$2"
	xmsg "cp_script: SRC:$SRC"
	xmsg "cp_script: DST:$DST"

	if [ ! -f "$SRC" ]; then
		emsg "cp_script: $SRC: not found, error return"
		return $ERR_NOTEXISTED
	fi
	if [ "$SRC" = "$DST" ]; then
		emsg "cp_script: $SRC: $DST: same file, error return"
		return $ERR_BADARG
	fi

	# DF DstFile
	DFSRC=`get_latestdatefile "$SRC"`
	xxmsg "cp_script: DFSRC:$DFSRC"
	YMDSRC=`get_datefile_date ymd $DFSRC`
	xxmsg "cp_script: YMDSRC:$YMDSRC"
	DSTDT="${DST}.$YMDSRC"
	cmd cp -p "$SRC" "$DSTDT" || die $ERR_CANTCOPY "can't copy $SRC to $DSTDT"
	cmd cp -p "$SRC" "$DST" || die $ERR_CANTCOPY "can't copy $SRC to $DST"
	CPSCRIPTFILES="$DSTDT $DST"
}
test_cp_script()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	# set test env
	DT=`date '+%y%m%d'`
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
	mcmd ls $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}* $TMPDIR1
	func_test_reset

	# test code
	cp_script
	func_test $ERR_NOARG "no arg: cp_script"

	#msg "ls -l $OKFILE $NGFILE $OKFILE2 $NGFILE2"
	cp_script $NGFILE
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $NGFILE"
	cp_script $OKFILE
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $OKFILE"
	cp_script $NGFILE2
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $NGFILE2"
	cp_script $OKFILE2
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $OKFILE2"

	cp_script $NGFILE $NGFILE2
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: cp_script $NGFILE $NGFILE2"
	cp_script $OKFILE $OKFILE2
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $OKFILE2"
	cp_script $OKFILE $NGFILE
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $NGFILE"
	rm $NGFILE
	cp_script $OKFILE $NGFILE2
	RETCODE=$?; mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $NGFILE2"
	rm $NGFILE2

	# reset test env
	func_test_show
	mcmd rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
	mcmd rmdir $TMPDIR1
	mcmd ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
}
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_TRUE; test_cp_script; exit 0
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_FALSE; test_cp_script; exit 0

# func:git_script ver: 2024.04.21
# git push scripts ymd, UPDATENAME, FIXSHNAME, MKZIPNAME
# git_script
git_script()
{
	# in build

	msg "# git push scripts ..."

	local DT0 ADDFILES COMMITFILES
	local DFUPDATE DFFIXSH DFMKZIP FUPDATE FFIXSH FMKZIP
	local DFUPDATEG DFFIXSHG DFMKZIPG FUPDATEG FFIXSHG FMKZIPG
	local TBRANCH

	# check
	if [ x"$BASEDIR" = x ]; then
		die $ERR_BADSETTINGS "git_script: need path, BASEDIR, exit"
	fi
	#if [ x"$TOPDIR" = x ]; then
	#	die $ERR_BADSETTINGS "git_script: need dirname, TOPDIR, exit"
	#fi
	if [ x"$GITDIR" = x ]; then
		die $ERR_BADSETTINGS "git_script: need dirname, GITDIR, exit"
	fi
	if [ x"${FIXSHNAME}" = x ]; then
		die $ERR_BADSETTINGS "git_script: need FIXSHNAME, exit"
	fi
	if [ x"${MKZIPNAME}" = x ]; then
		die $ERR_BADSETTINGS "git_script: need MKZIPNAME, exit"
	fi
	if [ x"${UPDATENAME}" = x ]; then
		die $ERR_BADSETTINGS "git_script: need UPDATENAME, exit"
	fi
	if [ x"$SCRIPT" = x ]; then
		die $ERR_BADSETTINGS "git_script: need branch, SCRIPT, exit"
	fi
	if [ x"$BRANCH" = x ]; then
		die $ERR_BADSETTINGS "git_script: need branch, BRANCH, exit"
	fi
	if [ x"$BUILDPATH" = x ]; then
		die $ERR_BADSETTINGS "git_script: need path, BUILDPATH, exit"
	fi

	DT0=`date '+%y%m%d'`
	msg "DT0:$DT0"

	ADDFILES=""
	COMMITFILES=""

	# to BASEDIR
	mcmd cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		cmd ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
	fi
	DFUPDATE=`get_latestdatefile "${UPDATENAME}"`
	DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
	DFMKZIP=`get_latestdatefile "${MKZIPNAME}"`
	FUPDATE=
	FFIXSH=
	FMKZIP=
	if [ ! x"$DFUPDATE" = x ]; then
		FUPDATE=`get_datefile_file $DFUPDATE`
	fi
	if [ ! x"$DFFIXSH" = x ]; then
		FFIXSH=`get_datefile_file $DFFIXSH`
	fi
	if [ ! x"$DFMKZIP" = x ]; then
		FMKZIP=`get_datefile_file $DFMKZIP`
	fi
	msg "FUPDATE:$FUPDATE"
	msg "FFIXSH:$FFIXSH"
	msg "FMKZIP:$FMKZIP"

	# to GITDIR
	# move to git SCRIPT branch and sync

	mcmd cd $GITDIR
	cmd git branch
	msg "git checkout $SCRIPT"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git checkout $SCRIPT
		# first time?
		if [ ! $? -eq $RET_OK ]; then
			cmd git checkout -b $SCRIPT || die $? "git_script: can not create $SCRIPT branch, exit"
			cmd git push -u origin $SCRIPT || die $? "git_script: can not create remote $SCRIPT branch, exit"
		fi
	fi
	# check branch
	get_gitbranch TBRANCH
	if [ ! x"$TBRANCH" = x"$SCRIPT" ]; then
		die $ERR_NOTEXISTED "git_script: BRANCH:$TBRANCH: not $SCRIPT branch, exit"
	fi

	if [ $TIMESTAMPS -eq $RET_TRUE ]; then
		# restore timestamps
		mcmd ls -lad $GITDIR/*
		mcmd ls -la $GITDIR/.timestamps*
		mcmd $BASEDIR/post-checkout --dir $GITDIR
		mcmd ls -lad $GITDIR/*
	fi

	# avoid error: pathspec 'fix1202.sh' did not match any file(s) known to git.
	# avoid  ! [rejected]	script -> script (non-fast-forward)  error: failed to push some refs to 'https://ghp_ ...
	# https://docs.github.com/ja/get-started/using-git/dealing-with-non-fast-forward-errors
	cmd git pull origin $SCRIPT
	if [ ! $? -eq $RET_OK ]; then
		RETCODE=$?
		cmd git checkout master
		die $RETCODE "git_script: RETCODE:$?: can not git pull origin $SCRIPT, exit"
	fi

	if [ $VERBOSE -ge 1 ]; then
		cmd ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
	fi

	# G means git
	DFUPDATEG=`get_latestdatefile "${UPDATENAME}"`
	DFFIXSHG=`get_latestdatefile "${FIXSHNAME}*"`
	DFMKZIPG=`get_latestdatefile "${MKZIPNAME}"`
	FUPDATEG=
	FFIXSHG=
	FMKZIPG=
	if [ ! x"$DFUPDATEG" = x ]; then
		FUPDATEG=`get_datefile_file $DFUPDATEG`
	fi
	if [ ! x"$DFFIXSHG" = x ]; then
		FFIXSHG=`get_datefile_file $DFFIXSHG`
	fi
	if [ ! x"$DFMKZIPG" = x ]; then
		FMKZIPG=`get_datefile_file $DFMKZIPG`
	fi
	msg "FUPDATEG:$FUPDATEG"
	msg "FFIXSHG:$FFIXSHG"
	msg "FMKZIPG:$FMKZIPG"

	#
	if [ ! x"$FUPDATE" = x ]; then
		if [ x"$FUPDATEG" = x ]; then
			# new copy
			FUPDATEG="$UPDATENAME"
			msg "new: copy: $BASEDIR/$FUPDATE $FUPDATEG"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp_script $BASEDIR/$FUPDATE $FUPDATEG
				ADDFILES="$ADDFILES $CPSCRIPTFILES"
				COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
			fi
		else
			# check diff, copy
			msg "diff $FUPDATEG $BASEDIR/$FUPDATE"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				if [ $VERBOSE -ge 1 ]; then
					diff $FUPDATEG $BASEDIR/$FUPDATE
				else
					diff $FUPDATEG $BASEDIR/$FUPDATE > /dev/null
				fi
				if [ $? -eq $RET_OK -a $FORCE -eq 0 ]; then
					msg "same: no copy: $BASEDIR/$FUPDATE $FUPDATEG"
				else
					msg "diff: copy: $BASEDIR/$FUPDATE $FUPDATEG"
					cp_script $BASEDIR/$FUPDATE $FUPDATEG
					ADDFILES="$ADDFILES $CPSCRIPTFILES"
					COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
				fi
			fi
		fi
	fi

	if [ ! x"FFIXSH" = x ]; then
		if [ x"$FFIXSHG" = x ]; then
			# new copy
			msg "new: copy: $BASEDIR/$FFIXSH $FFIXSH"
			msg "cp -p $BASEDIR/$FFIXSH $FFIXSH"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp -p $BASEDIR/$FFIXSH $FFIXSH
				ADDFILES="$ADDFILES $FFIXSH"
				COMMITFILES="$COMMITFILES $FFIXSH"
			fi
			msg "cp -p $BASEDIR/$FFIXSH $FIXSHLATESTNAME"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp -p $BASEDIR/$FFIXSH $FIXSHLATESTNAME
				ADDFILES="$ADDFILES $FIXSHLATESTNAME"
				COMMITFILES="$COMMITFILES $FIXSHLATESTNAME"
			fi
		elif [ ! $FFIXSH = $FFIXSHG ]; then
			# always copy
			msg "always: copy: $BASEDIR/$FFIXSH $FFIXSH"
			msg "cp -p $BASEDIR/$FFIXSH $FFIXSH"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp -p $BASEDIR/$FFIXSH $FFIXSH
				ADDFILES="$ADDFILES $FFIXSH"
				COMMITFILES="$COMMITFILES $FFIXSH"
			fi
			msg "cp -p $BASEDIR/$FFIXSH $FIXSHLATESTNAME"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp -p $BASEDIR/$FFIXSH $FIXSHLATESTNAME
				ADDFILES="$ADDFILES $FIXSHLATESTNAME"
				COMMITFILES="$COMMITFILES $FIXSHLATESTNAME"
			fi
		else
			# check diff, copy
			msg "diff $FFIXSHG $BASEDIR/$FFIXSH"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				if [ $VERBOSE -ge 1 ]; then
					diff $FFIXSHG $BASEDIR/$FFIXSH
				else
					diff $FFIXSHG $BASEDIR/$FFIXSH > /dev/null
				fi
				if [ $? -eq $RET_OK -a $FORCE -eq 0 ]; then
					msg "same: no copy: $BASEDIR/$FFIXSH $FFIXSHG"
				else
					msg "diff: copy: $BASEDIR/$FFIXSH $FFIXSHG"
					cp_script $BASEDIR/$FFIXSH $FFIXSHG
					ADDFILES="$ADDFILES $CPSCRIPTFILES"
					COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
					msg "cp -p $BASEDIR/$FFIXSH $FIXSHLATESTNAME"
					if [ $NOEXEC -eq $RET_FALSE ]; then
						cp -p $BASEDIR/$FFIXSH $FIXSHLATESTNAME
						ADDFILES="$ADDFILES $FIXSHLATESTNAME"
						COMMITFILES="$COMMITFILES $FIXSHLATESTNAME"
					fi
				fi
			fi
		fi
	fi

	if [ ! x"$FMKZIP" = x ]; then
		if [ x"$FMKZIPG" = x ]; then
			# new copy
			FMKZIPG="$MKZIPNAME"
			msg "new: copy: $BASEDIR/$FMKZIP $FMKZIPG"
			cp_script $BASEDIR/$FMKZIP $FMKZIPG
			ADDFILES="$ADDFILES $CPSCRIPTFILES"
			COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
		else
			# check diff, copy
			msg "diff $FMKZIPG $BASEDIR/$FMKZIP"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				if [ $VERBOSE -ge 1 ]; then
					diff $FMKZIPG $BASEDIR/$FMKZIP
				else
					diff $FMKZIPG $BASEDIR/$FMKZIP > /dev/null
				fi
				if [ $? -eq $RET_OK -a $FORCE -eq 0 ]; then
					msg "same: no copy: $BASEDIR/$FMKZIP $FMKZIPG"
				else
					msg "diff: copy: $BASEDIR/$FMKZIP $FMKZIPG"
					cp_script $BASEDIR/$FMKZIP $FMKZIPG
					ADDFILES="$ADDFILES $CPSCRIPTFILES"
					COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
				fi
			fi
		fi
	fi

	# git
	msg "ADDFILES:$ADDFILES"
	msg "COMMITFILES:$COMMITFILES"
	if [ ! x"$COMMITFILES" = x ]; then
		if [ ! x"$ADDFILES" = x ]; then
			cmd git add $ADDFILES
		fi
		cmd git commit -m "update scripts" $COMMITFILES
		cmd git status
		msg "git push origin $SCRIPT"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			git push origin $SCRIPT
			RETCODE=$?
			if [ ! $? -eq $RET_OK ]; then
				emsg "back to $BRANCH"
				mcmd git checkout $BRANCH
				die $RET_NG "can not git push origin $SCRIPT, exit"
			fi
		fi
	
		if [ $TIMESTAMPS -eq $RET_TRUE ]; then
			# save timestamps
			mcmd $BASEDIR/pre-commit -d $GITDIR
			mcmd ls -la .timestamps*
		fi
	fi

	# back
	cmd git checkout $BRANCH
	if [ $TIMESTAMPS -eq $RET_TRUE ]; then
		# restore timestamps
		mcmd ls -lad $GITDIR/*
		mcmd ls -la $GITDIR/.timestamps*
		mcmd $BASEDIR/post-checkout -d $GITDIR
		mcmd ls -lad $GITDIR/*
	fi

	# back to BUILDPATH
	mcmd get_targets
}
#msg "git_script"; NOEXEC=$RET_TRUE; VERBOSE=2; git_script; exit 0

# for llama.cpp
# func:do_bin ver: 2024.04.27
# execute DOBIN with MODEL, VARPROMPT, DOBINOPT for llama.cpp
# do_bin DOBIN MODEL VARPROMPT DOBINOPT
do_bin()
{
	local RETCODE XDOBIN XMODEL VARPROMPT DOBINOPT XSEED PROMPTTXT

	xmsg "do_bin: $*"

	RETCODE=$RET_OK

	if [ x"$DIRNAME" = x ]; then
		emsg "do_bin: need DIRNAME, skip"
		return $ERR_BADSETTINGS
	fi

	if [ x"$1" = x ]; then
		emsg "do_bin: need DOBIN, MODEL, VARPROMPT skip"
		return $ERR_BADARG
	fi
	XDOBIN="$1"
	XMODEL="$2"
	VARPROMPT="$3"
	shift 3
	DOBINOPT="$*"

	#msg "./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
	#./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"
	XSEED=$SEEDOPT
	PROMPTTXT=`eval echo '$'${VARPROMPT}`

	msg "#"
	# warmup
	get_physpath PHYSPATH "$XMODEL"
	mcmd ls -l $PHYSPATH

	msg "./$DIRNAME/$XDOBIN -m $XMODEL $DOBINOPT -s $XSEED -p \"$PROMPTTXT\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		./$DIRNAME/$XDOBIN -m $XMODEL $DOBINOPT -s $XSEED -p "$PROMPTTXT"
		RETCODE=$?

		ls -l $PHYSPATH
		msg "#./$DIRNAME/$XDOBIN -m $XMODEL $DOBINOPT -s $XSEED -p \"$PROMPTTXT\""

		if [ ! $RETCODE -eq $RET_OK ]; then
			emsg "do $XDOBIN failed"
		fi
	fi

	return $RETCODE
}


LEVELMIN2=2

# func:do_vicuna ver: 2024.03.24
# execute main with vicuna for llama.cpp
# do_vicuna DOOPT SUBOPT
do_vicuna()
{
	# in build

	xmsg "do_vicuna: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELMIN do_bin $MAINBIN ../models/vicuna/ggml-vic7b-q4_0.bin PROMPT "-n 512 $MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/ggml-vic7b-q4_1.bin PROMPT "-n 512 $MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/vicuna/ggml-vic7b-q4_0-new.bin PROMPT "-n 512 $MAINOPT"

			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q2_K.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q3_K_L.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q3_K_M.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q3_K_S.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q4_0.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q4_1.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q4_K_M.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q4_K_S.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q5_0.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q5_1.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q5_K_M.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q5_K_S.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q6_K.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/vicuna/vicuna-7b-1.1.ggmlv3.q8_0.bin PROMPT "$MAINOPT $OPT"
		fi
	else
		xmsg "do_vicuna: noexec"
	fi

	return $RET_OK
}

# func:do_cyberagent ver: 2024.03.24
# execute main with cyberagent calm for llama.cpp
# do_cyberagent DOOPT SUBOPT
do_cyberagent()
{
	# in build

	xmsg "do_cyberagent: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELMAX do_bin $MAINBIN ../models/cyberagent/ggml-calm-small-f32.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/cyberagent/ggml-calm-small-f16.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/cyberagent/ggml-calm-small-q4_0.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/cyberagent/ggml-calm-medium-f32.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/cyberagent/ggml-calm-medium-f16.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/cyberagent/ggml-calm-medium-q4_0.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/cyberagent/ggml-calm-large-f32.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/cyberagent/ggml-calm-large-f16.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/cyberagent/ggml-calm-large-q4_0.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/cyberagent/ggml-calm-1b-f32.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/cyberagent/ggml-calm-1b-f16.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/cyberagent/ggml-calm-1b-q4_0.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/cyberagent/ggml-calm-3b-f32.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/cyberagent/ggml-calm-3b-f16.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/cyberagent/ggml-calm-3b-q4_0.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/cyberagent/ggml-calm-7b-f32.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/cyberagent/ggml-calm-7b-f16.bin PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/cyberagent/ggml-calm-7b-q4_0.bin PROMPTJP "$MAINOPT"
		fi
	else
		xmsg "do_cyberagent: noexec"
	fi

	return $RET_OK
}

# func:do_llama2 ver: 2024.05.05
# execute main with llama2 for llama.cpp
# do_llama2 DOOPT SUBOPT
do_llama2()
{
	# in build

	xmsg "do_llama2: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama2/llama-2-7b.Q2_K.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b.Q3_K_S.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b.Q4_0.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMIN2 do_bin $MAINBIN ../models/llama2/llama-2-7b.Q4_K_M.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b.Q5_0.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b.Q5_K_S.gguf PROMPT "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama2/llama-2-7b.Q5_K_M.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b.Q6_0.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/llama2/llama-2-7b.Q8_0-local.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMIN2 do_bin $MAINBIN ../models/llama2/llama-2-7b.Q8_0.gguf PROMPT "$MAINOPT"
		fi
	else
		xmsg "do_llama2: noexec"
	fi

	return $RET_OK
}

# func:do_llama2chat ver: 2024.05.05
# execute main with llama2 chat for llama.cpp
# do_llama2chat DOOPT SUBOPT
do_llama2chat()
{
	# in build

	xmsg "do_llama2chat: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q2_K.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q3_K_S.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q3_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN2 do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q4_K_M.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q5_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q6_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q8_0-local.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN2 do_bin $MAINBIN ../models/llama2/llama-2-7b-chat.Q8_0.gguf PROMPTCHATJP "$MAINOPT"
		fi
	else
		xmsg "do_llama2chat: noexec"
	fi

	return $RET_OK
}

# func:do_swallow ver: 2024.05.05
# execute main with swallow for llama.cpp
# do_swallow DOOPT SUBOPT
do_swallow()
{
	# in build

	xmsg "do_swallow: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/swallow/swallow-7b-hf-Q2_K.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/swallow/swallow-7b-hf-Q3_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN2 do_bin $MAINBIN ../models/swallow/swallow-7b-hf-Q4_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/swallow/swallow-7b-hf-Q5_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/swallow/swallow-7b-hf-Q8_0.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/swallow/swallow-7b-hf-f16.gguf PROMPTJP "$MAINOPT"
		fi
	else
		xmsg "do_swallow: noexec"
	fi

	return $RET_OK
}

# func:do_karasu ver: 2024.05.05
# execute main with karasu for llama.cpp
# do_karasu DOOPT SUBOPT
do_karasu()
{
	# in build

	xmsg "do_karasu: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/karasu/karasu-1.1b-Q2_K.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/karasu/karasu-1.1b-Q3_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN2 do_bin $MAINBIN ../models/karasu/karasu-1.1b-Q4_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/karasu/karasu-1.1b-Q5_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/karasu/karasu-1.1b-Q8_0.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/karasu/karasu-1.1b-f16.gguf PROMPTJP "$MAINOPT"

			chk_level $LEVELSTD do_bin $MAINBIN ../models/karasu/karasu-7b-Q2_K.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/karasu/karasu-7b-Q3_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN2 do_bin $MAINBIN ../models/karasu/karasu-7b-Q4_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/karasu/karasu-7b-Q5_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/karasu/karasu-7b-Q8_0.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/karasu/karasu-7b-f16.gguf PROMPTJP "$MAINOPT"
		fi
	else
		xmsg "do_karasu: noexec"
	fi

	return $RET_OK
}

# func:do_llama3 ver: 2024.04.29
# execute main with llama3-8b for llama.cpp
# do_llama3 DOOPT SUBOPT
do_llama3()
{
	# in build

	xmsg "do_llama3: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama3/llama3-8b-Q2_K.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama3/llama3-8b-Q3_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/llama3/llama3-8b-Q4_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama3/llama3-8b-Q5_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama3/llama3-8b-Q8_0.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama3/llama3-8b-f16.gguf PROMPTJP "$MAINOPT"
		fi
	else
		xmsg "do_llama3: noexec"
	fi

	return $RET_OK
}

# func:do_llama3inst ver: 2024.04.29
# execute main with llama3-8b-inst for llama.cpp
# do_llama3inst DOOPT SUBOPT
do_llama3inst()
{
	# in build

	xmsg "do_llama3inst: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama3/llama3-8b-inst-Q2_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama3/llama3-8b-inst-Q3_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/llama3/llama3-8b-inst-Q4_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama3/llama3-8b-inst-Q5_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/llama3/llama3-8b-inst-Q8_0.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/llama3/llama3-8b-inst-f16.gguf PROMPTCHATJP "$MAINOPT"

			chk_level $LEVELMIN do_bin $MAINBIN ../models/llama3/llama3-8b-inst-Q4_K_M.gguf PROMPTJP "$MAINOPT"
		fi
	else
		xmsg "do_llama3inst: noexec"
	fi

	return $RET_OK
}

# func:do_tinyllama11 ver: 2024.04.29
# execute main with tinyllama-1.1b for llama.cpp
# do_tinyllama11 DOOPT SUBOPT
do_tinyllama11()
{
	# in build

	xmsg "do_tinyllama11: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELMIN do_bin $MAINBIN ../models/tinyllama/tinyllama-1.1b-1431k-Q2_K.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/tinyllama/tinyllama-1.1b-1431k-Q3_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/tinyllama/tinyllama-1.1b-1431k-Q4_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/tinyllama/tinyllama-1.1b-1431k-Q5_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/tinyllama/tinyllama-1.1b-1431k-Q6_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/tinyllama/tinyllama-1.1b-1431k-Q8_0.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/tinyllama/tinyllama-1.1b-1431k-f16.gguf PROMPTJP "$MAINOPT"
		fi
	else
		xmsg "do_tinyllama11: noexec"
	fi

	return $RET_OK
}

# func:do_phi2 ver: 2024.04.29
# execute main with phi-2 for llama.cpp
# do_phi2 DOOPT SUBOPT
do_phi2()
{
	# in build

	xmsg "do_phi2: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-2/phi-2-Q2_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-2/phi-2-Q3_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-2/phi-2-Q4_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-2/phi-2-Q5_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-2/phi-2-Q6_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-2/phi-2-Q8_0.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-2/phi-2-f16.gguf PROMPTCHATJP "$MAINOPT"

			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-2/phi-2-Q2_K.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-2/phi-2-Q4_K_M.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-2/phi-2-Q8_0.gguf PROMPTCHAT "$MAINOPT"

			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-2/phi2-q4_0.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-2/phi2-q8_0.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-2/phi2-f16.gguf PROMPTCHATJP "$MAINOPT"
		fi
	else
		xmsg "do_phi2: noexec"
	fi

	return $RET_OK
}

# func:do_phi3 ver: 2024.05.03
# execute main with phi-3 for llama.cpp
# do_phi3 DOOPT SUBOPT
do_phi3()
{
	# in build

	xmsg "do_phi3: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q2_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q3_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q4_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q5_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q6_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q8_0.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-f16.gguf PROMPTCHATJP "$MAINOPT"

			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q2_K.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q4_K_M.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-4k-inst-Q8_0.gguf PROMPTCHAT "$MAINOPT"
		
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q2_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q3_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q4_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q5_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q6_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q8_0.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-f16.gguf PROMPTCHATJP "$MAINOPT"

			chk_level $LEVELSTD do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q2_K.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q4_K_M.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/phi-3/phi-3-mini-128k-inst-Q8_0.gguf PROMPTCHAT "$MAINOPT"
		fi
	else
		xmsg "do_phi3: noexec"
	fi

	return $RET_OK
}

# func:do_kujira ver: 2024.06.02
# execute main with kujira for llama.cpp
# do_kujira DOOPT SUBOPT
do_kujira()
{
	# in build

	xmsg "do_kujira: $*"

	local DOOPT SUBOPT

	DOOPT="$1"
	SUBOPT="$2"

	if [ ! x"$DOOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
		if [ -f ./$DIRNAME/$MAINBIN ]; then
			chk_level $LEVELSTD do_bin $MAINBIN ../models/kujira/kujira-7b-Q2_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/kujira/kujira-7b-Q3_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/kujira/kujira-7b-Q4_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/kujira/kujira-7b-Q5_K_M.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/kujira/kujira-7b-Q6_K.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/kujira/kujira-7b-Q8_0.gguf PROMPTCHATJP "$MAINOPT"
			chk_level $LEVELSTD do_bin $MAINBIN ../models/kujira/kujira-7b-f16.gguf PROMPTCHATJP "$MAINOPT"

			chk_level $LEVELSTD do_bin $MAINBIN ../models/kujira/kujira-7b-Q2_K.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/kujira/kujira-7b-Q4_K_M.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/kujira/kujira-7b-Q8_0.gguf PROMPTCHAT "$MAINOPT"
		fi
	else
		xmsg "do_kujira: noexec"
	fi

	return $RET_OK
}

# for llama.cpp
# func:do_main ver: 2024.03.24
# execute main for llama.cpp
# do_main DOMAINOPT SUBOPT
do_main()
{
	# in build

	local DOOPT SUBOPT BINS

	DOOPT="$1"
	SUBOPT="$2"

	msg "# executing main ... (DOOPT:$DOOPT SUBOPT:$SUBOPT)"
	# make main
	if [ ! x"$DOOPT" = xNOMAKE ]; then
		mk_clean $DOOPT
		mk_main $DOOPT
	fi

	# main
	if [ ! x"$DOOPT" = xNOEXEC ]; then
		if [ -f ./$DIRNAME/$MAINBIN -a ! x"$SUBOPT" = xGGUF ]; then
			#msg "./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			chk_level $LEVELMIN do_bin $MAINBIN ../models/alpaca/ggml-alpaca-7b-q4.bin PROMPT "-n 512 $MAINOPT"

			#
			#
			chk_level $LEVELMIN do_bin $MAINBIN ../models/wizardlm/WizardLM-7B-uncensored.ggml.q4_0.bin PROMPT "-n 512 $MAINOPT"
					chk_level $LEVELSTD do_bin $MAINBIN ../models/wizardlm/WizardLM-7B-uncensored.ggml.q5_0.bin PROMPT "-n 512 $MAINOPT"
			chk_level $LEVELMAX do_bin $MAINBIN ../models/wizardlm/WizardLM-7B-uncensored.ggml.q5_1.bin PROMPT "-n 512 $MAINOPT"

			chk_level $LEVELMIN do_bin $MAINBIN ../models/wizardlm/Wizard-Vicuna-13B-Uncensored.ggml.q4_0.bin PROMPT "-n 512 $MAINOPT"

			# vicuna 1.1 2023.6
			do_vicuna $DOOPT $SUBOPT

			do_cyberagent $DOOPT $SUBOPT

			#
			#msg "./$DIRNAME/main -m ../models/7B/ggml-model-f32.bin $MAINOPT -p \"$PROMPT\""
			chk_level $LEVELMAX do_bin $MAINBIN ../models/7B/ggml-model-f32.bin PROMPT "$MAINOPT"
			chk_level $LEVELMIN do_bin $MAINBIN ../models/7B/ggml-model-q4_0.bin PROMPT "$MAINOPT"

		elif [ -f ./$DIRNAME/$MAINBIN ]; then
			# gguf since 2023.8
			do_llama2 $DOOPT $SUBOPT
			do_llama2chat $DOOPT $SUBOPT

			do_swallow $DOOPT $SUBOPT
			do_karasu $DOOPT $SUBOPT
			do_llama3 $DOOPT $SUBOPT
			do_llama3inst $DOOPT $SUBOPT
			do_phi2 $DOOPT $SUBOPT
			do_phi3 $DOOPT $SUBOPT
			do_kujira $DOOPT $SUBOPT
		else
			msg "no ./$DIRNAME/$MAINBIN, skip executing main"
		fi

		cmd "./$DIRNAME/quantize"
		cmd "./$DIRNAME/quantize-stats"
		cmd "./$DIRNAME/perplexity"
		cmd "./$DIRNAME/embedding"
		if [ -f ./$DIRNAME/benchmark-matmult ]; then
			cmd "./$DIRNAME/benchmark-matmult"
		fi
	else
		msg "skip executing main, tests and others"
	fi
}

# func:doone_cmd ver: 2024.04.21
# set DONECMD
# done_cmd
done_cmd()
{
	xmsg "done_cmd: $DONECMD -> RET_TRUE"
	DONECMD=$RET_TRUE
}


###
usage()
{
	echo "usage: $MYNAME [-h][-v][-n][-f][-nd][-ncp][-nc][-nofmk][-ts][-noavx|avx|avx2][-ione][-sycl][-qkk64][-lv LEVEL][-s SEED] dirname branch cmd"
	echo "       $MYNAME setup GITTOKEN"
	echo "       $MYNAME [-h][-v][-n][-f][-nd][-ncp] token|gitinfo [TOKEN][OPT]"
	echo "options: (default)"
	echo "  -h|--help ... this message"
	echo "  -v|--verbose ... increase verbose message level ($VERBOSE)"
	echo "  -n|--noexec ... no execution, test mode ($NOEXEC)"
	echo "  -f|--force ... increase force level ($FORCE)"
	echo "  -nd|--nodie ... no die ($NODIE)"
	echo "  -ncp|--nocopy ... no copy ($NOCOPY)"
	echo "  -nc|--noclean ... no make clean ($NOCLEAN)"
	echo "  -nofmk|--nofixmk ... no fix script mk ($NOFIXMK)"
	echo "  -ts|--timestamps ... process timestamps (FALSE)"
	#echo "  -up ... upstream, no mod source, skip benchmark-matmult"
	echo "  -noavx|-avx|-avx2 ... set cmake option for no AVX, AVX, AVX2 (AVX)"
	echo "  -ione|--inteloneapi ... using Intel oneAP compiler ($INTELONEAPI)"
	echo "  -sycl|--sycl ... using SYCL with intel oneAPI compiler ($SYCL)"
	echo "  -qkk64 ... add cmake option for QKK_64"
	echo "  -lv|--level LEVEL ... set execution level as LEVEL, min. 1 .. max. 5 ($DOLEVEL)"
	echo "  -s|--seed SEED ... set SEED ($SEEDOPT)"
	echo "  dirname ... directory name ex. 240520up"
	echo "  branch ... git branch ex. master, gq, devpr"
	echo "  cmd ... sycpcmktstmain sy/sync,cp/copy,cmk/cmake,tst/test,main"
	echo "  cmd ... sycpcmktstnm sy,cp,cmk,tst,nm  nm .. build main but no exec"
	echo "  cmd ... mainonly .. main execution only"
	echo "  cmd ... ggufonly .. main execution w/ gguf models only"
	echo "  cmd ... ca/cyberagent .. main execution w/ given models"
	echo "  cmd ... llama2 llama2chat swallow karasu .. main execution w/ gguf models"
	echo "  cmd ... llama3 llama3inst tinyllama/tllama phi-2/phi2 phi-3/phi3 .. main execution w/ gguf models"
	echo "  cmd ... kujira/kujira7b .. main execution w/ gguf models"
	echo "  cmd ... script .. push $UPDATENAME $MKZIPNAME $FIXSHNAME to remote"
	echo ""
	echo "  cmd ... setup .. setup $TOPDIR with GITTOKEN, git clone, init, download scripts"
	echo "  cmd ... token [TOKEN][OPT] .. update git token with TOKEN, opt .. removeadd"
	echo "  cmd ... gitinfo .. show github info"
}
# default -avx
CMKOPT="$CMKOPTAVX"
CMKOPT2=""

###
# options and args
if [ x"$1" = x ]; then
	usage
	exit $ERR_USAGE
fi

ALLOPT="$*"
OPTLOOP=$RET_TRUE
while [ $OPTLOOP -eq $RET_TRUE ];
do
	case $1 in
	-h|--help)	usage; exit $ERR_USAGE;;
	-v|--verbose)	VERBOSE=`expr $VERBOSE + 1`;;
	-n|--noexec)	NOEXEC=$RET_TRUE;;
	-f|--force)	FORCE=`expr $FORCE + 1`;;
	-nd|--nodie)	NODIE=$RET_TRUE;;
	-ncp|--nocopy)	NOCOPY=$RET_TRUE;;
	-nc|--noclean)	NOCLEAN=$RET_TRUE;;
	-nofmk|--nofixmk)
			NOFIXMK=$RET_TRUE;;
	-ts|--timestamps)
			TIMESTAMPS=$RET_TRUE;;
	#-up)		ALLBINS="$ALLBINSUP";;
	-noavx)		CMKOPT="$CMKOPTNOAVX";;
	-avx)		CMKOPT="$CMKOPTAVX";;
	-avx2)		CMKOPT="$CMKOPTAVX2";;
	-ione|-ioneapi|--intel|--intelone|--inteloneapi)
			INTELONEAPI=$RET_TRUE;;
	-sycl|--sycl)	SYCL=$RET_TRUE; INTELONEAPI=$RET_TRUE;;
	-qkk64)		CMKOPT2="-DLLAMA_QKK_64=ON";;
	-lv|--level)	shift; DOLEVEL=$1;;
	-s|--seed)	shift; SEEDOPT=$1;;
	*)		OPTLOOP=$RET_FALSE; break;;
	esac
	shift
done

# default -avx|AVX
if [ x"$CMKOPT" = x"" ]; then
	CMKOPT="$CMKOPTAVX"
fi
#CMKOPT="$CMKOPT $CMKOPT2"

# token
if [ x"$1" = x"token" ]; then
	shift
	mcmd git_updatetoken $*
	exit $?
fi
if [ x"$1" = x"gitinfo" ]; then
	shift
	mcmd git_showinfo $*
	exit $?
fi

if [ $# -lt 3 ]; then
	usage
	exit $ERR_USAGE
fi
DIRNAME="$1"
BRANCH="$2"
CMD="$3"
shift 2
ADDINTEL=$RET_FALSE
ADDSYCL=$RET_FALSE

xmsg "VERBOSE:$VERBOSE NOEXEC:$NOEXEC FORCE:$FORCE NODIE:$NODIE NOCOPY:$NOCOPY"
xmsg "NOCLEAN:$NOCLEAN NOFIXMK:$NOFIXMK TIMESTAMPS:$TIMESTAMPS"
xmsg "CMKOPT:$CMKOPT CMKOPT2:$CMKOPT2"
xmsg "LEVEL:$DOLEVEL SEED:$SEEDOPT"
xmsg "INTELONEAPI:$INTELONEAPI SYCL:$SYCL"
if [ $NOEXEC -eq $RET_TRUE ]; then
	emsg "SET NOEXEC as TRUE"
fi

###
# setup part

msg "# start"
get_datetime DTTM0
msg "# date time: $DTTM0"

# warning:  Clock skew detected.  Your build may be incomplete.
cmd sudo ntpdate ntp.nict.jp || die $? "can not ntp sync, exit"

# check
if [ $NOEXEC -eq $RET_FALSE ]; then
	if [ ! -d $TOPDIR ]; then
		die $ERR_NOTOPDIR "# can't find $TOPDIR, exit"
	fi
else
	msg "skip check $TOPDIR"
fi
if [ ! -d $BUILDPATH ]; then
	cmd mkdir -p $BUILDPATH
	if [ ! -d $BUILDPATH ]; then
		die $ERR_NOBUILDDIR "# can't find $BUILDPATH, exit"
	fi
fi

msg "cd $BUILDPATH"
cd $BUILDPATH

cmd git branch
get_gitbranch CURBRANCH
if [ $TIMESTAMPS -eq $RET_TRUE ]; then
	if [ ! x"$BRANCH" = x"$CURBRANCH" ]; then
		emsg "branch mismatch $BRANCH != $CURBRANCH"
		emsg "ls -al $GITDIR/.timestamps*"
		ls -al $GITDIR/.timestamps*
		emsg "do ../pre-commit [-a], ../post-checkout [-r reference-branch]"
		die $ERR_BADSETTINGS "branch mismatch $BRANCH != $CURBRANCH, exit"
	fi
fi

cmd git checkout $BRANCH
TBRANCH=
get_gitbranch TBRANCH
xmsg "TBRANCH:$TBRANCH"
if [ ! $? -eq $RET_OK ]; then
	die $? "# can't git checkout BRANCH:$BRANCH, exit"
elif [ ! $TBRANCH = $BRANCH ]; then
	die $ERR_BADARG "# BRANCH:$TBRANCH: can't git checkout BRANCH:$BRANCH, exit"
fi

if [ ! -e $DIRNAME ]; then
	cmd mkdir $DIRNAME
	if [ ! -e $DIRNAME ]; then
		die $ERR_NOTEXISTED "no directory: $DIRNAME, exit"
	fi
fi


# main options and cmd loop

xmsg "cmdloop: CMD:$# $*"
while [ $# -gt 0 ];
do
	OPTLOOP=$RET_TRUE
	xmsg "cmdloop: OPTLOOP:$OPTLOOP CMD:$# $*"

	# remove break at *
	case $1 in
	-h|--help)	usage; exit $ERR_USAGE;;
	-v|--verbose)	VERBOSE=`expr $VERBOSE + 1`;;
	-n|--noexec)	NOEXEC=$RET_TRUE;;
	-f|--force)	FORCE=`expr $FORCE + 1`;;
	-nd|--nodie)	NODIE=$RET_TRUE;;
	-ncp|--nocopy)	NOCOPY=$RET_TRUE;;
	-nc|--noclean)	NOCLEAN=$RET_TRUE;;
	-nofmk|--nofixmk)
			NOFIXMK=$RET_TRUE;;
	-ts|--timestamps)
			TIMESTAMPS=$RET_TRUE;;
	#-up)		ALLBINS="$ALLBINSUP";;
	-noavx)		CMKOPT="$CMKOPTNOAVX";;
	-avx)		CMKOPT="$CMKOPTAVX";;
	-avx2)		CMKOPT="$CMKOPTAVX2";;
	-qkk64)		CMKOPT2="-DLLAMA_QKK_64=ON";;
	-ione|-ioneapi|--intel|--intelone|--inteloneapi)
			INTELONEAPI=$RET_TRUE;;
	-sycl|--sycl)	SYCL=$RET_TRUE; INTELONEAPI=$RET_TRUE;;
	-lv|--level)	shift; DOLEVEL=$1;;
	-s|--seed)	shift; SEEDOPT=$1;;
	*)		OPTLOOP=$RET_FALSE;;
	esac

	# check no CMD
	if [ $OPTLOOP -eq $RET_TRUE ]; then
		shift
		xmsg "cmdloop: continue: CMD:$# $*"
		continue
	fi

	CMD="$1"
	xmsg "cmdloop: CMD:$CMD"

	# check intel
	msg "INTELONEAPI:$INTELONEAPI SYCL:$SYCL"
	if [ $INTELONEAPI -eq $RET_TRUE -a $ADDINTEL -eq $RET_FALSE ]; then
		chk_inteloneapi || die $? "can't use Intel oneAPI compiler, exit"
		CMKOPT2="$CMKOPT2 -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx"
		msg "updated CMKOPT2:$CMKOPT2"
		ADDINTEL=$RET_TRUE
	fi
	# sycl
	if [ $SYCL -eq $RET_TRUE -a $ADDSYCL -eq $RET_FALSE -a $ADDINTEL -eq $RET_TRUE ]; then
		cmd sycl-ls || die $? "can't use sycl-ls, exit"
		CMKOPT2="$CMKOPT2 -DLLAMA_SYCL=ON"
		msg "updated CMKOPT2:$CMKOPT2"
		ADDSYCL=$RET_TRUE
	fi
	msg "CMKOPT:$CMKOPT"
	msg "CMKOPT2:$CMKOPT2"

	DONECMD=$RET_FALSE

	case $CMD in
	*sync*)		done_cmd; do_sync; cd_buildpath; do_mk_script;;
	*sy*)		done_cmd; do_sync; cd_buildpath; do_mk_script;;
	*)		msg "no sync";;
	esac

	case $CMD in
	*copy*)		done_cmd; do_cp;;
	*cp*)		done_cmd; do_cp;;
	*)		msg "no copy";;
	esac

	case $CMD in
	*cmake*)	done_cmd; do_cmk;;
	*cmk*)		done_cmd; do_cmk;;
	*)		msg "no cmake";;
	esac

	case $CMD in
	*test*)		done_cmd; do_test;;
	*tst*)		done_cmd; do_test;;
	*)		msg "no make test";;
	esac

	case $CMD in
	*nm*)		done_cmd; do_main NOEXEC;;
	*nomain*)	done_cmd; do_main NOEXEC;;
	*mainonly*)	done_cmd; do_main NOMAKE;;
	*mainggufonly*)	done_cmd; do_main NOMAKE GGUF;;
	*ggufonly*)	done_cmd; do_main NOMAKE GGUF;;
	*gguf*)		done_cmd; do_main MAKE GGUF;;
	*main*)		done_cmd; do_main;;
	*)		msg "no make main";;
	esac

	case $CMD in
	*vicuna*)	done_cmd; do_vicuna;;
	vicuna)		done_cmd; do_vicuna;;
	esac
	case $CMD in
	*cyberagent*|*ca*)	done_cmd; do_cyberagent;;
	cyberagent|ca)		done_cmd; do_cyberagent;;
	esac
	case $CMD in
	*llama2[^c]*)	done_cmd; do_llama2;;
	llama2)		done_cmd; do_llama2;;
	esac
	case $CMD in
	*llama2chat*)	done_cmd; do_llama2chat;;
	llama2chat)	done_cmd; do_llama2chat;;
	esac
	case $CMD in
	*swallow*)	done_cmd; do_swallow;;
	swallow)	done_cmd; do_swallow;;
	esac
	case $CMD in
	*karasu*)	done_cmd; do_karasu;;
	karasu)		done_cmd; do_karasu;;
	esac
	case $CMD in
	*llama3[^c]*)	done_cmd; do_llama3;;
	llama3)		done_cmd; do_llama3;;
	esac
	case $CMD in
	*llama3inst*)	done_cmd; do_llama3inst;;
	llama3inst)	done_cmd; do_llama3inst;;
	esac
	case $CMD in
	*tllama[^23]*)	done_cmd; do_tinyllama11;;
	tllama)		done_cmd; do_tinyllama11;;
	*tinyllama[^23]*) done_cmd; do_tinyllama11;;
	tinyllama)	  done_cmd; do_tinyllama11;;
	esac
	case $CMD in
	*phi2*|*phi-2*)	done_cmd; do_phi2;;
	phi2|phi-2)	done_cmd; do_phi2;;
	esac
	case $CMD in
	*phi3*|*phi-3*)	done_cmd; do_phi3;;
	phi3|phi-3)	done_cmd; do_phi3;;
	esac
	case $CMD in
	*kujira*|*kujira7b*)	done_cmd; do_kujira;;
	kujira|kujira7b)	done_cmd; do_kujira;;
	esac

	case $CMD in
	*script*)	done_cmd; git_script;;
	*scr*)		done_cmd; git_script;;
	*)		msg "no git push script";;
	esac

	xmsg "DONECMD:$DONECMD"
	if [ $DONECMD -eq $RET_FALSE ]; then
		emsg "CMD:$CMD: unknown command, skip"
	fi

	shift
done


# end part

msg "# end"
get_datetime DTTM1
msg "# date time: $DTTM1"
msg "# done."

# duration
#update-katsu560-sdcpp.sh: # date: 20231229-064933
#update-katsu560-sdcpp.sh: # date: 20231229-145939
DTTMSEC=`diff_datetime $DTTM0 $DTTM1`

# summary
msg "# $MYNAME $ALLOPT"
msg "# date time of start: $DTTM0"
msg "# date time of end:   $DTTM1"
msg "# duration: $DTTMSEC sec"
msg "# output file(s):"
DTTMMIN=`expr $DTTMSEC + 59`
DTTMMIN=`expr $DTTMMIN / 60`
EXCLUDE='^'$BUILDPATH'/(CMakeFiles|Testing|common|examples|pocs|tests)/.*'
msg find $BUILDPATH -type f \( -cmin -$DTTMMIN -o -mmin -$DTTMMIN \) -regextype awk -not -regex $EXCLUDE -exec ls -l '{}' \;
find $BUILDPATH -type f \( -cmin -$DTTMMIN -o -mmin -$DTTMMIN \) -regextype awk -not -regex $EXCLUDE -exec ls -l '{}' \;

# end

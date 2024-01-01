#!/bin/sh

# update katsu560/llama.cpp
# T902 Intel(R) Core(TM) i5-3320M CPU @ 2.60GHz  2C/4T F16C,AVX IvyBridge/3rd Gen.
# AH   Intel(R) Core(TM) i3-10110U CPU @ 2.10GHz  2C/4T F16C,AVX,AVX2,FMA CometLake/10th Gen.

MYNAME=update-katsu560-llamacpp.sh

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

# set unique return code from 100
ERR_NOTOPDIR=100	# no topdir
ERR_NOBUILDDIR=101	# no build dir
ERR_NOUSB=102		# no USB found


### flags
VERBOSE=0		# -v --verbose flag, -v -v means more verbose
NOEXEC=$RET_FALSE	# -n --noexec flag
FORCE=$RET_FALSE	# -f --force flag
NODIE=$RET_FALSE	# -nd --nodie
NOCOPY=$RET_FALSE	# -ncp --nocopy
NOTHING=

LEVELMIN=1
LEVELSTD=3
LEVELMAX=5
DOLEVEL=$LEVELSTD

### date time
DTTMSHSTART=


###
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
# https://qiita.com/PruneMazui/items/8a023347772620025ad6
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
ESC=$(printf '\033')
ESCRESET="${ESC}[0m"
ESCBOLD="${ESC}[1m"
ESCFAINT="${ESC}[2m"
ESCITALIC="${ESC}[3m"
ESCUL="${ESC}[4m"       # underline
ESCBLINK="${ESC}[5m"    # slow blink
ESCRBLINK="${ESC}[6m"   # rapid blink
ESCREVERSE="${ESC}[7m"
ESCCONCEAL="${ESC}[8m"
ESCDELETED="${ESC}[9m"  # crossed-out
ESCBOLDOFF="${ESC}[22m" # bold off, faint off
ESCITALICOFF="${ESC}[23m"  # italic off
ESCULOFF="${ESC}[24m"   # underline off
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

# func:func_test_show ver:2023.12.30
# show FUNCTEST_OK, FUNCTEST_NG
# func_test_reset
func_test_show()
{
	if [ $FUNCTEST_NG -eq 0 ]; then
		msg "${ESCOK}func_test_show: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG${ESCBACK}"
	else
		msg "${ESCERR}func_test_show: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG${ESCBACK}"
	fi
}

# func:func_test ver:2023.12.30
# check return code of func test with OKCODE and output message for test code
# func_test OKCODE "messages"
func_test()
{
	RETCODE=$?

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
	msg "----"
}

# func:set_ret ver:2023.12.23
# set $? as return code for test code
# set_ret RETCODE
set_ret()
{
	return $1
}

# func:chk_level ver: 2023.12.31
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
	CHK=`echo $LEVEL | awk '!/[1-5]/ { print "BADVALUE"; exit } { print $0 }'`
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
		xmsg "${ESCWARN}chk_level: skip $*${ESCBACK}"
		RETCODE=$RET_OK
	fi

	xxmsg "chk_level: RETCODE:$RETCODE"
	return $RETCODE
}
test_chk_level_func()
{
	msg "${ESCOK}test_chk_level_func: $*${ESCBACK}"
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

# func:chk_and_cp ver:2023.12.30
# do cp with cp option and check source file(s) and dir(s) to file or dir
# chk_and_cp CPOPT SRCFILE SRCDIR ... DSTPATH
chk_and_cp()
{
	local chkfiles cpopt narg argfiles dstpath ncp cpfiles i

	#xmsg "----"
	#xmsg "chk_and_cp: VERBOSE:$VERBOSE NOEXEC:$NOEXEC NOCOPY:$NOCOPY"
	#xmsg "chk_and_cp: $*"
	#xmsg "chk_and_cp: nargs:$# args:$*"
	if [ $# -eq 0 ]; then
		emsg "chk_and_cp: ARG:$*: no cpopt, chkfiles"
		return $ERR_NOARG
	fi

	# get cp opt
	cpopt=$1
	shift
	#xmsg "chk_and_cp: narg:$# args:$*"

	if [ $# -le 1 ]; then
		emsg "chk_and_cp: CPOPT:$cpopt ARG:$*: bad arg, not enough"
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

	xmsg "chk_and_cp: cpopt:$cpopt ncp:$ncp cpfiles:$cpfiles dstpath:$dstpath"
	if [ x"$cpfiles" = x ]; then
		emsg "chk_and_cp: bad arg, no cpfiles"
		return $ERR_BADARG
	fi

	if [ x"$dstpath" = x ]; then
		emsg "chk_and_cp: bad arg, no dstpath$"
		return $ERR_BADARG
	fi

	if [ $ncp -eq 1 ]; then
		emsg "chk_and_cp: bad arg, only 1 parameter:$cpfiles $dstpath"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			return $ERR_BADARG
		else
			msg "${ESC_WARN}NOEXEC, return $RET_OK${ESC_BACK}"
			return $RET_OK
		fi
	elif [ $ncp -eq 2 ]; then
		if [ -f $cpfiles -a ! -e $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -f $dstpath -a $cpfiles = $dstpath ]; then
			emsg "chk_and_cp: bad arg, same file"
			return $ERR_BADARG
		elif [ -d $cpfiles -a -f $dstpath ]; then
			emsg "chk_and_cp: bad arg, dir to file"
			return $ERR_BADARG
		elif [ -f $cpfiles -a -f $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -d $dstpath ]; then
			nothing
		fi
	elif [ ! -e $dstpath ]; then
		emsg "chk_and_cp: dstpath:$dstpath: not existed"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			return $ERR_NOTEXISTED
		else
			msg "${ESC_WARN}NOEXEC, return $RET_OK${ESC_BACK}"
			return $RET_OK
		fi
	elif [ ! -d $dstpath ]; then
		emsg "chk_and_cp: not dir"
		return $ERR_NOTDIR
	fi

	if [ $NOEXEC -eq $RET_FALSE -a $NOCOPY -eq $RET_FALSE ]; then
		msg "cp $cpopt $cpfiles $dstpath"
		cp $cpopt $cpfiles $dstpath || return $?
	else
		msg "${ESCWARN}noexec: cp $cpopt $cpfiles $dstpath${ESCBACK}"
	fi

	return $RET_OK
}

# chk_and_cp test code
test_chk_and_cp()
{
	# test files and dir, test-no.$$, testdir-no.$$: not existed
	touch test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$
	rm test-no.$$
	mkdir testdir.$$
	rmdir testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: create test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"
	func_test_reset

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

	# reset test env
	func_test_show
	rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$
	rm -rf testdir.$$ testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"
}
#msg "test_chk_and_cp"; VERBOSE=2; test_chk_and_cp; exit 0

# func:get_latestdatefile ver: 2023.12.30
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
	msg "ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
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

# func:get_datefile_file ver: 2023.12.30
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
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
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
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_datefile_file"; VERBOSE=2; test_get_datefile_file; exit 0

# func:find_latest ver: 2023.12.31
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

	xmsg "find . -maxdepth 1 -type f -cmin -$DTTMMIN -mmin -$DTTMMIN -exec ls -l '{}' \;"
	find . -maxdepth 1 -type f -cmin -$DTTMMIN -mmin -$DTTMMIN -exec ls -l '{}' \;
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
TOPDIR=llama.cpp
BASEDIR=~/github/$TOPDIR
BUILDPATH="$BASEDIR/$TOPDIR/build"
# script
SCRIPT=script
FIXBASE="fix"
SCRIPTNAME=llamacpp
UPDATENAME=update-katsu560-${SCRIPTNAME}.sh
FIXSHNAME=${FIXBASE}[0-9][0-9][01][0-9][0-3][0-9].sh
MKZIPNAME=mkzip-${SCRIPTNAME}.sh

# cmake
# check OpenBLAS
BLASCMKLIST="$TOPDIR/CMakeLists.txt"
if [ ! -f $BLASCMKLIST ]; then
	die $ERR_NOTEXISTED "not existed: BLASCMKLIST:$BLASCMKLIST, exit"
fi
OPENBLAS=`grep -sr LLAMA_OPENBLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*LLAMA_OPENBLAS.*/LLAMA_OPENBLAS/'`
BLAS=`grep -sr LLAMA_BLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*LLAMA_BLAS.*/LLAMA_BLAS/'`
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

CMKCOMMON="-DLLAMA_STANDALONE=ON -DLLAMA_BUILD_TESTS=ON -DLLAMA_BUILD_EXAMPLES=ON"
CMKOPTNOAVX="-DLLAMA_AVX=OFF -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=OFF $CMKOPTBLAS $CMKCOMMON"
CMKOPTAVX="-DLLAMA_AVX=ON -DLLAMA_AVX2=OFF -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=OFF -DLLAMA_F16C=ON $CMKOPTBLAS $CMKCOMMON"
CMKOPTAVX2="-DLLAMA_AVX=ON -DLLAMA_AVX2=ON -DLLAMA_AVX512=OFF -DLLAMA_AVX512_VBMI=OFF -DLLAMA_AVX512_VNNI=OFF -DLLAMA_FMA=ON -DLLAMA_F16C=ON $CMKOPTBLAS $CMKCOMMON"
CMKOPTNONE="$CMKOPTBLAS $CMKCOMMON"
CMKOPT="$CMKOPTNONE"
CMKOPT2=""
#msg "CMKOPTBLAS:$CMKOPTBLAS CMKOPT:$CMKOPT CMKOPT2:$CMKOPT2"; exit 0

# targets
NOTGT="gguf libllava.a benchmark-matmult tests/test-c.o"
NOTEST="test-double-float test-opt"
TARGETS=
TESTS=

get_targets()
{
        if [ ! -e $BASEDIR/$TOPDIR/Makefile ]; then
                msg "no $BASEDIR/$TOPDIR/Makefile"
                return $ERR_NOTEXISTED
        fi

        msg "NOTGTS: $NOTGT"
        TARGETS=`awk -v NOTGT0="$NOTGT" '
	BEGIN { ST=0; split(NOTGT0,NOTGT); }
	function is_notgt(tgt) {
       		for(i in NOTGT) { if (NOTGT[i]==tgt) return 1; continue }
       		return 0;
	}
	ST==1 && /^$/ { ST=2 }
	ST==1 && !/^$/ { T=$0; sub(/[\r\n]$/,"",T); sub(/^[ ]*/,"",T); sub(/\\\/,"",T); split(T,TGT0); for(I in TGT0) { if (is_notgt(TGT0[I])==0) { printf("%s ",TGT0[I]) } } }
	ST==0 && /^BUILD_TARGETS = / { ST=1 }
	' $BASEDIR/$TOPDIR/Makefile`
        msg "TARGETS: $TARGETS"

        msg "NOTEST: $NOTEST"
        TESTS=`awk -v NOTGT0="$NOTEST" '
	BEGIN { ST=0; split(NOTGT0,NOTGT); }
	function is_notgt(tgt) {
       		for(i in NOTGT) { if (NOTGT[i]==tgt) return 1; continue }
       		return 0;
	}
	ST==1 && /^$/ { ST=2 }
	ST==1 && !/^$/ { T=$0; sub(/[\r\n]$/,"",T); sub(/^[ ]*/,"",T); sub(/\\\/,"",T); gsub(/tests\//,"",T); split(T,TGT0); for(I in TGT0) { if (is_notgt(TGT0[I])==0) { printf("%s ",TGT0[I]) } } }
	ST==0 && /^TEST_TARGETS = / { ST=1 }
	' $BASEDIR/$TOPDIR/Makefile`
        msg "TESTS: $TESTS"

        return $RET_OK
}
#get_targets; exit 0

# for test, main, examples execution
TESTENV="GGML_NLOOP=1 GGML_NTHREADS=4"

PROMPT="Building a website can be done in 10 simple steps:"
PROMPTCHAT="Tell me about FIFA worldcup 2022 Qatar. What country win the match?"
PROMPTJP="日本語で回答ください。京都について教えてください"
SEEDOPT=1681527203
MAINOPT="--log-disable"

MKCLEAN=$RET_FALSE
NOCLEAN=$RET_FALSE

###
usage()
{
	echo "usage: $MYNAME [-h][-v][-n][-nd][-ncp][-nc][-noavx|avx|avx2][-qkk64][-lv LEVEL][-s SEED] dirname branch cmd"
	echo "options: (default)"
	echo "  -h|--help ... this message"
	echo "  -v|--verbose ... increase verbose message level"
	echo "  -n|--noexec ... no execution, test mode (FALSE)"
	echo "  -nd|--nodie ... no die (FALSE)"
	echo "  -ncp|--nocopy ... no copy (FALSE)"
	echo "  -nc|--noclean ... no make clean (FALSE)"
	#echo "  -up ... upstream, no mod source, skip benchmark-matmult"
	echo "  -noavx|-avx|-avx2 ... set cmake option for no AVX, AVX, AVX2 (AVX)"
	echo "  -qkk64 ... add cmake option for QKK_64"
	echo "  -lv|--level LEVEL ... set execution level as LEVEL, min. 1 .. max. 5 ($DOLEVEL)"
	echo "  -s|--seed SEED ... set SEED ($SEED)"
	echo "  dirname ... directory name ex. 0407up"
	echo "  branch ... git branch ex. master, gq, devpr"
	echo "  cmd ... sycpcmktstmain sy/sync,cp/copy,cmk/cmake,tst/test,main"
	echo "  cmd ... sycpcmktstnm sy,cp,cmk,tst,nm  nm .. build main but no exec"
	echo "  cmd ... mainonly .. main execution only"
	echo "  cmd ... ggufonly .. main execution w/ gguf models only"
	echo "  cmd ... script .. push $UPDATENAME $MKZIPNAME $FIXSHNAME to remote"
}
# default -avx
CMKOPT="$CMKOPTAVX"

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
	-lv|--level)	shift; DOLEVEL=$1;;
	-qkk64)		CMKOPT2="-DLLAMA_QKK_64=ON";;
	-s|--seed)	shift; SEEDOPT=$1;;
	*)		OPTLOOP=$RET_FALSE; break;;
	esac
	shift
done

# default -avx|AVX
if [ x"$CMKOPT" = x"" ]; then
	CMKOPT="$CMKOPTAVX"
fi
CMKOPT="$CMKOPT $CMKOPT2"

DIRNAME="$1"
BRANCH="$2"
CMD="$3"

xmsg "VERBOSE:$VERBOSE NOEXEC:$NOEXEC NODIE:$NODIE NOCOPY:$NOCOPY"
xmsg "NOCLEAN:$NOCLEAN LEVEL:$DOLEVEL SEED:$SEEDOPT"

###
do_sync()
{
	# in build

	msg "# synchronizing ..."
        msg "git branch"
        git branch
        msg "git checkout $BRANCH"
	if [ $NOEXEC -eq $RET_FALSE ]; then
	        git checkout $BRANCH
	fi
        msg "git fetch"
	if [ $NOEXEC -eq $RET_FALSE ]; then
	        git fetch
	fi
        msg "git reset --hard origin/master"
	if [ $NOEXEC -eq $RET_FALSE ]; then
	        git reset --hard origin/master
	fi
}

# func:cp_mk_script ver: 2024.01.01
# do script(FIXBASEmmdd.sh mk) for create script
# cp_mk_script
do_mk_script()
{
	# in build

	# update fixsh in BASEDIR and save update files
	msg "# creating FIXSH ..."

	local DTNOW DFFIXSH FFIXSH DFIXSH

	DTNOW=`date '+%y%m%d'`
	msg "DTNOW:$DTNOW"


	# to BASEDIR
	msg "cd $BASEDIR"
	cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}*"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			ls -ltr ${FIXSHNAME}*
		fi
	fi
	DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
	DFIXSH=`get_datefile_date ymd $DFFIXSH`
	FFIXSH=`get_datefile_file $DFFIXSH`
	msg "FIXSH:$FFIXSH"

	# check
	if [ ! x$DTNOW = x"$DFIXSH" ]; then
		msg "sh $FFIXSH mk"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			sh $FFIXSH mk
			if [ ! $? -eq $RET_OK ]; then
				die $? "RETCODE:$?: can't make ${FIXBASE}${DTNOW}.sh, exit"
			fi
			if [ ! -s $FFIXSH ]; then
				rm -f $FFIXSH
				die $ERR_CANTCREATE "size zero, can't create ${FIXBASE}${DTNOW}.sh, exit"				
			fi

			DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
			FFIXSH=`get_datefile_file $DFFIXSH`
			msg "$FFIXSH: created"
			msg "$ ls -l $FFIXSH"
			ls -l $FFIXSH
		fi
	else
		msg "$FFIXSH: already existed, skip"	
	fi

	# back to BUILDPATH
	msg "cd $BUILDPATH"
	cd $BUILDPATH
}

do_cp()
{
	# in build

	msg "# copying ..."
	chk_and_cp -p ../ggml.[ch] ../k_quants.[ch] ../ggml-alloc.h ../ggml-alloc.c ../ggml-opencl.h ../ggml-opencl.cpp ../llama.cpp ../llama.h ../llama-*.h ../CMakeLists.txt ../Makefile $DIRNAME || die 201 "can't copy files"
	chk_and_cp -pr ../examples $DIRNAME || die 202 "can't copy examples files"
	chk_and_cp -pr ../tests $DIRNAME || die 203 "can't copy tests files"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		find $DIRNAME -name '*.[0-9][0-9][01][0-9][0-3][0-9]*' -exec rm {} \;
	fi
}

do_cmk()
{
	# in build

	msg "# do cmake"
	if [ -f CMakeCache.txt ]; then
		msg "rm CMakeCache.txt"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			rm CMakeCache.txt
		fi
	fi
	msg "cmake .. $CMKOPT"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cmake .. $CMKOPT || die 231 "cmake failed"
	fi
	chk_and_cp -p Makefile $DIRNAME/Makefile.build

	# update targets
	msg "get_targets"
	get_targets
}

do_test()
{
	# in build

	msg "# testing ..."
	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 241 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi
	# update targets
	msg "get_targets"
	get_targets

	msg "make $TESTS"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		make $TESTS || die 242 "make test build failed"
	fi

	msg "env $TESTENV make test"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		env $TESTENV make test || die 243 "make test failed"
	fi
	msg "mv bin/test* $DIRNAME/"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		mv bin/test* $DIRNAME || die 244 "can't move tests"
	fi
}

CPSCRIPTFILES=
# func:cp_script ver: 2024.01.01
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
	msg "cp -p \"$SRC\" \"$DSTDT\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DSTDT"
	fi
	msg "cp -p \"$SRC\" \"$DST\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DST"
	fi
	CPSCRIPTFILES="$DSTDT $DST"
}
test_cp_script()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	# set test env
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
	func_test_reset

	# test code
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

	# reset test env
	func_test_show
	msg "rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
	rmdir $TMPDIR1
	msg "ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
}
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_TRUE; test_cp_script; exit 0
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_FALSE; test_cp_script; exit 0

# func:git_script ver: 2024.01.01
# git push scripts, UPDATENAME, FIXSHNAME, MKZIPNAME
# git_script
git_script()
{
	# in build

	msg "# git push scripts ..."

	local DT0 ADDFILES COMMITFILES
	local DFUPDATE DFFIXSH DFMKZIP FUPDATE FFIXSH FMKZIP
	local DFUPDATEG DFFIXSHG DFMKZIPG FUPDATEG FFIXSHG FMKZIPG


	DT0=`date '+%y%m%d'`
	msg "DT0:$DT0"

	ADDFILES=""
	COMMITFILES=""

	# to BASEDIR
	msg "cd $BASEDIR"
	cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
		fi
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

	# to TOPDIR
	# move to git SCRIPT branch and sync

	msg "cd $BASEDIR/$TOPDIR"
	cd $BASEDIR/$TOPDIR
	msg "git branch"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git branch
	fi
	msg "git checkout $SCRIPT"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git checkout $SCRIPT
	fi

	# avoid error: pathspec 'fix1202.sh' did not match any file(s) known to git.
	# avoid  ! [rejected]        script -> script (non-fast-forward)  error: failed to push some refs to 'https://ghp_ ...
	# https://docs.github.com/ja/get-started/using-git/dealing-with-non-fast-forward-errors
	msg "git pull origin $SCRIPT"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git pull origin $SCRIPT
	fi

#        msg "git fetch"
#	if [ $NOEXEC -eq $RET_FALSE ]; then
#	        git fetch
#	fi
#        msg "git reset --hard origin/master"
#	if [ $NOEXEC -eq $RET_FALSE ]; then
#	        git reset --hard origin/master
#	fi

	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
		fi
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
			msg "Nnew: copy: $BASEDIR/$FUPDATE $FUPDATEG"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp_script $BASEDIR/$FUPDATE $FUPDATEG
				#find_latest DTTMSHSTART
				#ADDFILES="$ADDFILES $FUPDATEG"
				#COMMITFILES="$COMMITFILES $FUPDATEG"
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
				if [ $? -eq $RET_OK ]; then
					msg "same: no copy: $BASEDIR/$FUPDATE $FUPDATEG"
				else
					msg "diff: copy: $BASEDIR/$FUPDATE $FUPDATEG"
					cp_script $BASEDIR/$FUPDATE $FUPDATEG
					#find_latest DTTMSHSTART
					#ADDFILES="$ADDFILES $FUPDATEG"
					#COMMITFILES="$COMMITFILES $FUPDATEG"
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
				#find_latest DTTMSHSTART
				ADDFILES="$ADDFILES $FFIXSH"
				COMMITFILES="$COMMITFILES $FFIXSH"
			fi
		elif [ ! $FFIXSH = $FFIXSHG ]; then
			# always copy
			msg "always: copy: $BASEDIR/$FFIXSH $FFIXSH"
			msg "cp -p $BASEDIR/$FFIXSH $FFIXSH"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp -p $BASEDIR/$FFIXSH $FFIXSH
				#find_latest DTTMSHSTART
				ADDFILES="$ADDFILES $FFIXSH"
				COMMITFILES="$COMMITFILES $FFIXSH"
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
				if [ $? -eq $RET_OK ]; then
					msg "same: no copy: $BASEDIR/$FFIXSH $FFIXSHG"
				else
					msg "diff: copy: $BASEDIR/$FFIXSH $FFIXSHG"
					cp_script $BASEDIR/$FFIXSH $FFIXSHG
					#find_latest DTTMSHSTART
					#ADDFILES="$ADDFILES $FFIXSHG"
					#COMMITFILES="$COMMITFILES $FFIXSHG"
					ADDFILES="$ADDFILES $CPSCRIPTFILES"
					COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
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
			find_latest DTTMSHSTART
			#ADDFILES="$ADDFILES $FMKZIPG"
			#COMMITFILES="$COMMITFILES $FMKZIPG"
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
				if [ $? -eq $RET_OK ]; then
					msg "same: no copy: $BASEDIR/$FMKZIP $FMKZIPG"
				else
					msg "diff: copy: $BASEDIR/$FMKZIP $FMKZIPG"
					cp_script $BASEDIR/$FMKZIP $FMKZIPG
					find_latest DTTMSHSTART
					#ADDFILES="$ADDFILES $FMKZIPG"
					#COMMITFILES="$COMMITFILES $FMKZIPG"
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
			msg "git add $ADDFILES"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				git add $ADDFILES
			fi
		fi
		msg "git commit -m \"update scripts\" $COMMITFILES"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			git commit -m "update scripts" $COMMITFILES
		fi
		msg "git status"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			git status
		fi
		msg "git push origin $SCRIPT"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			git push origin $SCRIPT
		fi
	fi

	# back
	msg "git checkout $BRANCH"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git checkout $BRANCH
	fi

	# back to BUILDPATH
	msg "cd $BUILDPATH"
	cd $BUILDPATH
}
#msg "do_script"; NOEXEC=$RET_TRUE; VERBOSE=2; do_script; exit 0

# do_bin DOBIN MODEL VARPROMPT DOOPT
# do_bin DOBIN MODEL WAVFILE DOOPT
do_bin()
{
	local DOBIN MODEL VARPROMPT DOOPT RETCODE DT WAVFILE SEED PROMPTTXT

	if [ x"$1" = x ]; then
		emsg "do_bin: need DOBIN, MODEL, VARPROMPT skip"
		return $ERR_BADARG
	fi
	DOBIN="$1"
	MODEL="$2"
	VARPROMPT="$3"
	shift 3
	DOOPT="$*"

	RETCODE=$RET_OK

	DT=`date '+%y%m%d'`

	#msg "./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
	#./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p "$PROMPT"
	if [ x"$DOBIN" = x"whisper" ]; then
		WAVFILE=`eval echo '$'${VARPROMPT}`
		msg "./$DIRNAME/$DOBIN -m $MODEL $DOOPT -f $WAVFILE"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/$DOBIN -m $MODEL $DOOPT -f $WAVFILE
			RETCODE=$?
			if [ ! $RETCODE -eq $RET_OK ]; then
				emsg "do $DOBIN failed"
			fi
		fi
	else
		SEED=$SEEDOPT
		PROMPTTXT=`eval echo '$'${VARPROMPT}`

		msg "./$DIRNAME/$DOBIN -m $MODEL $DOOPT -s $SEED -p \"$PROMPTTXT\""
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/$DOBIN -m $MODEL $DOOPT -s $SEED -p "$PROMPTTXT"
			RETCODE=$?
			if [ ! $RETCODE -eq $RET_OK ]; then
				emsg "do $DOBIN failed"
			fi
		fi
	fi

	return $RETCODE
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
			if [ $NOEXEC -eq $RET_FALSE ]; then
				make clean || die 251 "make clean failed"
				MKCLEAN=$RET_TRUE
			fi
		fi
		msg "get_targets"
		get_targets
		msg "make $TARGETS"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make $TARGETS || die 252 "make main failed"
		fi
		BINS=""; for i in $TARGETS ;do BINS="$BINS bin/$i" ;done
		chk_and_cp -p $BINS $DIRNAME || die 253 "can't cp main"
	fi

	# main
	if [ ! x"$DOMAINOPT" = xNOEXEC ]; then
		if [ -f ./$DIRNAME/main -a ! x"$SUBOPT" = xGGUF ]; then
			#msg "./$DIRNAME/main -m ../models/ggml-alpaca-7b-q4.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			chk_level $LEVELMIN do_bin main ../models/ggml-alpaca-7b-q4.bin PROMPT "-n 512 $MAINOPT"

			#
			#msg "./$DIRNAME/main -m ../models/ggml-vic7b-q4_0.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			chk_level $LEVELMIN do_bin main ../models/ggml-vic7b-q4_0.bin PROMPT "-n 512 $MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/ggml-vic7b-q4_1.bin PROMPT "-n 512 $MAINOPT"
			chk_level $LEVELMIN do_bin main ../models/ggml-vic7b-q4_0-new.bin PROMPT "-n 512 $MAINOPT"
			#
			#msg "./$DIRNAME/main -m ../models/WizardLM-7B-uncensored.ggml.q4_0.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			chk_level $LEVELMIN do_bin main ../models/WizardLM-7B-uncensored.ggml.q4_0.bin PROMPT "-n 512 $MAINOPT"
			chk_level $LEVELSTD do_bin main ../models/WizardLM-7B-uncensored.ggml.q5_0.bin PROMPT "-n 512 $MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/WizardLM-7B-uncensored.ggml.q5_1.bin PROMPT "-n 512 $MAINOPT"

			#msg "./$DIRNAME/main -m ../models/Wizard-Vicuna-13B-Uncensored.ggml.q4_0.bin -n 512 $MAINOPT -s $SEED -p \"$PROMPT\""
			chk_level $LEVELMIN do_bin main ../models/Wizard-Vicuna-13B-Uncensored.ggml.q4_0.bin PROMPT "-n 512 $MAINOPT"

			# vicuna 1.1 2023.6
			#msg "./$DIRNAME/main -m ../models/vicuna-7b-1.1.ggmlv3.q2_K.bin $MAINOPT $OPT -s $SEED -p \"$PROMPT\""
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q2_K.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q3_K_L.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELSTD do_bin main ../models/vicuna-7b-1.1.ggmlv3.q3_K_M.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q3_K_S.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q4_0.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q4_1.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMIN do_bin main ../models/vicuna-7b-1.1.ggmlv3.q4_K_M.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q4_K_S.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q5_0.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q5_1.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELSTD do_bin main ../models/vicuna-7b-1.1.ggmlv3.q5_K_M.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q5_K_S.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMAX do_bin main ../models/vicuna-7b-1.1.ggmlv3.q6_K.bin PROMPT "$MAINOPT $OPT"
			chk_level $LEVELMIN do_bin main ../models/vicuna-7b-1.1.ggmlv3.q8_0.bin PROMPT "$MAINOPT $OPT"

			#
			#msg "./$DIRNAME/main -m ../models/7B/ggml-model-f32.bin $MAINOPT -p \"$PROMPT\""
			chk_level $LEVELMAX do_bin main ../models/7B/ggml-model-f32.bin PROMPT "$MAINOPT"
			chk_level $LEVELMIN do_bin main ../models/7B/ggml-model-q4_0.bin PROMPT "$MAINOPT"

		elif [ -f ./$DIRNAME/main ]; then
			# gguf since 2023.8
			#msg "./$DIRNAME/main -m ../models/llama-2-7b.Q2_K.gguf $MAINOPT -s $SEED -p \"$PROMPT\""
			chk_level $LEVELSTD do_bin main ../models/llama-2-7b.Q2_K.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b.Q3_K_S.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b.Q4_0.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMIN do_bin main ../models/llama-2-7b.Q4_K_M.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b.Q5_0.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b.Q5_K_S.gguf PROMPT "$MAINOPT"
			chk_level $LEVELSTD do_bin main ../models/llama-2-7b.Q5_K_M.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b.Q6_0.gguf PROMPT "$MAINOPT"
			chk_level $LEVELMIN do_bin main ../models/llama-2-7b.Q8_0.gguf PROMPT "$MAINOPT"
			#
			#msg "./$DIRNAME/main -m ../models/llama-2-7b-chat.Q2_K.gguf $MAINOPT -s $SEED -p \"$PROMPTCHAT\""
			chk_level $LEVELSTD do_bin main ../models/llama-2-7b-chat.Q2_K.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMIN do_bin main ../models/llama-2-7b-chat.Q4_K_M.gguf PROMPTCHAT "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b-chat.Q6_K.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b-chat.Q3_K_S.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELSTD do_bin main ../models/llama-2-7b-chat.Q3_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMAX do_bin main ../models/llama-2-7b-chat.Q5_K_M.gguf PROMPTJP "$MAINOPT"
			chk_level $LEVELMIN do_bin main ../models/llama-2-7b-chat.Q8_0.gguf PROMPTJP "$MAINOPT"
		else
			msg "no ./$DIRNAME/main, skip executing main"
		fi

		msg "./$DIRNAME/quantize"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/quantize
		fi
		msg "./$DIRNAME/quantize-stats"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/quantize-stats
		fi
		msg "./$DIRNAME/perplexity"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/perplexity
		fi
		msg "./$DIRNAME/embedding"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/embedding
		fi
		if [ -f ./$DIRNAME/benchmark-matmult ]; then
			msg "./$DIRNAME/benchmark-matmult"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				./$DIRNAME/benchmark-matmult
			fi
		fi
	else
		msg "skip executing main, tests and others"
	fi
}


###
msg "# start"
get_datetime DTTM0
msg "# date time: $DTTM0"

# warning:  Clock skew detected.  Your build may be incomplete.
msg "sudo ntpdate ntp.nict.jp"
sudo ntpdate ntp.nict.jp

# check
if [ $NOEXEC -eq $RET_FALSE ]; then
	if [ ! -d $TOPDIR ]; then
		die $ERR_NOTOPDIR "# can't find $TOPDIR, exit"
	fi
else
	msg "skip check $TOPDIR"
fi
if [ ! -d $BUILDPATH ]; then
	msg "mkdir -p $BUILDPATH"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		mkdir -p $BUILDPATH
		if [ ! -d $BUILDPATH ]; then
			die $ERR_NOBUILDDIR "# can't find $BUILDPATH, exit"
		fi
	fi
fi

msg "cd $BUILDPATH"
cd $BUILDPATH

msg "git branch"
if [ $NOEXEC -eq $RET_FALSE ]; then
	git branch
fi
msg "git checkout $BRANCH"
if [ $NOEXEC -eq $RET_FALSE ]; then
	git checkout $BRANCH
fi

msg "mkdir $DIRNAME"
if [ $NOEXEC -eq $RET_FALSE ]; then
	mkdir $DIRNAME
	if [ ! -e $DIRNAME ]; then
		die $ERR_NOTEXISTED "no directory: $DIRNAME, exit"
	fi
fi

case $CMD in
*sy*)		do_sync; do_mk_script;;
*sync*)		do_sync; do_mk_script;;
*)		msg "no sync";;
esac

case $CMD in
*cp*)		do_cp;;
*copy*)		do_cp;;
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
*gguf*)		do_main MAKE GGUF;;
*main*)		do_main;;
*)		msg "no make main";;
esac

case $CMD in
*script*)	git_script;;
*scr*)		git_script;;
*)		msg "no git push script";;
esac

# end
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
find $BUILDPATH -type f -cmin -$DTTMMIN -exec ls -l '{}' \;

# end
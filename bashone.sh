#!/bin/bash

# set constants
DEBUG=0
HOST='www.bigonezh.com'
MARKET='BTC-USDT'
PERIOD='day1'
LIMIT='36'
LINE='15'
MID_LINE='6'
PRICE_SCALE=''

COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_GREY='\033[37m'
NO_COLOR='\033[0m'
FONT_STRONG='\033[1m'
PRICE_UP_RECT="${COLOR_GREEN}█${NO_COLOR}"
PRICE_UP_RECT_TOP="${COLOR_GREEN}▀${NO_COLOR}"
PRICE_UP_RECT_BOTTOM="${COLOR_GREEN}▄${NO_COLOR}"
PRICE_DOWN_RECT="${COLOR_RED}█${NO_COLOR}"
PRICE_DOWN_RECT_TOP="${COLOR_RED}▀${NO_COLOR}"
PRICE_DOWN_RECT_BOTTOM="${COLOR_RED}▄${NO_COLOR}"
EMPTY_STR="${NO_COLOR} ${NO_COLOR}"

X_LINE="${COLOR_GREY}━${NO_COLOR}"
X_INDICATOR="${COLOR_GREY}┳${NO_COLOR}"
X_INDICATOR_SCALE='7'
Y_LINE="${COLOR_GREY}┃${NO_COLOR}"
Y_INDICATOR="${COLOR_GREY}┫${NO_COLOR}"
XY_CORNER="${COLOR_GREY}┗${NO_COLOR}"

PADDING_LEFT_SAPCE='4'
BASE_PADDING_LEFT_SAPCE=''
for i in $(seq 1 ${PADDING_LEFT_SAPCE}); do
    BASE_PADDING_LEFT_SAPCE+=${EMPTY_STR}
done
TICKER_SPACE='5'

LAST_PRICE_STR='Last Price'
H24_CHANGE_STR='24h Change'
H24_HIGH_STR='24h High'
H24_LOW_STR='24h Low'
H24_VOLUME_STR='24h Volume'

function log() {
    if [ ${DEBUG} = 1 ]; then
        echo ""
        echo $1
    fi
}

c_candle_open=""
c_candle_high=""
c_candle_low=""
c_candle_close=""
c_candle_change=""
c_candle_day_month=""
candle_arr=()

function getCurrentCandleData() {
    candle_data=(${candle_arr[$1]})
    c_candle_open=${candle_data[0]}
    c_candle_high=${candle_data[1]}
    c_candle_low=${candle_data[2]}
    c_candle_close=${candle_data[3]}
    c_candle_change=${candle_data[4]}
    c_candle_day_month=${candle_data[5]}
}

if [ -n "$1" ]; then
    MARKET=$1
fi
# feth asset info
api_result=$(curl -s "https://${HOST}/api/v3/asset_pairs")
log ${api_result}
if [[ ${api_result} != {\"code\":0* ]]; then
    echo -e "${COLOR_RED}fetch asset info error${NO_COLOR}"
    exit
fi
# parse quote scale
api_result=${api_result#*${MARKET}\",\"quote_scale\":}
PRICE_SCALE=${api_result%%,*}
log "price scale: ${PRICE_SCALE}"
# ticker
ticker_result=''
function drawTickerData() {
    # fetch ticker
    api_result=$(curl -s "https://${HOST}/api/v3/asset_pairs/${MARKET}/ticker")
    log ${api_result}
    if [[ ${api_result} != {\"code\":0* ]]; then
        return 1
    fi
    # parse ticker data
    _daily_change_percent=''
    _day_high_price=''
    _day_low_price=''
    _day_close_price=''
    _day_volume=''
    if [[ ${api_result} == {\"code\":0* ]]; then
        _day_high_price=${api_result#*high\":\"}
        _day_high_price=${_day_high_price%%\",*}
        _day_low_price=${api_result#*low\":\"}
        _day_low_price=${_day_low_price%%\",*}
        _day_volume=${api_result#*volume\":\"}
        _day_volume=${_day_volume%%\",*}
        _day_close_price=${api_result#*close\":\"}
        _day_close_price=${_day_close_price%%\",*}
        _open_price=${api_result#*open\":\"}
        _open_price=${_open_price%%\",*}
        _daily_change=${api_result#*daily_change\":\"}
        _daily_change=${_daily_change%%\"*}
        _daily_change_percent=$(echo "scale=8;${_daily_change} / ${_open_price} * 100" | bc)
        _daily_change_percent=$(echo "scale=2;${_daily_change_percent} / 1" | bc)
        if [[ ${_daily_change_percent} == .* ]] || [[ ${_daily_change_percent} == -.* ]]; then
            _daily_change_percent=${_daily_change_percent/./0.}
        fi
        if [[ ${_daily_change_percent} != -* ]]; then
            _daily_change_percent="+${_daily_change_percent}"
        fi
        _daily_change_percent+='%'
    fi
    # draw ticker
    ticker_result=${BASE_PADDING_LEFT_SAPCE}
    _ticker_info_gap_str=''
    for i in $(seq 1 ${TICKER_SPACE}); do
        _ticker_info_gap_str+=${EMPTY_STR}
    done
    for i in $(seq 1 ${#MARKET}); do
        ticker_result+=${EMPTY_STR}
    done
    ticker_result+=${_ticker_info_gap_str}
    # last price
    ticker_result+="${COLOR_GREY}${LAST_PRICE_STR}${NO_COLOR}"
    _ticker_str_offset=$(expr ${#LAST_PRICE_STR} - ${#_day_close_price})
    _ticker_str_offset=${_ticker_str_offset#-}
    _last_price_gap=''
    if [ ${#_day_close_price} -le ${#LAST_PRICE_STR} ]; then
        ticker_result+=${_ticker_info_gap_str}
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            _last_price_gap+=${EMPTY_STR}
        done
    else
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            ticker_result+=${EMPTY_STR}
        done
        _last_price_gap+=${_ticker_info_gap_str}
    fi
    # 24h change
    ticker_result+="${COLOR_GREY}${H24_CHANGE_STR}${NO_COLOR}"
    _ticker_str_offset=$(expr ${#H24_CHANGE_STR} - ${#_daily_change_percent})
    _ticker_str_offset=${_ticker_str_offset#-}
    _daily_change_gap=''
    if [ ${#_daily_change_percent} -le ${#H24_CHANGE_STR} ]; then
        ticker_result+=${_ticker_info_gap_str}
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            _daily_change_gap+=${EMPTY_STR}
        done
    else
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            ticker_result+=${EMPTY_STR}
        done
        _daily_change_gap+=${_ticker_info_gap_str}
    fi
    # 24h high
    ticker_result+="${COLOR_GREY}${H24_HIGH_STR}${NO_COLOR}"
    _ticker_str_offset=$(expr ${#H24_HIGH_STR} - ${#_day_high_price})
    _ticker_str_offset=${_ticker_str_offset#-}
    _day_high_gap=''
    if [ ${#_day_high_price} -le ${#H24_HIGH_STR} ]; then
        ticker_result+=${_ticker_info_gap_str}
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            _day_high_gap+=${EMPTY_STR}
        done
    else
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            ticker_result+=${EMPTY_STR}
        done
        _day_high_gap+=${_ticker_info_gap_str}
    fi
    # 24h low
    ticker_result+="${COLOR_GREY}${H24_LOW_STR}${NO_COLOR}"
    _ticker_str_offset=$(expr ${#H24_LOW_STR} - ${#_day_low_price})
    _ticker_str_offset=${_ticker_str_offset#-}
    _day_low_gap=''
    if [ ${#_day_low_price} -le ${#H24_LOW_STR} ]; then
        ticker_result+=${_ticker_info_gap_str}
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            _day_low_gap+=${EMPTY_STR}
        done
    else
        for i in $(seq 1 $(expr ${_ticker_str_offset} + ${TICKER_SPACE})); do
            ticker_result+=${EMPTY_STR}
        done
        _day_low_gap+=${_ticker_info_gap_str}
    fi
    # 24h volume
    ticker_result+="${COLOR_GREY}${H24_VOLUME_STR}${NO_COLOR}"
    # ticker data
    ticker_result+="\n${BASE_PADDING_LEFT_SAPCE}${FONT_STRONG}${COLOR_GREEN}${MARKET}${NO_COLOR}${_ticker_info_gap_str}"
    ticker_result+="${FONT_STRONG}${COLOR_GREEN}${_day_close_price}${NO_COLOR}${_last_price_gap}"
    if [[ ${_daily_change_percent} == -* ]]; then
        _daily_change_percent="${FONT_STRONG}${COLOR_RED}${_daily_change_percent}${NO_COLOR}"
    else
        _daily_change_percent="${FONT_STRONG}${COLOR_GREEN}${_daily_change_percent}${NO_COLOR}"
    fi
    ticker_result+="${_daily_change_percent}${NO_COLOR}${_daily_change_gap}"
    ticker_result+="${FONT_STRONG}${COLOR_GREEN}${_day_high_price}${NO_COLOR}${_day_high_gap}"
    ticker_result+="${FONT_STRONG}${COLOR_GREEN}${_day_low_price}${NO_COLOR}${_day_low_gap}"
    ticker_result+="${FONT_STRONG}${COLOR_GREEN}${_day_volume} ${MARKET%%-*}${NO_COLOR}"
}
# chart
chart_result=''
function drawChartData() {
    # fetch candles
    api_result=$(curl -s "https://${HOST}/api/v3/asset_pairs/${MARKET}/candles?period=${PERIOD}&limit=${LIMIT}")
    log ${api_result}
    if [[ ${api_result} != {\"code\":0* ]]; then
        return 1
    fi
    # parse candle array
    api_result=${api_result#*[}
    api_result=${api_result%]*}
    log ${api_result}
    # calculate candle count
    candle_count=$(echo ${api_result} | grep -o '},{' | wc -l)
    candle_count=$(expr ${candle_count} + 1)
    log "candle count: ${candle_count}"
    if [ ${candle_count} = 0 ]; then
        return 1
    fi
    # parse candle item
    for i in $(seq 1 ${candle_count}); do
        _item=""
        if [ ${i} = ${candle_count} ]; then
            _item=${api_result}
        else
            _item=${api_result%%\},\{*}
            api_result=${api_result#*\},\{}
        fi

        open=${_item#*open\":\"}
        open=${open%%\",*}

        high=${_item#*high\":\"}
        high=${high%%\",*}

        low=${_item#*low\":\"}
        low=${low%%\",*}

        close=${_item#*close\":\"}
        close=${close%%\",*}

        change="up"
        if [ $(echo "${open} > ${close}" | bc) -eq 1 ]; then
            change="down"
        fi

        day_month=${_item#*time\":\"}
        day_month=${day_month%%T*}
        day_month=${day_month#*-}

        candle_arr[$(expr ${i} - 1)]=${open}" "${high}" "${low}" "${close}" "${change}" "${day_month}
    done
    log "${candle_arr[*]}"

    # calculate kchart price
    max_price='0'
    min_price='0'
    for i in $(seq 0 $(expr ${#candle_arr[*]} - 1)); do
        getCurrentCandleData ${i}
        if [ $(echo "${c_candle_high} > ${max_price}" | bc) -eq 1 ]; then
            max_price=${c_candle_high}
        fi

        if [ ${min_price} = 0 ]; then
            min_price=${c_candle_low}
            continue
        fi
        if [ $(echo "${c_candle_low} < ${min_price}" | bc) -eq 1 ]; then
            min_price=${c_candle_low}
        fi
    done
    unit_price=$(echo "scale=${PRICE_SCALE};((${max_price} - ${min_price}) / (${LINE} - 4)) / 1" | bc)
    max_price=$(echo "scale=${PRICE_SCALE};(${max_price} + ${unit_price} * 2) / 1" | bc)
    min_price=$(echo "scale=${PRICE_SCALE};(${min_price} - ${unit_price} * 2) / 1" | bc)
    mid_price=$(echo "scale=${PRICE_SCALE};(${max_price} - (${max_price} - ${min_price}) / 2) / 1" | bc)

    if [[ ${max_price} == .* ]]; then
        max_price="0${max_price}"
    fi
    if [[ ${min_price} == .* ]]; then
        min_price="0${min_price}"
    fi
    if [[ ${mid_price} == .* ]]; then
        mid_price="0${mid_price}"
    fi

    log "max price: "${max_price}", min price: "${min_price}", mid price:"${mid_price}", unit price: "${unit_price}
    # calculate left space
    price_length=${#max_price}
    log "price lenght: "${price_length}
    padding_left_empty_str=''
    for i in $(seq 1 $(expr ${PADDING_LEFT_SAPCE} + ${price_length})); do
        padding_left_empty_str+=${EMPTY_STR}
    done
    # draw kchart
    _candle_count_in_loop=$(expr ${candle_count} - 1)
    found_max_arr=()
    for i in $(seq 0 ${_candle_count_in_loop}); do
        found_max_arr[$i]="0"
    done

    chart_left_empty_str="${padding_left_empty_str} ${Y_LINE} "
    result="${chart_left_empty_str}\n"
    result+="${BASE_PADDING_LEFT_SAPCE}${COLOR_GREY}${max_price}${NO_COLOR} ${Y_INDICATOR} "
    for i in $(seq 0 $(expr ${LINE} - 1)); do
        # unit base price, mid price
        _base_price=$(echo "${max_price} - ((${i} + 1) * ${unit_price})" | bc)
        _mid_price=$(echo "scale=${PRICE_SCALE};${_base_price} + ${unit_price} / 2" | bc)
        for j in $(seq 0 ${_candle_count_in_loop}); do
            _index=$(expr ${_candle_count_in_loop} - ${j})
            getCurrentCandleData ${_index}
            if [ ${found_max_arr[${_index}]} = "0" ]; then
                # draw half rect
                if [ $(echo "${c_candle_high} > ${_mid_price}" | bc) -eq 1 ]; then
                    if [ ${c_candle_change} = "up" ]; then
                        result+=${PRICE_UP_RECT}" "
                    else
                        result+=${PRICE_DOWN_RECT}" "
                    fi
                    found_max_arr[${_index}]="1"
                    continue
                fi
                # draw rect
                if [ $(echo "${c_candle_high} >= ${_base_price}" | bc) -eq 1 ]; then
                    if [ ${c_candle_change} = "up" ]; then
                        result+=${PRICE_UP_RECT_BOTTOM}" "
                    else
                        result+=${PRICE_DOWN_RECT_BOTTOM}" "
                    fi
                    found_max_arr[${_index}]="1"
                else
                    result+=${EMPTY_STR}" "
                fi
            else
                # draw rect
                if [ $(echo "${c_candle_low} < ${_mid_price}" | bc) -eq 1 ]; then
                    if [ ${c_candle_change} = "up" ]; then
                        result+=${PRICE_UP_RECT}" "
                    else
                        result+=${PRICE_DOWN_RECT}" "
                    fi
                    continue
                fi
                # draw half rect
                if [ $(echo "${c_candle_low} < (${_base_price} + ${unit_price})" | bc) -eq 1 ]; then
                    if [ ${c_candle_change} = "up" ]; then
                        result+=${PRICE_UP_RECT_TOP}" "
                    else
                        result+=${PRICE_DOWN_RECT_TOP}" "
                    fi
                else
                    result+=${EMPTY_STR}" "
                fi
            fi
        done
        # draw Y mid price
        if [ ${i} = ${MID_LINE} ]; then
            _offset_count=$(expr ${price_length} - ${#mid_price})
            _offset_space=''
            if [ ${_offset_count} -gt '0' ]; then
                for z in $(seq 1 ${_offset_count}); do
                    _offset_space+=${EMPTY_STR}
                done
            fi
            result+="\n${BASE_PADDING_LEFT_SAPCE}${_offset_space}${COLOR_GREY}${mid_price}${NO_COLOR} ${Y_INDICATOR} "
            continue
        fi
        # draw Y min price
        if [ ${i} = $(expr ${LINE} - 2) ]; then
            _offset_count=$(expr ${price_length} - ${#min_price})
            _offset_space=''
            if [ ${_offset_count} -gt '0' ]; then
                for z in $(seq 1 ${_offset_count}); do
                    _offset_space+=${EMPTY_STR}
                done
            fi
            result+="\n${BASE_PADDING_LEFT_SAPCE}${_offset_space}${COLOR_GREY}${min_price}${NO_COLOR} ${Y_INDICATOR}"
            continue
        fi

        if [ ${i} -lt $(expr ${LINE} - 1) ]; then
            result+="\n"${chart_left_empty_str}
        fi
    done
    # draw kchart bottom line
    result+="\n${padding_left_empty_str} ${XY_CORNER} "
    for i in $(seq 0 ${_candle_count_in_loop}); do
        _p=$(expr ${i} % ${X_INDICATOR_SCALE})
        if [ ${_p} -eq '0' ]; then
            result+="${X_INDICATOR} "
        else
            result+="${X_LINE} "
        fi
    done
    result+=${X_LINE}
    # draw date line
    date_gap_empty_str=''
    for i in $(seq 1 $(expr ${X_INDICATOR_SCALE} - 3)); do
        date_gap_empty_str+="${EMPTY_STR} "
    done
    getCurrentCandleData ${_candle_count_in_loop}
    result+="\n${padding_left_empty_str} ${EMPTY_STR} ${COLOR_GREY}${c_candle_day_month}${NO_COLOR} "
    for i in $(seq 1 ${_candle_count_in_loop}); do
        _p=$(expr ${i} % ${X_INDICATOR_SCALE})
        if [ ${_p} -eq '0' ]; then
            getCurrentCandleData $(expr ${_candle_count_in_loop} - ${i})
            result+="${date_gap_empty_str}${COLOR_GREY}${c_candle_day_month}${NO_COLOR} "
        fi
    done
    chart_result=${result}
}

tput clear
count='1'
while :; do
    count=$(expr ${count} + 1)
    if [ ${count} = '2' ]; then
        count='0'
        drawChartData
    fi
    drawTickerData
    tput cup 0 0
    echo -e "\n${ticker_result}"
    echo -e "\n${chart_result}\n\n"
    sleep 5
done

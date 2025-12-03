#!/usr/bin/env bash
##微信机器人通知相关封装
##包含发送文本 发送图片 发送markdown
notifys=()



function config() {
  OPTIND=1
while getopts ":n:" opt
do
  case "$opt" in
        n)
        array=(${OPTARG//\,/ })
        length=${#array[*]}
        if [[ length -gt 0 ]]; then
          for i in "${!array[@]}"; do
              notifys[i]=${array[i]}
          done
        fi
          echo "send_msg.sh config this is -n option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        ?)
            echo "send_msg.sh config 未知参数.默认方式"
            ;;
    esac
done
    if [[ ${#notifys[*]} == 0 ]]; then
        echo "send_msg.sh config  消息发送配置错误：通知地址为空";exit 1
    fi
}

##发送消息到微信机器人
sendMessage(){
    if [[ ${#notifys[*]} == 0 ]]; then
        echo "send_msg.sh sendMessage  消息发送配置错误：通知地址为空"
        exit 1
    fi

  for i in "${!notifys[@]}"; do
             curl curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key='"${notifys[i]}" \
             -H 'Content-Type: application/json' \
             -d "$1"
  done

}



##发送文本消息可以@所有人
## -t 类容
## -a @所有人 无参数
## -p @人员的电话号码 eg:110,112,119
function sendTxt() {
OPTIND=1
text_send_all=false
send_p=()
message=""
while getopts ":n:t:ap:" opt
do
  case "$opt" in
        n)
          config -n "$OPTARG"
          echo "send_msg.sh sendTxt this is -n option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        t)
          message=$OPTARG
            echo "send_msg.sh sendTxt this is -t option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        a)
          text_send_all=true
             echo "send_msg.sh sendTxt this is -a option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        p)
            array=(${OPTARG//\,/ })
            length=${#array[*]}
          if [[ length -gt 1 ]]; then
             for i in "${!array[@]}"; do
               send_p[$i]=${array[$i]}
            done
          fi
             echo "send_msg.sh sendTxt this is -p option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        ?)
            echo "send_msg.sh sendTxt 未知参数.默认方式"
            ;;
    esac
done

  #发送的信息为空则退出
  if [[ -z "$message" ]]; then
    echo "send_msg.sh sendTxt 不能发送空信息"; exit 1;
  fi

  ##处理发送列表

  send_list=""
  if [[ ${#send_p[*]} -gt 0 ]]; then
     for i in "${!send_p[@]}"; do
              if [[ i -gt 0 ]]; then
                    send_list="$send_list,\"${send_p[$i]}\""
                    else
                    send_list="\"${send_p[$i]}\""
              fi
            done
  fi
  ##添加@所有人
  if [[ $text_send_all == true ]]; then
     if [[ ${#send_list} -gt 0 ]]; then
          send_list="$send_list,\"@all\""
        else
          send_list="\"@all\""
     fi

  fi

  ##组合信息
  sendMessage "{
    \"msgtype\": \"text\",
    \"text\": {
        \"content\": \"$message\",
        \"mentioned_mobile_list\":[$send_list]
    }
  }"
}

#sendTxt -t "hello word"
#echo "$content"


##发送图片消息 不能@人员
## -t 标题
## -d 描述
## -u url 点击后连接地址
## -p 图片Url
function sendImage() {
  title=""
  description=""
  link_url=""
  picurl=""
  OPTIND=1
while getopts ":n:t:d:u:p:" opt
do
  case "$opt" in
        n)
          config -n "$OPTARG"
          echo "send_msg.sh sendImage this is -n option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        t)
          title=$OPTARG
            echo "send_msg.sh sendImage this is -t option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        d)
          description=$OPTARG
             echo "send_msg.sh sendImage this is -d option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        u)
          link_url=$OPTARG
             echo "send_msg.sh sendImage this is -u option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        p)
          picurl=$OPTARG
             echo "send_msg.sh sendImage this is -p option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        ?)
            echo "send_msg.sh sendImage 未知参数.默认方式"
            ;;
    esac
done

  #参数验证
  if [[ -z "$title" ]]; then
    echo "send_msg.sh sendImage 标题不能为空"; exit 1;
  fi
sendMessage "{
          \"msgtype\": \"news\",
          \"news\": {
             \"articles\" : [
                 {
                     \"title\" : \"$title\",
                     \"description\" : \"$description\",
                     \"url\" : \"${link_url}\",
                     \"picurl\" : \"${picurl}\"
                 }
              ]
          }
      }"
}

#sendImage -t "中秋快乐" -d "描述信息" -u "www.baidu.com" -p "baidu"
#echo "$content"




##发送MarkDown
## -n 发送到指定的机器人 参数：机器人id
## -t 内容
## -p 指定@人员 eg: 人员id，人员id
function sendMarkdown() {
  OPTIND=1
  message=""
  send_p=()
  while getopts ":n:t:ap:" opt
do
  case "$opt" in
        n)
           config -n  "$OPTARG"
          echo "send_msg.sh sendMarkdown this is -n option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        t)
          message=$OPTARG
            echo "send_msg.sh sendMarkdown this is -t option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        p)
            array=(${OPTARG//\,/ })
            length=${#array[*]}
          if [[ length -gt 1 ]]; then
             for i in "${!array[@]}"; do
               send_p[$i]=${array[$i]}
            done
          fi
             echo "send_msg.sh sendMarkdown this is -p option. OPTARG=[$OPTARG] OPTIND=[$OPTIND]"
            ;;
        ?)
            echo "send_msg.sh sendMarkdown sendMarkdown 未知参数.默认方式"
            ;;
    esac
done
 send_list=""
  if [[ ${#send_p[*]} -gt 0 ]]; then
     for i in "${!send_p[@]}"; do
              if [[ i -gt 0 ]]; then
                    send_list="$send_list<@${send_p[$i]}> "
                    else
                    send_list="<@${send_p[$i]}> "
              fi
            done
  fi
  #参数验证
  if [[ -z "$message" ]]; then
    echo "send_msg.sh sendMarkdown 内容不能为空"; exit 1;
  fi

  sendMessage "{
                        \"msgtype\": \"markdown\",
                        \"markdown\": {
                            \"content\": \"$message $send_list\"
                          }"

}



#sendMarkdown -t "\n## 测试 [流水线]($CI_PROJECT_URL/-/jobs/$CI_JOB_ID) \n > **我是文件**\n\n 我是描述\n" \-a -n "1"




##  \n## 打包完成 [流水线]($CI_PROJECT_URL/-/jobs/$CI_JOB_ID) \n > **${file##*/}**\n\n $buildUpdateDescription
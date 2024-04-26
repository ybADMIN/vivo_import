#!/bin/bash
if [ ! -e "$OUTAPK" ]; then
echo "文件不存在，上传失败"
    exit 1
fi

# 检查文件名是否包含 vivocerRES
if ! echo "$(basename "$OUTAPK")" | grep -q "$RES_NAME"; then
    echo "非正式包不上传蒲公英"
    exit 0
fi
# 将用户输入转换为小写字母以便比较
read -p "是否上传到蒲公英？（输入 Y 或 N）: " choice
choice=$(echo "${choice}" | tr '[:upper:]' '[:lower:]')

# 检查用户输入是否为 Y 或 y，如果是，则执行操作
if [ "${choice}" = "y" ]; then
   echo "上传到蒲公英"
    # 在这里执行你的操作
elif [ "${choice}" = "n" ]; then
    echo "用户取消操作"
    exit 1
else
    exit 1
fi

echo "准备上传APK:$OUTAPK"

##上传数据到蒲公英
tmpDir=$DIRECTORY/tmp
respFile=$tmpDir/temp.log
hostName=$(echo $(hostname | sed 's/.local//'))
rm -fr $respFile && mkdir -p $tmpDir
buildUpdateDescription="VIVO 正式打包完成，手动导入${fixName}证书"
#上传apk到蒲公英
updatePrams=(${ANDROID_PGY//\,/ })
curl -F "file=@$OUTAPK" -F "${updatePrams[0]}" -F ${updatePrams[1]} -F "buildUpdateDescription=${buildUpdateDescription}" https://upload.pgyer.com/apiv2/app/upload >$respFile

#引入json脚本
source $ANDROID_BUILD_SHELL/json_decode.sh
#引入消息发送功能
source $ANDROID_BUILD_SHELL/send_msg.sh
result=$(cat $respFile)
code=$(getJsonValuesByAwk "$result" "code" "defaultValue")

function successMsg() {
    #app_QR_code_url=$(getJsonValuesByAwk "$result" "buildQRCodeURL" "defaultValue"|sed ' s/"//g')
    app_icon="https://www.pgyer.com/image/view/app_icons/$(getJsonValuesByAwk "$result" "buildIcon" "defaultValue" | sed ' s/"//g')"
    apk_url="https://www.pgyer.com/$(getJsonValuesByAwk "$result" "buildKey" "defaultValue" | sed ' s/"//g')"
    build_file_name="$(getJsonValuesByAwk "$result" "buildFileName" "defaultValue" | sed ' s/"//g')"
    description="$buildUpdateDescription"
    sendImage -t "$build_file_name" -d "$description" -u "$apk_url" -p "$app_icon"
}

if [[ $code == 0 ]]; then
    config -n "$ANDROID_NOTIFY_WX"
    successMsg
fi

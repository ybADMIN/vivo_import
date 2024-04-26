#!/bin/bash
ANDROID_BUILD_SHELL=bin
#引入APK检测文件
source $ANDROID_BUILD_SHELL/checkvivoceradd.sh
## 如提示没有权限可以将该代码注释，可能需要使用sudo执行
chmod +rwx $ANDROID_BUILD_SHELL/aapt
chmod +rwx $ANDROID_BUILD_SHELL/zip
chmod +rwx $ANDROID_BUILD_SHELL/apksigner
xattr -d com.apple.quarantine $ANDROID_BUILD_SHELL/zip
xattr -d com.apple.quarantine $ANDROID_BUILD_SHELL/aapt
xattr -d com.apple.quarantine $ANDROID_BUILD_SHELL/apksigner
echo "Start..."
echo
if [ ! -e "config.sh" ]; then
echo "请先配置config.sh文件后使用"
    exit 1
fi
#引入配置信息
source config.sh

# 将当前目录加入到 PATH 中
export PATH=$PATH:./$ANDROID_BUILD_SHELL/
CURRENT_DIRECTORY=$(pwd)
# 设置要扫描的目录路径
DIRECTORY=$CURRENT_DIRECTORY/outApk
META_INF_DIRECTORY=META-INF
# 检查目录是否存在
if [ ! -d "$DIRECTORY" ]; then
    mkdir -p "$DIRECTORY"
fi

# 检查目录是否存在
if [ ! -d "$META_INF_DIRECTORY" ]; then
    mkdir -p "$META_INF_DIRECTORY"
fi

DEV_CER="CustomShortName:debug"
RES_CER="CustomShortName:BJCFXX-EP"
DEV_NAME="vivocerDEV"
RES_NAME="vivocerRES"
ERR_NAME="vivocerERR"
APK_VIVO_CER_PATH=$META_INF_DIRECTORY/VIVOEMM.CER
if [ $# -eq 0 ]; then
    echo "没有传递文件名称参数。"
    exit 1
fi
if ! [ $# -eq 2 ]; then
    echo "参数不正确：参数1:APK路径 参数2:证书路径"
    exit 1
fi
FILE_PATH="$1"
CER_NAME="$2"

#删除签名过的文件
find "${DIRECTORY}" -type f -name "${FILE_PATH%.apk}-vivocer*.apk" -exec rm {} \;

echo "=====================================START============================================="
echo "当前应用："
echo $(basename "${FILE_PATH}")
if [[ $(basename "${FILE_PATH}") != ep* ]]; then
    echo "错误应用名称，应用必须是 \"ep\" 开头"
    exit 1
fi
echo
# echo "输入使用证书："
# read CER_NAME
rm "$APK_VIVO_CER_PATH"
cp "$CER_NAME" "$APK_VIVO_CER_PATH"
if grep -q "$DEV_CER" "$APK_VIVO_CER_PATH"; then
    read -p "非商业证书导入请确认执行操作？（输入 Y 或 N）: " choice
    # 将用户输入转换为小写字母以便比较
    choice=$(echo "${choice}" | tr '[:upper:]' '[:lower:]')

    # 检查用户输入是否为 Y 或 y，如果是，则执行操作
    if [ "${choice}" = "y" ]; then
        echo "使用开发证书"
        # 在这里执行你的操作
    elif [ "${choice}" = "n" ]; then
        echo "用户取消操作"
        exit 1
    else
        exit 1
    fi
fi
# 获取证书MD5值
md5_value=$(md5 "$APK_VIVO_CER_PATH" | awk '{print $4}')
echo "证书MD5 $md5_value"
# 提示用户确认
cat $APK_VIVO_CER_PATH | grep -E "PackageName|CustomShortName|DeviceIds"
# 生成临时文件用于证书处理
baseName=$(basename "$FILE_PATH")
cp $FILE_PATH "$DIRECTORY/${baseName}.tmp"
FILE_PATH="$DIRECTORY/${baseName}.tmp"
# 删除 META-INF/VIVOEMM.CER
zip -d $FILE_PATH META-INF/VIVOEMM.CER >/dev/null
echo "Importing certificate..."
echo

# 使用 aapt 添加 META-INF/VIVOEMM.CER
aapt add $FILE_PATH META-INF/VIVOEMM.CER
echo

fixName="$ERR_NAME"
# 添加证书后缀
if grep -q "$DEV_CER" "$APK_VIVO_CER_PATH"; then
    echo "开发证书导入"
    fixName="$DEV_NAME"
fi
if grep -q "$RES_CER" "$APK_VIVO_CER_PATH"; then
    echo "商用证书导入"
    fixName="$RES_NAME"
fi

FILENAME_WITHOUT_EXTENSION=${FILE_PATH%.apk.tmp}
# 获取不带扩展名的文件名

if [[ "$FILENAME_WITHOUT_EXTENSION" =~ -vivocer[A-Za-z]+ ]]; then
    #如果存在证书名称标识重新导入证书后将旧版本标识去掉
    FILENAME_WITHOUT_EXTENSION=$(echo "$FILENAME_WITHOUT_EXTENSION" | sed 's/-vivocer[^-]*//')
fi
OUTAPK="$FILENAME_WITHOUT_EXTENSION-${fixName}.apk"
# 使用 apksigner 进行签名
apksigner sign --ks $KEY_STORE_PATH --v4-signing-enabled false --ks-key-alias $alias_key --ks-pass pass:$key_pass --out $OUTAPK $FILE_PATH
# 检查证书添加结果
rm $FILE_PATH
checkApk "$OUTAPK" "$md5_value"

#上传文件到蒲公英
source $ANDROID_BUILD_SHELL/upload.sh
# 检查是否有异常发生
if [ "$?" -ne "0" ]; then
    echo
    echo "发生异常，删除文件 $OUTAPK"
    rm -f "$OUTAPK"
fi
echo "=====================================END============================================="
# # 遍历目录中的文件
# for FILE_PATH in $(find $DIRECTORY -name "*.apk" ); do

# done

read -p "Press Enter to exit"

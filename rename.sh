#!/bin/bash
# 输出文件名
checkApk() {
    # 默认不执行重命名逻辑
    rename=false
    OPTIND=1
    # 解析命令行选项
    while getopts ":n:" option; do
        case "$option" in
        n)
            rename=true
            apk_file="$OPTARG"
            ;;
        :)
            echo "选项 -$OPTARG 需要一个参数。"
            exit 1
            ;;
        ?)
            echo "未知选项 -$OPTARG。"
            exit 1
            ;;
        esac
    done
    if $rename; then
        # 移动到选项参数的索引位置
        shift $((OPTIND - 1))
    else
        apk_file="$1"
    fi

    DEV_NAME="vivocerDEV"
    RES_NAME="vivocerRES"
    ERR_NAME="vivocerERR"
    DEV_CER="CustomShortName:debug"
    RES_CER="CustomShortName:BJCFXX-EP"

    cer_file="META-INF/VIVOEMM.CER"
    # 检查参数是否为空
    if [ -z "$apk_file" ]; then
        echo "Usage: $0 <APK_FILE>"
        return 1
    fi

    BASE_NAME=$(basename "$apk_file")
    BASE_DIR=$(dirname "$apk_file")
    # 解压 APK 文件
    echo "解压文件:$BASE_NAME"
    if [ -f "$apk_file" ]; then
        temp_dir="$(mktemp -d)"
        trap cleanup EXIT
        unzip -q -o "$apk_file" -d "$temp_dir"
    else
        echo "APK 文件不存在 $apk_file"
        return 1
    fi

    echo "检查证书"
    # 检查 META-INF/VIVOEMM.CER 文件是否存在
    cer_path="$temp_dir/$cer_file"
    if [ -f "$cer_path" ]; then
        cat $cer_path | grep -E "PackageName|CustomShortName|DeviceIds"

        fixName="$ERR_NAME"
        # 添加证书后缀
        if grep -q "$DEV_CER" "$cer_path"; then
            echo "存在开发证书"
            fixName="$DEV_NAME"
        fi
        if grep -q "$RES_CER" "$cer_path"; then
            echo "存在商用证书"
            fixName="$RES_NAME"
        fi

        # 使用 grep 命令查找文件名中是否包含 DEV_CER
        if echo "$BASE_NAME" | grep -q "$fixName"; then
            echo "已重命名文件无需命名 $fixName "
        else
            if $rename; then
                FILENAME_WITHOUT_EXTENSION=${BASE_NAME%.apk}
                OUTAPK="$BASE_DIR/$FILENAME_WITHOUT_EXTENSION-${fixName}.apk"
                mv "$apk_file" "$OUTAPK"
                echo "已重命名文件： $OUTAPK "
            fi
        fi
    else
        echo "源文件不存在证书"
    fi

    cleanup

}

# 设置清理函数
cleanup() {
    echo "Cleaning up..."
    # 检查临时目录是否不为空，如果不为空，则执行清理操作
    if [ -n "$(ls -A "$temp_dir")" ]; then
        rm -rf "$temp_dir"
        echo "temp_dir 存在缓存，已清理."
    else
        echo "temp_dir 没有缓存，无需清理."
    fi
    # 在这里添加清理操作
}

#!/bin/bash

checkApk() {
    # 传入参数：APK 文件路径、预期的 MD5 值
    apk_file="$1"
    expected_md5="$2"
    cer_file="META-INF/VIVOEMM.CER"
    # 检查参数是否为空
    if [ -z "$apk_file" ] || [ -z "$expected_md5" ]; then
        echo "Usage: $0 <APK_FILE> <EXPECTED_MD5>"
        return 1
    fi

    # 解压 APK 文件
    temp_dir=$(mktemp -d)
    echo "证书文件校验"
    unzip -q -o "$apk_file" -d "$temp_dir"

    # 检查 META-INF/VIVOEMM.CER 文件是否存在
    cer_path="$temp_dir/$cer_file"
    if [ -f "$cer_path" ]; then
        # 计算文件的 MD5 值
        actual_md5=$(md5 "$cer_path" | awk '{print $4}')

        # 比较 MD5 值
        if [ "$actual_md5" != "$expected_md5" ]; then
            echo "ERROR: META-INF/VIVOEMM.CER 文件的 MD5 值与预期不一致。"
            # 清理临时目录
            rm -rf "$temp_dir"
            return 1
        fi
        # 读取证书判断包名是否一致

        # 获取字符串
        string=$(cat "$META_INF_DIRECTORY/VIVOEMM.CER" | grep -E "^PackageName:")

        # 使用 cut 命令提取出值
        package_name=$(echo "$string" | cut -d ':' -f 2)

        echo "证书与应用PackageName校验"
        echo
        # # 定义要搜索的字符串
        search_string=package=\"$package_name\"
        java -jar $ANDROID_BUILD_SHELL/apktool_2.9.3.jar d $apk_file -o "$temp_dir/apktool"
        mfFiel=$temp_dir/apktool/AndroidManifest.xml

        if ! grep -q "$search_string" "$mfFiel"; then
            echo "安装包与证书不匹配：$search_string"
            rm -rf "$temp_dir"
            return 1
        fi
        echo "完成导入"
        # 使用 grep 命令在文件中查找字符串
        # if grep -q "$search_string" $mfFiel; then
        #     # echo "文件中存在指定的字符串：$search_string"
        # else
        #     echo "安装包与证书不匹配：$search_string"
        #     rm -rf "$temp_dir"
        #     exit 1
        # fi
    else
        echo "ERROR: META-INF/VIVOEMM.CER 文件不存在。"
        # 清理临时目录
        rm -rf "$temp_dir"
        return 1
    fi

}

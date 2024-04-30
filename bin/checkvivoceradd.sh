#!/bin/bash
## 读取配置文件config.sh中的KeyValue
function getCerOptionMapByKey() {
    local key="$1"
    for pair in "${cerOptionMap[@]}"; do
        local k="${pair%%:*}"
        local v="${pair#*:}"
        if [ "$k" = "$key" ]; then
            echo "$v"
            return
        fi
    done
    echo "Key not found"
    return 1
}

function checkApkDevCerExists(){
     local apk_file="$1"
     local cer_file="META-INF/VIVOEMM.CER"
      # 解压 APK 文件
    unzip -q -o "$apk_file" -d "$temp_dir"
    local cer_path="$temp_dir/$cer_file"
     if [ -f "$cer_path" ]; then
        # 获取字符串
         local apkCerStr=$(<"$cer_path")
         # 使用函数获取指定键的值
         local customShortName=$(getValueByKey "CustomShortName" "$apkCerStr")
        if [ "$DEV_CER" != "$customShortName" ]; then
             echo "APK中不含有开发证书，无法导入正式证书"
            return 1
        fi
    else
        echo "APK中不含有开发证书[文件不存在]，无法导入正式证书"
        # 清理临时目录
        return 1
    fi
}

function checkApk() {
    # 传入参数：APK 文件路径、预期的 MD5 值
    local apk_file="$1"
    local expected_md5="$2"
    local cer_file="META-INF/VIVOEMM.CER"
    # 检查参数是否为空
    if [ -z "$apk_file" ] || [ -z "$expected_md5" ]; then
        echo "Usage: $0 <APK_FILE> <EXPECTED_MD5>"
        return 1
    fi

    # 解压 APK 文件
    # trap cleanup_tempdir EXIT  
    echo "证书文件校验"
    unzip -q -o "$apk_file" -d "$temp_dir"

    # 检查 META-INF/VIVOEMM.CER 文件是否存在
    local cer_path="$temp_dir/$cer_file"
    if [ -f "$cer_path" ]; then
        # 计算文件的 MD5 值
       local actual_md5=$(md5 "$cer_path" | awk '{print $4}')

        # 比较 MD5 值
        if [ "$actual_md5" != "$expected_md5" ]; then
            echo "ERROR: META-INF/VIVOEMM.CER 文件的 MD5 值与预期不一致。"
            # 清理临时目录
            return 1
        fi

        # 读取证书判断包名是否一致

        # 获取字符串
         local importCerStr=$(<"$META_INF_DIRECTORY/VIVOEMM.CER")
         # 使用函数获取指定键的值
         local package_name=$(getValueByKey "PackageName" "$importCerStr")

        # 使用 cut 命令提取出值
        if [ -z "$package_name" ];then
            echo "包名获取错误$package_name"
            return 1;
        fi
        if [ "$RES_NAME" = "$fixName" ]; then
            # 证书系统权限校验
            echo "商业证书校验系统权限"
            cerOptionMapKey=$(echo "$package_name" | sed 's/\./_/g') 
            cerCheckvalue=$(getCerOptionMapByKey "$cerOptionMapKey")
            echo "通过包名：$cerOptionMapKey 获取标准证书：$cerCheckvalue"
        if [ -z "$cerCheckvalue" ] || [ ! -e "$cerCheckvalue" ]; then  
            echo "请检查配置文件是否正确配置，CER证书路径：key=$cerOptionMapKey value=$cerCheckvalue "
            return 1
           fi
             # 从文件中读取输入字符串
            local checkCerStr=$(<"$cerCheckvalue")
            local check_PackageName=$(getValueByKey "PackageName" "$checkCerStr")
            local import_PackageName=$(getValueByKey "PackageName" "$importCerStr")
            # 获取各个字段的值，并以分号分隔
            local check_RelatedPackageNames=$(getValueByKey "RelatedPackageNames" "$checkCerStr" | tr ';' '\n')
            local check_Permissions=$(getValueByKey "Permissions" "$checkCerStr" | tr ';' '\n')
            local check_CustomShortName=$(getValueByKey "CustomShortName" "$checkCerStr" | tr ';' '\n')
            local check_SystemPermissions=$(getValueByKey "SystemPermissions" "$checkCerStr" | tr ';' '\n')
        
            local import_RelatedPackageNames=$(getValueByKey "RelatedPackageNames" "$importCerStr" | tr ';' '\n')
            local import_Permissions=$(getValueByKey "Permissions" "$importCerStr" | tr ';' '\n')
            local import_CustomShortName=$(getValueByKey "CustomShortName" "$importCerStr" | tr ';' '\n')
            local import_SystemPermissions=$(getValueByKey "SystemPermissions" "$importCerStr" | tr ';' '\n')

            # 对比 check_ 中的每个值是否都在 import_ 中存在
            for value in $check_RelatedPackageNames; do
                if ! echo "$import_RelatedPackageNames" | grep -q "$value"; then
                    echo "RelatedPackageNames 中的值 '$value' 不在 import_ 中存在，抛出异常！"
                    return 1
                fi
            done
            echo "关联包检测完成"
            for value in $check_Permissions; do
                if ! echo "$import_Permissions" | grep -q "$value"; then
                    echo "Permissions 中的值 '$value' 不在 import_ 中存在，抛出异常！"
                    return 1
                fi
            done
            echo "权限配置检测完成"
            for value in $check_SystemPermissions; do
                if ! echo "$import_SystemPermissions" | grep -q "$value"; then
                    echo "SystemPermissions 中的值 '$value' 不在 import_ 中存在，抛出异常！"
                    return 1
                fi
            done
            echo "系统权限检测完成"
            for value in $check_CustomShortName; do
                if ! echo "$import_CustomShortName" | grep -q "$value"; then
                    echo "CustomShortName 中的值 '$value' 不在 import_ 中存在，抛出异常！"
                    return 1
                fi
            done
            echo "证书标识检测完成"
            if [ "$check_PackageName" != "$import_PackageName" ]; then
                echo "PackageName 不同！ check_PackageName = $check_PackageName import_PackageName= $import_PackageName "
                return 1
            fi
            echo "包名检测完成"
        fi
       
        echo "应用与证书包名校验"
        echo
        # # 定义要搜索的字符串
        local search_string=package=\"$package_name\"
        java -jar $ANDROID_BUILD_SHELL/apktool_2.9.3.jar d $apk_file -o "$temp_dir/apktool"
        local mfFiel=$temp_dir/apktool/AndroidManifest.xml

        if ! grep -q "$search_string" "$mfFiel"; then
            echo "安装包与证书不匹配：$search_string"
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
        return 1
    fi
}

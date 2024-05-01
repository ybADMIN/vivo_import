#!/bin/bash
function outputCerCacheFile(){
     # 保存目录中的 .CER 文件的 MD5 值
    find "$target_dir" -name "*.CER" -type f -exec md5 {} + > "$md5_file"
    initial_files=$(find "$target_dir" -name "*.CER" -type f > "$files_change_file")
}


function checkCersDirChange(){

# echo
# echo
# echo "--------证书完整性检测-开始--------"
# echo
# echo
echo "证书完整性检测..."
#检测证书完整性
local cer_abs_path=$(realpath $CER_NAME)

if [[ "$cer_abs_path" != "$CURRENT_DIRECTORY/cers"* ]]; then
    echo "注意：只有将证书存储在根目录的【cers】目录下才会做证书完整性检测"
    read -p "当前输入证书不在[cers]目录中，无法确保完整性是否继续？（输入 Y 或 N）: " choice
    # 将用户输入转换为小写字母以便比较
    choice=$(echo "${choice}" | tr '[:upper:]' '[:lower:]')

    # 检查用户输入是否为 Y 或 y，如果是，则执行操作
    if [ "${choice}" = "y" ]; then
        echo "注意!!!：${cer_abs_path} 无法检测检测完整性"
    elif [ "${choice}" = "n" ]; then
        echo "用户取消操作"
        exit 1
    else
        exit 1
    fi
fi

if [ ! -e  "cers" ]; then
    mkdir "cers"
    touch cers/readme.md
    echo "该目录可以保障你的证书，如果不小心被修改后在你使用签名时候提醒你"> cers/readme.md
fi
# 指定目录
local target_dir="cers"
if [ ! -e $target_dir ]; then
    echo "证书目录[$target_dir]不存在，请在根目录下创建证书目录[cers/dev 和 cers/res]"
    exit 1
fi


# 保存目录中的 .CER 文件的 MD5 值到文件
local md5_file="bin/tmp/cer_md5.txt"
local files_change_file="bin/tmp/file_list_record.txt"

if [ ! -e "bin/tmp" ]; then
    mkdir "bin/tmp"
fi


if [ ! -e $md5_file ]; then
  outputCerCacheFile
fi

local ischange=false
# 检查 .CER 文件是否发生变化或被删除
  while read -r line; do
        local file_path=$(echo "$line" | sed -E 's/.*\(([^)]+)\).*/\1/')
        local file_md5=$(echo "$line" | sed -E 's/.*= ([^ ]+).*/\1/')
        if [ ! -f "$file_path" ]; then
            echo "文件 $file_path 已被删除"
            ischange=true
        else
            local new_md5=$(md5 -q "$file_path")
            if [ "$file_md5" != "$new_md5" ]; then
                echo "文件 $file_path 已被修改"
                ischange=true
            fi
        fi
    done < "$md5_file"
    if [ "$ischange" = "true" ]; then
        read -p "证书文件有变更，请确认变更可控？（输入 Y 或 N）: " choice
            # 将用户输入转换为小写字母以便比较
            choice=$(echo "${choice}" | tr '[:upper:]' '[:lower:]')

            # 检查用户输入是否为 Y 或 y，如果是，则执行操作
            if [ "${choice}" = "y" ]; then
                echo "已确认正常变更"
                outputCerCacheFile
            elif [ "${choice}" = "n" ]; then
                echo "用户取消操作"
                exit 1
            else
                exit 1
            fi
        # else
        # echo "[cres]目录无修改"
    fi
    # 检查新增文件
    updated_files=$(find "$target_dir" -name "*.CER" -type f)
    initial_files=$(cat $files_change_file)
    new_files=$(comm -13 <(echo "$initial_files" | sort) <(echo "$updated_files" | sort))
    if [ -n "$new_files" ]; then
        echo "新增文件："
        echo "$new_files"
        read -p "新增证书是否更新配置文件，用于检测该证书后续变动？（输入 Y 或 N）: " choice
        # 将用户输入转换为小写字母以便比较
        choice=$(echo "${choice}" | tr '[:upper:]' '[:lower:]')

        # 检查用户输入是否为 Y 或 y，如果是，则执行操作
        if [ "${choice}" = "y" ]; then
            echo "已更新"
            outputCerCacheFile
        elif [ "${choice}" = "n" ]; then
            echo "用户取消操作"
            exit 1
        else
            exit 1
        fi   
    fi
#  echo
#  echo
#  echo "--------证书完整性检测-完成--------"
#  echo
#  echo
}
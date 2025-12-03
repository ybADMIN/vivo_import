
# 读取证书文件KeyValue
function getValueByKey {
   local key=$1
   local string=$2
    
    # 使用 grep 命令查找包含指定键的行，并使用 cut 命令获取值部分
    value=$(echo "$string" | grep "^$key:" | cut -d':' -f2-)
    
    # 去掉值部分前后的空格
    value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    echo "$value"
}
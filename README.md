使用步骤：

0. 根目录下新建文件`config.sh` 并修改对应参数
```shell
#KeyStore 路径
KEY_STORE_PATH="./bin/kt"
#key别名和密码
alias_key="abc"
key_pass="123"
#微信机器人id
ANDROID_NOTIFY_WX="企微群机器人"
#蒲公英配置
ANDROID_PGY="uKey=蒲公英Ukey,_api_key=蒲公英APIkey"
#证书参数校验 需要替为自己的包名和基础证书，证书文件用于检测应用打包时候制定的正式证书配置参数是否与标准证书一致
# 标准证书更新规则：PackageName、RelatedPackageNames、Permissions、SystemPermissions其中一项有变更
cerOptionMap=(
    "com_sx_sxassistant:bin/standardsCer/WORKPHONE.CER"
    "com_sx_sxDemon:bin/standardsCer/SXDEMON.CER"
    "com_sx_eptest:bin/standardsCer/EP-TEST.CER"
)

```

1. 命令行执行：import.sh <APK路径> <证书路径>"
   4、输出目录：outApk

2. 检测当前文件是否存在证书 
    * . rename.sh
    * checkApk <APK 路径>

导入校验说明：
1. 判断应用于证书是否对应
2.  导入开发证书会提醒用户确认
3. 文件命名为标准格式
4. 自动签名
5. 签名后验证证书是否与传入证书一致
6. 正式证书：标识、包名、权限、系统权限是否与config.sh cerOptionMap中标准证书一致
7. 验证证书包名是否与应用包名一致

该工具仅将证书打包进应用META-INF文件夹内，未做任何定制。您也可以自行下载使用其他工具如Android Studio打包导入。

但需注意，打包商业证书时应用内文件不允许有任何修改，因安装时需要校验apk hash。
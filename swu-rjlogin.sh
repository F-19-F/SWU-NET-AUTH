#!/bin/bash

#检测是否已经可以上网
captiveReturnCode=`curl -s -I -m 1 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
if [ "$captiveReturnCode" = "204" ]; then
  echo "已经可以正常上网了"
  exit 0
fi


#判断用户输入
if [ "$#" -lt "2" ]; then
  echo "用法: ./swu-rjlogin.sh 用户名 密码"
  echo "例: ./swu-rjlogin.sh 201620000000 123456"
  exit 1
fi



#如果无法上网，则尝试登录,不直接用域名，直接用ip，避免dns故障导致速度慢的情况
loginPageURL=`curl -s "http://1.1.1.1" | awk -F \' '{print $2}'`
loginURL=`echo $loginPageURL | awk -F \? '{print $1}'`
loginURL="${loginURL/index.jsp/InterFace.do?method=login}"




#简单的二次urlencode，只替换了可能出现的关键参数
queryString=`echo $loginPageURL | awk -F \? '{print $2}'`
queryString="${queryString//&/%2526}"
queryString="${queryString//=/%253D}"
queryString="${queryString//:/%253A}"
queryString="${queryString////%252F}"

result="fail"
#向认证接口发送信息
if [ -n "$loginURL" ]; then
  authResult=`curl -s\
    -A\
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36"\
    -e\
    "$loginPageURL"\
    -b\
    "EPORTAL_COOKIE_OPERATORPWD=;"\
    -d\
    "userId=$1&password=$2&service=%25E9%25BB%2598%25E8%25AE%25A4&queryString=$queryString&operatorPwd=&operatorUserId=&validcode="\
    -H\
    "Accept-Encoding: gzip, deflate"\
    -H\
    "Accept-Language: zh-CN,zh;q=0.9"\
    -H\
    "Content-Type: application/x-www-form-urlencoded; charset=UTF-8"\
    "$loginURL"`
  result=`echo $authResult | grep -oP '(?<="result":").*?(?=")'`
fi


if [ "$result" = "success" ]; then
  echo "登录成功"
else
  message=`echo $authResult | grep -oP '(?<="message":").*?(?=")'`
  echo "登录失败,失败原因:$message"
fi
#!/bin/bash

if [ $# -lt 1 ]; then
   echo "输入md文件"
   exit 1
fi

filename=${1%.*}
echo "filename ：${filename}"
filePath="./posts/${1}"

# 新建文章
cd ../
hexo new ${filename}

# 获取标题时间
title=`cat ${filePath} |grep "#" -m 1|awk '{print $2}'`
time=`date +%T`
date=`date +%F`
tags=""
categories=""

# 删除第一个---号之前的所有行
sed -i '1,/---/d' ${filePath}

# 添加分类标签
if [ $# -eq 3 ]; then
    categories=${2}
    tags=${3}
fi

# 替换插入
echo "title: ${title}"
echo "date: ${date} ${time}"
echo "tags: ${tags}"
echo "categories: ${categories}"

sed -i '1i---' ${filePath}
sed -i "1icategories: ${categories}" ${filePath}
sed -i "1itags: ${tags}" ${filePath}
sed -i "1idate: ${date} ${time}" ${filePath}
sed -i "1ititle: ${title}" ${filePath}
sed -i '1i---' ${filePath}

# 自己的md文件覆盖自动生成的文件
cp ${filePath} ./source/_posts/

#!/bin/bash
filename=${1%.*}
echo "创建文章：${filename}"

cd ../
hexo new ${filename}

cp ./posts/${1} ./source/_posts/

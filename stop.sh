#!/bin/bash
ps -aux |grep hexo |grep -v grep
kill -9 `ps -aux | grep hexo | grep -v grep | awk '{print $2}'`
echo "kill hexo ..."
ps -aux |grep hexo |grep -v grep

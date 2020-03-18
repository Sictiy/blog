#!/bin/bash
git pull
echo "hexo start run ..."
hexo generate 
hexo server >> ./hexo.log 2>&1

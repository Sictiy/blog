#!/bin/bash
hexo generate 
hexo deploy 
nohup hexo server > ./hexo.log 2>&1 &

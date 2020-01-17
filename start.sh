#!/bin/bash
hexo generate 
#hexo deploy 
hexo server > ./hexo.log 2>&1 &

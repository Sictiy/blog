#!/bin/bash
hexo generate 
hexo deploy
hexo server > ./log 2>&1 &

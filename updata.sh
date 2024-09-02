#!/bin/bash
git pull
hexo g
hexo d
git add *
git commit -m "updata:更新hexo配置"
git push

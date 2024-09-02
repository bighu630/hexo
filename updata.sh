#!/bin/bash
git pull
npx hexo g
npx hexo d
git add *
git commit -m "updata:更新hexo配置"
git push

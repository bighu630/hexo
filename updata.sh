#!/bin/bash
git pull
git add .
git commit -m "update"
git push

cd public
git pull
cd ..
npx hexo g

cd public
git add .
git commit -m "update"
git push
cd ..

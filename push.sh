#!/bin/bash
cd $(dirname $0)
./build-sitemap.sh
git add -A
git commit -m "update"
git push

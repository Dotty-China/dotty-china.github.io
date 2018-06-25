#!/bin/bash
cd $(dirname $0)
array=($(find . -name "*.html"))
rm -f site.txt
for str in "${array[@]}" 
do
  echo "https://www.dotty-china.org/${str:2}" >> site.txt
done

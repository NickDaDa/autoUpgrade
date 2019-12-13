#!/bin/bash
grep "success" /home/result/syncResult.txt > /dev/null
if [ $? -eq 0 ]; then
    echo "Data process succeed, Ready to execute logic shell..."
    ./logic.bash
else
    echo "Data Process Failed."
fi

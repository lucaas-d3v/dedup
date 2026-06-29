watch -n 0.5 "ps -C dedup -o pid,%cpu,%mem,rss,time | awk 'NR==1 {print \$0 \" (MB)\"}; NR>1 {\$4=sprintf(\"%.2f\", \$4/1024); print \$0}'"


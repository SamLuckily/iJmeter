#!/usr/bin/env bash

# JMeter 测试脚本自动执行器
# 必填 Jenkins 参数：
# thread_number_list="150 200 250"
# duration=60
# rampup_rate_list="5 10 15"（或单一值如 2.5）
# jmeter_path=/your/jmeter/path

set -e

export jmx_filename="tgfun-full-link-pressure-testing.jmx"

echo "🔧 自动化压测开始"
rm -f index.html
echo "" >index.html

rm -f *.jtl
rm -rf web_*

# 拆分参数为数组
IFS=' ' read -r -a thread_number_array <<<"$thread_number_list"
IFS=' ' read -r -a rampup_rate_array <<<"$rampup_rate_list"

# 自动填充 rampup_rate_list（若未提供或只有一个值）
if [ ${#rampup_rate_array[@]} -eq 1 ]; then
  single_rate="${rampup_rate_array[0]}"
  rampup_rate_array=()
  for ((i = 0; i < ${#thread_number_array[@]}; i++)); do
    rampup_rate_array+=("$single_rate")
  done
fi

# 校验两个列表长度是否一致
if [ ${#thread_number_array[@]} -ne ${#rampup_rate_array[@]} ]; then
  echo "❌ 参数数量不一致：thread_number_list 与 rampup_rate_list 必须一一对应"
  exit 1
fi

# 执行压测循环
for i in "${!thread_number_array[@]}"; do
  num="${thread_number_array[$i]}"
  rate="${rampup_rate_array[$i]}"
  rampup=$(awk -v n="$num" -v r="$rate" 'BEGIN { printf "%.0f", n / r }')

  echo ""
  echo "🚀 启动压测：线程数=$num | 启动速率=${rate}/s | Ramp-Up=${rampup}s | 持续时间=${duration}s"

  export jtl_filename="test_${num}.jtl"
  export web_report_path_name="web_${num}"

  "${jmeter_path}/bin/jmeter" \
    -n -t "${jmx_filename}" \
    -l "${jtl_filename}" \
    -Jthread="${num}" \
    -Jduration="${duration}" \
    -Jrampup="${rampup}" \
    -e -o "${web_report_path_name}"

  echo "✅ 完成并发数 ${num}，报告目录：${web_report_path_name}"
  echo "<a href='${web_report_path_name}'>${web_report_path_name}</a><br><br>" >>index.html

  sleep "${polling}"
done

echo ""
echo "🎉 全部压测任务完成，报告入口：index.html"

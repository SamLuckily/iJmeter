#!/usr/bin/env bash

# 必填 Jenkins 参数：线程数列表、持续时间、每秒并发启动速率
# 示例：
# thread_number_list="150 200 250 300"
# duration=600
# rampup_rate=2.5   # 每秒启动几个线程
# jmeter_path=/your/jmeter/path

export jmx_filename="tgfun-full-link-pressure-testing.jmx"

echo "🔧 自动化压测开始"
rm -f index.html
echo "" >index.html

rm -f *.jtl
rm -rf web_*

# 拆分线程数组
thread_number_array=($thread_number_list)

for num in "${thread_number_array[@]}"; do
  echo "🚀 压测并发数 ${num}"

  # ✅ 自动计算 Ramp-Up 时间 = 线程数 / 启动速率，向上取整
  rampup=$(awk -v n=${num} -v rate=${rampup_rate} 'BEGIN { printf "%.0f", n / rate }')
  echo "⏱️ Ramp-Up Period: ${rampup} 秒"

  export jtl_filename="test_${num}.jtl"
  export web_report_path_name="web_${num}"

  # 🔥 执行压测：使用 -J 参数传递 thread、duration、rampup
  ${jmeter_path}/bin/jmeter \
    -n -t ${jmx_filename} \
    -l ${jtl_filename} \
    -Jthread=${num} \
    -Jduration=${duration} \
    -Jrampup=${rampup} \
    -e -o ${web_report_path_name}

  # 追加报告入口
  echo "✅ 完成并发数 ${num}，报告生成：${web_report_path_name}"
  echo "<a href='${web_report_path_name}'>${web_report_path_name}</a><br><br>" >>index.html

  # ⏸️ 等待下一轮（可选）
  sleep ${polling}
done

echo "🎉 自动化压测全部结束"

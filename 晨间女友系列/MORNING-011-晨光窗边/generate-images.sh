#!/usr/bin/env bash
# 一张一张调度 MORNING-011 晨光窗边 的 Gemini 生图任务
# 每张图独立 add → dispatch → listen → copy，失败立即退出
set -euo pipefail

export PATH=/Users/leo/.nvm/versions/node/v20.20.0/bin:$PATH

ARTICLE_DIR="/Users/leo/Documents/awesome-image-prompt/晨间女友系列/MORNING-011-晨光窗边"
cd "$ARTICLE_DIR"

# -------------------------------------------------------
# 辅助函数：执行单张图任务
# 用法: run_job <job_json> <output_image> <job_id> <result_json>
# -------------------------------------------------------
run_job() {
  local JOB_FILE="$1"
  local TARGET_IMG="$2"
  local JOB_ID="$3"
  local RESULT_FILE="$4"

  echo ""
  echo "========================================"
  echo "▶ 开始生成 $TARGET_IMG (job: $JOB_ID)"
  echo "========================================"

  # 1. 提交任务
  auto-chat add "$JOB_FILE" --replace
  echo "  ✔ 任务已提交"

  # 2. 派发到 Gemini
  auto-chat dispatch --platform gpt "$JOB_ID"
  echo "  ✔ 已派发到 Gemini"

  # 3. 等待完成（阻塞，直到任务完成或失败）
  auto-chat listen "$JOB_ID"
  echo "  ✔ 任务监听结束"

  # 4. 保存结果 JSON
  auto-chat show "$JOB_ID" --json > "$RESULT_FILE"
  echo "  ✔ 结果已保存到 $RESULT_FILE"

  # 5. 从结果 JSON 解析 outputFiles[0] 并复制
  local OUTPUT_FILE
  OUTPUT_FILE=$(node -e "
    const r = require('./$RESULT_FILE');
    const files = r.outputFiles || [];
    if (files.length === 0) { console.error('❌ outputFiles 为空'); process.exit(1); }
    console.log(files[0]);
  ")
  echo "  ✔ 输出文件: $OUTPUT_FILE"

  cp "$OUTPUT_FILE" "$TARGET_IMG"
  echo "  ✔ 已复制到 $TARGET_IMG"

  # 6. 轻量校验
  file "$TARGET_IMG"
  echo "  ✅ $TARGET_IMG 生成完成"
}

# -------------------------------------------------------
# 逐张生成
# -------------------------------------------------------

run_job "image-job-01.json" "image-01.png" "morning011_img01" "job-result-01.json"
run_job "image-job-02.json" "image-02.png" "morning011_img02" "job-result-02.json"
run_job "image-job-03.json" "image-03.png" "morning011_img03" "job-result-03.json"
run_job "image-job-04.json" "image-04.png" "morning011_img04" "job-result-04.json"
run_job "image-job-05.json" "image-05.png" "morning011_img05" "job-result-05.json"

echo ""
echo "========================================"
echo "🎉 全部 5 张图片生成完毕！"
echo "========================================"
ls -lh image-0*.png

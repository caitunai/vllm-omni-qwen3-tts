# =========================
# Stage 1: 下载模型
# =========================
FROM python:3.14.3-slim AS builder

ENV MODEL_DIR=/models/qwen3-tts

RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir huggingface_hub

RUN mkdir -p ${MODEL_DIR} && \
    hf download \
    Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice \
    --local-dir ${MODEL_DIR}

# =========================
# Stage 2: 运行环境
# =========================
FROM vllm/vllm-omni:v0.18.0

ENV MODEL_DIR=/models/qwen3-tts

# 安装运行依赖（TTS 必须）
RUN apt-get update && apt-get install -y \
    sox \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 从 builder 拷贝模型
COPY --from=builder /models /models

# 暴露端口
EXPOSE 8091

# 启动（关键：--omni）
CMD ["vllm", "serve", "/models/qwen3-tts", \
     "--omni", \
     "--stage-configs-path", "vllm_omni/model_executor/stage_configs/qwen3_tts.yaml", \
     "--port", "8091"]

FROM runpod/worker-comfyui:5.8.5-base

RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# cache-bust: 2026-09-11-scail2-infinity — forces a fresh ComfyUI core clone
# below (Docker was reusing an old cached layer since this line's text hadn't
# changed, which caused comfy_api.latest/ComfyExtension — needed later by
# comfyui-scail2-infinity — to be missing from the stale cached core).
RUN rm -rf /comfyui && git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui && cd /comfyui && pip install --no-cache-dir -r requirements.txt && echo "cachebust-2026-09-11-scail2-infinity"

WORKDIR /comfyui/custom_nodes

RUN git clone https://github.com/city96/ComfyUI-GGUF.git && \
    if [ -f ComfyUI-GGUF/requirements.txt ]; then pip install --no-cache-dir -r ComfyUI-GGUF/requirements.txt; fi

RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    if [ -f ComfyUI-VideoHelperSuite/requirements.txt ]; then pip install --no-cache-dir -r ComfyUI-VideoHelperSuite/requirements.txt; fi

RUN git clone https://github.com/ComfyAssets/ComfyUI-KikoTools.git && \
    if [ -f ComfyUI-KikoTools/requirements.txt ]; then pip install --no-cache-dir -r ComfyUI-KikoTools/requirements.txt; fi

RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    if [ -f ComfyUI-KJNodes/requirements.txt ]; then pip install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt; fi

RUN git clone https://github.com/rgthree/rgthree-comfy.git && \
    if [ -f rgthree-comfy/requirements.txt ]; then pip install --no-cache-dir -r rgthree-comfy/requirements.txt; fi

# SCAIL-2 Infinity: all-in-one chunked long-video node (81-frame windows,
# 5-frame overlap, reuses core WanSCAILToVideo.execute() + common_ksampler()
# internally) — lets a single job generate arbitrarily long video at constant
# VRAM instead of allocating for the whole requested length at once.
RUN git clone https://github.com/collbroGTR/comfyui-scail2-infinity.git && \
    if [ -f comfyui-scail2-infinity/requirements.txt ]; then pip install --no-cache-dir -r comfyui-scail2-infinity/requirements.txt; fi

WORKDIR /comfyui

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# Patched handler: the stock runpod/worker-comfyui handler only collects node
# outputs under the "images" key, so VHS_VideoCombine's video output (saved
# under "gifs") was silently dropped ("success_no_images" despite a working
# render). This version also handles "gifs" and uploads it to bucket storage
# (R2/S3, via BUCKET_ENDPOINT_URL/BUCKET_ACCESS_KEY_ID/BUCKET_SECRET_ACCESS_KEY/
# BUCKET_NAME env vars on the endpoint) instead of returning it as base64,
# which is what overflowed RunPod's response size limit before.
COPY handler.py /handler.py

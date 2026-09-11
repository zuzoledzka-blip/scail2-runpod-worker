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

# SCAIL Auto Extend: chunked long-video sampler with Reinhard-LAB color-drift
# correction between chunks (comfyui-scail2-infinity lacked this and produced
# visible identity/color drift across chunk boundaries — hair/face changing).
RUN git clone https://github.com/Brobert-in-aus/scail-auto-extend.git && \
    if [ -f scail-auto-extend/requirements.txt ]; then pip install --no-cache-dir -r scail-auto-extend/requirements.txt; fi

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

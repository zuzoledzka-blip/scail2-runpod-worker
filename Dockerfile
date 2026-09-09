FROM runpod/worker-comfyui:5.8.5-base

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

WORKDIR /comfyui

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

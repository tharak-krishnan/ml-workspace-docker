# Use a recent stable Ubuntu image
FROM ubuntu:22.04

# Set environment variables to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PYTHONUNBUFFERED=1
# Set path for venv
ENV PATH="/opt/venv/bin:$PATH"

# Install system dependencies, Python3, pip, and venv
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3-pip \
    build-essential \
    cmake \
    git \
    curl \
    libgl1 \
    pkg-config \
    libsentencepiece-dev \
    # For OpenCV/matplotlib backends if needed beyond libgl1
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a Python virtual environment using python3.10
RUN python3.10 -m venv /opt/venv

# Activate the virtual environment and install Python libraries in batches
# This helps with readability and potentially caching layers

# --- Batch 1: Core ML, PyTorch, and essential compute libraries ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip wheel setuptools && \
    # Install PyTorch and related packages from the PyTorch CPU index
    pip install --no-cache-dir \
    torch~=2.3.0 --index-url https://download.pytorch.org/whl/cpu \
    torchvision~=0.18.0 --index-url https://download.pytorch.org/whl/cpu \
    torchaudio~=2.3.0 --index-url https://download.pytorch.org/whl/cpu && \
    # Install other core packages from PyPI
    pip install --no-cache-dir \
    jupyterlab \
    numpy \
    pandas \
    scipy \
    scikit-learn \
    Pillow

# --- Batch 2: Popular ML Frameworks & PyTorch Ecosystem ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    xgboost \
    lightgbm \
    catboost \
    pytorch-lightning \
    fastai \
    ignite \
    einops \
    skorch \
    accelerate \
    torchmetrics \
    # PyTorch Geometric and its dependencies
    torch-scatter torch-sparse torch-cluster torch-spline-conv -f https://data.pyg.org/whl/torch-2.3.0+cpu.html \
    torch-geometric

# --- Batch 3: Data Visualization ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    matplotlib \
    seaborn \
    plotly \
    bokeh \
    altair \
    ydata-profiling \
    plotnine

# --- Batch 4: Natural Language Processing (NLP) ---
# Install sentencepiece separately first, as it's a common build dependency
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir sentencepiece && \
    pip install --no-cache-dir \
    transformers \
    nltk \
    spacy \
    sentence-transformers \
    tokenizers \
    gensim \
    textblob && \
    # Download NLTK data and spaCy model
    python -m nltk.downloader popular && \
    python -m spacy download en_core_web_sm

# --- Batch 5: Computer Vision (CV) & Audio ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    timm \
    albumentations \
    opencv-python-headless \
    imageio \
    librosa \
    soundfile

# --- Batch 6: Hyperparameter Optimization (HPO) & Workflow ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    optuna \
    hyperopt \
    scikit-optimize \
    mlflow \
    wandb

# --- Batch 7: Model Interpretability ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    shap \
    captum \
    interpret \
    shapash \
    explainerdashboard \
    fairlearn \
    dtreeviz \
    dowhy \
    lit-nlp \
    imodels \
    aequitas \
    lofo-importance

# --- Batch 8: Scikit-learn Utilities & Other Useful Libraries ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    mlxtend \
    imbalanced-learn \
    category_encoders \
    statsmodels \
    hdbscan \
    pyjanitor \
    streamlit \
    gradio

# --- Batch 9: Malware Analysis & Reverse Engineering Tools ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    pefile \
    distorm3 \
    flare-capa \
    angr \
    vivisect \
    networkx

# Create a non-root user for security and a workspace directory
RUN useradd -m -s /bin/bash -u 1000 jupyteruser && \
    mkdir /workspace && \
    chown -R jupyteruser:jupyteruser /workspace

# Switch to the non-root user
USER jupyteruser

# Set the working directory
WORKDIR /workspace

# Expose the default Jupyter Notebook port
EXPOSE 8888

# Copy the entrypoint script (ensure this file exists in your build context)
COPY --chown=jupyteruser:jupyteruser entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden)
# Starts JupyterLab with no token/password for convenience in local dev
CMD ["--ip=0.0.0.0", "--port=8888", "--no-browser", "--NotebookApp.token=''", "--NotebookApp.password=''"]


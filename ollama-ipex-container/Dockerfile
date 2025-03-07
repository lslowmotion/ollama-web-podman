# Use an official base image as a starting point
FROM docker.io/intelanalytics/ipex-llm-inference-cpp-xpu:latest

# Set environment variables
ENV no_proxy=localhost,127.0.0.1
ENV OLLAMA_HOST=0.0.0.0
ENV DEVICE=Arc
ENV HOSTNAME=intel-llm
ENV OLLAMA_NUM_GPU=999
ENV ZES_ENABLE_SYSMAN=1
ENV ONEAPI_DEVICE_SELECTOR=level_zero:0

# Create a directory for Ollama if it doesn't exist
RUN mkdir -p /root/.ollama

# Expose the port
EXPOSE 11434

# Copy the entrypoint.sh script into the container
COPY entrypoint.sh /entrypoint.sh

# Make the entrypoint.sh script executable
RUN chmod +x /entrypoint.sh

# Run the entrypoint.sh script when the container starts
ENTRYPOINT ["/entrypoint.sh"]

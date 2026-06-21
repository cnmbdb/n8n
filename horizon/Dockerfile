# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install uv for faster dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Use a PyPI mirror by default because some VPS/Docker DNS paths intermittently
# fail to resolve files.pythonhosted.org during image builds.
ARG UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple
ENV UV_DEFAULT_INDEX=${UV_DEFAULT_INDEX}
ENV UV_HTTP_TIMEOUT=120
ENV UV_HTTP_RETRIES=10

# Copy project files
COPY pyproject.toml uv.lock README.md ./
COPY src ./src
COPY data ./data
COPY .env.example .env.example

# Install dependencies
RUN uv sync --frozen --no-dev

# Create volume mount points
VOLUME ["/app/data"]

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run the application
ENTRYPOINT ["uv", "run", "horizon"]
CMD []

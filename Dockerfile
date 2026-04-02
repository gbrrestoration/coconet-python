# syntax=docker/dockerfile:1

FROM python:3.12-slim-bookworm

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=/usr/local/bin/python3

WORKDIR /app

RUN useradd --create-home --shell /bin/bash --uid 1000 coconet

COPY pyproject.toml uv.lock README.md ./
COPY coconet ./coconet

RUN uv sync --frozen

COPY legacy ./legacy
COPY config ./config

RUN chown -R coconet:coconet /app

USER coconet

ENV PATH="/app/.venv/bin:${PATH}"

ENTRYPOINT ["coconet"]

CMD ["--help"]

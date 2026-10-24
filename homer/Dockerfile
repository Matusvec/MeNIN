# syntax=docker/dockerfile:1.7
# The agent service. Build from homer/ with the content bank as a second context:
#   docker compose build                                      (compose passes ../content)
#   docker build --build-context content=../content -t homer .
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app/homer

COPY requirements.txt .
# The CMU dictionary ships inside the pronouncing/cmudict wheels; load it once to prove it's there.
RUN pip install -r requirements.txt \
 && python -c "import pronouncing; pronouncing.init_cmu(); assert pronouncing.phones_for_word('sea')"

# content/formulas.json and friends, at /app/content (homer/formulas.py looks two levels up).
COPY --from=content . /app/content
COPY homer ./homer
COPY scripts ./scripts
COPY AGENTVERSE.md ./

RUN useradd --create-home --uid 10001 homer && chown -R homer /app
USER homer

EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD python -c "import sys, urllib.request; sys.exit(urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status != 200)"

# One worker: dealt hands, emotion samples and in-flight judging live in memory.
CMD ["uvicorn", "homer.server:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips", "*"]

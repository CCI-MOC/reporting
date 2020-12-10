
#summary-frontend
FROM python:3-buster
ADD ./src/ /code
WORKDIR /code

ENV PYTHONPATH="/code/app:${PYTHONPATH}"
RUN  true \
  && /usr/bin/env pip install --upgrade pip \
  && /usr/bin/env pip install -r requirements.txt

ENTRYPOINT ['/usr/bin/env', 'python3', '/code/docker_entrypoint.py']

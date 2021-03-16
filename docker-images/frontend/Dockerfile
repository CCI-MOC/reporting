
#summary-frontend
FROM python:3.9
ADD ./src/ /code
WORKDIR /code

ENV PYTHONPATH="/code/app:${PYTHONPATH}"
RUN  true \
  && pip install --upgrade pip \
  && pip install -r requirements.txt

CMD ["/usr/bin/env","python3", "/code/docker_entrypoint.py"]
# ENTRYPOINT ['sleep','60000']

FROM python:latest

RUN uname -a && python -V

WORKDIR deuterium

RUN pip install virtualenv
RUN virtualenv ext/venv \
    && chmod u+x ./ext/venv/bin/activate \
    && ./ext/venv/bin/activate
RUN pip install ipykernel jupyter_client pynvim

COPY . .

CMD ["/deuterium/run_tests.sh"]

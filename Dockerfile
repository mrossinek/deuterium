FROM python:latest

RUN uname -a && python -V
RUN apt-get update

WORKDIR neovim

RUN apt-get install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip
RUN git clone --recursive https://github.com/neovim/neovim.git .
RUN make CMAKE_BUILD_TYPE=RELEASE && make install

WORKDIR ../deuterium

RUN pip install virtualenv ipykernel jupyter_client
RUN virtualenv ext/venv \
    && chmod u+x ./ext/venv/bin/activate
RUN /bin/bash -c "source ./ext/venv/bin/activate && pip install ipykernel jupyter_client pynvim"

COPY . .

CMD ./run_tests.sh

# How to contribute

## Testing

You can run the unittests locally in either of two ways.

1. Using the `run_tests.sh` bash script: Simply execute the script from the
   root of the repository.
   Please ensure that you have cloned [vader.vim](https://github.com/junegunn/vader.vim) into `ext/vader.vim` and have set
   up a virtualenv under `ext/venv` in which the required packages `ipykernel`,
   `jupyter_client` and `pynvim` are installed.
2. Using docker: Simply run
   ```
   docker build -t deuterium .
   docker run deuterium
   ```
   from the root of the repository.
   Please ensure that `docker` is installed and its daemon is running.

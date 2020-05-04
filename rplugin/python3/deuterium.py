""" Deuterium """

import re
from base64 import decodebytes
from queue import Empty
from tempfile import NamedTemporaryFile
from subprocess import Popen
import vim  # pylint: disable=import-error


class Deuterium:
    """ Deuterium - to be used as a static class

    Attributes:
        manager   the KernelManager instance
        client    an instance of the jupyter KernelClient class
        msg_id    the integer id of the last execute_request message send to the kernel
    """
    manager = None
    client = None
    msg_id = None
    image_file = None

    @staticmethod
    def connect():
        """ Connect to the Kernel

        Assumes that an IPython kernel is running whose connection file can be found automatically.
        """
        # pylint: disable=import-outside-toplevel
        from jupyter_client import KernelManager, find_connection_file

        # setup kernel manager
        cfile = find_connection_file()
        Deuterium.manager = KernelManager(connection_file=cfile)
        Deuterium.manager.load_connection_file()

        # create client and connect
        Deuterium.client = Deuterium.manager.client()
        Deuterium.client.start_channels()

        # ping kernel
        Deuterium.client.kernel_info()
        try:
            Deuterium.client.get_shell_msg(timeout=1)
        except Empty:
            raise ConnectionError

    @staticmethod
    def shutdown():
        """ Shutdown the Kernel
        """
        if Deuterium.image_file:
            Deuterium.image_file.close()
        Deuterium.msg_id = Deuterium.manager.shutdown_kernel()
        try:
            Deuterium.client.get_shell_msg(timeout=1)
        except Empty:
            pass
        Deuterium.client.stop_channels()

    @staticmethod
    def send():
        """ Send code for execution to the Kernel

        The code send is automatically grabbed from the current selection in vim.
        """
        code = vim.eval("a:code")
        Deuterium.msg_id = Deuterium.client.execute(code, stop_on_error=False)
        success = False
        stdout = ''
        stderr = ''
        # wait for answer on shell channel
        while True:
            try:
                msg = Deuterium.client.get_shell_msg(timeout=1)
            except Empty:
                continue
            if msg['parent_header']['msg_id'] == Deuterium.msg_id \
                    and msg['msg_type'] == 'execute_reply':
                # TODO handle all possible statuses (incl. 'aborted')
                if msg['content']['status'] == 'ok':
                    success = True
                    # if the command ran successfully, check for any output on the stream channels
                    msgs = Deuterium.read_streams()
                    stdout = '\n'.join([m['text'] for m in msgs if m['name'] == 'stdout'])
                    stderr = '\n'.join([m['text'] for m in msgs if m['name'] == 'stderr'])
                else:
                    # otherwise we gather some information on the error
                    success = False
                    stdout = '{}: {}'.format(msg['content'].get('ename', ''),
                                             msg['content'].get('evalue', ''))
                    stderr = '\n'.join(msg['content'].get('traceback', ''))
                    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
                    stderr = ansi_escape.sub('', stderr)
                break

        vim.command('let success = %s' % int(success))
        vim.command('let stdout = "%s"' % stdout)
        vim.command('let stderr = "%s"' % stderr)

    @staticmethod
    def read_streams():
        """ Read the stream channels

        Returns:
            list: the contents of any stream messages send by the kernel
        """
        msgs = []
        for msg in Deuterium.client.iopub_channel.get_msgs():
            if msg['parent_header']['msg_id'] == Deuterium.msg_id:
                if msg['msg_type'] == 'stream':
                    msgs.append(msg['content'])
                elif msg['msg_type'] == 'display_data' \
                        and 'image/png' in msg['content']['data'].keys():
                    Deuterium.image_file = NamedTemporaryFile(suffix='.png')
                    Deuterium.image_file.write(decodebytes(
                        msg['content']['data']['image/png'].encode('utf-8')
                    ))
                    Popen(['/usr/bin/xdg-open', Deuterium.image_file.name])
        return msgs

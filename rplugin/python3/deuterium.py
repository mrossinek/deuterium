""" Deuterium """

from queue import Empty
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
        Deuterium.msg_id = Deuterium.client.execute(code)
        result = {}
        # wait for answer on shell channel
        while True:
            try:
                msg = Deuterium.client.get_shell_msg(timeout=1)
            except Empty:
                continue
            if msg['parent_header']['msg_id'] == Deuterium.msg_id \
                    and msg['msg_type'] == 'execute_reply':
                if msg['content']['status'] == 'ok':
                    result['success'] = True
                    # if the command ran successfully, check for any output on the stream channels
                    msgs = Deuterium.read_streams()
                    for stream in ('stdout', 'stderr'):
                        result[stream] = '\n'.join([m['text'] for m in msgs if m['name'] == stream])
                else:
                    # otherwise we gather some information on the error
                    result['success'] = False
                    result['stdout'] = msg['content']['ename'] + ': ' + msg['content']['evalue']
                    result['stderr'] = msg['content'].get('traceback', '')
                break

        # add an success indicator as virtual text
        virtualtext = [[vim.vars['deuterium#symbol_success'], 'DeuteriumSuccess']
                       if result['success'] else
                       [vim.vars['deuterium#symbol_failure'], 'DeuteriumFailure']]

        # if there is anything on stdout we add its first line to the virtual text
        if result['stdout'] != '':
            virtualtext.append([' ' + result['stdout'].split('\n')[0], 'DeuteriumText'])

        vim.command("let virtualtext = %s"% virtualtext)

        # TODO handle stderr output
        # TODO utilize popup or preview window for longer outputs

    @staticmethod
    def read_streams():
        """ Read the stream channels

        Returns:
            list: the contents of any stream messages send by the kernel
        """
        msgs = []
        for msg in Deuterium.client.iopub_channel.get_msgs():
            if msg['parent_header']['msg_id'] == Deuterium.msg_id \
                    and msg['msg_type'] == 'stream':
                msgs.append(msg['content'])
        return msgs

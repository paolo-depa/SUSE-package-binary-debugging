# SUSE Package Binary Debugging in VSCode

## Introduction
This guide provides an example of how to debug SLES package's binaries using Visual Studio Code (VSCode).
We will focus on debugging the following command:

> wicked --debug all --dry-run ifup lo

using a former version of the wicked package (0.6.75-3.40.1)
The setup will be performed on a SLES 12SP5, but the steps _should_ be similar on SLES15.

## VS Setup
- Visual Studio Code v 1.93.1
- Required extensions:
    - [Remote -SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
    - [C/C++ Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-extension-pack) (*)
    - [Native Debug](https://marketplace.visualstudio.com/items?itemName=webfreak.debug) (*)

(*) To be installed on the remote server

* Using the Remote SSH extension, SSH to the target machine with a user having admin credentials (root is suggested) and open a terminal
    - TODO evaluate remote debugging (either over SSH or not)
* Run the env_setup.sh script; ending successfully, the CWD should be /usr/src/packages/SOURCES/wicked-0.6.75 -> open that folder in VScode
* Select "Run -> Add Configuration" and copy the content of the launch.json file (its content is overkilling, but it is on purpose just to keep track of some useful options)
* Set a breakpoint in client/main.c at the very top of the main function and run the Debug config: after having downloaded eventually some debuginfo packages, debug should hit the breakpoint 
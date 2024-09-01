# xlarig-autosetup
An automatic setup for xlarig on termux. Once ran, it creates a Debian VM and builds xlarig automatically. It will then create a script called `xlarig.sh` whose options are described here :

- `-i` : must be included at first run to install xlarig on the VM.
- `-s` : if included, enables the solo mining
- `-d=<1-100>` : specifies the percentage of mined XLA to donate to Scala team
- `-a=<address>` : specifies the XLA crypto address
- `-w=<worker name>` : specifies the worker name
- `-c=<2|4>` : specifies whether to use 2 or 4 cores

Don't forget to star the repo if you found it useful !

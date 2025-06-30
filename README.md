# `vapixlib.sh`
Shell script implementation of Axis Communications Network Video VAPIX API 

## Contents

[vapixlib.sh](vapixlib.sh)  The source-able shell library. Uses a few `bash`isms. Most callable functions take the server name/IP, the axis user, and the axis password as the first three parameters, then whatever function-unique parameters may be needed. See `axis.sh` for examples.

[axis.sh](axis.sh) Example utilizing `vapixlib.sh`. Intended to be symbolically linked to a number of files, e.g. `down.sh`, `up.sh`, `left.sh`, `zoomin.sh`, etc. Whichever one is executed at the command line controls what function of the API is invoked.

Need to set the following environmental variables before running `axis.sh`. `AXIS` should be the IP address or hostname of your Axis product. `AXISPASS` and `AXISUSER` need to be whatever username and password you have set up in your Axis product. 

For example
``` 
AXIS=10.10.10.99
AXISUSER=axisuser
AXISPASS=somepasswd
``` 

# References
[Axis](https://wwwaxis.com/) Communications [VAPIX documentation](https://developer.axis.com/vapix/)
Requires `[curl](https://curl.se/)`, and the stream recording functions require `[xmlstarlet](https://xmlstar.sourceforge.net/)` (actually they will work without it, but it's difficult to use). So far `[jq](https://jqlang.org/)` is not required because VAPIX doesn't use much JSON (I am disappointed by this fact).

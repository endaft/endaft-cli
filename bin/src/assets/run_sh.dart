const dockerRunSh = r"""#!/bin/bash

if [ "$(command -v endaft)" == "" ]; then
    # The usual way of installing endaft
    dart pub global activate endaft >>/dev/null

    # Helpful for installing endaft from a local source. You probably don't want to use this
    # dart pub global activate --source path "/home/user/Source/endaft/cli" >>/dev/null
fi

endaft build
""";

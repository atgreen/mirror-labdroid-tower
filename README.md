# labdroid-tower

An Ansible Tower image with custom venvs in support of playbooks that
require additional libraries.

    $ oc create -f ImageStream.yml
    $ oc create -f BuildConfig.yml
    $ oc start-build labdroid-tower --follow
    

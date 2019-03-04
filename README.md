# Building Custom Tower Images for OpenShift

Let's build and deploy a modified Ansible Tower container with extra
Python libraries.

You'll need to do this, for instance, if you ever try to use the
`gcp_*` modules for talking to GCE: Ansible will complain about
missing the `google-auth` Python library.  You shouldn't just `pip
install` it on your running container, so let's build a new Tower
image based on the old one, but with a new Python virtual environment
containing our missing Python libraries.

First, create a Dockerfile that looks like this:

    FROM registry.access.redhat.com/ansible-tower-34/ansible-tower:latest
    
    USER root
    
    RUN mkdir -p /var/lib/awx/venv/gce
    RUN virtualenv --system-site-packages /var/lib/awx/venv/gce
    RUN umask 0022 \
        && cp -a /var/lib/awx/venv/ansible/lib64/python2.7/site-packages/* \
              /var/lib/awx/venv/gce/lib64/python2.7/site-packages/ \
        && sh -c ". /var/lib/awx/venv/gce/bin/activate ; pip install google_auth;"

This creates a new Python virtual environment called `gce` that has
the `google_auth` module installed.

And since we're using OpenShift, let's create ImageStream and
BuildConfig objects based on these files:

ImageStream:

    apiVersion: v1
    kind: ImageStream
    metadata:
      labels:
        app: labdroid-tower
      name: labdroid-tower
    spec: {}

BuildConfig:

    apiVersion: v1
    items:
    - apiVersion: v1
      kind: BuildConfig
      metadata:
        annotations:
        labels:
          app: "labdroid-tower"
        name: "labdroid-tower"
      spec:
        output:
          to:
            kind: "ImageStreamTag"
            name: "labdroid-tower:latest"
        resources: {}
        source:
          git:
            ref: master
            uri: https://gogs-labdroid.apps.home.labdroid.net/green/labdroid-tower.git
          contextDir:
          type: Git
        strategy:
          dockerStrategy:
            dockerfilePath: Dockerfile
            from:
              kind: DockerImage
              name: ansible-tower-34/ansible-tower
            forcePull: true
          type: Docker
    kind: List
    metadata: {}

Be sure to change the `uri` up there to point at your git repo
containing the `Dockerfile`.  You'll probably want to change
`labdroid-tower` to something else as well.  This will be the name of
your new container image.

Log into your Tower project on OpenShift, then create the objects and
start the build like so:

    $ oc create -f ImageStream.yml
    $ oc create -f BuildConfig.yml
    $ oc start-build labdroid-tower --follow

Now you'll have a new Tower image called `labdroid-tower:latest`.  To
deploy it, you need to change these variables in `group_vars/all` for
the Tower OpenShift installer playbook:

    kubernetes_web_image: docker-registry.default.svc:5000/tower/labdroid-tower
    kubernetes_task_image: docker-registry.default.svc:5000/tower/labdroid-tower
    kubernetes_task_version: 'latest'
    kubernetes_web_version: 'latest'

Now run the Tower installer and the old Tower containers will be
replaced with your new one.

In this case I needed the `google-auth` library on the target machine
for my playbook (which happens to be the Tower container), so I force
it to run in the virtual environment containing this library like so:

    - name: Use the GCE API to do some things
      hosts: localhost
      gather_facts: no
      vars:
        ansible_python_interpreter: "/var/lib/awx/venv/gce/bin/python"

That's it!

Happy hacking,

AG
    

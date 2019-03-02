FROM registry.access.redhat.com/ansible-tower-34/ansible-tower:latest

USER root

RUN mkdir -p /var/lib/awx/venv/gce
RUN virtualenv --system-site-packages /var/lib/awx/venv/gce
RUN umask 0022 \
    && cp -a /var/lib/awx/venv/ansible/lib64/python2.7/site-packages/* \
          /var/lib/awx/venv/gce/lib64/python2.7/site-packages/ \
    && sh -c ". /var/lib/awx/venv/gce/bin/activate ; pip install google_auth;"


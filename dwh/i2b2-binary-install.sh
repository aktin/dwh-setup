#!/bin/sh

# Installiert i2b2 von einem zuvor generierten Binärpaket
# TODO test

JBDDIR=/opt/jboss-as-7.1.1.Final/standalone/deployments

cd $JBDDIR
tar xvf /vagrant/packages/i2b2-war-bin.tar

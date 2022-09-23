#!/bin/bash

perl -I ./local/lib/perl5 ./RpgServer.pl daemon --listen http://*:$PORT -m $RUN_MODE



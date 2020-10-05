#!/bin/bash
set -ex

cpan -u
cpan -a
dateline=`date +%Y_%m_%d_00`
mv ~/.cpan/Bundle/Snapshot_${dateline}.pm /code/Snapshot_${dateline}.pm

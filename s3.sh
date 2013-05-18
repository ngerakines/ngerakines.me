#!/bin/bash

s3cmd sync _site/ s3://ngerakines.me
s3cmd setacl --acl-public --recursive s3://ngerakines.me

#!/bin/bash

s3cmd sync public/ s3://ngerakines.me
s3cmd setacl --acl-public --recursive s3://ngerakines.me

#!/bin/bash

echo "Started run_vdscreator with params:  username=$DREMIO_USERNAME vds-def-dir=/code/vdsdefinition/"

python3 /code/vds-creator.py --url "$DREMIO_ENDPOINT" --user "$DREMIO_USERNAME" --password "$DREMIO_PASSWORD" --vds-def-dir "/code/vdsdefinition/"



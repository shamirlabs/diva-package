#!/bin/bash

project_dir="../../diva"

cd "$project_dir"

if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar al directorio '$project_dir'."
    exit 1
fi

echo "Directorio actual: $(pwd)"

echo "Actualizando el repositorio..."
git pull

if [ $? -ne 0 ]; then
    echo "Error: La actualización del repositorio falló."
    exit 1
fi

make build

if [ $? -ne 0 ]; then
    echo "Error: el make build falló."
    exit 1
fi

make docker-build

if [ $? -ne 0 ]; then
    echo "Error: el make build-docker falló."
    exit 1
fi

echo "all ok"
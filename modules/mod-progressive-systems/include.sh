#!/bin/bash

# Progressive Systems Module Loader
# Infinite Progression System for AzerothCore
# Database setup is now AUTOMATIC on server startup!

echo "==========================================="
echo "Loading Progressive Systems Module..."
echo "Infinite Progression System"
echo "==========================================="
echo "Database tables will be auto-created on server startup"
echo "No manual SQL import needed!"
echo "==========================================="

# Copy config file if it doesn't exist
if [ ! -f "${INSTALL_DIR}/etc/mod-progressive-systems.conf" ]; then
    if [ -f "${CMAKE_CURRENT_SOURCE_DIR}/mod-progressive-systems.conf.dist" ]; then
        cp "${CMAKE_CURRENT_SOURCE_DIR}/mod-progressive-systems.conf.dist" "${INSTALL_DIR}/etc/mod-progressive-systems.conf"
        echo "Copied mod-progressive-systems.conf.dist to etc/mod-progressive-systems.conf"
    fi
fi

echo "Progressive Systems Module loaded successfully!"
echo "==========================================="

# OpenWorld

![Flutter](https://img.shields.io/badge/-Flutter-black?style=flat-circle&logo=flutter)
![OpenStreetMap](https://img.shields.io/badge/-OpenStreetMap-black?style=flat-circle&logo=openstreetmap)

A Flutter-based exploration tracking app that gamifies real-world exploration through an interactive fog-of-war system on OpenStreetMap.

## Overview

OpenWorld transforms your everyday movements into an exploration adventure. As you move through the real world, the app reveals areas on the map by clearing procedurally generated cloud textures, creating a unique fog-of-war experience similar to video games.

## Features

- **Real-time Location Tracking**: Continuously tracks your position and automatically reveals explored areas
- **Procedural Cloud System**: Realistic cloud textures using Perlin noise that cover unexplored regions
- **Exploration Statistics**: Track your progress with detailed stats including covered area, distance traveled, and zones explored
- **Persistent Data**: All explored areas are stored locally using SQLite
- **Performance Optimized**: Adaptive rendering based on zoom level, viewport culling, and efficient geometry calculations

## Tech Stack

- **Framework**: Flutter 3.9.2+ / Dart 3.9.2+
- **Mapping**: flutter_map ^7.0.2 (OpenStreetMap with CartoDB Voyager tiles)
- **Location Services**: geolocator ^13.0.2
- **Database**: sqflite ^2.4.1 (SQLite for persistent storage)
- **Coordinates**: latlong2 ^0.9.2
- **UI**: Material Design 3 with custom theme support

## Configuration

The app automatically handles permissions for location services. On first run, it will request access to your device's location.

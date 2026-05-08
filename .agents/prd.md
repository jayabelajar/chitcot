# PRD — BlueMesh Chat

## Overview
BlueMesh Chat adalah aplikasi chat offline-first berbasis Bluetooth Low Energy (BLE) mesh networking yang memungkinkan pengguna berkirim pesan tanpa internet, tanpa server, dan tanpa akun.

## Core Features
- Offline messaging via BLE
- Anonymous identity (tanpa login/no HP/email)
- Nearby public room
- Private direct message
- BLE mesh relay (multi-hop)
- TTL / hop limit
- Duplicate message filter
- Store & forward messaging
- Hybrid online/offline mode
- End-to-end encryption

## Target Users
- Mahasiswa
- Event/community users
- Area minim sinyal
- Emergency communication
- Privacy-focused users

## Core Concept
Setiap device menjadi:
- sender
- receiver
- relay node

Contoh relay:
A → B → C → D

Pesan dapat “melompat” antar device untuk memperluas jangkauan komunikasi.

## User Flow
Open App
↓
Generate local identity
↓
Enable Bluetooth
↓
Discover nearby peers
↓
Join local room
↓
Send/receive messages

## Transport System
### Offline Mode
- Bluetooth Low Energy (BLE)
- Mesh relay
- No internet

### Online Mode
- Firebase / Supabase
- Sync pending messages
- Auto fallback ke BLE saat offline

## Tech Stack
Frontend:
- Flutter

Bluetooth:
- flutter_blue_plus
- Native BLE bridge

Database:
- Drift / SQLite / Isar

State Management:
- Riverpod / Bloc

Encryption:
- AES/GCM
- Curve25519
- libsodium

Online Backend:
- Firebase OR Supabase

## Architecture
Flutter App
│
├── UI Layer
├── Messaging Engine
├── Mesh Engine
├── BLE Transport
├── Online Transport
├── Security Layer
└── Local Database

## Main Modules
### BLE Layer
- scan peer
- advertise
- connect
- send packet

### Mesh Engine
- relay message
- TTL control
- duplicate filter
- routing
- store & forward

### Security
- local key pair
- encrypted messaging
- signature verification

## Database Schema
users
- id
- nickname
- public_key

messages
- id
- sender_id
- receiver_id
- ciphertext
- ttl
- hop_count
- status

relay_queue
- message_id
- expires_at

seen_messages
- message_id

## MVP Roadmap

### Phase 1
- BLE discovery
- public chat
- basic DM

### Phase 2
- mesh relay
- TTL
- duplicate filter

### Phase 3
- encryption
- store & forward
- delivery status

### Phase 4
- online sync
- emergency broadcast
- multi-room

## Key Challenges
- BLE payload limitation
- Android/iOS background restriction
- battery optimization
- mesh stability
- relay spam prevention

## Unique Selling Point
- No internet required
- No server
- Anonymous communication
- Offline-first
- Mesh-based messaging
- Privacy-focused
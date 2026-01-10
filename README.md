# Pokemon TCG Online — Ruby on Rails Web App

A full-stack web application that digitalizes Pokemon Trading Card Game, implementing gameplay mechanics, real-time multiplayer battles, and deck management with Vue.js frontend and Rails API backend.

## 🎮 Features

- **Digital Card Table**: Virtual play space for Pokemon TCG with manual card control
- **Card Movement System**: Drag-and-drop interface for moving cards between zones
- **Real-time Synchronization**: All card movements instantly synced between players via WebSocket
- **Card Zone Management**: Support for all TCG zones (Active, Bench, Hand, Deck, Discard, Prize)
- **Room System**: Create/join game rooms for multiplayer sessions
- **Deck Builder**: Search card database and build custom decks for gameplay
- **Game State Persistence**: Save and restore game sessions
- **OAuth Authentication**: Google OAuth2 integration for secure login

### Frontend
- **Vue.js 3**: Component-based UI framework
- **WebSocket**: Real-time card movement sync

### Backend
- **Ruby on Rails 8.0.3**: RESTful API server
- **PostgreSQL**: Primary database
- **Solid Cable**: WebSocket server for real-time synchronization

### Development & Testing
- **RSpec**: Testing framework
- **Factory Bot**: Test data generation

## Installation & Setup

1. git clone
2. 
```
# Terminal 1 - Backend
bundle install
rails db:create db:migrate db:seed
rails server

# Terminal 2 - Frontend
cd frontend
npm install
npm run dev
```
3. Create `.env` file:

```
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
JWT_SECRET_KEY=your_jwt_secret_key
```

4. Setup database:
```
rails db:create db:migrate db:seed
```

5. Start servers
```
# Terminal 1 - Backend
rails server

# Terminal 2 - Frontend
cd frontend && npm run dev
```

License
This project is for educational and personal learning purposes only.

Acknowledgments
Card Data: [PTCG-database](https://github.com/type-null/PTCG-database)

Educational Purpose Statement: This project serves as a learning exercise in full-stack web development, including RESTful API design, real-time WebSocket communication, database modeling, OAuth authentication, and modern frontend frameworks. Pokemon and all related properties are trademarks of Nintendo/Creatures Inc./GAME FREAK Inc.
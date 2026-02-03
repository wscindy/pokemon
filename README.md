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
- **GitHub Actions**: Automated testing on every push

## Testing

This project uses **RSpec** for backend testing and **Playwright** for frontend E2E testing. All tests run automatically via GitHub Actions on every push.

### Backend Testing (RSpec)


Run tests locally:


[RSpec Tests Folder](https://github.com/wscindy/pokemon/tree/fdad7f328a5fc6038becce8c7a3218b054ff510b/backend/spec)
```bash
cd backend
bundle exec rspec                    # Run all tests
bundle exec rspec spec/models/       # Test specific folder
bundle exec rspec spec/models/user_spec.rb  # Test specific file
```

**CI/CD:** Tests automatically run on push via [GitHub Actions](.github/workflows/test.yml)

### Frontend E2E Testing (Playwright)
Run tests locally:

```bash
cd frontend/vue-project
npx playwright test                  # Run all tests
npx playwright test --ui             # Run with UI mode
npx playwright test --headed         # Run with browser visible
npx playwright show-report           # View test report
```

**CI/CD:** Playwright test cases automatically run on push via [GitHub Actions](.github/workflows/playwright.yml)

**An example of passed Playwright test cases on GitHub Actions**: [View Test Report](https://github.com/wscindy/pokemon/actions/runs/21621774799)

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
# B-Side: Music Category Challenge App

B-Side is a mobile-first web application for weekly music challenge games among friends. Each week features a category, players submit songs that fit the category, then vote on each other's picks. The app features seasonal leaderboards and automatic Spotify/Tidal playlist generation.

## Features

- **Weekly Music Challenges**: Submit and vote on songs based on weekly categories
- **Invite-Only Groups**: Create private groups and invite friends via unique invite codes
- **Seasonal Leaderboards**: Track scores across 10-week seasons
- **Playlist Generation**: Automatic Spotify and Tidal playlist creation (when configured)
- **Mobile-First Design**: Responsive Tailwind CSS interface optimized for mobile devices
- **Real-Time Updates**: Hotwire (Turbo + Stimulus) for seamless interactivity
- **Background Jobs**: Solid Queue for playlist generation and reminders

## Game Rules

1. **Monday**: New category announced for the week
2. **Monday-Thursday**: Players submit one song each with optional comment
3. **Thursday**: Submission deadline, playlists auto-generated, voting opens
4. **Thursday-Sunday**: Players vote on others' submissions (1-10 scale) with optional comments
5. **Monday**: Results revealed, new category starts
6. **Seasons**: 10 weeks each, seasonal leaderboard tracks cumulative scores

## Tech Stack

- **Rails 8.1** - Web framework
- **PostgreSQL** - Database
- **Tailwind CSS** - Mobile-first styling
- **Hotwire** (Turbo + Stimulus) - Reactivity without heavy JavaScript
- **Devise** - Authentication
- **Solid Queue** - Background job processing
- **esbuild** - JavaScript bundling

## Local Development Setup

### Prerequisites

- Ruby 3.2+
- PostgreSQL 14+
- Node.js 18+ (for esbuild and Tailwind)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/b-side.git
cd b-side
```

2. Install dependencies:
```bash
bundle install
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Set up the database:
```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # Optional: adds sample data
```

5. Start the development server:
```bash
bin/dev
```

The app will be available at `http://localhost:3000`.

## Environment Variables

Required environment variables (see `.env.example` for full list):

- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Rails secret (generate with `bin/rails secret`)
- `DEVISE_SECRET_KEY` - Devise secret (generate with `bin/rails secret`)

Optional (for full functionality):

- `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET` - For Spotify playlist generation
- `TIDAL_CLIENT_ID` and `TIDAL_CLIENT_SECRET` - For Tidal playlist generation
- SMTP settings - For email reminders

## Database Schema

### Core Models

- **User**: Email, display name, avatar (Devise authentication)
- **Group**: Name, unique invite code, creator
- **Membership**: User-Group association with role (member/admin)
- **Season**: 10-week competition period within a group
- **Week**: Individual week with category and deadlines
- **Submission**: User's song submission for a week
- **Vote**: User's vote (1-10) on another user's submission

## Deployment

### Fly.io Deployment

1. Install Fly CLI:
```bash
curl -L https://fly.io/install.sh | sh
```

2. Login to Fly:
```bash
fly auth login
```

3. Create and configure the app:
```bash
fly launch
```

4. Set environment secrets:
```bash
fly secrets set SECRET_KEY_BASE=$(bin/rails secret)
fly secrets set DEVISE_SECRET_KEY=$(bin/rails secret)
# Add other secrets as needed
```

5. Provision PostgreSQL:
```bash
fly postgres create
fly postgres attach <postgres-app-name>
```

6. Deploy:
```bash
fly deploy
```

### Neon PostgreSQL (Alternative)

B-Side is compatible with Neon's serverless PostgreSQL. Set your `DATABASE_URL` to your Neon connection string.

## API Integrations

### Spotify API (Optional)

To enable Spotify playlist generation:

1. Create an app at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Add your Client ID and Secret to environment variables
3. Implement authentication flow in `app/services/spotify_service.rb`

### Tidal API (Optional)

To enable Tidal playlist generation:

1. Register for Tidal API access
2. Add your credentials to environment variables
3. Implement integration in `app/services/tidal_service.rb`

## Development

### Running Tests

```bash
bin/rails test
```

### Code Quality

```bash
bin/rubocop        # Ruby linting
bin/brakeman       # Security scanning
bin/bundler-audit  # Dependency auditing
```

### Background Jobs

Background jobs are handled by Solid Queue. In development, they run automatically with `bin/dev`. In production, ensure the worker process is running.

## Architecture

### Services

- `SpotifyService` - Spotify API integration (placeholder)
- `TidalService` - Tidal API integration (placeholder)
- `ScoringService` - Calculate voting scores and leaderboards

### Background Jobs

- `GeneratePlaylistsJob` - Creates Spotify/Tidal playlists when voting opens
- `SendReminderJob` - Email reminders for submission/voting deadlines
- `AdvanceWeekJob` - Automated week progression

### Controllers

- `DashboardController` - User home showing active groups and current weeks
- `GroupsController` - Group management
- `InvitesController` - Invite link handling
- `SeasonsController` - Season management
- `WeeksController` - Week viewing
- `SubmissionsController` - Song submission
- `VotesController` - Voting on submissions
- `LeaderboardsController` - Weekly, season, and all-time rankings

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open a GitHub issue or contact the maintainers.


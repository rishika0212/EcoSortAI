# EcoSortAI Web Frontend

A modern, responsive web application for waste classification and recycling education.

## Features

- Image upload and waste classification
- User authentication and profile management
- Educational content about recycling
- Points system and leaderboard
- Responsive design for all devices

## Tech Stack

- React 18
- TypeScript
- Tailwind CSS
- React Router
- Axios for API calls
- Headless UI for accessible components

## Prerequisites

- Node.js 16.x or later
- npm 7.x or later

## Getting Started

1. Install dependencies:

   ```bash
   npm install
   ```

2. Start the development server:

   ```bash
   npm start
   ```

3. Build for production:
   ```bash
   npm run build
   ```

## Project Structure

```
src/
  ├── components/     # Reusable UI components
  ├── contexts/       # React contexts (auth, theme, etc.)
  ├── pages/         # Page components
  ├── services/      # API services
  ├── utils/         # Utility functions
  ├── types/         # TypeScript type definitions
  └── App.tsx        # Main application component
```

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```
REACT_APP_API_URL=http://localhost:8000
REACT_APP_ENV=development
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

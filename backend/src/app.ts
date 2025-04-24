import express from 'express';
import { setupMiddleware } from './middleware';
import routes from './routes';

// Initialize Express app
const app = express();

// Setup middleware
setupMiddleware(app);

// Register routes
app.use('/api', routes);

export default app; 
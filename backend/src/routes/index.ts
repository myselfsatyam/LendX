import { Router } from 'express';
import exampleRoutes from './example.routes';

const router = Router();

// Default route
router.get('/', (req, res) => {
  res.json({ message: "Welcome to LendX Backend API" });
});

// Mount example routes
router.use('/examples', exampleRoutes);

export default router; 
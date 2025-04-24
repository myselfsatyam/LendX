import { Router } from 'express';

const router = Router();

// Default route
router.get('/', (req, res) => {
  res.json({ message: "Welcome to LendX Backend API" });
});


export default router; 
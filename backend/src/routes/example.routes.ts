import { Router } from 'express';
import { getExamples, createExample } from '../controllers/example.controller';

const router = Router();

// Example routes
router.get('/', getExamples);
router.post('/', createExample);

export default router; 
import express from 'express';
import cors from 'cors';

export const setupMiddleware = (app: express.Application): void => {
  // Enable CORS
  app.use(cors());
  
  // Parse JSON bodies
  app.use(express.json());
}; 
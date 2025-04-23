import { Request, Response } from 'express';
import ExampleModel, { IExample } from '../models/example.model';

export const getExamples = async (req: Request, res: Response): Promise<void> => {
  try {
    const examples = await ExampleModel.find();
    res.status(200).json(examples);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching examples', error });
  }
};

export const createExample = async (req: Request, res: Response): Promise<void> => {
  try {
    const { title, description } = req.body;
    const newExample = new ExampleModel({
      title,
      description
    });
    
    const savedExample = await newExample.save();
    res.status(201).json(savedExample);
  } catch (error) {
    res.status(500).json({ message: 'Error creating example', error });
  }
}; 
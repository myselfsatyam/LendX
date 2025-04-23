import mongoose, { Schema, Document } from 'mongoose';

// Example interface for a model
export interface IExample extends Document {
  title: string;
  description: string;
  createdAt: Date;
}

// Example schema
const ExampleSchema: Schema = new Schema({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

export default mongoose.model<IExample>('Example', ExampleSchema); 
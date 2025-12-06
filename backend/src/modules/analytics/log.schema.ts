import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type LogDocument = HydratedDocument<Log>;

@Schema({ timestamps: true })
export class Log {
  @Prop({ required: true })
  category: string; // e.g., 'POS', 'AUTH', 'SYSTEM'

  @Prop({ required: true })
  action: string; // e.g., 'CHECKOUT', 'LOGIN_FAIL'

  @Prop({ type: Object })
  meta: any; // Flexible JSON payload

  @Prop()
  userId: number; // Optional user ID linked to event
}

export const LogSchema = SchemaFactory.createForClass(Log);

import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Log, LogDocument } from './log.schema';

@Injectable()
export class AnalyticsService {
  constructor(@InjectModel(Log.name) private logModel: Model<LogDocument>) {}

  getHealth() {
    return { status: 'ok', service: 'analytics', db: 'mongo' };
  }

  async logEvent(category: string, action: string, userId: number, meta: any = {}) {
    const newLog = new this.logModel({
      category,
      action,
      userId,
      meta,
    });
    return newLog.save();
  }

  async getRecentLogs(limit = 10) {
    return this.logModel.find().sort({ createdAt: -1 }).limit(limit).exec();
  }
}

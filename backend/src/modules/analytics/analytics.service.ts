import { Injectable } from '@nestjs/common';

@Injectable()
export class AnalyticsService {
  getHealth() {
    return { status: 'ok', service: 'analytics', timestamp: new Date().toISOString() };
  }
}

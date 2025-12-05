import { Injectable } from '@nestjs/common';

@Injectable()
export class FeedService {
  getHealth() {
    return { status: 'ok', service: 'feed', timestamp: new Date().toISOString() };
  }
}

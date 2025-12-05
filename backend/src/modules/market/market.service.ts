import { Injectable } from '@nestjs/common';

@Injectable()
export class MarketService {
  getHealth() {
    return { status: 'ok', service: 'market', timestamp: new Date().toISOString() };
  }
}

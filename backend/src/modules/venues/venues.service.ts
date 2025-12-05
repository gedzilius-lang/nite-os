import { Injectable } from '@nestjs/common';

@Injectable()
export class VenuesService {
  getHealth() {
    return { status: 'ok', service: 'venues', timestamp: new Date().toISOString() };
  }
}

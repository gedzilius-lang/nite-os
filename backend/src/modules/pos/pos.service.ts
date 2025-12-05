import { Injectable } from '@nestjs/common';

@Injectable()
export class PosService {
  getHealth() {
    return { status: 'ok', service: 'pos', timestamp: new Date().toISOString() };
  }
}

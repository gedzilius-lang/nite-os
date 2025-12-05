import { Injectable } from '@nestjs/common';

@Injectable()
export class NitecoinService {
  getHealth() {
    return { status: 'ok', service: 'nitecoin', timestamp: new Date().toISOString() };
  }
}

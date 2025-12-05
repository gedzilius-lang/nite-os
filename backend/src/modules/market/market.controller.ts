import { Controller, Get } from '@nestjs/common';
import { MarketService } from './market.service';

@Controller('market')
export class MarketController {
  constructor(private readonly service: MarketService) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }
}

import { Controller, Get, Param, Post } from '@nestjs/common';
import { MarketService } from './market.service';

@Controller('market')
export class MarketController {
  constructor(private readonly service: MarketService) {}

  @Get(':venueId/items')
  async getItems(@Param('venueId') venueId: string) {
    return this.service.getItemsByVenue(Number(venueId));
  }

  // Helper to generate data for manual testing
  @Post(':venueId/seed')
  async seed(@Param('venueId') venueId: string) {
    return this.service.seedDemoData(Number(venueId));
  }
}

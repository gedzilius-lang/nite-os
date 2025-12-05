import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MarketItem } from './market-item.entity';

@Injectable()
export class MarketService {
  constructor(
    @InjectRepository(MarketItem)
    private itemRepo: Repository<MarketItem>,
  ) {}

  // Fetch active items for a venue
  async getItemsByVenue(venueId: number) {
    return this.itemRepo.find({
      where: { venueId, active: true },
      order: { title: 'ASC' },
    });
  }

  // Temporary Seed Helper (for testing)
  async seedDemoData(venueId: number) {
    const items = [
      { title: 'Beer', priceChf: 8.0, priceNite: 50, venueId, active: true },
      { title: 'Long Drink', priceChf: 15.0, priceNite: 120, venueId, active: true },
      { title: 'Shot', priceChf: 5.0, priceNite: 30, venueId, active: true },
      { title: 'VIP Table', priceChf: 200.0, priceNite: 2000, venueId, active: true },
    ];
    // Clear old items for this venue to avoid dupes
    await this.itemRepo.delete({ venueId });
    return this.itemRepo.save(items);
  }
}

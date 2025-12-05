import { Repository } from 'typeorm';
import { MarketItem } from './market-item.entity';
export declare class MarketService {
    private itemRepo;
    constructor(itemRepo: Repository<MarketItem>);
    getItemsByVenue(venueId: number): Promise<MarketItem[]>;
    seedDemoData(venueId: number): Promise<({
        title: string;
        priceChf: number;
        priceNite: number;
        venueId: number;
        active: boolean;
    } & MarketItem)[]>;
}

import { MarketService } from './market.service';
export declare class MarketController {
    private readonly service;
    constructor(service: MarketService);
    getItems(venueId: string): Promise<import("./market-item.entity").MarketItem[]>;
    seed(venueId: string): Promise<({
        title: string;
        priceChf: number;
        priceNite: number;
        venueId: number;
        active: boolean;
    } & import("./market-item.entity").MarketItem)[]>;
}
